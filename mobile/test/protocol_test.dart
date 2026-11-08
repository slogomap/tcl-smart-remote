import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcl_smart_remote/tv/protocol/android_tv_v2.dart';
import 'package:tcl_smart_remote/tv/protocol/key_codes.dart';
import 'package:tcl_smart_remote/tv/protocol/pairing_v2.dart';

void main() {
  group('Android TV Remote v2 Protocol Tests', () {
    test('Varint encoding and decoding', () {
      final encoded = AndroidTvRemoteV2Protocol.encodeVarint(624);
      final decoded = AndroidTvRemoteV2Protocol.decodeVarint(Uint8List.fromList(encoded), 0);
      expect(decoded[0], equals(624));
    });

    test('Key inject message building', () {
      final packet = AndroidTvRemoteV2Protocol.buildRemoteKeyInject(
        keyCode: AndroidKeyCodes.keycodeDpadUp,
        direction: AndroidKeyCodes.directionShort,
      );
      expect(packet.isNotEmpty, isTrue);

      // Verify packet structure
      final parsed = AndroidTvRemoteV2Protocol.parsePacket(packet);
      expect(parsed['fieldNumber'], equals(AndroidTvRemoteV2Protocol.fieldRemoteKeyInject));
    });

    test('Ping response packet building', () {
      final packet = AndroidTvRemoteV2Protocol.buildPingResponse(42);
      expect(packet.isNotEmpty, isTrue);

      final parsed = AndroidTvRemoteV2Protocol.parsePacket(packet);
      expect(parsed['type'], equals('ping_response'));
    });

    test('App link packet building for YouTube and Spotify', () {
      final ytPacket = AndroidTvRemoteV2Protocol.buildRemoteAppLink('https://www.youtube.com');
      expect(ytPacket.isNotEmpty, isTrue);

      final spotPacket = AndroidTvRemoteV2Protocol.buildRemoteAppLink('spotify://');
      expect(spotPacket.isNotEmpty, isTrue);
    });
  });

  group('Pairing Protocol v2 Tests', () {
    test('Pairing request packet structure', () {
      final req = PairingProtocolV2.buildPairingRequest(
        clientName: 'TCL SMART REMOTE',
      );
      expect(req.isNotEmpty, isTrue);
      expect(req[0], equals(req.length - 1)); // 1-byte length prefix
    });

    test('Pairing secret calculation consistency', () {
      final clientCert = utf8.encode('TEST_CLIENT_CERTIFICATE_DER');
      final serverCert = utf8.encode('TEST_SERVER_CERTIFICATE_DER');
      const pin = 'A1B2C3';

      final secret1 = PairingProtocolV2.computePairingSecret(
        clientCertDer: clientCert,
        serverCertDer: serverCert,
        pinCode: pin,
      );

      final secret2 = PairingProtocolV2.computePairingSecret(
        clientCertDer: clientCert,
        serverCertDer: serverCert,
        pinCode: pin,
      );

      expect(secret1, equals(secret2));
      expect(secret1.length, equals(32)); // SHA-256 output length
    });
  });
}
