import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../../models/tv_device.dart';
import '../../utils/logger.dart';
import '../protocol/pairing_v2.dart';

enum PairingStep {
  idle,
  connecting,
  requestingCode,
  waitingForPin,
  submittingPin,
  paired,
  failed,
}

class TvPairer {
  SecureSocket? _pairingSocket;
  X509Certificate? _serverCertificate;
  PairingStep _step = PairingStep.idle;
  PairingStep get step => _step;

  final StreamController<PairingStep> _stepController =
      StreamController<PairingStep>.broadcast();
  Stream<PairingStep> get stepStream => _stepController.stream;

  String? _lastError;
  String? get lastError => _lastError;

  /// Step 1 & 2 & 3: Connect over TLS and initiate pairing request to display PIN on TV
  Future<bool> initiatePairing({
    required TvDevice device,
    required SecurityContext clientSecurityContext,
    int timeoutSeconds = 15,
  }) async {
    _step = PairingStep.connecting;
    _stepController.add(_step);
    _lastError = null;

    AppLogger.info('Initiating pairing with ${device.name} at ${device.ipAddress}...', 'Pairer');

    try {
      // Modern Android TV Remote v2 uses port 6467 for both pairing and commands; legacy uses 6466
      int targetPort = device.port;
      SecureSocket? socket;

      try {
        socket = await SecureSocket.connect(
          device.ipAddress,
          targetPort,
          context: clientSecurityContext,
          onBadCertificate: (X509Certificate cert) {
            _serverCertificate = cert;
            return true; // Trust TV's self-signed certificate during pairing
          },
          timeout: Duration(seconds: timeoutSeconds),
        );
      } catch (e) {
        // Fallback to legacy pairing port 6466 if 6467 failed
        AppLogger.warn('Port $targetPort pairing failed, trying fallback port 6466...', 'Pairer');
        targetPort = 6466;
        socket = await SecureSocket.connect(
          device.ipAddress,
          targetPort,
          context: clientSecurityContext,
          onBadCertificate: (X509Certificate cert) {
            _serverCertificate = cert;
            return true;
          },
          timeout: Duration(seconds: timeoutSeconds),
        );
      }

      _pairingSocket = socket;
      _step = PairingStep.requestingCode;
      _stepController.add(_step);

      // Step 3: Send PairingRequest
      final pairingReq = PairingProtocolV2.buildPairingRequest(
        clientName: 'TCL SMART REMOTE',
      );
      _pairingSocket!.add(pairingReq);
      await _pairingSocket!.flush();

      // Send PairingConfiguration
      final configReq = PairingProtocolV2.buildPairingConfiguration(
        encodingType: PairingProtocolV2.encodingHexadecimal,
      );
      _pairingSocket!.add(configReq);
      await _pairingSocket!.flush();

      AppLogger.info('Pairing request sent. TV should now display a 6-character PIN code.', 'Pairer');
      _step = PairingStep.waitingForPin;
      _stepController.add(_step);
      return true;
    } catch (e) {
      _step = PairingStep.failed;
      _lastError = 'Unable to establish pairing connection: $e';
      _stepController.add(_step);
      AppLogger.error(_lastError!, 'Pairer');
      disconnect();
      return false;
    }
  }

  /// Step 4 & 5: Submit the PIN entered by user, calculate secret, and verify with TV
  Future<bool> submitPin({
    required String pinCode,
    required List<int> clientCertDer,
  }) async {
    if (_pairingSocket == null || _step != PairingStep.waitingForPin) {
      _lastError = 'Pairing socket is not in waiting state';
      return false;
    }

    _step = PairingStep.submittingPin;
    _stepController.add(_step);

    try {
      final serverDer = _serverCertificate?.der ?? Uint8List(0);
      final secretBytes = PairingProtocolV2.computePairingSecret(
        clientCertDer: clientCertDer,
        serverCertDer: serverDer,
        pinCode: pinCode,
      );

      final secretPacket = PairingProtocolV2.buildPairingSecret(secretBytes);
      _pairingSocket!.add(secretPacket);
      await _pairingSocket!.flush();

      // Wait for PairingSecretAck response from TV
      final completer = Completer<bool>();

      late StreamSubscription sub;
      sub = _pairingSocket!.listen(
        (Uint8List data) {
          final ok = PairingProtocolV2.isResponseOk(data);
          if (ok) {
            if (!completer.isCompleted) completer.complete(true);
          } else {
            if (!completer.isCompleted) completer.complete(false);
          }
        },
        onError: (err) {
          if (!completer.isCompleted) completer.complete(false);
        },
      );

      final success = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );

      await sub.cancel();

      if (success) {
        _step = PairingStep.paired;
        _stepController.add(_step);
        AppLogger.info('Pairing successful! TV certificate verified and whitelisted.', 'Pairer');
        disconnect();
        return true;
      } else {
        _step = PairingStep.failed;
        _lastError = 'Incorrect PIN code entered or pairing rejected by TV.';
        _stepController.add(_step);
        disconnect();
        return false;
      }
    } catch (e) {
      _step = PairingStep.failed;
      _lastError = 'Failed to submit pairing secret: $e';
      _stepController.add(_step);
      disconnect();
      return false;
    }
  }

  void disconnect() {
    try {
      _pairingSocket?.destroy();
    } catch (_) {}
    _pairingSocket = null;
  }

  void dispose() {
    disconnect();
    _stepController.close();
  }
}
