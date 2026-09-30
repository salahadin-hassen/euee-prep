import '../models/exam.dart';

abstract interface class ExamRepository {
  Future<Exam> insert(Exam exam);

  Future<List<Exam>> getAll();

  Future<List<Exam>> getBySubjectId(int subjectId);

  Future<List<int>> getQuestionIdsByExamId(int examId);
}
