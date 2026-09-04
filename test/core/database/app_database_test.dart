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

    expect(database.schemaVersion, 3);
  });

  test('database defines the current foundation tables', () {
    final tableNames =
        database.allTables.map((table) => table.actualTableName).toSet();

    expect(tableNames, {
      'grades',
      'streams',
      'subjects',
      'content_packs',
    });
  });
}
