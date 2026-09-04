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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For tests: allows injecting an in-memory connection instead of the
  /// real on-device file, per 07_CODING_STANDARDS.md's testing conventions
  /// ("no test should hit a real file-backed SQLite database").
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 5;

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

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'euee_prep.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
