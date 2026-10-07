# Iranux Script Specification

> Formerly "Iranux Bash Script Standard". Version 1.0 and 1.1 documents keep their
> original titles as historical versions. Persian: «مشخصات فنی اسکریپت Iranux», short
> form «مشخصات اسکریپت Iranux». The `IRANUX_*` block names, the `standard` JSON key and
> the "Iranux Compatible" / "Iranux Verified" badges are unchanged.

**A self-contained metadata and execution-contract specification for Bash scripts that
Iranux runs on Linux servers.**

> Current version: **1.2** (2026-10). Versions 1.0 and 1.1 remain valid for scripts
> that declare them.

A script describes itself inside the Bash file, in strict-JSON heredoc blocks. The
Iranux applications read those blocks to list the script, build its input form in
English or Persian, check the inputs, run the script non-interactively over SSH, read
its exit code, final marker and structured result, and show the outcome to a person
who is not a Linux expert.

## Versions

| Version | Date | Status | Specification | What it added |
|---|---|---|---|---|
| 1.2 | 2026-10 | current | [`docs/specification/iranux-script-specification-v1.2.md`](docs/specification/iranux-script-specification-v1.2.md) | localized text (`i18n`, Persian first), basic/advanced parameters, generated values, the `IRANUX_RESULT` line, `estimated_minutes`; complete rules for certification, exit codes, transport, OS identifiers, risk levels, security |
| 1.1 | 2026-06-16 | valid | [`docs/specification/iranux-bash-script-standard-v1.1.md`](docs/specification/iranux-bash-script-standard-v1.1.md) | required `ui` object: category, action, Material Design Icon |
| 1.0 | 2026-05 | valid | the rules the v1.1 specification inherits, and `schemas/iranux-param-v1.0.schema.json` | metadata, parameters, certification concept, final marker |

New scripts declare `1.2`. Migration guides: [`docs/migration/v1.0-to-v1.1.md`](docs/migration/v1.0-to-v1.1.md),
[`docs/migration/v1.1-to-v1.2.md`](docs/migration/v1.1-to-v1.2.md).

## What a v1.2 script looks like

```bash
#!/usr/bin/env bash

: <<'IRANUX_METADATA'
{
  "standard": { "name": "iranux-script-metadata", "schema_version": "1.2" },
  "script": {
    "id": "show-disk-usage", "name": "Show disk usage", "version": "1.0.0",
    "description": "Shows how much disk space is used and free on the server.",
    "estimated_minutes": 1,
    "i18n": { "fa": { "name": "نمایش فضای دیسک", "description": "نشان می‌دهد چه مقدار از فضای دیسک سرور استفاده شده و چه مقدار آزاد است." } }
  },
  "risk": { "level": "safe" },
  "requirements": { "requires_root": false, "requires_internet": false, "supported_os": [], "required_commands": ["df"] },
  "ui": {
    "category": { "id": "storage", "name": "Storage" },
    "action": { "id": "disk-analysis", "name": "Disk Analysis" },
    "icon": { "library": "mdi", "name": "harddisk" }
  }
}
IRANUX_METADATA

: <<'IRANUX_PARAM'
{
  "name": "mount_point", "label": "Folder to check",
  "description": "The folder whose disk is reported. Leave the default to check the whole system.",
  "type": "path", "required": true, "default": "/", "level": "advanced",
  "i18n": { "fa": { "label": "پوشه‌ی موردنظر", "description": "پوشه‌ای که فضای دیسک آن گزارش می‌شود." } }
}
IRANUX_PARAM

set -euo pipefail
MOUNT_POINT="${MOUNT_POINT:-/}"
[[ -d "$MOUNT_POINT" ]] || { echo "Folder not found: $MOUNT_POINT" >&2; exit 64; }

df -h -- "$MOUNT_POINT"
used="$(df --output=pcent -- "$MOUNT_POINT" | tail -n 1 | tr -dc '0-9')"

echo "IRANUX_RESULT {\"outputs\":[{\"key\":\"used_percent\",\"label\":\"Used\",\"value\":\"${used}%\",\"i18n\":{\"fa\":{\"label\":\"استفاده‌شده\"}}}]}"
echo "__IRANUX_REACHED_END_V1__"
exit 0
```

The blocks are Bash no-ops. The parameter reaches the script as the environment
variable `MOUNT_POINT`. The marker line tells Iranux the script reached its end; the
result line tells the user what came out.

## Script status levels

| Status | Meaning |
|---|---|
| Plain Bash script | No parseable `IRANUX_METADATA` block. Iranux cannot build a form or filter by system. |
| Invalid | Has metadata, but breaks a rule the Iranux runner enforces. Not listed in the web catalog. |
| Iranux Compatible | Metadata, parameters and final marker satisfy every runner rule. This is what authors and AI tools can produce. |
| Iranux Verified | Compatible, plus an `IRANUX_CERTIFICATION` block whose hash matches the file and whose signature verifies against a published Iranux key. Only the official Iranux Validator can produce it. No Iranux signing key has been published yet, so no script is Verified today. |

## Repository layout

| Path | Content |
|---|---|
| `docs/specification/` | the specification of each version (v1.2 is self-contained) |
| `docs/validator/` | the rule tables the Validator applies, with identifiers and levels |
| `docs/migration/` | step-by-step migration between versions |
| `docs/implementation/` | implementation guidance for applications (UI metadata, icon validation) |
| `schemas/` | JSON Schemas (draft 2020-12): metadata v1.1 and v1.2, parameter v1.0 and v1.2, result v1.2, certification v1.0 |
| `Samples/` | complete scripts: `v1.2/` (two scripts that pass every check), `v1.1/`, and a v1.0 sample |
| `tests/` | JSON fixtures that must validate (`valid/`) or fail (`invalid/`), see `tests/README.md` |
| `tools/check_fixtures.py` | checks the fixtures and samples against the schemas and a subset of the validator rules |
| `prompts/convert-to-iranux-specification.md` | a system prompt for an AI agent that converts any Bash script into a v1.2 Compatible candidate |

## Checking a script

```bash
python3 -m pip install jsonschema
python3 tools/check_fixtures.py                       # fixtures and Samples/v1.2
python3 tools/check_fixtures.py my-script.sh          # one script
python3 tools/check_fixtures.py --profile catalog --mdi mdi-names.txt my-script.sh
bash -n my-script.sh && shellcheck my-script.sh
```

`check_fixtures.py` mirrors the regular expressions the Iranux runner uses to find the
blocks, so a script that passes here parses in the applications. It is a repository
test aid, not the Validator, and it issues no certification.

## Converting an existing script

`prompts/convert-to-iranux-specification.md` is a complete system prompt. Given a Bash
script and optional notes, an AI agent following it returns the converted v1.2 script,
a change report and a list of questions where the original's intent was unclear. It
preserves behaviour, marks secrets sensitive, chooses the risk level by the rules of
the specification and never invents URLs, versions, checksums or certification.

## Scope

The specification defines metadata, parameters, localized text, the execution contract
(non-interactive runs, root handling, exit codes, final marker, retries, result line),
security rules, OS identifiers, risk levels and certification. It does not define the
SSH implementation, file transfer, output streaming, rollback, workflows or
conditional parameters.

## Licence

MIT. See `LICENSE`.
