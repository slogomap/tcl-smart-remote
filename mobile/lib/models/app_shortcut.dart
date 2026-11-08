class AppShortcut {
  final String id;
  final String name;
  final String packageId;
  final String? deepLink;
  final String iconName;
  final bool isEnabled;
  final int sortOrder;

  AppShortcut({
    required this.id,
    required this.name,
    required this.packageId,
    this.deepLink,
    required this.iconName,
    this.isEnabled = true,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'package_id': packageId,
      'deep_link': deepLink,
      'icon_name': iconName,
      'is_enabled': isEnabled ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  factory AppShortcut.fromJson(Map<String, dynamic> json) {
    return AppShortcut(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      packageId: json['package_id']?.toString() ?? '',
      deepLink: json['deep_link']?.toString(),
      iconName: json['icon_name']?.toString() ?? 'app',
      isEnabled: json['is_enabled'] == 1 || json['is_enabled'] == true,
      sortOrder: (json['sort_order'] is int)
          ? json['sort_order']
          : int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
    );
  }

  static List<AppShortcut> get defaultShortcuts => [
        AppShortcut(
          id: 'youtube-shortcut',
          name: 'YouTube',
          packageId: 'com.google.android.youtube.tv',
          deepLink: 'https://www.youtube.com',
          iconName: 'youtube',
          isEnabled: true,
          sortOrder: 1,
        ),
        AppShortcut(
          id: 'spotify-shortcut',
          name: 'Spotify',
          packageId: 'com.spotify.tv.android',
          deepLink: 'spotify://',
          iconName: 'spotify',
          isEnabled: true,
          sortOrder: 2,
        ),
        AppShortcut(
          id: 'netflix-shortcut',
          name: 'Netflix',
          packageId: 'com.netflix.ninja',
          deepLink: 'netflix://',
          iconName: 'netflix',
          isEnabled: true,
          sortOrder: 3,
        ),
        AppShortcut(
          id: 'prime-shortcut',
          name: 'Prime Video',
          packageId: 'com.amazon.amazonvideo.livingroom',
          deepLink: 'https://app.primevideo.com',
          iconName: 'primevideo',
          isEnabled: true,
          sortOrder: 4,
        ),
      ];
}
