import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/connection_state.dart';
import '../models/tv_command.dart';
import '../models/tv_device.dart';
import '../models/app_shortcut.dart';
import '../services/storage_service.dart';
import '../services/network_service.dart';
import '../services/backend_api_client.dart';
import '../services/diagnostics_service.dart';
import '../tv/connection/tv_connection.dart';
import '../tv/commands/tv_command_runner.dart';
import '../tv/pairing/tv_pairer.dart';
import '../utils/crypto_utils.dart';
import '../utils/logger.dart';

class RemoteProvider extends ChangeNotifier {
  final StorageService _storageService;
  final NetworkService _networkService;
  final BackendApiClient _backendApiClient;
  final DiagnosticsService _diagnosticsService;

  late final TvConnectionManager _connectionManager;
  late final TvCommandRunner _commandRunner;
  late final TvPairer _pairer;

  RemoteConnectionState _state = const RemoteConnectionState();
  RemoteConnectionState get state => _state;

  List<AppShortcut> _shortcuts = [];
  List<AppShortcut> get shortcuts => _shortcuts;

  String? _clientCertPem;
  String? _clientKeyPem;
  Uint8List? _clientCertDer;

  bool _hapticEnabled = true;

  RemoteProvider({
    required StorageService storageService,
    required NetworkService networkService,
    required BackendApiClient backendApiClient,
    required DiagnosticsService diagnosticsService,
  })  : _storageService = storageService,
        _networkService = networkService,
        _backendApiClient = backendApiClient,
        _diagnosticsService = diagnosticsService {
    _connectionManager = TvConnectionManager();
    _commandRunner = TvCommandRunner(_connectionManager);
    _pairer = TvPairer();

    _listenToEvents();
  }

  TvConnectionManager get connectionManager => _connectionManager;
  TvCommandRunner get commandRunner => _commandRunner;
  TvPairer get pairer => _pairer;

  Future<void> init() async {
    _shortcuts = _storageService.getShortcuts();
    final settings = _storageService.getSettings();
    _hapticEnabled = settings.hapticFeedback;
    _connectionManager.enableAutoReconnect(settings.autoReconnect);

    // Initialize or load cryptographic credentials securely
    await _initCryptoCredentials();

    // Check saved devices and auto-connect if available
    final savedDevices = _storageService.getSavedDevices();
    final selectedId = _storageService.getSelectedDeviceId();

    TvDevice? targetDevice;
    if (selectedId != null && savedDevices.isNotEmpty) {
      targetDevice = savedDevices.firstWhere(
        (d) => d.id == selectedId,
        orElse: () => savedDevices.first,
      );
    } else if (savedDevices.isNotEmpty) {
      targetDevice = savedDevices.first;
    }

    if (targetDevice != null) {
      _state = _state.copyWith(
        activeDeviceId: targetDevice.id,
        activeDeviceName: targetDevice.name,
        activeDeviceIp: targetDevice.ipAddress,
        status: DeviceConnectionStatus.disconnected,
      );
      notifyListeners();

      // Connect if TV is already paired
      if (targetDevice.isPaired) {
        connectToDevice(targetDevice);
      }
    }
  }

  Future<void> _initCryptoCredentials() async {
    try {
      _clientCertPem = await _storageService.getClientCertificatePem();
      _clientKeyPem = await _storageService.getClientPrivateKeyPem();

      if (_clientCertPem == null || _clientKeyPem == null) {
        AppLogger.info('Generating new RSA 2048-bit keypair and self-signed X.509 certificate...', 'Security');
        final keyPair = CryptoUtils.generateRsaKeyPair(bitLength: 2048);
        _clientCertDer = CryptoUtils.generateSelfSignedCertificate(
          publicKey: keyPair.publicKey,
          privateKey: keyPair.privateKey,
          commonName: 'TCL SMART REMOTE',
        );

        _clientCertPem = CryptoUtils.encodeToPem(_clientCertDer!, 'CERTIFICATE');
        final privKeyDer = CryptoUtils.privateKeyToPkcs8Der(keyPair.privateKey);
        _clientKeyPem = CryptoUtils.encodeToPem(privKeyDer, 'PRIVATE KEY');

        await _storageService.saveClientCertificatePem(_clientCertPem!);
        await _storageService.saveClientPrivateKeyPem(_clientKeyPem!);
      } else {
        // Derive DER from PEM
        final cleanB64 = _clientCertPem!
            .replaceAll('-----BEGIN CERTIFICATE-----', '')
            .replaceAll('-----END CERTIFICATE-----', '')
            .replaceAll(RegExp(r'\s+'), '');
        _clientCertDer = base64.decode(cleanB64);
      }

      // Configure SecurityContext for TLS sockets
      final secContext = SecurityContext(withTrustedRoots: false);
      secContext.useCertificateChainBytes(utf8.encode(_clientCertPem!));
      secContext.usePrivateKeyBytes(utf8.encode(_clientKeyPem!));

      _connectionManager.setSecurityContext(secContext);
    } catch (e) {
      AppLogger.error('Failed to configure cryptographic credentials: $e', 'Security');
      _diagnosticsService.record(
        level: 'ERROR',
        component: 'Crypto',
        message: 'Cryptographic initialization failed: $e',
      );
    }
  }

  void _listenToEvents() {
    _connectionManager.statusStream.listen((status) {
      _state = _state.copyWith(status: status);
      notifyListeners();
    });

    _networkService.batteryStream.listen((battery) {
      _state = _state.copyWith(batteryLevel: battery);
      notifyListeners();
    });

    _networkService.wifiStatusStream.listen((wifiOk) {
      _state = _state.copyWith(
        isLocalWifiActive: wifiOk,
        status: !wifiOk ? DeviceConnectionStatus.offline : _state.status,
      );
      notifyListeners();
    });
  }

  Future<bool> connectToDevice(TvDevice device) async {
    _state = _state.copyWith(
      activeDeviceId: device.id,
      activeDeviceName: device.name,
      activeDeviceIp: device.ipAddress,
      status: DeviceConnectionStatus.connecting,
      errorMessage: null,
    );
    notifyListeners();

    final ok = await _connectionManager.connect(device);
    if (ok) {
      await _storageService.setSelectedDeviceId(device.id);
      _diagnosticsService.record(
        level: 'INFO',
        component: 'Connection',
        message: 'Connected to ${device.name} at ${device.ipAddress}',
      );
    } else {
      _state = _state.copyWith(
        errorMessage: 'Could not connect to ${device.name}. Ensure TV is turned on and on the same Wi-Fi.',
      );
      notifyListeners();
    }
    return ok;
  }

  Future<void> disconnectCurrent() async {
    _connectionManager.disconnect();
    _state = _state.copyWith(status: DeviceConnectionStatus.disconnected);
    notifyListeners();
  }

  Future<CommandExecutionResult> sendButton(
    TvButtonType buttonType, {
    KeyDirection direction = KeyDirection.click,
  }) async {
    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }

    final result = await _commandRunner.executeButton(buttonType, direction: direction);
    if (!result.success) {
      _state = _state.copyWith(errorMessage: result.message);
      notifyListeners();
      _diagnosticsService.record(
        level: 'WARN',
        component: 'Command',
        message: 'Command $buttonType failed: ${result.message}',
      );
    }
    return result;
  }

  Future<CommandExecutionResult> launchApp(AppShortcut shortcut) async {
    if (_hapticEnabled) {
      HapticFeedback.mediumImpact();
    }

    final result = await _commandRunner.launchApp(
      name: shortcut.name,
      packageId: shortcut.packageId,
      deepLink: shortcut.deepLink,
    );

    if (!result.success) {
      _state = _state.copyWith(errorMessage: result.message);
      notifyListeners();
      _diagnosticsService.record(
        level: 'WARN',
        component: 'AppLaunch',
        message: 'Launch of ${shortcut.name} failed: ${result.message}',
      );
    }
    return result;
  }

  Future<CommandExecutionResult> sendText(String text) async {
    return await _commandRunner.sendText(text);
  }

  void updateHapticSetting(bool enabled) {
    _hapticEnabled = enabled;
  }

  Uint8List get clientCertDer => _clientCertDer ?? Uint8List(0);
}
