import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum RemoteButtonStyle {
  normal,
  accent,
  power,
  iconOnly,
}

class RemoteButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final RemoteButtonStyle style;
  final double size;

  const RemoteButton({
    Key? key,
    this.icon,
    this.label,
    required this.onTap,
    this.onLongPress,
    this.style = RemoteButtonStyle.normal,
    this.size = 52.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color fgColor;
    Color borderColor;

    switch (style) {
      case RemoteButtonStyle.power:
        bgColor = isDark ? const Color(0xFF321316) : const Color(0xFFFFEBEE);
        fgColor = AppColors.tclRed;
        borderColor = AppColors.tclRed.withOpacity(0.5);
        break;
      case RemoteButtonStyle.accent:
        bgColor = AppColors.tclRed;
        fgColor = Colors.white;
        borderColor = AppColors.tclRedDark;
        break;
      case RemoteButtonStyle.iconOnly:
        bgColor = Colors.transparent;
        fgColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        borderColor = Colors.transparent;
        break;
      case RemoteButtonStyle.normal:
      default:
        bgColor = isDark ? AppColors.darkButton : AppColors.lightCard;
        fgColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: style != RemoteButtonStyle.iconOnly
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          splashColor: (style == RemoteButtonStyle.power || style == RemoteButtonStyle.accent)
              ? Colors.white24
              : AppColors.tclRed.withOpacity(0.25),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Center(
            child: icon != null
                ? Icon(icon, color: fgColor, size: size * 0.46)
                : Text(
                    label ?? '',
                    style: TextStyle(
                      color: fgColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
