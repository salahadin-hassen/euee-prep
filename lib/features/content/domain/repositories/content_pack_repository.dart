import '../models/content_pack.dart';

abstract interface class ContentPackRepository {
  Future<ContentPack> insert(ContentPack pack);

  Future<List<ContentPack>> getAll();

  Future<ContentPack?> getLatestForPackKey(String packKey);
}
