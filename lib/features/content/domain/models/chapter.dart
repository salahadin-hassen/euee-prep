class Chapter {
  const Chapter({
    required this.id,
    required this.subjectId,
    required this.gradeId,
    required this.sourcePackId,
    required this.packLocalId,
    required this.title,
    required this.orderIndex,
  });

  final int id;
  final int subjectId;
  final int gradeId;
  final String sourcePackId;
  final String packLocalId;
  final String title;
  final int orderIndex;
}
