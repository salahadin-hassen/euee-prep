// Local UI model — presentation layer only.
//
// Not a domain model. Real Resource entities (Notes/Flashcards/Mind
// Maps, Decision 011's one-to-many-under-Topic scope) and Question
// counts (via the Question-Topic many-to-many join, Decision 011) are
// owned by the data/domain/service layers, aggregated up to the
// Chapter level for this screen.
//
// TODO(integration): replace mock construction with a mapper that
// aggregates Resource records across all Topics in a Chapter, and a
// Question count via the Chapter→Topic→Question join. Widgets should
// not need to change.

enum StudyResourceType { notes, flashcards, mindMap }

class StudyResourceUiModel {
  const StudyResourceUiModel({
    required this.type,
    required this.isAvailable,
    this.count,
  });

  final StudyResourceType type;

  /// False when the content pack simply doesn't include this resource
  /// type for this chapter yet — an expected content state (Decision
  /// 015/021), not an error.
  final bool isAvailable;

  /// Only meaningful for flashcards at MVP (per the design review —
  /// Notes/Mind Map aren't unit-countable in a way that helps the
  /// student decide).
  final int? count;
}

class PracticeUiModel {
  const PracticeUiModel({required this.questionCount});

  final int questionCount;
}
