import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from ai_extraction import (
    ANSWER_ANALYSIS_SCHEMA,
    EXTRACTION_SCHEMA,
    _call_json,
    classify,
    GeminiQuotaExhaustedError,
    GeminiUnavailableError,
    build_blocked_candidate,
    validate_answer_analysis,
    validate_page,
    write_review,
    run,
    store_human_verification,
)


def question(number=1, answer=None):
    return {
        "question_number": number,
        "prompt": "Visible prompt",
        "choices": ["A", "B", "C", "D"],
        "correct_choice_index": answer,
        "answer_status": "authoritative" if answer is not None else "unresolved",
        "source_region": {"x": 0.1, "y": 0.1, "width": 0.8, "height": 0.2},
        "uncertainties": [],
    }


def extraction(page, number):
    return {
        "pdf_page": page,
        "printed_page": page + 13,
        "visible_metadata": [],
        "questions": [question(number)],
    }


def verification(page, number):
    return {
        "pdf_page": page,
        "questions": [{"question_number": number, "status": "verified", "findings": []}],
    }


def answer_analysis(page, number, confidence="high", prediction=1, basis="ai_solution"):
    return {
        "pdf_page": page,
        "questions": [
            {
                "question_number": number,
                "predicted_choice_index": prediction,
                "confidence": confidence,
                "reasoning": "The visible choices support this proposed answer.",
                "uncertainties": [],
                "answer_basis": basis,
            }
        ],
    }


class ExtractionValidationTests(unittest.TestCase):
    def test_nullable_schema_is_accepted_by_genai_config(self):
        from google.genai import types

        config = types.GenerateContentConfig(
            response_mime_type="application/json",
            response_json_schema=EXTRACTION_SCHEMA,
        )

        self.assertEqual(config.response_json_schema, EXTRACTION_SCHEMA)
        self.assertEqual(
            config.response_json_schema["properties"]["printed_page"]["type"],
            ["integer", "null"],
        )
        self.assertEqual(
            config.response_json_schema["properties"]["questions"]["items"]
            ["properties"]["correct_choice_index"]["type"],
            ["integer", "null"],
        )
        self.assertEqual(
            ANSWER_ANALYSIS_SCHEMA["properties"]["questions"]["items"]
            ["properties"]["predicted_choice_index"]["type"],
            ["integer", "null"],
        )

    def test_call_uses_json_schema_without_converting_nullable_union(self):
        class Response:
            text = '{"pdf_page": 1, "questions": []}'

        class Models:
            def generate_content(self, **kwargs):
                self.kwargs = kwargs
                return Response()

        class Client:
            def __init__(self):
                self.models = Models()

        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "page.png"
            image.write_bytes(b"not-a-real-image")
            client = Client()
            result = _call_json(client, "test-model", image, "extract", EXTRACTION_SCHEMA)

        self.assertEqual(result["pdf_page"], 1)
        config = client.models.kwargs["config"]
        self.assertIsNone(config.response_schema)
        self.assertEqual(config.response_json_schema, EXTRACTION_SCHEMA)
        self.assertTrue(config.automatic_function_calling.disable)

    def test_call_classifies_resource_exhausted_as_quota_error(self):
        class Models:
            def generate_content(self, **kwargs):
                raise RuntimeError("429 RESOURCE_EXHAUSTED quota exceeded")

        class Client:
            models = Models()

        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "page.png"
            image.write_bytes(b"image")
            with self.assertRaises(GeminiQuotaExhaustedError):
                _call_json(Client(), "test-model", image, "extract", EXTRACTION_SCHEMA)

    def test_valid_unresolved_extraction_preserves_provenance_shape(self):
        result = validate_page({"pdf_page": 1, "printed_page": 14, "visible_metadata": [], "questions": [question()]}, 1, [])
        self.assertTrue(result["valid"])
        self.assertEqual(result["question_numbers"], [1])

    def test_high_confidence_ai_prediction_is_not_authoritative(self):
        extracted = extraction(1, 1)
        analysis = answer_analysis(1, 1)
        result = validate_answer_analysis(analysis, extracted, 1)
        self.assertTrue(result["valid"])
        self.assertEqual(analysis["questions"][0]["answer_basis"], "ai_solution")
        self.assertIsNone(extracted["questions"][0]["correct_choice_index"])

    def test_medium_prediction_requires_review(self):
        analysis = answer_analysis(1, 1, confidence="medium")
        self.assertEqual(analysis["questions"][0]["confidence"], "medium")
        self.assertEqual(analysis["questions"][0]["answer_basis"], "ai_solution")

    def test_low_prediction_is_unresolved(self):
        analysis = answer_analysis(1, 1, confidence="low", prediction=None, basis="unresolved")
        result = validate_answer_analysis(analysis, extraction(1, 1), 1)
        self.assertTrue(result["valid"])
        self.assertIsNone(analysis["questions"][0]["predicted_choice_index"])

    def test_human_verification_is_stored_separately(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            ai_path = root / "answer_analysis/page-001.json"
            ai_path.parent.mkdir(parents=True)
            original = json.dumps(answer_analysis(1, 1))
            ai_path.write_text(original, encoding="utf-8")
            target = store_human_verification(root, 1, 1, 2, "reviewer", "Checked against source")
            self.assertTrue(target.exists())
            self.assertEqual(ai_path.read_text(encoding="utf-8"), original)
            self.assertEqual(json.loads(target.read_text())["verified_choice_index"], 2)

    def test_blocked_candidate_keeps_ai_answer_non_authoritative(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            result = __import__("ai_extraction").PageResult(
                page=1,
                extracted=extraction(1, 1),
                validation={"errors": [], "warnings": []},
                answer_analysis=answer_analysis(1, 1),
            )
            output = root / "blocked.json"
            build_blocked_candidate([result], Path("paper.pdf"), output)
            payload = json.loads(output.read_text())
            self.assertEqual(payload["status"], "blocked")
            self.assertEqual(payload["questions"][0]["ai_answer_analysis"]["answer_basis"], "ai_solution")

    def test_duplicate_numbers_fail(self):
        result = validate_page({"pdf_page": 1, "printed_page": 14, "visible_metadata": [], "questions": [question(), question()]}, 1, [])
        self.assertFalse(result["valid"])
        self.assertTrue(any("duplicate" in error for error in result["errors"]))

    def test_wrong_choice_count_fails(self):
        item = question()
        item["choices"] = ["A", "B"]
        result = validate_page({"pdf_page": 1, "printed_page": 14, "visible_metadata": [], "questions": [item]}, 1, [])
        self.assertFalse(result["valid"])

    def test_answer_marking_remains_yellow_when_unresolved(self):
        item = question()
        validation = validate_page({"pdf_page": 1, "printed_page": 14, "visible_metadata": [], "questions": [item]}, 1, [])
        self.assertEqual(classify(validation, {"questions": [{"question_number": 1, "status": "verified", "findings": []}]}, item), "YELLOW")

    def test_review_artifact_contains_uncertain_question(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "review.md"
            from ai_extraction import PageResult
            result = PageResult(page=1, extracted={"pdf_page": 1, "questions": [question()]}, validation={"errors": [], "warnings": []}, verification={"questions": []})
            counts = write_review([result], path)
            self.assertEqual(counts["YELLOW"], 1)
            self.assertIn("Question 1", path.read_text(encoding="utf-8"))

    def test_review_artifact_shows_high_confidence_ai_answer(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "review.md"
            from ai_extraction import PageResult
            result = PageResult(
                page=1,
                extracted=extraction(1, 1),
                validation={"errors": [], "warnings": []},
                answer_analysis=answer_analysis(1, 1),
                verification={"questions": []},
            )
            write_review([result], path)
            report = path.read_text(encoding="utf-8")
            self.assertIn("Gemini proposed answer", report)
            self.assertIn("ai_solution", report)

    def test_quota_error_stops_processing_immediately(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            images = [root / "page-001.png", root / "page-002.png"]
            for image in images:
                image.write_bytes(b"image")
            with patch.dict(os.environ, {"GEMINI_API_KEY": "test-key"}), patch(
                "ai_extraction.render_pages", return_value=images
            ), patch(
                "ai_extraction._call_json",
                side_effect=GeminiQuotaExhaustedError("429 RESOURCE_EXHAUSTED"),
            ) as call:
                run(Path("paper.pdf"), root, "test-model", client=object())

            self.assertEqual(call.call_count, 1)
            summary = json.loads((root / "run_summary.json").read_text(encoding="utf-8"))
            self.assertEqual(summary["status"], "quota_exhausted")
            self.assertEqual(summary["gemini_calls"], 1)

    def test_completed_pages_are_skipped_on_resume(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            images = [root / "page-001.png", root / "page-002.png"]
            for image in images:
                image.write_bytes(b"image")
            for name in ("raw_extraction", "validated_extraction", "verification", "human_review"):
                (root / name).mkdir()
            (root / "answer_analysis").mkdir()
            (root / "raw_extraction/page-001.json").write_text(json.dumps(extraction(1, 1)), encoding="utf-8")
            (root / "answer_analysis/page-001.json").write_text(json.dumps(answer_analysis(1, 1)), encoding="utf-8")
            (root / "verification/page-001.json").write_text(json.dumps(verification(1, 1)), encoding="utf-8")
            responses = [extraction(2, 2), answer_analysis(2, 2), verification(2, 2)]
            with patch.dict(os.environ, {"GEMINI_API_KEY": "test-key"}), patch(
                "ai_extraction.render_pages", return_value=images
            ), patch("ai_extraction._call_json", side_effect=responses) as call:
                run(Path("paper.pdf"), root, "test-model", client=object())

            self.assertEqual(call.call_count, 3)
            self.assertEqual(json.loads((root / "raw_extraction/page-001.json").read_text()), extraction(1, 1))

    def test_missing_verification_is_retried_without_reextracting(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            image = root / "page-001.png"
            image.write_bytes(b"image")
            (root / "raw_extraction").mkdir(parents=True)
            (root / "answer_analysis").mkdir(parents=True)
            (root / "raw_extraction/page-001.json").write_text(json.dumps(extraction(1, 1)), encoding="utf-8")
            with patch.dict(os.environ, {"GEMINI_API_KEY": "test-key"}), patch(
                "ai_extraction.render_pages", return_value=[image]
            ), patch("ai_extraction._call_json", side_effect=[answer_analysis(1, 1), verification(1, 1)]) as call:
                run(Path("paper.pdf"), root, "test-model", client=object())

            self.assertEqual(call.call_count, 2)
            self.assertTrue((root / "verification/page-001.json").exists())

    def test_transient_503_does_not_corrupt_completed_artifacts(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            images = [root / "page-001.png", root / "page-002.png"]
            for image in images:
                image.write_bytes(b"image")
            (root / "raw_extraction").mkdir(parents=True)
            (root / "answer_analysis").mkdir(parents=True)
            (root / "verification").mkdir(parents=True)
            raw = json.dumps(extraction(1, 1))
            verified = json.dumps(verification(1, 1))
            (root / "raw_extraction/page-001.json").write_text(raw, encoding="utf-8")
            (root / "answer_analysis/page-001.json").write_text(json.dumps(answer_analysis(1, 1)), encoding="utf-8")
            (root / "verification/page-001.json").write_text(verified, encoding="utf-8")
            with patch.dict(os.environ, {"GEMINI_API_KEY": "test-key"}), patch(
                "ai_extraction.render_pages", return_value=images
            ), patch(
                "ai_extraction._call_json",
                side_effect=GeminiUnavailableError("503 UNAVAILABLE"),
            ):
                run(Path("paper.pdf"), root, "test-model", client=object())

            self.assertEqual((root / "raw_extraction/page-001.json").read_text(), raw)
            self.assertEqual((root / "verification/page-001.json").read_text(), verified)
            summary = json.loads((root / "run_summary.json").read_text(encoding="utf-8"))
            self.assertEqual(summary["status"], "completed_with_errors")
            self.assertTrue(any("GeminiUnavailableError" in error for error in summary["errors"]))


if __name__ == "__main__":
    unittest.main()
