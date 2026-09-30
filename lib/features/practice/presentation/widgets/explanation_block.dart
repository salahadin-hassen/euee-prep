import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';

/// Post-submit feedback block: correct/incorrect banner, explicit
/// answer labels, explanation, and optional textbook reference.
///
/// No card/box around the explanation itself — a soft top border is
/// enough separation from the answer options above, avoiding
/// boxes-within-boxes (per the design review).
class ExplanationBlock extends StatelessWidget {
  const ExplanationBlock({
    super.key,
    required this.isCorrect,
    required this.explanation,
    this.textbookReference,
    required this.yourAnswerLabel,
    required this.correctAnswerLabel,
  });

  final bool isCorrect;
  final String explanation;
  final String? textbookReference;

  /// e.g. "B" or "B. Mitochondria"
  final String yourAnswerLabel;

  /// e.g. "C" or "C. Chloroplast"
  final String correctAnswerLabel;

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
          if (!isCorrect) ...[
            const SizedBox(height: AppSpacing.spaceSm),
            _AnswerLine(
              label: 'Your answer',
              value: yourAnswerLabel,
              color: AppColors.colorError,
            ),
            const SizedBox(height: AppSpacing.spaceXs),
            _AnswerLine(
              label: 'Correct answer',
              value: correctAnswerLabel,
              color: AppColors.colorSuccess,
            ),
          ],
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
        ],
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  const _AnswerLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: AppTypography.typeBody
              .copyWith(color: AppColors.colorTextSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.typeBody
                .copyWith(fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }
}
