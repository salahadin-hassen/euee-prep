import 'dart:convert';

/// Thrown when a content-pack file cannot be parsed into typed objects —
/// a malformed field, wrong type, or missing required field.
///
/// Value-level problems (empty strings, out-of-range integers, unknown enum
/// values, broken references) are *not* parse errors; they are surfaced as
/// [ContentImportIssue]s by the validator in `content_import_service.dart`.
class ContentPackFormatException implements Exception {
  const ContentPackFormatException(this.message);

  final String message;

  @override
  String toString() => 'ContentPackFormatException: $message';
}

/// Parsed top-level content pack file (contract: `docs/content-pack-spec.md`).
///
/// DTOs in this file mirror the pack file format only — they are distinct from
/// the domain models in this folder (`chapter.dart`, `question.dart`, ...)
/// which represent persisted rows. `toCanonicalJson()` produces the
/// deterministic serialization that the pack checksum is computed over.
class ContentPackFile {
  const ContentPackFile({
    required this.packVersion,
    required this.schemaVersion,
    required this.generatedAt,
    required this.checksum,
    required this.minimumAppVersion,
    required this.stream,
    required this.subject,
    required this.chapters,
    required this.exams,
  });

  final String packVersion;
  final String schemaVersion;
  final String generatedAt;
  final String checksum;
  final String minimumAppVersion;
  final String stream;
  final SubjectDescriptor subject;
  final List<ChapterFile> chapters;
  final List<ExamFile> exams;

  /// Version-independent pack identity: `{stream_slug}-{subject_slug}`.
  String get packKey => '$stream-${subject.slug}';

  /// Version-specific row identity: `{pack_key}#{pack_version}`.
  String get id => '$packKey#$packVersion';

  factory ContentPackFile.parse(String rawJson) {
    final Object? decoded;
    try {
      decoded = jsonDecode(rawJson);
    } on FormatException catch (e) {
      throw ContentPackFormatException('malformed JSON: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ContentPackFormatException('the pack must be a JSON object');
    }
    return ContentPackFile.fromJson(decoded);
  }

  factory ContentPackFile.fromJson(Map<String, dynamic> json) {
    return ContentPackFile(
      packVersion: _string(json, 'pack_version'),
      schemaVersion: _string(json, 'schema_version'),
      generatedAt: _string(json, 'generated_at'),
      checksum: _string(json, 'checksum'),
      minimumAppVersion: _string(json, 'minimum_app_version'),
      stream: _string(json, 'stream'),
      subject: SubjectDescriptor.fromJson(_map(json, 'subject')),
      chapters: _list(json, 'chapters')
          .map((e) => ChapterFile.fromJson(_asMap(e, 'chapters[]')))
          .toList(),
      exams: _list(json, 'exams')
          .map((e) => ExamFile.fromJson(_asMap(e, 'exams[]')))
          .toList(),
    );
  }

  /// Deterministic serialization used for checksum verification. The
  /// `checksum` field is deliberately excluded — a pack cannot checksum itself.
  String toCanonicalJson() {
    return jsonEncode({
      'pack_version': packVersion,
      'schema_version': schemaVersion,
      'generated_at': generatedAt,
      'minimum_app_version': minimumAppVersion,
      'stream': stream,
      'subject': subject.toJson(),
      'chapters': chapters.map((c) => c.toJson()).toList(),
      'exams': exams.map((e) => e.toJson()).toList(),
    });
  }
}

class SubjectDescriptor {
  const SubjectDescriptor({required this.slug, required this.title});

  final String slug;
  final String title;

  factory SubjectDescriptor.fromJson(Map<String, dynamic> json) {
    return SubjectDescriptor(
      slug: _string(json, 'slug'),
      title: _string(json, 'title'),
    );
  }

  Map<String, dynamic> toJson() => {'slug': slug, 'title': title};
}

class ChapterFile {
  const ChapterFile({
    required this.id,
    required this.grade,
    required this.title,
    required this.orderIndex,
    required this.topics,
  });

  final String id;
  final int grade;
  final String title;
  final int orderIndex;
  final List<TopicFile> topics;

  factory ChapterFile.fromJson(Map<String, dynamic> json) {
    return ChapterFile(
      id: _string(json, 'id'),
      grade: _int(json, 'grade'),
      title: _string(json, 'title'),
      orderIndex: _int(json, 'order_index'),
      topics: _list(json, 'topics')
          .map((e) => TopicFile.fromJson(_asMap(e, 'topics[]')))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'grade': grade,
        'title': title,
        'order_index': orderIndex,
        'topics': topics.map((t) => t.toJson()).toList(),
      };
}

class TopicFile {
  const TopicFile({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.questions,
    required this.resources,
  });

  final String id;
  final String title;
  final int orderIndex;
  final List<QuestionFile> questions;
  final List<ResourceFile> resources;

  factory TopicFile.fromJson(Map<String, dynamic> json) {
    return TopicFile(
      id: _string(json, 'id'),
      title: _string(json, 'title'),
      orderIndex: _int(json, 'order_index'),
      questions: _list(json, 'questions')
          .map((e) => QuestionFile.fromJson(_asMap(e, 'questions[]')))
          .toList(),
      resources: _list(json, 'resources')
          .map((e) => ResourceFile.fromJson(_asMap(e, 'resources[]')))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'order_index': orderIndex,
        'questions': questions.map((q) => q.toJson()).toList(),
        'resources': resources.map((r) => r.toJson()).toList(),
      };
}

class QuestionFile {
  const QuestionFile({
    required this.id,
    required this.prompt,
    required this.choices,
    required this.correctChoiceIndex,
    required this.topicRefs,
    this.explanation,
    this.textbookReference,
    this.examYearEc,
    this.imageReference,
    this.graphReference,
    this.diagramReference,
    this.tableReference,
  });

  final String id;
  final String prompt;
  final List<String> choices;
  final int correctChoiceIndex;
  final List<String> topicRefs;
  final String? explanation;
  final String? textbookReference;
  final int? examYearEc;
  final String? imageReference;
  final String? graphReference;
  final String? diagramReference;
  final String? tableReference;

  factory QuestionFile.fromJson(Map<String, dynamic> json) {
    return QuestionFile(
      id: _string(json, 'id'),
      prompt: _string(json, 'prompt'),
      choices: _stringList(json, 'choices'),
      correctChoiceIndex: _int(json, 'correct_choice_index'),
      topicRefs: _stringList(json, 'topic_refs'),
      explanation: _nullableString(json, 'explanation'),
      textbookReference: _nullableString(json, 'textbook_reference'),
      examYearEc: _nullableInt(json, 'exam_year_ec'),
      imageReference: _nullableString(json, 'image_reference'),
      graphReference: _nullableString(json, 'graph_reference'),
      diagramReference: _nullableString(json, 'diagram_reference'),
      tableReference: _nullableString(json, 'table_reference'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt': prompt,
        'choices': choices,
        'correct_choice_index': correctChoiceIndex,
        if (explanation != null) 'explanation': explanation,
        if (textbookReference != null) 'textbook_reference': textbookReference,
        if (examYearEc != null) 'exam_year_ec': examYearEc,
        'topic_refs': topicRefs,
        if (imageReference != null) 'image_reference': imageReference,
        if (graphReference != null) 'graph_reference': graphReference,
        if (diagramReference != null) 'diagram_reference': diagramReference,
        if (tableReference != null) 'table_reference': tableReference,
      };
}

class ResourceFile {
  const ResourceFile({
    required this.id,
    required this.type,
    required this.content,
    required this.orderIndex,
    this.title,
  });

  final String id;
  final String type;
  final String? title;
  final String content;
  final int orderIndex;

  factory ResourceFile.fromJson(Map<String, dynamic> json) {
    return ResourceFile(
      id: _string(json, 'id'),
      type: _string(json, 'type'),
      title: _nullableString(json, 'title'),
      content: _string(json, 'content'),
      orderIndex: _int(json, 'order_index'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        if (title != null) 'title': title,
        'content': content,
        'order_index': orderIndex,
      };
}

class ExamFile {
  const ExamFile({
    required this.id,
    required this.yearEc,
    required this.questionIds,
    this.title,
    this.durationSeconds,
  });

  final String id;
  final int yearEc;
  final String? title;
  final int? durationSeconds;
  final List<String> questionIds;

  factory ExamFile.fromJson(Map<String, dynamic> json) {
    return ExamFile(
      id: _string(json, 'id'),
      yearEc: _int(json, 'year_ec'),
      title: _nullableString(json, 'title'),
      durationSeconds: _nullableInt(json, 'duration_seconds'),
      questionIds: _stringList(json, 'question_ids'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'year_ec': yearEc,
        if (title != null) 'title': title,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        'question_ids': questionIds,
      };
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw ContentPackFormatException('"$key" must be a string');
  }
  return value;
}

String? _nullableString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw ContentPackFormatException('"$key" must be a string or null');
  }
  return value;
}

int _int(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw ContentPackFormatException('"$key" must be an integer');
  }
  return value;
}

int? _nullableInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! int) {
    throw ContentPackFormatException('"$key" must be an integer or null');
  }
  return value;
}

List<dynamic> _list(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) {
    throw ContentPackFormatException('"$key" must be an array');
  }
  return value;
}

List<String> _stringList(Map<String, dynamic> json, String key) {
  final value = _list(json, key);
  final strings = <String>[];
  for (final element in value) {
    if (element is! String) {
      throw ContentPackFormatException('"$key" must be an array of strings');
    }
    strings.add(element);
  }
  return strings;
}

Map<String, dynamic> _map(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map<String, dynamic>) {
    throw ContentPackFormatException('"$key" must be an object');
  }
  return value;
}

Map<String, dynamic> _asMap(Object? value, String path) {
  if (value is! Map<String, dynamic>) {
    throw ContentPackFormatException('$path must be an object');
  }
  return value;
}
