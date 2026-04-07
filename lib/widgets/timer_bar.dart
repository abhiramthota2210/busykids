import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class TimerBar extends StatelessWidget {
  final double progress; // 1.0 = full, 0.0 = empty
  final Color color;

  const TimerBar({super.key, required this.progress, required this.color});

  Color get _barColor {
    if (progress > 0.5) return color;
    if (progress > 0.25) return AppColors.warning;
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: _barColor,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: _barColor.withValues(alpha: 0.2), blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
