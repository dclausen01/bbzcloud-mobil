/// BBZCloud Mobile - Home Screen
/// 
/// Main screen showing all available apps
/// 
/// @version 0.1.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbzcloud_mobil/core/constants/app_strings.dart';
import 'package:bbzcloud_mobil/core/constants/navigation_apps.dart';
import 'package:bbzcloud_mobil/core/theme/app_theme.dart';
import 'package:bbzcloud_mobil/core/utils/route_animations.dart';
import 'package:bbzcloud_mobil/data/models/custom_app.dart';
import 'package:bbzcloud_mobil/presentation/providers/apps_provider.dart';
import 'package:bbzcloud_mobil/presentation/providers/user_provider.dart';
import 'package:bbzcloud_mobil/presentation/screens/webview_screen.dart';
import 'package:bbzcloud_mobil/presentation/widgets/app_card.dart';
import 'package:bbzcloud_mobil/presentation/widgets/app_drawer.dart';
import 'package:bbzcloud_mobil/presentation/widgets/custom_app_dialog.dart';
import 'package:bbzcloud_mobil/presentation/screens/todos_screen.dart';
import 'package:bbzcloud_mobil/presentation/providers/todo_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isEditMode = false;

  String _getAppId(dynamic app) {
    if (app is AppItem) {
      return app.id;
    } else if (app is CustomApp) {
      return app.id;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final apps = _isEditMode 
        ? ref.watch(allAppsProvider) 
        : ref.watch(visibleAppsProvider);
    final userState = ref.watch(userProvider);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
        actions: [
          // Todo Button with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    RouteAnimations.slideFromBottom(const TodosScreen()),
                  );
                },
                tooltip: 'Aufgaben',
              ),
              Consumer(
                builder: (context, ref, child) {
                  final activeTodoCount = ref.watch(activeTodoCountProvider);
                  if (activeTodoCount == 0) return const SizedBox.shrink();
                  
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          activeTodoCount > 99 ? '99+' : '$activeTodoCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const CustomAppDialog(),
                );
              },
              tooltip: 'Eigene App hinzufügen',
            ),
          IconButton(
            icon: Icon(_isEditMode ? Icons.done : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
            },
            tooltip: _isEditMode ? 'Fertig' : 'Bearbeiten',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: userState.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Kein Benutzer angemeldet',
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Bitte richten Sie zuerst Ihr Konto ein',
                    style: AppTextStyles.body1.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          if (apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.apps_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Keine Apps verfügbar',
                    style: AppTextStyles.heading2,
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // Header
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Willkommen, ${user.email.split('@')[0]}',
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        user.role.displayName,
                        style: AppTextStyles.body2.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Text(
                            AppStrings.allApps,
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_isEditMode) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '(Ziehen zum Sortieren)',
                              style: AppTextStyles.caption.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Apps Grid or Reorderable List
              if (_isEditMode)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  sliver: SliverReorderableList(
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      final appId = _getAppId(app);
                      final isVisible = settings.isVisible(appId);
                      
                      return ReorderableDragStartListener(
                        key: ValueKey(appId),
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                // Dedicated drag handle area (left column)
                                Container(
                                  width: 60,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomLeft: Radius.circular(10),
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.drag_indicator,
                                      size: 32,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                // App card content (right column)
                                Expanded(
                                  child: Stack(
                                    children: [
                                      SizedBox(
                                        height: 180,
                                        child: AppCard(
                                          app: app,
                                          onTap: () {},
                                          isEditMode: true,
                                          isVisible: isVisible,
                                          onToggleVisibility: () {
                                            ref.read(appSettingsProvider.notifier).toggleVisibility(appId);
                                          },
                                        ),
                                      ),
                                      // Edit/Delete buttons for Custom Apps only
                                      if (app is CustomApp)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Edit button
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.9),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(Icons.edit, size: 20),
                                                  color: Colors.white,
                                                  onPressed: () => _editCustomApp(app),
                                                  tooltip: 'Bearbeiten',
                                                  padding: const EdgeInsets.all(8),
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              // Delete button
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(0.9),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(Icons.delete, size: 20),
                                                  color: Colors.white,
                                                  onPressed: () => _deleteCustomApp(app),
                                                  tooltip: 'Löschen',
                                                  padding: const EdgeInsets.all(8),
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      
                      final reorderedApps = List<dynamic>.from(apps);
                      final app = reorderedApps.removeAt(oldIndex);
                      reorderedApps.insert(newIndex, app);
                      
                      final appIds = reorderedApps.map((a) => _getAppId(a)).toList();
                      ref.read(appSettingsProvider.notifier).reorderApps(appIds);
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final app = apps[index];
                        return AppCard(
                          app: app,
                          onTap: () => _handleAppTap(context, app),
                        );
                      },
                      childCount: apps.length,
                    ),
                  ),
                ),
              
              const SliverPadding(
                padding: EdgeInsets.only(bottom: AppSpacing.xxl),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Fehler beim Laden',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error.toString(),
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () {
                  ref.read(userProvider.notifier).reload();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAppTap(BuildContext context, dynamic app) {
    String id;
    String title;
    String url;
    bool requiresAuth = false;

    if (app is AppItem) {
      id = app.id;
      title = app.title;
      url = app.url;
      requiresAuth = app.requiresAuth;
    } else if (app is CustomApp) {
      id = app.id;
      title = app.title;
      url = app.url;
      requiresAuth = false;
    } else {
      return;
    }

    Navigator.push(
      context,
      RouteAnimations.slideFromBottom(
        WebViewScreen(
          appId: id,
          title: title,
          url: url,
          requiresAuth: requiresAuth,
        ),
      ),
    );
  }

  /// Edit a custom app - opens dialog with existing app data
  Future<void> _editCustomApp(CustomApp app) async {
    await showDialog(
      context: context,
      builder: (context) => CustomAppDialog(existingApp: app),
    );
  }

  /// Delete a custom app with confirmation dialog
  Future<void> _deleteCustomApp(CustomApp app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom App löschen?'),
        content: Text('Möchten Sie "${app.title}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(customAppsProvider.notifier).deleteApp(app.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${app.title} wurde gelöscht'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Löschen: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
