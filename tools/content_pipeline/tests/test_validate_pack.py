"""Unit tests for the content-pack validation script (``validate_pack.py``).

Run with::

    python -m unittest discover tools/content_pipeline/tests -v

The tests exercise every rejection rule the in-app importer also enforces, and
prove the pipeline checksum is byte-compatible with the Dart importer — the
fixture's embedded checksum was produced by the Dart side, so re-computing it
here must yield the identical value.
"""

import copy
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools" / "content_pipeline"))

from pack_checksum import compute_checksum  # noqa: E402
from validate_pack import validate, validate_file, validate_integrity  # noqa: E402

FIXTURE = (
    ROOT
    / "test"
    / "features"
    / "content"
    / "fixtures"
    / "physics_euee_pack_v1.json"
)


def load_fixture():
    """Return a deep copy of the fixture pack as a plain dict."""
    return copy.deepcopy(json.loads(FIXTURE.read_text(encoding="utf-8")))


def resign(pack):
    """Recompute and set the checksum so the mutated pack stays signed."""
    pack["checksum"] = compute_checksum(pack)
    return pack


def first_question(pack):
    return pack["chapters"][0]["topics"][0]["questions"][0]


class TestValidPack(unittest.TestCase):
    def test_fixture_is_valid(self):
        self.assertEqual(validate(load_fixture()), [])

    def test_checksum_byte_compatible_with_dart_importer(self):
        # The fixture's embedded checksum was produced by the Dart importer; the
        # pipeline must compute the identical value from the canonical contract.
        pack = load_fixture()
        self.assertEqual(compute_checksum(pack), pack["checksum"])

    def test_validate_file_passes_fixture(self):
        self.assertEqual(validate_file(FIXTURE), [])

    def test_resigned_pack_stays_valid(self):
        pack = resign(load_fixture())
        self.assertEqual(validate(pack), [])
        self.assertEqual(validate_integrity(pack), [])


class TestMetadataValidation(unittest.TestCase):
    def test_unsupported_schema_version(self):
        pack = load_fixture()
        pack["schema_version"] = "3"
        self.assertTrue(any("schema_version" in e for e in validate(pack)))

    def test_unknown_stream(self):
        pack = load_fixture()
        pack["stream"] = "engineering"
        self.assertTrue(any("stream" in e for e in validate(pack)))

    def test_empty_subject_slug(self):
        pack = load_fixture()
        pack["subject"]["slug"] = ""
        self.assertTrue(any("subject.slug" in e for e in validate(pack)))

    def test_invalid_generated_at(self):
        pack = load_fixture()
        pack["generated_at"] = "not-a-date"
        self.assertTrue(any("generated_at" in e for e in validate(pack)))

    def test_missing_checksum(self):
        pack = load_fixture()
        pack["checksum"] = ""
        self.assertTrue(any("checksum" in e for e in validate(pack)))


class TestContentValidation(unittest.TestCase):
    def test_invalid_grade(self):
        pack = load_fixture()
        pack["chapters"][0]["grade"] = 8
        self.assertTrue(any("grade" in e for e in validate(pack)))

    def test_invalid_resource_type(self):
        pack = load_fixture()
        pack["chapters"][0]["topics"][0]["resources"][0]["type"] = "article"
        self.assertTrue(any("invalid type" in e for e in validate(pack)))

    def test_empty_prompt(self):
        pack = load_fixture()
        first_question(pack)["prompt"] = ""
        self.assertTrue(any("prompt" in e for e in validate(pack)))

    def test_too_few_choices(self):
        pack = load_fixture()
        first_question(pack)["choices"] = ["only"]
        self.assertTrue(any("at least two choices" in e for e in validate(pack)))

    def test_out_of_range_correct_choice_index(self):
        pack = load_fixture()
        first_question(pack)["correct_choice_index"] = 99
        self.assertTrue(any("out of range" in e for e in validate(pack)))

    def test_duplicate_pack_local_ids(self):
        pack = load_fixture()
        pack["chapters"][0]["topics"].append(
            {
                "id": "t-newton-laws",
                "title": "Duplicate Topic",
                "order_index": 2,
                "questions": [],
                "resources": [],
            }
        )
        self.assertTrue(any("duplicate pack-local id" in e for e in validate(pack)))

    def test_broken_topic_reference(self):
        pack = load_fixture()
        first_question(pack)["topic_refs"] = ["t-missing"]
        self.assertTrue(any("unknown topic" in e for e in validate(pack)))

    def test_broken_exam_question_reference(self):
        pack = load_fixture()
        pack["exams"][0]["question_ids"] = ["q-missing"]
        self.assertTrue(any("unknown question" in e for e in validate(pack)))

    def test_duplicate_exam_membership(self):
        pack = load_fixture()
        pack["exams"][0]["question_ids"] = ["q-newton-1", "q-newton-1"]
        self.assertTrue(any("more than once" in e for e in validate(pack)))

    def test_duplicate_exam_year(self):
        pack = load_fixture()
        second = copy.deepcopy(pack["exams"][0])
        second["id"] = "exam-physics-2015-b"
        pack["exams"].append(second)
        self.assertTrue(any("one paper per" in e for e in validate(pack)))


class TestIntegrity(unittest.TestCase):
    def test_checksum_mismatch_detected(self):
        pack = load_fixture()
        first_question(pack)["prompt"] = "tampered prompt"
        errors = validate_integrity(pack)
        self.assertTrue(any("checksum mismatch" in e for e in errors))

    def test_resigned_tampered_pack_passes_integrity(self):
        pack = resign(load_fixture())
        first_question(pack)["prompt"] = "a corrected prompt"
        resign(pack)
        self.assertEqual(validate(pack), [])
        self.assertEqual(validate_integrity(pack), [])


if __name__ == "__main__":
    unittest.main()
