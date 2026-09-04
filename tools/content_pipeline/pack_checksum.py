"""Content-pack integrity checksum for the EUEE Prep content pipeline.

This module is the Python counterpart to the in-app importer's checksum
(`lib/features/content/domain/services/content_import_checksum.dart`). Both
implement the *same* canonical serialization and the *same* FNV-1a 64-bit
hash, so a pack's declared ``checksum`` verifies identically in the pipeline
and on-device (Decision 021).

Canonical serialization rules (must match the Dart side byte-for-byte):

* Fields are emitted in the order defined by ``docs/content-pack-spec.md``.
* The top-level ``checksum`` field is excluded (a pack cannot checksum itself).
* Nullable fields are omitted entirely when ``null``.
* JSON is emitted compactly (no whitespace) and non-ASCII characters are left
  as raw UTF-8 (not ``\\uXXXX`` escapes).

Format: ``fnv1a64:<16 lowercase hex digits>``.
"""

import json
from typing import Any, Dict

OFFSET_BASIS = 14695981039346656037
PRIME = 1099511628211
MASK = (1 << 64) - 1


def fnv1a64(data: bytes) -> str:
    """Return the ``fnv1a64:`` checksum string for ``data``."""
    h = OFFSET_BASIS
    for byte in data:
        h ^= byte
        h = (h * PRIME) & MASK
    return "fnv1a64:{:016x}".format(h)


def canonical_json(pack: Dict[str, Any]) -> str:
    """Serialize ``pack`` (a parsed pack dict) into its canonical form."""
    return json.dumps(
        _canonical_pack(pack), separators=(",", ":"), ensure_ascii=False
    )


def compute_checksum(pack: Dict[str, Any]) -> str:
    """Return the checksum the canonical serialization of ``pack`` produces."""
    return fnv1a64(canonical_json(pack).encode("utf-8"))


def _canonical_pack(pack: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "pack_version": pack["pack_version"],
        "schema_version": pack["schema_version"],
        "generated_at": pack["generated_at"],
        "minimum_app_version": pack["minimum_app_version"],
        "stream": pack["stream"],
        "subject": _canonical_subject(pack["subject"]),
        "chapters": [_canonical_chapter(c) for c in pack["chapters"]],
        "exams": [_canonical_exam(e) for e in pack["exams"]],
    }


def _canonical_subject(subject: Dict[str, Any]) -> Dict[str, Any]:
    return {"slug": subject["slug"], "title": subject["title"]}


def _canonical_chapter(chapter: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "id": chapter["id"],
        "grade": chapter["grade"],
        "title": chapter["title"],
        "order_index": chapter["order_index"],
        "topics": [_canonical_topic(t) for t in chapter["topics"]],
    }


def _canonical_topic(topic: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "id": topic["id"],
        "title": topic["title"],
        "order_index": topic["order_index"],
        "questions": [_canonical_question(q) for q in topic["questions"]],
        "resources": [_canonical_resource(r) for r in topic["resources"]],
    }


def _canonical_question(question: Dict[str, Any]) -> Dict[str, Any]:
    out: Dict[str, Any] = {
        "id": question["id"],
        "prompt": question["prompt"],
        "choices": question["choices"],
        "correct_choice_index": question["correct_choice_index"],
    }
    if question.get("explanation") is not None:
        out["explanation"] = question["explanation"]
    if question.get("textbook_reference") is not None:
        out["textbook_reference"] = question["textbook_reference"]
    if question.get("exam_year_ec") is not None:
        out["exam_year_ec"] = question["exam_year_ec"]
    out["topic_refs"] = question["topic_refs"]
    for key in (
        "image_reference",
        "graph_reference",
        "diagram_reference",
        "table_reference",
    ):
        if question.get(key) is not None:
            out[key] = question[key]
    return out


def _canonical_resource(resource: Dict[str, Any]) -> Dict[str, Any]:
    out: Dict[str, Any] = {"id": resource["id"], "type": resource["type"]}
    if resource.get("title") is not None:
        out["title"] = resource["title"]
    out["content"] = resource["content"]
    out["order_index"] = resource["order_index"]
    return out


def _canonical_exam(exam: Dict[str, Any]) -> Dict[str, Any]:
    out: Dict[str, Any] = {"id": exam["id"], "year_ec": exam["year_ec"]}
    if exam.get("title") is not None:
        out["title"] = exam["title"]
    if exam.get("duration_seconds") is not None:
        out["duration_seconds"] = exam["duration_seconds"]
    out["question_ids"] = exam["question_ids"]
    return out
