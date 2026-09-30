import 'dart:convert';

/// Thrown when a content-pack file cannot be parsed into typed objects —
/// a malformed field, wrong type, or missing required field.
///
/// Value-level problems (empty strings, out-of-range integers, unknown enum
/// values, broken references) are *not* parse errors; they are surfaced as
/// [ContentImportIssue]s by the validator in `content_pack_validator.dart`.
class ContentPackFormatException implements Exception {
  const ContentPackFormatException(this.message);

  final String message;

  @override
  String toString() => 'ContentPackFormatException: $message';
}

/// Parsed content-pack file for the v3 flat schema.
///
/// One paper = one content pack. The conceptual hierarchy is:
///   Stream → Subject → Paper (year) → Questions
///
/// DTOs mirror the pack file format only — they are distinct from the
/// domain models which represent persisted rows. `toCanonicalJson()`
/// produces the deterministic serialization that the checksum is computed over.
class ContentPackFile {
  const ContentPackFile({
    required this.schemaVersion,
    required this.packId,
    required this.packVersion,
    required this.generatedAt,
    required this.checksum,
    required this.minimumAppVersion,
    required this.stream,
    required this.subject,
    required this.paper,
    required this.questions,
  });

  final String schemaVersion;
  final String packId;
  final String packVersion;
  final String generatedAt;
  final String checksum;
  final String minimumAppVersion;
  final String stream;
  final SubjectDescriptor subject;
  final PaperDescriptor paper;
  final List<QuestionFile> questions;

  /// Version-independent pack identity: `{stream}-{subject_slug}`.
  String get packKey => '$stream-${subject.slug}';

  /// Version-specific row identity: `{pack_id}#{pack_version}`.
  String get id => '$packId#$packVersion';

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
      schemaVersion: _string(json, 'schema_version'),
      packId: _string(json, 'pack_id'),
      packVersion: _string(json, 'pack_version'),
      generatedAt: _string(json, 'generated_at'),
      checksum: _string(json, 'checksum'),
      minimumAppVersion: _string(json, 'minimum_app_version'),
      stream: _string(json, 'stream'),
      subject: SubjectDescriptor.fromJson(_map(json, 'subject')),
      paper: PaperDescriptor.fromJson(_map(json, 'paper')),
      questions: _list(json, 'questions')
          .map((e) => QuestionFile.fromJson(_asMap(e, 'questions[]')))
          .toList(),
    );
  }

  /// Deterministic serialization used for checksum verification. The
  /// `checksum` field is deliberately excluded — a pack cannot checksum itself.
  String toCanonicalJson() {
    return jsonEncode({
      'generated_at': generatedAt,
      'minimum_app_version': minimumAppVersion,
      'pack_id': packId,
      'pack_version': packVersion,
      'paper': paper.toJson(),
      'questions': questions.map((q) => q.toJson()).toList(),
      'schema_version': schemaVersion,
      'stream': stream,
      'subject': subject.toJson(),
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

class PaperDescriptor {
  const PaperDescriptor({
    required this.year,
    required this.title,
    required this.questionCount,
  });

  final int year;
  final String title;
  final int questionCount;

  factory PaperDescriptor.fromJson(Map<String, dynamic> json) {
    return PaperDescriptor(
      year: _int(json, 'year'),
      title: _string(json, 'title'),
      questionCount: _int(json, 'question_count'),
    );
  }

  Map<String, dynamic> toJson() => {
        'year': year,
        'title': title,
        'question_count': questionCount,
      };
}

class QuestionFile {
  const QuestionFile({
    required this.id,
    required this.number,
    required this.prompt,
    required this.choices,
    required this.correctChoiceIndex,
    this.explanation,
    this.sourcePage,
  });

  final String id;
  final int number;
  final String prompt;
  final List<String> choices;
  final int correctChoiceIndex;
  final String? explanation;
  final int? sourcePage;

  factory QuestionFile.fromJson(Map<String, dynamic> json) {
    return QuestionFile(
      id: _string(json, 'id'),
      number: _int(json, 'number'),
      prompt: _string(json, 'prompt'),
      choices: _stringList(json, 'choices'),
      correctChoiceIndex: _int(json, 'correct_choice_index'),
      explanation: _nullableString(json, 'explanation'),
      sourcePage: _nullableInt(json, 'source_page'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'prompt': prompt,
        'choices': choices,
        'correct_choice_index': correctChoiceIndex,
        if (explanation != null) 'explanation': explanation,
        if (sourcePage != null) 'source_page': sourcePage,
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
