import '../../domain/models/stream_model.dart';
import '../../domain/repositories/stream_repository.dart';
import '../local_data_sources/stream_local_data_source.dart';
import '../models/stream_persistence_model.dart';

class StreamRepositoryImpl implements StreamRepository {
  StreamRepositoryImpl(this._localDataSource);

  final StreamLocalDataSource _localDataSource;

  @override
  Future<StreamModel> insert(StreamModel stream) async {
    final model = await _localDataSource.insert(
      StreamPersistenceModel(id: stream.id, slug: stream.slug),
    );
    return StreamModel(id: model.id, slug: model.slug);
  }

  @override
  Future<List<StreamModel>> getAll() async {
    final models = await _localDataSource.getAll();
    return models
        .map((model) => StreamModel(id: model.id, slug: model.slug))
        .toList();
  }

  @override
  Future<StreamModel?> getBySlug(String slug) async {
    final model = await _localDataSource.getBySlug(slug);
    return model == null ? null : StreamModel(id: model.id, slug: model.slug);
  }
}
