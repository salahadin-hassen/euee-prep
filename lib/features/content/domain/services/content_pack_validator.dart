import '../models/content_pack_file.dart';
import 'content_import_issue.dart';

/// Validates a parsed content-pack file against the contract in
/// `docs/content-pack-spec.md` and the schema in `docs/database-schema.md`.
///
/// Pure value-level validation — no database access. Returns every problem it
/// finds as a [ContentImportIssue]; an empty list means the pack is valid.
/// The importer refuses to write anything when issues exist (Decision 021).
class ContentPackValidator {
  const ContentPackValidator({
    this.supportedSchemaVersion = supportedContentPackSchemaVersion,
  });

  /// The pack file-format schema version this importer understands.
  /// The contract document (`content-pack-spec.md`) is v2.
  static const supportedContentPackSchemaVersion = '2';

  final String supportedSchemaVersion;

  static const _validStreams = {'natural_science', 'social_science'};
  static const _validGrades = {9, 10, 11, 12};
  static const _validResourceTypes = {'note', 'flashcard', 'mindmap'};

  List<ContentImportIssue> validate(ContentPackFile pack) {
    final issues = <ContentImportIssue>[];

    _validateMetadata(pack, issues);

    final allIds = <String>{};
    final topicIds = <String>{};
    final questionIds = <String>{};
    final examYears = <int>[];

    for (final chapter in pack.chapters) {
      _validateChapter(chapter, issues);
      if (chapter.id.isNotEmpty && !allIds.add(chapter.id)) {
        issues.add(
          ContentImportIssue('duplicate pack-local id "${chapter.id}"'),
        );
      }
      for (final topic in chapter.topics) {
        _validateTopic(topic, issues);
        if (topic.id.isNotEmpty && !allIds.add(topic.id)) {
          issues.add(
            ContentImportIssue('duplicate pack-local id "${topic.id}"'),
          );
        }
        topicIds.add(topic.id);
        for (final resource in topic.resources) {
          _validateResource(resource, issues);
          if (resource.id.isNotEmpty && !allIds.add(resource.id)) {
            issues.add(
              ContentImportIssue('duplicate pack-local id "${resource.id}"'),
            );
          }
        }
        for (final question in topic.questions) {
          _validateQuestion(question, issues);
          if (question.id.isNotEmpty && !allIds.add(question.id)) {
            issues.add(
              ContentImportIssue('duplicate pack-local id "${question.id}"'),
            );
          }
          questionIds.add(question.id);
        }
      }
    }

    for (final exam in pack.exams) {
      _validateExam(exam, issues);
      if (exam.id.isNotEmpty && !allIds.add(exam.id)) {
        issues.add(
          ContentImportIssue('duplicate pack-local id "${exam.id}"'),
        );
      }
      examYears.add(exam.yearEc);
    }

    // Decision 038 — one paper per (subject, EC year) per pack.
    final seenYears = <int>{};
    for (final year in examYears) {
      if (!seenYears.add(year)) {
        issues.add(
          ContentImportIssue(
            'duplicate exam for subject and year_ec $year — '
            'one paper per (subject, year) per pack (Decision 038)',
          ),
        );
      }
    }

    _validateReferences(pack, topicIds, questionIds, issues);

    return issues;
  }

  void _validateMetadata(
      ContentPackFile pack, List<ContentImportIssue> issues) {
    if (pack.schemaVersion != supportedSchemaVersion) {
      issues.add(
        ContentImportIssue(
          'unsupported schema_version "${pack.schemaVersion}"; '
          'supported: "$supportedSchemaVersion"',
        ),
      );
    }
    if (!_validStreams.contains(pack.stream)) {
      issues.add(
        ContentImportIssue(
          'stream must be "natural_science" or "social_science", '
          'got "${pack.stream}"',
        ),
      );
    }
    if (pack.subject.slug.isEmpty) {
      issues.add(const ContentImportIssue('subject.slug must be non-empty'));
    }
    if (pack.subject.title.isEmpty) {
      issues.add(const ContentImportIssue('subject.title must be non-empty'));
    }
    if (pack.packVersion.isEmpty) {
      issues.add(const ContentImportIssue('pack_version must be non-empty'));
    }
    if (pack.generatedAt.isEmpty ||
        DateTime.tryParse(pack.generatedAt) == null) {
      issues.add(
        const ContentImportIssue(
          'generated_at must be a valid ISO8601 timestamp',
        ),
      );
    }
    if (pack.checksum.isEmpty) {
      issues.add(const ContentImportIssue('checksum must be non-empty'));
    }
    if (pack.minimumAppVersion.isEmpty) {
      issues.add(
        const ContentImportIssue('minimum_app_version must be non-empty'),
      );
    }
  }

  void _validateChapter(ChapterFile chapter, List<ContentImportIssue> issues) {
    if (chapter.id.isEmpty) {
      issues.add(const ContentImportIssue('chapter has an empty id'));
    }
    if (!_validGrades.contains(chapter.grade)) {
      issues.add(
        ContentImportIssue(
          'chapter "${chapter.id}" has invalid grade ${chapter.grade}; '
          'expected 9, 10, 11, or 12',
        ),
      );
    }
    if (chapter.title.isEmpty) {
      issues.add(
        ContentImportIssue('chapter "${chapter.id}" title must be non-empty'),
      );
    }
    if (chapter.orderIndex < 0) {
      issues.add(
        ContentImportIssue(
          'chapter "${chapter.id}" order_index must be >= 0',
        ),
      );
    }
  }

  void _validateTopic(TopicFile topic, List<ContentImportIssue> issues) {
    if (topic.id.isEmpty) {
      issues.add(const ContentImportIssue('topic has an empty id'));
    }
    if (topic.title.isEmpty) {
      issues.add(
        ContentImportIssue('topic "${topic.id}" title must be non-empty'),
      );
    }
    if (topic.orderIndex < 0) {
      issues.add(
        ContentImportIssue('topic "${topic.id}" order_index must be >= 0'),
      );
    }
  }

  void _validateQuestion(
      QuestionFile question, List<ContentImportIssue> issues) {
    if (question.id.isEmpty) {
      issues.add(const ContentImportIssue('question has an empty id'));
    }
    if (question.prompt.isEmpty) {
      issues.add(
        ContentImportIssue(
            'question "${question.id}" prompt must be non-empty'),
      );
    }
    if (question.choices.length < 2) {
      issues.add(
        ContentImportIssue(
          'question "${question.id}" must have at least two choices',
        ),
      );
    }
    for (final choice in question.choices) {
      if (choice.isEmpty) {
        issues.add(
          ContentImportIssue(
            'question "${question.id}" contains an empty choice',
          ),
        );
      }
    }
    if (question.correctChoiceIndex < 0 ||
        question.correctChoiceIndex >= question.choices.length) {
      issues.add(
        ContentImportIssue(
          'question "${question.id}" correct_choice_index '
          '${question.correctChoiceIndex} is out of range for '
          '${question.choices.length} choices',
        ),
      );
    }
    if (question.topicRefs.isEmpty) {
      issues.add(
        ContentImportIssue(
          'question "${question.id}" must reference at least one topic',
        ),
      );
    }
  }

  void _validateResource(
      ResourceFile resource, List<ContentImportIssue> issues) {
    if (resource.id.isEmpty) {
      issues.add(const ContentImportIssue('resource has an empty id'));
    }
    if (!_validResourceTypes.contains(resource.type)) {
      issues.add(
        ContentImportIssue(
          'resource "${resource.id}" has invalid type "${resource.type}"; '
          'expected note, flashcard, or mindmap (Decision 037)',
        ),
      );
    }
    if (resource.content.isEmpty) {
      issues.add(
        ContentImportIssue(
            'resource "${resource.id}" content must be non-empty'),
      );
    }
    if (resource.orderIndex < 0) {
      issues.add(
        ContentImportIssue(
          'resource "${resource.id}" order_index must be >= 0',
        ),
      );
    }
  }

  void _validateExam(ExamFile exam, List<ContentImportIssue> issues) {
    if (exam.id.isEmpty) {
      issues.add(const ContentImportIssue('exam has an empty id'));
    }
    if (exam.yearEc <= 0) {
      issues.add(
        ContentImportIssue(
            'exam "${exam.id}" has invalid year_ec ${exam.yearEc}'),
      );
    }
    if (exam.durationSeconds != null && exam.durationSeconds! <= 0) {
      issues.add(
        ContentImportIssue(
          'exam "${exam.id}" duration_seconds must be > 0 when provided',
        ),
      );
    }
  }

  void _validateReferences(
    ContentPackFile pack,
    Set<String> topicIds,
    Set<String> questionIds,
    List<ContentImportIssue> issues,
  ) {
    for (final topic in pack.chapters.expand((c) => c.topics)) {
      for (final question in topic.questions) {
        for (final ref in question.topicRefs) {
          if (!topicIds.contains(ref)) {
            issues.add(
              ContentImportIssue(
                'question "${question.id}" references unknown topic "$ref"',
              ),
            );
          }
        }
        if (question.topicRefs.toSet().length != question.topicRefs.length) {
          issues.add(
            ContentImportIssue(
              'question "${question.id}" lists a topic more than once',
            ),
          );
        }
      }
    }

    for (final exam in pack.exams) {
      for (final ref in exam.questionIds) {
        if (!questionIds.contains(ref)) {
          issues.add(
            ContentImportIssue(
              'exam "${exam.id}" references unknown question "$ref"',
            ),
          );
        }
      }
      if (exam.questionIds.toSet().length != exam.questionIds.length) {
        issues.add(
          ContentImportIssue(
            'exam "${exam.id}" lists a question more than once',
          ),
        );
      }
    }
  }
}
