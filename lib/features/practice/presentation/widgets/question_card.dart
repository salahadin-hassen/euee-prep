import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../models/practice_models.dart';
import 'answer_option.dart';
import 'explanation_block.dart';

/// Question prompt + answer options + conditional feedback.
///
/// [showFeedback] controls whether ExplanationBlock and answer
/// correctness coloring render — true immediately after submit in
/// Learn/Practice, always false during an Exam session (feedback is
/// withheld until the exam is submitted).
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.attemptState,
    required this.showFeedback,
    required this.onSelectOption,
    required this.notesAvailable,
    required this.flashcardsAvailable,
    required this.mindMapAvailable,
    required this.onViewNotes,
    required this.onViewFlashcards,
    required this.onViewMindMap,
  });

  final QuestionUiModel question;
  final QuestionAttemptState attemptState;
  final bool showFeedback;
  final ValueChanged<int> onSelectOption;

  final bool notesAvailable;
  final bool flashcardsAvailable;
  final bool mindMapAvailable;
  final VoidCallback onViewNotes;
  final VoidCallback onViewFlashcards;
  final VoidCallback onViewMindMap;

  static const _optionLabels = ['A', 'B', 'C', 'D', 'E', 'F'];

  AnswerOptionVisualState _stateFor(int index) {
    final selected = attemptState.selectedIndex == index;
    if (!showFeedback) {
      return selected
          ? AnswerOptionVisualState.selected
          : AnswerOptionVisualState.unselected;
    }
    final isCorrectOption = index == question.correctIndex;
    if (isCorrectOption && selected)
      return AnswerOptionVisualState.correctSelected;
    if (isCorrectOption && !selected)
      return AnswerOptionVisualState.correctUnselected;
    if (!isCorrectOption && selected)
      return AnswerOptionVisualState.incorrectSelected;
    return AnswerOptionVisualState.unselected;
  }

  @override
  Widget build(BuildContext context) {
    // Options remain tappable pre-feedback so the student can change
    // their mind (both in-progress Learn/Practice before submitting,
    // and throughout an Exam session where answers are freely
    // revisable until the whole exam is submitted).
    final optionsInteractive = !showFeedback;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.prompt, style: AppTypography.typeHeading2),
          const SizedBox(height: AppSpacing.spaceMd),
          for (var i = 0; i < question.options.length; i++)
            AnswerOption(
              label: _optionLabels[i],
              text: question.options[i],
              state: _stateFor(i),
              onTap: optionsInteractive ? () => onSelectOption(i) : null,
            ),
          if (showFeedback)
            ExplanationBlock(
              isCorrect: attemptState.selectedIndex == question.correctIndex,
              explanation: question.explanation,
              textbookReference: question.textbookReference,
              notesAvailable: notesAvailable,
              flashcardsAvailable: flashcardsAvailable,
              mindMapAvailable: mindMapAvailable,
              onViewNotes: onViewNotes,
              onViewFlashcards: onViewFlashcards,
              onViewMindMap: onViewMindMap,
            ),
        ],
      ),
    );
  }
}
