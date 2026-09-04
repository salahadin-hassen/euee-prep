class SubjectPersistenceModel {
  const SubjectPersistenceModel({
    required this.id,
    required this.streamId,
    required this.slug,
    required this.title,
  });

  final int id;
  final int streamId;
  final String slug;
  final String title;
}
