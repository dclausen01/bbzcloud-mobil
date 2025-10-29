/// BBZCloud Mobile - Embedded WebView Widget
/// 
/// Reusable WebView widget that can be used both in:
/// - WebViewScreen (fullscreen on phones)
/// - Embedded in HomeScreen (on tablets)
/// 
/// @version 0.1.0

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bbzcloud_mobil/core/utils/app_logger.dart';
import 'package:bbzcloud_mobil/data/services/credential_service.dart';
import 'package:bbzcloud_mobil/services/injection_scripts.dart';
import 'package:bbzcloud_mobil/services/download_service.dart';
import 'package:bbzcloud_mobil/presentation/providers/webview_stack_provider.dart';
import 'package:bbzcloud_mobil/presentation/providers/current_webview_provider.dart';
import 'package:bbzcloud_mobil/presentation/widgets/draggable_overlay_button.dart';
import 'package:bbzcloud_mobil/presentation/widgets/app_switcher_overlay.dart';

class EmbeddedWebViewWidget extends ConsumerStatefulWidget {
  final String title;
  final String url;
  final bool requiresAuth;
  final String? appId;
  final bool showAppBar;
  final bool showBottomBar;
  final VoidCallback? onHomePressed;

  const EmbeddedWebViewWidget({
    super.key,
    required this.title,
    required this.url,
    this.requiresAuth = false,
    this.appId,
    this.showAppBar = true,
    this.showBottomBar = true,
    this.onHomePressed,
  });

  @override
  ConsumerState<EmbeddedWebViewWidget> createState() =>
      _EmbeddedWebViewWidgetState();
}

class _EmbeddedWebViewWidgetState
    extends ConsumerState<EmbeddedWebViewWidget> {
  InAppWebViewController? _webViewController;
  double _loadingProgress = 0;
  String? _currentUrl;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _showAppSwitcher = false;
  bool _webuntisPhase1Done = false;
  bool _webuntisLoginTriggered = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isInjecting = false;

  @override
  void initState() {
    super.initState();
    _addToStack();
  }

  void _addToStack() {
    if (widget.appId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(webViewStackProvider.notifier).addOrUpdateWebView(
              id: widget.appId!,
              title: widget.title,
              url: widget.url,
              requiresAuth: widget.requiresAuth,
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Optional AppBar
        if (widget.showAppBar) _buildAppBar(),

        // Loading Progress Bar
        if (_loadingProgress < 1.0)
          LinearProgressIndicator(
            value: _loadingProgress,
            minHeight: 3,
          ),

        // WebView
        Expanded(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(widget.url),
                ),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  javaScriptCanOpenWindowsAutomatically: true,
                  mediaPlaybackRequiresUserGesture: false,
                  useHybridComposition: true,
                  allowFileAccessFromFileURLs: false,
                  allowUniversalAccessFromFileURLs: false,
                  userAgent: _getUserAgentForApp(widget.appId),
                  initialScale: _getInitialScaleForApp(widget.appId),
                  thirdPartyCookiesEnabled: true,
                  cacheEnabled: true,
                  clearCache: false,
                  incognito: false,
                  disableContextMenu: false,
                  supportZoom: true,
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;

                  controller.addJavaScriptHandler(
                    handlerName: 'loginComplete',
                    callback: (args) {
                      if (mounted && _isInjecting) {
                        setState(() {
                          _isInjecting = false;
                        });
                        logger.info(
                            'Login complete signal received from JavaScript');
                      }
                      return {'success': true};
                    },
                  );
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final url = navigationAction.request.url;

                  if (widget.appId?.toLowerCase() == 'bbb' && url != null) {
                    if (_isBBBMeetingLink(url.toString())) {
                      logger.info(
                          'BBB Meeting link detected, opening in system browser');
                      await _openInSystemBrowser(url.toString());
                      return NavigationActionPolicy.CANCEL;
                    }
                  }

                  if (widget.appId?.toLowerCase() == 'schulcloud' &&
                      url != null) {
                    if (_isSchulcloudDownloadLink(url.toString())) {
                      logger.info(
                          'schul.cloud download link detected, opening in system browser');
                      await _openInSystemBrowser(url.toString());
                      return NavigationActionPolicy.CANCEL;
                    }
                  }

                  return NavigationActionPolicy.ALLOW;
                },
                onLoadStart: (controller, url) async {
                  setState(() {
                    _currentUrl = url.toString();
                    _loadingProgress = 0;
                  });
                },
                onLoadStop: (controller, url) async {
                  setState(() {
                    _loadingProgress = 1.0;
                    _currentUrl = url.toString();
                  });

                  _updateNavigationButtons();

                  if (widget.requiresAuth && !_isInjecting) {
                    setState(() {
                      _isInjecting = true;
                    });
                  }

                  if (widget.appId?.toLowerCase() == 'webuntis') {
                    await _handleWebUntisFlow(controller, url.toString());
                  } else {
                    if (widget.appId != null) {
                      await _runPostLoadScript(controller);
                    }

                    if (widget.requiresAuth) {
                      await _injectAuthScript(controller);
                    }
                  }

                  if (widget.requiresAuth) {
                    await Future.delayed(const Duration(milliseconds: 500));
                    if (mounted) {
                      setState(() {
                        _isInjecting = false;
                      });
                    }
                  }
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    _loadingProgress = progress / 100;
                  });
                },
                onUpdateVisitedHistory: (controller, url, androidIsReload) {
                  _updateNavigationButtons();
                },
                onDownloadStartRequest: (controller, request) async {
                  if (widget.appId?.toLowerCase() == 'schulcloud') {
                    logger.info(
                        'schul.cloud download - skipping onDownloadStartRequest');
                    return;
                  }

                  await _handleDownload(request);
                },
                onConsoleMessage: (controller, consoleMessage) {
                  debugPrint('Console: ${consoleMessage.message}');
                },
              ),

              // Draggable Overlay Button
              DraggableOverlayButton(
                onTap: () {
                  setState(() {
                    _showAppSwitcher = true;
                  });
                },
                onLongPress: () {
                  ref.read(webViewStackProvider.notifier).clearCurrent();
                  if (widget.onHomePressed != null) {
                    widget.onHomePressed!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),

              // App Switcher Overlay
              if (_showAppSwitcher)
                AppSwitcherOverlay(
                  onAppSelected: (id, title, url, requiresAuth) {
                    setState(() {
                      _showAppSwitcher = false;
                    });
                    _switchToApp(id, title, url, requiresAuth);
                  },
                  onClose: () {
                    setState(() {
                      _showAppSwitcher = false;
                    });
                  },
                ),

              // Auth Injection Loading Overlay
              if (_isInjecting && widget.requiresAuth)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Laden...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Optional Bottom Navigation Bar
        if (widget.showBottomBar) _buildBottomBar(),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'open_browser':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('In externem Browser öffnen')),
                  );
                  break;
                case 'copy_url':
                  if (_currentUrl != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('URL kopiert')),
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'open_browser',
                child: Row(
                  children: [
                    Icon(Icons.open_in_browser),
                    SizedBox(width: 8),
                    Text('Im Browser öffnen'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy_url',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('URL kopieren'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _canGoBack ? () => _webViewController?.goBack() : null,
            tooltip: 'Zurück',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed:
                _canGoForward ? () => _webViewController?.goForward() : null,
            tooltip: 'Vorwärts',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController?.reload(),
            tooltip: 'Neu laden',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              ref.read(webViewStackProvider.notifier).clearCurrent();
              if (widget.onHomePressed != null) {
                widget.onHomePressed!();
              } else {
                Navigator.of(context).pop();
              }
            },
            tooltip: 'Zur Startseite',
          ),
        ],
      ),
    );
  }

  void _switchToApp(String id, String title, String url, bool requiresAuth) {
    if (id == widget.appId) {
      return;
    }

    // Check if we have onHomePressed callback (indicates embedded mode on tablet)
    if (widget.onHomePressed != null) {
      // Tablet embedded mode: Update provider instead of navigating
      ref.read(currentWebViewProvider.notifier).showWebView(
        appId: id,
        title: title,
        url: url,
        requiresAuth: requiresAuth,
      );
    } else {
      // Phone fullscreen mode: Navigate to new screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            body: EmbeddedWebViewWidget(
              appId: id,
              title: title,
              url: url,
              requiresAuth: requiresAuth,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _updateNavigationButtons() async {
    if (_webViewController != null) {
      final canGoBack = await _webViewController!.canGoBack();
      final canGoForward = await _webViewController!.canGoForward();

      if (mounted) {
        setState(() {
          _canGoBack = canGoBack;
          _canGoForward = canGoForward;
        });
      }
    }
  }

  Future<void> _injectAuthScript(InAppWebViewController controller) async {
    final timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isInjecting) {
        setState(() {
          _isInjecting = false;
        });
        logger.warning(
            'Auth injection timeout - overlay force-hidden after 5 seconds');
      }
    });

    try {
      final credentials = await CredentialService.instance.loadCredentials();

      if (!credentials.hasBasicCredentials) {
        logger.warning('No credentials available for auto-fill');
        return;
      }

      final String? injectionScript = InjectionScripts.getInjectionForApp(
        widget.appId ?? '',
        credentials.email!,
        credentials.password ?? '',
        bbbPassword: credentials.bbbPassword,
        webuntisEmail: credentials.webuntisEmail,
        webuntisPassword: credentials.webuntisPassword,
      );

      if (injectionScript != null) {
        await controller.evaluateJavascript(source: injectionScript);
        logger.info(
            'App-specific auth script injected for ${widget.title} (${widget.appId})');
      }
    } catch (error, stackTrace) {
      logger.error('Error injecting auth script', error, stackTrace);
    } finally {
      timeoutTimer.cancel();
    }
  }

  Future<void> _runPostLoadScript(InAppWebViewController controller) async {
    try {
      final postLoadScript =
          InjectionScripts.getPostLoadScriptForApp(widget.appId!);

      if (postLoadScript != null) {
        if (postLoadScript.delay > 0) {
          await Future.delayed(Duration(milliseconds: postLoadScript.delay));
        }

        await controller.evaluateJavascript(source: postLoadScript.js);
        logger.info(
            'Post-load script executed for ${widget.title}: ${postLoadScript.description}');
      }
    } catch (error, stackTrace) {
      logger.error('Error running post-load script', error, stackTrace);
    }
  }

  Future<void> _handleWebUntisFlow(
      InAppWebViewController controller, String url) async {
    try {
      await _applyWebUntisPersistentZoom(controller);

      final isLoginPage = url.contains('login') || !url.contains('today');

      if (isLoginPage && !_webuntisPhase1Done) {
        logger.info('WebUntis: Starting Phase 1 (close initial dialog)');
        await _runPostLoadScript(controller);
        _webuntisPhase1Done = true;

        if (widget.requiresAuth && !_webuntisLoginTriggered) {
          logger.info('WebUntis: Starting Phase 2 (credential injection)');
          await Future.delayed(const Duration(milliseconds: 800));
          await _injectAuthScript(controller);
          _webuntisLoginTriggered = true;
        }
      } else if (!isLoginPage && _webuntisLoginTriggered) {
        logger.info('WebUntis: URL indicates logged in, verifying page is ready...');

        await Future.delayed(const Duration(milliseconds: 2000));

        final isPageReady = await controller.evaluateJavascript(source: '''
          (function() {
            const hasToday = document.querySelector('.today, [class*="today"]');
            const hasCalendar = document.querySelector('.calendar, [class*="calendar"]');
            const hasTimetable = document.querySelector('.timetable, [class*="timetable"]');
            const hasMainContent = document.querySelector('.main-content, main, [role="main"]');
            const loginForm = document.querySelector('.un2-login-form');
            const noLoginForm = !loginForm;
            const isReady = (hasToday || hasCalendar || hasTimetable || hasMainContent) && noLoginForm;
            return isReady;
          })()
        ''');

        if (isPageReady == true) {
          logger.info('WebUntis: Page ready confirmed, starting Phase 2 & 3 (close overlays)');

          final phase2Script = InjectionScripts.webuntisPhase2Injection;
          await controller.evaluateJavascript(source: phase2Script.js);
          logger.info('WebUntis: Phase 2 completed');

          await Future.delayed(const Duration(milliseconds: 500));
          final phase3Script = InjectionScripts.webuntisPhase3Injection;
          await controller.evaluateJavascript(source: phase3Script.js);
          logger.info('WebUntis: Phase 3 monitoring started');

          _webuntisLoginTriggered = false;
          _webuntisPhase1Done = false;
        } else {
          logger.warning(
              'WebUntis: Page not ready yet, skipping Phase 2 & 3');
        }
      }
    } catch (error, stackTrace) {
      logger.error('Error in WebUntis flow', error, stackTrace);
    }
  }

  Future<void> _applyWebUntisPersistentZoom(
      InAppWebViewController controller) async {
    try {
      await controller.evaluateJavascript(source: '''
        (function() {
          if (!document.getElementById('bbzcloud-webuntis-zoom')) {
            const style = document.createElement('style');
            style.id = 'bbzcloud-webuntis-zoom';
            style.textContent = `
              body {
                zoom: 1.5;
                -moz-transform: scale(1.5);
                -moz-transform-origin: 0 0;
              }
            `;
            document.head.appendChild(style);
          }
        })();
      ''');
    } catch (error, stackTrace) {
      logger.error('Error applying WebUntis zoom', error, stackTrace);
    }
  }

  String _getFilenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);

      if (uri.pathSegments.isNotEmpty) {
        final lastSegment = uri.pathSegments.last;
        if (lastSegment.contains('.') && !lastSegment.endsWith('.')) {
          final decoded = Uri.decodeComponent(lastSegment);
          logger.info('Extracted filename from URL: $decoded');
          return decoded;
        }
      }

      if (uri.queryParameters.containsKey('file')) {
        final fileParam = uri.queryParameters['file']!;
        if (fileParam.isNotEmpty) {
          logger.info('Extracted filename from query param: $fileParam');
          return fileParam;
        }
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fallback = 'download_$timestamp';
      logger.warning('Could not extract filename from URL, using: $fallback');
      return fallback;
    } catch (e) {
      logger.error('Error extracting filename from URL', e);
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> _handleDownload(DownloadStartRequest request) async {
    try {
      logger.info('=== DOWNLOAD REQUEST START ===');
      logger.info('URL: ${request.url}');

      if (mounted) {
        setState(() {
          _isDownloading = true;
          _downloadProgress = 0.0;
        });
      }

      String filename;
      if (request.suggestedFilename != null &&
          request.suggestedFilename!.isNotEmpty &&
          request.suggestedFilename != 'null' &&
          !request.suggestedFilename!.endsWith('.bin')) {
        filename = request.suggestedFilename!;
      } else {
        filename = _getFilenameFromUrl(request.url.toString());
      }

      final Map<String, String> headers = {};
      final userAgent = _getUserAgentForApp(widget.appId);
      headers['User-Agent'] = userAgent;

      if (_currentUrl != null) {
        headers['Referer'] = _currentUrl!;
      }

      if (_webViewController != null) {
        final cookieManager = CookieManager.instance();
        final cookies = await cookieManager.getCookies(url: request.url);
        if (cookies.isNotEmpty) {
          final cookieString =
              cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
          headers['Cookie'] = cookieString;
        }
      }

      final downloadRequest = DownloadRequest(
        url: request.url.toString(),
        filename: filename,
        headers: headers.isNotEmpty ? headers : null,
      );

      final downloadService = DownloadService();

      if (mounted) {
        await downloadService.downloadFile(
          context: context,
          request: downloadRequest,
          onProgress: (received, total) {
            if (mounted && total > 0) {
              final progress = received / total;
              setState(() {
                _downloadProgress = progress;
              });
            }
          },
        );
      }

      logger.info('=== DOWNLOAD COMPLETED ===');
    } catch (error, stackTrace) {
      logger.error('=== DOWNLOAD FAILED ===', error, stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download fehlgeschlagen: ${error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  bool _isBBBMeetingLink(String url) {
    return url.contains('bbb.bbz-rd-eck.de/bigbluebutton/api/join?') ||
        url.contains('meet.stashcat.com');
  }

  bool _isSchulcloudDownloadLink(String url) {
    return url.contains('api.stashcat.com/file/download') ||
        url.contains('/file/download?id=');
  }

  Future<void> _openInSystemBrowser(String url) async {
    try {
      final uri = Uri.parse(url);

      String message;
      if (widget.appId?.toLowerCase() == 'schulcloud') {
        message = 'Download wird im System-Browser geöffnet...';
      } else {
        message = 'BBB-Konferenz wird im System-Browser geöffnet...';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        logger.info('Opened in system browser: $url');
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (error, stackTrace) {
      logger.error('Error opening system browser', error, stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Öffnen des System-Browsers'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getUserAgentForApp(String? appId) {
    if (appId?.toLowerCase() == 'webuntis' ||
        appId?.toLowerCase() == 'schulcloud') {
      return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    }

    return 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 BBZCloud/1.0';
  }

  int _getInitialScaleForApp(String? appId) {
    if (appId?.toLowerCase() == 'webuntis') {
      return 150;
    }
    return 100;
  }

  @override
  void dispose() {
    _webViewController = null;
    super.dispose();
  }
}
