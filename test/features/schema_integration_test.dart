import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/features/content/data/local_data_sources/chapter_local_data_source.dart';
import 'package:euee_prep/features/content/data/local_data_sources/content_pack_local_data_source.dart';
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
import 'package:euee_prep/features/content/domain/models/chapter.dart';
import 'package:euee_prep/features/content/domain/models/content_pack.dart';
import 'package:euee_prep/features/content/domain/models/exam.dart';
import 'package:euee_prep/features/content/domain/models/question.dart';
import 'package:euee_prep/features/content/domain/models/resource.dart';
import 'package:euee_prep/features/content/domain/models/topic.dart';
import 'package:euee_prep/features/grades/data/local_data_sources/grade_local_data_source.dart';
import 'package:euee_prep/features/grades/data/repositories/grade_repository_impl.dart';
import 'package:euee_prep/features/grades/domain/models/grade.dart';
import 'package:euee_prep/features/progress/data/local_data_sources/attempt_local_data_source.dart';
import 'package:euee_prep/features/progress/data/repositories/attempt_repository_impl.dart';
import 'package:euee_prep/features/progress/domain/models/attempt.dart';
import 'package:euee_prep/features/streams/data/local_data_sources/stream_local_data_source.dart';
import 'package:euee_prep/features/streams/data/repositories/stream_repository_impl.dart';
import 'package:euee_prep/features/streams/domain/models/stream_model.dart';
import 'package:euee_prep/features/subjects/data/local_data_sources/subject_local_data_source.dart';
import 'package:euee_prep/features/subjects/data/repositories/subject_repository_impl.dart';
import 'package:euee_prep/features/subjects/domain/models/subject.dart';

/// Integration test: seeds one subject's worth of Physics fixture data
/// (one chapter, two topics, multi-topic questions, one exam paper, resources,
/// and attempts) to prove the schema works end-to-end.
void main() {
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('full Physics fixture proves the schema end-to-end', () async {
    // --- Repositories ---
    final gradeRepo = GradeRepositoryImpl(GradeLocalDataSource(database));
    final streamRepo = StreamRepositoryImpl(StreamLocalDataSource(database));
    final subjectRepo = SubjectRepositoryImpl(SubjectLocalDataSource(database));
    final packRepo =
        ContentPackRepositoryImpl(ContentPackLocalDataSource(database));
    final chapterRepo = ChapterRepositoryImpl(ChapterLocalDataSource(database));
    final topicRepo = TopicRepositoryImpl(TopicLocalDataSource(database));
    final questionRepo =
        QuestionRepositoryImpl(QuestionLocalDataSource(database));
    final examRepo = ExamRepositoryImpl(ExamLocalDataSource(database));
    final resourceRepo =
        ResourceRepositoryImpl(ResourceLocalDataSource(database));
    final attemptRepo = AttemptRepositoryImpl(AttemptLocalDataSource(database));

    // --- 1. Seed reference data ---
    final grade11 = await gradeRepo.insert(
      const Grade(id: 1, level: 11),
    );
    final ns = await streamRepo.insert(
      const StreamModel(id: 1, slug: 'natural_science'),
    );
    final physics = await subjectRepo.insert(
      const Subject(
        id: 1,
        streamId: 1,
        slug: 'physics',
        title: 'Physics',
      ),
    );

    expect(grade11.level, 11);
    expect(ns.slug, 'natural_science');
    expect(physics.title, 'Physics');

    // --- 2. Seed content pack ---
    final pack = await packRepo.insert(
      const ContentPack(
        id: 'natural_science-physics#1.0.0',
        packKey: 'natural_science-physics',
        subjectId: 1,
        packVersion: '1.0.0',
        schemaVersion: '2',
        generatedAt: '2025-12-01T00:00:00Z',
        checksum: 'sha256:abc123',
        minimumAppVersion: '0.1.0',
        importedAt: '2026-01-15T08:00:00Z',
      ),
    );

    expect(pack.id, 'natural_science-physics#1.0.0');
    expect(pack.packKey, 'natural_science-physics');

    // --- 3. Seed chapter (scoped to Grade 11 + Physics) ---
    final chapter = await chapterRepo.insert(
      const Chapter(
        id: 1,
        subjectId: 1,
        gradeId: 1,
        sourcePackId: 'natural_science-physics#1.0.0',
        packLocalId: 'ch-mechanics-11',
        title: 'Mechanics',
        orderIndex: 1,
      ),
    );

    expect(chapter.subjectId, 1);
    expect(chapter.gradeId, 1);

    // --- 4. Seed topics within the chapter ---
    final newtonLaws = await topicRepo.insert(
      const Topic(
        id: 1,
        chapterId: 1,
        sourcePackId: 'natural_science-physics#1.0.0',
        packLocalId: 'topic-newton-laws',
        title: "Newton's Laws of Motion",
        orderIndex: 1,
      ),
    );
    final energy = await topicRepo.insert(
      const Topic(
        id: 2,
        chapterId: 1,
        sourcePackId: 'natural_science-physics#1.0.0',
        packLocalId: 'topic-energy-conservation',
        title: 'Energy Conservation',
        orderIndex: 2,
      ),
    );

    expect(newtonLaws.chapterId, 1);
    expect(energy.chapterId, 1);

    // --- 5. Seed questions (many-to-many with topics — Decision 011) ---
    // Question 1: tests only Newton's Laws
    final q1 = await questionRepo.insert(
      Question(
        id: 1,
        sourcePackId: 'natural_science-physics#1.0.0',
        packLocalId: 'q-newton-1',
        prompt: 'A 5kg object accelerates at 2 m/s². What is the net force?',
        choicesJson: '["5N","10N","15N","20N"]',
        correctChoiceIndex: 1,
        explanation: 'F = ma = 5 × 2 = 10N',
        topicIds: [1],
      ),
    );

    // Question 2: multi-topic — tests BOTH Newton's Laws AND Energy Conservation
    final q2 = await questionRepo.insert(
      Question(
        id: 2,
        sourcePackId: 'natural_science-physics#1.0.0',
        packLocalId: 'q-multi-1',
        prompt:
            'A ball is dropped from 10m. Using energy conservation, what is its velocity at ground level?',
        choicesJson: '["10 m/s","14 m/s","20 m/s","98 m/s"]',
        correctChoiceIndex: 1,
        explanation: 'mgh = ½mv² → v = √(2gh) ≈ 14 m/s',
        examYearEc: 2015,
        topicIds: [1, 2],
      ),
    );

    // Question 3: tests only Energy Conservation
    final q3 = await questionRepo.insert(
      Question(
        id: 3,
        sourcePackId: 'natural_science-physics#1.0.0',
        packLocalId: 'q-energy-1',
        prompt:
            'Which principle explains why a pendulum returns to its original height?',
        choicesJson:
            '["Inertia","Conservation of energy","Newton\'s third law","Friction"]',
        correctChoiceIndex: 1,
        explanation: 'Energy is conserved in an ideal pendulum.',
        topicIds: [2],
      ),
    );

    expect(q1.topicIds, [1]);
    expect(q2.topicIds, [1, 2]);
    expect(q3.topicIds, [2]);

    // Verify the many-to-many mapping
    final allQuestions = await questionRepo.getAll();
    expect(allQuestions, hasLength(3));

    // --- 6. Seed exam (Decision 038 — ordered question membership) ---
    final exam = await examRepo.insert(
      Exam(
        id: 1,
        sourcePackId: 'natural_science-physics#1.0.0',
        packLocalId: 'exam-physics-2015',
        subjectId: 1,
        examYearEc: 2015,
        title: 'EUEE Physics 2015',
        durationSeconds: 12600,
        questionIds: [1, 2, 3],
      ),
    );

    expect(exam.examYearEc, 2015);
    expect(exam.questionIds, [1, 2, 3]);
    expect(exam.durationSeconds, 12600);

    // Verify exam questions are returned in order
    final exams = await examRepo.getAll();
    expect(exams, hasLength(1));
    expect(exams.single.questionIds, [1, 2, 3]);

    // --- 7. Seed resources (notes, flashcards — Decision 011 scope, 037) ---
    final note = await resourceRepo.insert(
      Resource(
        id: 1,
        topicId: 1,
        sourcePackId: 'natural_science-physics#1.0.0',
        packLocalId: 'res-newton-note',
        type: ResourceType.note,
        title: "Newton's Laws Summary",
        content:
            "# Newton's Laws\n\n1. First Law (Inertia)\n2. Second Law (F=ma)\n3. Third Law (Action-Reaction)",
        orderIndex: 0,
      ),
    );
    final flashcard = await resourceRepo.insert(
      Resource(
        id: 2,
        topicId: 2,
        sourcePackId: 'natural_science-physics#1.0.0',
        packLocalId: 'res-energy-flashcard',
        type: ResourceType.flashcard,
        title: 'Energy Types',
        content: '{"front":"What is kinetic energy?","back":"½mv²"}',
        orderIndex: 0,
      ),
    );
    final mindmap = await resourceRepo.insert(
      Resource(
        id: 3,
        topicId: 1,
        sourcePackId: 'natural_science-physics#1.0.0',
        packLocalId: 'res-newton-mindmap',
        type: ResourceType.mindmap,
        title: "Newton's Laws Mind Map",
        content:
            "# Newton's Laws Mind Map\n\n- First Law\n  - Inertia\n  - Rest/motion\n- Second Law\n  - F=ma\n  - Acceleration\n- Third Law\n  - Action-reaction\n  - Pairs",
        orderIndex: 1,
      ),
    );

    expect(note.type, ResourceType.note);
    expect(flashcard.type, ResourceType.flashcard);
    expect(mindmap.type, ResourceType.mindmap);

    // Verify resources by topic
    final topic1Resources = await resourceRepo.getByTopicId(1);
    final topic2Resources = await resourceRepo.getByTopicId(2);
    expect(topic1Resources, hasLength(2));
    expect(topic2Resources, hasLength(1));
    expect(topic1Resources[0].type, ResourceType.note);
    expect(topic1Resources[1].type, ResourceType.mindmap);
    expect(topic2Resources.single.type, ResourceType.flashcard);

    // --- 8. Seed attempts (Decision 016 — append-only) ---
    final attempt1 = await attemptRepo.insert(
      const Attempt(
        id: 1,
        questionId: 1,
        selectedChoiceIndex: 1,
        isCorrect: true,
        attemptedAt: '2026-02-01T10:00:00Z',
        mode: 'practice',
        subjectId: 1,
        chapterId: 1,
      ),
    );
    final attempt2 = await attemptRepo.insert(
      const Attempt(
        id: 2,
        questionId: 2,
        selectedChoiceIndex: 0,
        isCorrect: false,
        attemptedAt: '2026-02-01T10:05:00Z',
        mode: 'practice',
        subjectId: 1,
        chapterId: 1,
      ),
    );
    await attemptRepo.insert(
      const Attempt(
        id: 3,
        questionId: 3,
        selectedChoiceIndex: 1,
        isCorrect: true,
        attemptedAt: '2026-02-01T10:10:00Z',
        mode: 'practice',
        subjectId: 1,
        chapterId: 1,
      ),
    );

    // Simulation attempt (exam mode)
    final simAttempt = await attemptRepo.insert(
      const Attempt(
        id: 4,
        questionId: 1,
        selectedChoiceIndex: 2,
        isCorrect: false,
        attemptedAt: '2026-02-02T14:00:00Z',
        mode: 'simulation',
        durationSeconds: 120,
        subjectId: 1,
        chapterId: 1,
        examId: 1,
      ),
    );

    expect(attempt1.isCorrect, isTrue);
    expect(attempt2.isCorrect, isFalse);
    expect(simAttempt.mode, 'simulation');
    expect(simAttempt.examId, 1);

    // Verify multiple attempts for same question
    final q1Attempts = await attemptRepo.getByQuestionId(1);
    expect(q1Attempts, hasLength(2));

    // Verify all attempts are returned
    final allAttempts = await attemptRepo.getAll();
    expect(allAttempts, hasLength(4));

    // --- 9. Verify FK integrity: old pack version's questions remain readable ---
    // (Decision 035 — attempts reference questions by stable identity)
    final q1Again = (await questionRepo.getAll()).firstWhere((q) => q.id == 1);
    expect(q1Again.prompt, contains('5kg'));

    // --- 10. Verify pack version lookup ---
    final latestPack =
        await packRepo.getLatestForPackKey('natural_science-physics');
    expect(latestPack, isNotNull);
    expect(latestPack!.id, 'natural_science-physics#1.0.0');

    // --- 11. Verify no updated_at/is_deleted on attempts ---
    final columns =
        await database.customSelect('PRAGMA table_info(attempts)').get();
    final columnNames = columns.map((row) => row.read<String>('name')).toSet();
    expect(columnNames, isNot(contains('updated_at')));
    expect(columnNames, isNot(contains('is_deleted')));

    // --- 12. Verify all indexes exist ---
    final indexes = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type='index'")
        .get();
    final indexNames = indexes.map((row) => row.read<String>('name')).toSet();
    expect(indexNames, contains('idx_attempts_question_id'));
    expect(indexNames, contains('idx_attempts_attempted_at'));
    expect(indexNames, contains('idx_attempts_subject_id'));
    expect(indexNames, contains('idx_attempts_chapter_id'));
    expect(indexNames, contains('idx_attempts_exam_id'));
  });
}
