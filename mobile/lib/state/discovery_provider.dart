import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/tv_device.dart';
import '../services/storage_service.dart';
import '../services/backend_api_client.dart';
import '../tv/discovery/mdns_discovery.dart';
import '../utils/logger.dart';

class DiscoveryProvider extends ChangeNotifier {
  final StorageService _storageService;
  final BackendApiClient _backendApiClient;
  final TvDiscoveryService _discoveryService = TvDiscoveryService();

  List<TvDevice> _discoveredDevices = [];
  List<TvDevice> get discoveredDevices => _discoveredDevices;

  List<TvDevice> _savedDevices = [];
  List<TvDevice> get savedDevices => _savedDevices;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  StreamSubscription? _scanSub;

  DiscoveryProvider({
    required StorageService storageService,
    required BackendApiClient backendApiClient,
  })  : _storageService = storageService,
        _backendApiClient = backendApiClient {
    _loadSavedDevices();
    _listenToScanner();
  }

  void _loadSavedDevices() {
    _savedDevices = _storageService.getSavedDevices();
    notifyListeners();
  }

  void _listenToScanner() {
    _scanSub = _discoveryService.discoveredDevicesStream.listen((devices) {
      _discoveredDevices = devices;
      notifyListeners();
    });
  }

  Future<void> startScan() async {
    _isScanning = true;
    _discoveredDevices = [];
    notifyListeners();

    await _discoveryService.startDiscovery(timeout: const Duration(seconds: 8));
    _isScanning = false;
    notifyListeners();
  }

  void stopScan() {
    _discoveryService.stopDiscovery();
    _isScanning = false;
    notifyListeners();
  }

  /// Add a television by manual IP entry
  Future<TvDevice> addManualDevice({
    required String name,
    required String ipAddress,
    int port = 6467,
    String? macAddress,
  }) async {
    final cleanIp = ipAddress.trim();
    final device = TvDevice(
      id: 'tv-$cleanIp',
      name: name.trim().isEmpty ? 'TCL TV ($cleanIp)' : name.trim(),
      ipAddress: cleanIp,
      port: port,
      macAddress: macAddress?.trim(),
      model: 'TCL Smart TV',
      isPaired: false,
    );

    await saveDevice(device);
    return device;
  }

  Future<void> saveDevice(TvDevice device) async {
    await _storageService.saveOrUpdateDevice(device);
    _loadSavedDevices();

    // Sync with backend API if online
    _backendApiClient.syncDevice(device);
  }

  Future<void> forgetDevice(String deviceId) async {
    await _storageService.removeDevice(deviceId);
    _loadSavedDevices();

    _backendApiClient.deleteDevice(deviceId);
    AppLogger.info('Device $deviceId forgotten and removed from storage', 'Discovery');
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _discoveryService.dispose();
    super.dispose();
  }
}
