import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/progress_bar.dart';
import '../home_providers.dart';

/// Navy "Continue studying" card at the top of Home.
///
/// Shows the paper that is currently mid-flight: subject, EC year, the
/// 1-based number of the next unanswered question, overall completion and
/// the action that resumes it.
class ContinueStudyingCard extends StatelessWidget {
  const ContinueStudyingCard({
    super.key,
    required this.session,
    required this.onContinue,
  });

  final ContinueSession session;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppBrand.navy,
        borderRadius: BorderRadius.circular(AppRadius.radiusCard),
      ),
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTINUE STUDYING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Text(
            session.subjectName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${session.examYearEc} E.C. paper',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
          const SizedBox(height: AppSpacing.spaceSm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Next: question ${session.nextQuestionNumber} '
                  'of ${session.totalQuestions}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
              Text(
                '${session.percent}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          ProgressBar(
            progress: session.progress,
            trackColor: Colors.white.withValues(alpha: 0.2),
            fillColor: Colors.white,
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          SizedBox(
            width: double.infinity,
            child: Semantics(
              button: true,
              label: 'Continue ${session.subjectName} '
                  '${session.examYearEc} paper',
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                child: InkWell(
                  onTap: onContinue,
                  borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppBrand.navy,
                          ),
                        ),
                        SizedBox(width: AppSpacing.spaceSm),
                        Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: AppBrand.navy,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
