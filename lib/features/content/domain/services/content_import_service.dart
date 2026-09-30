import 'dart:convert';

import '../../../streams/domain/repositories/stream_repository.dart';
import '../../../subjects/domain/repositories/subject_repository.dart';
import '../../../subjects/domain/models/subject.dart';
import '../../../streams/domain/models/stream_model.dart';
import '../models/content_pack.dart';
import '../models/content_pack_file.dart';
import '../models/exam.dart';
import '../models/question.dart';
import '../repositories/content_pack_repository.dart';
import '../repositories/exam_repository.dart';
import '../repositories/question_repository.dart';
import 'content_import_checksum.dart';
import 'content_import_issue.dart';
import 'content_import_transaction.dart';
import 'content_pack_validator.dart';

/// Result of a content-pack import attempt.
///
/// Import failures are expected states (malformed pack, broken references,
/// unsupported version), so they are returned as data rather than thrown —
/// see `docs/coding-standards.md` error-handling rules.
class ContentImportResult {
  const ContentImportResult._({
    this.pack,
    required this.alreadyImported,
    this.issues = const [],
  });

  factory ContentImportResult.success(ContentPack pack) =>
      ContentImportResult._(pack: pack, alreadyImported: false);

  /// The exact pack/version already exists on the device — re-import is a
  /// no-op (Decision 034: import is insert-only, `(source_pack_id,
  /// pack_local_id)` mapping is idempotent).
  factory ContentImportResult.alreadyImported(ContentPack pack) =>
      ContentImportResult._(pack: pack, alreadyImported: true);

  factory ContentImportResult.failure(List<ContentImportIssue> issues) =>
      ContentImportResult._(
        alreadyImported: false,
        issues: List.unmodifiable(issues),
      );

  final ContentPack? pack;
  final bool alreadyImported;
  final List<ContentImportIssue> issues;

  bool get isSuccess => pack != null;
}

/// Thrown inside the import transaction for a condition that only the
/// database can detect (e.g. a subject title changing across pack versions).
/// Drift rolls the transaction back and the service converts it into a
/// [ContentImportResult.failure].
class ContentPackImportException implements Exception {
  const ContentPackImportException(this.issue);

  final ContentImportIssue issue;

  @override
  String toString() => 'ContentPackImportException: $issue';
}

/// Coordinates content-pack ingestion: parse → validate → checksum →
/// app-version gate → idempotency → atomic import through the existing
/// repositories.
///
/// For the v3 flat schema, the import pipeline is simplified:
///   Stream → Subject → ContentPack → Exam → Questions → ExamQuestions
///
/// No chapters, topics, or resources are created.
class ContentImportService {
  ContentImportService({
    required ContentPackRepository contentPackRepository,
    required StreamRepository streamRepository,
    required SubjectRepository subjectRepository,
    required QuestionRepository questionRepository,
    required ExamRepository examRepository,
    required ContentImportTransaction transaction,
    this.currentAppVersion = '1.0.0',
  })  : _contentPackRepository = contentPackRepository,
        _streamRepository = streamRepository,
        _subjectRepository = subjectRepository,
        _questionRepository = questionRepository,
        _examRepository = examRepository,
        _transaction = transaction;

  final ContentPackRepository _contentPackRepository;
  final StreamRepository _streamRepository;
  final SubjectRepository _subjectRepository;
  final QuestionRepository _questionRepository;
  final ExamRepository _examRepository;
  final ContentImportTransaction _transaction;

  /// The running app version, compared against `minimum_app_version`.
  final String currentAppVersion;

  Future<ContentImportResult> import(String rawJson,
      {String? importedAt}) async {
    final ContentPackFile pack;
    try {
      pack = ContentPackFile.parse(rawJson);
    } on ContentPackFormatException catch (e) {
      return ContentImportResult.failure([ContentImportIssue(e.message)]);
    }

    final issues = const ContentPackValidator().validate(pack);
    if (issues.isNotEmpty) {
      return ContentImportResult.failure(issues);
    }

    if (pack.checksum != ContentChecksum.compute(pack)) {
      return ContentImportResult.failure(const [
        ContentImportIssue(
          'checksum mismatch — the pack does not match its declared checksum',
        ),
      ]);
    }

    if (_compareSemVer(pack.minimumAppVersion, currentAppVersion) > 0) {
      return ContentImportResult.failure([
        ContentImportIssue(
          'pack requires app version ${pack.minimumAppVersion} '
          'but the app is $currentAppVersion',
        ),
      ]);
    }

    final existing = await _contentPackRepository.getById(pack.id);
    if (existing != null) {
      return ContentImportResult.alreadyImported(existing);
    }

    try {
      final contentPack = await _transaction.run(
        () => _importPack(pack, importedAt ?? _nowIso8601()),
      );
      return ContentImportResult.success(contentPack);
    } on ContentPackImportException catch (e) {
      return ContentImportResult.failure([e.issue]);
    }
  }

  Future<ContentPack> _importPack(
    ContentPackFile pack,
    String importedAt,
  ) async {
    var nextStreamId = _maxPlusOne(
      (await _streamRepository.getAll()).map((s) => s.id),
    );
    var nextSubjectId = _maxPlusOne(
      (await _subjectRepository.getAll()).map((s) => s.id),
    );
    var nextQuestionId = _maxPlusOne(
      (await _questionRepository.getAll()).map((q) => q.id),
    );
    var nextExamId = _maxPlusOne(
      (await _examRepository.getAll()).map((e) => e.id),
    );

    // Stream — find or create.
    final existingStream = await _streamRepository.getBySlug(pack.stream);
    final int streamId;
    if (existingStream != null) {
      streamId = existingStream.id;
    } else {
      streamId = nextStreamId++;
      await _streamRepository.insert(
        StreamModel(id: streamId, slug: pack.stream),
      );
    }

    // Subject — find or create. Reject title changes across pack versions.
    final existingSubject = await _subjectRepository.getByStreamAndSlug(
      streamId,
      pack.subject.slug,
    );
    final int subjectId;
    if (existingSubject != null) {
      if (existingSubject.title != pack.subject.title) {
        throw ContentPackImportException(
          ContentImportIssue(
            'subject "${pack.subject.slug}" title changed from '
            '"${existingSubject.title}" to "${pack.subject.title}" across '
            'pack versions — content is immutable',
          ),
        );
      }
      subjectId = existingSubject.id;
    } else {
      subjectId = nextSubjectId++;
      await _subjectRepository.insert(
        Subject(
          id: subjectId,
          streamId: streamId,
          slug: pack.subject.slug,
          title: pack.subject.title,
        ),
      );
    }

    // Content pack metadata.
    final contentPack = await _contentPackRepository.insert(
      ContentPack(
        id: pack.id,
        packKey: pack.packKey,
        subjectId: subjectId,
        packVersion: pack.packVersion,
        schemaVersion: pack.schemaVersion,
        generatedAt: pack.generatedAt,
        checksum: pack.checksum,
        minimumAppVersion: pack.minimumAppVersion,
        importedAt: importedAt,
      ),
    );

    // Questions — flat list, no topics.
    final questionIdByPackLocal = <String, int>{};
    for (final questionFile in pack.questions) {
      final questionId = nextQuestionId++;
      await _questionRepository.insert(
        Question(
          id: questionId,
          sourcePackId: contentPack.id,
          packLocalId: questionFile.id,
          prompt: questionFile.prompt,
          choicesJson: jsonEncode(questionFile.choices),
          correctChoiceIndex: questionFile.correctChoiceIndex,
          topicIds: const [],
          explanation: questionFile.explanation,
        ),
      );
      questionIdByPackLocal[questionFile.id] = questionId;
    }

    // Exam — one paper per pack.
    final examId = nextExamId++;
    final examQuestionIds = pack.questions
        .map((q) => questionIdByPackLocal[q.id]!)
        .toList();
    await _examRepository.insert(
      Exam(
        id: examId,
        sourcePackId: contentPack.id,
        packLocalId: pack.packId,
        subjectId: subjectId,
        examYearEc: pack.paper.year,
        questionIds: examQuestionIds,
        title: pack.paper.title,
      ),
    );

    return contentPack;
  }
}

int _maxPlusOne(Iterable<int> ids) {
  var max = 0;
  for (final id in ids) {
    if (id > max) max = id;
  }
  return max + 1;
}

int _compareSemVer(String a, String b) {
  final partsA = a.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final partsB = b.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final length = partsA.length > partsB.length ? partsA.length : partsB.length;
  for (var i = 0; i < length; i++) {
    final x = i < partsA.length ? partsA[i] : 0;
    final y = i < partsB.length ? partsB[i] : 0;
    if (x != y) return x < y ? -1 : 1;
  }
  return 0;
}

String _nowIso8601() => DateTime.now().toUtc().toIso8601String();
