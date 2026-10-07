# Test fixtures

`valid/` holds JSON documents that must validate against their schema; `invalid/`
holds documents that must fail. The file-name prefix selects the schema:

| Prefix | Schema |
|---|---|
| `metadata-v1.2-` | `schemas/iranux-metadata-v1.2.schema.json` |
| `v1.1-` | `schemas/iranux-metadata-v1.1.schema.json` |
| `param-v1.2-` | `schemas/iranux-param-v1.2.schema.json` |
| `param-v1.0-` | `schemas/iranux-param-v1.0.schema.json` |
| `result-v1.2-` | `schemas/iranux-result-v1.2.schema.json` |
| `certification-v1.0-` | `schemas/iranux-certification-v1.0.schema.json` |

The rest of the file name says what the fixture shows, for example
`param-v1.2-advanced-required-no-default.json`.

Run the checks, which also validate the sample scripts in `Samples/v1.2/`:

```bash
python3 -m pip install jsonschema
python3 tools/check_fixtures.py
python3 tools/check_fixtures.py --mdi /path/to/mdi-names.txt --profile catalog
```

Both commands exit 0 on this repository. Without `--mdi`, the icon check prints
"IRX1107 skipped" and nothing fails because of it.

`certification-v1.0-illustrative.json` only shows the field shapes. Its hash and
signature are placeholders; no Iranux signing key exists, and nothing in this
repository is a trust anchor.
