import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/features/subjects/presentation/subject_detail_screen.dart';

void main() {
  group('decodeChoicesJson', () {
    test('reconstructs four choices exactly, including an embedded comma',
        () {
      final stored = jsonEncode([
        'Option A, with a comma',
        'Option B',
        'Option C',
        'Option D',
      ]);

      expect(decodeChoicesJson(stored), [
        'Option A, with a comma',
        'Option B',
        'Option C',
        'Option D',
      ]);
    });

    test('round-trips the exact encoding the importer writes', () {
      const choices = ['5 N', '10 N', '15 N', '20 N'];

      expect(decodeChoicesJson(jsonEncode(choices)), choices);
    });

    test('keeps quotes, brackets, and slashes intact', () {
      final stored = jsonEncode([
        'He said "hello" to me',
        '[bracketed] option',
        'a/b ratio',
        'tab\tand\nnewline',
      ]);

      expect(decodeChoicesJson(stored), [
        'He said "hello" to me',
        '[bracketed] option',
        'a/b ratio',
        'tab\tand\nnewline',
      ]);
    });

    test('preserves non-ASCII characters', () {
      final stored = jsonEncode(['10²', '10⁴', '10⁶', '10⁸']);

      expect(decodeChoicesJson(stored), ['10²', '10⁴', '10⁶', '10⁸']);
    });

    test('returns an empty list for an empty array', () {
      expect(decodeChoicesJson('[]'), isEmpty);
    });

    test('rejects malformed JSON instead of mangling the options', () {
      expect(
        () => decodeChoicesJson('["Option A, with a comma", "Option B"'),
        throwsFormatException,
      );
      expect(() => decodeChoicesJson('not json'), throwsFormatException);
    });

    test('rejects a JSON value that is not an array', () {
      expect(() => decodeChoicesJson('{"a": 1}'), throwsFormatException);
      expect(() => decodeChoicesJson('"just a string"'), throwsFormatException);
      expect(() => decodeChoicesJson('42'), throwsFormatException);
    });

    test('rejects an array containing non-string elements', () {
      expect(() => decodeChoicesJson('["A", 2]'), throwsFormatException);
      expect(() => decodeChoicesJson('["A", null]'), throwsFormatException);
    });
  });
}
