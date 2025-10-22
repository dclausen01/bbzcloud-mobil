/// BBZCloud Mobile - App Switcher Overlay
/// 
/// Modal overlay for quick app switching
/// 
/// @version 0.1.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbzcloud_mobil/core/constants/navigation_apps.dart';
import 'package:bbzcloud_mobil/core/theme/app_theme.dart';
import 'package:bbzcloud_mobil/data/models/custom_app.dart';
import 'package:bbzcloud_mobil/presentation/providers/apps_provider.dart';
import 'package:bbzcloud_mobil/presentation/providers/webview_stack_provider.dart';

class AppSwitcherOverlay extends ConsumerWidget {
  final Function(String id, String title, String url, bool requiresAuth) onAppSelected;
  final VoidCallback onClose;

  const AppSwitcherOverlay({
    super.key,
    required this.onAppSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(visibleAppsProvider);
    final webViewStack = ref.watch(webViewStackProvider);
    final currentWebViewId = webViewStack.currentWebViewId;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.lg),
                  topRight: Radius.circular(AppSpacing.lg),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.apps,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'App-Wechsler',
                    style: AppTextStyles.heading3.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),

            // Active WebViews Section
            if (webViewStack.stack.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tab,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Aktive Apps (${webViewStack.stack.length})',
                          style: AppTextStyles.caption.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: ref
                          .read(webViewStackProvider.notifier)
                          .getSortedStack()
                          .map((item) {
                        final isActive = item.id == currentWebViewId;
                        return InkWell(
                          onTap: () {
                            ref
                                .read(webViewStackProvider.notifier)
                                .switchToWebView(item.id);
                            onAppSelected(
                              item.id,
                              item.title,
                              item.url,
                              item.requiresAuth,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(AppSpacing.sm),
                              border: Border.all(
                                color: isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.title,
                                  style: AppTextStyles.caption.copyWith(
                                    color: isActive
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : Theme.of(context).colorScheme.onSurface,
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                InkWell(
                                  onTap: () {
                                    ref
                                        .read(webViewStackProvider.notifier)
                                        .removeWebView(item.id);
                                  },
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: isActive
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            // All Apps Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                  ),
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    
                    String id, title, url;
                    Color color;
                    IconData icon;
                    bool requiresAuth = false;

                    if (app is AppItem) {
                      id = app.id;
                      title = app.title;
                      url = app.url;
                      color = app.color;
                      icon = app.icon;
                      requiresAuth = app.requiresAuth;
                    } else if (app is CustomApp) {
                      id = app.id;
                      title = app.title;
                      url = app.url;
                      color = app.color;
                      icon = app.icon;
                    } else {
                      return const SizedBox.shrink();
                    }

                    final isInStack = webViewStack.hasWebView(id);

                    return InkWell(
                      onTap: () => onAppSelected(id, title, url, requiresAuth),
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [color, color.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                          border: isInStack
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    icon,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    title,
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isInStack)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
