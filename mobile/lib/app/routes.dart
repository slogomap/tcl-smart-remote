import 'package:flutter/material.dart';
import '../screens/remote_screen.dart';
import '../screens/discovery_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/shortcuts_screen.dart';
import '../screens/diagnostics_screen.dart';

class AppRoutes {
  static const String remote = '/';
  static const String discovery = '/discovery';
  static const String settings = '/settings';
  static const String shortcuts = '/shortcuts';
  static const String diagnostics = '/diagnostics';

  static Map<String, WidgetBuilder> get routes => {
        remote: (context) => const RemoteScreen(),
        discovery: (context) => const DiscoveryScreen(),
        settings: (context) => const SettingsScreen(),
        shortcuts: (context) => const ShortcutsScreen(),
        diagnostics: (context) => const DiagnosticsScreen(),
      };
}
