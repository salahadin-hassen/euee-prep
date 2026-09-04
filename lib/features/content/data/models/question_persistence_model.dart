class QuestionPersistenceModel {
  QuestionPersistenceModel({
    required this.id,
    required this.sourcePackId,
    required this.packLocalId,
    required this.prompt,
    required this.choicesJson,
    required this.correctChoiceIndex,
    required List<int> topicIds,
    this.explanation,
    this.textbookReference,
    this.examYearEc,
    this.imageReference,
    this.graphReference,
    this.diagramReference,
    this.tableReference,
  }) : topicIds = List.unmodifiable(topicIds);

  final int id;
  final String sourcePackId;
  final String packLocalId;
  final String prompt;
  final String choicesJson;
  final int correctChoiceIndex;
  final List<int> topicIds;
  final String? explanation;
  final String? textbookReference;
  final int? examYearEc;
  final String? imageReference;
  final String? graphReference;
  final String? diagramReference;
  final String? tableReference;
}
