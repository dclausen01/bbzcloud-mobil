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
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

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
import 'package:bbzcloud_mobil/services/app_icon_badge.dart';
import 'package:bbzcloud_mobil/services/chat_bridge.dart';
import 'package:bbzcloud_mobil/services/download_service.dart';
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

    // Zoom-Setting: Auf Wertänderung den WebView neu skalieren.
    ref.listen<int>(webviewZoomProvider, (prev, next) {
      _applyZoom(next);
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
    return PopScope(
      // canPop=false → wir interceptn IMMER. So funktioniert auch die
      // Edge-Swipe-Geste (Android 13+ Predictive Back, dafür braucht es
      // android:enableOnBackInvokedCallback="true" im Manifest).
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_showAppSwitcher) {
          setState(() => _showAppSwitcher = false);
          return;
        }
        final c = _controller;
        if (c == null) {
          await SystemNavigator.pop();
          return;
        }

        // 0) Schnellpfad: Wenn das React-Frontend ueber notifyRouteChange
        //    gemeldet hat, dass wir auf der Root-Sicht sind, koennen wir
        //    den JS-Round-Trip sparen und direkt in den Hintergrund.
        //    (Modals/Bottom-Sheets aendern den Pfad nicht, also gilt das
        //    nur fuer Top-Level Root-Sicht ohne offenes Overlay.)
        final path = ref.read(chatStateProvider).currentPath;
        if (path == '/') {
          // Trotzdem 1x handleBack fragen - falls ein Modal offen ist,
          // soll der React-Chat das selbst schliessen koennen.
          try {
            final res = await c.evaluateJavascript(source:
                "(function(){try{return !!(window.bbzChat && typeof window.bbzChat.handleBack==='function' && window.bbzChat.handleBack());}catch(e){return false}})()");
            if (res == true || res == 'true') return;
          } catch (_) {}
          await SystemNavigator.pop();
          return;
        }

        // 1) React-Chat zuerst fragen, ob er den Back-Event selbst
        //    konsumieren will (Conversation schliessen, Modal zu, ...).
        try {
          final res = await c.evaluateJavascript(source:
              "(function(){try{return !!(window.bbzChat && typeof window.bbzChat.handleBack==='function' && window.bbzChat.handleBack());}catch(e){return false}})()");
          if (res == true || res == 'true') {
            return; // React hat den Back konsumiert.
          }
        } catch (_) {
          // ignore - fallback auf native History.
        }

        // 2) Native WebView-History (klassische href-Navigation).
        if (await c.canGoBack()) {
          await c.goBack();
          return;
        }

        // 3) Top-Level: App in den Hintergrund.
        await SystemNavigator.pop();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(AppConfig.chatUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            // true, damit der Chat per window.open() Datei-Previews
            // aufmachen kann. Wir fangen das via onCreateWindow ab und
            // oeffnen es in einer in-app WebView (oder bei Downloads
            // direkt im DownloadService).
            javaScriptCanOpenWindowsAutomatically: true,
            supportMultipleWindows: true,
            mediaPlaybackRequiresUserGesture: false,
            useHybridComposition: true,
            // The chat needs its own cookies for session resume.
            thirdPartyCookiesEnabled: true,
            cacheEnabled: true,
            supportZoom: false,
            // Initial-Zoom aus Settings (Default 110%). Änderungen
            // werden zur Laufzeit via _applyZoom() reingedrückt.
            textZoom: ref.read(webviewZoomProvider),
            // Transparent background prevents the white strip that the
            // platform draws while the React app boots.
            transparentBackground: true,
            // Auto-grant der React-App getUserMedia()-Requests fuer
            // Sprachnachrichten und Voice/Video-Calls (s. onPermissionRequest).
            iframeAllow: 'camera; microphone',
            iframeAllowFullscreen: true,
            allowsInlineMediaPlayback: true,
            // Downloads aktivieren - sonst feuert onDownloadStartRequest
            // gar nicht.
            useOnDownloadStart: true,
          ),
          onPermissionRequest: (controller, request) async {
            // Bevor wir dem WebView GRANT zurückgeben, müssen die
            // App-Level-Permissions auf OS-Ebene tatsächlich vorhanden
            // sein – sonst nutzt unser GRANT nichts und getUserMedia()
            // schlägt fehl ("Mikrofonzugriff verweigert").
            await _ensureMediaPermissions(request.resources);
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT,
            );
          },
          onDownloadStartRequest: (controller, request) async {
            // Klassische "Content-Disposition: attachment"-Downloads
            // oder <a href="..." download> Klicks.
            await _handleDownload(request);
          },
          onCreateWindow: (controller, createWindowAction) async {
            // window.open() / target=_blank: zB. fuer Bild-/PDF-Previews.
            // Wir oeffnen das in einer in-app WebView, die selber
            // Downloads + Bilder anzeigen kann - statt im System-Browser.
            final url = createWindowAction.request.url?.toString();
            if (url == null || url.isEmpty) return false;
            _openInAppPreview(url);
            return true; // wir haben uebernommen
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

    // Chat ist offen → OS-Icon-Badge zuruecksetzen. Der React-Chat
    // sendet `setBadge(n)` ueber die Bridge sobald er Unread-Counts
    // neu berechnet hat; bis dahin ist 0 das sinnvolle Default.
    unawaited(AppIconBadge.clear());

    // 0. Viewport / Layout Fix: erzwinge volle Höhe und entferne den
    //    weißen Streifen, der manchmal entstand, wenn das React-App
    //    intrinsische Höhe < Viewport meldete.
    await _applyChatLayoutFix();

    // 1. Token-Injection für SSO. Erfolg ist best-effort – ohne Token
    //    zeigt der Chat seinen eigenen Login an, das ist akzeptabel.
    if (!_tokenPushed) {
      final token = await _ensureMobileToken();
      if (token != null && token.isNotEmpty) {
        // Bridge-Pfad: setToken() triggert serverseitig
        // /api/auth/mobile-session und liefert dem React-Client den
        // Session-Token, der dann in localStorage.schulchat_token landet
        // und fuer SSE/Cookies verwendet wird.
        //
        // WICHTIG: Wir schreiben den mobileToken NICHT mehr selbst in
        // localStorage.schulchat_token - das war ein Fallback aus der Zeit
        // vor mobile-session und ist seit dem Server-Fix aktiv schaedlich:
        // der React-Client wuerde den 64-Hex-mobileToken als Session-Token
        // interpretieren und damit eine EventSource zu /api/events oeffnen
        // -> Server lehnt mit "Invalid token format" ab, Doppel-Connect,
        // unnoetiges Log-Rauschen.
        await b.setToken(token);
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

    // 3. Pending Deeplink abholen, falls schon einer ansteht.
    //    Beim Cold-Start (App ueber Notification-Tap gestartet) wird
    //    requestDeeplink() VOR dem ersten WebView-Mount aufgerufen,
    //    bevor unser ref.listen aktiv ist - der initiale Wert wird
    //    also nicht gemeldet. Hier holen wir ihn einmal nach.
    final pending = ref.read(chatStateProvider).pendingDeeplink;
    if (pending != null && pending.isNotEmpty) {
      logger.info('Replaying pending deeplink: $pending');
      await b.navigate(pending);
      ref.read(chatStateProvider.notifier).consumeDeeplink();
    }
  }

  /// Fordert die Android/iOS-System-Permissions an, die vom WebView
  /// als nächstes verwendet werden sollen.
  Future<void> _ensureMediaPermissions(
      List<PermissionResourceType> resources) async {
    final toRequest = <ph.Permission>{};
    for (final r in resources) {
      final id = r.toString().toUpperCase();
      if (id.contains('AUDIO') || id.contains('MICROPHONE')) {
        toRequest.add(ph.Permission.microphone);
      }
      if (id.contains('VIDEO') || id.contains('CAMERA')) {
        toRequest.add(ph.Permission.camera);
      }
    }
    for (final p in toRequest) {
      try {
        final status = await p.status;
        if (!status.isGranted) {
          await p.request();
        }
      } catch (e) {
        logger.warning('Permission request failed for $p: $e');
      }
    }
  }

  /// Klick auf <a download> oder Datei mit Content-Disposition: attachment.
  /// Wir nutzen den selben DownloadService wie die EmbeddedWebView.
  /// Cookies werden mitgegeben, damit das Chat-Session-Cookie greift.
  Future<void> _handleDownload(DownloadStartRequest request) async {
    final c = _controller;
    try {
      final headers = <String, String>{};
      if (c != null) {
        try {
          final cookies = await CookieManager.instance().getCookies(
            url: request.url,
          );
          if (cookies.isNotEmpty) {
            headers['Cookie'] = cookies
                .map((cookie) => '${cookie.name}=${cookie.value}')
                .join('; ');
          }
        } catch (_) {}
      }
      String? filename = request.suggestedFilename;
      if (filename == null ||
          filename.isEmpty ||
          filename == 'null' ||
          filename.endsWith('.bin')) {
        filename = _filenameFromUrl(request.url.toString());
      }
      final dl = DownloadRequest(
        url: request.url.toString(),
        filename: filename,
        headers: headers.isNotEmpty ? headers : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download startet: $filename'),
          duration: const Duration(seconds: 2),
        ),
      );
      await DownloadService().downloadFile(
        context: context,
        request: dl,
      );
    } catch (e, st) {
      logger.error('Chat-Download fehlgeschlagen', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download fehlgeschlagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _filenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last;
        if (last.contains('.') && !last.endsWith('.')) {
          return Uri.decodeComponent(last);
        }
      }
      if (uri.queryParameters.containsKey('filename')) {
        return uri.queryParameters['filename']!;
      }
    } catch (_) {}
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// In-app Preview-WebView fuer window.open() / target=_blank.
  /// Bekommt vom Parent Cookies + User-Agent uebergeben, damit
  /// authentifizierte Datei-Previews und Downloads funktionieren.
  void _openInAppPreview(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewScreen(
          appId: 'chat_preview',
          title: 'Vorschau',
          url: url,
          requiresAuth: false,
        ),
      ),
    );
  }

  Future<void> _applyZoom(int zoom) async {
    final c = _controller;
    if (c == null) return;
    try {
      await c.setSettings(
        settings: InAppWebViewSettings(textZoom: zoom),
      );
    } catch (e) {
      logger.warning('Chat applyZoom failed: $e');
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

  /// Direkter Auto-Login wie in BBZ Cloud 2: ruft `/api/login` aus
  /// dem WebView-Kontext heraus auf, speichert das Token und reloaded.
  /// Holt zusätzlich das Token zurück nach Flutter, damit wir es als
  /// Bearer für /api/push-tokens benutzen können.
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
      // Rückgabewerte:
      //   "ALREADY:<token>"  – schon eingeloggt, Token aus localStorage
      //   "OK:<token>"       – frisch eingeloggt
      //   "HTTP_<status>"    – API-Fehler
      //   "NO_TOKEN"         – Response ohne Token
      //   "ERR:<msg>"        – Exception
      final result = await c.evaluateJavascript(source: '''
        (async function() {
          try {
            const existing = localStorage.getItem('schulchat_token');
            if (existing) {
              try {
                const r = await fetch('/api/me', {
                  headers: { 'Authorization': 'Bearer ' + existing }
                });
                if (r.ok) return 'ALREADY:' + existing;
                localStorage.removeItem('schulchat_token');
              } catch (e) {
                return 'ALREADY:' + existing; // network: trust token
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
              return 'OK:' + data.token;
            }
            return 'NO_TOKEN';
          } catch (e) {
            return 'ERR:' + (e && e.message || 'unknown');
          }
        })()
      ''');
      final str = result?.toString() ?? '';
      logger.info('Chat direct-login result: ${str.startsWith('OK:') || str.startsWith('ALREADY:') ? str.substring(0, str.indexOf(':') + 1) + '<token>' : str}');

      String? sessionToken;
      if (str.startsWith('OK:')) {
        sessionToken = str.substring(3);
      } else if (str.startsWith('ALREADY:')) {
        sessionToken = str.substring(8);
      }

      if (sessionToken != null && sessionToken.isNotEmpty) {
        _tokenPushed = true;
        // Der Direct-Flow hat die WebView/React-Seite eingeloggt
        // (localStorage.schulchat_token ist gesetzt). Fuer Push brauchen
        // wir aber den 64-Hex `mobileToken` aus /api/auth/mobile-login -
        // den holen wir jetzt separat. Falls das fehlschlaegt: kein Push,
        // aber Chat selbst funktioniert weiter.
        await _fetchAndStoreMobileToken();

        if (str.startsWith('OK:')) {
          await c.reload();
        }
      }
    } catch (e) {
      logger.warning('Chat direct-login failed: $e');
    }
  }

  /// Holt /api/auth/mobile-login und cached den zurueckgegebenen
  /// `mobileToken`. Wird erst nach erfolgreichem Direct-Login (oder beim
  /// Boot, wenn das Token im Cache als ungueltig erkannt wurde) aufgerufen.
  /// Loest danach die Push-Registrierung aus.
  Future<void> _fetchAndStoreMobileToken() async {
    final creds = CredentialService.instance;
    final email = await creds.loadEmail();
    final password = await creds.loadPassword();
    if (email == null || password == null || password.isEmpty) return;
    final securityPassword = await creds.loadSecurityPassword();
    try {
      final token = await ChatAuthService.instance.mobileLogin(
        email: email,
        password: password,
        securityPassword:
            (securityPassword?.isNotEmpty ?? false) ? securityPassword : password,
      );
      await creds.saveChatMobileToken(token);
      logger.info('mobile-login OK (mobileToken len=${token.length})');
      unawaited(PushService.instance.requestPermissionAndRegister());
    } catch (e) {
      logger.warning('mobile-login refresh failed: $e');
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
    if (cached != null && _looksLikeMobileToken(cached)) return cached;

    if (cached != null && cached.isNotEmpty) {
      // Cache enthielt aelteres Schrott-Token (z.B. ein
      // schulchat_token, das frueher faelschlich hier abgelegt wurde).
      logger.info('Discarding cached non-mobile-token (len=${cached.length})');
      await creds.deleteChatMobileToken();
    }

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

  /// Heuristik fuer echte mobileToken-Strings (vom Server geliefert):
  /// 64 hexadezimale Zeichen (AES-256-GCM-blob hex). Session-Tokens
  /// und Schul.cloud-Tokens enthalten ":" und sind deutlich laenger.
  static bool _looksLikeMobileToken(String s) {
    if (s.length != 64) return false;
    final hex = RegExp(r'^[0-9a-fA-F]+$');
    return hex.hasMatch(s);
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
