import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/progress_bar.dart';

/// Non-scrolling header for Subject Detail: subject name, the same
/// "Grade 9–12 · N chapters" caption used on the Subject List card for
/// visual continuity, and an overall progress bar.
///
/// Reuses core/design/widgets/progress_bar.dart — the exact reuse case
/// flagged when that component was first built for Subject List.
class SubjectDetailHeader extends StatelessWidget {
  const SubjectDetailHeader({
    super.key,
    required this.subjectName,
    required this.chapterCount,
    required this.overallProgress,
  });

  final String subjectName;
  final int chapterCount;
  final double overallProgress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subjectName, style: AppTypography.typeHeading1),
          const SizedBox(height: AppSpacing.spaceXs),
          Text(
            'Grade 9–12 · $chapterCount chapters',
            style: AppTypography.typeCaption,
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          ProgressBar(progress: overallProgress),
        ],
      ),
    );
  }
}
