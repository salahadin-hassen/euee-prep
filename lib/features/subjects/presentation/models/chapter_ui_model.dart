// Local UI models — presentation layer only.
//
// Not domain models. The real Chapter/Grade entities (Decision 010) and
// completion status (derived from Attempt history via a Service-layer
// calculation, Decision 016 — never stored) are owned by the
// data/domain/service layers.
//
// TODO(integration): replace mock construction with a mapper from the
// domain Chapter model + a Service-layer per-chapter completion rollup.
// Widgets should not need to change.

/// Chapter completion status.
///
/// Modeled as 3 states per the Subject Detail design review — flagged
/// there as an open question pending confirmation of whether the real
/// data model distinguishes "in progress" from "not started". If it
/// turns out completion is binary, this collapses to 2 states with no
/// widget changes needed beyond this enum and ChapterRow's icon mapping.
enum ChapterStatus { notStarted, inProgress, completed }

class ChapterUiModel {
  const ChapterUiModel({
    required this.chapterId,
    required this.title,
    required this.status,
  });

  final String chapterId;
  final String title;
  final ChapterStatus status;
}

class GradeSectionUiModel {
  const GradeSectionUiModel({
    required this.grade,
    required this.chapters,
  });

  final int grade; // 9, 10, 11, 12
  final List<ChapterUiModel> chapters;
}
