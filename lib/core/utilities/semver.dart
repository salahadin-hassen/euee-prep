/// Semantic-version comparison shared by the content-import pipeline and the
/// published-paper catalog.
///
/// Deliberately tiny — dotted numeric segments only (`major.minor.patch`),
/// non-numeric segments count as `0`, missing segments pad with `0`. This is
/// the exact behavior the importer has always applied to
/// `minimum_app_version`; it is extracted here so catalog update checks reuse
/// the same rules instead of duplicating them.
library;

/// Returns a negative number if [a] is older than [b], `0` when equal, and a
/// positive number if [a] is newer than [b].
int compareSemVer(String a, String b) {
  final partsA = a.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final partsB = b.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final length = partsA.length > partsB.length ? partsA.length : partsB.length;
  for (var i = 0; i < length; i++) {
    final x = i < partsA.length ? partsA[i] : 0;
    final y = i < partsB.length ? partsB[i] : 0;
    if (x != y) return x < y ? -1 : 1;
  }
  return 0;
}
