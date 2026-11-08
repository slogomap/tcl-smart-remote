class AppSettings {
  final String themeMode; // 'dark' or 'light'
  final bool hapticFeedback;
  final bool buttonSound;
  final bool autoReconnect;
  final int connectionTimeoutMs;
  final String backendUrl;

  const AppSettings({
    this.themeMode = 'dark',
    this.hapticFeedback = true,
    this.buttonSound = false,
    this.autoReconnect = true,
    this.connectionTimeoutMs = 5000,
    this.backendUrl = 'http://192.168.1.100:3000',
  });

  AppSettings copyWith({
    String? themeMode,
    bool? hapticFeedback,
    bool? buttonSound,
    bool? autoReconnect,
    int? connectionTimeoutMs,
    String? backendUrl,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      buttonSound: buttonSound ?? this.buttonSound,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      connectionTimeoutMs: connectionTimeoutMs ?? this.connectionTimeoutMs,
      backendUrl: backendUrl ?? this.backendUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'hapticFeedback': hapticFeedback,
      'buttonSound': buttonSound,
      'autoReconnect': autoReconnect,
      'connectionTimeoutMs': connectionTimeoutMs,
      'backendUrl': backendUrl,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: json['themeMode']?.toString() ?? 'dark',
      hapticFeedback: json['hapticFeedback'] == true || json['hapticFeedback'] == 1,
      buttonSound: json['buttonSound'] == true || json['buttonSound'] == 1,
      autoReconnect: json['autoReconnect'] == true || json['autoReconnect'] == 1,
      connectionTimeoutMs: (json['connectionTimeoutMs'] is int)
          ? json['connectionTimeoutMs']
          : int.tryParse(json['connectionTimeoutMs']?.toString() ?? '5000') ?? 5000,
      backendUrl: json['backendUrl']?.toString() ?? 'http://192.168.1.100:3000',
    );
  }
}
