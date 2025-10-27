/// BBZCloud Mobile - Main Entry Point
/// 
/// @version 0.1.0

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbzcloud_mobil/core/constants/app_strings.dart';
import 'package:bbzcloud_mobil/core/theme/app_theme.dart';
import 'package:bbzcloud_mobil/presentation/providers/settings_provider.dart';
import 'package:bbzcloud_mobil/presentation/screens/home_screen.dart';
import 'package:bbzcloud_mobil/presentation/screens/welcome_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: BBZCloudApp(),
    ),
  );
}

class BBZCloudApp extends ConsumerWidget {
  const BBZCloudApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isFirstLaunch = ref.watch(isFirstLaunchProvider);

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
      
      // Home - Show WelcomeScreen on first launch
      home: isFirstLaunch ? const WelcomeScreen() : const HomeScreen(),
    );
  }
}
