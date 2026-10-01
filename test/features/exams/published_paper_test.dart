import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/features/exams/domain/models/published_paper.dart';

void main() {
  group('PublishedPaper.fromJson', () {
    test('parses a full catalog entry', () {
      final paper = PublishedPaper.fromJson(_entry());

      expect(paper.id, '11111111-2222-3333-4444-555555555555');
      expect(paper.packId, 'physics-2015-natural-science');
      expect(paper.subjectSlug, 'physics');
      expect(paper.subjectTitle, 'Physics');
      expect(paper.stream, 'natural_science');
      expect(paper.year, 2015);
      expect(paper.title, 'EUEE Physics 2015');
      expect(paper.questionCount, 3);
      expect(paper.packVersion, '1.0.0');
      expect(paper.sizeBytes, 4096);
      expect(paper.storagePath, 'physics-2015-natural-science/1.0.0.zip');
      expect(paper.publishedAt, '2026-10-01T00:00:00.000Z');
      expect(paper.minimumAppVersion, '1.0.0');
      expect(paper.updatedAt, '2026-10-01T00:00:00.000Z');
      expect(paper.downloadUrl, 'https://storage.test/physics.zip');
      expect(paper.packVersionId, 'physics-2015-natural-science#1.0.0');
    });

    test('round-trips through toJson', () {
      final paper = PublishedPaper.fromJson(_entry());
      expect(PublishedPaper.fromJson(paper.toJson()), paper);
      expect(paper == PublishedPaper.fromJson(paper.toJson()), isTrue);
    });

    test('rejects a missing required field', () {
      final entry = _entry()..remove('pack_version');
      expect(
        () => PublishedPaper.fromJson(entry),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('pack_version'),
          ),
        ),
      );
    });

    test('rejects a mistyped field', () {
      final entry = _entry()..['year'] = '2015';
      expect(
        () => PublishedPaper.fromJson(entry),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an empty identifier', () {
      final entry = _entry()..['pack_id'] = '';
      expect(
        () => PublishedPaper.fromJson(entry),
        throwsA(isA<FormatException>()),
      );
    });

    test('tolerates a null id', () {
      final entry = _entry()..['id'] = null;
      expect(PublishedPaper.fromJson(entry).id, isNull);
    });
  });

  group('PaperInstallStatus.compute', () {
    test('is available when nothing is installed', () {
      final status = PaperInstallStatus.compute(
        publishedVersion: '1.0.0',
        installedVersion: null,
      );
      expect(status.state, PaperInstallState.available);
      expect(status.installedVersion, isNull);
    });

    test('is installed when the published version is installed', () {
      final status = PaperInstallStatus.compute(
        publishedVersion: '1.0.0',
        installedVersion: '1.0.0',
      );
      expect(status.state, PaperInstallState.installed);
    });

    test('is installed when a newer version is installed', () {
      final status = PaperInstallStatus.compute(
        publishedVersion: '1.0.0',
        installedVersion: '1.1.0',
      );
      expect(status.state, PaperInstallState.installed);
    });

    test('is updateAvailable when only an older version is installed', () {
      final status = PaperInstallStatus.compute(
        publishedVersion: '1.1.0',
        installedVersion: '1.0.0',
      );
      expect(status.state, PaperInstallState.updateAvailable);
      expect(status.publishedVersion, '1.1.0');
      expect(status.installedVersion, '1.0.0');
    });

    test('compares versions numerically (1.10.0 > 1.9.0)', () {
      final status = PaperInstallStatus.compute(
        publishedVersion: '1.10.0',
        installedVersion: '1.9.0',
      );
      expect(status.state, PaperInstallState.updateAvailable);
    });
  });

  group('PublishedPaperQuery', () {
    test('has value equality for use as a provider family key', () {
      const a = PublishedPaperQuery(stream: 'natural_science', year: 2015);
      const b = PublishedPaperQuery(stream: 'natural_science', year: 2015);
      const c = PublishedPaperQuery(stream: 'social_science', year: 2015);

      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });
}

Map<String, dynamic> _entry() => {
      'id': '11111111-2222-3333-4444-555555555555',
      'pack_id': 'physics-2015-natural-science',
      'subject_slug': 'physics',
      'subject_title': 'Physics',
      'stream': 'natural_science',
      'year': 2015,
      'title': 'EUEE Physics 2015',
      'question_count': 3,
      'pack_version': '1.0.0',
      'size_bytes': 4096,
      'storage_path': 'physics-2015-natural-science/1.0.0.zip',
      'published_at': '2026-10-01T00:00:00.000Z',
      'minimum_app_version': '1.0.0',
      'updated_at': '2026-10-01T00:00:00.000Z',
      'download_url': 'https://storage.test/physics.zip',
    };
