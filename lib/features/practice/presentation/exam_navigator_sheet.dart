import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import 'models/practice_models.dart';

/// Grid of numbered tiles for jumping directly to any question in an
/// Exam session. Deliberately plain (number + state icon only, no
/// question previews) so it stays usable even at 180 questions.
///
/// Shown via [showExamNavigator]; returns the selected index (or null
/// if dismissed without a selection) to the caller.
///
/// BUGFIX: the sheet is now `isScrollControlled` with a bounded,
/// internally-scrolling grid. The previous version used
/// `shrinkWrap: true` + `NeverScrollableScrollPhysics` inside a plain
/// (non-scrolling) Column with no outer scroll container — fine at
/// chapter scale (a handful of questions) but guaranteed to overflow
/// and clip content at full-exam scale (up to 180 questions), since
/// neither the grid nor its parent could scroll to fit everything.
Future<int?> showExamNavigator({
  required BuildContext context,
  required List<QuestionAttemptState> states,
  required int currentIndex,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: AppColors.colorSurface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.radiusLg)),
    ),
    builder: (context) => _ExamNavigatorContent(
      states: states,
      currentIndex: currentIndex,
    ),
  );
}

class _ExamNavigatorContent extends StatelessWidget {
  const _ExamNavigatorContent({
    required this.states,
    required this.currentIndex,
  });

  final List<QuestionAttemptState> states;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    // Bounded to a fraction of screen height so the sheet never exceeds
    // the viewport regardless of question count — the grid scrolls
    // internally beyond that, rather than the sheet trying to grow to
    // fit every tile unscrolled.
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Jump to Question', style: AppTypography.typeHeading3),
              const SizedBox(height: AppSpacing.spaceMd),
              Flexible(
                child: GridView.builder(
                  itemCount: states.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: AppSpacing.spaceSm,
                    crossAxisSpacing: AppSpacing.spaceSm,
                  ),
                  itemBuilder: (context, index) {
                    return _NavigatorTile(
                      number: index + 1,
                      isCurrent: index == currentIndex,
                      isAnswered: states[index].isAnswered,
                      isFlagged: states[index].isFlagged,
                      onTap: () => Navigator.of(context).pop(index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigatorTile extends StatelessWidget {
  const _NavigatorTile({
    required this.number,
    required this.isCurrent,
    required this.isAnswered,
    required this.isFlagged,
    required this.onTap,
  });

  final int number;
  final bool isCurrent;
  final bool isAnswered;
  final bool isFlagged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semanticState = [
      if (isCurrent) 'current question',
      isAnswered ? 'answered' : 'unanswered',
      if (isFlagged) 'flagged for review',
    ].join(', ');

    return Semantics(
      label: 'Question $number, $semanticState. Double tap to open.',
      button: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
        child: Container(
          decoration: BoxDecoration(
            color: isAnswered
                ? AppColors.colorPrimary.withOpacity(0.12)
                : AppColors.colorSurface,
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
            border: Border.all(
              color: isCurrent ? AppColors.colorPrimary : AppColors.colorBorder,
              width: isCurrent ? 2 : AppStroke.strokeThin,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Text('$number', style: AppTypography.typeBody),
              ),
              if (isFlagged)
                const Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(
                    Icons.flag,
                    size: AppIconSize.iconSizeSm,
                    color: AppColors.colorWarning,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
