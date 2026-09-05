import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_button.dart';
import '../../../core/design/tokens.dart';
import '../../../core/providers.dart';
import '../../entitlements/presentation/payment_submission_flow.dart';
import '../../streams/presentation/onboarding_screen.dart';
import '../../subjects/domain/models/subject.dart';
import 'models/subject_ui_model.dart';
import 'subject_detail_screen.dart';
import 'widgets/subject_card.dart';
import 'widgets/subject_list_header.dart';

/// Subject List (Home) screen — the navigation root after onboarding
/// (Decision 014). Shows only the 6 subjects belonging to the user's
/// Preferred Stream (Decision 029) — never the other stream, in any
/// state.
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
        backgroundColor: AppColors.colorBackground,
        elevation: 0,
        title: const Text('EUEE Prep', style: AppTypography.typeHeading2),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: preferredStreamAsync.when(
          loading: () => const _SubjectListSkeleton(),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (streamId) {
            if (streamId == null) {
              return const _NoStreamSelected();
            }
            return _StreamSubjectsView(streamId: streamId);
          },
        ),
      ),
    );
  }
}

/// Displays subjects for the given stream, with a resolved stream name
/// for the header label.
class _StreamSubjectsView extends ConsumerWidget {
  const _StreamSubjectsView({required this.streamId});

  final int streamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsByStreamProvider(streamId));
    final streamsAsync = ref.watch(streamRepositoryProvider).getAll();
    final entitlementAsync = ref.watch(
      activeEntitlementForStreamProvider(streamId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<List<dynamic>>(
          future: streamsAsync,
          builder: (context, snapshot) {
            final streams = snapshot.data;
            final stream = streams?.where((s) => s.id == streamId).toList();
            final name = stream != null && stream.isNotEmpty
                ? streamDisplayName(stream.first.slug)
                : '';
            return SubjectListHeader(streamName: name);
          },
        ),
        Expanded(
          child: subjectsAsync.when(
            loading: () => const _SubjectListSkeleton(),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (subjects) {
              if (subjects.isEmpty) {
                return const _EmptySubjects();
              }
              final isEntitled = entitlementAsync.valueOrNull != null;
              return _SubjectList(
                subjects: subjects,
                isEntitled: isEntitled,
                onSubjectTap: (subject) => _handleSubjectTap(
                  context,
                  ref,
                  subject,
                  isEntitled: isEntitled,
                  streamId: streamId,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubjectTap(
    BuildContext context,
    WidgetRef ref,
    Subject subject, {
    required bool isEntitled,
    required int streamId,
  }) async {
    if (isEntitled) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SubjectDetailScreen(
            subjectId: subject.slug,
            subjectName: subject.title,
            overallProgress: 0.0,
          ),
        ),
      );
    } else {
      final streams = await ref.read(streamRepositoryProvider).getAll();
      final stream = streams.where((s) => s.id == streamId).toList();
      final streamSlug = stream.isNotEmpty ? stream.first.slug : '';
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentSubmissionFlow(
            streamName: streamDisplayName(streamSlug),
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
}

/// Maps a domain [Subject] to its presentation [SubjectUiModel].
SubjectUiModel _toUiModel(Subject subject, {required bool isEntitled}) {
  return SubjectUiModel(
    subjectId: subject.slug,
    name: subject.title,
    iconGlyph: _iconForSlug(subject.slug),
    chapterCount: 0, // TODO(integration): query chapter count
    isEntitled: isEntitled,
    progress: null,
  );
}

String _iconForSlug(String slug) {
  switch (slug) {
    case 'physics':
      return '\u{1F9EA}';
    case 'mathematics':
      return '\u{1F4D0}';
    case 'chemistry':
      return '\u{2697}\u{FE0F}';
    case 'biology':
      return '\u{1F9EC}';
    case 'english':
      return '\u{1F4D6}';
    case 'sat_aptitude':
      return '\u{1F9E9}';
    case 'geography':
      return '\u{1F30D}';
    case 'history':
      return '\u{1F3DB}\u{FE0F}';
    case 'economics':
      return '\u{1F4B0}';
    default:
      return '\u{1F4DA}';
  }
}

/// Renders the subject list with [SubjectCard] items.
class _SubjectList extends StatelessWidget {
  const _SubjectList({
    required this.subjects,
    required this.isEntitled,
    required this.onSubjectTap,
  });

  final List<Subject> subjects;
  final bool isEntitled;
  final ValueChanged<Subject> onSubjectTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spaceMd,
        0,
        AppSpacing.spaceMd,
        AppSpacing.spaceMd,
      ),
      itemCount: subjects.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.spaceMd),
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return SubjectCard(
          subject: _toUiModel(subject, isEntitled: isEntitled),
          onTap: () => onSubjectTap(subject),
        );
      },
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
              variant: AppButtonVariant.primary,
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

/// Skeleton loading state — 6 placeholder cards matching SubjectCard's
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
              color: AppColors.colorDisabled.withValues(alpha: 0.3),
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
            SizedBox(height: AppSpacing.spaceSm),
            Text(
              'Import a content pack to see subjects here.',
              style: AppTypography.typeCaption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
