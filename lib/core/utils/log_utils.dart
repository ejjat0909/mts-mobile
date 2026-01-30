import 'dart:developer' as logg;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Log utility functions
class LogUtils {
  /// Log levels
  static const int levelDebug = 0;
  static const int levelInfo = 1;
  static const int levelWarning = 2;
  static const int levelError = 3;

  /// Current log level
  static int currentLogLevel = levelError;

  /// Log directory path
  static String? _logDirectoryPath;

  /// Current log file path
  static String? _currentLogFilePath;

  /// Date formatter for log file names
  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd', 'en_US');

  /// DateTime formatter for log entries
  static final DateFormat _timestampFormatter = DateFormat(
    'yyyy-MM-dd HH:mm:ss.SSS',
    'en_US',
  );

  /// Initialize log directory and daily log file
  static Future<void> init() async {
    try {
      Directory? appDocDir =
          Platform.isAndroid
              ? await getDownloadsDirectory()
              : await getApplicationDocumentsDirectory();

      // Ensure directory is not null
      appDocDir ??= await getApplicationDocumentsDirectory();
      _logDirectoryPath = '${appDocDir.path}/logs';

      // Create log directory if it doesn't exist
      final logDirectory = Directory(_logDirectoryPath!);
      if (!await logDirectory.exists()) {
        await logDirectory.create(recursive: true);
        prints('Created log directory: $_logDirectoryPath');
      }

      // Set current log file path based on today's date
      await _setCurrentLogFile();

      // Clean up old log files (keep only last 30 days)
      await _cleanupOldLogs();

      prints('Log system initialized. Current log file: $_currentLogFilePath');
    } catch (e) {
      prints('Error initializing log system: $e');
    }
  }

  /// Set current log file based on today's date
  static Future<void> _setCurrentLogFile() async {
    try {
      final today = _dateFormatter.format(DateTime.now());
      _currentLogFilePath = '$_logDirectoryPath/app_log_$today.txt';

      // Create the log file if it doesn't exist
      final logFile = File(_currentLogFilePath!);
      if (!await logFile.exists()) {
        await logFile.create();
        // Write header to new log file
        final header = '=== MTS Application Log - $today ===\n';
        await logFile.writeAsString(header);
      }
    } catch (e) {
      prints('Error setting current log file: $e');
    }
  }

  /// Clean up old log files (keep only last 30 days)
  static Future<void> _cleanupOldLogs() async {
    try {
      if (_logDirectoryPath == null) return;

      final logDirectory = Directory(_logDirectoryPath!);
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));

      await for (final entity in logDirectory.list()) {
        if (entity is File && entity.path.contains('app_log_')) {
          final fileName = entity.path.split('/').last;
          final dateMatch = RegExp(
            r'app_log_(\d{4}-\d{2}-\d{2})\.txt',
          ).firstMatch(fileName);

          if (dateMatch != null) {
            try {
              final fileDate = DateTime.parse(dateMatch.group(1)!);
              if (fileDate.isBefore(cutoffDate)) {
                await entity.delete();
                prints('Deleted old log file: $fileName');
              }
            } catch (e) {
              prints('Error parsing date from log file $fileName: $e');
            }
          }
        }
      }
    } catch (e) {
      prints('Error cleaning up old logs: $e');
    }
  }

  /// Check if we need to rotate to a new daily log file
  static Future<void> _checkDailyRotation() async {
    try {
      final today = _dateFormatter.format(DateTime.now());
      final expectedPath = '$_logDirectoryPath/app_log_$today.txt';

      // If current log file path doesn't match today's date, rotate to new file
      if (_currentLogFilePath != expectedPath) {
        await _setCurrentLogFile();
      }
    } catch (e) {
      prints('Error checking daily rotation: $e');
    }
  }

  /// Log a debug message
  static Future<void> debug(String message) async {
    if (currentLogLevel <= levelDebug) {
      await _writeLog('DEBUG', message);
    }
  }

  /// Log an info message
  static Future<void> info(String message) async {
    if (currentLogLevel <= levelInfo) {
      await _writeLog('INFO', message);
    }
  }

  /// Log a warning message
  static Future<void> warning(String message) async {
    if (currentLogLevel <= levelWarning) {
      await _writeLog('WARNING', message);
    }
  }

  /// Log an error message
  static Future<void> error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) async {
    if (currentLogLevel <= levelError) {
      String logMessage = message;
      if (error != null) {
        logMessage += '\nError: $error';
      }
      if (stackTrace != null) {
        logMessage += '\nStackTrace: $stackTrace';
      }
      await _writeLog('ERROR', logMessage);
    }
  }

  /// Write log to file with proper formatting
  static Future<void> _writeLog(String level, String message) async {
    try {
      // Initialize if not already done
      if (_currentLogFilePath == null) {
        await init();
      }

      if (_currentLogFilePath == null) return;

      // Check if we need to rotate to a new daily log file
      await _checkDailyRotation();

      final logFile = File(_currentLogFilePath!);
      final timestamp = _timestampFormatter.format(DateTime.now());

      // Format the log entry with proper alignment
      final logEntry = '[$timestamp] [$level] $message\n';

      // Print to console in debug mode
      if (kDebugMode) {
        prints(logEntry.trim());
      }

      // Write to file
      await logFile.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      prints('Error writing log: $e');
    }
  }

  /// Get current log file contents
  static Future<String> getLogContents([String? date]) async {
    try {
      if (_currentLogFilePath == null) {
        await init();
      }

      String logFilePath;
      if (date != null) {
        // Get specific date log file
        logFilePath = '$_logDirectoryPath/app_log_$date.txt';
      } else {
        // Get current log file
        logFilePath = _currentLogFilePath ?? '';
      }

      if (logFilePath.isEmpty) return 'Log file not initialized';

      final logFile = File(logFilePath);
      if (await logFile.exists()) {
        return await logFile.readAsString();
      } else {
        return 'Log file does not exist: ${logFile.path}';
      }
    } catch (e) {
      return 'Error reading log file: $e';
    }
  }

  /// Get list of available log files
  static Future<List<String>> getAvailableLogDates() async {
    try {
      if (_logDirectoryPath == null) {
        await init();
      }

      if (_logDirectoryPath == null) return [];

      final logDirectory = Directory(_logDirectoryPath!);
      final List<String> dates = [];

      await for (final entity in logDirectory.list()) {
        if (entity is File && entity.path.contains('app_log_')) {
          final fileName = entity.path.split('/').last;
          final dateMatch = RegExp(
            r'app_log_(\d{4}-\d{2}-\d{2})\.txt',
          ).firstMatch(fileName);

          if (dateMatch != null) {
            dates.add(dateMatch.group(1)!);
          }
        }
      }

      dates.sort((a, b) => b.compareTo(a)); // Sort descending (newest first)
      return dates;
    } catch (e) {
      prints('Error getting available log dates: $e');
      return [];
    }
  }

  /// Clear current log file
  static Future<void> clearCurrentLog() async {
    try {
      if (_currentLogFilePath == null) {
        await init();
      }

      if (_currentLogFilePath == null) return;

      final logFile = File(_currentLogFilePath!);
      if (await logFile.exists()) {
        final today = _dateFormatter.format(DateTime.now());
        final header = '=== MTS Application Log - $today ===\n';
        await logFile.writeAsString(header);
      }
    } catch (e) {
      prints('Error clearing current log: $e');
    }
  }

  /// Clear all log files
  static Future<void> clearAllLogs() async {
    try {
      if (_logDirectoryPath == null) {
        await init();
      }

      if (_logDirectoryPath == null) return;

      final logDirectory = Directory(_logDirectoryPath!);
      await for (final entity in logDirectory.list()) {
        if (entity is File && entity.path.contains('app_log_')) {
          await entity.delete();
          prints('Deleted log file: ${entity.path.split('/').last}');
        }
      }

      // Reinitialize current log file
      await _setCurrentLogFile();
    } catch (e) {
      prints('Error clearing all logs: $e');
    }
  }

  /// Get log directory path
  static String? get logDirectoryPath => _logDirectoryPath;

  /// Get current log file path
  static String? get currentLogFilePath => _currentLogFilePath;

  static void log(String message) {
    logg.log(message);
  }

  // static void prints(Object? message) {
  //   if (kDebugMode) {
  //     prints(message);
  //   }
  // }
}

prints(Object? message) {
  if (kDebugMode) {
    print(message);
  }
}

printsErrorRetrievingList(String modelName) {
  prints(
    'Error retrieving list $modelName from Hive Box, falling back to SQLite',
  );
}
