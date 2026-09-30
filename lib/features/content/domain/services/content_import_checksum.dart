import 'dart:convert';

import '../models/content_pack_file.dart';

/// Content-pack integrity checksum.
///
/// FNV-1a 64-bit over the UTF-8 bytes of the pack's canonical serialization
/// (excluding the `checksum` field — a pack cannot checksum itself). The
/// result is deterministic across runs and platforms, which is what the
/// importer needs to verify a pack's declared `checksum` before writing
/// anything.
///
/// Format: `fnv1a64:<16 lowercase hex digits>`.
///
/// Canonicalization contract (must match TypeScript implementation exactly):
/// 1. Build the pack object WITHOUT the `checksum` field.
/// 2. Sort ALL object keys alphabetically at every nesting level (recursive).
/// 3. Serialize to JSON with 2-space indentation and NO trailing newline.
/// 4. Encode as UTF-8 bytes.
/// 5. Compute FNV-1a 64-bit over those bytes.
/// 6. Format as `fnv1a64:<16 lowercase hex digits>`.
class ContentChecksum {
  const ContentChecksum._();

  static const String _offsetBasis = '14695981039346656037';
  static const String _prime = '1099511628211';

  static String compute(ContentPackFile pack) {
    final canonical = _canonicalJson(pack);
    final bytes = utf8.encode(canonical);
    var hash = BigInt.parse(_offsetBasis);
    final prime = BigInt.parse(_prime);
    final mask = (BigInt.one << 64) - BigInt.one;

    for (final byte in bytes) {
      hash = ((hash ^ BigInt.from(byte)) * prime) & mask;
    }

    return 'fnv1a64:${hash.toRadixString(16).padLeft(16, '0')}';
  }

  /// Produce the canonical JSON string used for checksum computation.
  ///
  /// - Excludes the `checksum` field.
  /// - Sorts all keys alphabetically at every level.
  /// - Uses 2-space indentation, no trailing newline.
  static String _canonicalJson(ContentPackFile pack) {
    final map = pack.toCanonicalJson();
    final decoded = jsonDecode(map) as Map<String, dynamic>;
    final sorted = _sortKeys(decoded);
    return _jsonEncodeSorted(sorted);
  }

  /// Recursively sort all object keys for deterministic serialization.
  static dynamic _sortKeys(dynamic obj) {
    if (obj is List) {
      return obj.map(_sortKeys).toList();
    }
    if (obj is Map<String, dynamic>) {
      final sorted = <String, dynamic>{};
      final keys = obj.keys.toList()..sort();
      for (final key in keys) {
        sorted[key] = _sortKeys(obj[key]);
      }
      return sorted;
    }
    return obj;
  }

  /// JSON encode with 2-space indentation. Dart's `JsonEncoder.withIndent`
  /// produces the exact same output as JavaScript's `JSON.stringify(obj, null, 2)`.
  static String _jsonEncodeSorted(dynamic obj) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(obj);
  }
}
