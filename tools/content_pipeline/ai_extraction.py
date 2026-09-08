"""Gemini-assisted extraction of scanned EUEE question pages.

This module deliberately keeps extraction provenance separate from the v2
production content-pack contract.  It can therefore preserve unresolved answer
keys without inventing a ``correct_choice_index``.
"""

from __future__ import annotations

import argparse
import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Dict, Iterable, List, Optional

try:
    import pymupdf as fitz  # type: ignore
except ImportError:  # pragma: no cover - exercised by the CLI environment
    fitz = None

try:
    from google import genai  # type: ignore
    from google.genai import types  # type: ignore
except ImportError:  # pragma: no cover - exercised by the CLI environment
    genai = None
    types = None


EXTRACTION_SCHEMA: Dict[str, Any] = {
    "type": "object",
    "properties": {
        "pdf_page": {"type": "integer", "minimum": 1},
        "printed_page": {"type": ["integer", "null"], "minimum": 1},
        "visible_metadata": {"type": "array", "items": {"type": "string"}},
        "questions": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "question_number": {"type": "integer", "minimum": 1},
                    "prompt": {"type": "string"},
                    "choices": {
                        "type": "array",
                        "items": {"type": "string"},
                    },
                    "correct_choice_index": {"type": ["integer", "null"]},
                    "answer_status": {
                        "type": "string",
                        "enum": ["authoritative", "unresolved"],
                    },
                    "source_region": {
                        "type": ["object", "null"],
                        "properties": {
                            "x": {"type": "number"},
                            "y": {"type": "number"},
                            "width": {"type": "number"},
                            "height": {"type": "number"},
                        },
                        "required": ["x", "y", "width", "height"],
                    },
                    "uncertainties": {
                        "type": "array",
                        "items": {"type": "string"},
                    },
                },
                "required": [
                    "question_number",
                    "prompt",
                    "choices",
                    "correct_choice_index",
                    "answer_status",
                    "source_region",
                    "uncertainties",
                ],
            },
        },
    },
    "required": ["pdf_page", "printed_page", "visible_metadata", "questions"],
}

VERIFICATION_SCHEMA: Dict[str, Any] = {
    "type": "object",
    "properties": {
        "pdf_page": {"type": "integer", "minimum": 1},
        "questions": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "question_number": {"type": "integer", "minimum": 1},
                    "status": {
                        "type": "string",
                        "enum": ["verified", "needs_review", "critical_error"],
                    },
                    "findings": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "field": {"type": "string"},
                                "reason": {"type": "string"},
                            },
                            "required": ["field", "reason"],
                        },
                    },
                },
                "required": ["question_number", "status", "findings"],
            },
        },
    },
    "required": ["pdf_page", "questions"],
}

ANSWER_ANALYSIS_SCHEMA: Dict[str, Any] = {
    "type": "object",
    "properties": {
        "pdf_page": {"type": "integer", "minimum": 1},
        "questions": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "question_number": {"type": "integer", "minimum": 1},
                    "predicted_choice_index": {"type": ["integer", "null"]},
                    "confidence": {
                        "type": "string",
                        "enum": ["high", "medium", "low"],
                    },
                    "reasoning": {"type": "string"},
                    "uncertainties": {
                        "type": "array",
                        "items": {"type": "string"},
                    },
                    "answer_basis": {
                        "type": "string",
                        "enum": ["source_answer_key", "ai_solution", "unresolved"],
                    },
                },
                "required": [
                    "question_number",
                    "predicted_choice_index",
                    "confidence",
                    "reasoning",
                    "uncertainties",
                    "answer_basis",
                ],
            },
        },
    },
    "required": ["pdf_page", "questions"],
}


@dataclass
class PageResult:
    page: int
    extracted: Optional[Dict[str, Any]] = None
    validation: Optional[Dict[str, Any]] = None
    answer_analysis: Optional[Dict[str, Any]] = None
    verification: Optional[Dict[str, Any]] = None
    error: Optional[str] = None


class GeminiQuotaExhaustedError(RuntimeError):
    """The project/model quota is exhausted; do not issue another request."""


class GeminiUnavailableError(RuntimeError):
    """A transient Gemini 503 response that does not imply quota exhaustion."""


def _error_text(error: BaseException) -> str:
    return "%s: %s" % (type(error).__name__, error)


def _is_quota_exhausted(error: BaseException) -> bool:
    code = getattr(error, "code", None)
    status = getattr(error, "status", None)
    text = _error_text(error).upper()
    return (
        code == 429
        or status == "RESOURCE_EXHAUSTED"
        or "RESOURCE_EXHAUSTED" in text
        or ("429" in text and "QUOTA" in text)
    )


def _is_unavailable(error: BaseException) -> bool:
    code = getattr(error, "code", None)
    status = getattr(error, "status", None)
    text = _error_text(error).upper()
    return code == 503 or status == "UNAVAILABLE" or "503 UNAVAILABLE" in text


def _json_response(response: Any) -> Dict[str, Any]:
    text = getattr(response, "text", None)
    if not isinstance(text, str) or not text.strip():
        raise ValueError("Gemini response did not contain JSON text")
    try:
        value = json.loads(text)
    except json.JSONDecodeError as exc:
        raise ValueError("Gemini returned malformed JSON: %s" % exc) from exc
    if not isinstance(value, dict):
        raise ValueError("Gemini JSON response must be an object")
    return value


def _schema_prompt(page: int) -> str:
    return f"""Extract only visibly printed content from PDF page {page}. Return JSON matching the supplied schema.

Rules:
- Preserve the source wording; only remove obvious layout line breaks and repeated whitespace.
- Extract every complete multiple-choice question visible on this page, in reading order.
- Extract exactly the choices visible for each question. Do not infer or complete missing text.
- Record printed page number only if visibly present; otherwise use null.
- Record source_region in normalized image coordinates from 0 to 1 when practical.
- Handwritten marks, circles, highlights, and annotations are not an authoritative answer key.
- Unless the page explicitly identifies an official answer key, set correct_choice_index to null and answer_status to unresolved.
- Do not use outside knowledge.
"""


def _verify_prompt(page: int, extraction: Dict[str, Any]) -> str:
    return f"""Compare the attached source image for PDF page {page} against this extraction JSON:
{json.dumps(extraction, ensure_ascii=False)}

Return only JSON matching the verification schema. Do not rewrite the extraction.
For each question identify only discrepancies or uncertainty in the source comparison.
Check numbering, prompt text, choice boundaries, missing words, unreadable characters,
merged/split questions, diagrams/tables, and whether any markings could be mistaken for
an official answer key. A question with unresolved answer data should be needs_review
unless the source explicitly identifies an authoritative answer key.
"""


def _answer_prompt(page: int, extraction: Dict[str, Any]) -> str:
    questions = [
        {
            "question_number": question.get("question_number"),
            "prompt": question.get("prompt"),
            "choices": question.get("choices"),
        }
        for question in extraction.get("questions", [])
    ]
    return f"""Solve the visible multiple-choice questions from PDF page {page} independently.
Use only the question and choices supplied below, plus general subject knowledge.
Do not invent, repair, or complete missing source text. Return one result for every
question, in the same order, matching the supplied answer-analysis schema.

Questions:
{json.dumps(questions, ensure_ascii=False)}

Rules:
- predicted_choice_index is zero-based.
- Use answer_basis=ai_solution for an independently solved answer.
- Use answer_basis=source_answer_key only if the source explicitly contains an
  authoritative answer key; circles, handwriting, highlights, and annotations do
  not qualify.
- If the answer cannot be determined reliably, use predicted_choice_index=null,
  confidence=low, answer_basis=unresolved, and explain why in uncertainties.
- Never infer an answer from a student's marking.
- Reasoning must explain the basis of the proposed answer without changing the
  extracted wording.
"""


def render_pages(pdf_path: Path, output_dir: Path, dpi: int = 180) -> List[Path]:
    if fitz is None:
        raise RuntimeError("PyMuPDF is required; install it with `python -m pip install PyMuPDF`")
    output_dir.mkdir(parents=True, exist_ok=True)
    rendered: List[Path] = []
    with fitz.open(pdf_path) as document:
        for index, page in enumerate(document, start=1):
            target = output_dir / ("page-%03d.png" % index)
            if not target.exists():
                pixmap = page.get_pixmap(dpi=dpi, alpha=False)
                pixmap.save(str(target))
            rendered.append(target)
    return rendered


def _call_json(client: Any, model: str, image_path: Path, prompt: str, schema: Dict[str, Any]) -> Dict[str, Any]:
    image = image_path.read_bytes()
    try:
        response = client.models.generate_content(
            model=model,
            contents=[types.Part.from_bytes(data=image, mime_type="image/png"), prompt],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                # Keep JSON Schema unions such as ["integer", "null"] intact.
                # response_schema converts through types.Schema, whose `type` field
                # accepts only one value in google-genai 2.x.
                response_json_schema=schema,
                automatic_function_calling=types.AutomaticFunctionCallingConfig(
                    disable=True,
                ),
                temperature=0,
            ),
        )
    except Exception as exc:
        if _is_quota_exhausted(exc):
            raise GeminiQuotaExhaustedError(_error_text(exc)) from exc
        if _is_unavailable(exc):
            raise GeminiUnavailableError(_error_text(exc)) from exc
        raise
    return _json_response(response)


def validate_page(extraction: Dict[str, Any], page: int, previous_numbers: Iterable[int]) -> Dict[str, Any]:
    errors: List[str] = []
    warnings: List[str] = []
    if extraction.get("pdf_page") != page:
        errors.append("pdf_page does not match requested page")
    questions = extraction.get("questions")
    if not isinstance(questions, list):
        errors.append("questions must be an array")
        questions = []
    numbers: List[int] = []
    for index, question in enumerate(questions):
        where = "questions[%d]" % index
        if not isinstance(question, dict):
            errors.append("%s must be an object" % where)
            continue
        number = question.get("question_number")
        if not isinstance(number, int) or number <= 0:
            errors.append("%s.question_number must be a positive integer" % where)
        elif number in numbers:
            errors.append("duplicate question number %s" % number)
        else:
            numbers.append(number)
        if not isinstance(question.get("prompt"), str) or not question["prompt"].strip():
            errors.append("%s.prompt must be non-empty" % where)
        choices = question.get("choices")
        if not isinstance(choices, list) or len(choices) != 4:
            errors.append("%s.choices must contain exactly four strings" % where)
        elif any(not isinstance(choice, str) or not choice.strip() for choice in choices):
            errors.append("%s.choices contains empty or non-string text" % where)
        answer = question.get("correct_choice_index")
        status = question.get("answer_status")
        if answer is not None:
            if not isinstance(answer, int) or not 0 <= answer < 4:
                errors.append("%s.correct_choice_index is invalid" % where)
            if status != "authoritative":
                errors.append("%s has an answer index without authoritative status" % where)
        if answer is None and status != "unresolved":
            errors.append("%s unresolved answer must use unresolved status" % where)
        if not isinstance(question.get("uncertainties"), list):
            errors.append("%s.uncertainties must be an array" % where)
        region = question.get("source_region")
        if region is not None:
            if not isinstance(region, dict) or any(
                not isinstance(region.get(key), (int, float)) for key in ("x", "y", "width", "height")
            ):
                errors.append("%s.source_region is malformed" % where)
            elif any(region[key] < 0 or region[key] > 1 for key in ("x", "y", "width", "height")):
                errors.append("%s.source_region must use normalized coordinates" % where)
        if answer is None:
            warnings.append("question %s has no authoritative answer" % number)
    if numbers and numbers != sorted(numbers):
        errors.append("question order is not ascending")
    prior = list(previous_numbers)
    if prior and numbers and numbers[0] <= prior[-1]:
        errors.append("question numbering overlaps a previous page")
    return {"pdf_page": page, "valid": not errors, "errors": errors, "warnings": warnings, "question_numbers": numbers}


def validate_answer_analysis(
    analysis: Dict[str, Any], extraction: Dict[str, Any], page: int
) -> Dict[str, Any]:
    errors: List[str] = []
    expected = [question.get("question_number") for question in extraction.get("questions", [])]
    if analysis.get("pdf_page") != page:
        errors.append("pdf_page does not match requested page")
    items = analysis.get("questions")
    if not isinstance(items, list):
        errors.append("questions must be an array")
        items = []
    actual: List[Any] = []
    source_by_number = {
        question.get("question_number"): question
        for question in extraction.get("questions", [])
    }
    for index, item in enumerate(items):
        where = "questions[%d]" % index
        if not isinstance(item, dict):
            errors.append("%s must be an object" % where)
            continue
        number = item.get("question_number")
        actual.append(number)
        if number in actual[:-1]:
            errors.append("duplicate answer analysis for question %s" % number)
        if number not in source_by_number:
            errors.append("answer analysis references unknown question %s" % number)
        prediction = item.get("predicted_choice_index")
        if prediction is not None and (not isinstance(prediction, int) or not 0 <= prediction < 4):
            errors.append("%s.predicted_choice_index is invalid" % where)
        if item.get("confidence") not in {"high", "medium", "low"}:
            errors.append("%s.confidence is invalid" % where)
        if not isinstance(item.get("reasoning"), str) or not item["reasoning"].strip():
            errors.append("%s.reasoning must be non-empty" % where)
        if not isinstance(item.get("uncertainties"), list) or any(
            not isinstance(value, str) for value in item.get("uncertainties", [])
        ):
            errors.append("%s.uncertainties must be an array of strings" % where)
        basis = item.get("answer_basis")
        if basis not in {"source_answer_key", "ai_solution", "unresolved"}:
            errors.append("%s.answer_basis is invalid" % where)
        if basis == "unresolved" and prediction is not None:
            errors.append("%s unresolved answer must have a null prediction" % where)
        source = source_by_number.get(number)
        if basis == "source_answer_key" and (
            not source
            or source.get("answer_status") != "authoritative"
            or source.get("correct_choice_index") is None
        ):
            errors.append("%s source_answer_key is not supported by extraction provenance" % where)
    if actual != expected:
        errors.append("answer analysis question set/order does not match extraction")
    return {"pdf_page": page, "valid": not errors, "errors": errors, "question_numbers": actual}


def classify(validation: Dict[str, Any], verification: Optional[Dict[str, Any]], question: Dict[str, Any]) -> str:
    if validation["errors"]:
        return "RED"
    findings = []
    if verification:
        item = next((x for x in verification.get("questions", []) if x.get("question_number") == question.get("question_number")), None)
        if item:
            if item.get("status") == "critical_error":
                return "RED"
            if item.get("status") == "needs_review" or item.get("findings"):
                findings.append(True)
    if question.get("correct_choice_index") is None or question.get("uncertainties"):
        findings.append(True)
    return "YELLOW" if findings else "GREEN"


def build_blocked_candidate(results: List[PageResult], source: Path, output: Path) -> None:
    questions = []
    reasons = []
    for result in results:
        if not result.extracted:
            continue
        validation = result.validation or {}
        answer_analysis = result.answer_analysis or {}
        verification = result.verification or {}
        for question in result.extracted.get("questions", []):
            status = classify(validation, verification, question)
            item = dict(question)
            item.update({"pdf_page": result.page, "review_class": status})
            answer_item = next(
                (
                    answer
                    for answer in answer_analysis.get("questions", [])
                    if answer.get("question_number") == question.get("question_number")
                ),
                None,
            )
            if answer_item is not None:
                item["ai_answer_analysis"] = answer_item
            questions.append(item)
            if question.get("correct_choice_index") is None:
                reasons.append("question %s has no authoritative correct_choice_index" % question.get("question_number"))
            if answer_item and answer_item.get("answer_basis") != "source_answer_key":
                reasons.append("question %s has only an AI-derived or unresolved answer" % question.get("question_number"))
            if validation.get("errors"):
                reasons.extend(validation["errors"])
    payload = {
        "status": "blocked",
        "reason": "The existing content-pack contract requires authoritative correct_choice_index values.",
        "source_pdf": str(source),
        "questions": questions,
        "blocking_issues": sorted(set(reasons)),
        "note": "This is not a production content pack and must not be imported.",
    }
    output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_review(results: List[PageResult], output: Path) -> Dict[str, int]:
    counts = {"GREEN": 0, "YELLOW": 0, "RED": 0}
    lines = ["# Formal Exam Extraction Review", "", "Only YELLOW and RED items are listed.", ""]
    for result in results:
        if not result.extracted:
            continue
        validation = result.validation or {}
        answer_analysis = result.answer_analysis or {}
        verification = result.verification or {}
        for question in result.extracted.get("questions", []):
            status = classify(validation, verification, question)
            counts[status] += 1
            answer_item = next(
                (
                    item
                    for item in answer_analysis.get("questions", [])
                    if item.get("question_number") == question.get("question_number")
                ),
                None,
            )
            if status == "GREEN" and answer_item is None:
                continue
            number = question.get("question_number")
            lines.extend([
                "## Question %s" % number, "", "- PDF page: %s" % result.page,
                "- Review class: **%s**" % status,
                "- Prompt: %s" % question.get("prompt", ""),
                "- Choices:",
            ])
            lines.extend("  - %s" % choice for choice in question.get("choices", []))
            lines.append("- Extraction uncertainties: %s" % ("; ".join(question.get("uncertainties", [])) or "none"))
            if answer_item:
                prediction = answer_item.get("predicted_choice_index")
                proposed = "unresolved" if prediction is None else str(prediction)
                lines.extend([
                    "- Gemini proposed answer (zero-based choice index): %s" % proposed,
                    "- Answer confidence: **%s**" % answer_item.get("confidence"),
                    "- Answer basis: `%s`" % answer_item.get("answer_basis"),
                    "- Answer reasoning: %s" % answer_item.get("reasoning"),
                    "- Answer uncertainties: %s" % ("; ".join(answer_item.get("uncertainties", [])) or "none"),
                    "- Human answer verification required: **%s**" % (
                        "yes" if answer_item.get("confidence") != "high" or answer_item.get("answer_basis") != "source_answer_key" else "no"
                    ),
                ])
            item = next((x for x in verification.get("questions", []) if x.get("question_number") == number), None)
            if item:
                lines.append("- Verification: %s" % item.get("status"))
                for finding in item.get("findings", []):
                    lines.append("- %s: %s" % (finding.get("field"), finding.get("reason")))
            lines.extend(["", "Source image: `pages/page-%03d.png`" % result.page, ""])
    output.write_text("\n".join(lines), encoding="utf-8")
    return counts


def store_human_verification(
    output_root: Path,
    page: int,
    question_number: int,
    verified_choice_index: Optional[int],
    reviewer: str,
    note: str = "",
) -> Path:
    """Store a review decision without overwriting the AI answer analysis."""
    if verified_choice_index is not None and not 0 <= verified_choice_index < 4:
        raise ValueError("verified_choice_index must be null or a choice index from 0 to 3")
    target = output_root / "human_verification" / (
        "page-%03d-question-%03d.json" % (page, question_number)
    )
    target.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "pdf_page": page,
        "question_number": question_number,
        "verified_choice_index": verified_choice_index,
        "reviewer": reviewer,
        "note": note,
        "verification_basis": "human_review",
    }
    target.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return target


def _read_cached_json(path: Path) -> Optional[Dict[str, Any]]:
    if not path.exists():
        return None
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    return value if isinstance(value, dict) else None


def _cached_verification(path: Path, page: int) -> Optional[Dict[str, Any]]:
    value = _read_cached_json(path)
    if value is None or value.get("pdf_page") != page or not isinstance(value.get("questions"), list):
        return None
    return value


def _cached_answer_analysis(
    path: Path, extraction: Dict[str, Any], page: int
) -> Optional[Dict[str, Any]]:
    value = _read_cached_json(path)
    if value is None:
        return None
    validation = validate_answer_analysis(value, extraction, page)
    return value if validation["valid"] else None


def _write_summary(
    output_root: Path,
    pdf: Path,
    model: str,
    pages_seen: int,
    results: List[PageResult],
    calls: int,
    cached_pages: int,
    status: str,
) -> None:
    counts = write_review(results, output_root / "human_review" / "review.md")
    payload = {
        "source_pdf": str(pdf),
        "model": model,
        "pages_seen": pages_seen,
        "pages_completed": sum(1 for result in results if result.extracted),
        "gemini_calls": calls,
        "cached_pages": cached_pages,
        "status": status,
        "confidence_counts": counts,
        "errors": [result.error for result in results if result.error],
    }
    (output_root / "run_summary.json").write_text(
        json.dumps(payload, indent=2) + "\n", encoding="utf-8"
    )


def run(
    pdf: Path,
    output_root: Path,
    model: str,
    dpi: int = 180,
    client: Any = None,
    client_factory: Optional[Callable[[str], Any]] = None,
) -> int:
    if genai is None or types is None:
        raise RuntimeError("google-genai is required; install it with `python -m pip install google-genai`")
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY is not set; no Gemini request was made")
    if client is None:
        factory = client_factory or (lambda key: genai.Client(api_key=key))
        client = factory(api_key)
    for name in (
        "raw_extraction",
        "validated_extraction",
        "answer_analysis",
        "verification",
        "human_review",
        "human_verification",
    ):
        (output_root / name).mkdir(parents=True, exist_ok=True)
    pages_dir = output_root / "pages"
    images = render_pages(pdf, pages_dir, dpi)
    results: List[PageResult] = []
    previous_numbers: List[int] = []
    calls = 0
    cached_pages = 0
    status = "completed"
    for page, image in enumerate(images, start=1):
        result = PageResult(page=page)
        raw_path = output_root / "raw_extraction" / ("page-%03d.json" % page)
        validation_path = output_root / "validated_extraction" / ("page-%03d.json" % page)
        answer_path = output_root / "answer_analysis" / ("page-%03d.json" % page)
        answer_validation_path = output_root / "answer_analysis" / ("page-%03d.validation.json" % page)
        verification_path = output_root / "verification" / ("page-%03d.json" % page)
        extracted = _read_cached_json(raw_path)
        if extracted is not None:
            result.extracted = extracted
            cached_pages += 1
        else:
            try:
                calls += 1
                extracted = _call_json(client, model, image, _schema_prompt(page), EXTRACTION_SCHEMA)
                result.extracted = extracted
                raw_path.write_text(json.dumps(extracted, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            except GeminiQuotaExhaustedError as exc:
                status = "quota_exhausted"
                result.error = _error_text(exc)
                results.append(result)
                _write_summary(output_root, pdf, model, len(images), results, calls, cached_pages, status)
                build_blocked_candidate(results, pdf, output_root / "content_pack_candidate_blocked.json")
                break
            except GeminiUnavailableError as exc:
                status = "completed_with_errors"
                result.error = _error_text(exc)
                (output_root / "validated_extraction" / ("page-%03d.error.json" % page)).write_text(
                    json.dumps({"pdf_page": page, "stage": "extraction", "error": result.error}, indent=2) + "\n",
                    encoding="utf-8",
                )
                results.append(result)
                build_blocked_candidate(results, pdf, output_root / "content_pack_candidate_blocked.json")
                _write_summary(output_root, pdf, model, len(images), results, calls, cached_pages, status)
                continue
            except Exception as exc:
                status = "completed_with_errors"
                result.error = _error_text(exc)
                (output_root / "validated_extraction" / ("page-%03d.error.json" % page)).write_text(
                    json.dumps({"pdf_page": page, "stage": "extraction", "error": result.error}, indent=2) + "\n",
                    encoding="utf-8",
                )
                results.append(result)
                build_blocked_candidate(results, pdf, output_root / "content_pack_candidate_blocked.json")
                _write_summary(output_root, pdf, model, len(images), results, calls, cached_pages, status)
                continue

        validation = validate_page(extracted, page, previous_numbers)
        result.validation = validation
        validation_path.write_text(json.dumps(validation, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        if validation["valid"]:
            previous_numbers.extend(validation["question_numbers"])
            answer_analysis = _cached_answer_analysis(answer_path, extracted, page)
            if answer_analysis is not None:
                result.answer_analysis = answer_analysis
            else:
                try:
                    calls += 1
                    answer_analysis = _call_json(
                        client,
                        model,
                        image,
                        _answer_prompt(page, extracted),
                        ANSWER_ANALYSIS_SCHEMA,
                    )
                    result.answer_analysis = answer_analysis
                    answer_path.write_text(
                        json.dumps(answer_analysis, ensure_ascii=False, indent=2) + "\n",
                        encoding="utf-8",
                    )
                    answer_validation_path.write_text(
                        json.dumps(
                            validate_answer_analysis(answer_analysis, extracted, page),
                            ensure_ascii=False,
                            indent=2,
                        )
                        + "\n",
                        encoding="utf-8",
                    )
                except GeminiQuotaExhaustedError as exc:
                    status = "quota_exhausted"
                    result.error = _error_text(exc)
                    results.append(result)
                    _write_summary(output_root, pdf, model, len(images), results, calls, cached_pages, status)
                    build_blocked_candidate(results, pdf, output_root / "content_pack_candidate_blocked.json")
                    break
                except GeminiUnavailableError as exc:
                    status = "completed_with_errors"
                    result.error = _error_text(exc)
                    (output_root / "answer_analysis" / ("page-%03d.error.json" % page)).write_text(
                        json.dumps({"pdf_page": page, "stage": "answer_analysis", "error": result.error}, indent=2) + "\n",
                        encoding="utf-8",
                    )
                except Exception as exc:
                    status = "completed_with_errors"
                    result.error = _error_text(exc)
                    (output_root / "answer_analysis" / ("page-%03d.error.json" % page)).write_text(
                        json.dumps({"pdf_page": page, "stage": "answer_analysis", "error": result.error}, indent=2) + "\n",
                        encoding="utf-8",
                    )
            verification = _cached_verification(verification_path, page)
            if verification is not None:
                result.verification = verification
            else:
                try:
                    calls += 1
                    verification = _call_json(client, model, image, _verify_prompt(page, extracted), VERIFICATION_SCHEMA)
                    result.verification = verification
                    verification_path.write_text(json.dumps(verification, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
                except GeminiQuotaExhaustedError as exc:
                    status = "quota_exhausted"
                    result.error = _error_text(exc)
                    results.append(result)
                    _write_summary(output_root, pdf, model, len(images), results, calls, cached_pages, status)
                    build_blocked_candidate(results, pdf, output_root / "content_pack_candidate_blocked.json")
                    break
                except GeminiUnavailableError as exc:
                    status = "completed_with_errors"
                    result.error = _error_text(exc)
                    (output_root / "validated_extraction" / ("page-%03d.error.json" % page)).write_text(
                        json.dumps({"pdf_page": page, "stage": "verification", "error": result.error}, indent=2) + "\n",
                        encoding="utf-8",
                    )
                except Exception as exc:
                    status = "completed_with_errors"
                    result.error = _error_text(exc)
        else:
            result.verification = {"pdf_page": page, "questions": [], "skipped": "deterministic validation failed"}
        results.append(result)
        build_blocked_candidate(results, pdf, output_root / "content_pack_candidate_blocked.json")
        _write_summary(output_root, pdf, model, len(images), results, calls, cached_pages, status)
    return 0


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Run Gemini-assisted scanned EUEE extraction.")
    parser.add_argument("--pdf", type=Path, default=Path("test/fixtures/formal_exam.pdf"))
    parser.add_argument("--output", type=Path, default=Path("tools/content_pipeline/output/formal_exam"))
    parser.add_argument("--model", default=os.environ.get("GEMINI_MODEL"))
    parser.add_argument("--dpi", type=int, default=180)
    args = parser.parse_args(argv)
    if not args.model:
        parser.error("GEMINI_MODEL is not set and --model was not supplied")
    if not args.pdf.exists():
        parser.error("PDF does not exist: %s" % args.pdf)
    return run(args.pdf, args.output, args.model, args.dpi)


if __name__ == "__main__":
    raise SystemExit(main())
