import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tv_command.dart';
import '../models/app_shortcut.dart';
import '../state/remote_provider.dart';
import '../theme/colors.dart';
import '../widgets/status_bar_card.dart';
import '../widgets/remote_dpad.dart';
import '../widgets/remote_button.dart';
import '../widgets/volume_channel_control.dart';
import '../widgets/media_controls.dart';
import '../widgets/app_shortcut_card.dart';
import '../widgets/keyboard_dialog.dart';
import '../widgets/touchpad_view.dart';
import 'discovery_screen.dart';
import 'settings_screen.dart';
import 'shortcuts_screen.dart';

class RemoteScreen extends StatefulWidget {
  const RemoteScreen({Key? key}) : super(key: key);

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  bool _useTouchpadMode = false;

  void _handleButtonPress(TvButtonType type, {KeyDirection direction = KeyDirection.click}) async {
    final remote = context.read<RemoteProvider>();

    if (type == TvButtonType.keyboard) {
      _showKeyboardInput();
      return;
    }

    if (type == TvButtonType.touchpad) {
      setState(() {
        _useTouchpadMode = !_useTouchpadMode;
      });
      return;
    }

    final result = await remote.sendButton(type, direction: direction);
    if (!result.success && mounted) {
      _showFeedbackSnackBar(result.message ?? 'Command failed', isError: true);
    }
  }

  void _handleAppLaunch(AppShortcut shortcut) async {
    final remote = context.read<RemoteProvider>();
    final result = await remote.launchApp(shortcut);

    if (mounted) {
      if (result.success) {
        _showFeedbackSnackBar('Launched ${shortcut.name} on TV');
      } else {
        _showFeedbackSnackBar(result.message ?? 'Failed to launch ${shortcut.name}', isError: true);
      }
    }
  }

  void _showFeedbackSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.statusRed : AppColors.tclRed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showKeyboardInput() {
    showDialog(
      context: context,
      builder: (ctx) => KeyboardInputDialog(
        onSendText: (text) async {
          final remote = context.read<RemoteProvider>();
          final res = await remote.sendText(text);
          if (mounted) {
            _showFeedbackSnackBar(res.success ? 'Text sent to TV' : (res.message ?? 'Failed to send text'));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remote = context.watch<RemoteProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TCL SMART REMOTE'),
        actions: [
          IconButton(
            icon: Icon(
              _useTouchpadMode ? Icons.gamepad : Icons.touch_app,
              color: _useTouchpadMode ? AppColors.tclRed : null,
            ),
            tooltip: _useTouchpadMode ? 'Switch to D-Pad' : 'Switch to Touchpad',
            onPressed: () {
              setState(() {
                _useTouchpadMode = !_useTouchpadMode;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.keyboard),
            tooltip: 'TV Keyboard Input',
            onPressed: _showKeyboardInput,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 1. Status Bar Card (Logo, TV Name, IP, Status Color, Battery)
              StatusBarCard(
                connectionState: remote.state,
                onTapTvStatus: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DiscoveryScreen()),
                  );
                },
              ),

              // 2. Power and Primary Utility Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Power Button
                    RemoteButton(
                      icon: Icons.power_settings_new,
                      size: 54,
                      style: RemoteButtonStyle.power,
                      onTap: () => _handleButtonPress(TvButtonType.power),
                      onLongPress: () => _handleButtonPress(TvButtonType.powerOnWol),
                    ),

                    // Google Assistant / Voice Search
                    RemoteButton(
                      icon: Icons.mic,
                      size: 48,
                      style: RemoteButtonStyle.accent,
                      onTap: () => _handleButtonPress(TvButtonType.voiceAssistant),
                    ),

                    // Settings Button
                    RemoteButton(
                      icon: Icons.tune,
                      size: 48,
                      onTap: () => _handleButtonPress(TvButtonType.settings),
                    ),

                    // TV Input / Source
                    RemoteButton(
                      icon: Icons.input,
                      size: 48,
                      onTap: () => _handleButtonPress(TvButtonType.menu),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 3. Navigation Controls: Circular D-Pad or Touchpad
              if (_useTouchpadMode)
                TouchpadView(onSwipeAction: _handleButtonPress)
              else
                RemoteDpad(onButtonPressed: _handleButtonPress),

              const SizedBox(height: 12),

              // 4. System Navigation Functions: BACK, HOME, MENU
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // BACK
                    Column(
                      children: [
                        RemoteButton(
                          icon: Icons.arrow_back,
                          size: 48,
                          onTap: () => _handleButtonPress(TvButtonType.back),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'BACK',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),

                    // HOME
                    Column(
                      children: [
                        RemoteButton(
                          icon: Icons.home,
                          size: 52,
                          style: RemoteButtonStyle.accent,
                          onTap: () => _handleButtonPress(TvButtonType.home),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'HOME',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),

                    // MENU
                    Column(
                      children: [
                        RemoteButton(
                          icon: Icons.menu,
                          size: 48,
                          onTap: () => _handleButtonPress(TvButtonType.menu),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'MENU',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. Volume & Channel Dual Rockers with Center Mute/Info
              VolumeChannelControl(onButtonPressed: _handleButtonPress),

              const SizedBox(height: 12),

              // 6. Media Controls (Rewind, Play/Pause, Stop, Fast Forward)
              MediaControls(onButtonPressed: _handleButtonPress),

              const SizedBox(height: 12),

              // 7. Quick Applications (YouTube, Spotify, Netflix, Prime Video)
              AppShortcutRow(
                shortcuts: remote.shortcuts,
                onLaunch: _handleAppLaunch,
                onConfigure: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShortcutsScreen()),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
