import '../../domain/models/payment_request.dart';
import '../../domain/repositories/payment_request_repository.dart';
import '../local_data_sources/payment_request_local_data_source.dart';
import '../models/payment_request_persistence_model.dart';

class PaymentRequestRepositoryImpl implements PaymentRequestRepository {
  PaymentRequestRepositoryImpl(this._localDataSource);

  final PaymentRequestLocalDataSource _localDataSource;

  @override
  Future<List<PaymentRequest>> getByInstallId(String installId) async {
    final models = await _localDataSource.getByInstallId(installId);
    return models.map(_toDomain).toList();
  }

  @override
  Future<PaymentRequest?> getByRequestId(String requestId) async {
    final model = await _localDataSource.getByRequestId(requestId);
    if (model == null) return null;
    return _toDomain(model);
  }

  @override
  Future<void> syncFromServer(
    String installId,
    List<PaymentRequest> requests,
  ) async {
    await _localDataSource.deleteByInstallId(installId);
    if (requests.isNotEmpty) {
      await _localDataSource.insertAll(requests.map(_toPersistence).toList());
    }
  }

  PaymentRequest _toDomain(PaymentRequestPersistenceModel model) {
    return PaymentRequest(
      requestId: model.requestId,
      installId: model.installId,
      streamId: model.streamId,
      proofType: ProofType.values.firstWhere((e) => e.name == model.proofType),
      proofValue: model.proofValue,
      status:
          PaymentRequestStatus.values.firstWhere((e) => e.name == model.status),
      submittedAt: model.submittedAt,
      rejectionReason: model.rejectionReason,
      verifiedAt: model.verifiedAt,
    );
  }

  PaymentRequestPersistenceModel _toPersistence(PaymentRequest request) {
    return PaymentRequestPersistenceModel(
      requestId: request.requestId,
      installId: request.installId,
      streamId: request.streamId,
      proofType: request.proofType.name,
      proofValue: request.proofValue,
      status: request.status.name,
      submittedAt: request.submittedAt,
      rejectionReason: request.rejectionReason,
      verifiedAt: request.verifiedAt,
    );
  }
}
