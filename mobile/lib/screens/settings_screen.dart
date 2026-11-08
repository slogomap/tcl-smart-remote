import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/constants.dart';
import '../state/settings_provider.dart';
import '../state/discovery_provider.dart';
import '../state/remote_provider.dart';
import '../theme/colors.dart';
import 'diagnostics_screen.dart';
import 'discovery_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'TCL SMART REMOTE',
      applicationVersion: AppConstants.appVersion,
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.tclRed,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: const Text(
          'TCL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
      children: const [
        Text(
          'Professional cross-platform smart television remote control application for TCL Google TVs and compatible Android TV devices.',
          style: TextStyle(fontSize: 13),
        ),
        SizedBox(height: 10),
        Text(
          'Local-first design: All control signals travel directly between your phone and your television over your local home Wi-Fi network without third-party cloud routing.',
          style: TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy & Local-First Policy'),
        content: const SingleChildScrollView(
          child: Text(
            '1. Direct Local Communication: All TV control commands, navigation events, and keystrokes are sent directly from your smartphone to your TV via an encrypted TLS socket on your local home network (port 6467).\n\n'
            '2. Zero Cloud Intermediary: No cloud server intercepts or records your remote keystrokes.\n\n'
            '3. Secure Credentials: TV pairing certificates and private keys are generated directly on your smartphone and stored exclusively inside the hardware-backed Android Keystore / iOS Keychain.\n\n'
            '4. Offline Guaranteed: The remote operates completely offline even when external internet is disconnected.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final remote = context.watch<RemoteProvider>();
    final discovery = context.watch<DiscoveryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // Preference Section
            const _SectionHeader(title: 'PREFERENCES'),
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Charcoal & true black interface with TCL red accent'),
              secondary: const Icon(Icons.dark_mode_outlined),
              value: settings.isDarkMode,
              activeColor: AppColors.tclRed,
              onChanged: (val) => settings.toggleTheme(val),
            ),
            SwitchListTile(
              title: const Text('Haptic Feedback'),
              subtitle: const Text('Tactile vibration response on button presses'),
              secondary: const Icon(Icons.vibration),
              value: settings.settings.hapticFeedback,
              activeColor: AppColors.tclRed,
              onChanged: (val) {
                settings.setHapticFeedback(val);
                remote.updateHapticSetting(val);
              },
            ),
            SwitchListTile(
              title: const Text('Auto-Reconnect'),
              subtitle: const Text('Automatically reconnect to active TV when on home Wi-Fi'),
              secondary: const Icon(Icons.autorenew),
              value: settings.settings.autoReconnect,
              activeColor: AppColors.tclRed,
              onChanged: (val) {
                settings.setAutoReconnect(val);
                remote.connectionManager.enableAutoReconnect(val);
              },
            ),

            const Divider(),

            // Televisions Section
            const _SectionHeader(title: 'TELEVISIONS'),
            ListTile(
              leading: const Icon(Icons.tv),
              title: const Text('Manage Saved Televisions'),
              subtitle: Text('${discovery.savedDevices.length} saved television(s)'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DiscoveryScreen()),
                );
              },
            ),

            const Divider(),

            // Diagnostics & Backend
            const _SectionHeader(title: 'SYSTEM & DIAGNOSTICS'),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Diagnostic Logs & Metrics'),
              subtitle: const Text('Inspect connection events, socket health, and latency'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
                );
              },
            ),

            const Divider(),

            // About & Legal
            const _SectionHeader(title: 'APPLICATION'),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About TCL SMART REMOTE'),
              subtitle: const Text('Version 1.0.0 (Production Build)'),
              onTap: () => _showAboutDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Privacy & Security Information'),
              subtitle: const Text('Local-first operation & Keystore security details'),
              onTap: () => _showPrivacyDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppColors.tclRed,
        ),
      ),
    );
  }
}
