# EUEE Prep — Content Pipeline

Offline tooling for authoring and shipping content packs. This is the
pipeline counterpart to the in-app importer
(`lib/features/content/domain/services/`): packs are validated here **before
they ship** so malformed or badly-versioned content never reaches a device
(Decision 021). The app independently re-validates on-device at import time —
this is the *last line of defense before* that, not a replacement for it.

Pure Python 3.11+, standard library only. No third-party dependencies.

## Validate a pack

```
python tools/content_pipeline/validate_pack.py <pack-file> [<pack-file> ...]
```

Each pack is checked against the contract in `docs/content-pack-spec.md`
and the schema in `docs/database-schema.md`:

- Required metadata and versioning fields (`pack_version`, `schema_version`,
  `generated_at`, `checksum`, `minimum_app_version`)
- Supported `schema_version`
- Stream / grade / resource-type enum values
- Required stable pack-local IDs and pack-wide ID uniqueness
- Broken topic references and broken exam question references
- Duplicate question/exam membership
- One paper per (subject, EC year) per pack (Decision 038)
- Checksum integrity (see below)

The script prints one line per problem (file path + exact field), then a
summary. Exit status is `0` only when every pack validates, so it can gate a
CI step or a packaging script.

## Checksum

`pack_checksum.py` computes the pack integrity checksum and is the Python
counterpart of the importer's checksum
(`lib/features/content/domain/services/content_import_checksum.dart`). Both
implement the same canonical serialization and the same FNV-1a 64-bit hash,
so a checksum computed here verifies identically on-device.

Format: `fnv1a64:<16 hex digits>`. To sign a pack you are authoring, set its
`checksum` field to:

```
python -c "import json; from tools.content_pipeline.pack_checksum import compute_checksum; print(compute_checksum(json.load(open('<pack-file>'))))"
```

## Tests

```
python -m unittest discover tools/content_pipeline/tests -v
```

The tests use the importer's deterministic fixture
(`test/features/content/fixtures/physics_euee_pack_v1.json`), whose embedded
checksum was produced by the Dart side — so the suite also proves the pipeline
and app agree on the canonical checksum byte-for-byte.

## Notes

- `black` is the formatter of record for pipeline Python
  (`docs/coding-standards.md`); run it if available.
- Authoring the real packs themselves is Milestone 3, task 4 — it requires the
  actual EUEE source material (previous-year papers, curriculum mapping),
  which is not yet present in the repository.
