import 'package:flutter/material.dart';

import '../../../core/design/app_button.dart';
import '../../../core/design/tokens.dart';
import 'models/practice_models.dart';
import 'widgets/session_summary_widgets.dart';

class SessionSummaryScreen extends StatelessWidget {
  const SessionSummaryScreen({
    super.key,
    required this.mode,
    required this.questions,
    required this.states,
    required this.totalTimeSeconds,
    this.timeRemainingSeconds,
    required this.onRetryWrong,
    required this.onReviewResources,
    required this.onBackToChapter,
  });

  final PracticeMode mode;
  final List<QuestionUiModel> questions;
  final List<QuestionAttemptState> states;
  final int totalTimeSeconds;

  /// Non-null only when [mode] is exam — replaces Average Time per the
  /// spec's mode-dependent statistics rule.
  final int? timeRemainingSeconds;

  final ValueChanged<List<QuestionUiModel>> onRetryWrong;
  final VoidCallback onReviewResources;
  final VoidCallback onBackToChapter;

  int get _correctCount {
    var count = 0;
    for (var i = 0; i < questions.length; i++) {
      if (states[i].selectedIndex == questions[i].correctIndex) count++;
    }
    return count;
  }

  List<QuestionUiModel> get _wrongQuestions {
    final wrong = <QuestionUiModel>[];
    for (var i = 0; i < questions.length; i++) {
      if (states[i].selectedIndex != questions[i].correctIndex) {
        wrong.add(questions[i]);
      }
    }
    return wrong;
  }

  /// Per-topic missed counts — Decision 011: a wrong answer counts
  /// against every tagged topic, not just one.
  Map<String, int> get _topicMissedCounts {
    final counts = <String, int>{};
    for (var i = 0; i < questions.length; i++) {
      if (states[i].selectedIndex == questions[i].correctIndex) continue;
      for (final topicId in questions[i].topicIds) {
        counts[topicId] = (counts[topicId] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Per-topic attempted counts (for strongest/weakest, which needs a
  /// rate, not just a raw miss count).
  Map<String, int> get _topicAttemptedCounts {
    final counts = <String, int>{};
    for (final q in questions) {
      for (final topicId in q.topicIds) {
        counts[topicId] = (counts[topicId] ?? 0) + 1;
      }
    }
    return counts;
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final wrongQuestions = _wrongQuestions;
    final missed = _topicMissedCounts;
    final attempted = _topicAttemptedCounts;

    final focusEntries = missed.entries
        .map((e) => FocusAreaEntry(topicName: e.key, missedCount: e.value))
        .toList()
      ..sort((a, b) => b.missedCount.compareTo(a.missedCount));

    // Strongest/weakest by accuracy rate per topic — graceful "—" when
    // there isn't enough data to distinguish (e.g. a tie, or only one
    // topic tested), per the spec's explicit degrade-gracefully note.
    String strongest = '—';
    String weakest = '—';
    if (attempted.length > 1) {
      final rates = <String, double>{
        for (final topicId in attempted.keys)
          topicId: 1 - ((missed[topicId] ?? 0) / attempted[topicId]!),
      };
      final sorted = rates.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (sorted.first.value != sorted.last.value) {
        strongest = sorted.first.key;
        weakest = sorted.last.key;
      }
    }

    final answeredCount = states.where((s) => s.isAnswered).length;
    final avgTimeSeconds =
        answeredCount == 0 ? 0 : (totalTimeSeconds / answeredCount).round();

    final statEntries = <StatEntry>[
      if (mode == PracticeMode.exam && timeRemainingSeconds != null)
        StatEntry(label: 'Time Remaining', value: _formatDuration(timeRemainingSeconds!))
      else
        StatEntry(label: 'Average Time per Question', value: '${avgTimeSeconds}s'),
      StatEntry(label: 'Total Time', value: _formatDuration(totalTimeSeconds)),
      StatEntry(label: 'Strongest Topic', value: strongest),
      StatEntry(label: 'Weakest Topic', value: weakest),
    ];

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.spaceLg),
              ScoreCard(correctCount: _correctCount, totalCount: questions.length),
              const SizedBox(height: AppSpacing.spaceLg),
              StatisticsCard(entries: statEntries),
              const SizedBox(height: AppSpacing.spaceLg),
              Align(
                alignment: Alignment.centerLeft,
                child: FocusAreaList(entries: focusEntries),
              ),
              const SizedBox(height: AppSpacing.spaceXl),
              AppButton(
                label: 'Review Resources',
                variant: AppButtonVariant.secondary,
                isFullWidth: true,
                onPressed: onReviewResources,
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              AppButton(
                label: 'Retry Wrong (${wrongQuestions.length})',
                variant: AppButtonVariant.secondary,
                isFullWidth: true,
                onPressed: wrongQuestions.isEmpty
                    ? null
                    : () => onRetryWrong(wrongQuestions),
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              AppButton(
                label: 'Back to Chapter',
                variant: AppButtonVariant.text,
                isFullWidth: true,
                onPressed: onBackToChapter,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
