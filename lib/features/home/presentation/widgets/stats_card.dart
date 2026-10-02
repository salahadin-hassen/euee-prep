import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';

/// White three-up summary card: questions answered, papers started,
/// active subjects. All values are real numbers handed in by the caller.
class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.questionsAnswered,
    required this.papersStarted,
    required this.activeSubjects,
  });

  final int questionsAnswered;
  final int papersStarted;
  final int activeSubjects;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.radiusCard),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spaceSm,
        vertical: AppSpacing.spaceMd,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatItem(
              value: '$questionsAnswered',
              label: 'Questions answered',
            ),
            const _StatDivider(),
            _StatItem(value: '$papersStarted', label: 'Papers started'),
            const _StatDivider(),
            _StatItem(value: '$activeSubjects', label: 'Active subjects'),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppBrand.navy,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceXs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              height: 1.25,
              color: AppColors.colorTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 44, color: AppColors.colorBorder);
  }
}
