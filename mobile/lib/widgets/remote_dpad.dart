import 'package:flutter/material.dart';
import '../models/tv_command.dart';
import '../theme/colors.dart';

class RemoteDpad extends StatelessWidget {
  final Function(TvButtonType type, {KeyDirection direction}) onButtonPressed;

  const RemoteDpad({
    Key? key,
    required this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const double dpadSize = 220.0;
    const double centerButtonSize = 84.0;

    return Center(
      child: Container(
        width: dpadSize,
        height: dpadSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? AppColors.darkSurface : AppColors.lightCard,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // UP Button
            Positioned(
              top: 8,
              child: _DpadArrowButton(
                icon: Icons.keyboard_arrow_up,
                onTap: () => onButtonPressed(TvButtonType.dpadUp),
                isDark: isDark,
              ),
            ),

            // DOWN Button
            Positioned(
              bottom: 8,
              child: _DpadArrowButton(
                icon: Icons.keyboard_arrow_down,
                onTap: () => onButtonPressed(TvButtonType.dpadDown),
                isDark: isDark,
              ),
            ),

            // LEFT Button
            Positioned(
              left: 8,
              child: _DpadArrowButton(
                icon: Icons.keyboard_arrow_left,
                onTap: () => onButtonPressed(TvButtonType.dpadLeft),
                isDark: isDark,
              ),
            ),

            // RIGHT Button
            Positioned(
              right: 8,
              child: _DpadArrowButton(
                icon: Icons.keyboard_arrow_right,
                onTap: () => onButtonPressed(TvButtonType.dpadRight),
                isDark: isDark,
              ),
            ),

            // CENTER OK / SELECT BUTTON
            Container(
              width: centerButtonSize,
              height: centerButtonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.darkButtonActive, AppColors.darkButton]
                      : [AppColors.lightSurface, AppColors.lightButton],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  splashColor: AppColors.tclRed.withOpacity(0.3),
                  highlightColor: AppColors.tclRed.withOpacity(0.1),
                  onTap: () => onButtonPressed(TvButtonType.dpadCenter),
                  child: Center(
                    child: Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DpadArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _DpadArrowButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        splashColor: AppColors.tclRed.withOpacity(0.2),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(
            icon,
            size: 32,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
    );
  }
}
