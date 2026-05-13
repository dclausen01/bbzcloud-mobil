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
    return Stack(
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
          ),
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
            onClose: () => setState(() => _showAppSwitcher = false),
          ),

        if (_failed) _ErrorOverlay(message: _error, onRetry: _retry),
      ],
    );
  }

  Future<void> _injectInitialBridgeState() async {
    final c = _controller;
    final b = _bridge;
    if (c == null || b == null) return;

    // 1. Token-Injection für SSO. Erfolg ist best-effort – ohne Token
    //    zeigt der Chat seinen eigenen Login an, das ist akzeptabel.
    if (!_tokenPushed) {
      final token = await _ensureMobileToken();
      if (token != null && token.isNotEmpty) {
        await b.setToken(token);
        _tokenPushed = true;
      }
    }

    // 2. Theme synchron halten – beim ersten Boot reicht ein push.
    final mode = ref.read(themeModeProvider);
    await _pushTheme(mode, force: true);
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
