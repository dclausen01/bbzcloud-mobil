/// BBZCloud Mobile - App Card Widget
/// 
/// Card widget to display individual apps
/// 
/// @version 0.2.0

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:bbzcloud_mobil/core/constants/navigation_apps.dart';
import 'package:bbzcloud_mobil/core/theme/app_theme.dart';
import 'package:bbzcloud_mobil/data/models/custom_app.dart';
import 'package:bbzcloud_mobil/core/utils/app_logger.dart';

class AppCard extends StatelessWidget {
  final dynamic app; // Can be AppItem or CustomApp
  final VoidCallback onTap;
  final VoidCallback? onNativeAppTap; // NEW: For native app launch
  final bool isEditMode;
  final bool isVisible;
  final VoidCallback? onToggleVisibility;

  const AppCard({
    super.key,
    required this.app,
    required this.onTap,
    this.onNativeAppTap,
    this.isEditMode = false,
    this.isVisible = true,
    this.onToggleVisibility,
  });

  /// Check if this app has a native app option
  bool get hasNativeApp {
    if (app is AppItem) {
      final appItem = app as AppItem;
      return appItem.id == 'schulcloud' || appItem.id == 'webuntis';
    }
    return false;
  }
  
  /// Get app ID for native app handling
  String? get _appId {
    if (app is AppItem) {
      return (app as AppItem).id;
    }
    return null;
  }

  /// Get app-specific configuration
  Map<String, dynamic> _getAppConfig() {
    final appId = _appId;
    switch (appId) {
      case 'schulcloud':
        return {
          'androidPackage': 'de.heinekingmedia.schulcloud',
          'iosScheme': 'schulcloud://',
          'androidStoreUrl': 'https://play.google.com/store/apps/details?id=de.heinekingmedia.schulcloud',
          'iosStoreUrl': 'https://apps.apple.com/de/app/schul-cloud/id1426477195',
          'appName': 'schul.cloud',
        };
      case 'webuntis':
        return {
          'androidPackage': 'com.grupet.web.app',
          'iosScheme': 'untis://',
          'androidStoreUrl': 'https://play.google.com/store/apps/details?id=com.grupet.web.app',
          'iosStoreUrl': 'https://apps.apple.com/app/untis-mobile/id926186904',
          'appName': 'WebUntis',
        };
      default:
        return {};
    }
  }

  /// Launch native app directly using AndroidIntent with multiple fallback strategies
  Future<void> _launchNativeApp(BuildContext context) async {
    final config = _getAppConfig();
    final appName = config['appName'] ?? 'App';
    
    try {
      logger.info('Attempting to launch native $appName app');
      
      if (Platform.isAndroid) {
        // Android: Try multiple strategies
        final packageName = config['androidPackage'] as String;
        logger.info('Package name: $packageName');
        
        bool launched = false;
        
        // Strategy 1: ACTION_MAIN with CATEGORY_LAUNCHER (standard app launch)
        if (!launched) {
          try {
            logger.info('Strategy 1: ACTION_MAIN + CATEGORY_LAUNCHER');
            final intent = AndroidIntent(
              action: 'android.intent.action.MAIN',
              package: packageName,
              category: 'android.intent.category.LAUNCHER',
              flags: <int>[
                0x10000000, // FLAG_ACTIVITY_NEW_TASK
              ],
            );
            
            await intent.launch();
            logger.info('✅ App launched successfully with Strategy 1');
            launched = true;
          } catch (e1) {
            logger.warning('Strategy 1 failed: $e1');
          }
        }
        
        // Strategy 2: ACTION_MAIN without category (WebUntis approach)
        if (!launched) {
          try {
            logger.info('Strategy 2: ACTION_MAIN only');
            final intent = AndroidIntent(
              action: 'android.intent.action.MAIN',
              package: packageName,
              flags: <int>[
                0x10000000, // FLAG_ACTIVITY_NEW_TASK
              ],
            );
            
            await intent.launch();
            logger.info('✅ App launched successfully with Strategy 2');
            launched = true;
          } catch (e2) {
            logger.warning('Strategy 2 failed: $e2');
          }
        }
        
        // Strategy 3: ACTION_VIEW (some apps need this)
        if (!launched) {
          try {
            logger.info('Strategy 3: ACTION_VIEW');
            final intent = AndroidIntent(
              action: 'android.intent.action.VIEW',
              package: packageName,
              flags: <int>[
                0x10000000, // FLAG_ACTIVITY_NEW_TASK
              ],
            );
            
            await intent.launch();
            logger.info('✅ App launched successfully with Strategy 3');
            launched = true;
          } catch (e3) {
            logger.warning('Strategy 3 failed: $e3');
          }
        }
        
        // All strategies failed - app not installed
        if (!launched) {
          logger.warning('❌ All strategies failed - app not installed');
          if (context.mounted) {
            _showInstallAppDialog(context, appName);
          }
        }
      } else if (Platform.isIOS) {
        // iOS: Use URL Scheme
        final appUri = Uri.parse(config['iosScheme'] as String);
        logger.info('Using iOS URL Scheme: $appUri');
        
        if (await canLaunchUrl(appUri)) {
          await launchUrl(appUri, mode: LaunchMode.externalApplication);
          logger.info('Native $appName app launched successfully');
        } else {
          logger.warning('$appName app not installed on iOS');
          if (context.mounted) {
            _showInstallAppDialog(context, appName);
          }
        }
      } else {
        logger.warning('Unsupported platform');
      }
    } catch (error, stackTrace) {
      logger.error('Unexpected error launching native app', error, stackTrace);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Öffnen der App: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show dialog to install native app
  void _showInstallAppDialog(BuildContext context, String appName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App nicht installiert'),
        content: Text(
          'Die $appName App ist nicht installiert.\n\n'
          'Möchten Sie die App aus dem Store herunterladen?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _openAppStore();
            },
            child: const Text('Zum Store'),
          ),
        ],
      ),
    );
  }

  /// Open app store for current app
  Future<void> _openAppStore() async {
    final config = _getAppConfig();
    final appName = config['appName'] ?? 'App';
    
    try {
      final Uri storeUrl;
      if (Platform.isIOS) {
        storeUrl = Uri.parse(config['iosStoreUrl'] as String);
      } else if (Platform.isAndroid) {
        storeUrl = Uri.parse(config['androidStoreUrl'] as String);
      } else {
        logger.warning('Unsupported platform for app store');
        return;
      }
      
      if (await canLaunchUrl(storeUrl)) {
        await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
        logger.info('Opened app store for $appName');
      }
    } catch (error, stackTrace) {
      logger.error('Error opening app store', error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title;
    final Color color;
    final IconData icon;
    final String? description;

    if (app is AppItem) {
      final appItem = app as AppItem;
      title = appItem.title;
      color = appItem.color;
      icon = appItem.icon;
      description = appItem.description;
    } else if (app is CustomApp) {
      final customApp = app as CustomApp;
      title = customApp.title;
      color = customApp.color;
      icon = customApp.icon;
      description = null;
    } else {
      return const SizedBox.shrink();
    }

    // Split button for apps with native app option
    if (hasNativeApp && !isEditMode) {
      return _buildSplitButtonCard(context, title, color, icon, description);
    }

    return Opacity(
      opacity: isEditMode && !isVisible ? 0.5 : 1.0,
      child: Card(
        clipBehavior: Clip.none, // Changed from antiAlias to none for edit controls
        elevation: isEditMode ? 4 : 1,
        child: Stack(
          clipBehavior: Clip.none, // Allow controls to overflow
          children: [
            // Main card content
            _buildCardContent(context, title, color, icon, description),
            
            // Edit Mode Controls - now on top with proper z-index
            if (isEditMode) ...[
              // Drag Handle
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.drag_indicator,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              
              // Visibility Toggle Button
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onToggleVisibility,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build standard card content
  Widget _buildCardContent(
    BuildContext context,
    String title,
    Color color,
    IconData icon,
    String? description,
  ) {
    return SizedBox.expand(
      child: InkWell(
        onTap: isEditMode ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: AppTextStyles.heading3.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (description != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build split button card (native app + WebView)
  Widget _buildSplitButtonCard(
    BuildContext context,
    String title,
    Color color,
    IconData icon,
    String? description,
  ) {
    return Opacity(
      opacity: isEditMode && !isVisible ? 0.5 : 1.0,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            children: [
              // Top button: Native App
              Expanded(
                child: InkWell(
                  onTap: () => _launchNativeApp(context),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.open_in_new,
                          size: 32,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _appId == 'webuntis' ? 'WebUntis App' : 'schul.cloud App',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Divider
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              ),
              
              // Bottom button: WebView
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 32,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _appId == 'webuntis' ? 'WebUntis Web' : 'schul.cloud Web',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
