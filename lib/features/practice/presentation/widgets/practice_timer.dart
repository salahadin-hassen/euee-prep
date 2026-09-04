import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';

/// Purely presentational countdown display. Owns no ticking logic —
/// PracticeScreen owns the Timer.periodic and passes remainingSeconds
/// down, so this widget stays cheap to rebuild every second (per the
/// spec's performance note: timer ticking should update only the timer
/// display, not trigger a full-screen rebuild).
class PracticeTimer extends StatelessWidget {
  const PracticeTimer({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isCollapsed,
    required this.onToggleCollapsed,
  });

  final int remainingSeconds;
  final int totalSeconds;

  /// Exam Mode: collapsed = small clock icon only, still running.
  /// Practice Mode: this widget is only built at all when the student
  /// has toggled the timer on — see PracticeAppBar for that distinction.
  final bool isCollapsed;
  final VoidCallback onToggleCollapsed;

  double get _fractionRemaining =>
      totalSeconds == 0 ? 0 : (remainingSeconds / totalSeconds).clamp(0, 1);

  Color get _color {
    final fraction = _fractionRemaining;
    if (fraction < 0.10) return AppColors.colorError;
    if (fraction < 0.25) return AppColors.colorWarning;
    return AppColors.colorSuccess;
  }

  String get _formatted {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Semantics(
      label: 'Time remaining $_formatted',
      button: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: onToggleCollapsed,
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceXs),
          child: isCollapsed
              ? Icon(Icons.timer_outlined, color: color, size: AppIconSize.iconSizeMd)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, color: color, size: AppIconSize.iconSizeSm),
                    const SizedBox(width: AppSpacing.spaceXs),
                    Text(
                      _formatted,
                      style: AppTypography.typeCaption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
