// lib/services/sync_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/log_entry.dart';

class SyncService {
  final StreamController<LogEntry> _logController =
      StreamController<LogEntry>.broadcast();
  final StreamController<bool> _syncingController =
      StreamController<bool>.broadcast();

  Stream<LogEntry> get logStream => _logController.stream;
  Stream<bool> get syncingStream => _syncingController.stream;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  DateTime? lastSync;
  Process? _currentProcess;

  Future<void> runSync({
    required String pythonPath,
    required String scriptPath,
    List<String> arguments = const [],
  }) async {
    if (_isSyncing) return;

    _isSyncing = true;
    _syncingController.add(true);

    _addLog(LogLevel.info, 'Starting sync process...');

    try {
      final args = [scriptPath, ...arguments];

      _currentProcess = await Process.start(
        pythonPath,
        args,
        runInShell: Platform.isWindows,
      );

      // Listen to stdout
      _currentProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.trim().isEmpty) return;
        final entry = _parseLine(line);
        _logController.add(entry);
      });

      // Listen to stderr
      _currentProcess!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.trim().isEmpty) return;
        _logController.add(LogEntry(
          timestamp: DateTime.now(),
          level: LogLevel.error,
          message: line,
        ));
      });

      final exitCode = await _currentProcess!.exitCode;

      if (exitCode == 0) {
        lastSync = DateTime.now();
        _addLog(LogLevel.success,
            'Sync completed successfully (exit code: $exitCode)');
      } else {
        _addLog(LogLevel.error, 'Sync failed with exit code: $exitCode');
      }
    } on ProcessException catch (e) {
      _addLog(LogLevel.error, 'Failed to start process: ${e.message}');
    } catch (e) {
      _addLog(LogLevel.error, 'Unexpected error: $e');
    } finally {
      _isSyncing = false;
      _currentProcess = null;
      _syncingController.add(false);
    }
  }

  LogEntry _parseLine(String line) {
    final regex = RegExp(
      r'^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s*\|\s*(\w+)\s*\|\s*(.*)',
      dotAll: true,
    );

    final match = regex.firstMatch(line);
    if (match != null) {
      final levelStr = match.group(2)!.trim().toUpperCase();
      final message = match.group(3)!.trim();

      LogLevel level;
      switch (levelStr) {
        case 'INFO':
          level = LogLevel.success;
          break;
        case 'ERROR':
          level = LogLevel.error;
          break;
        case 'WARNING':
        case 'WARN':
          level = LogLevel.warning;
          break;
        default:
          level = LogLevel.info;
      }

      return LogEntry(
          timestamp: DateTime.now(), level: level, message: message);
    }

    // Fallback
    final upper = line.toUpperCase();
    LogLevel level;
    if (upper.contains('ERROR') ||
        upper.contains('FAIL') ||
        upper.contains('EXCEPTION')) {
      level = LogLevel.error;
    } else if (upper.contains('WARN')) {
      level = LogLevel.warning;
    } else if (upper.contains('SUCCESS') ||
        upper.contains('DONE') ||
        upper.contains('COMPLETE')) {
      level = LogLevel.success;
    } else {
      level = LogLevel.info;
    }

    return LogEntry(timestamp: DateTime.now(), level: level, message: line);
  }

  void _addLog(LogLevel level, String message) {
    _logController.add(LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
    ));
  }

  void stopSync() {
    _currentProcess?.kill();
    _addLog(LogLevel.warning, 'Sync manually stopped by user.');
  }

  void clearLogs() {
    // Signal to clear — handled externally via state
  }

  void dispose() {
    _logController.close();
    _syncingController.close();
  }
}
