import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/payment_request_persistence_model.dart';

class PaymentRequestLocalDataSource {
  PaymentRequestLocalDataSource(this._database);

  final AppDatabase _database;

  Future<void> deleteByInstallId(String installId) async {
    await (_database.delete(_database.paymentRequests)
          ..where((e) => e.installId.equals(installId)))
        .go();
  }

  Future<void> insertAll(List<PaymentRequestPersistenceModel> requests) async {
    await _database.batch((batch) {
      batch.insertAll(
        _database.paymentRequests,
        requests
            .map((r) => PaymentRequestsCompanion.insert(
                  requestId: r.requestId,
                  installId: r.installId,
                  streamId: r.streamId,
                  proofType: r.proofType,
                  proofValue: r.proofValue,
                  status: r.status,
                  submittedAt: r.submittedAt,
                  rejectionReason: Value(r.rejectionReason),
                  verifiedAt: Value(r.verifiedAt),
                ))
            .toList(),
      );
    });
  }

  Future<List<PaymentRequestPersistenceModel>> getByInstallId(
    String installId,
  ) async {
    final rows = await (_database.select(_database.paymentRequests)
          ..where((e) => e.installId.equals(installId))
          ..orderBy([(e) => OrderingTerm(expression: e.submittedAt)]))
        .get();
    return rows.map(_mapRow).toList();
  }

  Future<PaymentRequestPersistenceModel?> getByRequestId(
    String requestId,
  ) async {
    final row = await (_database.select(_database.paymentRequests)
          ..where((e) => e.requestId.equals(requestId))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return _mapRow(row);
  }

  PaymentRequestPersistenceModel _mapRow(PaymentRequest row) {
    return PaymentRequestPersistenceModel(
      requestId: row.requestId,
      installId: row.installId,
      streamId: row.streamId,
      proofType: row.proofType,
      proofValue: row.proofValue,
      status: row.status,
      submittedAt: row.submittedAt,
      rejectionReason: row.rejectionReason,
      verifiedAt: row.verifiedAt,
    );
  }
}
