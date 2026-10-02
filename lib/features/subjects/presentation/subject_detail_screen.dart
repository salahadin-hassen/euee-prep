import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_button.dart';
import '../../../core/design/tokens.dart';
import '../../../core/providers.dart';
import '../../content/domain/models/exam.dart';
import '../../exams/domain/models/published_paper.dart';
import '../../exams/presentation/paper_download_controller.dart';
import '../../practice/presentation/models/practice_models.dart';
import '../../practice/presentation/practice_screen.dart';

/// Decodes the `choices_json` column into the option list shown in practice.
///
/// The importer writes this column with `jsonEncode`, so it must be read back
/// with the matching JSON parser: choices routinely contain commas, quotes and
/// brackets (e.g. `"Option A, with a comma"`), which the previous
/// `replaceAll`/`split(',')` parsing mangled into extra options.
///
/// Throws [FormatException] when the stored value is not a JSON array of
/// strings — malformed content must fail loudly rather than render as
/// silently corrupted options.
List<String> decodeChoicesJson(String choicesJson) {
  final Object? decoded;
  try {
    decoded = jsonDecode(choicesJson);
  } on FormatException catch (e) {
    throw FormatException('choices_json is not valid JSON: ${e.message}');
  }
  if (decoded is! List) {
    throw const FormatException('choices_json must be a JSON array of strings');
  }
  return decoded.map((element) {
    if (element is! String) {
      throw const FormatException(
        'choices_json must be a JSON array of strings',
      );
    }
    return element;
  }).toList();
}


/// Subject Detail screen — shows past papers for one subject.
///
/// Local papers come from [examsBySubjectProvider]; published papers that
/// are not installed yet come from [papersWithStatusProvider] and are
/// fetched through [paperDownloadControllerProvider] (Available →
/// Downloading → Installed, or Update available → Update). Learners never
/// import content manually — download is the only way content arrives.
class SubjectDetailScreen extends ConsumerWidget {
  const SubjectDetailScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.subjectSlug,
    required this.streamId,
  });

  final int subjectId;
  final String subjectName;
  final String subjectSlug;
  final int streamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsBySubjectProvider(subjectId));
    final streamsAsync = ref.watch(allStreamsProvider);

    String? streamSlug;
    final streams = streamsAsync.valueOrNull;
    if (streams != null) {
      for (final stream in streams) {
        if (stream.id == streamId) {
          streamSlug = stream.slug;
          break;
        }
      }
    }

    // The catalog query always pairs stream + subject so an ambiguous slug
    // (english, mathematics, sat) can't leak papers from the other stream.
    // While the stream slug is unknown the screen renders local content only.
    final catalogAsync = streamSlug == null
        ? null
        : ref.watch(
            papersWithStatusProvider(
              PublishedPaperQuery(stream: streamSlug, subjectSlug: subjectSlug),
            ),
          );

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: AppColors.colorBackground,
        elevation: 0,
        title: Text(subjectName, style: AppTypography.typeHeading3),
      ),
      body: SafeArea(
        child: examsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (exams) {
            final localPapers = exams;
            if (localPapers.isNotEmpty) {
              return _PaperList(
                exams: localPapers,
                papers: catalogAsync?.valueOrNull ?? const [],
                subjectName: subjectName,
              );
            }
            // No local papers: wait for the catalog when it is in flight,
            // otherwise fall back to the empty state (catalog offline too).
            final catalog = catalogAsync;
            if (catalog == null) {
              if (streamsAsync.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return const _NoPapers();
            }
            return catalog.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              // Offline-first: a failed catalog read degrades to the empty
              // state instead of an error page.
              error: (_, __) => const _NoPapers(),
              data: (papers) {
                if (papers.isEmpty) return const _NoPapers();
                return _PaperList(
                  exams: const [],
                  papers: papers,
                  subjectName: subjectName,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Strips the `#version` suffix off a local `content_packs.id`
/// (`{pack_id}#{pack_version}`) so it can be matched against a catalog
/// `packId`. Returns null for ids that don't carry a version separator
/// (e.g. hand-seeded fixtures) — those simply have no catalog counterpart.
String? _packIdOf(String sourcePackId) {
  final cut = sourcePackId.lastIndexOf('#');
  if (cut <= 0) return null;
  return sourcePackId.substring(0, cut);
}

class _PaperList extends ConsumerWidget {
  const _PaperList({
    required this.exams,
    required this.papers,
    required this.subjectName,
  });

  final List<Exam> exams;
  final List<PaperAvailability> papers;
  final String subjectName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(paperDownloadControllerProvider);
    final controller = ref.read(paperDownloadControllerProvider.notifier);

    final catalogByPackId = <String, PaperAvailability>{
      for (final availability in papers) availability.paper.packId: availability,
    };
    final matchedPackIds = <String>{};

    final cards = <Widget>[];
    for (final exam in exams) {
      final packId = _packIdOf(exam.sourcePackId);
      final availability = packId == null ? null : catalogByPackId[packId];
      if (availability != null) matchedPackIds.add(availability.paper.packId);

      final isDownloading = _isActiveDownload(
        downloadState,
        availability,
      ) && downloadState.phase == PaperDownloadPhase.downloading;
      final hasFailed = _isActiveDownload(downloadState, availability) &&
          downloadState.phase == PaperDownloadPhase.failed;
      final updateAvailable =
          availability?.state == PaperInstallState.updateAvailable;

      final Widget action;
      if (isDownloading) {
        action = _DownloadProgress(progress: downloadState.progress);
      } else if (hasFailed) {
        action = AppButton(
          label: 'Retry',
          onPressed: () => controller.download(availability!.paper),
        );
      } else if (updateAvailable) {
        action = AppButton(
          label: 'Update',
          onPressed: downloadState.isDownloading
              ? null
              : () => controller.download(availability!.paper),
        );
      } else {
        action = AppButton(
          label: 'Open',
          variant: AppButtonVariant.secondary,
          onPressed: () => _showStartSheet(context, exam, subjectName),
        );
      }

      cards.add(
        _PaperCard(
          exam: exam,
          subjectName: subjectName,
          action: action,
          onTap: () => _showStartSheet(context, exam, subjectName),
        ),
      );
    }

    for (final availability in papers) {
      if (matchedPackIds.contains(availability.paper.packId)) continue;
      // Installed packs always have local exams (import is atomic), so a
      // catalog row without a local counterpart is only ever not-installed.
      if (availability.state != PaperInstallState.available) continue;
      cards.add(
        _DownloadCard(
          availability: availability,
          downloadState: downloadState,
          onStart: () => controller.download(availability.paper),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      children: [
        Text(
          'Past papers',
          style: AppTypography.typeCaption.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        for (var i = 0; i < cards.length; i++) ...[
          cards[i],
          if (i < cards.length - 1)
            const SizedBox(height: AppSpacing.spaceMd),
        ],
      ],
    );
  }

  bool _isActiveDownload(
    PaperDownloadState state,
    PaperAvailability? availability,
  ) =>
      availability != null &&
      state.paper?.packVersionId == availability.paper.packVersionId;

  void _showStartSheet(
    BuildContext context,
    Exam exam,
    String subjectName,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.colorBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.radiusLg)),
      ),
      builder: (context) => _PaperStartSheet(
        exam: exam,
        subjectName: subjectName,
        onStart: () {
          Navigator.of(context).pop();
          _openPractice(context, exam, subjectName);
        },
      ),
    );
  }

  void _openPractice(
    BuildContext context,
    Exam exam,
    String subjectName,
  ) async {
    final questionRepo =
        ProviderScope.containerOf(context).read(questionRepositoryProvider);
    final questionIds = exam.questionIds;
    if (questionIds.isEmpty) return;

    final questions = await questionRepo.getByIds(questionIds);
    if (!context.mounted) return;

    final idToIndex = <int, int>{};
    for (var i = 0; i < questionIds.length; i++) {
      idToIndex[questionIds[i]] = i;
    }
    final sorted = List.of(questions)
      ..sort((a, b) =>
          (idToIndex[a.id] ?? 0).compareTo(idToIndex[b.id] ?? 0));

    final uiModels = sorted.map((q) {
      return QuestionUiModel(
        dbQuestionId: q.id,
        questionId: q.packLocalId,
        topicIds: const [],
        prompt: q.prompt,
        options: decodeChoicesJson(q.choicesJson),
        correctIndex: q.correctChoiceIndex,
        explanation: q.explanation ?? '',
        textbookReference: q.textbookReference,
      );
    }).toList();

    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PracticeScreen(
          mode: PracticeMode.practice,
          questions: uiModels,
          chapterId: exam.packLocalId,
          chapterTitle: '$subjectName ${exam.examYearEc}',
          examId: exam.id,
          subjectId: exam.subjectId,
        ),
      ),
    );
  }
}

/// Minimal bottom sheet shown before starting practice.
class _PaperStartSheet extends StatelessWidget {
  const _PaperStartSheet({
    required this.exam,
    required this.subjectName,
    required this.onStart,
  });

  final Exam exam;
  final String subjectName;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final year = exam.examYearEc;
    final questionCount = exam.questionIds.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.colorBorder,
                  borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spaceLg),
            Text('$subjectName $year', style: AppTypography.typeHeading2),
            const SizedBox(height: AppSpacing.spaceXs),
            Text(
              '$questionCount questions',
              style: AppTypography.typeBody
                  .copyWith(color: AppColors.colorTextSecondary),
            ),
            const SizedBox(height: AppSpacing.spaceLg),
            AppButton(
              label: 'Start Practice',
              isFullWidth: true,
              onPressed: onStart,
            ),
            const SizedBox(height: AppSpacing.spaceSm),
          ],
        ),
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  const _PaperCard({
    required this.exam,
    required this.subjectName,
    required this.action,
    required this.onTap,
  });

  final Exam exam;
  final String subjectName;

  /// Trailing control: Open for local papers, Update/Retry/progress while
  /// the catalog reports a newer published version.
  final Widget action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final questionCount = exam.questionIds.length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spaceMd),
        decoration: BoxDecoration(
          color: AppColors.colorSurface,
          borderRadius: BorderRadius.circular(AppRadius.radiusMd),
          border: Border.all(color: AppColors.colorBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.colorPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.radiusSm),
              ),
              child: Center(
                child: Text(
                  '${exam.examYearEc}',
                  style: AppTypography.typeHeading3.copyWith(
                    color: AppColors.colorPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$subjectName ${exam.examYearEc}',
                    style: AppTypography.typeBody
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.spaceXs),
                  Text(
                    '$questionCount questions',
                    style: AppTypography.typeCaption,
                  ),
                ],
              ),
            ),
            action,
          ],
        ),
      ),
    );
  }
}

/// A catalog paper that is not installed yet: Download starts the pipeline,
/// progress/failure are driven by the shared download controller.
class _DownloadCard extends StatelessWidget {
  const _DownloadCard({
    required this.availability,
    required this.downloadState,
    required this.onStart,
  });

  final PaperAvailability availability;
  final PaperDownloadState downloadState;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final paper = availability.paper;
    final isThis =
        downloadState.paper?.packVersionId == paper.packVersionId;

    final Widget action;
    if (isThis && downloadState.phase == PaperDownloadPhase.downloading) {
      action = _DownloadProgress(progress: downloadState.progress);
    } else if (isThis && downloadState.phase == PaperDownloadPhase.failed) {
      action = AppButton(label: 'Retry', onPressed: onStart);
    } else {
      // One download at a time: other rows' buttons wait for the active one.
      action = AppButton(
        label: 'Download',
        onPressed: downloadState.isDownloading ? null : onStart,
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: AppColors.colorBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.colorPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusSm),
            ),
            child: Center(
              child: Text(
                '${paper.year}',
                style: AppTypography.typeHeading3.copyWith(
                  color: AppColors.colorPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paper.title,
                  style: AppTypography.typeBody
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.spaceXs),
                Text(
                  '${paper.questionCount} questions',
                  style: AppTypography.typeCaption,
                ),
              ],
            ),
          ),
          action,
        ],
      ),
    );
  }
}

/// Inline replacement for the row's trailing button while bytes are flowing.
class _DownloadProgress extends StatelessWidget {
  const _DownloadProgress({required this.progress});

  /// `0.0`–`1.0`, or null when the total is unknown.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Downloading…', style: AppTypography.typeCaption),
          const SizedBox(height: AppSpacing.spaceXs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.radiusFull),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              color: AppColors.colorPrimary,
              backgroundColor: AppColors.colorBorder,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPapers extends StatelessWidget {
  const _NoPapers();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: AppIconSize.iconSizeXl,
              color: AppColors.colorTextSecondary,
            ),
            SizedBox(height: AppSpacing.spaceMd),
            Text(
              'No papers available',
              style: AppTypography.typeHeading3,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
