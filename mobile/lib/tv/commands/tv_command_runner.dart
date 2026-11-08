import 'dart:async';
import '../protocol/android_tv_v2.dart';
import '../protocol/key_codes.dart';
import '../connection/tv_connection.dart';
import '../discovery/wol_service.dart';
import '../../models/tv_command.dart';
import '../../utils/logger.dart';

class CommandExecutionResult {
  final bool success;
  final String? message;
  final bool isSupported;

  const CommandExecutionResult({
    required this.success,
    this.message,
    this.isSupported = true,
  });

  factory CommandExecutionResult.ok() => const CommandExecutionResult(success: true);
  factory CommandExecutionResult.failed(String reason) => CommandExecutionResult(success: false, message: reason);
  factory CommandExecutionResult.unsupported(String feature) =>
      CommandExecutionResult(success: false, message: '$feature is not supported on this TV', isSupported: false);
}

class TvCommandRunner {
  final TvConnectionManager _connectionManager;

  TvCommandRunner(this._connectionManager);

  /// Send standard key press (click = down followed by up)
  Future<CommandExecutionResult> sendKey(
    int keyCode, {
    KeyDirection direction = KeyDirection.click,
  }) async {
    if (_connectionManager.status != DeviceConnectionStatus.connected) {
      return CommandExecutionResult.failed('Not connected to television');
    }

    try {
      if (direction == KeyDirection.click) {
        // Send KEY_DOWN followed by KEY_UP
        final downPacket = AndroidTvRemoteV2Protocol.buildRemoteKeyInject(
          keyCode: keyCode,
          direction: AndroidKeyCodes.directionStart,
        );
        _connectionManager.sendRaw(downPacket);

        await Future.delayed(const Duration(milliseconds: 60));

        final upPacket = AndroidTvRemoteV2Protocol.buildRemoteKeyInject(
          keyCode: keyCode,
          direction: AndroidKeyCodes.directionEnd,
        );
        final ok = _connectionManager.sendRaw(upPacket);
        return ok ? CommandExecutionResult.ok() : CommandExecutionResult.failed('Failed to transmit key event');
      } else if (direction == KeyDirection.down) {
        final packet = AndroidTvRemoteV2Protocol.buildRemoteKeyInject(
          keyCode: keyCode,
          direction: AndroidKeyCodes.directionStart,
        );
        final ok = _connectionManager.sendRaw(packet);
        return ok ? CommandExecutionResult.ok() : CommandExecutionResult.failed('Failed to transmit key down');
      } else if (direction == KeyDirection.up) {
        final packet = AndroidTvRemoteV2Protocol.buildRemoteKeyInject(
          keyCode: keyCode,
          direction: AndroidKeyCodes.directionEnd,
        );
        final ok = _connectionManager.sendRaw(packet);
        return ok ? CommandExecutionResult.ok() : CommandExecutionResult.failed('Failed to transmit key up');
      } else if (direction == KeyDirection.longPress) {
        final packet = AndroidTvRemoteV2Protocol.buildRemoteKeyInject(
          keyCode: keyCode,
          direction: AndroidKeyCodes.directionStartLong,
        );
        final ok = _connectionManager.sendRaw(packet);
        return ok ? CommandExecutionResult.ok() : CommandExecutionResult.failed('Failed to transmit long press');
      }

      return CommandExecutionResult.ok();
    } catch (e) {
      AppLogger.error('Error executing key command: $e', 'Command');
      return CommandExecutionResult.failed('Command transmission error: $e');
    }
  }

  /// Send button command based on TvButtonType
  Future<CommandExecutionResult> executeButton(
    TvButtonType buttonType, {
    KeyDirection direction = KeyDirection.click,
  }) async {
    switch (buttonType) {
      // Power
      case TvButtonType.power:
      case TvButtonType.powerOff:
        return sendKey(AndroidKeyCodes.keycodePower, direction: direction);

      case TvButtonType.powerOnWol:
        final dev = _connectionManager.connectedDevice;
        if (dev != null && dev.macAddress != null && dev.macAddress!.isNotEmpty) {
          final sent = await WolService.sendWakeOnLan(macAddress: dev.macAddress!);
          return sent
              ? CommandExecutionResult.ok()
              : CommandExecutionResult.failed('Could not broadcast Wake-on-LAN packet');
        }
        return CommandExecutionResult.unsupported('Wake-on-LAN (MAC address not registered)');

      // Navigation
      case TvButtonType.dpadUp:
        return sendKey(AndroidKeyCodes.keycodeDpadUp, direction: direction);
      case TvButtonType.dpadDown:
        return sendKey(AndroidKeyCodes.keycodeDpadDown, direction: direction);
      case TvButtonType.dpadLeft:
        return sendKey(AndroidKeyCodes.keycodeDpadLeft, direction: direction);
      case TvButtonType.dpadRight:
        return sendKey(AndroidKeyCodes.keycodeDpadRight, direction: direction);
      case TvButtonType.dpadCenter:
        return sendKey(AndroidKeyCodes.keycodeDpadCenter, direction: direction);

      // System Navigation
      case TvButtonType.back:
        return sendKey(AndroidKeyCodes.keycodeBack, direction: direction);
      case TvButtonType.home:
        return sendKey(AndroidKeyCodes.keycodeHome, direction: direction);
      case TvButtonType.menu:
        return sendKey(AndroidKeyCodes.keycodeMenu, direction: direction);
      case TvButtonType.settings:
        return sendKey(AndroidKeyCodes.keycodeSettings, direction: direction);
      case TvButtonType.info:
        return sendKey(AndroidKeyCodes.keycodeInfo, direction: direction);

      // Volume
      case TvButtonType.volumeUp:
        return sendKey(AndroidKeyCodes.keycodeVolumeUp, direction: direction);
      case TvButtonType.volumeDown:
        return sendKey(AndroidKeyCodes.keycodeVolumeDown, direction: direction);
      case TvButtonType.volumeMute:
        return sendKey(AndroidKeyCodes.keycodeVolumeMute, direction: direction);

      // Channel
      case TvButtonType.channelUp:
        return sendKey(AndroidKeyCodes.keycodeChannelUp, direction: direction);
      case TvButtonType.channelDown:
        return sendKey(AndroidKeyCodes.keycodeChannelDown, direction: direction);

      // Media
      case TvButtonType.mediaPlay:
        return sendKey(AndroidKeyCodes.keycodeMediaPlay, direction: direction);
      case TvButtonType.mediaPause:
        return sendKey(AndroidKeyCodes.keycodeMediaPause, direction: direction);
      case TvButtonType.mediaPlayPause:
        return sendKey(AndroidKeyCodes.keycodeMediaPlayPause, direction: direction);
      case TvButtonType.mediaStop:
        return sendKey(AndroidKeyCodes.keycodeMediaStop, direction: direction);
      case TvButtonType.mediaRewind:
        return sendKey(AndroidKeyCodes.keycodeMediaRewind, direction: direction);
      case TvButtonType.mediaFastForward:
        return sendKey(AndroidKeyCodes.keycodeMediaFastForward, direction: direction);

      // Additional Controls
      case TvButtonType.voiceAssistant:
        return sendKey(AndroidKeyCodes.keycodeVoiceAssist, direction: direction);

      case TvButtonType.keyboard:
      case TvButtonType.touchpad:
        return CommandExecutionResult.ok();
    }
  }

  /// Launch application shortcut (e.g. YouTube, Spotify)
  Future<CommandExecutionResult> launchApp({
    required String name,
    required String packageId,
    String? deepLink,
  }) async {
    if (_connectionManager.status != DeviceConnectionStatus.connected) {
      return CommandExecutionResult.failed('Not connected to television');
    }

    try {
      // Prioritize deep link if available, fallback to package intent
      final targetUri = (deepLink != null && deepLink.isNotEmpty) ? deepLink : 'android-app://$packageId';
      final packet = AndroidTvRemoteV2Protocol.buildRemoteAppLink(targetUri);
      final sent = _connectionManager.sendRaw(packet);

      if (sent) {
        AppLogger.info('Sent app launch intent for $name ($targetUri)', 'Command');
        return CommandExecutionResult.ok();
      } else {
        return CommandExecutionResult.failed('Failed to transmit app launch packet');
      }
    } catch (e) {
      return CommandExecutionResult.failed('App launch error: $e');
    }
  }

  /// Send text input to TV keyboard / search
  Future<CommandExecutionResult> sendText(String text) async {
    if (_connectionManager.status != DeviceConnectionStatus.connected) {
      return CommandExecutionResult.failed('Not connected to television');
    }

    try {
      for (final char in text.split('')) {
        // Map characters or send key codes
        final lower = char.toLowerCase();
        int? code;
        if (lower.codeUnitAt(0) >= 97 && lower.codeUnitAt(0) <= 122) {
          // A-Z
          code = 29 + (lower.codeUnitAt(0) - 97);
        } else if (lower.codeUnitAt(0) >= 48 && lower.codeUnitAt(0) <= 57) {
          // 0-9
          code = 7 + (lower.codeUnitAt(0) - 48);
        } else if (char == ' ') {
          code = 62; // KEYCODE_SPACE
        }

        if (code != null) {
          await sendKey(code);
          await Future.delayed(const Duration(milliseconds: 30));
        }
      }
      return CommandExecutionResult.ok();
    } catch (e) {
      return CommandExecutionResult.failed('Failed to send text input: $e');
    }
  }
}
