// Local UI model — presentation layer only.
//
// Not a domain model. The real Flashcard Resource entity (belongs to a
// single Topic, one-to-many per Decision 011) is owned by the
// data/domain layers, aggregated across all Topics in a Chapter for
// this screen (same aggregation as Study Resources).
//
// TODO(integration): replace mock construction with a mapper from the
// domain Flashcard/Resource model. Widgets should not need to change.

class FlashcardUiModel {
  const FlashcardUiModel({
    required this.cardId,
    required this.front,
    required this.back,
  });

  final String cardId;
  final String front;
  final String back;
}
