import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../content/domain/models/exam.dart';
import '../../progress/domain/models/attempt.dart';
import '../../subjects/domain/models/subject.dart';

/// Everything the Home dashboard renders, derived from real Exam and
/// Attempt rows for the given stream. Never faked, never cached beyond the
/// provider lifetime — Attempt history is append-only (Decision 016).
final homeDashboardProvider =
    FutureProvider.autoDispose.family<HomeDashboard, int>(
  (ref, streamId) async {
    final subjects =
        await ref.watch(subjectRepositoryProvider).getByStreamId(streamId);
    final exams = await ref.watch(examRepositoryProvider).getAll();
    final attempts = await ref.watch(attemptRepositoryProvider).getAll();
    final subjectStats =
        await ref.watch(subjectStatsForStreamProvider(streamId).future);

    final subjectById = {for (final s in subjects) s.id: s};
    final subjectIds = subjectById.keys.toSet();
    final examById = {for (final e in exams) e.id: e};

    final streamExams =
        exams.where((e) => subjectIds.contains(e.subjectId)).toList();

    final questionsAnswered = attempts.map((a) => a.questionId).toSet().length;
    final papersStarted = attempts
        .map((a) => a.examId)
        .whereType<int>()
        .toSet()
        .length;
    final activeSubjects = attempts
        .map((a) => a.subjectId)
        .whereType<int>()
        .where(subjectIds.contains)
        .toSet()
        .length;

    return HomeDashboard(
      questionsAnswered: questionsAnswered,
      papersStarted: papersStarted,
      activeSubjects: activeSubjects,
      offlinePapers: streamExams.length,
      subjectStats: subjectStats,
      continueSession: _findContinueSession(
        attempts: attempts,
        examById: examById,
        subjectById: subjectById,
      ),
    );
  },
);

/// Picks the most recently attempted paper that is started but not
/// finished (0 < answered < total) — the paper "Continue" resumes.
ContinueSession? _findContinueSession({
  required List<Attempt> attempts,
  required Map<int, Exam> examById,
  required Map<int, Subject> subjectById,
}) {
  final attemptedByExam = <int, Set<int>>{};
  final lastTouchedByExam = <int, String>{};

  for (final attempt in attempts) {
    final examId = attempt.examId;
    if (examId == null) continue;
    attemptedByExam.putIfAbsent(examId, () => <int>{}).add(attempt.questionId);
    final previous = lastTouchedByExam[examId];
    if (previous == null || attempt.attemptedAt.compareTo(previous) > 0) {
      lastTouchedByExam[examId] = attempt.attemptedAt;
    }
  }

  ContinueSession? best;
  var bestTouchedAt = '';

  for (final entry in attemptedByExam.entries) {
    final exam = examById[entry.key];
    if (exam == null) continue;
    final subject = subjectById[exam.subjectId];
    if (subject == null) continue;

    final paperQuestionIds = exam.questionIds;
    final total = paperQuestionIds.length;
    if (total == 0) continue;

    final paperQuestionIdSet = paperQuestionIds.toSet();
    final attempted = entry.value.intersection(paperQuestionIdSet);
    final answered = attempted.length;
    if (answered == 0 || answered >= total) continue;

    final touchedAt = lastTouchedByExam[entry.key]!;
    if (touchedAt.compareTo(bestTouchedAt) <= 0) continue;
    bestTouchedAt = touchedAt;
    best = ContinueSession(
      exam: exam,
      subject: subject,
      answeredQuestionIds: attempted,
    );
  }

  return best;
}

/// Aggregated Home dashboard numbers.
class HomeDashboard {
  const HomeDashboard({
    required this.questionsAnswered,
    required this.papersStarted,
    required this.activeSubjects,
    required this.offlinePapers,
    required this.subjectStats,
    required this.continueSession,
  });

  /// Distinct questions answered across the whole attempt history.
  final int questionsAnswered;

  /// Distinct papers that have at least one answer recorded.
  final int papersStarted;

  /// Distinct subjects in this stream that have at least one answer.
  final int activeSubjects;

  /// Papers imported for this stream — all of them live on-device
  /// (offline-first), so this is the "ready offline" count.
  final int offlinePapers;

  /// Per-subject real counts, keyed by subject id.
  final Map<int, SubjectStats> subjectStats;

  /// The partially-finished paper to resume, or `null` when nothing is
  /// mid-flight.
  final ContinueSession? continueSession;
}

/// A paper that has been started but not finished.
class ContinueSession {
  const ContinueSession({
    required this.exam,
    required this.subject,
    required this.answeredQuestionIds,
  });

  final Exam exam;
  final Subject subject;

  /// Subset of the paper's question ids already answered.
  final Set<int> answeredQuestionIds;

  /// Every question id of the paper, in paper order.
  List<int> get questionIds => exam.questionIds;

  String get subjectName => subject.title;

  String get subjectSlug => subject.slug;

  int get subjectId => subject.id;

  int get examId => exam.id;

  int get examYearEc => exam.examYearEc;

  int get totalQuestions => questionIds.length;

  int get answeredCount => answeredQuestionIds.length;

  /// 1-based number of the first unanswered question.
  int get nextQuestionNumber => answeredCount + 1;

  double get progress =>
      totalQuestions == 0 ? 0 : answeredCount / totalQuestions;

  int get percent => (progress * 100).round();

  /// Paper-order slice still unanswered — what "Continue" opens.
  List<int> get remainingQuestionIds => questionIds
      .where((id) => !answeredQuestionIds.contains(id))
      .toList(growable: false);
}
