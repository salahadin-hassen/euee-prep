import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';

enum AnswerOptionVisualState {
  unselected,
  selected,
  correctSelected,
  incorrectSelected,
  correctUnselected,
}

/// Single answer row. Only the leading icon and option text carry state
/// color — row background stays neutral in every state, per the "calm,
/// never flooded with color" rule applied consistently across the app.
class AnswerOption extends StatelessWidget {
  const AnswerOption({
    super.key,
    required this.label,
    required this.text,
    required this.state,
    required this.onTap,
  });

  /// e.g. "A", "B", "C" — used in the accessible label.
  final String label;
  final String text;
  final AnswerOptionVisualState state;

  /// Null when the option can no longer be tapped (post-submit in
  /// Learn/Practice; Exam Mode options remain tappable until the whole
  /// exam is submitted, so this is rarely null there).
  final VoidCallback? onTap;

  ({IconData icon, Color color}) get _visual => switch (state) {
        AnswerOptionVisualState.unselected => (
            icon: Icons.circle_outlined,
            color: AppColors.colorBorder,
          ),
        AnswerOptionVisualState.selected => (
            icon: Icons.circle,
            color: AppColors.colorPrimary,
          ),
        AnswerOptionVisualState.correctSelected => (
            icon: Icons.check_circle,
            color: AppColors.colorSuccess,
          ),
        AnswerOptionVisualState.incorrectSelected => (
            icon: Icons.cancel,
            color: AppColors.colorError,
          ),
        AnswerOptionVisualState.correctUnselected => (
            icon: Icons.check_circle_outline,
            color: AppColors.colorSuccess,
          ),
      };

  String get _semanticLabel {
    final base = 'Option $label, $text';
    return switch (state) {
      AnswerOptionVisualState.unselected =>
        onTap != null ? '$base. Double tap to select.' : base,
      AnswerOptionVisualState.selected => '$base, selected.',
      AnswerOptionVisualState.correctSelected =>
        '$base, selected, correct answer.',
      AnswerOptionVisualState.incorrectSelected => '$base, selected, incorrect.',
      AnswerOptionVisualState.correctUnselected => '$base, correct answer.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final visual = _visual;
    final textColor = switch (state) {
      AnswerOptionVisualState.correctSelected => AppColors.colorSuccess,
      AnswerOptionVisualState.incorrectSelected => AppColors.colorError,
      _ => AppColors.colorTextPrimary,
    };

    return Semantics(
      label: _semanticLabel,
      button: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spaceMd,
            vertical: AppSpacing.spaceSm,
          ),
          child: Row(
            children: [
              Icon(visual.icon, size: AppIconSize.iconSizeMd, color: visual.color),
              const SizedBox(width: AppSpacing.spaceMd),
              Expanded(
                child: Text(
                  '$label. $text',
                  style: AppTypography.typeBody.copyWith(color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
