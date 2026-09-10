"""Versioned conversion of extraction artifacts into a staging contract."""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional

from worker_protocol import WorkerJobDescriptor


RESULT_SCHEMA_VERSION = "1"
_SHA256_RE = re.compile(r"^(?:sha256:)?[0-9a-fA-F]{64}$")
_REGION_KEYS = ("x", "y", "width", "height")
_CONFIDENCES = {"high", "medium", "low"}
_ANSWER_BASES = {"source_answer_key", "ai_solution", "unresolved"}
_VERIFICATION_STATUSES = {"verified", "needs_review", "critical_error"}


class ImportContractError(ValueError):
    """Raised when a result contract is malformed or unsafe to stage."""


def _read_json(path: Path, required: bool = True) -> Optional[Dict[str, Any]]:
    if not path.exists():
        if required:
            raise ImportContractError("missing artifact: %s" % path)
        return None
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ImportContractError("invalid JSON artifact: %s" % path) from exc
    if not isinstance(value, dict):
        raise ImportContractError("artifact must be an object: %s" % path)
    return value


def _region(value: Any, field: str, allow_none: bool = True) -> Optional[Dict[str, float]]:
    if value is None and allow_none:
        return None
    if not isinstance(value, dict) or any(not isinstance(value.get(key), (int, float)) for key in _REGION_KEYS):
        raise ImportContractError("%s must be a normalized region" % field)
    result = {key: float(value[key]) for key in _REGION_KEYS}
    if any(result[key] < 0 or result[key] > 1 for key in _REGION_KEYS):
        raise ImportContractError("%s must use coordinates in [0, 1]" % field)
    if result["width"] <= 0 or result["height"] <= 0:
        raise ImportContractError("%s must have positive dimensions" % field)
    return result


def _sha256(value: Any, field: str) -> str:
    if not isinstance(value, str) or not _SHA256_RE.fullmatch(value):
        raise ImportContractError("%s must be a SHA-256 checksum" % field)
    return value.lower()


def _asset_id(question_id: str, index: int) -> str:
    return "%s:asset-%02d" % (question_id, index)


def _question_id(job_id: str, page: int, number: int) -> str:
    return "%s:page-%03d:question-%03d" % (job_id, page, number)


def _canonical(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def validate_result_contract(value: Any) -> Dict[str, Any]:
    if not isinstance(value, dict):
        raise ImportContractError("result contract must be an object")
    if value.get("result_schema_version") != RESULT_SCHEMA_VERSION:
        raise ImportContractError("unsupported result_schema_version")
    job = value.get("job")
    descriptor = WorkerJobDescriptor.from_dict(job)
    source = value.get("source")
    if not isinstance(source, dict):
        raise ImportContractError("source must be an object")
    if source.get("source_document_id") != descriptor.source_document_id:
        raise ImportContractError("source document does not match job descriptor")
    _sha256(source.get("source_pdf_sha256"), "source.source_pdf_sha256")
    if not isinstance(source.get("extraction_options"), dict):
        raise ImportContractError("source.extraction_options must be an object")
    pages = value.get("pages")
    if not isinstance(pages, list):
        raise ImportContractError("pages must be an array")
    seen_pages = set()
    for page_result in pages:
        if not isinstance(page_result, dict):
            raise ImportContractError("page result must be an object")
        page = page_result.get("source_page")
        if not isinstance(page, int) or page not in descriptor.requested_pages or page in seen_pages:
            raise ImportContractError("page result is not a unique requested page")
        seen_pages.add(page)
        status = page_result.get("status")
        if status not in {"completed", "failed", "quota_exhausted"}:
            raise ImportContractError("unsupported page result status")
        if status != "completed":
            if not isinstance(page_result.get("error"), str) or not page_result["error"].strip():
                raise ImportContractError("failed page result requires an error")
            continue
        questions = page_result.get("questions")
        if not isinstance(questions, list):
            raise ImportContractError("completed page questions must be an array")
        numbers = set()
        for question in questions:
            if not isinstance(question, dict):
                raise ImportContractError("question must be an object")
            number = question.get("question_number")
            if not isinstance(number, int) or number <= 0 or number in numbers:
                raise ImportContractError("question_number must be unique and positive")
            numbers.add(number)
            if question.get("id") != _question_id(descriptor.job_id, page, number):
                raise ImportContractError("question id is not deterministic")
            allowed_question_fields = {
                "id", "source_page", "question_number", "prompt", "choices",
                "source_region", "uncertainties", "ai_answer", "verification", "visual_assets",
            }
            unexpected_question_fields = set(question) - allowed_question_fields
            if unexpected_question_fields:
                raise ImportContractError("unexpected question fields: %s" % ", ".join(sorted(unexpected_question_fields)))
            if not isinstance(question.get("prompt"), str) or not question["prompt"].strip():
                raise ImportContractError("question prompt is required")
            if not isinstance(question.get("choices"), list) or any(not isinstance(c, str) for c in question["choices"]):
                raise ImportContractError("question choices must be strings")
            _region(question.get("source_region"), "question.source_region")
            if not isinstance(question.get("uncertainties"), list) or any(not isinstance(u, str) for u in question["uncertainties"]):
                raise ImportContractError("question uncertainties must be strings")
            answer = question.get("ai_answer")
            if answer is not None:
                if not isinstance(answer, dict) or answer.get("answer_basis") not in _ANSWER_BASES:
                    raise ImportContractError("invalid AI answer basis")
                prediction = answer.get("predicted_choice_index")
                if prediction is not None and (not isinstance(prediction, int) or prediction < 0 or prediction >= len(question["choices"])):
                    raise ImportContractError("invalid AI prediction")
                if answer.get("confidence") not in _CONFIDENCES or not isinstance(answer.get("reasoning"), str):
                    raise ImportContractError("invalid AI answer metadata")
            verification = question.get("verification")
            if verification is not None:
                if not isinstance(verification, dict) or verification.get("status") not in _VERIFICATION_STATUSES:
                    raise ImportContractError("invalid verification metadata")
                if not isinstance(verification.get("findings"), list):
                    raise ImportContractError("verification findings must be an array")
            assets = question.get("visual_assets", [])
            if not isinstance(assets, list):
                raise ImportContractError("visual_assets must be an array")
            for index, asset in enumerate(assets, 1):
                if not isinstance(asset, dict) or asset.get("id") != _asset_id(question["id"], index):
                    raise ImportContractError("visual asset id is not deterministic")
                allowed_asset_fields = {
                    "id", "asset_type", "source_page", "relative_path", "storage_path",
                    "source_region", "confidence", "uncertainties", "sha256", "pixel_width", "pixel_height",
                }
                if set(asset) - allowed_asset_fields:
                    raise ImportContractError("unexpected visual asset fields")
                if not isinstance(asset.get("asset_type"), str) or not isinstance(asset.get("relative_path"), str):
                    raise ImportContractError("visual asset identity is required")
                _region(asset.get("source_region"), "visual_asset.source_region", allow_none=False)
                if asset.get("confidence") not in _CONFIDENCES:
                    raise ImportContractError("invalid visual asset confidence")
                if not isinstance(asset.get("uncertainties"), list) or any(not isinstance(u, str) for u in asset["uncertainties"]):
                    raise ImportContractError("visual asset uncertainties must be strings")
                _sha256(asset.get("sha256"), "visual_asset.sha256")
                if not isinstance(asset.get("pixel_width"), int) or not isinstance(asset.get("pixel_height"), int):
                    raise ImportContractError("visual asset dimensions are required")
                if asset["pixel_width"] <= 0 or asset["pixel_height"] <= 0:
                    raise ImportContractError("visual asset dimensions must be positive")
    if seen_pages != set(descriptor.requested_pages):
        raise ImportContractError("result must contain every requested page")
    return value


def build_result_contract(
    descriptor: WorkerJobDescriptor,
    source_pdf_sha256: str,
    output_root: Path,
    extraction_options: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Read existing pipeline artifacts without changing the extraction engine."""
    source_hash = _sha256(source_pdf_sha256, "source_pdf_sha256")
    pages: List[Dict[str, Any]] = []
    for page in descriptor.requested_pages:
        raw = _read_json(output_root / "raw_extraction" / ("page-%03d.json" % page), required=False)
        error_paths = [
            output_root / "validated_extraction" / ("page-%03d.error.json" % page),
            output_root / "answer_analysis" / ("page-%03d.error.json" % page),
        ]
        error = next((_read_json(path, required=False) for path in error_paths if path.exists()), None)
        if raw is None:
            pages.append({
                "source_page": page,
                "status": "quota_exhausted" if error and "quota" in str(error.get("error", "")).lower() else "failed",
                "error": (error or {}).get("error", "No extraction artifact was produced"),
            })
            continue

        validation = _read_json(output_root / "validated_extraction" / ("page-%03d.json" % page), required=False) or {}
        if validation.get("errors") or validation.get("valid") is False:
            pages.append({
                "source_page": page,
                "status": "failed",
                "error": "; ".join(str(error) for error in validation.get("errors", [])) or "Deterministic validation failed",
            })
            continue
        analysis = _read_json(output_root / "answer_analysis" / ("page-%03d.json" % page), required=False)
        verification = _read_json(output_root / "verification" / ("page-%03d.json" % page), required=False)
        analysis_by_number = {item.get("question_number"): item for item in (analysis or {}).get("questions", []) if isinstance(item, dict)}
        verification_by_number = {item.get("question_number"): item for item in (verification or {}).get("questions", []) if isinstance(item, dict)}
        visual_by_number: Dict[int, List[Dict[str, Any]]] = {}
        for manifest_path in sorted((output_root / "visual_assets").glob("page-%03d-question-*.png.manifest.json" % page)):
            manifest = _read_json(manifest_path)
            if manifest is None:
                continue
            number = manifest.get("question_number")
            index = len(visual_by_number.setdefault(number, [])) + 1
            crop_path = output_root / "visual_assets" / manifest["output_file"]
            visual_by_number[number].append({
                "id": _asset_id(_question_id(descriptor.job_id, page, number), index),
                "asset_type": manifest.get("asset_type"),
                "source_page": page,
                "relative_path": str(crop_path.relative_to(output_root)).replace("\\", "/"),
                "storage_path": None,
                "source_region": manifest.get("source_region"),
                "confidence": manifest.get("confidence"),
                "uncertainties": manifest.get("uncertainties", []),
                "sha256": manifest.get("checksum"),
                "pixel_width": manifest.get("pixel_width"),
                "pixel_height": manifest.get("pixel_height"),
            })

        questions = []
        for question in raw.get("questions", []):
            number = question.get("question_number")
            answer_item = analysis_by_number.get(number)
            verification_item = verification_by_number.get(number)
            questions.append({
                "id": _question_id(descriptor.job_id, page, number),
                "source_page": page,
                "question_number": number,
                "prompt": question.get("prompt"),
                "choices": question.get("choices"),
                "source_region": question.get("source_region"),
                "uncertainties": question.get("uncertainties", []),
                "ai_answer": None if answer_item is None else {
                    "predicted_choice_index": answer_item.get("predicted_choice_index"),
                    "confidence": answer_item.get("confidence"),
                    "reasoning": answer_item.get("reasoning"),
                    "uncertainties": answer_item.get("uncertainties", []),
                    "answer_basis": answer_item.get("answer_basis"),
                },
                "verification": None if verification_item is None else {
                    "status": verification_item.get("status"),
                    "findings": verification_item.get("findings", []),
                },
                "visual_assets": visual_by_number.get(number, []),
            })
        pages.append({
            "source_page": page,
            "status": "completed" if validation.get("valid", True) else "failed",
            "validation": validation,
            "questions": questions,
        })

    result = {
        "result_schema_version": RESULT_SCHEMA_VERSION,
        "job": descriptor.to_dict(),
        "source": {
            "source_document_id": descriptor.source_document_id,
            "source_pdf_sha256": source_hash,
            "pipeline_version": descriptor.pipeline_version,
            "extraction_options": extraction_options or {},
        },
        "pages": pages,
    }
    return validate_result_contract(result)


def serialize_result_contract(value: Dict[str, Any]) -> bytes:
    return (_canonical(validate_result_contract(value)) + "\n").encode("utf-8")


def result_contract_sha256(value: Dict[str, Any]) -> str:
    return "sha256:" + hashlib.sha256(serialize_result_contract(value)).hexdigest()
