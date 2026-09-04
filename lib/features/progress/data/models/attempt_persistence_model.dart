/// Persistence-layer representation of an Attempt row.
///
/// Never leaves the data layer — the repository converts this to a domain
/// [Attempt] before returning upward.
class AttemptPersistenceModel {
  const AttemptPersistenceModel({
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
