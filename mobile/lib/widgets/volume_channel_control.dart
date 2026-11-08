import 'package:flutter/material.dart';
import '../models/tv_command.dart';
import '../theme/colors.dart';
import 'remote_button.dart';

class VolumeChannelControl extends StatelessWidget {
  final Function(TvButtonType type, {KeyDirection direction}) onButtonPressed;

  const VolumeChannelControl({
    Key? key,
    required this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Volume Rocker
          _RockerPill(
            label: 'VOL',
            topIcon: Icons.add,
            bottomIcon: Icons.remove,
            onTopTap: () => onButtonPressed(TvButtonType.volumeUp),
            onBottomTap: () => onButtonPressed(TvButtonType.volumeDown),
            isDark: isDark,
          ),

          // Center: MUTE & INFO / GUIDE
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RemoteButton(
                icon: Icons.volume_off,
                size: 46,
                onTap: () => onButtonPressed(TvButtonType.volumeMute),
              ),
              const SizedBox(height: 8),
              Text(
                'MUTE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 12),
              RemoteButton(
                icon: Icons.info_outline,
                size: 46,
                onTap: () => onButtonPressed(TvButtonType.info),
              ),
              const SizedBox(height: 8),
              Text(
                'INFO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),

          // Channel Rocker
          _RockerPill(
            label: 'CH',
            topIcon: Icons.keyboard_arrow_up,
            bottomIcon: Icons.keyboard_arrow_down,
            onTopTap: () => onButtonPressed(TvButtonType.channelUp),
            onBottomTap: () => onButtonPressed(TvButtonType.channelDown),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _RockerPill extends StatelessWidget {
  final String label;
  final IconData topIcon;
  final IconData bottomIcon;
  final VoidCallback onTopTap;
  final VoidCallback onBottomTap;
  final bool isDark;

  const _RockerPill({
    required this.label,
    required this.topIcon,
    required this.bottomIcon,
    required this.onTopTap,
    required this.onBottomTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 140,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkButton : AppColors.lightCard,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Plus / Up
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                splashColor: AppColors.tclRed.withOpacity(0.2),
                onTap: onTopTap,
                child: Center(
                  child: Icon(
                    topIcon,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Label
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),

          // Minus / Down
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                splashColor: AppColors.tclRed.withOpacity(0.2),
                onTap: onBottomTap,
                child: Center(
                  child: Icon(
                    bottomIcon,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
