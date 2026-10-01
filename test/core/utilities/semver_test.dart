import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/utilities/semver.dart';

void main() {
  group('compareSemVer', () {
    test('orders equal versions as equal', () {
      expect(compareSemVer('1.0.0', '1.0.0'), 0);
      expect(compareSemVer('2.3.4', '2.3.4'), 0);
    });

    test('orders versions numerically, not lexicographically', () {
      expect(compareSemVer('1.9.0', '1.10.0'), lessThan(0));
      expect(compareSemVer('1.10.0', '1.9.0'), greaterThan(0));
      expect(compareSemVer('1.0.0', '1.0.1'), lessThan(0));
      expect(compareSemVer('2.0.0', '1.9.9'), greaterThan(0));
    });

    test('pads missing segments with zero', () {
      expect(compareSemVer('1.0', '1.0.0'), 0);
      expect(compareSemVer('1', '1.0.0'), 0);
      expect(compareSemVer('1.0.1', '1.0'), greaterThan(0));
      expect(compareSemVer('1.0', '1.0.1'), lessThan(0));
    });

    test('treats non-numeric segments as zero', () {
      expect(compareSemVer('1.0.0-beta', '1.0.0'), 0);
      expect(compareSemVer('1.0.x', '1.0.0'), 0);
    });
  });
}
