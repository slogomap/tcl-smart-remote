import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../models/tv_device.dart';
import '../../utils/logger.dart';

class TvDiscoveryService {
  static const String mdnsServiceV2 = '_androidtvremote2._tcp.local';
  static const String mdnsServiceLegacy = '_androidtvremote._tcp.local';
  static const int mdnsPort = 5353;
  static const String mdnsAddress = '224.0.0.251';

  final StreamController<List<TvDevice>> _discoveredDevicesController =
      StreamController<List<TvDevice>>.broadcast();

  Stream<List<TvDevice>> get discoveredDevicesStream =>
      _discoveredDevicesController.stream;

  final Map<String, TvDevice> _foundDevices = {};
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  /// Start mDNS discovery and local subnet probe
  Future<void> startDiscovery({Duration timeout = const Duration(seconds: 8)}) async {
    if (_isScanning) return;
    _isScanning = true;
    _foundDevices.clear();
    _notify();

    AppLogger.info('Starting local television discovery...', 'Discovery');

    RawDatagramSocket? socket;
    Timer? timer;

    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
        reusePort: false,
      );
      socket.broadcastEnabled = true;
      socket.multicastLoopback = false;

      // Join mDNS multicast group
      try {
        socket.joinMulticast(InternetAddress(mdnsAddress));
      } catch (e) {
        AppLogger.warn('Could not join multicast group: $e', 'Discovery');
      }

      // Listen for incoming mDNS packets
      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket?.receive();
          if (datagram != null) {
            _parseMdnsResponse(datagram);
          }
        }
      });

      // Send mDNS PTR query for Android TV Remote v2
      _sendMdnsQuery(socket, mdnsServiceV2);
      _sendMdnsQuery(socket, mdnsServiceLegacy);

      // Probe active local subnet (e.g. checking current host IP subnet)
      _probeLocalSubnet();

      // Automatically terminate after timeout
      timer = Timer(timeout, () {
        stopDiscovery();
      });
    } catch (e) {
      AppLogger.error('Discovery error: $e', 'Discovery');
      stopDiscovery();
    }
  }

  /// Send standard DNS query over mDNS
  void _sendMdnsQuery(RawDatagramSocket socket, String serviceName) {
    try {
      final List<int> query = [];
      // Transaction ID
      query.addAll([0x00, 0x00]);
      // Flags (standard query)
      query.addAll([0x00, 0x00]);
      // Questions count: 1
      query.addAll([0x00, 0x01]);
      // Answer, Authority, Additional count = 0
      query.addAll([0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);

      // Query name labels
      final parts = serviceName.split('.');
      for (final part in parts) {
        query.add(part.length);
        query.addAll(utf8.encode(part));
      }
      query.add(0x00); // null terminator

      // Type: PTR (0x000C)
      query.addAll([0x00, 0x0C]);
      // Class: IN (0x0001) | unicast-response (0x8000)
      query.addAll([0x00, 0x01]);

      socket.send(query, InternetAddress(mdnsAddress), mdnsPort);
    } catch (e) {
      AppLogger.warn('Failed to send mDNS query: $e', 'Discovery');
    }
  }

  void _parseMdnsResponse(Datagram datagram) {
    try {
      final raw = datagram.data;
      final ip = datagram.address.address;
      final content = String.fromCharCodes(raw);

      if (content.contains('androidtvremote') || content.contains('TCL') || content.contains('Google TV')) {
        // Extract friendly name if available
        String name = 'TCL Google TV';
        final nameMatch = RegExp(r'n=([^;\x00]+)').firstMatch(content);
        if (nameMatch != null && nameMatch.group(1) != null) {
          name = nameMatch.group(1)!;
        } else if (content.contains('TCL')) {
          name = 'TCL Smart TV ($ip)';
        }

        final device = TvDevice(
          id: 'tv-$ip',
          name: name,
          ipAddress: ip,
          port: 6467,
          model: 'TCL Google TV',
        );

        if (!_foundDevices.containsKey(ip)) {
          _foundDevices[ip] = device;
          AppLogger.info('Discovered television at $ip ($name)', 'Discovery');
          _notify();
        }
      }
    } catch (e) {
      // Ignore packet parse failure
    }
  }

  /// Probe local subnet on port 6467 as fallback for routers with mDNS disabled
  Future<void> _probeLocalSubnet() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ipStr = addr.address;
          if (ipStr.startsWith('192.168.') || ipStr.startsWith('10.') || ipStr.startsWith('172.')) {
            final subnet = ipStr.substring(0, ipStr.lastIndexOf('.'));
            _probeSubnetRange(subnet);
          }
        }
      }
    } catch (e) {
      AppLogger.warn('Subnet probe fallback not available: $e', 'Discovery');
    }
  }

  Future<void> _probeSubnetRange(String subnetPrefix) async {
    // Probe common TV IP assignments quickly with short timeout
    final commonIps = [
      '$subnetPrefix.10',
      '$subnetPrefix.50',
      '$subnetPrefix.100',
      '$subnetPrefix.101',
      '$subnetPrefix.105',
      '$subnetPrefix.150',
      '$subnetPrefix.200',
    ];

    for (final ip in commonIps) {
      if (!_isScanning) break;
      _probeSingleIp(ip);
    }
  }

  Future<void> _probeSingleIp(String ip) async {
    try {
      final socket = await Socket.connect(
        ip,
        6467,
        timeout: const Duration(milliseconds: 600),
      );
      socket.destroy();

      if (!_foundDevices.containsKey(ip)) {
        final device = TvDevice(
          id: 'tv-$ip',
          name: 'TCL TV ($ip)',
          ipAddress: ip,
          port: 6467,
          model: 'TCL Android TV',
        );
        _foundDevices[ip] = device;
        AppLogger.info('Discovered TV via TCP probe: $ip', 'Discovery');
        _notify();
      }
    } catch (_) {
      // Not reachable on port 6467
    }
  }

  void stopDiscovery() {
    _isScanning = false;
    AppLogger.info('Television discovery stopped. Found ${_foundDevices.length} devices.', 'Discovery');
    _notify();
  }

  void _notify() {
    if (!_discoveredDevicesController.isClosed) {
      _discoveredDevicesController.add(_foundDevices.values.toList());
    }
  }

  void dispose() {
    _isScanning = false;
    _discoveredDevicesController.close();
  }
}
