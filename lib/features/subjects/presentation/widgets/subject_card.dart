import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/subject_icon_tile.dart';
import '../models/subject_ui_model.dart';

/// One subject row on the Subject List screen.
///
/// Shows the subject's tinted icon tile, name and real paper/question
/// counts. Locked subjects are drawn on the muted palette with a lock
/// affordance instead of a chevron. No fake stats or marketing copy.
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.subject,
    required this.onTap,
  });

  final SubjectUiModel subject;
  final VoidCallback onTap;

  String get _semanticLabel {
    if (!subject.isOpen) {
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
    final foreground = subject.isOpen
        ? AppColors.colorTextPrimary
        : AppBrand.lockedForeground;

    return Semantics(
      label: _semanticLabel,
      button: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radiusCard),
        child: Container(
          decoration: BoxDecoration(
            color: subject.isOpen
                ? AppColors.colorSurface
                : AppBrand.lockedSurface,
            borderRadius: BorderRadius.circular(AppRadius.radiusCard),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spaceMd,
            vertical: AppSpacing.spaceMd,
          ),
          child: Row(
            children: [
              SubjectIconTile(
                slug: subject.subjectId,
                locked: !subject.isOpen,
              ),
              const SizedBox(width: AppSpacing.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spaceXs),
                    Text(
                      '${subject.paperCount} $paperLabel'
                      ' \u2022 ${subject.questionCount} $questionLabel',
                      style: TextStyle(
                        fontSize: 13,
                        color: subject.isOpen
                            ? AppColors.colorTextSecondary
                            : AppBrand.lockedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              subject.isOpen
                  ? const Icon(
                      Icons.chevron_right,
                      size: AppIconSize.iconSizeMd,
                      color: AppBrand.lockedForeground,
                    )
                  : const Icon(
                      Icons.lock_outline,
                      size: AppIconSize.iconSizeMd,
                      color: AppBrand.lockedForeground,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
