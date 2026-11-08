import 'dart:async';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import '../utils/logger.dart';

class NetworkService {
  final Battery _battery = Battery();
  Timer? _statusPollTimer;

  final StreamController<int> _batteryController = StreamController<int>.broadcast();
  Stream<int> get batteryStream => _batteryController.stream;

  final StreamController<bool> _wifiStatusController = StreamController<bool>.broadcast();
  Stream<bool> get wifiStatusStream => _wifiStatusController.stream;

  int _lastBattery = 100;
  int get lastBattery => _lastBattery;

  bool _isLocalWifiConnected = true;
  bool get isLocalWifiConnected => _isLocalWifiConnected;

  void startMonitoring() {
    _pollStatus();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _pollStatus());
  }

  Future<void> _pollStatus() async {
    // Battery check
    try {
      final level = await _battery.batteryLevel;
      _lastBattery = level;
      if (!_batteryController.isClosed) _batteryController.add(level);
    } catch (_) {
      // Fallback if simulator/unsupported
      _lastBattery = 95;
    }

    // Local Wi-Fi / IP check
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      bool foundLocalIp = false;
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.')) {
            foundLocalIp = true;
            break;
          }
        }
      }

      _isLocalWifiConnected = foundLocalIp || interfaces.isNotEmpty;
      if (!_wifiStatusController.isClosed) {
        _wifiStatusController.add(_isLocalWifiConnected);
      }
    } catch (e) {
      AppLogger.warn('Network interface check failed: $e', 'Network');
    }
  }

  void stopMonitoring() {
    _statusPollTimer?.cancel();
  }

  void dispose() {
    stopMonitoring();
    _batteryController.close();
    _wifiStatusController.close();
  }
}
