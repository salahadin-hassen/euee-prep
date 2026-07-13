import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';

/// Orientation header for Study Resources: chapter title + "Grade N ·
/// Subject" caption. No progress bar — deliberately a separate
/// component from SubjectDetailHeader rather than a shared one with an
/// optional progress bar, since this header structurally never has one
/// (flagged as a design-system tradeoff in the design review).
class ChapterContextHeader extends StatelessWidget {
  const ChapterContextHeader({
    super.key,
    required this.chapterTitle,
    required this.grade,
    required this.subjectName,
  });

  final String chapterTitle;
  final int grade;
  final String subjectName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(chapterTitle, style: AppTypography.typeHeading1),
          const SizedBox(height: AppSpacing.spaceXs),
          Text(
            'Grade $grade · $subjectName',
            style: AppTypography.typeCaption,
          ),
        ],
      ),
    );
  }
}
