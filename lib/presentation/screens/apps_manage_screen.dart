/// BBZCloud Mobile - Apps Manage Screen
///
/// Replaces the in-line edit mode that used to live inside the home grid.
/// Offers reorder, visibility toggle and edit/delete for custom apps in one
/// dedicated screen reachable from the drawer.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bbzcloud_mobil/core/constants/navigation_apps.dart';
import 'package:bbzcloud_mobil/core/theme/app_theme.dart';
import 'package:bbzcloud_mobil/data/models/custom_app.dart';
import 'package:bbzcloud_mobil/presentation/providers/apps_provider.dart';
import 'package:bbzcloud_mobil/presentation/widgets/custom_app_dialog.dart';

class AppsManageScreen extends ConsumerWidget {
  const AppsManageScreen({super.key});

  String _appId(dynamic app) {
    if (app is AppItem) return app.id;
    if (app is CustomApp) return app.id;
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(allAppsProvider);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apps verwalten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Eigene App hinzufügen',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const CustomAppDialog(),
            ),
          ),
        ],
      ),
      body: apps.isEmpty
          ? const Center(child: Text('Keine Apps verfügbar'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: apps.length,
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) newIndex -= 1;
                final reordered = List<dynamic>.from(apps);
                final item = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, item);
                ref
                    .read(appSettingsProvider.notifier)
                    .reorderApps(reordered.map(_appId).toList());
              },
              itemBuilder: (context, index) {
                final app = apps[index];
                final id = _appId(app);
                final visible = settings.isVisible(id);
                return _Row(
                  key: ValueKey(id),
                  app: app,
                  visible: visible,
                  onToggleVisibility: () => ref
                      .read(appSettingsProvider.notifier)
                      .toggleVisibility(id),
                );
              },
            ),
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({
    super.key,
    required this.app,
    required this.visible,
    required this.onToggleVisibility,
  });

  final dynamic app;
  final bool visible;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title;
    final Color color;
    final IconData icon;
    final bool isCustom;

    if (app is AppItem) {
      title = (app as AppItem).title;
      color = (app as AppItem).color;
      icon = (app as AppItem).icon;
      isCustom = false;
    } else if (app is CustomApp) {
      title = (app as CustomApp).title;
      color = (app as CustomApp).color;
      icon = (app as CustomApp).icon;
      isCustom = true;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(
                visible ? 0.3 : 0.1,
              ),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(color: visible ? null : Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                visible ? Icons.visibility : Icons.visibility_off,
                color: visible
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              tooltip: visible ? 'Ausblenden' : 'Einblenden',
              onPressed: onToggleVisibility,
            ),
            if (isCustom) ...[
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: Colors.blue,
                tooltip: 'Bearbeiten',
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) =>
                      CustomAppDialog(existingApp: app as CustomApp),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red,
                tooltip: 'Löschen',
                onPressed: () => _confirmDelete(context, ref, app as CustomApp),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CustomApp app,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Custom App löschen?'),
        content: Text('Möchten Sie "${app.title}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(customAppsProvider.notifier).deleteApp(app.id);
    }
  }
}
