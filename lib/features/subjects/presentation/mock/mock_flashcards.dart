// TEMPORARY MOCK DATA SOURCE.
//
// Stands in for the real repository/provider until Riverpod/Drift are
// wired up.
//
// TODO(integration): delete once a real provider supplies
// FlashcardUiModel instances derived from Resource records scoped to
// this chapter's Topics.

import '../models/flashcard_ui_model.dart';

class MockFlashcards {
  MockFlashcards._();

  static List<FlashcardUiModel> forChapter(String chapterId) {
    if (chapterId == 'p11-1') {
      return const [
        FlashcardUiModel(
          cardId: 'c1',
          front: 'What is the speed of sound in air at 20°C?',
          back: '~343 m/s',
        ),
        FlashcardUiModel(
          cardId: 'c2',
          front: 'What is the relationship between frequency and wavelength?',
          back: 'v = f × λ  (speed = frequency × wavelength)',
        ),
      ];
    }

    return const [
      FlashcardUiModel(
        cardId: 'c1',
        front: 'What is the SI unit of Work?',
        back: 'Joule (J)\n1 J = 1 N·m',
      ),
      FlashcardUiModel(
        cardId: 'c2',
        front: 'State the Work-Energy Theorem.',
        back: 'The net work done on an object equals its change in '
            'kinetic energy.',
      ),
      FlashcardUiModel(
        cardId: 'c3',
        front: 'What is the formula for kinetic energy?',
        back: 'KE = ½mv²',
      ),
      FlashcardUiModel(
        cardId: 'c4',
        front: 'What is the SI unit of Power?',
        back: 'Watt (W)\n1 W = 1 J/s',
      ),
    ];
  }
}
