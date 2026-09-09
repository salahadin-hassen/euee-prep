import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/core/providers.dart';
import 'package:euee_prep/main.dart';
import 'package:euee_prep/features/streams/data/local_data_sources/stream_local_data_source.dart';
import 'package:euee_prep/features/streams/data/repositories/stream_repository_impl.dart';
import 'package:euee_prep/features/streams/domain/models/stream_model.dart';
import 'package:euee_prep/features/subjects/data/local_data_sources/subject_local_data_source.dart';
import 'package:euee_prep/features/subjects/data/repositories/subject_repository_impl.dart';
import 'package:euee_prep/features/subjects/domain/models/subject.dart';

void main() {
  testWidgets('EueePrepApp shows EUEE Prep title', (WidgetTester tester) async {
    final testDb = db.AppDatabase.forTesting(NativeDatabase.memory());
    // Seed a stream so the subject list works
    final streamRepo = StreamRepositoryImpl(StreamLocalDataSource(testDb));
    final subjectRepo = SubjectRepositoryImpl(SubjectLocalDataSource(testDb));
    await streamRepo.insert(
      const StreamModel(id: 1, slug: 'natural_science'),
    );
    await subjectRepo.insert(
      const Subject(id: 1, streamId: 1, slug: 'physics', title: 'Physics'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const EueePrepApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('EUEE Prep'), findsOneWidget);

    await testDb.close();
  });
}
