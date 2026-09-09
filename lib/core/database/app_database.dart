import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// The application's local Drift database.
///
/// Schema changes are versioned explicitly. Content-pack metadata is stored
/// before content tables so their source-pack foreign keys remain valid.
@DriftDatabase(
  tables: [
    Grades,
    Streams,
    Subjects,
    ContentPacks,
    Chapters,
    Topics,
    Questions,
    QuestionTopics,
    Exams,
    ExamQuestions,
    Resources,
    Attempts,
    InstallIdentities,
    Entitlements,
    PaymentRequests,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For tests: allows injecting an in-memory connection instead of the
  /// real on-device file, per 07_CODING_STANDARDS.md's testing conventions
  /// ("no test should hit a real file-backed SQLite database").
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(grades);
            await m.createTable(streams);
            await m.createTable(subjects);
          }
          if (from < 3) {
            await m.createTable(contentPacks);
          }
          if (from < 4) {
            await m.createTable(chapters);
            await m.createTable(topics);
          }
          if (from < 5) {
            await m.createTable(questions);
            await m.createTable(questionTopics);
          }
          if (from < 6) {
            await m.createTable(exams);
            await m.createTable(examQuestions);
          }
          if (from < 7) {
            await m.createTable(resources);
          }
          if (from < 8) {
            await m.createTable(attempts);
          }
          if (from < 9) {
            await m.createTable(installIdentities);
            await customStatement(
              "CREATE UNIQUE INDEX IF NOT EXISTS install_identity_singleton ON install_identities (id) WHERE id = 1",
            );
          }
          if (from < 10) {
            await m.createTable(entitlements);
          }
          if (from < 11) {
            await m.createTable(paymentRequests);
          }
          if (from < 12) {
            await m.createTable(settings);
          }
        },
      );
}

class Grades extends Table {
  IntColumn get id => integer()();

  IntColumn get level => integer().unique()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Streams extends Table {
  IntColumn get id => integer()();

  TextColumn get slug => text().unique()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Subjects extends Table {
  IntColumn get id => integer()();

  IntColumn get streamId => integer().references(Streams, #id)();

  TextColumn get slug => text()();

  TextColumn get title => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {streamId, slug},
      ];
}

class ContentPacks extends Table {
  TextColumn get id => text()();

  TextColumn get packKey => text()();

  IntColumn get subjectId => integer().references(Subjects, #id)();

  TextColumn get packVersion => text()();

  TextColumn get schemaVersion => text()();

  TextColumn get generatedAt => text()();

  TextColumn get checksum => text()();

  TextColumn get minimumAppVersion => text()();

  TextColumn get importedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {packKey, packVersion},
      ];
}

@TableIndex(name: 'idx_chapters_subject_grade', columns: {#subjectId, #gradeId})
class Chapters extends Table {
  IntColumn get id => integer()();

  IntColumn get subjectId => integer().references(Subjects, #id)();

  IntColumn get gradeId => integer().references(Grades, #id)();

  TextColumn get sourcePackId => text().references(ContentPacks, #id)();

  TextColumn get packLocalId => text()();

  TextColumn get title => text()();

  IntColumn get orderIndex => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {sourcePackId, packLocalId},
      ];
}

@TableIndex(name: 'idx_topics_chapter_id', columns: {#chapterId})
class Topics extends Table {
  IntColumn get id => integer()();

  IntColumn get chapterId => integer().references(Chapters, #id)();

  TextColumn get sourcePackId => text().references(ContentPacks, #id)();

  TextColumn get packLocalId => text()();

  TextColumn get title => text()();

  IntColumn get orderIndex => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {sourcePackId, packLocalId},
      ];
}

@TableIndex(name: 'idx_questions_source_pack', columns: {#sourcePackId})
class Questions extends Table {
  IntColumn get id => integer()();

  TextColumn get sourcePackId => text().references(ContentPacks, #id)();

  TextColumn get packLocalId => text()();

  TextColumn get prompt => text()();

  TextColumn get choicesJson => text()();

  IntColumn get correctChoiceIndex => integer()();

  TextColumn get explanation => text().nullable()();

  TextColumn get textbookReference => text().nullable()();

  IntColumn get examYearEc => integer().nullable()();

  TextColumn get imageReference => text().nullable()();

  TextColumn get graphReference => text().nullable()();

  TextColumn get diagramReference => text().nullable()();

  TextColumn get tableReference => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {sourcePackId, packLocalId},
      ];
}

@TableIndex(name: 'idx_question_topics_topic', columns: {#topicId})
class QuestionTopics extends Table {
  IntColumn get questionId => integer().references(Questions, #id)();

  IntColumn get topicId => integer().references(Topics, #id)();

  @override
  Set<Column<Object>> get primaryKey => {questionId, topicId};
}

@TableIndex(name: 'idx_exams_subject_year', columns: {#subjectId, #examYearEc})
class Exams extends Table {
  IntColumn get id => integer()();

  TextColumn get sourcePackId => text().references(ContentPacks, #id)();

  TextColumn get packLocalId => text()();

  IntColumn get subjectId => integer().references(Subjects, #id)();

  IntColumn get examYearEc => integer()();

  TextColumn get title => text().nullable()();

  IntColumn get durationSeconds => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {sourcePackId, packLocalId},
        {sourcePackId, subjectId, examYearEc},
      ];
}

@TableIndex(name: 'idx_exam_questions_question', columns: {#questionId})
class ExamQuestions extends Table {
  IntColumn get examId => integer().references(Exams, #id)();

  IntColumn get questionId => integer().references(Questions, #id)();

  IntColumn get orderIndex => integer()();

  @override
  Set<Column<Object>> get primaryKey => {examId, questionId};
}

@TableIndex(name: 'idx_resources_topic_id', columns: {#topicId})
class Resources extends Table {
  IntColumn get id => integer()();

  IntColumn get topicId => integer().references(Topics, #id)();

  TextColumn get sourcePackId => text().references(ContentPacks, #id)();

  TextColumn get packLocalId => text()();

  TextColumn get type => text()();

  TextColumn get title => text().nullable()();

  TextColumn get content => text()();

  IntColumn get orderIndex => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {sourcePackId, packLocalId},
      ];
}

// -- Attempts: append-only, no update/delete (Decision 016)
@TableIndex(name: 'idx_attempts_question_id', columns: {#questionId})
@TableIndex(name: 'idx_attempts_attempted_at', columns: {#attemptedAt})
@TableIndex(name: 'idx_attempts_subject_id', columns: {#subjectId})
@TableIndex(name: 'idx_attempts_chapter_id', columns: {#chapterId})
@TableIndex(name: 'idx_attempts_exam_id', columns: {#examId})
class Attempts extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get questionId => integer().references(Questions, #id)();

  IntColumn get selectedChoiceIndex => integer()();

  IntColumn get isCorrect => integer()();

  TextColumn get attemptedAt => text()();

  TextColumn get mode => text().nullable()();

  IntColumn get durationSeconds => integer().nullable()();

  IntColumn get subjectId => integer().references(Subjects, #id).nullable()();

  IntColumn get chapterId => integer().references(Chapters, #id).nullable()();

  IntColumn get examId => integer().references(Exams, #id).nullable()();
}

// -- Install identity: singleton row (Decision 032; CHECK(id=1) enforced via migration)
class InstallIdentities extends Table {
  IntColumn get id => integer()();

  TextColumn get installId => text().unique()();

  TextColumn get createdAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// -- Entitlement: server-authoritative, cached locally (Decisions 017, 033)
// Sync direction is server → device only.
@TableIndex(name: 'idx_entitlements_install', columns: {#installId, #streamId})
class Entitlements extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get installId =>
      text().references(InstallIdentities, #installId)();

  IntColumn get streamId => integer().references(Streams, #id)();

  TextColumn get status => text()();

  TextColumn get grantedAt => text()();

  TextColumn get revokedAt => text().nullable()();

  TextColumn get sourcePaymentRequestId =>
      text().nullable().references(PaymentRequests, #requestId)();
}

// -- PaymentRequest: server-authoritative, cached locally (Decisions 013, 017, 023, 036)
// request_id is the canonical identifier (Decision 023).
// Exactly three persisted states: 'pending' | 'verified' | 'rejected' (Decision 036).
@TableIndex(name: 'idx_payment_requests_install', columns: {#installId})
class PaymentRequests extends Table {
  TextColumn get requestId => text()();

  TextColumn get installId =>
      text().references(InstallIdentities, #installId)();

  IntColumn get streamId => integer().references(Streams, #id)();

  TextColumn get proofType => text()();

  TextColumn get proofValue => text()();

  TextColumn get status => text()();

  TextColumn get rejectionReason => text().nullable()();

  TextColumn get submittedAt => text()();

  TextColumn get verifiedAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {requestId};
}

// -- Settings: simple key-value store for local-only preferences (Decision 017)
// Install identity is NOT here — it lives in install_identity (Decision 032).
class Settings extends Table {
  TextColumn get key => text()();

  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'euee_prep.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// Minimal settings helpers — reads/writes the local `settings` key-value
/// table (Decision 017 — local-only, never synced). Kept as free functions
/// on AppDatabase to avoid a separate feature module for two queries.
extension SettingsQueries on AppDatabase {
  Future<String?> getSetting(String key) async {
    final row = await (select(settings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(key: key, value: value),
    );
  }
}
