import '../models/subject.dart';

abstract interface class SubjectRepository {
  Future<Subject> insert(Subject subject);

  Future<List<Subject>> getAll();

  Future<Subject?> getByStreamAndSlug(int streamId, String slug);
}
