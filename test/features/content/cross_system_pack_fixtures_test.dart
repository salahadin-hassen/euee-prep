import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/features/content/domain/models/content_pack_file.dart';
import 'package:euee_prep/features/content/domain/services/content_import_checksum.dart';
import 'package:euee_prep/features/content/domain/services/content_pack_validator.dart';

/// Fixtures produced by each system in the content-pack chain. Every one must
/// parse, validate, and re-checksum identically in this importer — that is
/// what makes an exported pack importable on-device.
const _fixtures = <String, String>{
  'Flutter-signed physics pack':
      'test/features/content/fixtures/physics_euee_pack_v3.json',
  'Content Studio export':
      'content-studio/tests/fixtures/exported-content-pack-v3.json',
  'Cross-language fixture':
      'content-studio/tests/fixtures/cross-language-pack.json',
};

void main() {
  group('cross-system content pack fixtures', () {
    for (final entry in _fixtures.entries) {
      test('${entry.key} parses as a valid v3 pack', () {
        final pack = _parse(entry.value);

        expect(pack.schemaVersion, '3');
        expect(pack.stream, anyOf('natural_science', 'social_science'));
        expect(pack.subject.slug, isNotEmpty);
        expect(pack.paper.questionCount, pack.questions.length);
        expect(const ContentPackValidator().validate(pack), isEmpty,
            reason: 'the importer must accept a pack from the other system');
      });

      test('${entry.key} carries a checksum this importer recomputes', () {
        final pack = _parse(entry.value);

        expect(
          ContentChecksum.compute(pack),
          pack.checksum,
          reason: 'checksum must be byte-identical across TypeScript, '
              'Python, and Dart',
        );
      });
    }
  });
}

ContentPackFile _parse(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: 'missing fixture: $path');
  return ContentPackFile.parse(file.readAsStringSync());
}
