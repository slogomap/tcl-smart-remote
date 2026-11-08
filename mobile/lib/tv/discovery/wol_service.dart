import 'dart:io';
import 'dart:typed_data';
import '../../utils/logger.dart';

class WolService {
  /// Send Wake-on-LAN magic packet to power on a TV in network standby mode.
  /// [macAddress] format: "AA:BB:CC:DD:EE:FF" or "AA-BB-CC-DD-EE-FF"
  static Future<bool> sendWakeOnLan({
    required String macAddress,
    int port = 9,
    String broadcastIp = '255.255.255.255',
  }) async {
    try {
      final cleanMac = macAddress.replaceAll(RegExp(r'[^a-fA-F0-9]'), '');
      if (cleanMac.length != 12) {
        AppLogger.warn('Invalid MAC address length for Wake-on-LAN: $macAddress', 'WoL');
        return false;
      }

      final macBytes = <int>[];
      for (int i = 0; i < 12; i += 2) {
        macBytes.add(int.parse(cleanMac.substring(i, i + 2), radix: 16));
      }

      // 6 bytes of 0xFF followed by 16 repetitions of the MAC address
      final packet = Uint8List(6 + 16 * 6);
      for (int i = 0; i < 6; i++) {
        packet[i] = 0xFF;
      }

      for (int i = 0; i < 16; i++) {
        packet.setRange(6 + i * 6, 6 + (i + 1) * 6, macBytes);
      }

      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final targetAddress = InternetAddress(broadcastIp);
      socket.send(packet, targetAddress, port);
      // Also broadcast on port 7 as fallback
      socket.send(packet, targetAddress, 7);

      socket.close();
      AppLogger.info('Sent Wake-on-LAN magic packet to MAC: $macAddress', 'WoL');
      return true;
    } catch (e) {
      AppLogger.error('Failed to send Wake-on-LAN packet: $e', 'WoL');
      return false;
    }
  }
}
