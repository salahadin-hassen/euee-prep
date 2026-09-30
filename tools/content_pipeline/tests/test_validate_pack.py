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
from validate_pack import (  # noqa: E402
    SUPPORTED_SCHEMA_VERSION,
    validate,
    validate_file,
    validate_integrity,
)

# Signed by the Flutter importer (test/features/content/content_import_service_test.dart).
DART_FIXTURE = (
    ROOT / "test" / "features" / "content" / "fixtures" / "physics_euee_pack_v3.json"
)
# Produced by the Content Studio exporter (content-studio/lib/export-pack.ts).
EXPORT_FIXTURE = (
    ROOT
    / "content-studio"
    / "tests"
    / "fixtures"
    / "exported-content-pack-v3.json"
)
# Shared cross-language fixture maintained by content-studio/tests/checksum.test.ts.
CROSS_LANGUAGE_FIXTURE = (
    ROOT / "content-studio" / "tests" / "fixtures" / "cross-language-pack.json"
)


def load_fixture(path=DART_FIXTURE):
    """Return a deep copy of the fixture pack as a plain dict."""
    return copy.deepcopy(json.loads(Path(path).read_text(encoding="utf-8")))


def resign(pack):
    """Recompute and set the checksum so the mutated pack stays signed."""
    pack["checksum"] = compute_checksum(pack)
    return pack


def first_question(pack):
    return pack["questions"][0]


class TestValidPack(unittest.TestCase):
    def test_supported_schema_version_is_3(self):
        self.assertEqual(SUPPORTED_SCHEMA_VERSION, "3")

    def test_fixture_is_valid(self):
        self.assertEqual(validate(load_fixture()), [])

    def test_checksum_byte_compatible_with_dart_importer(self):
        # The fixture's embedded checksum was produced by the Dart importer; the
        # pipeline must compute the identical value from the canonical contract.
        pack = load_fixture()
        self.assertEqual(compute_checksum(pack), pack["checksum"])

    def test_validate_file_passes_fixture(self):
        self.assertEqual(validate_file(DART_FIXTURE), [])

    def test_resigned_pack_stays_valid(self):
        pack = resign(load_fixture())
        self.assertEqual(validate(pack), [])
        self.assertEqual(validate_integrity(pack), [])


class TestMetadataValidation(unittest.TestCase):
    def test_stale_v2_schema_version_is_rejected(self):
        pack = load_fixture()
        pack["schema_version"] = "2"
        errors = validate(pack)
        self.assertTrue(any("schema_version" in e for e in errors))
        self.assertTrue(any('supported: "3"' in e for e in errors))

    def test_missing_schema_version_is_rejected(self):
        pack = load_fixture()
        del pack["schema_version"]
        self.assertTrue(any("schema_version" in e for e in validate(pack)))

    def test_unknown_stream(self):
        pack = load_fixture()
        pack["stream"] = "engineering"
        self.assertTrue(any("stream" in e for e in validate(pack)))

    def test_display_name_stream_is_rejected(self):
        pack = load_fixture()
        pack["stream"] = "Natural Science"
        self.assertTrue(any("stream" in e for e in validate(pack)))

    def test_empty_subject_slug(self):
        pack = load_fixture()
        pack["subject"]["slug"] = ""
        self.assertTrue(any("subject.slug" in e for e in validate(pack)))

    def test_missing_pack_id(self):
        pack = load_fixture()
        pack["pack_id"] = ""
        self.assertTrue(any("pack_id" in e for e in validate(pack)))

    def test_invalid_generated_at(self):
        pack = load_fixture()
        pack["generated_at"] = "not-a-date"
        self.assertTrue(any("generated_at" in e for e in validate(pack)))

    def test_missing_checksum(self):
        pack = load_fixture()
        pack["checksum"] = ""
        self.assertTrue(any("checksum" in e for e in validate(pack)))

    def test_missing_minimum_app_version(self):
        pack = load_fixture()
        del pack["minimum_app_version"]
        self.assertTrue(any("minimum_app_version" in e for e in validate(pack)))

    def test_stale_v2_chapters_field_is_rejected(self):
        pack = load_fixture()
        pack["chapters"] = []
        errors = validate(pack)
        self.assertTrue(any('"chapters"' in e for e in errors))
        self.assertTrue(any("v3 content pack" in e for e in errors))

    def test_stale_v2_exams_field_is_rejected(self):
        pack = load_fixture()
        pack["exams"] = []
        self.assertTrue(any('"exams"' in e for e in validate(pack)))

    def test_stale_v2_nested_question_fields_are_rejected(self):
        pack = load_fixture()
        first_question(pack)["topic_refs"] = ["t-newton-laws"]
        first_question(pack)["exam_year_ec"] = 2015
        errors = validate(pack)
        self.assertTrue(any("topic_refs" in e for e in errors))
        self.assertTrue(any("exam_year_ec" in e for e in errors))


class TestPaperValidation(unittest.TestCase):
    def test_paper_must_be_an_object(self):
        pack = load_fixture()
        pack["paper"] = "2015 Physics"
        self.assertTrue(any('"paper" must be an object' in e for e in validate(pack)))

    def test_non_positive_year(self):
        pack = load_fixture()
        pack["paper"]["year"] = 0
        self.assertTrue(any("paper.year" in e for e in validate(pack)))

    def test_empty_paper_title(self):
        pack = load_fixture()
        pack["paper"]["title"] = ""
        self.assertTrue(any("paper.title" in e for e in validate(pack)))

    def test_question_count_mismatch(self):
        pack = load_fixture()
        pack["paper"]["question_count"] = 99
        errors = validate(pack)
        self.assertTrue(any("question_count" in e for e in errors))
        self.assertTrue(any("does not match" in e for e in errors))

    def test_unknown_paper_field(self):
        pack = load_fixture()
        pack["paper"]["duration_seconds"] = 7200
        self.assertTrue(any('"paper.duration_seconds"' in e for e in validate(pack)))


class TestQuestionValidation(unittest.TestCase):
    def test_questions_must_be_an_array(self):
        pack = load_fixture()
        pack["questions"] = {"q1": {}}
        self.assertTrue(any('"questions" must be an array' in e for e in validate(pack)))

    def test_question_must_be_an_object(self):
        pack = load_fixture()
        pack["questions"][0] = "not a question"
        self.assertTrue(any("must be an object" in e for e in validate(pack)))

    def test_empty_prompt(self):
        pack = load_fixture()
        first_question(pack)["prompt"] = ""
        self.assertTrue(any("prompt must be non-empty" in e for e in validate(pack)))

    def test_number_must_be_positive(self):
        pack = load_fixture()
        first_question(pack)["number"] = 0
        self.assertTrue(any("number must be > 0" in e for e in validate(pack)))

    def test_too_few_choices(self):
        pack = load_fixture()
        first_question(pack)["choices"] = ["only"]
        self.assertTrue(any("at least two choices" in e for e in validate(pack)))

    def test_empty_choice(self):
        pack = load_fixture()
        first_question(pack)["choices"][1] = ""
        self.assertTrue(any("empty choice" in e for e in validate(pack)))

    def test_choices_must_be_an_array_of_strings(self):
        pack = load_fixture()
        first_question(pack)["choices"] = "A, B, C, D"
        self.assertTrue(any("array of strings" in e for e in validate(pack)))

    def test_out_of_range_correct_choice_index(self):
        pack = load_fixture()
        first_question(pack)["correct_choice_index"] = 99
        self.assertTrue(any("out of range" in e for e in validate(pack)))

    def test_non_integer_correct_choice_index(self):
        pack = load_fixture()
        first_question(pack)["correct_choice_index"] = "1"
        self.assertTrue(
            any("correct_choice_index must be an integer" in e for e in validate(pack))
        )

    def test_duplicate_question_ids(self):
        pack = load_fixture()
        copy_of_first = copy.deepcopy(first_question(pack))
        copy_of_first["number"] = len(pack["questions"]) + 1
        pack["questions"].append(copy_of_first)
        self.assertTrue(any("duplicate question id" in e for e in validate(pack)))

    def test_explanation_must_be_string_or_null(self):
        pack = load_fixture()
        first_question(pack)["explanation"] = 42
        self.assertTrue(any("explanation must be a string or null" in e for e in validate(pack)))

    def test_source_page_must_be_integer_or_null(self):
        pack = load_fixture()
        first_question(pack)["source_page"] = "3"
        self.assertTrue(
            any("source_page must be an integer or null" in e for e in validate(pack))
        )


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


class TestCrossSystemPacks(unittest.TestCase):
    """Packs produced by the other systems must validate and verify here."""

    def test_content_studio_export_fixture_is_valid(self):
        pack = load_fixture(EXPORT_FIXTURE)
        self.assertEqual(validate(pack), [])

    def test_content_studio_export_checksum_matches_typescript(self):
        pack = load_fixture(EXPORT_FIXTURE)
        self.assertEqual(compute_checksum(pack), pack["checksum"])
        self.assertEqual(validate_integrity(pack), [])

    def test_cross_language_fixture_is_valid(self):
        pack = load_fixture(CROSS_LANGUAGE_FIXTURE)
        self.assertEqual(validate(pack), [])
        self.assertEqual(compute_checksum(pack), pack["checksum"])


if __name__ == "__main__":
    unittest.main()
