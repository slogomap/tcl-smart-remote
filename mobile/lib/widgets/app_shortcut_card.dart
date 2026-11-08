import 'package:flutter/material.dart';
import '../models/app_shortcut.dart';
import '../theme/colors.dart';

class AppShortcutRow extends StatelessWidget {
  final List<AppShortcut> shortcuts;
  final Function(AppShortcut shortcut) onLaunch;
  final VoidCallback onConfigure;

  const AppShortcutRow({
    Key? key,
    required this.shortcuts,
    required this.onLaunch,
    required this.onConfigure,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enabledShortcuts = shortcuts.where((s) => s.isEnabled).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'QUICK APPS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.darkTextMuted,
                ),
              ),
              InkWell(
                onTap: onConfigure,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Customize',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tclRed,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: enabledShortcuts.map((s) {
                return _ShortcutButton(
                  shortcut: s,
                  onTap: () => onLaunch(s),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  final AppShortcut shortcut;
  final VoidCallback onTap;

  const _ShortcutButton({
    required this.shortcut,
    required this.onTap,
  });

  Color _getBadgeColor() {
    switch (shortcut.iconName.toLowerCase()) {
      case 'youtube':
        return const Color(0xFFFF0000); // YouTube Red
      case 'spotify':
        return const Color(0xFF1DB954); // Spotify Green
      case 'netflix':
        return const Color(0xFFE50914); // Netflix Red
      case 'primevideo':
        return const Color(0xFF00A8E1); // Prime Blue
      default:
        return AppColors.tclRed;
    }
  }

  IconData _getIconData() {
    switch (shortcut.iconName.toLowerCase()) {
      case 'youtube':
        return Icons.play_circle_fill;
      case 'spotify':
        return Icons.music_note;
      case 'netflix':
        return Icons.movie_filter;
      case 'primevideo':
        return Icons.video_library;
      default:
        return Icons.tv;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeColor = _getBadgeColor();

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: isDark ? AppColors.darkButton : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        elevation: isDark ? 0 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: badgeColor.withOpacity(0.25),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIconData(),
                  color: badgeColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  shortcut.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
