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
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: SizedBox(
                            height: 200, // Fixed height for edit mode cards
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
      floatingActionButton: _isEditMode ? null : FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CustomAppDialog(),
          );
        },
        child: const Icon(Icons.add),
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
}
