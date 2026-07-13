import 'package:flutter/material.dart';

import '../../../../core/design/app_button.dart';
import '../../../../core/design/tokens.dart';

/// Previous / Next controls below the flashcard.
///
/// Reliable baseline alongside optional swipe gestures — button
/// controls must exist regardless of swipe support, since gesture-only
/// navigation is an accessibility anti-pattern (per the design review).
class FlashcardNavControls extends StatelessWidget {
  const FlashcardNavControls({
    super.key,
    required this.canGoPrevious,
    required this.onPrevious,
    required this.onNext,
  });

  final bool canGoPrevious;
  final VoidCallback onPrevious;

  /// Always enabled — on the last card, "Next" triggers deck-complete
  /// rather than being disabled (per the design review).
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spaceMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppButton(
            label: 'Previous',
            variant: AppButtonVariant.text,
            icon: Icons.arrow_back,
            onPressed: canGoPrevious ? onPrevious : null,
          ),
          AppButton(
            label: 'Next',
            variant: AppButtonVariant.text,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
