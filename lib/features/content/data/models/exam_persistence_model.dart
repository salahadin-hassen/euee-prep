class ExamPersistenceModel {
  ExamPersistenceModel({
    required this.id,
    required this.sourcePackId,
    required this.packLocalId,
    required this.subjectId,
    required this.examYearEc,
    required List<int> questionIds,
    this.title,
    this.durationSeconds,
  }) : questionIds = List.unmodifiable(questionIds);

  final int id;
  final String sourcePackId;
  final String packLocalId;
  final int subjectId;
  final int examYearEc;
  final List<int> questionIds;
  final String? title;
  final int? durationSeconds;
}
