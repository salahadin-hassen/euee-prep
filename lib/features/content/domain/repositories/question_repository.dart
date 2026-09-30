import '../models/question.dart';

abstract interface class QuestionRepository {
  Future<Question> insert(Question question);

  Future<List<Question>> getAll();

  Future<List<Question>> getByIds(List<int> ids);
}
