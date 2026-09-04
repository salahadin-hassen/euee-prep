class ContentPack {
  const ContentPack({
    required this.id,
    required this.packKey,
    required this.subjectId,
    required this.packVersion,
    required this.schemaVersion,
    required this.generatedAt,
    required this.checksum,
    required this.minimumAppVersion,
    required this.importedAt,
  });

  final String id;
  final String packKey;
  final int subjectId;
  final String packVersion;
  final String schemaVersion;
  final String generatedAt;
  final String checksum;
  final String minimumAppVersion;
  final String importedAt;
}
