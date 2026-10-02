import 'package:flutter/material.dart';

import '../tokens.dart';

/// Thin, muted horizontal progress indicator.
///
/// Deliberately understated per the "calm, never flashy" design
/// philosophy — no percentage badge, no color-coded thresholds, no
/// celebratory animation. [progress] is a fraction from 0.0 to 1.0.
///
/// Built generic (not payment- or subject-specific) since the design
/// review flagged this as likely reusable in exam review and weakness
/// analysis screens later.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.progress,
    this.height = 6,
    this.trackColor = AppColors.colorBorder,
    this.fillColor = AppColors.colorPrimary,
  });

  /// 0.0 to 1.0. Values outside that range are clamped.
  final double progress;
  final double height;

  /// Track (unfilled) color — overridden on the navy Continue card.
  final Color trackColor;

  /// Fill color — overridden per subject accent on Home preview rows.
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final percentLabel = '${(clamped * 100).round()} percent complete';

    return Semantics(
      label: percentLabel,
      value: percentLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: height,
                  width: constraints.maxWidth,
                  color: trackColor,
                ),
                Container(
                  height: height,
                  width: constraints.maxWidth * clamped,
                  color: fillColor,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
