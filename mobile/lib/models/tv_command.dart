enum KeyDirection {
  click,
  down,
  up,
  longPress,
}

enum TvButtonType {
  power,
  powerOff,
  powerOnWol,
  dpadUp,
  dpadDown,
  dpadLeft,
  dpadRight,
  dpadCenter,
  back,
  home,
  menu,
  settings,
  volumeUp,
  volumeDown,
  volumeMute,
  channelUp,
  channelDown,
  mediaPlay,
  mediaPause,
  mediaStop,
  mediaRewind,
  mediaFastForward,
  mediaPlayPause,
  voiceAssistant,
  keyboard,
  touchpad,
  info,
}

class TvCommand {
  final TvButtonType type;
  final KeyDirection direction;
  final String? textPayload;
  final String? appUriPayload;
  final DateTime timestamp;

  TvCommand({
    required this.type,
    this.direction = KeyDirection.click,
    this.textPayload,
    this.appUriPayload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
