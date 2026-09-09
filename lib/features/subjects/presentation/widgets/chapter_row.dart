import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../models/chapter_ui_model.dart';

/// Single chapter row inside a [GradeSection].
///
/// Only the small leading icon carries state color — row background
/// stays neutral, consistent with the "calm, never flashy" treatment
/// used for StatusBadge and SubjectCard elsewhere in the app.
class ChapterRow extends StatelessWidget {
  const ChapterRow({
    super.key,
    required this.chapter,
    required this.onTap,
  });

  final ChapterUiModel chapter;
  final VoidCallback onTap;

  ({IconData icon, Color color, String label}) get _statusConfig =>
      switch (chapter.status) {
        ChapterStatus.notStarted => (
            icon: Icons.circle_outlined,
            color: AppColors.colorTextSecondary,
            label: 'not started',
          ),
        ChapterStatus.inProgress => (
            icon: Icons.adjust,
            color: AppColors.colorWarning,
            label: 'in progress',
          ),
        ChapterStatus.completed => (
            icon: Icons.check_circle,
            color: AppColors.colorSuccess,
            label: 'completed',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig;

    return Semantics(
      label: '${chapter.title}, ${config.label}. Double tap to open.',
      button: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spaceMd,
            vertical: AppSpacing.spaceSm,
          ),
          child: Row(
            children: [
              Icon(config.icon,
                  size: AppIconSize.iconSizeMd, color: config.color),
              const SizedBox(width: AppSpacing.spaceMd),
              Expanded(
                child: Text(chapter.title, style: AppTypography.typeBody),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
