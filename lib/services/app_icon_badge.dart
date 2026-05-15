/// BBZCloud Mobile - App Badge Helper
///
/// Wrapt `app_badge_plus` mit defensiver Fehlerbehandlung. Wird sowohl
/// vom ChatBridge.setBadge JS-Handler als auch vom PushService nach
/// Empfang einer Nachricht aufgerufen.

import 'package:app_badge_plus/app_badge_plus.dart';

class AppIconBadge {
  AppIconBadge._();

  /// Setzt die Badge-Zahl auf dem Launcher-/Home-Screen-Icon.
  /// Auf nicht-unterstuetzten Launchern (oder Geraeten ohne Badge-
  /// Funktion) wird der Call still verschluckt.
  static Future<void> set(int count) async {
    try {
      final supported = await AppBadgePlus.isSupported();
      if (!supported) return;
      if (count <= 0) {
        await AppBadgePlus.updateBadge(0);
      } else {
        await AppBadgePlus.updateBadge(count);
      }
    } catch (_) {
      // ignore - Badge ist Polish, kein Hard-Requirement.
    }
  }

  static Future<void> clear() => set(0);
}
