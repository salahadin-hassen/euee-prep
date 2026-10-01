/// A single problem found while importing a content pack.
///
/// [code] classifies the problem so callers (e.g. the paper download
/// pipeline) can map failures onto their own error states without parsing
/// human-readable messages.
class ContentImportIssue {
  const ContentImportIssue(this.message, {this.code = ContentImportIssueCode.validation});

  final String message;

  final ContentImportIssueCode code;

  @override
  String toString() => message;
}

/// Machine-readable classification of a [ContentImportIssue].
enum ContentImportIssueCode {
  /// The pack file was not valid JSON.
  malformedJson,

  /// The pack parsed but violated the v3 schema/value rules.
  validation,

  /// The pack's FNV-1a checksum did not match its contents.
  checksumMismatch,

  /// The pack requires a newer app version than the running one.
  incompatibleAppVersion,

  /// The database rejected the import (rolled back atomically).
  importFailed,
}
