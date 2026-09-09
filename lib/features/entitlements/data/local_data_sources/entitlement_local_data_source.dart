import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/entitlement_persistence_model.dart';

class EntitlementLocalDataSource {
  EntitlementLocalDataSource(this._database);

  final AppDatabase _database;

  Future<void> deleteByInstallId(String installId) async {
    await (_database.delete(_database.entitlements)
          ..where((e) => e.installId.equals(installId)))
        .go();
  }

  Future<void> insertAll(List<EntitlementPersistenceModel> entitlements) async {
    await _database.batch((batch) {
      batch.insertAll(
        _database.entitlements,
        entitlements
            .map((e) => EntitlementsCompanion.insert(
                  installId: e.installId,
                  streamId: e.streamId,
                  status: e.status,
                  grantedAt: e.grantedAt,
                  revokedAt: Value(e.revokedAt),
                  sourcePaymentRequestId: Value(e.sourcePaymentRequestId),
                ))
            .toList(),
      );
    });
  }

  Future<List<EntitlementPersistenceModel>> getByInstallId(
    String installId,
  ) async {
    final rows = await (_database.select(_database.entitlements)
          ..where((e) => e.installId.equals(installId))
          ..orderBy([(e) => OrderingTerm(expression: e.id)]))
        .get();
    return rows.map(_mapRow).toList();
  }

  Future<EntitlementPersistenceModel?> getActiveByInstallIdAndStreamId(
    String installId,
    int streamId,
  ) async {
    final row = await (_database.select(_database.entitlements)
          ..where((e) =>
              e.installId.equals(installId) &
              e.streamId.equals(streamId) &
              e.status.equals('active'))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return _mapRow(row);
  }

  EntitlementPersistenceModel _mapRow(Entitlement row) {
    return EntitlementPersistenceModel(
      id: row.id,
      installId: row.installId,
      streamId: row.streamId,
      status: row.status,
      grantedAt: row.grantedAt,
      revokedAt: row.revokedAt,
      sourcePaymentRequestId: row.sourcePaymentRequestId,
    );
  }
}
