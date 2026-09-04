import '../models/stream_model.dart';

abstract interface class StreamRepository {
  Future<StreamModel> insert(StreamModel stream);

  Future<List<StreamModel>> getAll();

  Future<StreamModel?> getBySlug(String slug);
}
