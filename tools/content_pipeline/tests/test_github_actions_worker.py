import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import providers.github_actions_worker as worker


JOB = "11111111-1111-4111-8111-111111111111"
PROJECT = "22222222-2222-4222-8222-222222222222"
DOCUMENT = "33333333-3333-4333-8333-333333333333"


def write_json(path: Path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    import json
    path.write_text(json.dumps(value), encoding="utf-8")


class GithubActionsWorkerTests(unittest.TestCase):
    def test_provider_adapter_submits_contract_without_gemini_in_test(self):
        descriptor = {
            "protocol_version": "1",
            "job_id": JOB,
            "project_id": PROJECT,
            "source_document_id": DOCUMENT,
            "requested_pages": [1],
            "pipeline_version": "test",
            "result_schema_version": "1",
        }

        def fake_run(pdf, output, model, pages=None):
            write_json(output / "raw_extraction/page-001.json", {
                "pdf_page": 1, "printed_page": None, "visible_metadata": [], "questions": [{
                    "question_number": 1, "prompt": "Prompt", "choices": ["A", "B", "C", "D"],
                    "correct_choice_index": None, "answer_status": "unresolved", "source_region": None, "uncertainties": [],
                }],
            })
            write_json(output / "validated_extraction/page-001.json", {"pdf_page": 1, "valid": True, "errors": [], "warnings": []})
            write_json(output / "verification/page-001.json", {"pdf_page": 1, "questions": []})
            return 0

        calls = []

        def fake_request(control_url, token, path, payload=None):
            calls.append((path, payload))
            if path == "/api/worker/claim-next":
                return {"descriptor": descriptor, "source_pdf_sha256": "a" * 64, "source_pdf_url": "https://signed.invalid"}
            return {"ok": True}

        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, {
            "WORKER_CONTROL_URL": "https://studio.invalid",
            "WORKER_SHARED_SECRET": "test-secret",
            "WORKER_ID": "test-worker",
            "GEMINI_MODEL": "test-model",
        }, clear=False), patch.object(worker, "_request", side_effect=fake_request), patch.object(worker, "_download", side_effect=lambda url, target: target.write_bytes(b"pdf")), patch.object(worker, "run_extraction", side_effect=fake_run):
            self.assertEqual(worker.process_one_job(), 0)

        paths = [path for path, _ in calls]
        self.assertIn("/api/worker/page-started", paths)
        self.assertIn("/api/worker/page-result", paths)
        self.assertIn("/api/worker/complete", paths)
        result_payload = next(payload for path, payload in calls if path == "/api/worker/page-result")
        self.assertIsNone(result_payload["result"]["questions"][0].get("correct_choice_index"))


if __name__ == "__main__":
    unittest.main()
