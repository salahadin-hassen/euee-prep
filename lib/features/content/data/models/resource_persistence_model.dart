class ResourcePersistenceModel {
  ResourcePersistenceModel({
    required this.id,
    required this.topicId,
    required this.sourcePackId,
    required this.packLocalId,
    required this.type,
    required this.content,
    required this.orderIndex,
    this.title,
  });

  final int id;
  final int topicId;
  final String sourcePackId;
  final String packLocalId;
  final String type;
  final String? title;
  final String content;
  final int orderIndex;
}
