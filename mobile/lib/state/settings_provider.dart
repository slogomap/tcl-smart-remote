import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/app_shortcut.dart';
import '../services/storage_service.dart';
import '../services/backend_api_client.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;
  final BackendApiClient _backendApiClient;

  late AppSettings _settings;
  AppSettings get settings => _settings;

  List<AppShortcut> _shortcuts = [];
  List<AppShortcut> get shortcuts => _shortcuts;

  SettingsProvider({
    required StorageService storageService,
    required BackendApiClient backendApiClient,
  })  : _storageService = storageService,
        _backendApiClient = backendApiClient {
    _settings = _storageService.getSettings();
    _shortcuts = _storageService.getShortcuts();
  }

  ThemeMode get themeMode =>
      _settings.themeMode == 'light' ? ThemeMode.light : ThemeMode.dark;

  bool get isDarkMode => _settings.themeMode == 'dark';

  Future<void> toggleTheme(bool dark) async {
    _settings = _settings.copyWith(themeMode: dark ? 'dark' : 'light');
    await _storageService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setHapticFeedback(bool enabled) async {
    _settings = _settings.copyWith(hapticFeedback: enabled);
    await _storageService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setButtonSound(bool enabled) async {
    _settings = _settings.copyWith(buttonSound: enabled);
    await _storageService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setAutoReconnect(bool enabled) async {
    _settings = _settings.copyWith(autoReconnect: enabled);
    await _storageService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setBackendUrl(String url) async {
    _settings = _settings.copyWith(backendUrl: url);
    await _storageService.saveSettings(_settings);
    _backendApiClient.updateBaseUrl(url);
    notifyListeners();
  }

  Future<void> saveShortcuts(List<AppShortcut> list) async {
    _shortcuts = list;
    await _storageService.saveShortcuts(list);
    notifyListeners();
  }

  Future<void> addShortcut(AppShortcut shortcut) async {
    _shortcuts.add(shortcut);
    await saveShortcuts(_shortcuts);
  }

  Future<void> removeShortcut(String id) async {
    _shortcuts.removeWhere((s) => s.id == id);
    await saveShortcuts(_shortcuts);
  }
}
