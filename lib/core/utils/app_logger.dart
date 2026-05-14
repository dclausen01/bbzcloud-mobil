/// BBZCloud Mobile - Application Logger
///
/// Centralized logging utility for better debugging and error tracking.
/// Behält zusätzlich einen In-Memory-Ringbuffer mit den letzten 500
/// Einträgen, damit Logs auch ohne USB/adb über den In-App
/// Log-Viewer angeschaut werden können.

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Eintrag im Ringbuffer.
class LogEntry {
  final DateTime timestamp;
  final Level level;
  final String message;
  final String? error;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
  });

  String formatLine() {
    final t = timestamp.toIso8601String().substring(11, 23); // HH:MM:SS.mmm
    final lvl = level.name.toUpperCase().padRight(7);
    final body = error == null ? message : '$message\n    err: $error';
    return '[$t] $lvl $body';
  }
}

/// Singleton logger instance for the entire app
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;

  late final Logger _logger;

  /// Ringbuffer: behält die letzten 500 Einträge.
  static const int _maxBufferSize = 500;
  final Queue<LogEntry> _buffer = Queue<LogEntry>();
  final List<VoidCallback> _listeners = [];

  AppLogger._internal() {
    _logger = Logger(
      filter: _CustomFilter(),
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      output: _CustomOutput(),
    );
  }

  /// Snapshot des aktuellen Buffer-Inhalts (älteste zuerst).
  List<LogEntry> getBuffer() => List<LogEntry>.unmodifiable(_buffer);

  /// Buffer leeren.
  void clearBuffer() {
    _buffer.clear();
    _notifyListeners();
  }

  /// UI-Komponenten können sich auf neue Einträge subscriben.
  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);

  void _notifyListeners() {
    for (final l in List<VoidCallback>.from(_listeners)) {
      try {
        l();
      } catch (_) {}
    }
  }

  void _appendToBuffer(Level level, dynamic message, dynamic error) {
    _buffer.add(LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message?.toString() ?? '',
      error: error?.toString(),
    ));
    while (_buffer.length > _maxBufferSize) {
      _buffer.removeFirst();
    }
    _notifyListeners();
  }

  /// Log debug message
  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _appendToBuffer(Level.debug, message, error);
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _appendToBuffer(Level.info, message, error);
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _appendToBuffer(Level.warning, message, error);
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _appendToBuffer(Level.error, message, error);
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal error message
  void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _appendToBuffer(Level.fatal, message, error);
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log trace message (verbose)
  void trace(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _appendToBuffer(Level.trace, message, error);
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// Close logger resources
  void close() {
    _logger.close();
  }
}

/// Filter für den Logger.output. Der Buffer wird IMMER befüllt
/// (vor diesem Filter), damit der In-App-Viewer auch im Release-Build
/// info-Logs zeigt.
class _CustomFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // Logcat: in Release nur warning+ (ruhiger), in Debug alles.
    if (kReleaseMode) {
      return event.level.index >= Level.warning.index;
    }
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
