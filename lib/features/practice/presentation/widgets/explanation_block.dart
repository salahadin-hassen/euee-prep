import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';

/// Post-submit feedback block: correct/incorrect banner, explanation,
/// optional textbook reference, and resource navigation links.
///
/// No card/box around the explanation itself — a soft top border is
/// enough separation from the answer options above, avoiding
/// boxes-within-boxes (per the design review).
///
/// Resource links are navigation-only — tapping pushes the real
/// Notes/Flashcards/Mind Map screen for this chapter; nothing renders
/// inline here.
class ExplanationBlock extends StatelessWidget {
  const ExplanationBlock({
    super.key,
    required this.isCorrect,
    required this.explanation,
    this.textbookReference,
    required this.notesAvailable,
    required this.flashcardsAvailable,
    required this.mindMapAvailable,
    required this.onViewNotes,
    required this.onViewFlashcards,
    required this.onViewMindMap,
  });

  final bool isCorrect;
  final String explanation;
  final String? textbookReference;

  final bool notesAvailable;
  final bool flashcardsAvailable;
  final bool mindMapAvailable;

  final VoidCallback onViewNotes;
  final VoidCallback onViewFlashcards;
  final VoidCallback onViewMindMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.spaceMd),
      padding: const EdgeInsets.only(top: AppSpacing.spaceMd),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
              color: AppColors.colorBorder, width: AppStroke.strokeThin),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                size: AppIconSize.iconSizeMd,
                color:
                    isCorrect ? AppColors.colorSuccess : AppColors.colorError,
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Text(
                isCorrect ? 'Correct' : 'Incorrect',
                style: AppTypography.typeHeading3.copyWith(
                  color:
                      isCorrect ? AppColors.colorSuccess : AppColors.colorError,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Text(explanation, style: AppTypography.typeBody),
          if (textbookReference != null) ...[
            const SizedBox(height: AppSpacing.spaceSm),
            Row(
              children: [
                const Icon(
                  Icons.menu_book_outlined,
                  size: AppIconSize.iconSizeSm,
                  color: AppColors.colorTextSecondary,
                ),
                const SizedBox(width: AppSpacing.spaceXs),
                Text(textbookReference!, style: AppTypography.typeCaption),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.spaceMd),
          Wrap(
            spacing: AppSpacing.spaceSm,
            runSpacing: AppSpacing.spaceSm,
            children: [
              if (notesAvailable)
                _ResourceLinkChip(label: 'View Notes', onTap: onViewNotes),
              if (flashcardsAvailable)
                _ResourceLinkChip(
                    label: 'View Flashcards', onTap: onViewFlashcards),
              if (mindMapAvailable)
                _ResourceLinkChip(label: 'View Mind Map', onTap: onViewMindMap),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceLinkChip extends StatelessWidget {
  const _ResourceLinkChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label. Double tap to open.',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spaceMd,
            vertical: AppSpacing.spaceSm,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.colorPrimary),
            borderRadius: BorderRadius.circular(AppRadius.radiusFull),
          ),
          child: Text(
            label,
            style: AppTypography.typeCaption
                .copyWith(color: AppColors.colorPrimary),
          ),
        ),
      ),
    );
  }
}
