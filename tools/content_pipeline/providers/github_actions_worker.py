"""GitHub Actions provider adapter for the provider-neutral worker protocol."""

from __future__ import annotations

import json
import os
import shutil
import sys
import tempfile
import hashlib
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any, Dict, Optional

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from ai_extraction import run as run_extraction
from import_contract import build_result_contract
from worker_protocol import WorkerJobDescriptor


class WorkerControlError(RuntimeError):
    pass


def _request(control_url: str, token: str, path: str, payload: Optional[Dict[str, Any]] = None) -> Optional[Dict[str, Any]]:
    body = None if payload is None else json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        control_url.rstrip("/") + path,
        data=body,
        method="POST",
        headers={"Authorization": "Bearer " + token, "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            if response.status == 204:
                return None
            value = json.loads(response.read().decode("utf-8"))
            if not isinstance(value, dict): raise WorkerControlError("control response was not an object")
            return value
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")[:500]
        raise WorkerControlError("control request failed (%s): %s" % (exc.code, detail)) from exc


def _download(url: str, target: Path) -> None:
    request = urllib.request.Request(url, headers={"Accept": "application/pdf"})
    with urllib.request.urlopen(request, timeout=120) as response, target.open("wb") as output:
        shutil.copyfileobj(response, output)


def _upload_asset(control_url: str, token: str, worker_id: str, job_id: str, asset_key: str, path: Path) -> str:
    request = urllib.request.Request(
        control_url.rstrip("/") + "/api/worker/asset",
        data=path.read_bytes(),
        method="POST",
        headers={
            "Authorization": "Bearer " + token,
            "Content-Type": "image/png",
            "x-job-id": job_id,
            "x-worker-id": worker_id,
            "x-asset-key": asset_key,
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            value = json.loads(response.read().decode("utf-8"))
            return value["storage_path"]
    except (urllib.error.HTTPError, KeyError, json.JSONDecodeError) as exc:
        raise WorkerControlError("visual asset upload failed") from exc


def process_one_job() -> int:
    control_url = os.environ.get("WORKER_CONTROL_URL")
    token = os.environ.get("WORKER_SHARED_SECRET")
    worker_id = os.environ.get("WORKER_ID", "github-actions")
    model = os.environ.get("GEMINI_MODEL")
    if not control_url or not token or not model:
        raise WorkerControlError("WORKER_CONTROL_URL, WORKER_SHARED_SECRET, and GEMINI_MODEL are required")

    claimed = _request(control_url, token, "/api/worker/claim-next", {"worker_id": worker_id})
    if claimed is None:
        return 0
    descriptor = WorkerJobDescriptor.from_dict(claimed["descriptor"])
    source_url = claimed["source_pdf_url"]
    source_hash = claimed["source_pdf_sha256"]

    with tempfile.TemporaryDirectory(prefix="euee-extraction-") as directory:
        root = Path(directory)
        pdf_path = root / "source.pdf"
        output_root = root / "output"
        _download(source_url, pdf_path)
        for page in descriptor.requested_pages:
            _request(control_url, token, "/api/worker/page-started", {"job_id": descriptor.job_id, "worker_id": worker_id, "pdf_page": page})
        exit_code = run_extraction(pdf_path, output_root, model, pages=descriptor.requested_pages)
        result = build_result_contract(descriptor, source_hash, output_root, {"dpi": 180})

        for page_result in result["pages"]:
            page = page_result["source_page"]
            if page_result["status"] != "completed":
                _request(control_url, token, "/api/worker/page-failure", {
                    "job_id": descriptor.job_id, "worker_id": worker_id, "pdf_page": page,
                    "status": page_result["status"], "error": page_result.get("error", "Page processing failed"),
                })
                continue
            for question in page_result.get("questions", []):
                for asset in question.get("visual_assets", []):
                    local_path = output_root / asset["relative_path"]
                    asset["storage_path"] = _upload_asset(control_url, token, worker_id, descriptor.job_id, asset["id"], local_path)
            page_contract = {
                "result_schema_version": result["result_schema_version"],
                "job": result["job"],
                "source": result["source"],
                **page_result,
            }
            _request(control_url, token, "/api/worker/page-result", {
                "job_id": descriptor.job_id, "worker_id": worker_id, "pdf_page": page,
                "result": page_contract,
                "result_checksum": "sha256:" + hashlib.sha256(
                    json.dumps(page_contract, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
                ).hexdigest(),
            })
        _request(control_url, token, "/api/worker/complete", {"job_id": descriptor.job_id, "worker_id": worker_id})
    return exit_code


if __name__ == "__main__":
    try:
        raise SystemExit(process_one_job())
    except Exception as exc:
        print("Worker failed: %s" % exc, file=sys.stderr)
        raise SystemExit(1)
