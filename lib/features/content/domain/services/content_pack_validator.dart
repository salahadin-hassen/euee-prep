import '../models/content_pack_file.dart';
import 'content_import_issue.dart';

/// Validates a parsed content-pack file against the v3 flat schema contract.
///
/// Pure value-level validation — no database access. Returns every problem it
/// finds as a [ContentImportIssue]; an empty list means the pack is valid.
/// The importer refuses to write anything when issues exist.
class ContentPackValidator {
  const ContentPackValidator();

  static const supportedSchemaVersion = '3';
  static const _validStreams = {'natural_science', 'social_science'};

  List<ContentImportIssue> validate(ContentPackFile pack) {
    final issues = <ContentImportIssue>[];

    _validateMetadata(pack, issues);
    _validatePaper(pack, issues);
    _validateQuestions(pack, issues);

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
    if (pack.packId.isEmpty) {
      issues.add(const ContentImportIssue('pack_id must be non-empty'));
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

  void _validatePaper(ContentPackFile pack, List<ContentImportIssue> issues) {
    if (pack.paper.year <= 0) {
      issues.add(
        ContentImportIssue('paper.year must be > 0, got ${pack.paper.year}'),
      );
    }
    if (pack.paper.title.isEmpty) {
      issues.add(const ContentImportIssue('paper.title must be non-empty'));
    }
    if (pack.paper.questionCount != pack.questions.length) {
      issues.add(
        ContentImportIssue(
          'paper.question_count (${pack.paper.questionCount}) '
          'does not match actual question count (${pack.questions.length})',
        ),
      );
    }
  }

  void _validateQuestions(
      ContentPackFile pack, List<ContentImportIssue> issues) {
    final seenIds = <String>{};

    for (final question in pack.questions) {
      if (question.id.isEmpty) {
        issues.add(const ContentImportIssue('question has an empty id'));
      }
      if (!seenIds.add(question.id)) {
        issues.add(
          ContentImportIssue('duplicate question id "${question.id}"'),
        );
      }
      if (question.number <= 0) {
        issues.add(
          ContentImportIssue(
            'question "${question.id}" number must be > 0',
          ),
        );
      }
      if (question.prompt.isEmpty) {
        issues.add(
          ContentImportIssue(
            'question "${question.id}" prompt must be non-empty',
          ),
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
    }
  }
}
