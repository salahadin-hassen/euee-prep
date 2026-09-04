/// A single reason a content-pack import was rejected.
///
/// Validation failures are expected states (not exceptions), so the importer
/// returns them as data in a `ContentImportResult` (see `docs/coding-standards.md`
/// — avoid throwing for expected failure cases).
class ContentImportIssue {
  const ContentImportIssue(this.message);

  final String message;

  @override
  String toString() => message;
}
