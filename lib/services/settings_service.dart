// lib/services/settings_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyPythonPath = 'python_path';
  static const _keyScriptPath = 'script_path';
  static const _keyArguments = 'arguments';
  static const _keyAutoSync = 'auto_sync';
  static const _keyAutoSyncInterval = 'auto_sync_interval';
  static const _keyLastSync = 'last_sync';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get pythonPath =>
      _prefs.getString(_keyPythonPath) ?? 'python3';

  set pythonPath(String value) =>
      _prefs.setString(_keyPythonPath, value);

  String get scriptPath =>
      _prefs.getString(_keyScriptPath) ?? '';

  set scriptPath(String value) =>
      _prefs.setString(_keyScriptPath, value);

  String get arguments =>
      _prefs.getString(_keyArguments) ?? '';

  set arguments(String value) =>
      _prefs.setString(_keyArguments, value);

  bool get autoSync => _prefs.getBool(_keyAutoSync) ?? false;

  set autoSync(bool value) => _prefs.setBool(_keyAutoSync, value);

  int get autoSyncInterval =>
      _prefs.getInt(_keyAutoSyncInterval) ?? 30;

  set autoSyncInterval(int value) =>
      _prefs.setInt(_keyAutoSyncInterval, value);

  DateTime? get lastSync {
    final s = _prefs.getString(_keyLastSync);
    return s != null ? DateTime.tryParse(s) : null;
  }

  set lastSync(DateTime? value) {
    if (value != null) {
      _prefs.setString(_keyLastSync, value.toIso8601String());
    } else {
      _prefs.remove(_keyLastSync);
    }
  }
}
