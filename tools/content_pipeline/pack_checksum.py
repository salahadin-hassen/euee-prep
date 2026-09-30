"""Content-pack integrity checksum for the EUEE Prep content pipeline.

This module is the Python counterpart to the in-app importer's checksum
(``lib/features/content/domain/services/content_import_checksum.dart``) and the
Content Studio exporter's checksum (``content-studio/lib/checksum.ts``). All
three implement the *same* canonical serialization and the *same* FNV-1a 64-bit
hash, so a pack's declared ``checksum`` verifies identically in the pipeline,
in the browser, and on-device (Decision 021).

Canonical serialization rules (must match the Dart and TypeScript sides
byte-for-byte):

* The top-level ``checksum`` field is excluded (a pack cannot checksum itself).
* ALL object keys are sorted alphabetically, recursively, at every nesting
  level; array order is preserved as-is.
* JSON is emitted with two-space indentation and NO trailing newline — the
  same output as JavaScript's ``JSON.stringify(value, null, 2)`` and Dart's
  ``JsonEncoder.withIndent('  ')``.
* Non-ASCII characters are left as raw UTF-8 (``ensure_ascii=False``), matching
  ``JSON.stringify``.

Format: ``fnv1a64:<16 lowercase hex digits>``.
"""

import json
from typing import Any, Dict

OFFSET_BASIS = 14695981039346656037
PRIME = 1099511628211
MASK = (1 << 64) - 1


def fnv1a64(data: bytes) -> str:
    """Return the ``fnv1a64:`` checksum string for ``data``."""
    h = OFFSET_BASIS
    for byte in data:
        h ^= byte
        h = (h * PRIME) & MASK
    return "fnv1a64:{:016x}".format(h)


def canonical_json(pack: Dict[str, Any]) -> str:
    """Serialize ``pack`` (a parsed pack dict) into its canonical form."""
    payload = {key: value for key, value in pack.items() if key != "checksum"}
    return json.dumps(payload, indent=2, sort_keys=True, ensure_ascii=False)


def compute_checksum(pack: Dict[str, Any]) -> str:
    """Return the checksum the canonical serialization of ``pack`` produces."""
    return fnv1a64(canonical_json(pack).encode("utf-8"))
