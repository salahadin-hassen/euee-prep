import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/progress_bar.dart';
import '../models/subject_ui_model.dart';

/// One subject row on the Subject List (Home) screen.
///
/// Same layout for both states — locked shows a small lock icon (not a
/// full overlay, so the card still reads as inviting rather than a
/// paywall), entitled shows an optional progress bar instead. This
/// keeps the visual language of "this is a subject" consistent
/// regardless of purchase state, per Decision 029's intent that locked
/// browsing should feel native, not walled off.
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
                      'Grade 9–12 · ${subject.chapterCount} chapters',
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
