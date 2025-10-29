/// BBZCloud Mobile - Platform Utilities
/// 
/// Helper functions for platform and screen detection
/// 
/// @version 0.1.0

import 'package:flutter/material.dart';

class PlatformUtils {
  PlatformUtils._();

  /// Check if the current device is a tablet in landscape mode
  /// 
  /// A device is considered a tablet when:
  /// - Screen width >= 600dp (standard tablet breakpoint)
  /// - AND device is in landscape orientation
  /// 
  /// This ensures tablets in portrait mode behave like phones
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    return size.width >= 600 && orientation == Orientation.landscape;
  }

  /// Check if the device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if the device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get the screen width in dp
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get the screen height in dp
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get appropriate drawer width based on platform
  /// - Tablet: 300px
  /// - Phone: 256px (Material Design standard)
  static double getDrawerWidth(BuildContext context) {
    return isTablet(context) ? 300.0 : 256.0;
  }
}
