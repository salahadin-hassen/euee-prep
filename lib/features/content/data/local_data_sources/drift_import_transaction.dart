import '../../../../core/database/app_database.dart';
import '../../domain/services/content_import_transaction.dart';

/// Runs an import body inside a single Drift transaction.
///
/// Repositories and their Local Data Sources share this [AppDatabase], and
/// Drift routes their writes into the active transaction, so every insert the
/// import performs commits or rolls back together (Decision 021).
class DriftImportTransaction implements ContentImportTransaction {
  DriftImportTransaction(this._database);

  final AppDatabase _database;

  @override
  Future<T> run<T>(Future<T> Function() body) {
    return _database.transaction(() => body());
  }
}
