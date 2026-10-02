class SubjectUiModel {
  const SubjectUiModel({
    required this.subjectId,
    required this.name,
    required this.iconGlyph,
    required this.paperCount,
    required this.questionCount,
    required this.isOpen,
    this.progress,
  });

  final String subjectId;
  final String name;

  /// Simple decorative glyph (emoji stand-in) until real iconography
  /// is designed — flagged, not a final asset decision.
  final String iconGlyph;

  final int paperCount;
  final int questionCount;

  /// Whether this row can be opened right now — the row's own answer from
  /// `AccessPolicy`, not the stream-level entitlement flag.
  final bool isOpen;

  /// 0.0–1.0. Null when the row is closed (progress has no meaning for a
  /// subject the student can't open yet) or when the student hasn't
  /// attempted anything.
  final double? progress;
}
