import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/constants.dart';
import '../models/app_settings.dart';
import '../models/tv_device.dart';
import '../models/app_shortcut.dart';
import '../utils/logger.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ===========================================================================
  // SECURE STORAGE (Android Keystore / iOS Keychain)
  // NEVER write private keys or pairing certificates to plaintext files or prefs.
  // ===========================================================================

  Future<void> saveClientCertificatePem(String pem) async {
    await _secureStorage.write(key: AppConstants.secKeyClientCert, value: pem);
  }

  Future<String?> getClientCertificatePem() async {
    return await _secureStorage.read(key: AppConstants.secKeyClientCert);
  }

  Future<void> saveClientPrivateKeyPem(String pem) async {
    await _secureStorage.write(key: AppConstants.secKeyClientPrivateKey, value: pem);
  }

  Future<String?> getClientPrivateKeyPem() async {
    return await _secureStorage.read(key: AppConstants.secKeyClientPrivateKey);
  }

  Future<void> saveServerCertificate(String deviceId, String pem) async {
    await _secureStorage.write(key: '${AppConstants.secKeyServerCertPrefix}$deviceId', value: pem);
  }

  Future<String?> getServerCertificate(String deviceId) async {
    return await _secureStorage.read(key: '${AppConstants.secKeyServerCertPrefix}$deviceId');
  }

  Future<void> removeDeviceCredentials(String deviceId) async {
    await _secureStorage.delete(key: '${AppConstants.secKeyServerCertPrefix}$deviceId');
  }

  // ===========================================================================
  // LOCAL-FIRST PERSISTENCE (SharedPreferences)
  // Saved TV devices, local theme, haptics, shortcuts
  // ===========================================================================

  List<TvDevice> getSavedDevices() {
    final raw = _prefs.getString(AppConstants.prefSavedDevices);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(raw);
      return list.map((item) => TvDevice.fromJson(item)).toList();
    } catch (e) {
      AppLogger.warn('Failed to parse saved devices JSON: $e', 'Storage');
      return [];
    }
  }

  Future<void> saveDevices(List<TvDevice> devices) async {
    final raw = json.encode(devices.map((d) => d.toJson()).toList());
    await _prefs.setString(AppConstants.prefSavedDevices, raw);
  }

  Future<void> saveOrUpdateDevice(TvDevice device) async {
    final list = getSavedDevices();
    final index = list.indexWhere((d) => d.id == device.id || d.ipAddress == device.ipAddress);
    if (index >= 0) {
      list[index] = device;
    } else {
      list.add(device);
    }
    await saveDevices(list);
  }

  Future<void> removeDevice(String deviceId) async {
    final list = getSavedDevices();
    list.removeWhere((d) => d.id == deviceId);
    await saveDevices(list);
    await removeDeviceCredentials(deviceId);
  }

  String? getSelectedDeviceId() {
    return _prefs.getString(AppConstants.prefSelectedDeviceId);
  }

  Future<void> setSelectedDeviceId(String? id) async {
    if (id == null) {
      await _prefs.remove(AppConstants.prefSelectedDeviceId);
    } else {
      await _prefs.setString(AppConstants.prefSelectedDeviceId, id);
    }
  }

  AppSettings getSettings() {
    return AppSettings(
      themeMode: _prefs.getString(AppConstants.prefThemeMode) ?? 'dark',
      hapticFeedback: _prefs.getBool(AppConstants.prefHapticFeedback) ?? true,
      buttonSound: _prefs.getBool(AppConstants.prefButtonSound) ?? false,
      autoReconnect: _prefs.getBool(AppConstants.prefAutoReconnect) ?? true,
      backendUrl: _prefs.getString(AppConstants.prefBackendUrl) ?? AppConstants.defaultBackendUrl,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(AppConstants.prefThemeMode, settings.themeMode);
    await _prefs.setBool(AppConstants.prefHapticFeedback, settings.hapticFeedback);
    await _prefs.setBool(AppConstants.prefButtonSound, settings.buttonSound);
    await _prefs.setBool(AppConstants.prefAutoReconnect, settings.autoReconnect);
    await _prefs.setString(AppConstants.prefBackendUrl, settings.backendUrl);
  }

  List<AppShortcut> getShortcuts() {
    final raw = _prefs.getString('pref_app_shortcuts');
    if (raw == null) return AppShortcut.defaultShortcuts;
    try {
      final List<dynamic> list = json.decode(raw);
      return list.map((item) => AppShortcut.fromJson(item)).toList();
    } catch (_) {
      return AppShortcut.defaultShortcuts;
    }
  }

  Future<void> saveShortcuts(List<AppShortcut> shortcuts) async {
    final raw = json.encode(shortcuts.map((s) => s.toJson()).toList());
    await _prefs.setString('pref_app_shortcuts', raw);
  }
}
