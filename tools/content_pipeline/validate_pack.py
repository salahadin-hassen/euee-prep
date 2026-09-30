"""Content-pack validation script for the EUEE Prep content pipeline.

Usage::

    python validate_pack.py <pack-file> [<pack-file> ...]

Validates a content pack against the shared v3 content-pack contract before it
ships — the pipeline's last line of defense so bad content never reaches a
device (Decision 021; ``docs/coding-standards.md`` Python section: fail loudly
and specifically, naming the exact field that is invalid).

The contract is defined by the Flutter importer, which is the authority:

* ``lib/features/content/domain/models/content_pack_file.dart`` (shape)
* ``lib/features/content/domain/services/content_pack_validator.dart`` (rules)

and is produced by the Content Studio exporter
(``content-studio/lib/export-pack.ts``). This module must not accept anything
the app would reject, nor reject anything the app accepts.

Validation covers:

* Required metadata and versioning fields (``pack_id``, ``pack_version``,
  ``schema_version``, ``generated_at``, ``checksum``, ``minimum_app_version``)
* Supported ``schema_version`` (``"3"``) and rejection of stale v2 fields
* Stream enum values and the flat Stream → Subject → Paper → Questions shape
* ``paper`` metadata, including ``question_count`` agreement with the question
  list
* Question fields: ids, numbers, prompts, choices, ``correct_choice_index``
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

SUPPORTED_SCHEMA_VERSION = "3"
VALID_STREAMS = {"natural_science", "social_science"}

# Exact field set of the v3 content pack. Anything else is a stale (v2) or
# invented field and must be rejected instead of silently ignored.
TOP_LEVEL_FIELDS = {
    "schema_version",
    "pack_id",
    "pack_version",
    "generated_at",
    "checksum",
    "minimum_app_version",
    "stream",
    "subject",
    "paper",
    "questions",
}
SUBJECT_FIELDS = {"slug", "title"}
PAPER_FIELDS = {"year", "title", "question_count"}
QUESTION_FIELDS = {
    "id",
    "number",
    "prompt",
    "choices",
    "correct_choice_index",
    "explanation",
    "source_page",
}


def validate(pack: Any) -> List[str]:
    """Return every validation problem in ``pack`` as a list of messages.

    An empty list means the pack is valid. Pure — no filesystem access, so it
    is directly unit-testable.
    """
    if not isinstance(pack, dict):
        return ["pack root must be a JSON object"]

    errors: List[str] = []
    _validate_metadata(pack, errors)
    _validate_paper(pack, errors)
    _validate_questions(pack, errors)
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
    _reject_unknown_fields(pack, TOP_LEVEL_FIELDS, "", errors)

    schema_version = pack.get("schema_version")
    if not _is_nonempty_string(schema_version):
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
        _reject_unknown_fields(subject, SUBJECT_FIELDS, "subject.", errors)
        if not _is_nonempty_string(subject.get("slug")):
            errors.append("subject.slug must be a non-empty string")
        if not _is_nonempty_string(subject.get("title")):
            errors.append("subject.title must be a non-empty string")

    if not _is_nonempty_string(pack.get("pack_id")):
        errors.append('"pack_id" must be a non-empty string')
    if not _is_nonempty_string(pack.get("pack_version")):
        errors.append('"pack_version" must be a non-empty string')

    generated_at = pack.get("generated_at")
    if not _is_nonempty_string(generated_at) or not _is_iso8601(generated_at):
        errors.append('"generated_at" must be a valid ISO8601 timestamp')

    if not _is_nonempty_string(pack.get("checksum")):
        errors.append('"checksum" must be a non-empty string')

    if not _is_nonempty_string(pack.get("minimum_app_version")):
        errors.append('"minimum_app_version" must be a non-empty string')


def _validate_paper(pack: Dict[str, Any], errors: List[str]) -> None:
    paper = pack.get("paper")
    if not isinstance(paper, dict):
        errors.append('"paper" must be an object')
        return
    _reject_unknown_fields(paper, PAPER_FIELDS, "paper.", errors)

    year = paper.get("year")
    if not _is_int(year) or year <= 0:
        errors.append("paper.year must be > 0, got %r" % (year,))

    if not _is_nonempty_string(paper.get("title")):
        errors.append("paper.title must be a non-empty string")

    question_count = paper.get("question_count")
    if not _is_int(question_count):
        errors.append('"paper.question_count" must be an integer')
        return
    questions = pack.get("questions")
    if isinstance(questions, list) and question_count != len(questions):
        errors.append(
            "paper.question_count (%s) does not match actual question count (%s)"
            % (question_count, len(questions))
        )


def _validate_questions(pack: Dict[str, Any], errors: List[str]) -> None:
    questions = pack.get("questions")
    if not isinstance(questions, list):
        errors.append('"questions" must be an array')
        return

    seen_ids: set = set()
    for index, question in enumerate(questions):
        where = "questions[%s]" % index
        if not isinstance(question, dict):
            errors.append("%s must be an object" % where)
            continue
        _reject_unknown_fields(question, QUESTION_FIELDS, "", errors, where)

        question_id = question.get("id")
        if not _is_nonempty_string(question_id):
            errors.append("question has an empty id")
        elif question_id in seen_ids:
            errors.append('duplicate question id "%s"' % question_id)
        else:
            seen_ids.add(question_id)
        label = question_id if _is_nonempty_string(question_id) else where

        number = question.get("number")
        if not _is_int(number) or number <= 0:
            errors.append('question "%s" number must be > 0' % label)

        prompt = question.get("prompt")
        if not _is_nonempty_string(prompt):
            errors.append('question "%s" prompt must be non-empty' % label)

        choices = question.get("choices")
        if not isinstance(choices, list):
            errors.append('question "%s" choices must be an array of strings' % label)
            choices = []
        elif not all(isinstance(choice, str) for choice in choices):
            errors.append('question "%s" choices must be an array of strings' % label)
            choices = [c for c in choices if isinstance(c, str)]
        if len(choices) < 2:
            errors.append('question "%s" must have at least two choices' % label)
        for choice in choices:
            if not choice:
                errors.append('question "%s" contains an empty choice' % label)

        correct = question.get("correct_choice_index")
        if not _is_int(correct):
            errors.append('question "%s" correct_choice_index must be an integer' % label)
        elif correct < 0 or correct >= len(choices):
            errors.append(
                'question "%s" correct_choice_index %s is out of range for %s choices'
                % (label, correct, len(choices))
            )

        explanation = question.get("explanation")
        if explanation is not None and not isinstance(explanation, str):
            errors.append(
                'question "%s" explanation must be a string or null' % label
            )

        source_page = question.get("source_page")
        if source_page is not None and not _is_int(source_page):
            errors.append(
                'question "%s" source_page must be an integer or null' % label
            )


def _reject_unknown_fields(
    obj: Dict[str, Any],
    allowed: set,
    prefix: str,
    errors: List[str],
    where: str = "",
) -> None:
    for key in sorted(set(obj) - allowed):
        location = "%s.%s" % (where, key) if where else "%s%s" % (prefix, key)
        errors.append(
            'unexpected field "%s" — the v3 content pack does not define it'
            % location
        )


def _is_nonempty_string(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def _is_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _is_iso8601(value: str) -> bool:
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
