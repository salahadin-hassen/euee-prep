"""Provider-neutral protocol for dispatching extraction jobs."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from typing import Any, Dict, Iterable, List


PROTOCOL_VERSION = "1"
_UUID_RE = re.compile(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")


class WorkerProtocolError(ValueError):
    """Raised when a worker descriptor does not satisfy the protocol."""


def _uuid(value: Any, field: str) -> str:
    if not isinstance(value, str) or not _UUID_RE.fullmatch(value):
        raise WorkerProtocolError("%s must be a UUID" % field)
    return value.lower()


def _pages(value: Any) -> List[int]:
    if not isinstance(value, list) or not value:
        raise WorkerProtocolError("requested_pages must be a non-empty array")
    result: List[int] = []
    for page in value:
        if not isinstance(page, int) or isinstance(page, bool) or page <= 0:
            raise WorkerProtocolError("requested_pages must contain positive integers")
        if page in result:
            raise WorkerProtocolError("requested_pages must not contain duplicates")
        result.append(page)
    return sorted(result)


@dataclass(frozen=True)
class WorkerJobDescriptor:
    protocol_version: str
    job_id: str
    project_id: str
    source_document_id: str
    requested_pages: List[int]
    pipeline_version: str
    result_schema_version: str

    def __post_init__(self) -> None:
        if self.protocol_version != PROTOCOL_VERSION:
            raise WorkerProtocolError("unsupported protocol_version")
        _uuid(self.job_id, "job_id")
        _uuid(self.project_id, "project_id")
        _uuid(self.source_document_id, "source_document_id")
        object.__setattr__(self, "requested_pages", _pages(self.requested_pages))
        if not isinstance(self.pipeline_version, str) or not self.pipeline_version.strip():
            raise WorkerProtocolError("pipeline_version must be non-empty")
        if not isinstance(self.result_schema_version, str) or not self.result_schema_version.strip():
            raise WorkerProtocolError("result_schema_version must be non-empty")

    @classmethod
    def from_dict(cls, value: Any) -> "WorkerJobDescriptor":
        if not isinstance(value, dict):
            raise WorkerProtocolError("worker descriptor must be an object")
        required = {
            "protocol_version",
            "job_id",
            "project_id",
            "source_document_id",
            "requested_pages",
            "pipeline_version",
            "result_schema_version",
        }
        missing = sorted(required - set(value))
        if missing:
            raise WorkerProtocolError("missing descriptor fields: %s" % ", ".join(missing))
        unexpected = sorted(set(value) - required)
        if unexpected:
            raise WorkerProtocolError("unexpected descriptor fields: %s" % ", ".join(unexpected))
        return cls(
            protocol_version=value["protocol_version"],
            job_id=_uuid(value["job_id"], "job_id"),
            project_id=_uuid(value["project_id"], "project_id"),
            source_document_id=_uuid(value["source_document_id"], "source_document_id"),
            requested_pages=_pages(value["requested_pages"]),
            pipeline_version=value["pipeline_version"],
            result_schema_version=value["result_schema_version"],
        )

    def to_dict(self) -> Dict[str, Any]:
        return {
            "protocol_version": self.protocol_version,
            "job_id": self.job_id.lower(),
            "project_id": self.project_id.lower(),
            "source_document_id": self.source_document_id.lower(),
            "requested_pages": sorted(self.requested_pages),
            "pipeline_version": self.pipeline_version,
            "result_schema_version": self.result_schema_version,
        }

    def to_json(self) -> str:
        return json.dumps(self.to_dict(), sort_keys=True, separators=(",", ":"))


def descriptor_from_parts(
    job_id: str,
    project_id: str,
    source_document_id: str,
    requested_pages: Iterable[int],
    pipeline_version: str,
    result_schema_version: str = "1",
) -> WorkerJobDescriptor:
    return WorkerJobDescriptor(
        protocol_version=PROTOCOL_VERSION,
        job_id=job_id,
        project_id=project_id,
        source_document_id=source_document_id,
        requested_pages=list(requested_pages),
        pipeline_version=pipeline_version,
        result_schema_version=result_schema_version,
    )
