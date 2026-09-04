import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/content_pack_persistence_model.dart';

class ContentPackLocalDataSource {
  ContentPackLocalDataSource(this._database);

  final AppDatabase _database;

  Future<ContentPackPersistenceModel> insert(
    ContentPackPersistenceModel pack,
  ) async {
    await _database.into(_database.contentPacks).insert(
          ContentPacksCompanion.insert(
            id: pack.id,
            packKey: pack.packKey,
            subjectId: pack.subjectId,
            packVersion: pack.packVersion,
            schemaVersion: pack.schemaVersion,
            generatedAt: pack.generatedAt,
            checksum: pack.checksum,
            minimumAppVersion: pack.minimumAppVersion,
            importedAt: pack.importedAt,
          ),
        );
    return pack;
  }

  Future<List<ContentPackPersistenceModel>> getAll() async {
    final rows = await _database.select(_database.contentPacks).get();
    return rows.map(_mapRow).toList();
  }

  Future<ContentPackPersistenceModel?> getLatestForPackKey(
    String packKey,
  ) async {
    final row = await (_database.select(_database.contentPacks)
          ..where((pack) => pack.packKey.equals(packKey))
          ..orderBy([
            (pack) => OrderingTerm(
                  expression: pack.importedAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  Future<ContentPackPersistenceModel?> getById(String id) async {
    final row = await (_database.select(_database.contentPacks)
          ..where((pack) => pack.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  ContentPackPersistenceModel _mapRow(ContentPack row) {
    return ContentPackPersistenceModel(
      id: row.id,
      packKey: row.packKey,
      subjectId: row.subjectId,
      packVersion: row.packVersion,
      schemaVersion: row.schemaVersion,
      generatedAt: row.generatedAt,
      checksum: row.checksum,
      minimumAppVersion: row.minimumAppVersion,
      importedAt: row.importedAt,
    );
  }
}
