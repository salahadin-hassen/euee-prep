import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/features/content/data/local_data_sources/content_pack_local_data_source.dart';
import 'package:euee_prep/features/content/data/local_data_sources/drift_import_transaction.dart';
import 'package:euee_prep/features/content/data/local_data_sources/exam_local_data_source.dart';
import 'package:euee_prep/features/content/data/local_data_sources/question_local_data_source.dart';
import 'package:euee_prep/features/content/data/repositories/content_pack_repository_impl.dart';
import 'package:euee_prep/features/content/data/repositories/exam_repository_impl.dart';
import 'package:euee_prep/features/content/data/repositories/question_repository_impl.dart';
import 'package:euee_prep/features/content/domain/models/content_pack_file.dart';
import 'package:euee_prep/features/content/domain/repositories/content_pack_repository.dart';
import 'package:euee_prep/features/content/domain/repositories/exam_repository.dart';
import 'package:euee_prep/features/content/domain/repositories/question_repository.dart';
import 'package:euee_prep/features/content/domain/services/content_import_checksum.dart';
import 'package:euee_prep/features/content/domain/services/content_import_service.dart';
import 'package:euee_prep/features/streams/data/local_data_sources/stream_local_data_source.dart';
import 'package:euee_prep/features/streams/data/repositories/stream_repository_impl.dart';
import 'package:euee_prep/features/streams/domain/models/stream_model.dart';
import 'package:euee_prep/features/streams/domain/repositories/stream_repository.dart';
import 'package:euee_prep/features/subjects/data/local_data_sources/subject_local_data_source.dart';
import 'package:euee_prep/features/subjects/data/repositories/subject_repository_impl.dart';
import 'package:euee_prep/features/subjects/domain/models/subject.dart';
import 'package:euee_prep/features/subjects/domain/repositories/subject_repository.dart';

const _fixturePath = 'test/features/content/fixtures/physics_euee_pack_v3.json';

void main() {
  late db.AppDatabase database;
  late ContentImportService service;
  late ContentPackRepository contentPackRepo;
  late StreamRepository streamRepo;
  late SubjectRepository subjectRepo;
  late QuestionRepository questionRepo;
  late ExamRepository examRepo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    contentPackRepo =
        ContentPackRepositoryImpl(ContentPackLocalDataSource(database));
    streamRepo = StreamRepositoryImpl(StreamLocalDataSource(database));
    subjectRepo = SubjectRepositoryImpl(SubjectLocalDataSource(database));
    questionRepo = QuestionRepositoryImpl(QuestionLocalDataSource(database));
    examRepo = ExamRepositoryImpl(ExamLocalDataSource(database));
    service = ContentImportService(
      contentPackRepository: contentPackRepo,
      streamRepository: streamRepo,
      subjectRepository: subjectRepo,
      questionRepository: questionRepo,
      examRepository: examRepo,
      transaction: DriftImportTransaction(database),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('successful import', () {
    test('imports the v3 fixture and creates every expected row', () async {
      final result = await service.import(_fixture());

      expect(result.isSuccess, isTrue);
      expect(result.alreadyImported, isFalse);
      expect(result.pack!.id, 'physics-2015-natural-science#1.0.0');
      expect(result.pack!.packKey, 'natural_science-physics');
      expect(result.pack!.schemaVersion, '3');

      final stream = await streamRepo.getBySlug('natural_science');
      expect(stream, isNotNull);
      final subject =
          await subjectRepo.getByStreamAndSlug(stream!.id, 'physics');
      expect(subject, isNotNull);
      expect(subject!.title, 'Physics');

      expect(await contentPackRepo.getAll(), hasLength(1));
      expect(await questionRepo.getAll(), hasLength(3));
      expect(await examRepo.getAll(), hasLength(1));
    });

    test('preserves question payload including choices and explanation',
        () async {
      await service.import(_fixture());

      final questions = await questionRepo.getAll();
      final q1 = questions.firstWhere((q) => q.packLocalId == 'physics-2015-natural-science-q1');
      expect(q1.prompt, contains('5 kg mass'));
      expect(jsonDecode(q1.choicesJson), ['5 N', '10 N', '15 N', '20 N']);
      expect(q1.correctChoiceIndex, 1);
      expect(q1.explanation, contains('F = ma'));
      expect(q1.topicIds, isEmpty);
    });

    test('preserves exam with correct year and question ordering', () async {
      await service.import(_fixture());

      final questions = await questionRepo.getAll();
      int idOf(String packLocalId) =>
          questions.firstWhere((q) => q.packLocalId == packLocalId).id;

      final exam = (await examRepo.getAll()).single;
      expect(exam.packLocalId, 'physics-2015-natural-science');
      expect(exam.examYearEc, 2015);
      expect(exam.title, 'EUEE Physics 2015');
      expect(
        exam.questionIds,
        [
          idOf('physics-2015-natural-science-q1'),
          idOf('physics-2015-natural-science-q2'),
          idOf('physics-2015-natural-science-q3'),
        ],
        reason: 'array order in the pack is stored order, never sorted',
      );
    });

    test('repositories can read every imported entity afterward', () async {
      await service.import(_fixture());

      expect(await contentPackRepo.getAll(), hasLength(1));
      expect(await questionRepo.getAll(), hasLength(3));
      expect(await examRepo.getAll(), hasLength(1));
      expect(await streamRepo.getAll(), hasLength(1));
      expect(await subjectRepo.getAll(), hasLength(1));
    });
  });

  group('validation', () {
    test('rejects a schema version this importer does not support', () async {
      final result = await service.import(_mutateFixture((map) {
        map['schema_version'] = '2';
      }));

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('schema_version'));
    });

    test('rejects an unknown stream value', () async {
      final result = await service.import(_mutateFixture((map) {
        map['stream'] = 'engineering';
      }));

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('stream'));
    });

    test('rejects duplicate question IDs', () async {
      final result = await service.import(_mutateFixture((map) {
        final questions = map['questions'] as List;
        questions.add({
          'id': 'physics-2015-natural-science-q1',
          'number': 4,
          'prompt': 'Duplicate question',
          'choices': ['A', 'B'],
          'correct_choice_index': 0,
        });
      }));

      expect(result.isSuccess, isFalse);
      expect(result.issues.map((i) => i.message).join('\n'),
          contains('duplicate'));
    });

    test('rejects an empty question prompt', () async {
      final result = await service.import(_mutateFixture((map) {
        (map['questions'] as List).first['prompt'] = '';
      }));

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('non-empty'));
    });

    test('rejects an out-of-range correct choice index', () async {
      final result = await service.import(_mutateFixture((map) {
        (map['questions'] as List).first['correct_choice_index'] = 99;
      }));

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('out of range'));
    });

    test('rejects a question with fewer than two choices', () async {
      final result = await service.import(_mutateFixture((map) {
        (map['questions'] as List).first['choices'] = ['Only one'];
        (map['questions'] as List).first['correct_choice_index'] = 0;
      }));

      expect(result.isSuccess, isFalse);
      expect(
        result.issues.any((i) => i.message.contains('at least two')),
        isTrue,
      );
    });

    test('rejects a mismatched question_count', () async {
      final result = await service.import(_mutateFixture((map) {
        map['paper'] = {'year': 2015, 'title': 'Test', 'question_count': 99};
      }));

      expect(result.isSuccess, isFalse);
      expect(result.issues.single.message, contains('question_count'));
    });

    test('rejects a malformed field (wrong type)', () async {
      final map = jsonDecode(_fixture()) as Map<String, dynamic>;
      map['questions'] = 'not-an-array';

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
      (map['questions'] as List).first['prompt'] = 'tampered prompt';

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

      expect(await contentPackRepo.getAll(), isEmpty);
      expect(await questionRepo.getAll(), isEmpty);
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
      expect(await questionRepo.getAll(), hasLength(3));
    });

    test('a newer pack version coexists with the older one', () async {
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

      expect(await streamRepo.getAll(), hasLength(1),
          reason: 'reference data is find-or-create, never duplicated');
      expect(await subjectRepo.getAll(), hasLength(1));
    });
  });

  group('cross-system import chain', () {
    test('imports a pack exported by Content Studio', () async {
      final result = await service.import(_readFile(_exportFixturePath));

      expect(
        result.isSuccess,
        isTrue,
        reason: result.issues.map((i) => i.message).join('\n'),
      );
      expect(result.alreadyImported, isFalse);
      expect(result.pack!.id, 'biology-2018-natural_science#1.0.0');
      expect(result.pack!.packKey, 'natural_science-biology');
      expect(result.pack!.schemaVersion, '3');

      expect(await contentPackRepo.getAll(), hasLength(1));
      expect(await questionRepo.getAll(), hasLength(4));
      expect(await examRepo.getAll(), hasLength(1));

      final exam = (await examRepo.getAll()).single;
      expect(exam.packLocalId, 'biology-2018-natural_science');
      expect(exam.examYearEc, 2018);
      expect(exam.questionIds, hasLength(4));
    });

    test('round-trips choices containing commas through the database',
        () async {
      await service.import(_readFile(_exportFixturePath));

      final questions = await questionRepo.getAll();
      final q2 = questions
          .firstWhere((q) => q.packLocalId == 'biology-2018-natural_science-q2');

      expect(
        jsonDecode(q2.choicesJson),
        [
          'It needs a concentration gradient, and carrier proteins',
          'It requires ATP directly',
          'It moves solutes against a gradient',
          'It occurs only in plant cells',
        ],
      );
      expect(q2.correctChoiceIndex, 0);
      expect(q2.prompt, contains('"facilitated diffusion"'));
    });

    test('keeps the reviewer draft explanation as the fallback', () async {
      await service.import(_readFile(_exportFixturePath));

      final questions = await questionRepo.getAll();
      final q3 = questions
          .firstWhere((q) => q.packLocalId == 'biology-2018-natural_science-q3');

      expect(q3.explanation, contains('10–20 µm'));
    });
  });
}

const _exportFixturePath =
    'content-studio/tests/fixtures/exported-content-pack-v3.json';

String _fixture() => File(_fixturePath).readAsStringSync();

String _readFile(String path) => File(path).readAsStringSync();

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
