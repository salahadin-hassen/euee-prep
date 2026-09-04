import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';

class ScoreCard extends StatelessWidget {
  const ScoreCard({super.key, required this.correctCount, required this.totalCount});

  final int correctCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final accuracy = totalCount == 0 ? 0 : (correctCount / totalCount * 100).round();
    return Column(
      children: [
        Text('$correctCount / $totalCount correct', style: AppTypography.typeHeading1),
        const SizedBox(height: AppSpacing.spaceXs),
        Text('$accuracy% accuracy', style: AppTypography.typeBody.copyWith(
          color: AppColors.colorTextSecondary,
        )),
      ],
    );
  }
}

/// One stat row's worth of data — used for both the mode-dependent
/// time stat and total time.
class StatEntry {
  const StatEntry({required this.label, required this.value});
  final String label;
  final String value;
}

class StatisticsCard extends StatelessWidget {
  const StatisticsCard({super.key, required this.entries});

  final List<StatEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: AppColors.colorBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entries[i].label, style: AppTypography.typeBody),
                Text(entries[i].value, style: AppTypography.typeBody.copyWith(
                  fontWeight: FontWeight.w600,
                )),
              ],
            ),
            if (i != entries.length - 1) const SizedBox(height: AppSpacing.spaceSm),
          ],
        ],
      ),
    );
  }
}

class FocusAreaEntry {
  const FocusAreaEntry({required this.topicName, required this.missedCount});
  final String topicName;
  final int missedCount;
}

/// Topic-level list — a wrong answer is counted against every tagged
/// topic (Decision 011), so this reflects the many-to-many rollup, not
/// a raw per-question tally.
class FocusAreaList extends StatelessWidget {
  const FocusAreaList({super.key, required this.entries});

  final List<FocusAreaEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text(
        'No missed topics — nice work.',
        style: AppTypography.typeBody.copyWith(color: AppColors.colorTextSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Focus areas', style: AppTypography.typeHeading3),
        const SizedBox(height: AppSpacing.spaceSm),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '•  ${entry.topicName} (${entry.missedCount} missed)',
              style: AppTypography.typeBody,
            ),
          ),
      ],
    );
  }
}
