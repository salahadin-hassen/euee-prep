import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // In-memory connection per 07_CODING_STANDARDS.md: no test should hit
    // a real file-backed SQLite database.
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('database opens and reports the expected schema version', () async {
    // Executing any query forces the connection (and migration) to run.
    await database.customSelect('SELECT 1').get();

    expect(database.schemaVersion, 1);
  });

  test('database currently defines no business tables', () {
    // Deliberate assertion for this task's scope (Milestone 0, Task 8):
    // if this ever fails because someone added a table here, it should
    // fail loudly — table additions belong to Milestone 1/2, each as its
    // own commit, not silently folded into the scaffold.
    expect(database.allTables, isEmpty);
  });
}
