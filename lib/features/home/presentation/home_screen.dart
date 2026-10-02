import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_button.dart';
import '../../../core/design/tokens.dart';
import '../../../core/providers.dart';
import '../../entitlements/domain/services/access_policy.dart';
import '../../entitlements/presentation/payment_submission_flow.dart';
import '../../subjects/domain/models/subject.dart';
import '../../subjects/presentation/subject_actions.dart';
import 'home_providers.dart';
import 'widgets/continue_studying_card.dart';
import 'widgets/home_header.dart';
import 'widgets/home_status_cards.dart';
import 'widgets/stats_card.dart';
import 'widgets/subject_preview_card.dart';

/// Home dashboard — the launch tab after onboarding (Decision 014).
///
/// Every number on this screen is derived from the Attempt, Exam and
/// Subject tables for the Preferred Stream. No mock data.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onViewAll});

  /// Switches the shell to the Subjects tab.
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferredStreamAsync = ref.watch(preferredStreamIdProvider);

    return Scaffold(
      backgroundColor: AppBrand.cream,
      body: SafeArea(
        child: preferredStreamAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (streamId) {
            if (streamId == null) return const _WelcomeState();
            return _HomeContent(streamId: streamId, onViewAll: onViewAll);
          },
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.streamId, required this.onViewAll});

  final int streamId;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsByStreamProvider(streamId));
    final streamsAsync = ref.watch(allStreamsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        streamsAsync.when(
          loading: () => const SizedBox(height: 52),
          error: (_, __) => const SizedBox(height: 52),
          data: (streams) {
            final match = streams.where((s) => s.id == streamId).toList();
            return HomeHeader(
              streamName:
                  match.isNotEmpty ? streamDisplayName(match.first.slug) : '',
              onMenuTap: () => Navigator.of(context).pushNamed('/settings'),
            );
          },
        ),
        Expanded(
          child: subjectsAsync.when(
            loading: () => const _HomeSkeleton(),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (subjects) {
              if (subjects.isEmpty) return const _EmptyHome();
              return _HomeBody(
                streamId: streamId,
                subjects: subjects,
                onViewAll: onViewAll,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Renders the dashboard cards once the derived numbers are ready.
class _HomeBody extends ConsumerWidget {
  const _HomeBody({
    required this.streamId,
    required this.subjects,
    required this.onViewAll,
  });

  final int streamId;
  final List<Subject> subjects;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(homeDashboardProvider(streamId));
    final entitlementAsync =
        ref.watch(activeEntitlementForStreamProvider(streamId));

    return dashboardAsync.when(
      loading: () => const _HomeSkeleton(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (dashboard) {
        final preview = subjects.take(3).toList(growable: false);
        final isEntitled = entitlementAsync.valueOrNull != null;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.spaceMd,
            AppSpacing.spaceSm,
            AppSpacing.spaceMd,
            AppSpacing.spaceXl,
          ),
          children: [
            if (dashboard.continueSession != null) ...[
              ContinueStudyingCard(
                session: dashboard.continueSession!,
                onContinue: () {
                  final session = dashboard.continueSession!;
                  openPaperPractice(
                    context,
                    ref,
                    exam: session.exam,
                    subjectName: session.subjectName,
                    onlyQuestionIds: session.remainingQuestionIds,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.spaceMd),
            ],
            StatsCard(
              questionsAnswered: dashboard.questionsAnswered,
              papersStarted: dashboard.papersStarted,
              activeSubjects: dashboard.activeSubjects,
            ),
            const SizedBox(height: AppSpacing.spaceLg),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spaceSm),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'YOUR SUBJECTS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppBrand.navy,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'View all subjects',
                    child: InkWell(
                      onTap: onViewAll,
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.spaceXs),
                        child: Text(
                          'View all',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppBrand.blue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SubjectPreviewCard(
              subjects: preview,
              stats: dashboard.subjectStats,
              onSubjectTap: (subject, index) => openSubject(
                context,
                ref,
                subject: subject,
                hasAccess:
                    AccessPolicy.isOpen(index: index, isEntitled: isEntitled),
                streamId: streamId,
              ),
            ),
            const SizedBox(height: AppSpacing.spaceMd),
            OfflineReadyRow(paperCount: dashboard.offlinePapers),
            if (!isEntitled) ...[
              const SizedBox(height: AppSpacing.spaceSm),
              UnlockBar(
                onTap: () => _openUnlock(context, ref),
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              const UnlockVideoRow(),
            ],
          ],
        );
      },
    );
  }

  Future<void> _openUnlock(BuildContext context, WidgetRef ref) async {
    final streams = await ref.read(streamRepositoryProvider).getAll();
    final stream = streams.where((s) => s.id == streamId).toList();
    final slug = stream.isNotEmpty ? stream.first.slug : '';
    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentSubmissionFlow(
          streamName: streamDisplayName(slug),
          onFlowComplete: () {
            if (context.mounted) {
              Navigator.of(context).pop();
              ref.invalidate(activeEntitlementForStreamProvider(streamId));
            }
          },
        ),
      ),
    );
  }
}

/// Shown before a Preferred Stream exists (first launch).
class _WelcomeState extends StatelessWidget {
  const _WelcomeState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.school_outlined,
              size: AppIconSize.iconSizeXl,
              color: AppColors.colorTextSecondary,
            ),
            const SizedBox(height: AppSpacing.spaceMd),
            const Text(
              'Welcome to EUEE Prep',
              style: AppTypography.typeHeading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spaceSm),
            const Text(
              'Choose your stream to get started.',
              style: AppTypography.typeBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spaceLg),
            AppButton(
              label: 'Select Stream',
              isFullWidth: true,
              onPressed: () => Navigator.of(context).pushNamed('/onboarding'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the Preferred Stream has no subjects yet.
class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: AppIconSize.iconSizeXl,
              color: AppColors.colorTextSecondary,
            ),
            SizedBox(height: AppSpacing.spaceMd),
            Text(
              'No subjects available',
              style: AppTypography.typeHeading3,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton shown while the dashboard numbers are being derived.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.colorSurface,
              borderRadius: BorderRadius.circular(AppRadius.radiusCard),
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
        ],
      ],
    );
  }
}
