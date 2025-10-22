/// BBZCloud Mobile - App Drawer
/// 
/// Navigation drawer with app list
/// 
/// @version 0.1.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbzcloud_mobil/core/constants/app_strings.dart';
import 'package:bbzcloud_mobil/core/theme/app_theme.dart';
import 'package:bbzcloud_mobil/presentation/providers/user_provider.dart';
import 'package:bbzcloud_mobil/presentation/providers/apps_provider.dart';
import 'package:bbzcloud_mobil/presentation/screens/settings_screen.dart';
import 'package:bbzcloud_mobil/presentation/screens/todos_screen.dart';
import 'package:bbzcloud_mobil/presentation/screens/webview_screen.dart';
import 'package:bbzcloud_mobil/core/constants/navigation_apps.dart';
import 'package:bbzcloud_mobil/data/models/custom_app.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final apps = ref.watch(allAppsProvider);

    return Drawer(
      child: userState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Kein Benutzer angemeldet'),
            );
          }

          return Column(
            children: [
              // Drawer Header
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      user.email,
                      style: AppTextStyles.body1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      user.role.displayName,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Apps List
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(
                        AppStrings.allApps,
                        style: AppTextStyles.caption.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...apps.map((app) => _buildAppTile(context, app)),
                  ],
                ),
              ),

              // Bottom Section
              const Divider(),
              ListTile(
                leading: const Icon(Icons.checklist),
                title: const Text('Aufgaben'),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TodosScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text(AppStrings.settings),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Fehler: $error'),
        ),
      ),
    );
  }

  Widget _buildAppTile(BuildContext context, dynamic app) {
    final String title;
    final String url;
    final Color color;
    final IconData icon;
    final bool requiresAuth;

    if (app is AppItem) {
      title = app.title;
      url = app.url;
      color = app.color;
      icon = app.icon;
      requiresAuth = app.requiresAuth;
    } else if (app is CustomApp) {
      title = app.title;
      url = app.url;
      color = app.color;
      icon = app.icon;
      requiresAuth = false;
    } else {
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
      title: Text(title),
      onTap: () {
        Navigator.pop(context); // Close drawer
        // Open in WebView
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewScreen(
              title: title,
              url: url,
              requiresAuth: requiresAuth,
            ),
          ),
        );
      },
    );
  }
}
