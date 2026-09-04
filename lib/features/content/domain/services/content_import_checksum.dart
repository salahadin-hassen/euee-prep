import 'dart:convert';

import '../models/content_pack_file.dart';

/// Content-pack integrity checksum.
///
/// FNV-1a 64-bit over the UTF-8 bytes of the pack's canonical serialization
/// (excluding the `checksum` field — a pack cannot checksum itself). The
/// result is deterministic across runs and platforms, which is what the
/// importer needs to verify a pack's declared `checksum` before writing
/// anything (Decision 021, `docs/content-pack-spec.md`).
///
/// Format: `fnv1a64:<16 lowercase hex digits>`.
///
/// This is deliberately not a cryptographic hash: it is a corruption/integrity
/// check for a trusted content pipeline, computed with no third-party
/// dependency. The `sha256:` prefix in the spec example is illustrative only —
/// the algorithm is not part of the JSON schema. Swapping in SHA-256 later
/// (via `package:crypto`) is a one-line change to [compute].
class ContentChecksum {
  const ContentChecksum._();

  static const String _offsetBasis = '14695981039346656037';
  static const String _prime = '1099511628211';

  static String compute(ContentPackFile pack) {
    final bytes = utf8.encode(pack.toCanonicalJson());
    var hash = BigInt.parse(_offsetBasis);
    final prime = BigInt.parse(_prime);
    final mask = (BigInt.one << 64) - BigInt.one;

    for (final byte in bytes) {
      hash = ((hash ^ BigInt.from(byte)) * prime) & mask;
    }

    return 'fnv1a64:${hash.toRadixString(16).padLeft(16, '0')}';
  }
}
