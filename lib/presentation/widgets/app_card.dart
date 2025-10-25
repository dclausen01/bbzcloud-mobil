/// BBZCloud Mobile - App Card Widget
/// 
/// Card widget to display individual apps
/// 
/// @version 0.2.0

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
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
      return appItem.id == 'schulcloud'; // Only schul.cloud for now
    }
    return false;
  }

  /// Launch native schul.cloud app
  Future<void> _launchNativeApp(BuildContext context) async {
    try {
      logger.info('Attempting to launch native schul.cloud app');
      
      if (Platform.isAndroid) {
        // Android: Try to launch app via Intent
        // Skip canLaunchUrl() as it doesn't work well with Intents
        final appUri = Uri.parse('intent:#Intent;package=de.heinekingmedia.schulcloud;end');
        logger.info('Using Android Intent: $appUri');
        
        try {
          // Try to launch directly - will throw if app not installed
          await launchUrl(appUri, mode: LaunchMode.externalApplication);
          logger.info('Native schul.cloud app launched successfully');
        } catch (launchError) {
          // App not installed - show install dialog
          logger.warning('Could not launch app: $launchError');
          if (context.mounted) {
            _showInstallAppDialog(context);
          }
        }
      } else if (Platform.isIOS) {
        // iOS: Use URL Scheme with canLaunchUrl check
        final appUri = Uri.parse('schulcloud://');
        logger.info('Using iOS URL Scheme: $appUri');
        
        if (await canLaunchUrl(appUri)) {
          await launchUrl(appUri, mode: LaunchMode.externalApplication);
          logger.info('Native schul.cloud app launched successfully');
        } else {
          logger.warning('schul.cloud app not installed on iOS');
          if (context.mounted) {
            _showInstallAppDialog(context);
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
  void _showInstallAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App nicht installiert'),
        content: const Text(
          'Die schul.cloud App ist nicht installiert.\n\n'
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

  /// Open app store for schul.cloud
  Future<void> _openAppStore() async {
    try {
      final Uri storeUrl;
      if (Platform.isIOS) {
        storeUrl = Uri.parse('https://apps.apple.com/de/app/schul-cloud/id1426477195');
      } else if (Platform.isAndroid) {
        storeUrl = Uri.parse('https://play.google.com/store/apps/details?id=de.heinekingmedia.schulcloud');
      } else {
        logger.warning('Unsupported platform for app store');
        return;
      }
      
      if (await canLaunchUrl(storeUrl)) {
        await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
        logger.info('Opened app store for schul.cloud');
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
                          'schul.cloud App',
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
                          'schul.cloud Web',
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
