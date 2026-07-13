// TEMPORARY MOCK DATA SOURCE.
//
// Stands in for the real repository/provider until Riverpod/Drift are
// wired up. Represents a Natural Science Preferred Stream (Decision 009)
// with a mix of locked and entitled subjects, exercising both card
// states plus a partial-progress example.
//
// TODO(integration): delete once a real provider supplies
// SubjectUiModel instances derived from the Subject + Entitlement +
// Attempt repositories (scoped to the user's Preferred Stream per
// Decision 029, entitlement-gated per Decision 012).

import '../models/subject_ui_model.dart';

class MockSubjects {
  MockSubjects._();

  static const String preferredStreamName = 'Natural Science';

  static List<SubjectUiModel> naturalScience() => const [
        SubjectUiModel(
          subjectId: 'physics',
          name: 'Physics',
          iconGlyph: '🧪',
          chapterCount: 24,
          isEntitled: false,
        ),
        SubjectUiModel(
          subjectId: 'mathematics',
          name: 'Mathematics',
          iconGlyph: '📐',
          chapterCount: 31,
          isEntitled: true,
          progress: 0.62,
        ),
        SubjectUiModel(
          subjectId: 'biology',
          name: 'Biology',
          iconGlyph: '🧬',
          chapterCount: 19,
          isEntitled: false,
        ),
        SubjectUiModel(
          subjectId: 'chemistry',
          name: 'Chemistry',
          iconGlyph: '⚗️',
          chapterCount: 22,
          isEntitled: true,
          progress: 0.0,
        ),
        SubjectUiModel(
          subjectId: 'english',
          name: 'English',
          iconGlyph: '📖',
          chapterCount: 16,
          isEntitled: true,
          progress: 0.31,
        ),
        SubjectUiModel(
          subjectId: 'sat_aptitude',
          name: 'SAT (Aptitude)',
          iconGlyph: '🧩',
          chapterCount: 12,
          isEntitled: false,
        ),
      ];
}
