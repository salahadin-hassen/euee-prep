import '../../domain/models/entitlement.dart';
import '../../domain/repositories/entitlement_repository.dart';
import '../local_data_sources/entitlement_local_data_source.dart';
import '../models/entitlement_persistence_model.dart';

class EntitlementRepositoryImpl implements EntitlementRepository {
  EntitlementRepositoryImpl(this._localDataSource);

  final EntitlementLocalDataSource _localDataSource;

  @override
  Future<List<Entitlement>> getByInstallId(String installId) async {
    final models = await _localDataSource.getByInstallId(installId);
    return models.map(_toDomain).toList();
  }

  @override
  Future<Entitlement?> getActiveByInstallIdAndStreamId(
    String installId,
    int streamId,
  ) async {
    final model = await _localDataSource.getActiveByInstallIdAndStreamId(
      installId,
      streamId,
    );
    if (model == null) return null;
    return _toDomain(model);
  }

  @override
  Future<void> syncFromServer(
    String installId,
    List<Entitlement> entitlements,
  ) async {
    await _localDataSource.deleteByInstallId(installId);
    if (entitlements.isNotEmpty) {
      await _localDataSource.insertAll(
        entitlements.map(_toPersistence).toList(),
      );
    }
  }

  Entitlement _toDomain(EntitlementPersistenceModel model) {
    return Entitlement(
      id: model.id,
      installId: model.installId,
      streamId: model.streamId,
      status: EntitlementStatus.values.firstWhere(
        (e) => e.name == model.status,
      ),
      grantedAt: model.grantedAt,
      revokedAt: model.revokedAt,
      sourcePaymentRequestId: model.sourcePaymentRequestId,
    );
  }

  EntitlementPersistenceModel _toPersistence(Entitlement entitlement) {
    return EntitlementPersistenceModel(
      id: entitlement.id,
      installId: entitlement.installId,
      streamId: entitlement.streamId,
      status: entitlement.status.name,
      grantedAt: entitlement.grantedAt,
      revokedAt: entitlement.revokedAt,
      sourcePaymentRequestId: entitlement.sourcePaymentRequestId,
    );
  }
}
