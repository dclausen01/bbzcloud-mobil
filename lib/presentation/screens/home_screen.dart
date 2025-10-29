/// BBZCloud Mobile - Home Screen
/// 
/// Main screen showing all available apps
/// Responsive layout: Grid on phones, permanent drawer on tablets
/// 
/// @version 0.2.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbzcloud_mobil/core/constants/app_strings.dart';
import 'package:bbzcloud_mobil/core/constants/navigation_apps.dart';
import 'package:bbzcloud_mobil/core/theme/app_theme.dart';
import 'package:bbzcloud_mobil/core/utils/route_animations.dart';
import 'package:bbzcloud_mobil/core/utils/platform_utils.dart';
import 'package:bbzcloud_mobil/data/models/custom_app.dart';
import 'package:bbzcloud_mobil/data/models/todo.dart';
import 'package:bbzcloud_mobil/presentation/providers/apps_provider.dart';
import 'package:bbzcloud_mobil/presentation/providers/user_provider.dart';
import 'package:bbzcloud_mobil/presentation/screens/webview_screen.dart';
import 'package:bbzcloud_mobil/presentation/widgets/app_card.dart';
import 'package:bbzcloud_mobil/presentation/widgets/app_drawer.dart';
import 'package:bbzcloud_mobil/presentation/widgets/custom_app_dialog.dart';
import 'package:bbzcloud_mobil/presentation/screens/todos_screen.dart';
import 'package:bbzcloud_mobil/presentation/screens/settings_screen.dart';
import 'package:bbzcloud_mobil/presentation/providers/todo_provider.dart';
import 'package:bbzcloud_mobil/presentation/providers/current_webview_provider.dart';
import 'package:bbzcloud_mobil/presentation/widgets/embedded_webview_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isEditMode = false;
  bool _hasCheckedDueTodos = false;

  @override
  void initState() {
    super.initState();
    // Check for due todos after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDueTodos();
    });
  }

  Future<void> _checkDueTodos() async {
    if (_hasCheckedDueTodos) return;
    _hasCheckedDueTodos = true;

    // Wait a bit for providers to initialize
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;

    final dueTodayTodos = ref.read(todosDueTodayProvider);
    final overdueTodos = ref.read(overdueTodosProvider);
    
    if (dueTodayTodos.isNotEmpty || overdueTodos.isNotEmpty) {
      _showDueTodosDialog(dueTodayTodos, overdueTodos);
    }
  }

  void _showDueTodosDialog(List<Todo> dueTodayTodos, List<Todo> overdueTodos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Fällige Aufgaben'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (overdueTodos.isNotEmpty) ...[
                Text(
                  'Überfällig (${overdueTodos.length}):',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...overdueTodos.map((todo) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          todo.text,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
              ],
              if (dueTodayTodos.isNotEmpty) ...[
                Text(
                  'Heute fällig (${dueTodayTodos.length}):',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...dueTodayTodos.map((todo) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.today, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          todo.text,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Später'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                RouteAnimations.slideFromBottom(const TodosScreen()),
              );
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Zu Aufgaben'),
          ),
        ],
      ),
    );
  }

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
    final userState = ref.watch(userProvider);
    final isTablet = PlatformUtils.isTablet(context);

    return userState.when(
      data: (user) {
        if (user == null) {
          return _buildNoUserScreen(isTablet);
        }

        // Tablet layout with permanent drawer
        if (isTablet) {
          return _buildTabletLayout(user);
        }

        // Phone layout (original)
        return _buildPhoneLayout(user);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: _buildErrorScreen(error),
      ),
    );
  }

  /// Build layout for tablets in landscape mode
  Widget _buildTabletLayout(dynamic user) {
    return Scaffold(
      appBar: _buildAppBar(isTablet: true),
      body: Row(
        children: [
          // Permanent drawer (300px)
          Container(
            width: 300,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: _buildDrawerContent(user),
          ),
          // Content area
          Expanded(
            child: _isEditMode
                ? _buildEditModeContent()
                : _buildTabletHomeContent(),
          ),
        ],
      ),
    );
  }

  /// Build layout for phones
  Widget _buildPhoneLayout(dynamic user) {
    final apps = _isEditMode 
        ? ref.watch(allAppsProvider) 
        : ref.watch(visibleAppsProvider);

    return Scaffold(
      appBar: _buildAppBar(isTablet: false),
      drawer: const AppDrawer(),
      body: apps.isEmpty
          ? _buildNoAppsScreen()
          : _buildPhoneContent(user, apps),
    );
  }

  /// Build AppBar
  AppBar _buildAppBar({required bool isTablet}) {
    return AppBar(
      // Hide drawer button on tablets
      automaticallyImplyLeading: !isTablet,
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
    );
  }

  /// Build drawer content for tablet (includes edit mode)
  Widget _buildDrawerContent(dynamic user) {
    final apps = _isEditMode 
        ? ref.watch(allAppsProvider) 
        : ref.watch(visibleAppsProvider);
    final settings = ref.watch(appSettingsProvider);

    return Column(
      children: [
        // Drawer Header
        _buildDrawerHeader(user),
        
        // Apps Section
        Expanded(
          child: _isEditMode
              ? _buildEditModeList(apps, settings)
              : _buildNormalAppsList(apps),
        ),
        
        // Bottom Actions
        const Divider(),
        ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: const Text('Aufgaben'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TodosScreen()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text(AppStrings.settings),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  /// Build drawer header with user info
  Widget _buildDrawerHeader(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          // App Logo
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/icon.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // User Info
          Center(
            child: Column(
              children: [
                Text(
                  user.email,
                  style: AppTextStyles.body2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
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
          if (_isEditMode) ...[
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Bearbeitungsmodus',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build edit mode list with drag handles
  Widget _buildEditModeList(List<dynamic> apps, dynamic settings) {
    if (apps.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('Keine Apps verfügbar'),
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        final appId = _getAppId(app);
        final isVisible = settings.isVisible(appId);
        
        return _buildEditModeListTile(app, appId, isVisible);
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
    );
  }

  /// Build a single edit mode list tile
  Widget _buildEditModeListTile(dynamic app, String appId, bool isVisible) {
    final String title;
    final Color color;
    final IconData icon;

    if (app is AppItem) {
      title = app.title;
      color = app.color;
      icon = app.icon;
    } else if (app is CustomApp) {
      title = app.title;
      color = app.color;
      icon = app.icon;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      key: ValueKey(appId),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isVisible
              ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: ref.watch(allAppsProvider).indexOf(app),
              child: const Icon(
                Icons.drag_indicator,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 4),
            // App icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
          ],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isVisible ? null : Colors.grey,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Visibility toggle
            IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: isVisible ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
              onPressed: () {
                ref.read(appSettingsProvider.notifier).toggleVisibility(appId);
              },
              tooltip: isVisible ? 'Ausblenden' : 'Einblenden',
            ),
            // Edit/Delete for custom apps
            if (app is CustomApp) ...[
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: Colors.blue,
                onPressed: () => _editCustomApp(app),
                tooltip: 'Bearbeiten',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red,
                onPressed: () => _deleteCustomApp(app),
                tooltip: 'Löschen',
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build normal apps list (non-edit mode)
  Widget _buildNormalAppsList(List<dynamic> apps) {
    if (apps.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('Keine sichtbaren Apps'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        return _buildAppListTile(app);
      },
    );
  }

  /// Build a single app list tile (for tablet drawer)
  Widget _buildAppListTile(dynamic app) {
    final String title;
    final String url;
    final Color color;
    final IconData icon;
    final bool requiresAuth;
    final String appId = _getAppId(app);

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

    // Check if this app is currently active
    final currentWebView = ref.watch(tabletWebViewProvider);
    final isActive = currentWebView.appId == appId;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(isActive ? 0.3 : 0.2),
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: color, width: 2)
              : null,
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      onTap: () {
        // On tablets: Update provider to show embedded WebView
        // This avoids navigation and keeps sidebar visible
        ref.read(tabletWebViewProvider.notifier).showWebView(
          appId: appId,
          title: title,
          url: url,
          requiresAuth: requiresAuth,
        );
      },
    );
  }

  /// Build tablet home content (shows either home screen or embedded webview)
  Widget _buildTabletHomeContent() {
    final currentWebView = ref.watch(tabletWebViewProvider);
    
    // Show WebView if one is active
    if (currentWebView.hasWebView) {
      return EmbeddedWebViewWidget(
        key: ValueKey(currentWebView.appId), // Force rebuild on app change
        appId: currentWebView.appId!,
        title: currentWebView.title!,
        url: currentWebView.url!,
        requiresAuth: currentWebView.requiresAuth ?? false,
        showAppBar: false, // Hide AppBar (main AppBar is visible)
        showBottomBar: true,
        onHomePressed: () {
          // Clear WebView and return to home
          ref.read(tabletWebViewProvider.notifier).clearWebView();
        },
      );
    }
    
    // Show home screen when no app is open
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Logo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Image.asset(
              'assets/icon.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Wähle eine App aus dem Menü',
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Die ausgewählte App wird hier angezeigt',
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build edit mode content for tablet
  Widget _buildEditModeContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Bearbeitungsmodus aktiv',
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              'Apps in der Seitenleiste sortieren\nund Sichtbarkeit anpassen',
              style: AppTextStyles.body1.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Build phone content (original grid layout)
  Widget _buildPhoneContent(dynamic user, List<dynamic> apps) {
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
          _buildPhoneEditMode(apps)
        else
          _buildPhoneGrid(apps),
        
        const SliverPadding(
          padding: EdgeInsets.only(bottom: AppSpacing.xxl),
        ),
      ],
    );
  }

  /// Build phone edit mode (original)
  Widget _buildPhoneEditMode(List<dynamic> apps) {
    final settings = ref.watch(appSettingsProvider);
    
    return SliverPadding(
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
                    // Drag handle
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
                    // App card
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
                          if (app is CustomApp)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
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
    );
  }

  /// Build phone grid (original)
  Widget _buildPhoneGrid(List<dynamic> apps) {
    return SliverPadding(
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
    );
  }

  /// Build no user screen
  Widget _buildNoUserScreen(bool isTablet) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isTablet,
        title: const Text(AppStrings.appTitle),
      ),
      body: Center(
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
      ),
    );
  }

  /// Build no apps screen
  Widget _buildNoAppsScreen() {
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

  /// Build error screen
  Widget _buildErrorScreen(Object error) {
    return Center(
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
