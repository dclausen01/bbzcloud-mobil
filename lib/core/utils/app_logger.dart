/// BBZCloud Mobile - Application Logger
/// 
/// Centralized logging utility for better debugging and error tracking
/// 
/// @version 0.1.0

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Singleton logger instance for the entire app
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;

  late final Logger _logger;

  AppLogger._internal() {
    _logger = Logger(
      filter: _CustomFilter(),
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      output: _CustomOutput(),
    );
  }

  /// Log debug message
  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal error message
  void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log trace message (verbose)
  void trace(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// Close logger resources
  void close() {
    _logger.close();
  }
}

/// Custom filter to control which logs are shown
class _CustomFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // In release mode, only log warnings and above
    if (kReleaseMode) {
      return event.level.index >= Level.warning.index;
    }
    // In debug mode, log everything
    return true;
  }
}

/// Custom output to handle where logs go
class _CustomOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // In debug mode, print to console
    if (kDebugMode) {
      for (var line in event.lines) {
        // ignore: avoid_print
        print(line);
      }
    }
    
    // In production, you could send logs to a crash reporting service
    // like Firebase Crashlytics, Sentry, etc.
    if (kReleaseMode && event.level.index >= Level.error.index) {
      // TODO: Send to crash reporting service
      // Example: FirebaseCrashlytics.instance.log(event.lines.join('\n'));
    }
  }
}

/// Extension methods for easier logging
extension LoggerExtension on Object {
  void logDebug([dynamic error, StackTrace? stackTrace]) {
    AppLogger().debug(toString(), error, stackTrace);
  }

  void logInfo([dynamic error, StackTrace? stackTrace]) {
    AppLogger().info(toString(), error, stackTrace);
  }

  void logWarning([dynamic error, StackTrace? stackTrace]) {
    AppLogger().warning(toString(), error, stackTrace);
  }

  void logError([dynamic error, StackTrace? stackTrace]) {
    AppLogger().error(toString(), error, stackTrace);
  }
}

/// Global logger instance
final logger = AppLogger();
