import 'dart:math';

import '../../domain/models/install_identity.dart';
import '../../domain/repositories/install_identity_repository.dart';
import '../local_data_sources/install_identity_local_data_source.dart';
import '../models/install_identity_persistence_model.dart';

class InstallIdentityRepositoryImpl implements InstallIdentityRepository {
  InstallIdentityRepositoryImpl(this._localDataSource);

  final InstallIdentityLocalDataSource _localDataSource;

  static const _singletonRowId = 1;

  @override
  Future<InstallIdentity> ensureCreated() async {
    final existing = await _localDataSource.get();
    if (existing != null) return _toDomain(existing);

    final now = DateTime.now().toUtc().toIso8601String();
    final installId = _generateUuidV4();
    await _localDataSource.insert(
      InstallIdentityPersistenceModel(
        id: _singletonRowId,
        installId: installId,
        createdAt: now,
      ),
    );
    return _toDomain(
      InstallIdentityPersistenceModel(
        id: _singletonRowId,
        installId: installId,
        createdAt: now,
      ),
    );
  }

  @override
  Future<InstallIdentity?> get() async {
    final model = await _localDataSource.get();
    if (model == null) return null;
    return _toDomain(model);
  }

  InstallIdentity _toDomain(InstallIdentityPersistenceModel model) {
    return InstallIdentity(
      installId: model.installId,
      createdAt: model.createdAt,
    );
  }

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .replaceAllMapped(
          RegExp(r'(.{8})(.{4})(.{4})(.{4})(.{12})'),
          (m) => '${m[1]}-${m[2]}-${m[3]}-${m[4]}-${m[5]}',
        );
  }
}
