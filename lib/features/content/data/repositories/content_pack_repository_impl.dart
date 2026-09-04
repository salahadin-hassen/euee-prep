import '../../domain/models/content_pack.dart';
import '../../domain/repositories/content_pack_repository.dart';
import '../local_data_sources/content_pack_local_data_source.dart';
import '../models/content_pack_persistence_model.dart';

class ContentPackRepositoryImpl implements ContentPackRepository {
  ContentPackRepositoryImpl(this._localDataSource);

  final ContentPackLocalDataSource _localDataSource;

  @override
  Future<ContentPack> insert(ContentPack pack) async {
    final model = await _localDataSource.insert(_toPersistence(pack));
    return _toDomain(model);
  }

  @override
  Future<List<ContentPack>> getAll() async {
    final models = await _localDataSource.getAll();
    return models.map(_toDomain).toList();
  }

  @override
  Future<ContentPack?> getLatestForPackKey(String packKey) async {
    final model = await _localDataSource.getLatestForPackKey(packKey);
    return model == null ? null : _toDomain(model);
  }

  ContentPackPersistenceModel _toPersistence(ContentPack pack) {
    return ContentPackPersistenceModel(
      id: pack.id,
      packKey: pack.packKey,
      subjectId: pack.subjectId,
      packVersion: pack.packVersion,
      schemaVersion: pack.schemaVersion,
      generatedAt: pack.generatedAt,
      checksum: pack.checksum,
      minimumAppVersion: pack.minimumAppVersion,
      importedAt: pack.importedAt,
    );
  }

  ContentPack _toDomain(ContentPackPersistenceModel pack) {
    return ContentPack(
      id: pack.id,
      packKey: pack.packKey,
      subjectId: pack.subjectId,
      packVersion: pack.packVersion,
      schemaVersion: pack.schemaVersion,
      generatedAt: pack.generatedAt,
      checksum: pack.checksum,
      minimumAppVersion: pack.minimumAppVersion,
      importedAt: pack.importedAt,
    );
  }
}
