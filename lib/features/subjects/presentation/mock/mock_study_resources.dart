// TEMPORARY MOCK DATA SOURCE.
//
// Stands in for the real repository/provider until Riverpod/Drift are
// wired up.
//
// TODO(integration): delete once a real provider supplies
// StudyResourceUiModel/PracticeUiModel instances derived from the
// Resource and Question repositories, aggregated per chapter.

import '../models/study_resource_ui_model.dart';

class MockStudyResources {
  MockStudyResources._();

  static List<StudyResourceUiModel> resourcesFor(String chapterId) {
    // 'p11-1' (Waves and Sound) demonstrates the "Mind Map not
    // available yet" state — an expected content gap, not an error.
    if (chapterId == 'p11-1') {
      return const [
        StudyResourceUiModel(type: StudyResourceType.notes, isAvailable: true),
        StudyResourceUiModel(
          type: StudyResourceType.flashcards,
          isAvailable: true,
          count: 8,
        ),
        StudyResourceUiModel(
            type: StudyResourceType.mindMap, isAvailable: false),
      ];
    }

    return const [
      StudyResourceUiModel(type: StudyResourceType.notes, isAvailable: true),
      StudyResourceUiModel(
        type: StudyResourceType.flashcards,
        isAvailable: true,
        count: 12,
      ),
      StudyResourceUiModel(type: StudyResourceType.mindMap, isAvailable: true),
    ];
  }

  static PracticeUiModel practiceFor(String chapterId) {
    return const PracticeUiModel(questionCount: 24);
  }
}
