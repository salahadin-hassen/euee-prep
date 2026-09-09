import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/install_identity_persistence_model.dart';

class InstallIdentityLocalDataSource {
  InstallIdentityLocalDataSource(this._database);

  final AppDatabase _database;

  /// Insert the singleton install identity row. Fails if the row already exists.
  Future<void> insert(InstallIdentityPersistenceModel identity) async {
    await _database.into(_database.installIdentities).insert(
          InstallIdentitiesCompanion.insert(
            id: Value(identity.id),
            installId: identity.installId,
            createdAt: identity.createdAt,
          ),
        );
  }

  /// Return the singleton row, or `null` if none exists yet.
  Future<InstallIdentityPersistenceModel?> get() async {
    final row =
        await _database.select(_database.installIdentities).getSingleOrNull();
    if (row == null) return null;
    return _mapRow(row);
  }

  InstallIdentityPersistenceModel _mapRow(InstallIdentity row) {
    return InstallIdentityPersistenceModel(
      id: row.id,
      installId: row.installId,
      createdAt: row.createdAt,
    );
  }
}
