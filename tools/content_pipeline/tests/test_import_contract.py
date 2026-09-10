import json
import tempfile
import unittest
from pathlib import Path

from import_contract import (
    ImportContractError,
    build_result_contract,
    result_contract_sha256,
    serialize_result_contract,
    validate_result_contract,
)
from worker_protocol import descriptor_from_parts


JOB = "11111111-1111-4111-8111-111111111111"
PROJECT = "22222222-2222-4222-8222-222222222222"
DOCUMENT = "33333333-3333-4333-8333-333333333333"
SOURCE_HASH = "a" * 64


def write_json(path: Path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value), encoding="utf-8")


class ImportContractTests(unittest.TestCase):
    def fixture_output(self, root: Path) -> None:
        write_json(root / "raw_extraction/page-001.json", {
            "pdf_page": 1,
            "printed_page": 14,
            "visible_metadata": [],
            "questions": [{
                "question_number": 1,
                "prompt": "Visible prompt",
                "choices": ["A", "B", "C", "D"],
                "correct_choice_index": None,
                "answer_status": "unresolved",
                "source_region": {"x": 0.1, "y": 0.1, "width": 0.8, "height": 0.2},
                "uncertainties": ["small print"],
                "visual_assets": [],
            }],
        })
        write_json(root / "validated_extraction/page-001.json", {"pdf_page": 1, "valid": True, "errors": [], "warnings": []})
        write_json(root / "answer_analysis/page-001.json", {
            "pdf_page": 1,
            "questions": [{
                "question_number": 1,
                "predicted_choice_index": 2,
                "confidence": "medium",
                "reasoning": "AI reasoning",
                "uncertainties": [],
                "answer_basis": "ai_solution",
            }],
        })
        write_json(root / "verification/page-001.json", {
            "pdf_page": 1,
            "questions": [{"question_number": 1, "status": "needs_review", "findings": [{"field": "prompt", "reason": "uncertain"}]}],
        })

    def test_contract_preserves_ai_and_source_data_without_authoritative_answer(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.fixture_output(root)
            descriptor = descriptor_from_parts(JOB, PROJECT, DOCUMENT, [1], "pipeline-test")
            result = build_result_contract(descriptor, SOURCE_HASH, root, {"dpi": 180})
            question = result["pages"][0]["questions"][0]
            self.assertEqual(question["source_page"], 1)
            self.assertEqual(question["source_region"]["x"], 0.1)
            self.assertEqual(question["ai_answer"]["predicted_choice_index"], 2)
            self.assertEqual(question["ai_answer"]["answer_basis"], "ai_solution")
            self.assertNotIn("correct_choice_index", question)
            self.assertNotIn("authoritative_answer", question)

    def test_visual_metadata_is_preserved_and_serialization_is_stable(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.fixture_output(root)
            write_json(root / "visual_assets/page-001-question-001-diagram-01.png.manifest.json", {
                "pdf_page": 1,
                "question_number": 1,
                "asset_type": "diagram",
                "source_region": {"x": 0.2, "y": 0.3, "width": 0.4, "height": 0.2},
                "output_file": "page-001-question-001-diagram-01.png",
                "pixel_width": 120,
                "pixel_height": 80,
                "checksum": "sha256:" + "b" * 64,
                "confidence": "high",
                "uncertainties": [],
            })
            descriptor = descriptor_from_parts(JOB, PROJECT, DOCUMENT, [1], "pipeline-test")
            result = build_result_contract(descriptor, SOURCE_HASH, root)
            asset = result["pages"][0]["questions"][0]["visual_assets"][0]
            self.assertEqual(asset["source_region"]["width"], 0.4)
            self.assertEqual(asset["pixel_width"], 120)
            self.assertEqual(serialize_result_contract(result), serialize_result_contract(json.loads(serialize_result_contract(result))))
            self.assertTrue(result_contract_sha256(result).startswith("sha256:"))

    def test_invalid_contract_rejects_authoritative_answer_field(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.fixture_output(root)
            descriptor = descriptor_from_parts(JOB, PROJECT, DOCUMENT, [1], "pipeline-test")
            result = build_result_contract(descriptor, SOURCE_HASH, root)
            result["pages"][0]["questions"][0]["correct_choice_index"] = 1
            with self.assertRaises(ImportContractError):
                validate_result_contract(result)

    def test_failed_page_is_explicit_and_valid(self):
        descriptor = descriptor_from_parts(JOB, PROJECT, DOCUMENT, [1], "pipeline-test")
        value = {
            "result_schema_version": "1",
            "job": descriptor.to_dict(),
            "source": {
                "source_document_id": DOCUMENT,
                "source_pdf_sha256": SOURCE_HASH,
                "pipeline_version": "pipeline-test",
                "extraction_options": {},
            },
            "pages": [{"source_page": 1, "status": "quota_exhausted", "error": "429 quota"}],
        }
        self.assertEqual(validate_result_contract(value)["pages"][0]["status"], "quota_exhausted")


if __name__ == "__main__":
    unittest.main()
