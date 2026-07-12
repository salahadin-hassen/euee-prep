import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// The application's local Drift database.
///
/// Deliberately empty of business tables at this stage (Milestone 0,
/// Task 8 — database foundation only). Tables are added starting in
/// Milestone 1 (Core Data Layer) and Milestone 2 (Entitlement Foundation),
/// each as its own reviewable commit — see 10_IMPLEMENTATION_ROADMAP.md
/// and docs/AI_RULES.md ("one feature per commit").
///
/// Schema version starts at 1. Every future table addition or column
/// change bumps [schemaVersion] and adds a step to [migration] — never a
/// silent modification of an already-shipped version. This mirrors the
/// same immutability discipline Decision 015/021 apply to content packs,
/// applied here to the local database schema itself.
@DriftDatabase(tables: [])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For tests: allows injecting an in-memory connection instead of the
  /// real on-device file, per 07_CODING_STANDARDS.md's testing conventions
  /// ("no test should hit a real file-backed SQLite database").
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        // onUpgrade intentionally left as the default no-op for now — there
        // is nothing to migrate *to* yet. The first real onUpgrade step
        // arrives with Milestone 1's first table addition, not before.
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'euee_prep.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
