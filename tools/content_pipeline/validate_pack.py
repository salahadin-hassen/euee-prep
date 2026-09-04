"""Content-pack validation script for the EUEE Prep content pipeline.

Usage::

    python validate_pack.py <pack-file> [<pack-file> ...]

Validates a content pack against the contract in ``docs/content-pack-spec.md``
and the schema in ``docs/database-schema.md`` *before* the pack ships — the
pipeline's last line of defense so bad content never reaches a device
(Decision 021; ``docs/coding-standards.md`` Python section: fail loudly and
specifically, naming the exact field that is invalid).

Validation covers:

* Required metadata and versioning fields (``pack_version``,
  ``schema_version``, ``generated_at``, ``checksum``, ``minimum_app_version``)
* Supported ``schema_version``
* Stream / grade / resource-type enum values
* Required stable pack-local IDs and their pack-wide uniqueness
* Broken topic references, broken exam question references, and duplicate
  question/exam membership
* One paper per (subject, EC year) per pack (Decision 038)
* Checksum integrity (see ``pack_checksum.py``)

Exit status is ``0`` when every pack validates, ``1`` otherwise.
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List

from pack_checksum import compute_checksum

SUPPORTED_SCHEMA_VERSION = "2"
VALID_STREAMS = {"natural_science", "social_science"}
VALID_GRADES = {9, 10, 11, 12}
VALID_RESOURCE_TYPES = {"note", "flashcard", "mindmap"}


def validate(pack: Any) -> List[str]:
    """Return every validation problem in ``pack`` as a list of messages.

    An empty list means the pack is valid. Pure — no filesystem access, so it
    is directly unit-testable.
    """
    if not isinstance(pack, dict):
        return ["pack root must be a JSON object"]

    errors: List[str] = []
    _validate_metadata(pack, errors)

    chapters = pack.get("chapters")
    exams = pack.get("exams")
    if not isinstance(chapters, list):
        errors.append('"chapters" must be an array')
        chapters = []
    if not isinstance(exams, list):
        errors.append('"exams" must be an array')
        exams = []

    all_ids: set = set()
    topic_ids: set = set()
    question_ids: set = set()
    exam_years: List[Any] = []

    for index, chapter in enumerate(chapters):
        _validate_chapter(chapter, index, all_ids, topic_ids, question_ids, errors)

    for index, exam in enumerate(exams):
        _validate_exam(exam, index, all_ids, exam_years, errors)

    # Decision 038 — one paper per (subject, EC year) per pack.
    seen_years: set = set()
    for year in exam_years:
        if isinstance(year, int) and year in seen_years:
            errors.append(
                "duplicate exam for subject and year_ec %s — one paper per "
                "(subject, year) per pack (Decision 038)" % year
            )
        seen_years.add(year)

    _validate_references(chapters, exams, topic_ids, question_ids, errors)

    return errors


def validate_integrity(pack: Any) -> List[str]:
    """Return checksum/identity problems (run after :func:`validate` passes)."""
    if not isinstance(pack, dict):
        return []
    errors: List[str] = []
    declared = pack.get("checksum")
    if isinstance(declared, str) and declared:
        try:
            computed = compute_checksum(pack)
        except (KeyError, TypeError) as exc:
            errors.append("cannot compute checksum: %s" % exc)
        else:
            if computed != declared:
                errors.append(
                    "checksum mismatch — declared %s but computed %s"
                    % (declared, computed)
                )
    return errors


def _validate_metadata(pack: Dict[str, Any], errors: List[str]) -> None:
    schema_version = pack.get("schema_version")
    if not isinstance(schema_version, str) or not schema_version:
        errors.append('"schema_version" must be a non-empty string')
    elif schema_version != SUPPORTED_SCHEMA_VERSION:
        errors.append(
            'unsupported schema_version "%s"; supported: "%s"'
            % (schema_version, SUPPORTED_SCHEMA_VERSION)
        )

    stream = pack.get("stream")
    if stream not in VALID_STREAMS:
        errors.append(
            'stream must be "natural_science" or "social_science", got %r' % stream
        )

    subject = pack.get("subject")
    if not isinstance(subject, dict):
        errors.append('"subject" must be an object')
    else:
        if not _is_nonempty_string(subject.get("slug")):
            errors.append("subject.slug must be a non-empty string")
        if not _is_nonempty_string(subject.get("title")):
            errors.append("subject.title must be a non-empty string")

    if not _is_nonempty_string(pack.get("pack_version")):
        errors.append('"pack_version" must be a non-empty string')

    generated_at = pack.get("generated_at")
    if not _is_nonempty_string(generated_at) or not _is_iso8601(generated_at):
        errors.append('"generated_at" must be a valid ISO8601 timestamp')

    if not _is_nonempty_string(pack.get("checksum")):
        errors.append('"checksum" must be a non-empty string')

    if not _is_nonempty_string(pack.get("minimum_app_version")):
        errors.append('"minimum_app_version" must be a non-empty string')


def _validate_chapter(
    chapter: Any,
    chapter_index: int,
    all_ids: set,
    topic_ids: set,
    question_ids: set,
    errors: List[str],
) -> None:
    where = "chapters[%s]" % chapter_index
    if not isinstance(chapter, dict):
        errors.append("%s must be an object" % where)
        return

    _check_id(chapter.get("id"), "chapter", all_ids, errors)

    grade = chapter.get("grade")
    if not isinstance(grade, int) or grade not in VALID_GRADES:
        errors.append(
            '%s has invalid grade %r; expected 9, 10, 11, or 12' % (where, grade)
        )

    if not _is_nonempty_string(chapter.get("title")):
        errors.append("%s title must be a non-empty string" % where)

    order_index = chapter.get("order_index")
    if not isinstance(order_index, int) or order_index < 0:
        errors.append("%s order_index must be an integer >= 0" % where)

    topics = chapter.get("topics")
    if not isinstance(topics, list):
        errors.append("%s.topics must be an array" % where)
        return
    for topic_index, topic in enumerate(topics):
        _validate_topic(
            topic,
            "%s.topics[%s]" % (where, topic_index),
            all_ids,
            topic_ids,
            question_ids,
            errors,
        )


def _validate_topic(
    topic: Any,
    where: str,
    all_ids: set,
    topic_ids: set,
    question_ids: set,
    errors: List[str],
) -> None:
    if not isinstance(topic, dict):
        errors.append("%s must be an object" % where)
        return

    _check_id(topic.get("id"), "topic", all_ids, errors)
    topic_id = topic.get("id")
    if isinstance(topic_id, str):
        topic_ids.add(topic_id)

    if not _is_nonempty_string(topic.get("title")):
        errors.append("%s title must be a non-empty string" % where)

    order_index = topic.get("order_index")
    if not isinstance(order_index, int) or order_index < 0:
        errors.append("%s order_index must be an integer >= 0" % where)

    questions = topic.get("questions")
    if not isinstance(questions, list):
        errors.append("%s.questions must be an array" % where)
        questions = []
    resources = topic.get("resources")
    if not isinstance(resources, list):
        errors.append("%s.resources must be an array" % where)
        resources = []

    for q_index, question in enumerate(questions):
        _validate_question(
            question, "%s.questions[%s]" % (where, q_index), all_ids, question_ids, errors
        )
    for r_index, resource in enumerate(resources):
        _validate_resource(resource, "%s.resources[%s]" % (where, r_index), all_ids, errors)


def _validate_question(
    question: Any, where: str, all_ids: set, question_ids: set, errors: List[str]
) -> None:
    if not isinstance(question, dict):
        errors.append("%s must be an object" % where)
        return

    _check_id(question.get("id"), "question", all_ids, errors)
    question_id = question.get("id")
    if isinstance(question_id, str):
        question_ids.add(question_id)

    if not _is_nonempty_string(question.get("prompt")):
        errors.append("%s prompt must be a non-empty string" % where)

    choices = question.get("choices")
    if not isinstance(choices, list) or len(choices) < 2:
        errors.append("%s must have at least two choices" % where)
        choices = []
    else:
        for c_index, choice in enumerate(choices):
            if not _is_nonempty_string(choice):
                errors.append("%s.choices[%s] must be a non-empty string" % (where, c_index))

    correct = question.get("correct_choice_index")
    if not isinstance(correct, int):
        errors.append("%s correct_choice_index must be an integer" % where)
    elif correct < 0 or (choices and correct >= len(choices)):
        errors.append(
            "%s correct_choice_index %s is out of range for %s choices"
            % (where, correct, len(choices))
        )

    for nullable in ("explanation", "textbook_reference", "image_reference",
                     "graph_reference", "diagram_reference", "table_reference"):
        value = question.get(nullable)
        if value is not None and not isinstance(value, str):
            errors.append('%s "%s" must be a string or null' % (where, nullable))

    exam_year_ec = question.get("exam_year_ec")
    if exam_year_ec is not None and not isinstance(exam_year_ec, int):
        errors.append('%s "exam_year_ec" must be an integer or null' % where)

    topic_refs = question.get("topic_refs")
    if not isinstance(topic_refs, list):
        errors.append("%s topic_refs must be an array" % where)
    else:
        for r_index, ref in enumerate(topic_refs):
            if not isinstance(ref, str) or not ref:
                errors.append("%s.topic_refs[%s] must be a non-empty string" % (where, r_index))
        nonempty_refs = [r for r in topic_refs if isinstance(r, str) and r]
        if not nonempty_refs:
            errors.append("%s must reference at least one topic" % where)
        if len(set(topic_refs)) != len(topic_refs):
            errors.append("%s lists a topic more than once" % where)


def _validate_resource(
    resource: Any, where: str, all_ids: set, errors: List[str]
) -> None:
    if not isinstance(resource, dict):
        errors.append("%s must be an object" % where)
        return

    _check_id(resource.get("id"), "resource", all_ids, errors)

    resource_type = resource.get("type")
    if resource_type not in VALID_RESOURCE_TYPES:
        errors.append(
            '%s has invalid type %r; expected note, flashcard, or mindmap '
            "(Decision 037)" % (where, resource_type)
        )

    title = resource.get("title")
    if title is not None and not isinstance(title, str):
        errors.append('%s "title" must be a string or null' % where)

    if not _is_nonempty_string(resource.get("content")):
        errors.append("%s content must be a non-empty string" % where)

    order_index = resource.get("order_index")
    if not isinstance(order_index, int) or order_index < 0:
        errors.append("%s order_index must be an integer >= 0" % where)


def _validate_exam(
    exam: Any, exam_index: int, all_ids: set, exam_years: List[Any], errors: List[str]
) -> None:
    where = "exams[%s]" % exam_index
    if not isinstance(exam, dict):
        errors.append("%s must be an object" % where)
        return

    _check_id(exam.get("id"), "exam", all_ids, errors)

    year_ec = exam.get("year_ec")
    if not isinstance(year_ec, int) or year_ec <= 0:
        errors.append("%s has invalid year_ec %r" % (where, year_ec))
    exam_years.append(year_ec)

    title = exam.get("title")
    if title is not None and not isinstance(title, str):
        errors.append('%s "title" must be a string or null' % where)

    duration = exam.get("duration_seconds")
    if duration is not None and (not isinstance(duration, int) or duration <= 0):
        errors.append("%s duration_seconds must be an integer > 0 when provided" % where)

    question_ids = exam.get("question_ids")
    if not isinstance(question_ids, list):
        errors.append("%s question_ids must be an array" % where)
    else:
        for q_index, ref in enumerate(question_ids):
            if not isinstance(ref, str) or not ref:
                errors.append("%s.question_ids[%s] must be a non-empty string" % (where, q_index))
        if len(set(question_ids)) != len(question_ids):
            errors.append("%s lists a question more than once" % where)


def _validate_references(
    chapters: List[Any],
    exams: List[Any],
    topic_ids: set,
    question_ids: set,
    errors: List[str],
) -> None:
    for chapter in chapters:
        if not isinstance(chapter, dict):
            continue
        for topic in chapter.get("topics") or []:
            if not isinstance(topic, dict):
                continue
            for question in topic.get("questions") or []:
                if not isinstance(question, dict):
                    continue
                for ref in question.get("topic_refs") or []:
                    if isinstance(ref, str) and ref and ref not in topic_ids:
                        errors.append(
                            'question "%s" references unknown topic "%s"'
                            % (question.get("id"), ref)
                        )
    for exam in exams:
        if not isinstance(exam, dict):
            continue
        for ref in exam.get("question_ids") or []:
            if isinstance(ref, str) and ref and ref not in question_ids:
                errors.append(
                    'exam "%s" references unknown question "%s"'
                    % (exam.get("id"), ref)
                )


def _check_id(value: Any, kind: str, all_ids: set, errors: List[str]) -> None:
    if not isinstance(value, str) or not value:
        errors.append("%s has an empty or missing id" % kind)
    elif value in all_ids:
        errors.append('duplicate pack-local id "%s"' % value)
    else:
        all_ids.add(value)


def _is_nonempty_string(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def _is_iso8601(value: Any) -> bool:
    if not isinstance(value, str):
        return False
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return False
    return True


def validate_file(path: Path) -> List[str]:
    """Validate the pack file at ``path``; return its list of problems."""
    label = str(path)
    try:
        raw = path.read_text(encoding="utf-8")
    except OSError as exc:
        return ["%s: cannot read file: %s" % (label, exc)]
    try:
        pack = json.loads(raw)
    except json.JSONDecodeError as exc:
        return ["%s: malformed JSON: %s" % (label, exc)]

    errors = validate(pack)
    if not errors:
        errors = validate_integrity(pack)
    return ["%s: %s" % (label, error) for error in errors]


def main(argv: List[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Validate an EUEE Prep content pack against the pack contract."
    )
    parser.add_argument("packs", nargs="+", help="path(s) to content pack JSON files")
    args = parser.parse_args(argv)

    all_errors: List[str] = []
    for pack_path in args.packs:
        errors = validate_file(Path(pack_path))
        if errors:
            all_errors.extend(errors)
            for error in errors:
                print(error)
        else:
            print("%s: OK" % pack_path)

    if all_errors:
        print("FAILED: %d problem(s) found" % len(all_errors), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
