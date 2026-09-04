enum ResourceType { note, flashcard, mindmap }

class Resource {
  Resource({
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
  final ResourceType type;
  final String? title;
  final String content;
  final int orderIndex;
}
