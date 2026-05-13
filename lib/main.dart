/// BBZCloud Mobile - Main Entry Point
///
/// @version 0.1.0

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bbzcloud_mobil/core/constants/app_strings.dart';
import 'package:bbzcloud_mobil/core/theme/app_theme.dart';
import 'package:bbzcloud_mobil/data/services/database_service.dart';
import 'package:bbzcloud_mobil/presentation/providers/settings_provider.dart';
import 'package:bbzcloud_mobil/presentation/screens/chat_home_screen.dart';
import 'package:bbzcloud_mobil/presentation/screens/welcome_screen.dart';
import 'package:bbzcloud_mobil/services/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database before starting the app.
  try {
    await DatabaseService.instance.database;
    debugPrint('✅ Database initialized successfully');
  } catch (e) {
    debugPrint('❌ Database initialization error: $e');
  }

  // Firebase – swallows initialization errors so the app still boots
  // when google-services.json is missing (e.g. on web/desktop dev).
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init failed (continuing without push): $e');
  }

  // Shared ProviderContainer so PushService can push state into the same
  // Riverpod scope the UI watches.
  final container = ProviderContainer();
  try {
    await PushService.instance.init(container);
  } catch (e) {
    debugPrint('PushService init failed: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BBZCloudApp(),
    ),
  );
}

class BBZCloudApp extends ConsumerWidget {
  const BBZCloudApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,

      // Localization
      locale: const Locale('de', 'DE'),
      supportedLocales: const [
        Locale('de', 'DE'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Home - Show loading, welcome or home screen
      home: settingsAsync.when(
        data: (settings) => settings.isFirstLaunch
            ? const WelcomeScreen()
            : const ChatHomeScreen(),
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Fehler beim Laden: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(settingsProvider),
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
