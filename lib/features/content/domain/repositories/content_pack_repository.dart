import '../models/content_pack.dart';

abstract interface class ContentPackRepository {
  Future<ContentPack> insert(ContentPack pack);

  Future<List<ContentPack>> getAll();

  Future<ContentPack?> getLatestForPackKey(String packKey);

  Future<ContentPack?> getById(String id);

  /// The newest locally installed version of the paper identified by
  /// [packId] (the v3 file-level `pack_id`, e.g.
  /// `biology-2018-natural_science`), or `null` when no version is
  /// installed.
  ///
  /// Versions are compared with the shared semver rules, so callers can ask
  /// "which version is installed?" for a specific paper regardless of
  /// subject-level `packKey` grouping.
  Future<ContentPack?> getLatestForPackId(String packId);
}
