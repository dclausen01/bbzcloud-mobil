/// BBZCloud Mobile - App Card Widget
/// 
/// Card widget to display individual apps
/// 
/// @version 0.1.0

import 'package:flutter/material.dart';
import 'package:bbzcloud_mobil/core/constants/navigation_apps.dart';
import 'package:bbzcloud_mobil/core/theme/app_theme.dart';
import 'package:bbzcloud_mobil/data/models/custom_app.dart';

class AppCard extends StatelessWidget {
  final dynamic app; // Can be AppItem or CustomApp
  final VoidCallback onTap;
  final bool isEditMode;
  final bool isVisible;
  final VoidCallback? onToggleVisibility;

  const AppCard({
    super.key,
    required this.app,
    required this.onTap,
    this.isEditMode = false,
    this.isVisible = true,
    this.onToggleVisibility,
  });

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

    return Opacity(
      opacity: isEditMode && !isVisible ? 0.5 : 1.0,
      child: Card(
        clipBehavior: Clip.none, // Changed from antiAlias to none for edit controls
        elevation: isEditMode ? 4 : 1,
        child: Stack(
          clipBehavior: Clip.none, // Allow controls to overflow
          children: [
            // Main card content
            InkWell(
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
}
