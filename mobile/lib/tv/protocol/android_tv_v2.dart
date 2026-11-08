import 'dart:convert';
import 'dart:typed_data';
import 'key_codes.dart';

/// Wire encoder and decoder for Android TV Remote Service v2 Protobuf protocol.
class AndroidTvRemoteV2Protocol {
  // Field Numbers in RemoteMessage (proto v2)
  static const int fieldRemoteConfigure = 1;
  static const int fieldRemotePingRequest = 2;
  static const int fieldRemotePingResponse = 3;
  static const int fieldRemoteKeyInject = 7;
  static const int fieldRemoteImeKeyInject = 11;
  static const int fieldRemoteAppLink = 13;
  static const int fieldRemoteVoiceBegin = 14;
  static const int fieldRemoteVoicePayload = 15;
  static const int fieldRemoteVoiceEnd = 16;
  static const int fieldRemoteReset = 20;

  // Wire Types
  static const int wireVarint = 0;
  static const int wireLengthDelimited = 2;

  /// Encode an integer into Protobuf Varint bytes
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

  /// Decode Varint from buffer starting at [offset], returns [value, newOffset]
  static List<int> decodeVarint(Uint8List buffer, int offset) {
    int result = 0;
    int shift = 0;
    int pos = offset;

    while (pos < buffer.length) {
      final byte = buffer[pos++];
      result |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) {
        return [result, pos];
      }
      shift += 7;
    }
    return [result, pos];
  }

  /// Create Protobuf field tag: (fieldNumber << 3) | wireType
  static List<int> encodeTag(int fieldNumber, int wireType) {
    return encodeVarint((fieldNumber << 3) | wireType);
  }

  /// Encode a length-delimited sub-message or string/bytes
  static List<int> encodeLengthDelimited(int fieldNumber, List<int> payload) {
    final List<int> result = [];
    result.addAll(encodeTag(fieldNumber, wireLengthDelimited));
    result.addAll(encodeVarint(payload.length));
    result.addAll(payload);
    return result;
  }

  /// Encode a varint field
  static List<int> encodeVarintField(int fieldNumber, int value) {
    final List<int> result = [];
    result.addAll(encodeTag(fieldNumber, wireVarint));
    result.addAll(encodeVarint(value));
    return result;
  }

  /// Build RemoteConfigure packet (code: 624)
  static Uint8List buildRemoteConfigure({
    int code = 624,
    String model = 'TCL Android Remote',
    String vendor = 'TCL',
  }) {
    final List<int> deviceInfo = [];
    // DeviceInfo.model (field 1)
    deviceInfo.addAll(encodeLengthDelimited(1, utf8.encode(model)));
    // DeviceInfo.vendor (field 2)
    deviceInfo.addAll(encodeLengthDelimited(2, utf8.encode(vendor)));
    // DeviceInfo.unknown (field 3)
    deviceInfo.addAll(encodeVarintField(3, 1));
    // DeviceInfo.app_version (field 4)
    deviceInfo.addAll(encodeLengthDelimited(4, utf8.encode('1.0.0')));

    final List<int> remoteConfigure = [];
    // RemoteConfigure.code (field 1)
    remoteConfigure.addAll(encodeVarintField(1, code));
    // RemoteConfigure.device_info (field 2)
    remoteConfigure.addAll(encodeLengthDelimited(2, deviceInfo));

    final List<int> message = encodeLengthDelimited(fieldRemoteConfigure, remoteConfigure);
    return frameMessage(message);
  }

  /// Build RemoteKeyInject packet
  /// direction: 2 = SHORT (click), 3 = START (down), 4 = END (up), 1 = LONG
  static Uint8List buildRemoteKeyInject({
    required int keyCode,
    int direction = AndroidKeyCodes.directionShort,
  }) {
    final List<int> keyInject = [];
    // KeyInject.direction (field 1)
    keyInject.addAll(encodeVarintField(1, direction));
    // KeyInject.key_code (field 2)
    keyInject.addAll(encodeVarintField(2, keyCode));

    final List<int> message = encodeLengthDelimited(fieldRemoteKeyInject, keyInject);
    return frameMessage(message);
  }

  /// Build RemotePingResponse packet replying to TV keepalive ping
  static Uint8List buildPingResponse(int pingVal1) {
    final List<int> pingResponse = [];
    pingResponse.addAll(encodeVarintField(1, pingVal1));

    final List<int> message = encodeLengthDelimited(fieldRemotePingResponse, pingResponse);
    return frameMessage(message);
  }

  /// Build RemoteAppLink packet for deep linking apps (YouTube, Spotify, etc.)
  static Uint8List buildRemoteAppLink(String uri) {
    final List<int> appLinkPayload = [];
    // AppLink.app_link (field 1)
    appLinkPayload.addAll(encodeLengthDelimited(1, utf8.encode(uri)));

    final List<int> message = encodeLengthDelimited(fieldRemoteAppLink, appLinkPayload);
    return frameMessage(message);
  }

  /// Build RemoteVoiceBegin packet
  static Uint8List buildVoiceBegin() {
    final List<int> voiceBegin = [];
    final List<int> message = encodeLengthDelimited(fieldRemoteVoiceBegin, voiceBegin);
    return frameMessage(message);
  }

  /// Build RemoteVoiceEnd packet
  static Uint8List buildVoiceEnd() {
    final List<int> voiceEnd = [];
    final List<int> message = encodeLengthDelimited(fieldRemoteVoiceEnd, voiceEnd);
    return frameMessage(message);
  }

  /// Frame a protobuf message with Varint length prefix for socket wire transmission
  static Uint8List frameMessage(List<int> messageBytes) {
    final List<int> lengthBytes = encodeVarint(messageBytes.length);
    final Uint8List framed = Uint8List(lengthBytes.length + messageBytes.length);
    framed.setAll(0, lengthBytes);
    framed.setAll(lengthBytes.length, messageBytes);
    return framed;
  }

  /// Parse incoming framed packet and detect message type
  static Map<String, dynamic> parsePacket(Uint8List rawBytes) {
    if (rawBytes.isEmpty) return {'type': 'unknown'};

    // Decode length prefix
    final lenDecode = decodeVarint(rawBytes, 0);
    int offset = lenDecode[1];

    if (offset >= rawBytes.length) {
      return {'type': 'empty'};
    }

    final tagDecode = decodeVarint(rawBytes, offset);
    final tag = tagDecode[0];
    final fieldNumber = tag >> 3;
    final wireType = tag & 0x07;

    switch (fieldNumber) {
      case fieldRemotePingRequest:
        // Ping request from TV
        return {
          'type': 'ping_request',
          'field': fieldNumber,
          'wireType': wireType,
          'raw': rawBytes,
        };
      case fieldRemotePingResponse:
        return {'type': 'ping_response'};
      case fieldRemoteConfigure:
        return {'type': 'configure_ack'};
      case fieldRemoteReset:
        return {'type': 'reset'};
      default:
        return {'type': 'message', 'fieldNumber': fieldNumber};
    }
  }
}
