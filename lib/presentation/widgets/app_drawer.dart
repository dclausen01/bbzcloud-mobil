/// BBZCloud Mobile - App Drawer
///
/// The single source of navigation: chat (home), apps, custom apps,
/// todos and settings. Used both as a Drawer on phones and as a permanent
/// side panel on tablets (in that case the widget is wrapped in a SizedBox
/// instead of a Scaffold.drawer).
///

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bbzcloud_mobil/core/constants/app_strings.dart';
import 'package:bbzcloud_mobil/core/theme/app_theme.dart';
import 'package:bbzcloud_mobil/core/utils/platform_utils.dart';
import 'package:bbzcloud_mobil/core/constants/navigation_apps.dart';
import 'package:bbzcloud_mobil/data/models/custom_app.dart';
import 'package:bbzcloud_mobil/presentation/providers/apps_provider.dart';
import 'package:bbzcloud_mobil/presentation/providers/chat_state_provider.dart';
import 'package:bbzcloud_mobil/presentation/providers/current_webview_provider.dart';
import 'package:bbzcloud_mobil/presentation/providers/user_provider.dart';
import 'package:bbzcloud_mobil/presentation/screens/apps_manage_screen.dart';
import 'package:bbzcloud_mobil/presentation/screens/settings_screen.dart';
import 'package:bbzcloud_mobil/presentation/screens/todos_screen.dart';
import 'package:bbzcloud_mobil/presentation/screens/webview_screen.dart';
import 'package:bbzcloud_mobil/presentation/widgets/custom_app_dialog.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final isTablet = PlatformUtils.isTablet(context);

    final content = userState.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Kein Benutzer angemeldet'));
        }
        return _buildContent(context, ref, user, isTablet: isTablet);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Fehler: $error')),
    );

    // On tablets the drawer is rendered as a side panel directly (no
    // Drawer wrapper) so it stays open permanently.
    return isTablet ? Material(child: content) : Drawer(child: content);
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    dynamic user, {
    required bool isTablet,
  }) {
    final visibleApps = ref.watch(visibleAppsProvider);
    final activeTablet = ref.watch(tabletWebViewProvider);
    final isChatActive = !isTablet || !activeTablet.hasWebView;

    return Column(
      children: [
        _Header(user: user),

        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // --- Chat (home) ---
              _NavTile(
                leading: const _IconBadge(
                  icon: Icons.chat_bubble_outline,
                  color: Color(0xFF3880FF),
                ),
                title: 'Chat',
                selected: isChatActive,
                trailing: const _ChatUnreadPill(),
                onTap: () {
                  if (isTablet) {
                    ref.read(tabletWebViewProvider.notifier).clearWebView();
                  } else {
                    Navigator.pop(context); // Already on chat home; just close.
                  }
                },
              ),

              const _SectionLabel('Apps'),
              ...visibleApps.map(
                (app) => _AppTile(
                  app: app,
                  isTablet: isTablet,
                  active: isTablet &&
                      activeTablet.appId == _appIdOf(app),
                ),
              ),
              _NavTile(
                leading: const _IconBadge(
                  icon: Icons.tune,
                  color: Colors.blueGrey,
                ),
                title: 'Apps verwalten',
                onTap: () {
                  if (!isTablet) Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppsManageScreen(),
                    ),
                  );
                },
              ),
              _NavTile(
                leading: const _IconBadge(
                  icon: Icons.add_circle_outline,
                  color: Colors.teal,
                ),
                title: 'Eigene App hinzufügen',
                onTap: () {
                  if (!isTablet) Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => const CustomAppDialog(),
                  );
                },
              ),

              const _SectionLabel('Werkzeuge'),
              _NavTile(
                leading: const _IconBadge(
                  icon: Icons.check_circle_outline,
                  color: Colors.orange,
                ),
                title: 'Aufgaben',
                onTap: () {
                  if (!isTablet) Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TodosScreen()),
                  );
                },
              ),
              _NavTile(
                leading: const _IconBadge(
                  icon: Icons.settings,
                  color: Colors.grey,
                ),
                title: AppStrings.settings,
                onTap: () {
                  if (!isTablet) Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _appIdOf(dynamic app) {
    if (app is AppItem) return app.id;
    if (app is CustomApp) return app.id;
    return '';
  }
}

// -- Header -------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
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
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: Image.asset('assets/icon.png', fit: BoxFit.contain),
            ),
          ),
          const Spacer(),
          Center(
            child: Column(
              children: [
                Text(
                  user.email,
                  style: AppTextStyles.body1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    user.role.displayName,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -- Building blocks ----------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.leading,
    required this.title,
    required this.onTap,
    this.selected = false,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final VoidCallback onTap;
  final bool selected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: trailing,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _ChatUnreadPill extends ConsumerWidget {
  const _ChatUnreadPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(chatUnreadProvider);
    if (unread <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(minWidth: 22, minHeight: 18),
      child: Text(
        unread > 99 ? '99+' : '$unread',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _AppTile extends ConsumerWidget {
  const _AppTile({
    required this.app,
    required this.isTablet,
    required this.active,
  });

  final dynamic app;
  final bool isTablet;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title;
    final String url;
    final Color color;
    final IconData icon;
    final bool requiresAuth;
    final String appId;

    if (app is AppItem) {
      final a = app as AppItem;
      title = a.title;
      url = a.url;
      color = a.color;
      icon = a.icon;
      requiresAuth = a.requiresAuth;
      appId = a.id;
    } else if (app is CustomApp) {
      final a = app as CustomApp;
      title = a.title;
      url = a.url;
      color = a.color;
      icon = a.icon;
      requiresAuth = false;
      appId = a.id;
    } else {
      return const SizedBox.shrink();
    }

    return _NavTile(
      leading: _IconBadge(icon: icon, color: color),
      title: title,
      selected: active,
      onTap: () {
        if (isTablet) {
          ref.read(tabletWebViewProvider.notifier).showWebView(
                appId: appId,
                title: title,
                url: url,
                requiresAuth: requiresAuth,
              );
        } else {
          Navigator.pop(context); // Close drawer first.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WebViewScreen(
                appId: appId,
                title: title,
                url: url,
                requiresAuth: requiresAuth,
              ),
            ),
          );
        }
      },
    );
  }
}
