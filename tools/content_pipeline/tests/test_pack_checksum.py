"""Unit tests for the content-pack checksum (``pack_checksum.py``).

Run with::

    python -m unittest discover tools/content_pipeline/tests -v

The canonical form must be byte-identical to the Dart implementation
(``lib/features/content/domain/services/content_import_checksum.dart``) and the
TypeScript implementation (``content-studio/lib/checksum.ts``): keys sorted
recursively, two-space indentation, no trailing newline, checksum field
excluded, raw UTF-8 for non-ASCII characters.
"""

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools" / "content_pipeline"))

from pack_checksum import canonical_json, compute_checksum, fnv1a64  # noqa: E402

DART_FIXTURE = (
    ROOT / "test" / "features" / "content" / "fixtures" / "physics_euee_pack_v3.json"
)
EXPORT_FIXTURE = (
    ROOT / "content-studio" / "tests" / "fixtures" / "exported-content-pack-v3.json"
)


def load(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


class TestCanonicalJson(unittest.TestCase):
    def test_excludes_the_checksum_field(self):
        pack = {"schema_version": "3", "checksum": "fnv1a64:0000000000000000"}
        self.assertNotIn("checksum", canonical_json(pack))
        self.assertEqual(
            compute_checksum(pack),
            compute_checksum({k: v for k, v in pack.items() if k != "checksum"}),
        )

    def test_sorts_keys_recursively(self):
        a = {"z": {"b": 1, "a": 2}, "m": "hello"}
        b = {"m": "hello", "z": {"a": 2, "b": 1}}
        self.assertEqual(canonical_json(a), canonical_json(b))

    def test_uses_two_space_indentation(self):
        canonical = canonical_json({"a": 1, "b": {"c": 2}})
        self.assertIn('\n  "b": {', canonical)
        self.assertIn('\n    "c": 2', canonical)
        self.assertNotIn("\t", canonical)

    def test_has_no_trailing_newline(self):
        canonical = canonical_json({"a": 1})
        self.assertFalse(canonical.endswith("\n"))

    def test_preserves_array_order(self):
        canonical = canonical_json({"items": ["c", "a", "b"]})
        self.assertLess(canonical.index('"c"'), canonical.index('"a"'))
        self.assertLess(canonical.index('"a"'), canonical.index('"b"'))

    def test_keeps_non_ascii_characters_raw(self):
        canonical = canonical_json({"title": "Physics ² + µ"})
        self.assertIn("²", canonical)
        self.assertIn("µ", canonical)
        self.assertNotIn("\\u", canonical)

    def test_matches_json_stringify_style_round_trip(self):
        pack = {"a": [1, 2], "b": {"c": "d"}, "e": None}
        self.assertEqual(json.loads(canonical_json(pack)), pack)


class TestChecksum(unittest.TestCase):
    def test_fnv1a64_known_vector(self):
        # FNV-1a 64 of the empty string is the offset basis.
        self.assertEqual(fnv1a64(b""), "fnv1a64:cbf29ce484222325")
        self.assertEqual(fnv1a64(b"a"), "fnv1a64:af63dc4c8601ec8c")

    def test_output_format(self):
        checksum = compute_checksum({"a": 1})
        self.assertTrue(checksum.startswith("fnv1a64:"))
        self.assertEqual(len(checksum), len("fnv1a64:") + 16)

    def test_deterministic(self):
        pack = {"schema_version": "3", "stream": "natural_science"}
        self.assertEqual(compute_checksum(pack), compute_checksum(pack))

    def test_matches_dart_signed_fixture(self):
        pack = load(DART_FIXTURE)
        self.assertEqual(compute_checksum(pack), pack["checksum"])

    def test_matches_typescript_signed_export_fixture(self):
        pack = load(EXPORT_FIXTURE)
        self.assertEqual(compute_checksum(pack), pack["checksum"])


if __name__ == "__main__":
    unittest.main()
