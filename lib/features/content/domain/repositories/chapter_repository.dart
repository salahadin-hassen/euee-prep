import '../models/chapter.dart';

abstract interface class ChapterRepository {
  Future<Chapter> insert(Chapter chapter);

  Future<List<Chapter>> getAll();
}
