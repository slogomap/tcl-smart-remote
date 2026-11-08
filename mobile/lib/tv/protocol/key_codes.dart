/// Standard Android Key Codes used by Google TV & Android TV Remote Service v2
class AndroidKeyCodes {
  // Navigation
  static const int keycodeDpadUp = 19;
  static const int keycodeDpadDown = 20;
  static const int keycodeDpadLeft = 21;
  static const int keycodeDpadRight = 22;
  static const int keycodeDpadCenter = 23; // OK / Select

  // System & Navigation Functions
  static const int keycodeHome = 3;
  static const int keycodeBack = 4;
  static const int keycodeMenu = 82;
  static const int keycodeSettings = 176;
  static const int keycodeSearch = 84;
  static const int keycodeAssist = 219; // Google Assistant
  static const int keycodeVoiceAssist = 231;
  static const int keycodeInfo = 165;
  static const int keycodeGuide = 172;

  // Power
  static const int keycodePower = 26;
  static const int keycodeTvPower = 177;
  static const int keycodeSleep = 223;
  static const int keycodeWakeup = 224;

  // Volume & Audio
  static const int keycodeVolumeUp = 24;
  static const int keycodeVolumeDown = 25;
  static const int keycodeVolumeMute = 164;

  // TV Channel
  static const int keycodeChannelUp = 166;
  static const int keycodeChannelDown = 167;

  // Media Controls
  static const int keycodeMediaPlay = 126;
  static const int keycodeMediaPause = 127;
  static const int keycodeMediaPlayPause = 85;
  static const int keycodeMediaStop = 86;
  static const int keycodeMediaNext = 87;
  static const int keycodeMediaPrevious = 88;
  static const int keycodeMediaRewind = 89;
  static const int keycodeMediaFastForward = 90;

  // Number Pad
  static const int keycode0 = 7;
  static const int keycode1 = 8;
  static const int keycode2 = 9;
  static const int keycode3 = 10;
  static const int keycode4 = 11;
  static const int keycode5 = 12;
  static const int keycode6 = 13;
  static const int keycode7 = 14;
  static const int keycode8 = 15;
  static const int keycode9 = 16;

  // Key Event Directions (Android TV Remote v2)
  static const int directionStartLong = 1;
  static const int directionShort = 2; // Single click
  static const int directionStart = 3; // Key down
  static const int directionEnd = 4;   // Key up
}
