import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// The application's local Drift database.
///
/// Schema changes are versioned explicitly. This first business schema adds
/// only the curriculum reference entities covered by Milestone 1, Task 1.
@DriftDatabase(tables: [Grades, Streams, Subjects])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For tests: allows injecting an in-memory connection instead of the
  /// real on-device file, per 07_CODING_STANDARDS.md's testing conventions
  /// ("no test should hit a real file-backed SQLite database").
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 2;

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

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'euee_prep.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
