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
    VISUAL_ASSET_TYPES,
    _call_json,
    _compute_checksum,
    _crop_visual_assets,
    parse_page_selection,
    classify,
    GeminiQuotaExhaustedError,
    GeminiUnavailableError,
    build_blocked_candidate,
    validate_answer_analysis,
    validate_page,
    validate_visual_assets,
    validate_visual_asset_crops,
    write_review,
    run,
    store_human_verification,
)


def visual_asset(asset_type="image", x=0.1, y=0.1, width=0.2, height=0.2, confidence="high", uncertainties=None):
    return {
        "type": asset_type,
        "source_region": {"x": x, "y": y, "width": width, "height": height},
        "confidence": confidence,
        "uncertainties": uncertainties or [],
    }


def question(number=1, answer=None, visual_assets=None):
    item = {
        "question_number": number,
        "prompt": "Visible prompt",
        "choices": ["A", "B", "C", "D"],
        "correct_choice_index": answer,
        "answer_status": "authoritative" if answer is not None else "unresolved",
        "source_region": {"x": 0.1, "y": 0.1, "width": 0.8, "height": 0.2},
        "uncertainties": [],
    }
    if visual_assets is not None:
        item["visual_assets"] = visual_assets
    return item


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
    def test_page_selection_parses_single_pages_and_ranges(self):
        self.assertEqual(parse_page_selection("1"), [1])
        self.assertEqual(parse_page_selection("1, 3-4, 3"), [1, 3, 4])

    def test_page_selection_rejects_invalid_ranges(self):
        with self.assertRaises(ValueError):
            parse_page_selection("0")
        with self.assertRaises(ValueError):
            parse_page_selection("4-2")

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

    def test_run_passes_selected_pages_to_renderer(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            image = root / "page-001.png"
            image.write_bytes(b"image")
            with patch.dict(os.environ, {"GEMINI_API_KEY": "test-key"}), patch(
                "ai_extraction.render_pages", return_value=[image]
            ) as render, patch(
                "ai_extraction._call_json",
                side_effect=[extraction(1, 1), answer_analysis(1, 1), verification(1, 1)],
            ):
                run(Path("paper.pdf"), root, "test-model", client=object(), pages=[1])

            self.assertEqual(render.call_args.args[3], [1])

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


class VisualAssetValidationTests(unittest.TestCase):
    def test_valid_visual_assets_pass(self):
        ext = {
            "pdf_page": 1,
            "printed_page": 14,
            "visible_metadata": [],
            "questions": [question(1, visual_assets=[visual_asset()])],
        }
        errors = validate_visual_assets(ext, 1)
        self.assertEqual(errors, [])

    def test_all_asset_types_accepted(self):
        for atype in sorted(VISUAL_ASSET_TYPES):
            ext = {
                "pdf_page": 1,
                "printed_page": 14,
                "visible_metadata": [],
                "questions": [question(1, visual_assets=[visual_asset(asset_type=atype)])],
            }
            errors = validate_visual_assets(ext, 1)
            self.assertEqual(errors, [], "type %s should be valid" % atype)

    def test_invalid_asset_type_fails(self):
        ext = {
            "pdf_page": 1,
            "printed_page": 14,
            "visible_metadata": [],
            "questions": [question(1, visual_assets=[visual_asset(asset_type="chart")])],
        }
        errors = validate_visual_assets(ext, 1)
        self.assertTrue(any("type" in e for e in errors))

    def test_bbox_out_of_range_fails(self):
        ext = {
            "pdf_page": 1,
            "printed_page": 14,
            "visible_metadata": [],
            "questions": [question(1, visual_assets=[visual_asset(x=1.5, y=0.1, width=0.2, height=0.2)])],
        }
        errors = validate_visual_assets(ext, 1)
        self.assertTrue(any("[0, 1]" in e for e in errors))

    def test_zero_width_bbox_fails(self):
        ext = {
            "pdf_page": 1,
            "printed_page": 14,
            "visible_metadata": [],
            "questions": [question(1, visual_assets=[visual_asset(width=0, height=0.2)])],
        }
        errors = validate_visual_assets(ext, 1)
        self.assertTrue(any("width" in e for e in errors))

    def test_two_distinct_assets_pass(self):
        ext = {
            "pdf_page": 1,
            "printed_page": 14,
            "visible_metadata": [],
            "questions": [question(1, visual_assets=[
                visual_asset(asset_type="image"),
                visual_asset(asset_type="graph"),
            ])],
        }
        errors = validate_visual_assets(ext, 1)
        self.assertEqual(errors, [])

    def test_invalid_confidence_fails(self):
        ext = {
            "pdf_page": 1,
            "printed_page": 14,
            "visible_metadata": [],
            "questions": [question(1, visual_assets=[visual_asset(confidence="sure")])],
        }
        errors = validate_visual_assets(ext, 1)
        self.assertTrue(any("confidence" in e for e in errors))

    def test_uncertainties_must_be_string_array(self):
        ext = {
            "pdf_page": 1,
            "printed_page": 14,
            "visible_metadata": [],
            "questions": [question(1, visual_assets=[visual_asset(uncertainties=[123])])],
        }
        errors = validate_visual_assets(ext, 1)
        self.assertTrue(any("uncertainties" in e for e in errors))

    def test_no_visual_assets_passes(self):
        ext = {
            "pdf_page": 1,
            "printed_page": 14,
            "visible_metadata": [],
            "questions": [question(1)],
        }
        errors = validate_visual_assets(ext, 1)
        self.assertEqual(errors, [])

    def test_null_source_region_fails(self):
        ext = {
            "pdf_page": 1,
            "printed_page": 14,
            "visible_metadata": [],
            "questions": [question(1, visual_assets=[{"type": "image", "source_region": None, "confidence": "high", "uncertainties": []}])],
        }
        errors = validate_visual_assets(ext, 1)
        self.assertTrue(any("source_region" in e for e in errors))


class VisualAssetCropTests(unittest.TestCase):
    def _make_valid_extraction_with_crop(self, root, page=1):
        """Create a minimal valid extraction with one visual asset and a crop file."""
        assets_dir = root / "visual_assets"
        assets_dir.mkdir(parents=True, exist_ok=True)

        crop_name = "page-%03d-question-%03d-image-01.png" % (page, 1)
        crop_path = assets_dir / crop_name
        # Simulate a small PNG file (>100 bytes to pass size check).
        crop_path.write_bytes(b"\x89PNG\r\n\x1a\n" + b"\x00" * 200)

        manifest = {
            "pdf_page": page,
            "question_number": 1,
            "asset_type": "image",
            "source_region": {"x": 0.1, "y": 0.2, "width": 0.3, "height": 0.4},
            "output_file": crop_name,
            "pixel_width": 50,
            "pixel_height": 60,
            "checksum": _compute_checksum(crop_path.read_bytes()),
            "confidence": "high",
            "uncertainties": [],
        }
        manifest_path = assets_dir / (crop_name + ".manifest.json")
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

        ext = {
            "pdf_page": page,
            "printed_page": 14,
            "visible_metadata": [],
            "questions": [question(1, visual_assets=[visual_asset()])],
        }
        return ext, crop_path, manifest_path

    def test_valid_crop_passes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            ext, _, _ = self._make_valid_extraction_with_crop(root)
            errors = validate_visual_asset_crops(root, ext, 1)
            self.assertEqual(errors, [])

    def test_missing_crop_file_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            ext, _, _ = self._make_valid_extraction_with_crop(root)
            # Remove the crop file.
            (root / "visual_assets/page-001-question-001-image-01.png").unlink()
            errors = validate_visual_asset_crops(root, ext, 1)
            self.assertTrue(any("missing" in e for e in errors))

    def test_missing_manifest_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            ext, _, _ = self._make_valid_extraction_with_crop(root)
            # Remove the manifest.
            (root / "visual_assets/page-001-question-001-image-01.png.manifest.json").unlink()
            errors = validate_visual_asset_crops(root, ext, 1)
            self.assertTrue(any("manifest" in e for e in errors))

    def test_checksum_mismatch_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            ext, crop_path, manifest_path = self._make_valid_extraction_with_crop(root)
            # Tamper with the crop file.
            crop_path.write_bytes(b"\x89PNG\r\n\x1a\n" + b"\xFF" * 300)
            errors = validate_visual_asset_crops(root, ext, 1)
            self.assertTrue(any("checksum" in e for e in errors))

    def test_manifest_pixel_dimensions_missing_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            ext, _, manifest_path = self._make_valid_extraction_with_crop(root)
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            del manifest["pixel_width"]
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            errors = validate_visual_asset_crops(root, ext, 1)
            self.assertTrue(any("pixel" in e for e in errors))

    def test_crop_too_small_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            ext, crop_path, _ = self._make_valid_extraction_with_crop(root)
            crop_path.write_bytes(b"\x89PNG\r\n\x1a\n" + b"\x00" * 50)
            errors = validate_visual_asset_crops(root, ext, 1)
            self.assertTrue(any("small" in e for e in errors))


class VisualAssetIntegrationTests(unittest.TestCase):
    def test_visual_assets_appear_in_review(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "review.md"
            result = __import__("ai_extraction").PageResult(
                page=1,
                extracted={
                    "pdf_page": 1,
                    "printed_page": 14,
                    "visible_metadata": [],
                    "questions": [question(1, visual_assets=[visual_asset(confidence="low")])],
                },
                validation={"errors": [], "warnings": []},
                verification={"questions": []},
            )
            counts = write_review([result], path)
            report = path.read_text(encoding="utf-8")
            self.assertIn("Visual assets", report)
            self.assertIn("low", report)

    def test_visual_assets_in_blocked_candidate(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            result = __import__("ai_extraction").PageResult(
                page=1,
                extracted={
                    "pdf_page": 1,
                    "printed_page": 14,
                    "visible_metadata": [],
                    "questions": [question(1, visual_assets=[visual_asset()])],
                },
                validation={"errors": [], "warnings": []},
                answer_analysis=answer_analysis(1, 1),
            )
            output = root / "blocked.json"
            build_blocked_candidate([result], Path("paper.pdf"), output)
            payload = json.loads(output.read_text())
            self.assertIn("questions", payload)
            # Blocked candidate includes the visual_assets from extraction.
            q = payload["questions"][0]
            self.assertIn("visual_assets", q)

    def test_low_confidence_visual_flags_yellow(self):
        item = question(1, visual_assets=[visual_asset(confidence="low")])
        validation = validate_page(
            {
                "pdf_page": 1,
                "printed_page": 14,
                "visible_metadata": [],
                "questions": [item],
            },
            1,
            [],
        )
        classification = classify(
            validation,
            {"questions": [{"question_number": 1, "status": "verified", "findings": []}]},
            item,
        )
        self.assertEqual(classification, "YELLOW")

    def test_high_confidence_visual_stays_green(self):
        item = question(1, answer=1, visual_assets=[visual_asset(confidence="high")])
        validation = validate_page(
            {
                "pdf_page": 1,
                "printed_page": 14,
                "visible_metadata": [],
                "questions": [item],
            },
            1,
            [],
        )
        classification = classify(
            validation,
            {"questions": [{"question_number": 1, "status": "verified", "findings": []}]},
            item,
        )
        self.assertEqual(classification, "GREEN")

    def test_visual_with_uncertainties_flags_yellow(self):
        item = question(1, visual_assets=[visual_asset(uncertainties=["partially visible"])])
        validation = validate_page(
            {
                "pdf_page": 1,
                "printed_page": 14,
                "visible_metadata": [],
                "questions": [item],
            },
            1,
            [],
        )
        classification = classify(
            validation,
            {"questions": [{"question_number": 1, "status": "verified", "findings": []}]},
            item,
        )
        self.assertEqual(classification, "YELLOW")


class DeterministicCropIntegrationTests(unittest.TestCase):
    """Integration tests using the real rendered page-003.png from prior output."""

    SOURCE_PAGE = Path(__file__).resolve().parents[1] / "output" / "formal_exam" / "pages" / "page-003.png"

    def _make_extraction(self, question_number=72, asset_type="graph", x=0.1, y=0.3, width=0.8, height=0.3):
        return {
            "pdf_page": 3,
            "printed_page": 16,
            "visible_metadata": [],
            "questions": [
                {
                    "question_number": question_number,
                    "prompt": "The following graph shows the rate of reaction of catalase enzyme.",
                    "choices": ["0.4 to 0.5", "0.1 to 0.2", "0.5 to 0.6", "0.3 to 0.4"],
                    "correct_choice_index": None,
                    "answer_status": "unresolved",
                    "source_region": {"x": 0.05, "y": 0.25, "width": 0.9, "height": 0.5},
                    "uncertainties": [],
                    "visual_assets": [
                        {
                            "type": asset_type,
                            "source_region": {"x": x, "y": y, "width": width, "height": height},
                            "confidence": "high",
                            "uncertainties": [],
                        }
                    ],
                }
            ],
        }

    @unittest.skipUnless(
        SOURCE_PAGE.exists(),
        "rendered page-003.png not found; run extraction first",
    )
    def test_crop_creates_file_with_correct_dimensions(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "visual_assets").mkdir()
            extraction = self._make_extraction()
            manifests = _crop_visual_assets(extraction, self.SOURCE_PAGE, root, 3)
            self.assertEqual(len(manifests), 1)
            m = manifests[0]
            crop_path = root / "visual_assets" / m["output_file"]
            self.assertTrue(crop_path.exists())
            # Page is 595.6 x 842.0 pixels. 0.8*595.6=476.48->476, 0.3*842.0=252.6->253.
            self.assertEqual(m["pixel_width"], 476)
            self.assertEqual(m["pixel_height"], 253)
            self.assertGreater(crop_path.stat().st_size, 100)

    @unittest.skipUnless(
        SOURCE_PAGE.exists(),
        "rendered page-003.png not found; run extraction first",
    )
    def test_crop_stays_inside_page_boundary(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "visual_assets").mkdir()
            extraction = self._make_extraction(x=0.9, y=0.9, width=0.2, height=0.2)
            manifests = _crop_visual_assets(extraction, self.SOURCE_PAGE, root, 3)
            m = manifests[0]
            # Clamped: x=0.9, w=min(0.2, 1.0-0.9)=0.1, y=0.9, h=min(0.2, 1.0-0.9)=0.1
            self.assertEqual(m["source_region"]["x"], 0.9)
            self.assertEqual(m["source_region"]["width"], 0.1)
            self.assertEqual(m["source_region"]["y"], 0.9)
            self.assertEqual(m["source_region"]["height"], 0.1)
            crop_path = root / "visual_assets" / m["output_file"]
            self.assertTrue(crop_path.exists())

    @unittest.skipUnless(
        SOURCE_PAGE.exists(),
        "rendered page-003.png not found; run extraction first",
    )
    def test_manifest_has_sha256_checksum(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "visual_assets").mkdir()
            extraction = self._make_extraction()
            manifests = _crop_visual_assets(extraction, self.SOURCE_PAGE, root, 3)
            m = manifests[0]
            self.assertTrue(m["checksum"].startswith("sha256:"))
            crop_bytes = (root / "visual_assets" / m["output_file"]).read_bytes()
            self.assertEqual(m["checksum"], _compute_checksum(crop_bytes))

    @unittest.skipUnless(
        SOURCE_PAGE.exists(),
        "rendered page-003.png not found; run extraction first",
    )
    def test_source_page_unchanged_after_crop(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "visual_assets").mkdir()
            original_bytes = self.SOURCE_PAGE.read_bytes()
            extraction = self._make_extraction()
            _crop_visual_assets(extraction, self.SOURCE_PAGE, root, 3)
            self.assertEqual(self.SOURCE_PAGE.read_bytes(), original_bytes)

    @unittest.skipUnless(
        SOURCE_PAGE.exists(),
        "rendered page-003.png not found; run extraction first",
    )
    def test_rerun_reuses_valid_crop(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "visual_assets").mkdir()
            extraction = self._make_extraction()
            manifests1 = _crop_visual_assets(extraction, self.SOURCE_PAGE, root, 3)
            crop_path = root / "visual_assets" / manifests1[0]["output_file"]
            mtime1 = crop_path.stat().st_mtime
            manifests2 = _crop_visual_assets(extraction, self.SOURCE_PAGE, root, 3)
            mtime2 = crop_path.stat().st_mtime
            self.assertEqual(manifests1[0]["checksum"], manifests2[0]["checksum"])
            self.assertEqual(mtime1, mtime2)

    @unittest.skipUnless(
        SOURCE_PAGE.exists(),
        "rendered page-003.png not found; run extraction first",
    )
    def test_crop_validates_cleanly(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "visual_assets").mkdir()
            extraction = self._make_extraction()
            _crop_visual_assets(extraction, self.SOURCE_PAGE, root, 3)
            errors = validate_visual_asset_crops(root, extraction, 3)
            self.assertEqual(errors, [])


if __name__ == "__main__":
    unittest.main()
