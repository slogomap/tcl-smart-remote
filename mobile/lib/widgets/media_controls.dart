import 'package:flutter/material.dart';
import '../models/tv_command.dart';
import 'remote_button.dart';

class MediaControls extends StatelessWidget {
  final Function(TvButtonType type, {KeyDirection direction}) onButtonPressed;

  const MediaControls({
    Key? key,
    required this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Rewind
          RemoteButton(
            icon: Icons.fast_rewind,
            size: 44,
            onTap: () => onButtonPressed(TvButtonType.mediaRewind),
          ),

          // Play / Pause toggle
          RemoteButton(
            icon: Icons.play_arrow,
            size: 50,
            style: RemoteButtonStyle.accent,
            onTap: () => onButtonPressed(TvButtonType.mediaPlayPause),
          ),

          // Stop
          RemoteButton(
            icon: Icons.stop,
            size: 44,
            onTap: () => onButtonPressed(TvButtonType.mediaStop),
          ),

          // Fast Forward
          RemoteButton(
            icon: Icons.fast_forward,
            size: 44,
            onTap: () => onButtonPressed(TvButtonType.mediaFastForward),
          ),
        ],
      ),
    );
  }
}
