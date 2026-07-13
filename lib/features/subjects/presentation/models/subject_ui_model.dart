// Local UI model — presentation layer only.
//
// Not the domain model. The real Subject entity (Decision 009/010) and
// its per-stream ownership, grade/chapter relationships, and Attempt-
// derived progress calculation (Decision 016 — always recalculated,
// never stored) are owned by the data/domain/service layers.
//
// TODO(integration): replace SubjectUiModel.fromMock(...) call sites
// with a mapper from the domain Subject model + a Service-layer
// progress calculation once those exist. Widgets should not need to
// change.

class SubjectUiModel {
  const SubjectUiModel({
    required this.subjectId,
    required this.name,
    required this.iconGlyph,
    required this.chapterCount,
    required this.isEntitled,
    this.progress,
  });

  final String subjectId;
  final String name;

  /// Simple decorative glyph (emoji stand-in) until real iconography
  /// is designed — flagged, not a final asset decision.
  final String iconGlyph;

  final int chapterCount;
  final bool isEntitled;

  /// 0.0–1.0. Null when not entitled (progress has no meaning for a
  /// subject the student can't open yet) or when the student hasn't
  /// attempted anything.
  final double? progress;
}
