/// An immutable record of a single answer submission.
///
/// Attempts are append-only (Decision 016) — no update or delete path exists
/// anywhere in the app. Derived statistics are recalculated from Attempt
/// history on every read, never cached.
class Attempt {
  const Attempt({
    required this.id,
    required this.questionId,
    required this.selectedChoiceIndex,
    required this.isCorrect,
    required this.attemptedAt,
    this.mode,
    this.durationSeconds,
    this.subjectId,
    this.chapterId,
    this.examId,
  });

  final int id;
  final int questionId;
  final int selectedChoiceIndex;
  final bool isCorrect;
  final String attemptedAt;
  final String? mode;
  final int? durationSeconds;
  final int? subjectId;
  final int? chapterId;
  final int? examId;
}
