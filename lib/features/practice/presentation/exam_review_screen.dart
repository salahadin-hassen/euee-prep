import 'package:flutter/material.dart';

import '../../../core/design/app_button.dart';
import '../../../core/design/tokens.dart';
import 'models/practice_models.dart';

/// Mandatory checkpoint before an Exam session finalizes. Reachable
/// both at the end of the linear question set AND at any time via an
/// AppBar action (a persistent "status check", not a one-way gate).
///
/// Tile grid here is deliberately view-only — jumping to a specific
/// question happens via the separate Exam Navigator (opened from
/// PracticeScreen's AppBar), keeping this screen a summary rather than
/// a second navigation surface with overlapping responsibility.
class ExamReviewScreen extends StatelessWidget {
  const ExamReviewScreen({
    super.key,
    required this.states,
    required this.remainingSeconds,
    required this.onReviewQuestions,
    required this.onSubmitExam,
  });

  final List<QuestionAttemptState> states;
  final int remainingSeconds;
  final VoidCallback onReviewQuestions;
  final VoidCallback onSubmitExam;

  String get _formattedTime {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final answeredCount = states.where((s) => s.isAnswered).length;
    final unansweredCount = states.length - answeredCount;
    final flaggedCount = states.where((s) => s.isFlagged).length;

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: AppColors.colorBackground,
        elevation: 0,
        title: const Text('Review Before Submitting',
            style: AppTypography.typeHeading3),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      color: AppColors.colorTextSecondary),
                  const SizedBox(width: AppSpacing.spaceXs),
                  Text('$_formattedTime remaining',
                      style: AppTypography.typeBody),
                ],
              ),
              const SizedBox(height: AppSpacing.spaceLg),
              _CountRow(
                icon: Icons.check_circle_outline,
                color: AppColors.colorSuccess,
                label: 'Answered',
                count: answeredCount,
              ),
              _CountRow(
                icon: Icons.circle_outlined,
                color: AppColors.colorTextSecondary,
                label: 'Unanswered',
                count: unansweredCount,
              ),
              _CountRow(
                icon: Icons.flag_outlined,
                color: AppColors.colorWarning,
                label: 'Flagged',
                count: flaggedCount,
              ),
              const SizedBox(height: AppSpacing.spaceLg),
              Expanded(
                child: GridView.builder(
                  itemCount: states.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: AppSpacing.spaceSm,
                    crossAxisSpacing: AppSpacing.spaceSm,
                  ),
                  itemBuilder: (context, index) {
                    final state = states[index];
                    return _ReviewTile(number: index + 1, state: state);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.spaceMd),
              AppButton(
                label: 'Review Questions',
                variant: AppButtonVariant.secondary,
                isFullWidth: true,
                onPressed: onReviewQuestions,
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              AppButton(
                label: 'Submit Exam',
                isFullWidth: true,
                onPressed: onSubmitExam,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spaceXs),
      child: Row(
        children: [
          Icon(icon, size: AppIconSize.iconSizeMd, color: color),
          const SizedBox(width: AppSpacing.spaceSm),
          Text('$label:', style: AppTypography.typeBody),
          const SizedBox(width: AppSpacing.spaceXs),
          Text('$count', style: AppTypography.typeHeading3),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.number, required this.state});

  final int number;
  final QuestionAttemptState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: state.isAnswered
            ? AppColors.colorPrimary.withOpacity(0.12)
            : AppColors.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
        border: Border.all(color: AppColors.colorBorder),
      ),
      child: Stack(
        children: [
          Center(child: Text('$number', style: AppTypography.typeCaption)),
          if (state.isFlagged)
            const Positioned(
              top: 2,
              right: 2,
              child: Icon(Icons.flag, size: 10, color: AppColors.colorWarning),
            ),
        ],
      ),
    );
  }
}
