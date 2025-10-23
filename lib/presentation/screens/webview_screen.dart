/// BBZCloud Mobile - WebView Screen
/// 
/// Screen for displaying web apps with JavaScript injection and app switcher
/// 
/// @version 0.2.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bbzcloud_mobil/core/utils/app_logger.dart';
import 'package:bbzcloud_mobil/data/services/credential_service.dart';
import 'package:bbzcloud_mobil/services/injection_scripts.dart';
import 'package:bbzcloud_mobil/services/download_service.dart';
import 'package:bbzcloud_mobil/presentation/providers/webview_stack_provider.dart';
import 'package:bbzcloud_mobil/presentation/widgets/draggable_overlay_button.dart';
import 'package:bbzcloud_mobil/presentation/widgets/app_switcher_overlay.dart';

class WebViewScreen extends ConsumerStatefulWidget {
  final String title;
  final String url;
  final bool requiresAuth;
  final String? appId;

  const WebViewScreen({
    super.key,
    required this.title,
    required this.url,
    this.requiresAuth = false,
    this.appId,
  });

  @override
  ConsumerState<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends ConsumerState<WebViewScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Download indicator
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    value: _downloadProgress > 0 ? _downloadProgress : null,
                    strokeWidth: 2.5,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'open_browser':
                  // TODO: Open in external browser
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('In externem Browser öffnen')),
                  );
                  break;
                case 'copy_url':
                  if (_currentUrl != null) {
                    // TODO: Copy to clipboard
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
      body: Stack(
        children: [
          Column(
            children: [
              // Loading Progress Bar
              if (_loadingProgress < 1.0)
                LinearProgressIndicator(
                  value: _loadingProgress,
                  minHeight: 3,
                ),
              
              // WebView
              Expanded(
                child: InAppWebView(
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
                    userAgent: 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 BBZCloud/1.0',
                    // Session persistence settings for schul.cloud and other apps
                    thirdPartyCookiesEnabled: true,
                    cacheEnabled: true,
                    clearCache: false,
                    incognito: false,
                  ),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    final url = navigationAction.request.url;
                    
                    // BBB Meeting-Link Detection: Open in system browser
                    if (widget.appId?.toLowerCase() == 'bbb' && url != null) {
                      if (_isBBBMeetingLink(url.toString())) {
                        logger.info('BBB Meeting link detected, opening in system browser');
                        await _openInSystemBrowser(url.toString());
                        // Stop WebView navigation
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
                    
                    // WebUntis special handling
                    if (widget.appId?.toLowerCase() == 'webuntis') {
                      await _handleWebUntisFlow(controller, url.toString());
                    } else {
                      // Standard flow for other apps
                      if (widget.appId != null) {
                        await _runPostLoadScript(controller);
                      }
                      
                      if (widget.requiresAuth) {
                        await _injectAuthScript(controller);
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
                    // Handle download request using DownloadService
                    await _handleDownload(request);
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    debugPrint('Console: ${consoleMessage.message}');
                  },
                ),
              ),
            ],
          ),

          // Draggable Overlay Button
          DraggableOverlayButton(
            onTap: () {
              setState(() {
                _showAppSwitcher = true;
              });
            },
            onLongPress: () {
              // Long press: Go back to home
              ref.read(webViewStackProvider.notifier).clearCurrent();
              Navigator.of(context).pop();
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
        ],
      ),
      bottomNavigationBar: BottomAppBar(
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
              onPressed: _canGoForward ? () => _webViewController?.goForward() : null,
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
                Navigator.of(context).pop();
              },
              tooltip: 'Zur Startseite',
            ),
          ],
        ),
      ),
    );
  }

  /// Switch to another app
  void _switchToApp(String id, String title, String url, bool requiresAuth) {
    // Check if switching to same app
    if (id == widget.appId) {
      return;
    }

    // Replace current screen with new WebView
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          appId: id,
          title: title,
          url: url,
          requiresAuth: requiresAuth,
        ),
      ),
    );
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
    try {
      final credentials = await CredentialService.instance.loadCredentials();
      
      if (!credentials.hasBasicCredentials) {
        logger.warning('No credentials available for auto-fill');
        return;
      }

      // Get app-specific injection script
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
        logger.info('App-specific auth script injected for ${widget.title} (${widget.appId})');
      }
    } catch (error, stackTrace) {
      logger.error('Error injecting auth script', error, stackTrace);
    }
  }

  Future<void> _runPostLoadScript(InAppWebViewController controller) async {
    try {
      final postLoadScript = InjectionScripts.getPostLoadScriptForApp(widget.appId!);
      
      if (postLoadScript != null) {
        // Wait for the specified delay before running the script
        if (postLoadScript.delay > 0) {
          await Future.delayed(Duration(milliseconds: postLoadScript.delay));
        }
        
        await controller.evaluateJavascript(source: postLoadScript.js);
        logger.info('Post-load script executed for ${widget.title}: ${postLoadScript.description}');
      }
    } catch (error, stackTrace) {
      logger.error('Error running post-load script', error, stackTrace);
    }
  }

  /// WebUntis-specific 3-phase flow handler
  Future<void> _handleWebUntisFlow(InAppWebViewController controller, String url) async {
    try {
      final isLoginPage = url.contains('login') || !url.contains('today');
      
      if (isLoginPage && !_webuntisPhase1Done) {
        // Phase 1: Close "Im Browser öffnen" dialog
        logger.info('WebUntis: Starting Phase 1 (close initial dialog)');
        await _runPostLoadScript(controller);
        _webuntisPhase1Done = true;
        
        // Phase 2: Inject credentials after dialog is closed
        if (widget.requiresAuth && !_webuntisLoginTriggered) {
          logger.info('WebUntis: Starting Phase 2 (credential injection)');
          await Future.delayed(const Duration(milliseconds: 800));
          await _injectAuthScript(controller);
          _webuntisLoginTriggered = true;
        }
      } else if (!isLoginPage && _webuntisLoginTriggered) {
        // Phase 2 & 3: After successful login
        logger.info('WebUntis: Starting Phase 2 & 3 (close overlays)');
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Run Phase 2 injection (immediate overlay closing)
        final phase2Script = InjectionScripts.webuntisPhase2Injection;
        await controller.evaluateJavascript(source: phase2Script.js);
        logger.info('WebUntis: Phase 2 completed');
        
        // Run Phase 3 injection (monitor for overlays after interaction)
        await Future.delayed(const Duration(milliseconds: 500));
        final phase3Script = InjectionScripts.webuntisPhase3Injection;
        await controller.evaluateJavascript(source: phase3Script.js);
        logger.info('WebUntis: Phase 3 monitoring started');
        
        // Reset flags for potential future logins
        _webuntisLoginTriggered = false;
        _webuntisPhase1Done = false;
      }
    } catch (error, stackTrace) {
      logger.error('Error in WebUntis flow', error, stackTrace);
    }
  }

  /// Handle download request from WebView
  Future<void> _handleDownload(DownloadStartRequest request) async {
    try {
      logger.info('Download request intercepted: ${request.url}');
      logger.info('Suggested filename: ${request.suggestedFilename}');
      logger.info('Content length: ${request.contentLength}');

      // Show download indicator
      if (mounted) {
        setState(() {
          _isDownloading = true;
          _downloadProgress = 0.0;
        });
      }

      // Extract headers from the request if available
      final Map<String, String> headers = {};
      
      // Get cookies from WebView to maintain session
      if (_webViewController != null) {
        final cookieManager = CookieManager.instance();
        final cookies = await cookieManager.getCookies(url: request.url);
        if (cookies.isNotEmpty) {
          final cookieString = cookies
              .map((cookie) => '${cookie.name}=${cookie.value}')
              .join('; ');
          headers['Cookie'] = cookieString;
          logger.info('Added cookies to download request');
        }
      }

      // Create download request
      final downloadRequest = DownloadRequest(
        url: request.url.toString(),
        filename: request.suggestedFilename,
        headers: headers.isNotEmpty ? headers : null,
      );

      // Use DownloadService to download the file
      final downloadService = DownloadService();
      
      if (mounted) {
        await downloadService.downloadFile(
          context: context,
          request: downloadRequest,
          onProgress: (received, total) {
            // Update progress indicator
            if (mounted && total > 0) {
              final progress = received / total;
              setState(() {
                _downloadProgress = progress;
              });
              logger.info('Download progress: ${(progress * 100).round()}%');
            }
          },
        );
      }
    } catch (error, stackTrace) {
      logger.error('Error handling download', error, stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download fehlgeschlagen: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      // Hide download indicator
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  /// Check if URL is a BBB meeting/conference link
  /// Only matches actual meeting join API calls (precise selectors from desktop app)
  bool _isBBBMeetingLink(String url) {
    // BBB meeting patterns (from desktop app electron.js):
    // - bbb.bbz-rd-eck.de/bigbluebutton/api/join? - Actual API join with parameters
    // - meet.stashcat.com - Stashcat meetings
    return url.contains('bbb.bbz-rd-eck.de/bigbluebutton/api/join?') ||
           url.contains('meet.stashcat.com');
  }

  /// Open URL in system browser (for BBB meetings with camera/mic support)
  Future<void> _openInSystemBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      
      // Show message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('BBB-Konferenz wird im System-Browser geöffnet...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Launch in external browser (system default)
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (launched) {
        logger.info('BBB meeting link opened in system browser: $url');
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

  @override
  void dispose() {
    _webViewController = null;
    super.dispose();
  }
}
