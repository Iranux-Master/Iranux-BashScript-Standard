# Changelog

## Version 1.2 - 2026-10-07

Renamed: the document series is now the **Iranux Script Specification** (formerly
"Iranux Bash Script Standard"; Persian «مشخصات فنی اسکریپت Iranux»). The v1.0 and v1.1
documents keep their original titles as historical versions. The `IRANUX_*` block
names and markers, the `standard` JSON key and the "Iranux Compatible" / "Iranux
Verified" badges are unchanged.

Current version. Specification: `docs/specification/iranux-script-specification-v1.2.md`
(self-contained). The field names match the Iranux runner's parser, which already
accepts schema `1.2`.

Added:

- `script.i18n` and parameter `i18n` (keys `fa`, `en`, `fa-IR`...): localized name,
  description, label, placeholder; fallback exact tag → base language → English;
  Persian text rules for non-expert users (§6).
- `script.estimated_minutes` (1–240).
- parameter `level` (`basic` default, `advanced`): an advanced required parameter needs
  a `default` or a `generate`.
- parameter `generate` (`password`, `port`, `uuid`) with the allowed types and the exact
  values the platform produces.
- the structured result line `IRANUX_RESULT {json}` printed before the final marker:
  up to 20 outputs (`key`, `label`, `value`, `type` text/url/copy, `i18n`), and
  `show_generated`; 16 KB limit; secrets never in outputs.
- an enforcement level on every rule (R runner, V validator, W warning, A author) and a
  rule identifier for each, in `docs/validator/validator-rules-v1.2.md`.
- a parameter-to-variable transport contract (uppercase environment variable,
  `${NAME:-}`), the resolution order of user value → generated → default → required.
- an exit-code table (0, 1, 64, 65, 69, 70, 73, 75, 77, 78), retry and idempotency
  rules, the runners' fixed 10-minute run limit (warning IRX1234 when
  `estimated_minutes` exceeds it) and the output phrases the runner treats as a
  failure (IRX1236).
- warnings for an unanchored `validation.pattern` (IRX1235; the runner searches the
  value, it does not match it whole) and a "runner status" note in §9: the web runner
  does not yet read the `IRANUX_RESULT` line, and a `show_generated` entry whose
  value the user typed is refused today.
- operating-system identifiers defined as `/etc/os-release` `ID` values, with a table;
  an empty `supported_os` means any Linux (as the runner already treated it).
- an explicit decision rule for `risk.level` and a pattern table for the Validator.
- security rules: sensitive values never printed, passed on command lines or written
  without 0600; quoting; no `eval`/`bash -c` with parameters; HTTPS only; no
  `curl | bash` without review; `set -x` forbidden; mktemp.
- file rules: UTF-8 without BOM, LF, Bash shebang, no bidirectional control characters.
- the Catalog profile (§16) for script collections such as Just-Bash: Persian text,
  `estimated_minutes` and `supported_os` required.
- JSON Schemas: `iranux-metadata-v1.2`, `iranux-param-v1.2`, `iranux-result-v1.2`,
  `iranux-certification-v1.0`.
- samples `Samples/v1.2/install-nginx-protected-site.sh` (i18n, basic/advanced,
  generated port, sensitive password parameter, result) and
  `Samples/v1.2/show-system-summary.sh` (safe, common distributions, result).
- 15 valid and 40 invalid fixtures under `tests/`, and `tools/check_fixtures.py`.
- `prompts/convert-to-iranux-specification.md`: a system prompt for converting any Bash
  script into a v1.2 Compatible candidate.

Corrected (the v1.1 text disagreed with the Iranux runner or with itself; the runner
is normative):

- the `IRANUX_CERTIFICATION` block has seven fields (`validator_version`,
  `schema_version` = `1.0`, `timestamp`, `script_hash`, `hash_algorithm`,
  `signature`, `signature_key_id`); the three-field example in v1.1 never verified.
- the certifiable content, SHA-256 hash, canonical signed string and
  RSASSA-PKCS1-v1_5/SHA-256 signature are defined; key ids are `iranux-YYYY-NN`; the
  trust-anchor mechanism is described without creating a key.
- option `value` is a non-empty scalar without commas (the `multi_select` separator);
  options may carry `description`.
- `validation` has five defined keys; others are ignored by the runner and refused by
  the Validator.
- `supported_os` no longer requires at least one item.
- the final marker is alone on its line; the runner's static check is the regular
  expression `echo\s+['"]?__IRANUX_REACHED_END_V1__['"]?`, and the web runner stops
  reading the result at the first output line equal to the marker.
- `firewall` is not a Material Design Icons name (the v1.1 icon guide recommends it);
  `wall-fire` and `security-network` exist.
- README paths `samples/v1.1/` and `tests/invalid/` now match the repository.

Compatibility:

- v1.0 and v1.1 documents stay valid under their own rules; the runner never injects
  v1.2 fields into them.
- v1.2 fields in a `1.0`/`1.1` document are tolerated by the runner and refused by the
  Validator; use them only with `"schema_version": "1.2"`.
- the marker stays `__IRANUX_REACHED_END_V1__`; the certification schema stays `1.0`.

## Version 1.1 - 2026-06-16

Added required UI metadata for scripts declaring schema version 1.1:

- `ui.category.id`
- `ui.category.name`
- `ui.action.id`
- `ui.action.name`
- `ui.icon.library`
- `ui.icon.name`

Also added:

- official MDI canonical-name validation;
- the `script-text-outline` runtime fallback;
- the v1.1 metadata JSON Schema;
- parameter JSON Schema;
- UI implementation guidance;
- MDI validation guidance;
- Validator rules;
- one valid v1.1 metadata fixture;
- one v1.1 Nginx installer sample;
- one migration guide from v1.0 to v1.1.

Compatibility notes:

- v1.0 metadata remains governed by v1.0;
- v1.1 requires the complete `ui` object;
- existing parameter blocks and parameter types are unchanged;
- the certification model is unchanged;
- the final marker remains `__IRANUX_REACHED_END_V1__`;
- SSH execution and parameter transport remain outside the metadata standard.

## Version 1.0 - 2026-05

Initial draft defining metadata, parameter, certification, compatibility, validation, and final-marker concepts.
