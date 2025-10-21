/// BBZCloud Mobile - Settings Screen
/// 
/// Settings and account management
/// 
/// @version 0.1.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbzcloud_mobil/core/constants/app_config.dart';
import 'package:bbzcloud_mobil/core/constants/app_strings.dart';
import 'package:bbzcloud_mobil/core/theme/app_theme.dart';
import 'package:bbzcloud_mobil/data/services/credential_service.dart';
import 'package:bbzcloud_mobil/data/services/database_service.dart';
import 'package:bbzcloud_mobil/presentation/providers/user_provider.dart';
import 'package:bbzcloud_mobil/presentation/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
      ),
      body: userState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Kein Benutzer angemeldet'),
            );
          }

          return settingsState.when(
            data: (settings) => ListView(
              children: [
                // User Info Section
                _buildUserSection(context, user),
                const Divider(),

                // Theme Section
                _buildThemeSection(context, ref, settings.theme),
                const Divider(),

                // Account Section
                _buildAccountSection(context, ref, user),
                const Divider(),

                // About Section
                _buildAboutSection(context),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Fehler: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Fehler: $error'),
        ),
      ),
    );
  }

  Widget _buildUserSection(BuildContext context, user) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.account,
            style: AppTextStyles.heading3.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(user.email),
            subtitle: Text(user.role.displayName),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode currentTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.appearance,
            style: AppTextStyles.heading3.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          RadioListTile<AppThemeMode>(
            title: const Text(AppStrings.themeLight),
            subtitle: const Text('Helles Design'),
            value: AppThemeMode.light,
            groupValue: currentTheme,
            onChanged: (value) {
              if (value != null) {
                ref.read(settingsProvider.notifier).setTheme(value);
              }
            },
          ),
          RadioListTile<AppThemeMode>(
            title: const Text(AppStrings.themeDark),
            subtitle: const Text('Dunkles Design'),
            value: AppThemeMode.dark,
            groupValue: currentTheme,
            onChanged: (value) {
              if (value != null) {
                ref.read(settingsProvider.notifier).setTheme(value);
              }
            },
          ),
          RadioListTile<AppThemeMode>(
            title: const Text(AppStrings.themeSystem),
            subtitle: const Text('Folgt Systemeinstellungen'),
            value: AppThemeMode.system,
            groupValue: currentTheme,
            onChanged: (value) {
              if (value != null) {
                ref.read(settingsProvider.notifier).setTheme(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, WidgetRef ref, user) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Konto-Verwaltung',
            style: AppTextStyles.heading3.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: const Text('Anmeldedaten verwalten'),
            subtitle: const Text('Passwörter ändern oder löschen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showCredentialsDialog(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Alle Daten löschen',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            subtitle: const Text('App zurücksetzen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showResetDialog(context, ref);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.about,
            style: AppTextStyles.heading3.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('${AppStrings.version} ${AppConfig.appVersion}'),
            subtitle: const Text(AppConfig.appName),
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('BBZ Rendsburg-Eckernförde'),
            subtitle: const Text('www.bbz-rd-eck.de'),
          ),
        ],
      ),
    );
  }

  void _showCredentialsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anmeldedaten'),
        content: const Text(
          'Die Verwaltung der Anmeldedaten wird in einer kommenden Version verfügbar sein.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App zurücksetzen?'),
        content: const Text(
          'Alle Daten werden gelöscht und die App wird neu gestartet. '
          'Dieser Vorgang kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () async {
              // Close dialog
              Navigator.pop(context);

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              // Delete all data
              await DatabaseService.instance.deleteDatabase();
              await CredentialService.instance.clearAll();

              // Reload providers
              ref.invalidate(userProvider);
              ref.invalidate(settingsProvider);

              // Close loading and navigate back
              if (context.mounted) {
                Navigator.pop(context); // Close loading
                Navigator.pop(context); // Close settings
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}
