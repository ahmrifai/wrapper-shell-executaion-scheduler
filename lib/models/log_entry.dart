// lib/models/log_entry.dart

enum LogLevel { success, error, warning, info }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  String get levelLabel {
    switch (level) {
      case LogLevel.success:
        return 'SUCCESS';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.info:
        return 'INFO';
    }
  }
}
