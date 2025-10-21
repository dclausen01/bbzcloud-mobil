/// BBZCloud Mobile - WebView Screen
/// 
/// Screen for displaying web apps with JavaScript injection
/// 
/// @version 0.1.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:bbzcloud_mobil/core/utils/app_logger.dart';
import 'package:bbzcloud_mobil/data/services/credential_service.dart';

class WebViewScreen extends ConsumerStatefulWidget {
  final String title;
  final String url;
  final bool requiresAuth;

  const WebViewScreen({
    super.key,
    required this.title,
    required this.url,
    this.requiresAuth = false,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_canGoBack)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _webViewController?.goBack(),
            ),
          if (_canGoForward)
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => _webViewController?.goForward(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController?.reload(),
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
      body: Column(
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
                // SECURITY: Disabled file access from URLs to prevent XSS
                allowFileAccessFromFileURLs: false,
                allowUniversalAccessFromFileURLs: false,
                // User Agent
                userAgent: 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 BBZCloud/1.0',
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStart: (controller, url) {
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
                
                // Update navigation buttons
                _updateNavigationButtons();
                
                // Inject JavaScript if auth is required
                if (widget.requiresAuth) {
                  await _injectAuthScript(controller);
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
              onDownloadStartRequest: (controller, request) {
                // TODO: Handle downloads
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Download: ${request.url}'),
                  ),
                );
              },
              onConsoleMessage: (controller, consoleMessage) {
                // Log console messages for debugging
                debugPrint('Console: ${consoleMessage.message}');
              },
            ),
          ),
        ],
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

  /// Securely inject authentication script with credentials
  /// SECURITY: Uses callAsyncJavaScript to safely pass credentials without XSS risks
  Future<void> _injectAuthScript(InAppWebViewController controller) async {
    try {
      // Get credentials
      final credentials = await CredentialService.instance.loadCredentials();
      
      if (!credentials.hasBasicCredentials) {
        logger.warning('No credentials available for auto-fill');
        return;
      }

      // SECURITY: Use callAsyncJavaScript to pass credentials safely as arguments
      // This prevents XSS vulnerabilities from string interpolation
      await controller.callAsyncJavaScript(
        functionBody: '''
          return new Promise((resolve, reject) => {
            try {
              const email = arguments[0];
              const password = arguments[1];
              
              function fillLoginForm() {
                // Try to find email/username field
                const emailField = document.querySelector(
                  'input[type="email"], input[name*="email"], input[name*="user"], input[id*="email"], input[id*="user"]'
                );
                
                if (emailField && emailField.value === '' && email) {
                  emailField.value = email;
                  emailField.dispatchEvent(new Event('input', { bubbles: true }));
                  emailField.dispatchEvent(new Event('change', { bubbles: true }));
                }
                
                // Try to find password field
                const passwordField = document.querySelector('input[type="password"]');
                if (passwordField && passwordField.value === '' && password) {
                  passwordField.value = password;
                  passwordField.dispatchEvent(new Event('input', { bubbles: true }));
                  passwordField.dispatchEvent(new Event('change', { bubbles: true }));
                }
                
                resolve({ filled: true });
              }
              
              // Wait for page to be ready
              if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', fillLoginForm);
              } else {
                fillLoginForm();
              }
            } catch (error) {
              reject(error);
            }
          });
        ''',
        arguments: {
          'email': credentials.email,
          'password': credentials.password ?? '',
        },
      );
      
      logger.info('Auth script injected successfully for ${widget.title}');
    } catch (error, stackTrace) {
      logger.error('Error injecting auth script', error, stackTrace);
      // Don't show error to user as this is a convenience feature
    }
  }

  @override
  void dispose() {
    _webViewController = null;
    super.dispose();
  }
}
