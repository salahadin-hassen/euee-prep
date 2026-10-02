import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_button.dart';
import '../../../core/design/subject_palette.dart';
import '../../../core/design/tokens.dart';
import '../../../core/providers.dart';
import '../../content/presentation/import_screen.dart';
import '../../entitlements/domain/services/access_policy.dart';
import '../../entitlements/presentation/payment_submission_flow.dart';
import '../../streams/presentation/onboarding_screen.dart';
import '../../subjects/domain/models/subject.dart';
import 'models/subject_ui_model.dart';
import 'subject_actions.dart';
import 'widgets/subject_card.dart';

/// Subject List screen — the second tab of the shell and the "Subjects"
/// destination of Decision 014's Home → Subjects → Subject navigation.
///
/// Shows only the subjects belonging to the student's Preferred Stream
/// (Decision 029), each with its real paper/question counts. Locked rows
/// route to the payment flow; the "Unlock all subjects" card is shown only
/// while the stream has no active entitlement.
///
/// Data is loaded via Riverpod providers backed by the Subject repository
/// → Subject Local Data Source → Drift. No mock data is used.
class SubjectListScreen extends ConsumerWidget {
  const SubjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferredStreamAsync = ref.watch(preferredStreamIdProvider);

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: AppBrand.blue,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
        ),
        title: const _StreamTitle(),
      ),
      body: SafeArea(
        top: false,
        child: preferredStreamAsync.when(
          loading: () => const _SubjectListSkeleton(),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (streamId) {
            if (streamId == null) return const _NoStreamSelected();
            return _StreamSubjectsView(streamId: streamId);
          },
        ),
      ),
    );
  }
}

/// Bold white Preferred Stream name in the blue app bar.
class _StreamTitle extends ConsumerWidget {
  const _StreamTitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamId = ref.watch(preferredStreamIdProvider).valueOrNull;
    final streams = ref.watch(allStreamsProvider).valueOrNull;
    var name = '';
    if (streamId != null && streams != null) {
      final match = streams.where((s) => s.id == streamId).toList();
      if (match.isNotEmpty) name = streamDisplayName(match.first.slug);
    }
    return Text(
      name,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

/// Loads subjects, their real counts and the stream entitlement, then
/// renders the list plus the unlock card when the stream is still locked.
class _StreamSubjectsView extends ConsumerWidget {
  const _StreamSubjectsView({required this.streamId});

  final int streamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsByStreamProvider(streamId));
    final statsAsync = ref.watch(subjectStatsForStreamProvider(streamId));
    final entitlementAsync =
        ref.watch(activeEntitlementForStreamProvider(streamId));
    final streams = ref.watch(allStreamsProvider).valueOrNull ?? const [];
    final stream = streams.where((s) => s.id == streamId).toList();
    final streamName =
        stream.isNotEmpty ? streamDisplayName(stream.first.slug) : '';

    return subjectsAsync.when(
      loading: () => const _SubjectListSkeleton(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (subjects) {
        if (subjects.isEmpty) return const _EmptySubjects();

        return statsAsync.when(
          loading: () => const _SubjectListSkeleton(),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (stats) {
            final isEntitled = entitlementAsync.valueOrNull != null;
            return _SubjectListView(
              subjects: subjects,
              stats: stats,
              isEntitled: isEntitled,
              streamName: streamName,
              streamId: streamId,
            );
          },
        );
      },
    );
  }
}

class _SubjectListView extends ConsumerWidget {
  const _SubjectListView({
    required this.subjects,
    required this.stats,
    required this.isEntitled,
    required this.streamName,
    required this.streamId,
  });

  final Map<int, SubjectStats> stats;
  final List<Subject> subjects;
  final bool isEntitled;
  final String streamName;
  final int streamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = <Widget>[];
    for (var i = 0; i < subjects.length; i++) {
      final subject = subjects[i];
      final s = stats[subject.id] ??
          const SubjectStats(
            paperCount: 0,
            questionCount: 0,
            answeredCount: 0,
          );
      final hasAccess =
          AccessPolicy.isOpen(index: i, isEntitled: isEntitled);
      items.add(
        SubjectCard(
          subject: SubjectUiModel(
            subjectId: subject.slug,
            name: subject.title,
            iconGlyph: subjectIconForSlug(subject.slug),
            paperCount: s.paperCount,
            questionCount: s.questionCount,
            isOpen: hasAccess,
          ),
          onTap: () => openSubject(
            context,
            ref,
            subject: subject,
            hasAccess: hasAccess,
            streamId: streamId,
          ),
        ),
      );
      items.add(const SizedBox(height: AppSpacing.spaceMd));
    }

    if (!isEntitled) {
      items.add(
        _UnlockAllCard(
          streamName: streamName,
          lockedSubjectTitles: [
            for (var i = 0; i < subjects.length; i++)
              if (!AccessPolicy.isOpen(index: i, isEntitled: isEntitled))
                subjects[i].title,
          ],
          onUnlock: () => _openUnlock(context, ref),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spaceMd,
        AppSpacing.spaceMd,
        AppSpacing.spaceMd,
        AppSpacing.spaceXl,
      ),
      children: items,
    );
  }

  void _openUnlock(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentSubmissionFlow(
          streamName: streamName,
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

/// Light-blue upsell card shown while the whole stream is locked.
class _UnlockAllCard extends StatelessWidget {
  const _UnlockAllCard({
    required this.streamName,
    required this.lockedSubjectTitles,
    required this.onUnlock,
  });

  final String streamName;
  final List<String> lockedSubjectTitles;
  final VoidCallback onUnlock;

  String get _listOfNames {
    // Every row is inside the free-sample window — the upsell is for the
    // whole pack, so name no individual subject.
    if (lockedSubjectTitles.isEmpty) return 'every';
    if (lockedSubjectTitles.length == 1) return lockedSubjectTitles.single;
    if (lockedSubjectTitles.length == 2) {
      return '${lockedSubjectTitles.first} and ${lockedSubjectTitles.last}';
    }
    final head = lockedSubjectTitles.sublist(0, lockedSubjectTitles.length - 1);
    return '${head.join(', ')} and ${lockedSubjectTitles.last}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppBrand.blueTint,
        borderRadius: BorderRadius.circular(AppRadius.radiusCard),
      ),
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Unlock all subjects',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppBrand.navy,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Text(
            'Purchase the $streamName pack to access $_listOfNames papers.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.colorTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Material(
            color: AppBrand.navy,
            borderRadius: BorderRadius.circular(AppRadius.radiusMd),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.radiusMd),
              onTap: onUnlock,
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.spaceMd,
                  vertical: AppSpacing.spaceSm + 2,
                ),
                child: Text(
                  'View options',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

/// Shown when no Preferred Stream has been set (first launch).
class _NoStreamSelected extends StatelessWidget {
  const _NoStreamSelected();

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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OnboardingScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading state — placeholder rows matching SubjectCard's
/// footprint.
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
        borderRadius: BorderRadius.circular(AppRadius.radiusCard),
      ),
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.colorDisabled.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadius.radiusMd),
            ),
          ),
          const SizedBox(width: AppSpacing.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.colorDisabled.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceXs),
                Container(
                  width: 160,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.colorDisabled.withValues(alpha: 0.3),
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

/// Shown when the preferred stream is set but contains no subjects
/// (content pack not yet imported).
class _EmptySubjects extends StatelessWidget {
  const _EmptySubjects();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.library_books_outlined,
              size: AppIconSize.iconSizeXl,
              color: AppColors.colorTextSecondary,
            ),
            const SizedBox(height: AppSpacing.spaceMd),
            const Text(
              'No subjects available',
              style: AppTypography.typeHeading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spaceSm),
            const Text(
              'Import a content pack to see subjects here.',
              style: AppTypography.typeCaption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spaceLg),
            AppButton(
              label: 'Import Content Pack',
              isFullWidth: true,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ImportScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
