import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../entitlements/presentation/payment_submission_flow.dart';
import 'mock/mock_subjects.dart';
import 'models/subject_ui_model.dart';
import 'subject_detail_screen.dart';
import 'widgets/subject_card.dart';
import 'widgets/subject_list_header.dart';

/// Subject List (Home) screen — the navigation root after onboarding
/// (Decision 014). Shows only the 6 subjects belonging to the user's
/// Preferred Stream (Decision 029) — never the other stream, in any
/// state.
///
/// Presentation-layer only. Data currently comes from [MockSubjects].
///
/// TODO(integration): Replace mock data with a real provider scoped to
/// (a) Preferred Stream for which 6 subjects to show, and (b) purchased
/// Entitlement for lock/unlock state (Decision 012) — these are two
/// separate checks and must not be collapsed into one. Progress values
/// should come from a Service-layer calculation over Attempt history
/// (Decision 016), never a stored field.
class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  bool _isLoading = true;
  List<SubjectUiModel> _subjects = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    // Simulated latency so the skeleton state is visible during review.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _subjects = MockSubjects.naturalScience();
      _isLoading = false;
    });
  }

  void _handleSubjectTap(SubjectUiModel subject) {
    if (subject.isEntitled) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SubjectDetailScreen(
            subjectId: subject.subjectId,
            subjectName: subject.name,
            overallProgress: subject.progress ?? 0.0,
          ),
        ),
      );
      return;
    }

    // Locked subject → real navigation into the already-built
    // Payment Submission flow, pre-filled with this Preferred Stream.
    // All 6 subjects in a stream unlock together (Decision 012), so
    // any locked card in this list leads to the same purchase.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentSubmissionFlow(
          streamName: MockSubjects.preferredStreamName,
          onFlowComplete: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _openSettings() {
    // TODO(integration): navigate to the Settings screen (Preferred
    // Stream change + second-stream purchase entry point, Decision 029).
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings screen coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: AppColors.colorBackground,
        elevation: 0,
        title: const Text('EUEE Prep', style: AppTypography.typeHeading2),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isLoading)
              const SubjectListHeader(
                streamName: MockSubjects.preferredStreamName,
              ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const _SubjectListSkeleton();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spaceMd,
        0,
        AppSpacing.spaceMd,
        AppSpacing.spaceMd,
      ),
      itemCount: _subjects.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.spaceMd),
      itemBuilder: (context, index) {
        final subject = _subjects[index];
        return SubjectCard(
          subject: subject,
          onTap: () => _handleSubjectTap(subject),
        );
      },
    );
  }
}

/// Skeleton loading state — 6 placeholder cards matching SubjectCard's
/// footprint, consistent with the pattern used on Payment History.
class _SubjectListSkeleton extends StatelessWidget {
  const _SubjectListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.spaceMd),
      itemBuilder: (context, index) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: AppColors.colorBorder),
      ),
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.colorDisabled.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.colorDisabled.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceXs),
                Container(
                  width: 160,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.colorDisabled.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
