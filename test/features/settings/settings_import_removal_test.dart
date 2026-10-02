import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/core/providers.dart';
import 'package:euee_prep/features/settings/presentation/settings_screen.dart';

/// Learners download papers from the catalog — the manual
/// "Import Content Pack" workflow no longer exists anywhere in the UI.
void main() {
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('Settings exposes no manual content-pack import entry point',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Import Content Pack'), findsNothing);
    expect(find.text('Add exam papers from a file'), findsNothing);

    // The screen still offers its real actions.
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Reset Preferred Stream'), findsOneWidget);
  });
}
