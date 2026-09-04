import '../../domain/models/question.dart';
import '../../domain/repositories/question_repository.dart';
import '../local_data_sources/question_local_data_source.dart';
import '../models/question_persistence_model.dart';

class QuestionRepositoryImpl implements QuestionRepository {
  QuestionRepositoryImpl(this._localDataSource);

  final QuestionLocalDataSource _localDataSource;

  @override
  Future<Question> insert(Question question) async {
    final model = await _localDataSource.insert(_toPersistence(question));
    return _toDomain(model);
  }

  @override
  Future<List<Question>> getAll() async {
    final models = await _localDataSource.getAll();
    return models.map(_toDomain).toList();
  }

  QuestionPersistenceModel _toPersistence(Question question) {
    return QuestionPersistenceModel(
      id: question.id,
      sourcePackId: question.sourcePackId,
      packLocalId: question.packLocalId,
      prompt: question.prompt,
      choicesJson: question.choicesJson,
      correctChoiceIndex: question.correctChoiceIndex,
      topicIds: question.topicIds,
      explanation: question.explanation,
      textbookReference: question.textbookReference,
      examYearEc: question.examYearEc,
      imageReference: question.imageReference,
      graphReference: question.graphReference,
      diagramReference: question.diagramReference,
      tableReference: question.tableReference,
    );
  }

  Question _toDomain(QuestionPersistenceModel question) {
    return Question(
      id: question.id,
      sourcePackId: question.sourcePackId,
      packLocalId: question.packLocalId,
      prompt: question.prompt,
      choicesJson: question.choicesJson,
      correctChoiceIndex: question.correctChoiceIndex,
      topicIds: List.unmodifiable(question.topicIds),
      explanation: question.explanation,
      textbookReference: question.textbookReference,
      examYearEc: question.examYearEc,
      imageReference: question.imageReference,
      graphReference: question.graphReference,
      diagramReference: question.diagramReference,
      tableReference: question.tableReference,
    );
  }
}
