/// BBZCloud Mobile - Chat WebView
///
/// Purpose-built WebView for the stashcat-chat frontend running at
/// https://chat.bbz-rd-eck.com/?bridge=mobile. Wires up the JS bridge
/// (ChatBridge), pushes the mobile-bridge token for SSO, and keeps the
/// in-app theme in sync.
///
/// This is intentionally separate from `EmbeddedWebViewWidget`: the chat
/// does not need the legacy auto-login injection, BBB-link interception,
/// download forwarding, app switcher overlay etc. – everything is handled
/// inside the React app via the bridge.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bbzcloud_mobil/core/constants/app_config.dart';
import 'package:bbzcloud_mobil/core/utils/app_logger.dart';
import 'package:bbzcloud_mobil/core/utils/platform_utils.dart';
import 'package:bbzcloud_mobil/data/services/chat_auth_service.dart';
import 'package:bbzcloud_mobil/data/services/credential_service.dart';
import 'package:bbzcloud_mobil/presentation/providers/chat_state_provider.dart';
import 'package:bbzcloud_mobil/presentation/providers/settings_provider.dart';
import 'package:bbzcloud_mobil/presentation/screens/webview_screen.dart';
import 'package:bbzcloud_mobil/presentation/widgets/app_switcher_overlay.dart';
import 'package:bbzcloud_mobil/presentation/widgets/draggable_overlay_button.dart';
import 'package:bbzcloud_mobil/services/chat_bridge.dart';
import 'package:bbzcloud_mobil/services/push_service.dart';

class ChatWebView extends ConsumerStatefulWidget {
  const ChatWebView({super.key});

  @override
  ConsumerState<ChatWebView> createState() => _ChatWebViewState();
}

class _ChatWebViewState extends ConsumerState<ChatWebView> {
  InAppWebViewController? _controller;
  ChatBridge? _bridge;
  double _progress = 0;
  bool _failed = false;
  String? _error;
  bool _showAppSwitcher = false;

  // Avoid replaying setToken / setTheme on every minor reload.
  bool _tokenPushed = false;
  ThemeMode? _lastTheme;

  // Aktuell bekannter `canGoBack`-Wert des WebViews. Wir aktualisieren
  // den Wert bei jedem onUpdateVisitedHistory/onLoadStop, damit PopScope
  // synchron entscheiden kann, ob ein Back-Gesture verbraucht oder
  // an das System weitergegeben wird.
  bool _webCanGoBack = false;

  @override
  Widget build(BuildContext context) {
    // Theme sync: whenever the resolved ThemeMode changes, forward it to
    // the chat. Done via ref.listen so we don't accidentally rebuild the
    // entire WebView.
    ref.listen<ThemeMode>(themeModeProvider, (prev, next) {
      _pushTheme(next);
    });

    // Push deeplinks (set by a push tap, future routing layer, …).
    ref.listen(chatStateProvider.select((s) => s.pendingDeeplink),
        (prev, next) {
      if (next != null && next.isNotEmpty) {
        _bridge?.navigate(next);
        ref.read(chatStateProvider.notifier).consumeDeeplink();
      }
    });

    // The React app fires `bridgeReady` from its very first useEffect.
    // Whichever happens first – onLoadStop or bridgeReady – we want to
    // push the initial state (token + theme) exactly once.
    ref.listen<bool>(chatStateProvider.select((s) => s.ready), (prev, next) {
      if (next == true) {
        _injectInitialBridgeState();
      }
    });

    // StackFit.expand: forces the InAppWebView (non-Positioned child) to
    // fill the available bounds. Without it the WebView reports an
    // ambiguous intrinsic height which produces a white strip at the top
    // that the chat content can scroll under – classic flutter_inappwebview
    // gotcha when nested inside a Stack.
    final canBeIntercepted = _showAppSwitcher || _webCanGoBack;
    return PopScope(
      // canPop=false → wir intercepten Back. Wenn nichts zu intercepten ist
      // (Chat-Startseite, kein Overlay), lassen wir den Pop durch, sodass
      // Android die App regulär in den Hintergrund legt.
      canPop: !canBeIntercepted,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_showAppSwitcher) {
          setState(() => _showAppSwitcher = false);
          return;
        }
        final c = _controller;
        if (c != null && await c.canGoBack()) {
          await c.goBack();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(AppConfig.chatUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            javaScriptCanOpenWindowsAutomatically: false,
            mediaPlaybackRequiresUserGesture: false,
            useHybridComposition: true,
            // The chat needs its own cookies for session resume.
            thirdPartyCookiesEnabled: true,
            cacheEnabled: true,
            supportZoom: false,
            // 110 % macht Schrift und Symbole gut lesbar, ohne dass das
            // Layout bricht. Wert kann via /chat/setTextZoom auf Wunsch
            // weiter erhöht werden, falls jemand mehr braucht.
            textZoom: 110,
            // Transparent background prevents the white strip that the
            // platform draws while the React app boots.
            transparentBackground: true,
            // Auto-grant the React app's getUserMedia() requests so dass
            // Sprachnachrichten und Voice/Video-Calls direkt funktionieren.
            iframeAllow: 'camera; microphone',
            iframeAllowFullscreen: true,
            allowsInlineMediaPlayback: true,
          ),
          onPermissionRequest: (controller, request) async {
            // Auto-grant camera/microphone for the chat domain – the
            // user already trusted us by installing the app.
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT,
            );
          },
          onWebViewCreated: (controller) {
            _controller = controller;
            _bridge = ChatBridge(
              controller: controller,
              ref: ref,
              onLogout: performChatLogout,
            );
            _bridge!.attachHandlers();
          },
          onLoadStart: (_, __) {
            if (mounted) {
              setState(() {
                _progress = 0;
                _failed = false;
                _error = null;
              });
            }
          },
          onProgressChanged: (_, p) {
            if (mounted) {
              setState(() => _progress = p / 100);
            }
          },
          onLoadStop: (controller, url) async {
            if (mounted) setState(() => _progress = 1);
            await _injectInitialBridgeState();
            await _refreshCanGoBack();
          },
          onUpdateVisitedHistory: (controller, url, androidIsReload) async {
            await _refreshCanGoBack();
          },
          onReceivedError: (controller, request, error) {
            logger.warning(
                'ChatWebView load error ${error.type} ${error.description}');
            if (request.isForMainFrame ?? false) {
              if (mounted) {
                setState(() {
                  _failed = true;
                  _error = error.description;
                });
              }
            }
          },
          onReceivedHttpError: (controller, request, response) {
            if ((request.isForMainFrame ?? false) &&
                response.statusCode != null &&
                response.statusCode! >= 500) {
              if (mounted) {
                setState(() {
                  _failed = true;
                  _error = 'HTTP ${response.statusCode}';
                });
              }
            }
          },
          onConsoleMessage: (_, message) {
            if (message.messageLevel == ConsoleMessageLevel.ERROR) {
              logger.warning('Chat console: ${message.message}');
            }
          },
        ),
        if (_progress < 1.0 && !_failed)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 3,
              backgroundColor: Colors.transparent,
            ),
          ),

        // Phone-only: same draggable overlay button that the other
        // WebView apps already use, for visual consistency.
        // Tap → AppSwitcherOverlay (jump to another app).
        // Long-press → open the side drawer (settings, todos, …).
        if (!PlatformUtils.isTablet(context))
          DraggableOverlayButton(
            onTap: () => setState(() => _showAppSwitcher = true),
            onLongPress: () => Scaffold.maybeOf(context)?.openDrawer(),
          ),

        if (_showAppSwitcher)
          AppSwitcherOverlay(
            onAppSelected: (id, title, url, requiresAuth) {
              setState(() => _showAppSwitcher = false);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WebViewScreen(
                    appId: id,
                    title: title,
                    url: url,
                    requiresAuth: requiresAuth,
                  ),
                ),
              );
            },
            // Chat-Tile auf dem Chat-Screen schließt einfach den Switcher
            // und scrollt ggf. an den Anfang. onJumpToChat = no-op.
            onJumpToChat: () {
              setState(() => _showAppSwitcher = false);
              _bridge?.navigate('/');
            },
            onClose: () => setState(() => _showAppSwitcher = false),
          ),

        if (_failed) _ErrorOverlay(message: _error, onRetry: _retry),
        ],
      ),
    );
  }

  Future<void> _injectInitialBridgeState() async {
    final c = _controller;
    final b = _bridge;
    if (c == null || b == null) return;

    // 0. Viewport / Layout Fix: erzwinge volle Höhe und entferne den
    //    weißen Streifen, der manchmal entstand, wenn das React-App
    //    intrinsische Höhe < Viewport meldete.
    await _applyChatLayoutFix();

    // 1. Token-Injection für SSO. Erfolg ist best-effort – ohne Token
    //    zeigt der Chat seinen eigenen Login an, das ist akzeptabel.
    if (!_tokenPushed) {
      final token = await _ensureMobileToken();
      if (token != null && token.isNotEmpty) {
        // 1a) Bridge-Pfad (neue mobile-session API): setToken().
        await b.setToken(token);
        // 1b) Fallback-Pfad: Token auch direkt in localStorage als
        //     `schulchat_token` ablegen. So funktioniert Auto-Login
        //     selbst dann, wenn die mobile-session-Route im Backend
        //     noch nicht ausgerollt ist (BBZ Cloud 2 Pattern).
        await _writeChatLocalStorageToken(token);
        _tokenPushed = true;

        // Nach erfolgreichem SSO auch sicherstellen, dass der FCM-Token
        // serverseitig registriert ist. Bei Returning-Usern ist das der
        // einzige Trigger – das Welcome-Onboarding läuft nur einmal.
        unawaited(PushService.instance.requestPermissionAndRegister());
      } else {
        // 1c) Letzter Versuch: Falls weder mobile-login noch Bridge-Token
        //     funktioniert haben, fülle die React-Loginmaske direkt aus,
        //     wenn wir Credentials haben. Das ist genau das gleiche Pattern,
        //     das die Desktop-App (BBZ Cloud 2) verwendet.
        await _injectDirectChatLogin();
      }
    }

    // 2. Theme synchron halten – beim ersten Boot reicht ein push.
    final mode = ref.read(themeModeProvider);
    await _pushTheme(mode, force: true);
  }

  Future<void> _refreshCanGoBack() async {
    final c = _controller;
    if (c == null) return;
    try {
      final canBack = await c.canGoBack();
      if (mounted && canBack != _webCanGoBack) {
        setState(() => _webCanGoBack = canBack);
      }
    } catch (_) {
      // ignore
    }
  }

  /// Drücke einige CSS-Regeln rein, die garantieren, dass der React-Chat
  /// die volle WebView-Höhe nutzt – egal welche viewport-meta er selbst
  /// setzt. Behebt den weißen Streifen oben + die Mit-Scrollbarkeit
  /// der App.
  Future<void> _applyChatLayoutFix() async {
    final c = _controller;
    if (c == null) return;
    try {
      await c.evaluateJavascript(source: r'''
        (function() {
          // Sicherstellen, dass viewport-meta passt
          let vp = document.querySelector('meta[name=viewport]');
          if (!vp) {
            vp = document.createElement('meta');
            vp.name = 'viewport';
            document.head.appendChild(vp);
          }
          vp.content = 'width=device-width, initial-scale=1.0, viewport-fit=cover, user-scalable=no';

          // CSS: html/body auf 100dvh fixieren, Body nicht scrollen.
          if (!document.getElementById('bbz-chat-layout-fix')) {
            const s = document.createElement('style');
            s.id = 'bbz-chat-layout-fix';
            s.textContent = `
              html, body {
                height: 100% !important;
                min-height: 100% !important;
                margin: 0 !important;
                padding: 0 !important;
                overflow: hidden !important;
                background-color: var(--app-bg, #ffffff);
              }
              body > #root, body > #app, body > .app {
                min-height: 100dvh !important;
                height: 100dvh !important;
              }
            `;
            document.head.appendChild(s);
          }
        })();
      ''');
    } catch (e) {
      logger.warning('Chat layout fix failed: $e');
    }
  }

  /// Schreibt den mobileToken zusätzlich in `localStorage.schulchat_token`,
  /// damit der React-Chat ihn auch direkt verwenden kann (genau wie
  /// BBZ Cloud 2). Sicher: läuft ausschließlich auf der Chat-Domain.
  Future<void> _writeChatLocalStorageToken(String token) async {
    final c = _controller;
    if (c == null) return;
    try {
      await c.evaluateJavascript(source: '''
        (function() {
          try {
            localStorage.setItem('schulchat_token', ${jsonEncode(token)});
          } catch (e) {}
        })();
      ''');
    } catch (e) {
      logger.warning('Chat localStorage token write failed: $e');
    }
  }

  /// Direkter Auto-Login wie in BBZ Cloud 2: ruft `/api/login` aus
  /// dem WebView-Kontext heraus auf, speichert das Token und reloaded.
  Future<void> _injectDirectChatLogin() async {
    final c = _controller;
    if (c == null) return;
    final creds = CredentialService.instance;
    final email = await creds.loadEmail();
    final password = await creds.loadPassword();
    if (email == null || password == null || password.isEmpty) return;
    final securityPassword = await creds.loadSecurityPassword();
    final secPwd =
        (securityPassword != null && securityPassword.isNotEmpty)
            ? securityPassword
            : password;

    try {
      final result = await c.evaluateJavascript(source: '''
        (async function() {
          try {
            const existing = localStorage.getItem('schulchat_token');
            if (existing) {
              try {
                const r = await fetch('/api/me', {
                  headers: { 'Authorization': 'Bearer ' + existing }
                });
                if (r.ok) return 'ALREADY';
                localStorage.removeItem('schulchat_token');
              } catch (e) {
                return 'ALREADY'; // network: trust token
              }
            }
            const res = await fetch('/api/login', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                email: ${jsonEncode(email)},
                password: ${jsonEncode(password)},
                securityPassword: ${jsonEncode(secPwd)}
              })
            });
            if (!res.ok) return 'HTTP_' + res.status;
            const data = await res.json();
            if (data && data.token) {
              localStorage.setItem('schulchat_token', data.token);
              return 'OK';
            }
            return 'NO_TOKEN';
          } catch (e) {
            return 'ERR:' + (e && e.message || 'unknown');
          }
        })()
      ''');
      logger.info('Chat direct-login result: $result');
      if (result == 'OK') {
        _tokenPushed = true;
        // Auch lokal cachen, damit der nächste Start direkt klappt.
        await c.reload();
      } else if (result == 'ALREADY') {
        _tokenPushed = true;
      }
    } catch (e) {
      logger.warning('Chat direct-login failed: $e');
    }
  }

  Future<void> _pushTheme(ThemeMode mode, {bool force = false}) async {
    if (!force && _lastTheme == mode) return;
    _lastTheme = mode;
    final resolved = _resolveBrightness(mode);
    await _bridge?.setTheme(resolved);
  }

  ThemeMode _resolveBrightness(ThemeMode mode) {
    if (mode != ThemeMode.system) return mode;
    final brightness = MediaQuery.maybeOf(context)?.platformBrightness;
    return brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Returns the cached mobile token, or attempts to obtain a new one
  /// from stored credentials. Never throws – on failure returns null.
  Future<String?> _ensureMobileToken() async {
    final creds = CredentialService.instance;
    final cached = await creds.loadChatMobileToken();
    if (cached != null && cached.isNotEmpty) return cached;

    final email = await creds.loadEmail();
    final password = await creds.loadPassword();
    if (email == null || password == null || password.isEmpty) {
      // Kein Passwort gespeichert → der Chat-Login-Screen springt ein.
      return null;
    }

    final securityPassword = await creds.loadSecurityPassword();

    try {
      final token = await ChatAuthService.instance.mobileLogin(
        email: email,
        password: password,
        securityPassword:
            securityPassword?.isNotEmpty == true ? securityPassword : password,
      );
      await creds.saveChatMobileToken(token);
      return token;
    } catch (e) {
      logger.warning('Auto mobile-login failed: $e');
      return null;
    }
  }

  void _retry() {
    setState(() {
      _failed = false;
      _error = null;
      _progress = 0;
      _tokenPushed = false;
    });
    _controller?.loadUrl(
      urlRequest: URLRequest(url: WebUri(AppConfig.chatUrl)),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({this.message, required this.onRetry});
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 56,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Chat nicht erreichbar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message?.isNotEmpty == true
                ? message!
                : 'Bitte prüfe deine Internetverbindung und versuche es erneut.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
}
