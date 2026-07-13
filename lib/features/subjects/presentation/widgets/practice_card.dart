import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../models/study_resource_ui_model.dart';

/// The single visually-distinct card on Study Resources — saturated
/// colorPrimary background, white text/icon.
///
/// Deliberately NOT a variant of StudyResourceCard: Practice is
/// structurally the primary action on this screen (per the core
/// "Exam → Mistake → Explanation → Study → Retry" learning loop), not a
/// peer option alongside Notes/Flashcards/Mind Map, so it gets its own
/// component rather than a conditional style branch inside a shared one.
class PracticeCard extends StatelessWidget {
  const PracticeCard({
    super.key,
    required this.practice,
    required this.onTap,
  });

  final PracticeUiModel practice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasQuestions = practice.questionCount > 0;

    return Semantics(
      label: hasQuestions
          ? 'Practice Questions, ${practice.questionCount} questions. '
              'Double tap to start.'
          : 'Practice Questions, not available yet.',
      button: hasQuestions,
      excludeSemantics: true,
      child: Opacity(
        opacity: hasQuestions ? 1 : 0.5,
        child: InkWell(
          onTap: hasQuestions ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.radiusMd),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.colorPrimary,
              borderRadius: BorderRadius.circular(AppRadius.radiusMd),
            ),
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            child: Row(
              children: [
                const Icon(
                  Icons.play_circle_fill,
                  size: AppIconSize.iconSizeLg,
                  color: Colors.white,
                ),
                const SizedBox(width: AppSpacing.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Practice Questions',
                        style: AppTypography.typeHeading3.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spaceXs),
                      Text(
                        'Test what you know',
                        style: AppTypography.typeCaption.copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasQuestions)
                  Text(
                    '${practice.questionCount}',
                    style: AppTypography.typeCaption.copyWith(
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
