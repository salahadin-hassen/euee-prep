import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/progress_bar.dart';
import '../models/subject_ui_model.dart';

/// One subject row on the Subject List (Home) screen.
///
/// Shows the subject name, real paper/question counts, and an optional
/// progress bar for entitled subjects. No fake stats or marketing copy.
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.subject,
    required this.onTap,
  });

  final SubjectUiModel subject;
  final VoidCallback onTap;

  String get _semanticLabel {
    if (!subject.isEntitled) {
      return '${subject.name}, locked. Double tap to unlock.';
    }
    final progress = subject.progress;
    if (progress != null && progress > 0) {
      final percent = (progress * 100).round();
      return '${subject.name}, $percent percent complete. Double tap to open.';
    }
    return '${subject.name}. Double tap to open.';
  }

  @override
  Widget build(BuildContext context) {
    final paperLabel = subject.paperCount == 1 ? 'paper' : 'papers';
    final questionLabel =
        subject.questionCount == 1 ? 'question' : 'questions';

    return Semantics(
      label: _semanticLabel,
      button: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.colorSurface,
            borderRadius: BorderRadius.circular(AppRadius.radiusMd),
            border: Border.all(color: AppColors.colorBorder),
          ),
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Row(
            children: [
              Text(subject.iconGlyph, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: AppSpacing.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject.name, style: AppTypography.typeHeading3),
                    const SizedBox(height: AppSpacing.spaceXs),
                    Text(
                      '${subject.paperCount} $paperLabel \u2022 ${subject.questionCount} $questionLabel',
                      style: AppTypography.typeCaption,
                    ),
                    if (subject.isEntitled &&
                        subject.progress != null &&
                        subject.progress! > 0) ...[
                      const SizedBox(height: AppSpacing.spaceSm),
                      ProgressBar(progress: subject.progress!),
                    ],
                  ],
                ),
              ),
              if (!subject.isEntitled) ...[
                const SizedBox(width: AppSpacing.spaceSm),
                const Icon(
                  Icons.lock_outline,
                  size: AppIconSize.iconSizeMd,
                  color: AppColors.colorTextSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
