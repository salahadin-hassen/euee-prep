class Topic {
  const Topic({
    required this.id,
    required this.chapterId,
    required this.sourcePackId,
    required this.packLocalId,
    required this.title,
    required this.orderIndex,
  });

  final int id;
  final int chapterId;
  final String sourcePackId;
  final String packLocalId;
  final String title;
  final int orderIndex;
}
