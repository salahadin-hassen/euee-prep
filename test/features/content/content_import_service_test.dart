import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/features/content/data/local_data_sources/chapter_local_data_source.dart';
import 'package:euee_prep/features/content/data/local_data_sources/content_pack_local_data_source.dart';
import 'package:euee_prep/features/content/data/local_data_sources/drift_import_transaction.dart';
import 'package:euee_prep/features/content/data/local_data_sources/exam_local_data_source.dart';
import 'package:euee_prep/features/content/data/local_data_sources/question_local_data_source.dart';
import 'package:euee_prep/features/content/data/local_data_sources/resource_local_data_source.dart';
import 'package:euee_prep/features/content/data/local_data_sources/topic_local_data_source.dart';
import 'package:euee_prep/features/content/data/repositories/chapter_repository_impl.dart';
import 'package:euee_prep/features/content/data/repositories/content_pack_repository_impl.dart';
import 'package:euee_prep/features/content/data/repositories/exam_repository_impl.dart';
import 'package:euee_prep/features/content/data/repositories/question_repository_impl.dart';
import 'package:euee_prep/features/content/data/repositories/resource_repository_impl.dart';
import 'package:euee_prep/features/content/data/repositories/topic_repository_impl.dart';
import 'package:euee_prep/features/content/domain/models/content_pack_file.dart';
import 'package:euee_prep/features/content/domain/models/resource.dart';
import 'package:euee_prep/features/content/domain/repositories/chapter_repository.dart';
import 'package:euee_prep/features/content/domain/repositories/content_pack_repository.dart';
import 'package:euee_prep/features/content/domain/repositories/exam_repository.dart';
import 'package:euee_prep/features/content/domain/repositories/question_repository.dart';
import 'package:euee_prep/features/content/domain/repositories/resource_repository.dart';
import 'package:euee_prep/features/content/domain/repositories/topic_repository.dart';
import 'package:euee_prep/features/content/domain/services/content_import_checksum.dart';
import 'package:euee_prep/features/content/domain/services/content_import_service.dart';
import 'package:euee_prep/features/grades/data/local_data_sources/grade_local_data_source.dart';
import 'package:euee_prep/features/grades/data/repositories/grade_repository_impl.dart';
import 'package:euee_prep/features/grades/domain/repositories/grade_repository.dart';
import 'package:euee_prep/features/streams/data/local_data_sources/stream_local_data_source.dart';
import 'package:euee_prep/features/streams/data/repositories/stream_repository_impl.dart';
import 'package:euee_prep/features/streams/domain/models/stream_model.dart';
import 'package:euee_prep/features/streams/domain/repositories/stream_repository.dart';
import 'package:euee_prep/features/subjects/data/local_data_sources/subject_local_data_source.dart';
import 'package:euee_prep/features/subjects/data/repositories/subject_repository_impl.dart';
import 'package:euee_prep/features/subjects/domain/models/subject.dart';
import 'package:euee_prep/features/subjects/domain/repositories/subject_repository.dart';

const _fixturePath = 'test/features/content/fixtures/physics_euee_pack_v1.json';

void main() {
  late db.AppDatabase database;
  late ContentImportService service;
  late ContentPackRepository contentPackRepo;
  late GradeRepository gradeRepo;
  late StreamRepository streamRepo;
  late SubjectRepository subjectRepo;
  late ChapterRepository chapterRepo;
  late TopicRepository topicRepo;
  late QuestionRepository questionRepo;
  late ExamRepository examRepo;
  late ResourceRepository resourceRepo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    contentPackRepo =
        ContentPackRepositoryImpl(ContentPackLocalDataSource(database));
    gradeRepo = GradeRepositoryImpl(GradeLocalDataSource(database));
    streamRepo = StreamRepositoryImpl(StreamLocalDataSource(database));
    subjectRepo = SubjectRepositoryImpl(SubjectLocalDataSource(database));
    chapterRepo = ChapterRepositoryImpl(ChapterLocalDataSource(database));
    topicRepo = TopicRepositoryImpl(TopicLocalDataSource(database));
    questionRepo = QuestionRepositoryImpl(QuestionLocalDataSource(database));
    examRepo = ExamRepositoryImpl(ExamLocalDataSource(database));
    resourceRepo = ResourceRepositoryImpl(ResourceLocalDataSource(database));
    service = ContentImportService(
      contentPackRepository: contentPackRepo,
      gradeRepository: gradeRepo,
      streamRepository: streamRepo,
      subjectRepository: subjectRepo,
      chapterRepository: chapterRepo,
      topicRepository: topicRepo,
      questionRepository: questionRepo,
      examRepository: examRepo,
      resourceRepository: resourceRepo,
      transaction: DriftImportTransaction(database),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('successful import', () {
    test('imports the full fixture and creates every expected row', () async {
      final result = await service.import(_fixture());

      expect(result.isSuccess, isTrue);
      expect(result.alreadyImported, isFalse);
      expect(result.pack!.id, 'natural_science-physics#1.0.0');
      expect(result.pack!.packKey, 'natural_science-physics');
      expect(result.pack!.schemaVersion, '2');

      expect((await gradeRepo.getAll()).map((g) => g.level), [11]);
      final stream = await streamRepo.getBySlug('natural_science');
      expect(stream, isNotNull);
      final subject =
          await subjectRepo.getByStreamAndSlug(stream!.id, 'physics');
      expect(subject, isNotNull);
      expect(subject!.title, 'Physics');

      expect(await contentPackRepo.getAll(), hasLength(1));
      expect(await chapterRepo.getAll(), hasLength(1));
      expect(await topicRepo.getAll(), hasLength(2));
      expect(await questionRepo.getAll(), hasLength(3));
      expect(await resourceRepo.getAll(), hasLength(3));
      expect(await examRepo.getAll(), hasLength(1));
    });

    test('preserves chapter, topic, resource, and question relationships',
        () async {
      await service.import(_fixture());

      final subject = (await subjectRepo.getAll()).single;
      final grade = (await gradeRepo.getAll()).single;
      final chapter = (await chapterRepo.getAll()).single;
      expect(chapter.subjectId, subject.id);
      expect(chapter.gradeId, grade.id);
      expect(chapter.packLocalId, 'ch-mechanics-11');
      expect(chapter.sourcePackId, 'natural_science-physics#1.0.0');

      final topics = await topicRepo.getAll();
      final newton = topics.firstWhere((t) => t.packLocalId == 't-newton-laws');
      final energy =
          topics.firstWhere((t) => t.packLocalId == 't-energy-conservation');
      expect(newton.chapterId, chapter.id);
      expect(energy.chapterId, chapter.id);
      expect(newton.orderIndex, 0);
      expect(energy.orderIndex, 1);

      final resources = await resourceRepo.getAll();
      final note =
          resources.firstWhere((r) => r.packLocalId == 'res-newton-note');
      final flashcard =
          resources.firstWhere((r) => r.packLocalId == 'res-newton-flashcard');
      final mindmap =
          resources.firstWhere((r) => r.packLocalId == 'res-energy-mindmap');
      expect(note.topicId, newton.id);
      expect(flashcard.topicId, newton.id);
      expect(mindmap.topicId, energy.id);
    });

    test('preserves question-topic many-to-many mapping', () async {
      await service.import(_fixture());

      final topics = await topicRepo.getAll();
      final newton = topics.firstWhere((t) => t.packLocalId == 't-newton-laws');
      final energy =
          topics.firstWhere((t) => t.packLocalId == 't-energy-conservation');

      final questions = await questionRepo.getAll();
      final qNewton =
          questions.firstWhere((q) => q.packLocalId == 'q-newton-1');
      final qNewtonEnergy =
          questions.firstWhere((q) => q.packLocalId == 'q-newton-energy-1');
      final qEnergy =
          questions.firstWhere((q) => q.packLocalId == 'q-energy-1');

      expect(qNewton.topicIds, [newton.id]);
      expect(qNewtonEnergy.topicIds.toSet(), {newton.id, energy.id});
      expect(qEnergy.topicIds, [energy.id]);
    });

    test('preserves question payload including choices and explanation',
        () async {
      await service.import(_fixture());

      final qNewton = (await questionRepo.getAll())
          .firstWhere((q) => q.packLocalId == 'q-newton-1');
      expect(qNewton.prompt, contains('5 kg mass'));
      expect(jsonDecode(qNewton.choicesJson), ['5 N', '10 N', '15 N', '20 N']);
      expect(qNewton.correctChoiceIndex, 1);
      expect(qNewton.explanation, contains('F = ma'));
      expect(qNewton.textbookReference, 'Physics Grade 11, Unit 2');
      expect(qNewton.examYearEc, 2015);
    });

    test('preserves exam question ordering as declared (Decision 038)',
        () async {
      await service.import(_fixture());

      final questions = await questionRepo.getAll();
      int idOf(String packLocalId) =>
          questions.firstWhere((q) => q.packLocalId == packLocalId).id;

      final exam = (await examRepo.getAll()).single;
      expect(exam.packLocalId, 'exam-physics-2015-ec');
      expect(exam.examYearEc, 2015);
      expect(exam.durationSeconds, 12600);
      expect(
        exam.questionIds,
        [
          idOf('q-energy-1'),
          idOf('q-newton-1'),
          idOf('q-newton-energy-1'),
        ],
        reason: 'array order in the pack is stored order, never sorted',
      );
    });

    test('links resources to their topics with correct types', () async {
      await service.import(_fixture());

      final topics = await topicRepo.getAll();
      final newton = topics.firstWhere((t) => t.packLocalId == 't-newton-laws');
      final energy =
          topics.firstWhere((t) => t.packLocalId == 't-energy-conservation');

      final newtonResources = await resourceRepo.getByTopicId(newton.id);
      final energyResources = await resourceRepo.getByTopicId(energy.id);

      expect(newtonResources, hasLength(2));
      expect(newtonResources[0].type, ResourceType.note);
      expect(newtonResources[0].orderIndex, 0);
      expect(newtonResources[1].type, ResourceType.flashcard);
      expect(newtonResources[1].orderIndex, 1);
      expect(energyResources, hasLength(1));
      expect(energyResources.single.type, ResourceType.mindmap);
    });

    test('repositories can read every imported entity afterward', () async {
      await service.import(_fixture());

      expect(await gradeRepo.getAll(), hasLength(1));
      expect(await streamRepo.getAll(), hasLength(1));
      expect(await subjectRepo.getAll(), hasLength(1));
      expect(await contentPackRepo.getAll(), hasLength(1));
      expect(await chapterRepo.getAll(), hasLength(1));
      expect(await topicRepo.getAll(), hasLength(2));
      expect(await questionRepo.getAll(), hasLength(3));
      expect(await examRepo.getAll(), hasLength(1));
      expect(await resourceRepo.getAll(), hasLength(3));
    });
  });

  group('validation', () {
    test('rejects a schema version this importer does not support', () async {
      final result = await service.import(_mutateFixture((map) {
        map['schema_version'] = '3';
      }));

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('schema_version'));
      expect(await chapterRepo.getAll(), isEmpty);
    });

    test('rejects an unknown stream value', () async {
      final result = await service.import(_mutateFixture((map) {
        map['stream'] = 'engineering';
      }));

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('stream'));
    });

    test('rejects an invalid chapter grade', () async {
      final result = await service.import(_mutateFixture((map) {
        (map['chapters'] as List).first['grade'] = 8;
      }));

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('grade'));
    });

    test('rejects an invalid resource type (Decision 037)', () async {
      final result = await service.import(_mutateFixture((map) {
        final topic = (map['chapters'] as List).first['topics'] as List;
        (topic[0] as Map)['resources'][0]['type'] = 'article';
      }));

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('invalid type'));
    });

    test('rejects duplicate pack-local ids', () async {
      final result = await service.import(_mutateFixture((map) {
        final topics = (map['chapters'] as List).first['topics'] as List;
        topics.add({
          'id': 't-newton-laws',
          'title': 'Duplicate Topic',
          'order_index': 2,
          'questions': <Object>[],
          'resources': <Object>[],
        });
      }));

      expect(result.isSuccess, isFalse);
      expect(result.issues.map((i) => i.message).join('\n'),
          contains('duplicate'));
      expect(await chapterRepo.getAll(), isEmpty);
    });

    test('rejects a broken topic reference', () async {
      final result = await service.import(_mutateFixture((map) {
        final topic = (map['chapters'] as List).first['topics'] as List;
        (topic[0] as Map)['questions'][0]['topic_refs'] = ['t-missing'];
      }));

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('unknown topic'));
    });

    test('rejects a broken exam question reference', () async {
      final result = await service.import(_mutateFixture((map) {
        (map['exams'] as List).first['question_ids'] = ['q-missing'];
      }));

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('unknown question'));
    });

    test('rejects duplicate question membership inside an exam', () async {
      final result = await service.import(_mutateFixture((map) {
        (map['exams'] as List).first['question_ids'] = [
          'q-newton-1',
          'q-newton-1',
        ];
      }));

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('more than once'));
    });

    test('rejects two exams for the same subject and EC year (Decision 038)',
        () async {
      final result = await service.import(_mutateFixture((map) {
        final exams = map['exams'] as List;
        final first = exams.first as Map<String, dynamic>;
        exams.add({...first, 'id': 'exam-physics-2015-b'});
      }));

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('one paper per'));
    });

    test('rejects an empty question prompt', () async {
      final result = await service.import(_mutateFixture((map) {
        final topic = (map['chapters'] as List).first['topics'] as List;
        (topic[0] as Map)['questions'][0]['prompt'] = '';
      }));

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('non-empty'));
    });

    test('rejects an out-of-range correct choice index', () async {
      final result = await service.import(_mutateFixture((map) {
        final topic = (map['chapters'] as List).first['topics'] as List;
        (topic[0] as Map)['questions'][0]['correct_choice_index'] = 99;
      }));

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('out of range'));
    });

    test('rejects a malformed field (wrong type)', () async {
      final map = jsonDecode(_fixture()) as Map<String, dynamic>;
      map['chapters'] = 'not-an-array';

      final result = await service.import(jsonEncode(map));

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('must be an array'));
    });

    test('rejects malformed JSON', () async {
      final result = await service.import('{ this is not json');

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('JSON'));
    });

    test('rejects a checksum mismatch', () async {
      final map = jsonDecode(_fixture()) as Map<String, dynamic>;
      final topic = (map['chapters'] as List).first['topics'] as List;
      (topic[0] as Map)['questions'][0]['prompt'] = 'tampered prompt';

      final result = await service.import(jsonEncode(map));

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('checksum'));
    });

    test('rejects a pack whose minimum_app_version exceeds the app version',
        () async {
      final result = await service.import(_mutateFixture((map) {
        map['minimum_app_version'] = '9.9.9';
      }));

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('app version'));
    });
  });

  group('immutability and coexistence', () {
    test('a failed import leaves the database unchanged', () async {
      await streamRepo.insert(
        const StreamModel(id: 1, slug: 'natural_science'),
      );
      await subjectRepo.insert(
        const Subject(
          id: 1,
          streamId: 1,
          slug: 'physics',
          title: 'Wrong Title',
        ),
      );

      final result = await service.import(_fixture());

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('title changed'));

      expect(await gradeRepo.getAll(), isEmpty,
          reason:
              'grade 11 was created inside the transaction and rolled back');
      expect(await contentPackRepo.getAll(), isEmpty);
      expect(await chapterRepo.getAll(), isEmpty);
      expect(await topicRepo.getAll(), isEmpty);
      expect(await questionRepo.getAll(), isEmpty);
      expect(await resourceRepo.getAll(), isEmpty);
      expect(await examRepo.getAll(), isEmpty);
      expect((await subjectRepo.getAll()).single.title, 'Wrong Title');
    });

    test('re-importing an already-existing pack/version is a no-op', () async {
      final first = await service.import(_fixture());
      expect(first.isSuccess, isTrue);

      final second = await service.import(_fixture());

      expect(second.isSuccess, isTrue);
      expect(second.alreadyImported, isTrue);
      expect(await contentPackRepo.getAll(), hasLength(1));
      expect(await chapterRepo.getAll(), hasLength(1));
      expect(await questionRepo.getAll(), hasLength(3));
    });

    test('a newer pack version coexists with the older one (Decision 034)',
        () async {
      final first = await service.import(_fixture());
      expect(first.isSuccess, isTrue);

      final second = await service.import(_reversionedFixture('1.1.0'));

      expect(second.isSuccess, isTrue);
      expect(second.alreadyImported, isFalse);
      expect(await contentPackRepo.getAll(), hasLength(2));
      expect(
          (await contentPackRepo.getLatestForPackKey('natural_science-physics'))
              ?.packVersion,
          '1.1.0');
      expect(await chapterRepo.getAll(), hasLength(2));

      expect(await streamRepo.getAll(), hasLength(1),
          reason: 'reference data is find-or-create, never duplicated');
      expect(await subjectRepo.getAll(), hasLength(1));
    });
  });
}

String _fixture() => File(_fixturePath).readAsStringSync();

/// Applies [change] to the fixture, then re-signs it so the checksum stays
/// valid — the test targets the mutation, not the checksum.
String _mutateFixture(void Function(Map<String, dynamic> map) change) {
  final map = jsonDecode(_fixture()) as Map<String, dynamic>;
  change(map);
  return _resigned(map);
}

String _reversionedFixture(String packVersion) {
  final map = jsonDecode(_fixture()) as Map<String, dynamic>;
  map['pack_version'] = packVersion;
  return _resigned(map);
}

String _resigned(Map<String, dynamic> map) {
  map['checksum'] = '';
  final pack = ContentPackFile.fromJson(map);
  map['checksum'] = ContentChecksum.compute(pack);
  return jsonEncode(map);
}
