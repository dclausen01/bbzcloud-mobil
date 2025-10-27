/// BBZCloud Mobile - Navigation Apps Configuration
/// 
/// Configuration for all available apps in the BBZCloud ecosystem
/// 
/// @version 0.1.0

import 'package:flutter/material.dart';

/// Native App Configuration
class NativeAppConfig {
  final bool hasNativeApp;
  final bool preferNativeOnSmartphone;
  final String? iosScheme;
  final String? androidScheme;
  final String? androidPackage;
  final String? iosAppStoreId;

  const NativeAppConfig({
    required this.hasNativeApp,
    this.preferNativeOnSmartphone = false,
    this.iosScheme,
    this.androidScheme,
    this.androidPackage,
    this.iosAppStoreId,
  });
}

/// App Configuration Model
class AppItem {
  final String id;
  final String title;
  final String url;
  final IconData icon;
  final Color color;
  final String? description;
  final bool requiresAuth;
  final bool teacherOnly;
  final NativeAppConfig? nativeApp;
  final bool isVisible;
  final int orderIndex;

  const AppItem({
    required this.id,
    required this.title,
    required this.url,
    required this.icon,
    required this.color,
    this.description,
    this.requiresAuth = false,
    this.teacherOnly = false,
    this.nativeApp,
    this.isVisible = true,
    this.orderIndex = 999,
  });
}

/// URLs Configuration
class AppUrls {
  AppUrls._();

  // Organization website
  static const String bbzWebsite = 'https://www.bbz-rd-eck.de';

  // Educational platforms
  static const String schulcloud = 'https://app.schul.cloud';
  static const String moodle = 'https://portal.bbz-rd-eck.com';

  // Communication tools
  static const String bbb = 'https://bbb.bbz-rd-eck.de/b/signin';
  static const String outlook = 'https://exchange.bbz-rd-eck.de/owa/#path=/mail';

  // Productivity applications
  static const String cryptpad = 'https://cryptpad.fr/drive';
  static const String taskcards = 'https://bbzrdeck.taskcards.app';

  // Administrative tools
  static const String webuntis = 'https://neilo.webuntis.com/WebUntis/?school=bbz-rd-eck#/basic/login';
  static const String fobizz = 'https://tools.fobizz.com/';
  static const String wiki = 'https://wiki.bbz-rd-eck.com';
  static const String antraege = 'https://dms.bbz-rd-eck.de/';
}

/// Navigation Apps
class NavigationApps {
  NavigationApps._();

  static final Map<String, AppItem> apps = {
    'schulcloud': const AppItem(
      id: 'schulcloud',
      title: 'schul.cloud',
      url: AppUrls.schulcloud,
      icon: Icons.cloud,
      color: Color(0xFFFFA500),
      description: 'Chat & Dateiablage',
      requiresAuth: true,
      orderIndex: 1,
    ),
    'moodle': AppItem(
      id: 'moodle',
      title: 'Moodle',
      url: AppUrls.moodle,
      icon: Icons.book,
      color: const Color(0xFFF98012),
      description: 'Lernmanagementsystem',
      requiresAuth: true,
      orderIndex: 2,
      nativeApp: const NativeAppConfig(
        hasNativeApp: true,
        preferNativeOnSmartphone: false,
        iosScheme: 'moodlemobile://',
        androidScheme: 'moodlemobile://',
        androidPackage: 'com.moodle.moodlemobile',
        iosAppStoreId: '633359593',
      ),
    ),
    'outlook': const AppItem(
      id: 'outlook',
      title: 'Outlook',
      url: AppUrls.outlook,
      icon: Icons.mail,
      color: Color(0xFF0078D4),
      description: 'E-Mail-Client',
      requiresAuth: true,
      teacherOnly: true,
      orderIndex: 3,
    ),
    'webuntis': const AppItem(
      id: 'webuntis',
      title: 'WebUntis',
      url: AppUrls.webuntis,
      icon: Icons.calendar_today,
      color: Color(0xFFFF8800),
      description: 'Stundenplan',
      requiresAuth: true,
      orderIndex: 4,
    ),
    'bbb': const AppItem(
      id: 'bbb',
      title: 'BigBlueButton',
      url: AppUrls.bbb,
      icon: Icons.videocam,
      color: Color(0xFF0D3B66),
      description: 'Videokonferenzen',
      requiresAuth: true,
      orderIndex: 5,
    ),
    'wiki': const AppItem(
      id: 'wiki',
      title: 'Intranet',
      url: AppUrls.wiki,
      icon: Icons.library_books,
      color: Color(0xFF2D5F2E),
      description: 'Interne Dokumentation',
      orderIndex: 6,
    ),
    'taskcards': const AppItem(
      id: 'taskcards',
      title: 'TaskCards',
      url: AppUrls.taskcards,
      icon: Icons.view_module,
      color: Color(0xFFFF6B6B),
      description: 'Digitale Aufgabenkarten',
      requiresAuth: true,
      orderIndex: 7,
    ),
    'cryptpad': const AppItem(
      id: 'cryptpad',
      title: 'CryptPad',
      url: AppUrls.cryptpad,
      icon: Icons.lock,
      color: Color(0xFF4591C4),
      description: 'Verschlüsselte Dokumente',
      orderIndex: 8,
    ),
    'fobizz': const AppItem(
      id: 'fobizz',
      title: 'Fobizz Tools',
      url: AppUrls.fobizz,
      icon: Icons.construction,
      color: Color(0xFFA71930),
      description: 'Bildungstools',
      teacherOnly: true,
      orderIndex: 9,
    ),
    'antraege': const AppItem(
      id: 'antraege',
      title: 'Anträge',
      url: AppUrls.antraege,
      icon: Icons.description,
      color: Color(0xFF5A5A5A),
      description: 'Formulare & Dokumente',
      teacherOnly: true,
      orderIndex: 10,
    ),
  };

  /// Apps that students can access
  static const List<String> studentAllowedApps = [
    'schulcloud',
    'moodle',
    'cryptpad',
    'webuntis',
    'wiki',
  ];

  /// Get apps filtered by user role
  static Map<String, AppItem> getAppsForRole(String role) {
    if (role == 'teacher' || role == 'admin') {
      return apps;
    }
    
    // For students, filter to only allowed apps
    return Map.fromEntries(
      apps.entries.where((entry) => studentAllowedApps.contains(entry.key)),
    );
  }

  /// Get list of all apps sorted by title
  static List<AppItem> getAllAppsSorted() {
    final appsList = apps.values.toList();
    appsList.sort((a, b) => a.title.compareTo(b.title));
    return appsList;
  }
}

/// Custom App Colors for user-created apps
class CustomAppColors {
  CustomAppColors._();

  static const List<Color> colors = [
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Green
    Color(0xFF8BC34A), // Light Green
    Color(0xFFCDDC39), // Lime
    Color(0xFFFFC107), // Amber
    Color(0xFFFF9800), // Orange
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF9E9E9E), // Grey
    Color(0xFFF44336), // Red
  ];

  static Color getRandomColor() {
    return colors[(DateTime.now().millisecondsSinceEpoch % colors.length)];
  }
}
