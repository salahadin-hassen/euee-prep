import '../models/grade.dart';

abstract interface class GradeRepository {
  Future<Grade> insert(Grade grade);

  Future<List<Grade>> getAll();

  Future<Grade?> getByLevel(int level);
}
