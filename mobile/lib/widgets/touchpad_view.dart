import 'package:flutter/material.dart';
import '../models/tv_command.dart';
import '../theme/colors.dart';

class TouchpadView extends StatefulWidget {
  final Function(TvButtonType type, {KeyDirection direction}) onSwipeAction;

  const TouchpadView({
    Key? key,
    required this.onSwipeAction,
  }) : super(key: key);

  @override
  State<TouchpadView> createState() => _TouchpadViewState();
}

class _TouchpadViewState extends State<TouchpadView> {
  Offset? _startPosition;
  DateTime? _startTime;

  void _onPanStart(DragStartDetails details) {
    _startPosition = details.localPosition;
    _startTime = DateTime.now();
  }

  void _onPanEnd(DragEndDetails details) {
    if (_startPosition == null || _startTime == null) return;

    final duration = DateTime.now().difference(_startTime!);
    final velocity = details.velocity.pixelsPerSecond;

    // Detect fast fling or distance swipe
    if (duration.inMilliseconds < 500) {
      if (velocity.dx.abs() > velocity.dy.abs()) {
        if (velocity.dx > 200) {
          widget.onSwipeAction(TvButtonType.dpadRight);
        } else if (velocity.dx < -200) {
          widget.onSwipeAction(TvButtonType.dpadLeft);
        }
      } else {
        if (velocity.dy > 200) {
          widget.onSwipeAction(TvButtonType.dpadDown);
        } else if (velocity.dy < -200) {
          widget.onSwipeAction(TvButtonType.dpadUp);
        }
      }
    }

    _startPosition = null;
    _startTime = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => widget.onSwipeAction(TvButtonType.dpadCenter),
      onPanStart: _onPanStart,
      onPanEnd: _onPanEnd,
      child: Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app,
                size: 38,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              const SizedBox(height: 10),
              Text(
                'SWIPE TO NAVIGATE • TAP TO SELECT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
