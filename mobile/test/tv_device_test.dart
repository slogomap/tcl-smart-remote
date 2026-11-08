import 'package:flutter_test/flutter_test.dart';
import 'package:tcl_smart_remote/models/tv_device.dart';
import 'package:tcl_smart_remote/models/app_shortcut.dart';
import 'package:tcl_smart_remote/models/app_settings.dart';
import 'package:tcl_smart_remote/models/connection_state.dart';

void main() {
  group('TvDevice Model Tests', () {
    test('TvDevice serialization and deserialization', () {
      final device = TvDevice(
        id: 'tv-192.168.1.120',
        name: 'Living Room TCL 65',
        ipAddress: '192.168.1.120',
        port: 6467,
        macAddress: 'AA:BB:CC:DD:EE:FF',
        model: 'TCL Google TV',
        isPaired: true,
      );

      final json = device.toJson();
      expect(json['id'], equals('tv-192.168.1.120'));
      expect(json['is_paired'], equals(1));

      final restored = TvDevice.fromJson(json);
      expect(restored.name, equals('Living Room TCL 65'));
      expect(restored.ipAddress, equals('192.168.1.120'));
      expect(restored.isPaired, isTrue);
    });

    test('TvDevice copyWith preserves values', () {
      final original = TvDevice(
        id: '1',
        name: 'TCL 1',
        ipAddress: '192.168.1.10',
      );

      final updated = original.copyWith(name: 'TCL Renamed', isPaired: true);
      expect(updated.id, equals('1'));
      expect(updated.name, equals('TCL Renamed'));
      expect(updated.isPaired, isTrue);
      expect(updated.ipAddress, equals('192.168.1.10'));
    });
  });

  group('AppShortcut Model Tests', () {
    test('Default shortcuts include YouTube and Spotify', () {
      final defaults = AppShortcut.defaultShortcuts;
      expect(defaults.any((s) => s.name == 'YouTube'), isTrue);
      expect(defaults.any((s) => s.name == 'Spotify'), isTrue);

      final yt = defaults.firstWhere((s) => s.name == 'YouTube');
      expect(yt.packageId, equals('com.google.android.youtube.tv'));
    });
  });

  group('ConnectionState and AppSettings Tests', () {
    test('Connection status defaults to disconnected', () {
      const state = RemoteConnectionState();
      expect(state.status, equals(DeviceConnectionStatus.disconnected));
      expect(state.isConnected, isFalse);
    });

    test('AppSettings defaults', () {
      const settings = AppSettings();
      expect(settings.themeMode, equals('dark'));
      expect(settings.hapticFeedback, isTrue);
    });
  });
}
