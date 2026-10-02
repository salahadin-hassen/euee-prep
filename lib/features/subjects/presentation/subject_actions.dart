import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../content/domain/models/exam.dart';
import '../../entitlements/presentation/payment_submission_flow.dart';
import '../../practice/presentation/models/practice_models.dart';
import '../../practice/presentation/practice_screen.dart';
import '../../subjects/domain/models/subject.dart';
import 'subject_detail_screen.dart';

/// Opens a subject row's destination: the Subject screen when the row is
/// reachable, the payment submission flow when it is not (Decision
/// 012/013).
///
/// Shared by the Subjects list and the Home subject preview so both
/// screens resolve access identically. [hasAccess] is the row's own
/// answer — entitled stream, or a free-sample row while it is locked
/// (see [AccessPolicy]) — not the stream-level entitlement flag.
Future<void> openSubject(
  BuildContext context,
  WidgetRef ref, {
  required Subject subject,
  required bool hasAccess,
  required int streamId,
}) async {
  if (hasAccess) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubjectDetailScreen(
          subjectId: subject.id,
          subjectName: subject.title,
        ),
      ),
    );
    return;
  }

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

/// Starts a practice session over [exam], restricted to [onlyQuestionIds]
/// when the caller is resuming a partially-answered paper.
///
/// Questions are presented in paper order. Answers are recorded as normal
/// append-only Attempts (Decision 016) — nothing is mutated.
Future<void> openPaperPractice(
  BuildContext context,
  WidgetRef ref, {
  required Exam exam,
  required String subjectName,
  List<int>? onlyQuestionIds,
}) async {
  final orderedIds = onlyQuestionIds ?? exam.questionIds;
  if (orderedIds.isEmpty) return;

  final questions =
      await ref.read(questionRepositoryProvider).getByIds(orderedIds);
  if (!context.mounted) return;

  final indexById = <int, int>{
    for (var i = 0; i < orderedIds.length; i++) orderedIds[i]: i,
  };
  final sorted = List.of(questions)
    ..sort((a, b) => (indexById[a.id] ?? 0).compareTo(indexById[b.id] ?? 0));

  final uiModels = sorted
      .map(
        (q) => QuestionUiModel(
          dbQuestionId: q.id,
          questionId: q.packLocalId,
          topicIds: const [],
          prompt: q.prompt,
          options: decodeChoicesJson(q.choicesJson),
          correctIndex: q.correctChoiceIndex,
          explanation: q.explanation ?? '',
          textbookReference: q.textbookReference,
        ),
      )
      .toList(growable: false);

  if (uiModels.isEmpty) return;
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
