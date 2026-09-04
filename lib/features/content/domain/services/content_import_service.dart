import 'dart:convert';

import '../../../grades/domain/models/grade.dart';
import '../../../grades/domain/repositories/grade_repository.dart';
import '../../../streams/domain/models/stream_model.dart';
import '../../../streams/domain/repositories/stream_repository.dart';
import '../../../subjects/domain/models/subject.dart';
import '../../../subjects/domain/repositories/subject_repository.dart';
import '../models/chapter.dart';
import '../models/content_pack.dart';
import '../models/content_pack_file.dart';
import '../models/exam.dart';
import '../models/question.dart';
import '../models/resource.dart';
import '../models/topic.dart';
import '../repositories/chapter_repository.dart';
import '../repositories/content_pack_repository.dart';
import '../repositories/exam_repository.dart';
import '../repositories/question_repository.dart';
import '../repositories/resource_repository.dart';
import '../repositories/topic_repository.dart';
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
/// repositories (Decision 021/026, Milestone 3 of the roadmap).
///
/// Lives in `content/domain` because it is scoped entirely to the `content`
/// feature (per `docs/coding-standards.md` Service placement rule). All row
/// writes flow through repositories; the only Drift access is the injected
/// [ContentImportTransaction], which provides the atomic boundary without the
/// service executing any queries itself.
class ContentImportService {
  ContentImportService({
    required ContentPackRepository contentPackRepository,
    required GradeRepository gradeRepository,
    required StreamRepository streamRepository,
    required SubjectRepository subjectRepository,
    required ChapterRepository chapterRepository,
    required TopicRepository topicRepository,
    required QuestionRepository questionRepository,
    required ExamRepository examRepository,
    required ResourceRepository resourceRepository,
    required ContentImportTransaction transaction,
    this.currentAppVersion = '0.1.0',
  })  : _contentPackRepository = contentPackRepository,
        _gradeRepository = gradeRepository,
        _streamRepository = streamRepository,
        _subjectRepository = subjectRepository,
        _chapterRepository = chapterRepository,
        _topicRepository = topicRepository,
        _questionRepository = questionRepository,
        _examRepository = examRepository,
        _resourceRepository = resourceRepository,
        _transaction = transaction;

  final ContentPackRepository _contentPackRepository;
  final GradeRepository _gradeRepository;
  final StreamRepository _streamRepository;
  final SubjectRepository _subjectRepository;
  final ChapterRepository _chapterRepository;
  final TopicRepository _topicRepository;
  final QuestionRepository _questionRepository;
  final ExamRepository _examRepository;
  final ResourceRepository _resourceRepository;
  final ContentImportTransaction _transaction;

  /// The running app version, compared against `minimum_app_version`
  /// (Decision 021). Defaults to the value in `pubspec.yaml`.
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
    var nextGradeId = _maxPlusOne(
      (await _gradeRepository.getAll()).map((g) => g.id),
    );
    var nextStreamId = _maxPlusOne(
      (await _streamRepository.getAll()).map((s) => s.id),
    );
    var nextSubjectId = _maxPlusOne(
      (await _subjectRepository.getAll()).map((s) => s.id),
    );
    var nextChapterId = _maxPlusOne(
      (await _chapterRepository.getAll()).map((c) => c.id),
    );
    var nextTopicId = _maxPlusOne(
      (await _topicRepository.getAll()).map((t) => t.id),
    );
    var nextQuestionId = _maxPlusOne(
      (await _questionRepository.getAll()).map((q) => q.id),
    );
    var nextResourceId = _maxPlusOne(
      (await _resourceRepository.getAll()).map((r) => r.id),
    );
    var nextExamId = _maxPlusOne(
      (await _examRepository.getAll()).map((e) => e.id),
    );

    final gradeIdByLevel = <int, int>{};
    for (final level in pack.chapters.map((c) => c.grade).toSet()) {
      final existing = await _gradeRepository.getByLevel(level);
      if (existing != null) {
        gradeIdByLevel[level] = existing.id;
      } else {
        final id = nextGradeId++;
        await _gradeRepository.insert(Grade(id: id, level: level));
        gradeIdByLevel[level] = id;
      }
    }

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
            'pack versions — content is immutable (Decision 015/021)',
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

    final topicIdByPackLocal = <String, int>{};
    final questionIdByPackLocal = <String, int>{};

    // Phase 1 — chapters and topics. All topics must exist before any
    // question's topic_refs can be resolved.
    for (final chapterFile in pack.chapters) {
      final chapterId = nextChapterId++;
      await _chapterRepository.insert(
        Chapter(
          id: chapterId,
          subjectId: subjectId,
          gradeId: gradeIdByLevel[chapterFile.grade]!,
          sourcePackId: contentPack.id,
          packLocalId: chapterFile.id,
          title: chapterFile.title,
          orderIndex: chapterFile.orderIndex,
        ),
      );
      for (final topicFile in chapterFile.topics) {
        final topicId = nextTopicId++;
        await _topicRepository.insert(
          Topic(
            id: topicId,
            chapterId: chapterId,
            sourcePackId: contentPack.id,
            packLocalId: topicFile.id,
            title: topicFile.title,
            orderIndex: topicFile.orderIndex,
          ),
        );
        topicIdByPackLocal[topicFile.id] = topicId;
      }
    }

    // Phase 2 — resources and questions, now that every topic is known.
    for (final chapterFile in pack.chapters) {
      for (final topicFile in chapterFile.topics) {
        final topicId = topicIdByPackLocal[topicFile.id]!;
        for (final resourceFile in topicFile.resources) {
          final resourceId = nextResourceId++;
          await _resourceRepository.insert(
            Resource(
              id: resourceId,
              topicId: topicId,
              sourcePackId: contentPack.id,
              packLocalId: resourceFile.id,
              type: _resourceType(resourceFile.type),
              title: resourceFile.title,
              content: resourceFile.content,
              orderIndex: resourceFile.orderIndex,
            ),
          );
        }
        for (final questionFile in topicFile.questions) {
          final questionId = nextQuestionId++;
          await _questionRepository.insert(
            Question(
              id: questionId,
              sourcePackId: contentPack.id,
              packLocalId: questionFile.id,
              prompt: questionFile.prompt,
              choicesJson: jsonEncode(questionFile.choices),
              correctChoiceIndex: questionFile.correctChoiceIndex,
              topicIds: questionFile.topicRefs
                  .map((ref) => topicIdByPackLocal[ref]!)
                  .toList(),
              explanation: questionFile.explanation,
              textbookReference: questionFile.textbookReference,
              examYearEc: questionFile.examYearEc,
              imageReference: questionFile.imageReference,
              graphReference: questionFile.graphReference,
              diagramReference: questionFile.diagramReference,
              tableReference: questionFile.tableReference,
            ),
          );
          questionIdByPackLocal[questionFile.id] = questionId;
        }
      }
    }

    // Phase 3 — exams (Decision 038: array order is the stored order).
    for (final examFile in pack.exams) {
      final examId = nextExamId++;
      await _examRepository.insert(
        Exam(
          id: examId,
          sourcePackId: contentPack.id,
          packLocalId: examFile.id,
          subjectId: subjectId,
          examYearEc: examFile.yearEc,
          questionIds: examFile.questionIds
              .map((ref) => questionIdByPackLocal[ref]!)
              .toList(),
          title: examFile.title,
          durationSeconds: examFile.durationSeconds,
        ),
      );
    }

    return contentPack;
  }
}

ResourceType _resourceType(String type) {
  return switch (type) {
    'note' => ResourceType.note,
    'flashcard' => ResourceType.flashcard,
    'mindmap' => ResourceType.mindmap,
    _ => throw ArgumentError.value(type, 'type', 'unknown resource type'),
  };
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
