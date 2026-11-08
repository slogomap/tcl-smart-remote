import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Android TV Remote Service v2 Pairing Protocol Wire Framing and Messages
class PairingProtocolV2 {
  // Protocol Status Codes
  static const int statusUnknown = 0;
  static const int statusOk = 200;
  static const int statusError = 400;
  static const int statusBadConfiguration = 401;
  static const int statusBadSecret = 402;

  // Roles
  static const int roleUnknown = 0;
  static const int roleController = 1;
  static const int roleInput = 2;

  // Encoding Types
  static const int encodingAlphanumeric = 1;
  static const int encodingHexadecimal = 2;

  // Field tags
  static const int fieldProtocolVersion = 1;
  static const int fieldStatus = 2;
  static const int fieldRole = 3;
  static const int fieldServiceName = 4;
  static const int fieldClientName = 5;

  static const int fieldPairingRequest = 10;
  static const int fieldPairingResponse = 11;
  static const int fieldPairingConfiguration = 20;
  static const int fieldPairingConfigurationAck = 21;
  static const int fieldPairingSecret = 30;
  static const int fieldPairingSecretAck = 31;

  /// Helper: Encode Varint
  static List<int> encodeVarint(int value) {
    final List<int> bytes = [];
    int v = value;
    while (v > 0x7F) {
      bytes.add((v & 0x7F) | 0x80);
      v = v >> 7;
    }
    bytes.add(v & 0x7F);
    return bytes;
  }

  /// Helper: Encode Length Delimited
  static List<int> encodeLengthDelimited(int fieldNumber, List<int> payload) {
    final List<int> result = [];
    result.addAll(encodeVarint((fieldNumber << 3) | 2));
    result.addAll(encodeVarint(payload.length));
    result.addAll(payload);
    return result;
  }

  /// Helper: Encode Varint Field
  static List<int> encodeVarintField(int fieldNumber, int value) {
    final List<int> result = [];
    result.addAll(encodeVarint((fieldNumber << 3) | 0));
    result.addAll(encodeVarint(value));
    return result;
  }

  /// Frame pairing packet with 1-byte length prefix (standard for pairing protocol)
  static Uint8List framePairingPacket(List<int> payload) {
    final Uint8List packet = Uint8List(1 + payload.length);
    packet[0] = payload.length;
    packet.setRange(1, packet.length, payload);
    return packet;
  }

  /// Build PairingRequest packet
  static Uint8List buildPairingRequest({
    String clientName = 'TCL SMART REMOTE',
    String serviceName = 'com.google.android.tv.remote.service',
  }) {
    final List<int> req = [];
    // protocol_version = 2
    req.addAll(encodeVarintField(1, 2));
    // status = STATUS_OK
    req.addAll(encodeVarintField(2, statusOk));
    // role = ROLE_CONTROLLER
    req.addAll(encodeVarintField(3, roleController));
    // service_name
    req.addAll(encodeLengthDelimited(4, utf8.encode(serviceName)));
    // client_name
    req.addAll(encodeLengthDelimited(5, utf8.encode(clientName)));

    final List<int> outer = encodeLengthDelimited(fieldPairingRequest, req);
    return framePairingPacket(outer);
  }

  /// Build PairingConfiguration packet
  static Uint8List buildPairingConfiguration({
    int encodingType = encodingHexadecimal,
  }) {
    final List<int> config = [];
    // status = STATUS_OK
    config.addAll(encodeVarintField(1, statusOk));
    // encoding_type
    config.addAll(encodeVarintField(2, encodingType));

    final List<int> outer = encodeLengthDelimited(fieldPairingConfiguration, config);
    return framePairingPacket(outer);
  }

  /// Compute pairing secret from client certificate, server certificate, and PIN code
  /// Algorithm:
  /// client_hash = SHA256(client_cert_der)
  /// server_hash = SHA256(server_cert_der)
  /// secret = SHA256(client_hash + server_hash + pin_bytes)
  static Uint8List computePairingSecret({
    required List<int> clientCertDer,
    required List<int> serverCertDer,
    required String pinCode,
  }) {
    final clientHash = sha256.convert(clientCertDer).bytes;
    final serverHash = sha256.convert(serverCertDer).bytes;

    // Normalize PIN (uppercase, strip whitespace or dashes)
    final cleanPin = pinCode.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
    final pinBytes = utf8.encode(cleanPin);

    final List<int> combined = [];
    combined.addAll(clientHash);
    combined.addAll(serverHash);
    combined.addAll(pinBytes);

    final finalSecret = sha256.convert(combined).bytes;
    return Uint8List.fromList(finalSecret);
  }

  /// Build PairingSecret packet
  static Uint8List buildPairingSecret(List<int> secretBytes) {
    final List<int> secretPayload = [];
    // status = STATUS_OK
    secretPayload.addAll(encodeVarintField(1, statusOk));
    // secret bytes
    secretPayload.addAll(encodeLengthDelimited(2, secretBytes));

    final List<int> outer = encodeLengthDelimited(fieldPairingSecret, secretPayload);
    return framePairingPacket(outer);
  }

  /// Parse response status from TV
  static bool isResponseOk(Uint8List packet) {
    if (packet.isEmpty) return false;
    // Inspect packet for status code 200 (encoded as 0xC8, 0x01 in varint)
    for (int i = 0; i < packet.length - 1; i++) {
      if (packet[i] == 0xC8 && packet[i + 1] == 0x01) {
        return true;
      }
    }
    // Also check for raw 200 byte if single byte
    return packet.contains(200);
  }
}
