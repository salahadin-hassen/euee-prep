// TEMPORARY MOCK DATA SOURCE.
//
// Stands in for the real repository/provider until Riverpod/Drift are
// wired up.

import '../models/subject_ui_model.dart';

class MockSubjects {
  MockSubjects._();

  static const String preferredStreamName = 'Natural Science';

  static List<SubjectUiModel> naturalScience() => const [
        SubjectUiModel(
          subjectId: 'physics',
          name: 'Physics',
          iconGlyph: '🧪',
          paperCount: 0,
          questionCount: 0,
          isOpen: false,
        ),
        SubjectUiModel(
          subjectId: 'mathematics',
          name: 'Mathematics',
          iconGlyph: '📐',
          paperCount: 0,
          questionCount: 0,
          isOpen: true,
          progress: 0.62,
        ),
        SubjectUiModel(
          subjectId: 'biology',
          name: 'Biology',
          iconGlyph: '🧬',
          paperCount: 0,
          questionCount: 0,
          isOpen: false,
        ),
        SubjectUiModel(
          subjectId: 'chemistry',
          name: 'Chemistry',
          iconGlyph: '⚗️',
          paperCount: 0,
          questionCount: 0,
          isOpen: true,
          progress: 0.0,
        ),
        SubjectUiModel(
          subjectId: 'english',
          name: 'English',
          iconGlyph: '📖',
          paperCount: 0,
          questionCount: 0,
          isOpen: true,
          progress: 0.31,
        ),
        SubjectUiModel(
          subjectId: 'sat_aptitude',
          name: 'SAT (Aptitude)',
          iconGlyph: '🧩',
          paperCount: 0,
          questionCount: 0,
          isOpen: false,
        ),
      ];
}
