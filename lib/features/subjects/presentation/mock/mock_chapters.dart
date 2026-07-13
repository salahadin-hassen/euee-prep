// TEMPORARY MOCK DATA SOURCE.
//
// Stands in for the real repository/provider until Riverpod/Drift are
// wired up.
//
// TODO(integration): delete once a real provider supplies
// GradeSectionUiModel instances derived from Chapter (scoped to
// subjectId + each Grade, Decision 010) and a Service-layer completion
// rollup over Attempt history (Decision 016).

import '../models/chapter_ui_model.dart';

class MockChapters {
  MockChapters._();

  static List<GradeSectionUiModel> forSubject(String subjectId) {
    // Same shape for every mock subject at MVP — only Physics has
    // richer content since it's the primary example used in the design
    // review's wireframe.
    if (subjectId == 'physics') return _physics;
    return _generic(subjectId);
  }

  static final List<GradeSectionUiModel> _physics = [
    const GradeSectionUiModel(
      grade: 9,
      chapters: [
        ChapterUiModel(chapterId: 'p9-1', title: 'Measurement', status: ChapterStatus.completed),
        ChapterUiModel(chapterId: 'p9-2', title: 'Motion in a Straight Line', status: ChapterStatus.completed),
        ChapterUiModel(chapterId: 'p9-3', title: 'Force and Newton\'s Laws', status: ChapterStatus.notStarted),
      ],
    ),
    const GradeSectionUiModel(
      grade: 10,
      chapters: [
        ChapterUiModel(chapterId: 'p10-1', title: 'Motion and Forces', status: ChapterStatus.notStarted),
        ChapterUiModel(chapterId: 'p10-2', title: 'Work and Energy', status: ChapterStatus.completed),
        ChapterUiModel(chapterId: 'p10-3', title: 'Heat and Temperature', status: ChapterStatus.notStarted),
      ],
    ),
    const GradeSectionUiModel(
      grade: 11,
      chapters: [
        ChapterUiModel(chapterId: 'p11-1', title: 'Waves and Sound', status: ChapterStatus.inProgress),
        ChapterUiModel(chapterId: 'p11-2', title: 'Optics', status: ChapterStatus.notStarted),
        ChapterUiModel(chapterId: 'p11-3', title: 'Thermodynamics', status: ChapterStatus.notStarted),
      ],
    ),
    const GradeSectionUiModel(
      grade: 12,
      chapters: [
        ChapterUiModel(chapterId: 'p12-1', title: 'Electrostatics', status: ChapterStatus.completed),
        ChapterUiModel(chapterId: 'p12-2', title: 'Circuits', status: ChapterStatus.inProgress),
        ChapterUiModel(chapterId: 'p12-3', title: 'Modern Physics', status: ChapterStatus.notStarted),
      ],
    ),
  ];

  static List<GradeSectionUiModel> _generic(String subjectId) => [
        GradeSectionUiModel(
          grade: 9,
          chapters: [
            ChapterUiModel(chapterId: '$subjectId-9-1', title: 'Chapter 1', status: ChapterStatus.notStarted),
            ChapterUiModel(chapterId: '$subjectId-9-2', title: 'Chapter 2', status: ChapterStatus.notStarted),
          ],
        ),
        GradeSectionUiModel(
          grade: 10,
          chapters: [
            ChapterUiModel(chapterId: '$subjectId-10-1', title: 'Chapter 1', status: ChapterStatus.notStarted),
          ],
        ),
        GradeSectionUiModel(
          grade: 11,
          chapters: [
            ChapterUiModel(chapterId: '$subjectId-11-1', title: 'Chapter 1', status: ChapterStatus.notStarted),
          ],
        ),
        GradeSectionUiModel(
          grade: 12,
          chapters: [
            ChapterUiModel(chapterId: '$subjectId-12-1', title: 'Chapter 1', status: ChapterStatus.notStarted),
          ],
        ),
      ];
}
