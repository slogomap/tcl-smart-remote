import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../../models/connection_state.dart';
import '../../models/tv_device.dart';
import '../../utils/logger.dart';
import '../protocol/android_tv_v2.dart';

class TvConnectionManager {
  SecureSocket? _socket;
  TvDevice? _currentDevice;
  SecurityContext? _securityContext;

  Timer? _keepaliveTimer;
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  bool _shouldAutoReconnect = true;
  int _reconnectAttempts = 0;

  final StreamController<DeviceConnectionStatus> _statusController =
      StreamController<DeviceConnectionStatus>.broadcast();
  Stream<DeviceConnectionStatus> get statusStream => _statusController.stream;

  DeviceConnectionStatus _status = DeviceConnectionStatus.disconnected;
  DeviceConnectionStatus get status => _status;

  TvDevice? get connectedDevice => _currentDevice;

  void setSecurityContext(SecurityContext context) {
    _securityContext = context;
  }

  /// Connect to the specified TV device
  Future<bool> connect(TvDevice device) async {
    if (_status == DeviceConnectionStatus.connected && _currentDevice?.id == device.id) {
      return true;
    }

    _currentDevice = device;
    _updateStatus(DeviceConnectionStatus.connecting);
    _reconnectTimer?.cancel();

    AppLogger.info('Connecting to TV ${device.name} at ${device.ipAddress}:${device.port}...', 'Connection');

    try {
      if (_securityContext == null) {
        throw Exception('Client security context (certificate and key) not configured');
      }

      final socket = await SecureSocket.connect(
        device.ipAddress,
        device.port,
        context: _securityContext,
        onBadCertificate: (X509Certificate cert) {
          // Verify or accept TV certificate
          return true;
        },
        timeout: const Duration(seconds: 5),
      );

      _socket = socket;
      _reconnectAttempts = 0;

      // Listen for incoming messages (ping requests, config acks, etc.)
      _socket!.listen(
        _onDataReceived,
        onError: _onError,
        onDone: _onDisconnected,
        cancelOnError: false,
      );

      // Step 1: Send RemoteConfigure immediately upon connection
      final configPacket = AndroidTvRemoteV2Protocol.buildRemoteConfigure(
        code: 624,
        model: 'TCL Smart Remote',
        vendor: 'Antigravity',
      );
      _socket!.add(configPacket);
      await _socket!.flush();

      _updateStatus(DeviceConnectionStatus.connected);
      AppLogger.info('Successfully connected to TV: ${device.name}', 'Connection');

      _startKeepalive();
      return true;
    } catch (e) {
      AppLogger.error('Connection to TV failed: $e', 'Connection');
      _updateStatus(DeviceConnectionStatus.disconnected);
      _scheduleReconnect();
      return false;
    }
  }

  void _onDataReceived(Uint8List data) {
    try {
      final parsed = AndroidTvRemoteV2Protocol.parsePacket(data);
      if (parsed['type'] == 'ping_request') {
        // TV sent keepalive ping: reply with ping response
        final response = AndroidTvRemoteV2Protocol.buildPingResponse(1);
        sendRaw(response);
      }
    } catch (e) {
      AppLogger.debug('Packet processing notice: $e', 'Connection');
    }
  }

  void _onError(dynamic error) {
    AppLogger.error('Socket error: $error', 'Connection');
    _handleDisconnection();
  }

  void _onDisconnected() {
    AppLogger.warn('TV disconnected socket.', 'Connection');
    _handleDisconnection();
  }

  void _handleDisconnection() {
    _stopKeepalive();
    try {
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
    _updateStatus(DeviceConnectionStatus.disconnected);

    if (_shouldAutoReconnect && !_isDisposed) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!_shouldAutoReconnect || _currentDevice == null || _isDisposed) return;

    _reconnectAttempts++;
    final backoffSeconds = (_reconnectAttempts > 5) ? 15 : (_reconnectAttempts * 2);
    AppLogger.info('Scheduling reconnect in $backoffSeconds seconds (attempt $_reconnectAttempts)...', 'Connection');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
      if (_status != DeviceConnectionStatus.connected && _currentDevice != null) {
        connect(_currentDevice!);
      }
    });
  }

  void _startKeepalive() {
    _stopKeepalive();
    // Send ping every 5 seconds to keep TLS socket alive and detect drops early
    _keepaliveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_status == DeviceConnectionStatus.connected && _socket != null) {
        try {
          final pingPacket = AndroidTvRemoteV2Protocol.buildPingResponse(1);
          _socket!.add(pingPacket);
        } catch (e) {
          _handleDisconnection();
        }
      }
    });
  }

  void _stopKeepalive() {
    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
  }

  /// Send raw packet over active TLS socket
  bool sendRaw(Uint8List packet) {
    if (_socket == null || _status != DeviceConnectionStatus.connected) {
      AppLogger.warn('Cannot send packet: Not connected to TV', 'Connection');
      return false;
    }

    try {
      _socket!.add(packet);
      return true;
    } catch (e) {
      AppLogger.error('Failed to send packet over socket: $e', 'Connection');
      _handleDisconnection();
      return false;
    }
  }

  /// Disconnect manually
  void disconnect({bool preventAutoReconnect = true}) {
    if (preventAutoReconnect) {
      _shouldAutoReconnect = false;
      _reconnectTimer?.cancel();
    }
    _stopKeepalive();
    try {
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
    _updateStatus(DeviceConnectionStatus.disconnected);
  }

  void enableAutoReconnect(bool enable) {
    _shouldAutoReconnect = enable;
  }

  void _updateStatus(DeviceConnectionStatus newStatus) {
    _status = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(_status);
    }
  }

  void dispose() {
    _isDisposed = true;
    disconnect(preventAutoReconnect: true);
    _statusController.close();
  }
}
