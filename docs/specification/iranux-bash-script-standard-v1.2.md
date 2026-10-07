# Iranux Bash Script Standard v1.2 Specification

Status: current version. Published 2026-10. Supersedes v1.1 as the version new
scripts should declare. Scripts that declare `1.0` or `1.1` remain valid under their own
specifications.

This document is self-contained. It restates every rule a v1.2 script must satisfy,
including the rules inherited from v1.0 and v1.1, so a reader does not need the
earlier documents.

## 0. How to read this document

### 0.1 Requirement words

`MUST`, `MUST NOT`, `SHOULD`, `SHOULD NOT` and `MAY` have their RFC 2119 meanings.

### 0.2 Who enforces a rule

Every rule carries an enforcement level. The level says which tool refuses a script
that breaks the rule, so that every rule in this document is checkable by a stated
party.

| Level | Meaning |
|---|---|
| **R** | Enforced by the Iranux runner's parser. A script that breaks an R rule is **Invalid** in the Iranux applications: it is not listed in the web catalog and the desktop app shows the error. |
| **V** | Enforced by the Iranux Validator as an **error**. A script that breaks a V rule cannot be certified. The runner may accept it. |
| **W** | Reported by the Validator as a **warning**. Certification is still possible; the Catalog profile (§16) turns some warnings into errors. |
| **A** | Author rule that cannot be verified mechanically. The Validator may apply a heuristic and report a warning; the final judgement is human review. |

Rule identifiers in square brackets, for example `[IRX1211]`, refer to
`docs/validator/validator-rules-v1.2.md`, which lists every identifier with its
level, check and message.

### 0.3 Terms

| Term | Meaning |
|---|---|
| Plain Bash script | A script without a parseable `IRANUX_METADATA` block. |
| Invalid | A script with an `IRANUX_METADATA` block that breaks at least one R rule. |
| Iranux Compatible | A script whose metadata, parameters and final marker satisfy every R rule. Certification is not required. |
| Iranux Verified | An Iranux Compatible script with an `IRANUX_CERTIFICATION` block whose hash matches the file and whose signature verifies against a trusted Iranux key (§13). |
| Runner | The Iranux desktop or web application that parses, shows and executes scripts. |
| Validator | The deterministic Iranux Validator tool that applies the full rule set and issues certification. |
| Execution layer | The part of the runner that transports parameter values, runs the script over SSH and reads its output. |
| Catalog | A collection of scripts published for the Iranux applications, such as `Iranux-Master/Just-Bash`. |

## 1. Scope

The standard is a metadata and execution-contract standard for Bash scripts that
Iranux runs on Linux servers over SSH. It defines:

1. the file format and the embedded JSON blocks;
2. the metadata that describes a script and its placement in the Iranux library;
3. the parameters a script accepts, their types, how they are shown to a user in
   English or Persian, and how their values reach the script;
4. the execution contract: non-interactive runs, root handling, exit codes, the final
   marker, retries and the structured result line;
5. security rules for secrets, quoting and downloads;
6. operating-system identifiers and risk levels, with rules for choosing them;
7. certification: what Iranux Verified means and how it is checked.

The standard does not define the SSH library, the file transfer method, output
streaming, rollback, multi-step workflows, dependency graphs or conditional
parameters. Those belong to the execution layer or to a later version.

### 1.1 What v1.2 adds

New features (all optional unless stated):

- localized text in `i18n` objects for the script, each parameter and each result
  output, with Persian (`fa`) as the primary target (§6);
- `script.estimated_minutes` (§5.2);
- parameter `level` (`basic` or `advanced`) (§7.9);
- parameter `generate` (`password`, `port`, `uuid`) (§7.10);
- the structured result line `IRANUX_RESULT` (§9).

Completed or corrected relative to v1.1 (the v1.1 text was incomplete or disagreed with
the Iranux runner; the runner's behaviour is normative here):

- the `IRANUX_CERTIFICATION` block has the fields the runner reads (§13), not the
  three-field example printed in v1.1;
- the hash and signature algorithms, the canonical signed string and the key-id format
  are defined (§13);
- the exact form of the final marker line and the static check the runner applies (§8.5);
- the parameter-to-variable transport contract (§7.12);
- `required`, `default` and empty values (§7.4);
- the `validation` keys the runner applies (§7.8), and option `description`;
- `supported_os` identifiers are `/etc/os-release` `ID` values, and an empty list means
  "any Linux" (§11);
- exit codes (§8.4), retries and idempotency (§8.6);
- explicit decision rules for `risk.level` (§12);
- file encoding, shebang and bidirectional-control rules (§3);
- security rules for sensitive parameters (§10).

## 2. Compatibility statement

- A v1.0 document is validated by the v1.0 rules, a v1.1 document by the v1.1 rules.
- A v1.2 document keeps every v1.1 rule (complete `ui` object, semantic version,
  kebab-case identifiers) and adds the rules in this document.
- v1.2 fields (`i18n`, `estimated_minutes`, `level`, `generate`, `IRANUX_RESULT`) are
  defined only for documents that declare `"schema_version": "1.2"`. The Iranux runner
  tolerates them in `1.0` and `1.1` documents and checks them wherever they appear; the
  Validator rejects them there, because the v1.0 and v1.1 schemas allow no additional
  properties `[IRX1002]`. A script that uses them MUST declare `1.2` **[V]**.
- The final marker stays `__IRANUX_REACHED_END_V1__`. Marker versioning is
  independent of schema versioning.
- The certification block stays at certification schema `1.0`.
- A runner MUST reject a schema version it does not know **[R]** (`[IRX1001]`).

## 3. File requirements

| # | Rule | Level |
|---|---|---|
| 3.1 | The file is UTF-8 encoded and MUST NOT start with a byte-order mark. A BOM breaks the shebang. | V `[IRX1301]` |
| 3.2 | Line endings SHOULD be LF. The runner converts CRLF to LF before `bash -n` and execution, and the Validator normalises line endings before hashing, so CRLF does not fail validation; it is reported. | W `[IRX1302]` |
| 3.3 | The first line MUST be a Bash shebang: `#!/usr/bin/env bash` or `#!/bin/bash`. | V `[IRX1303]` |
| 3.4 | `bash -n <file>` MUST succeed. The runner runs this check on the server before execution and refuses the script when it fails. | V `[IRX1304]`, enforced by the execution layer |
| 3.5 | The file MUST NOT contain Unicode bidirectional control characters U+202A–U+202E or U+2066–U+2069 anywhere (metadata, comments or code). They can make displayed text differ from executed text. U+200C (zero-width non-joiner) and U+200F (right-to-left mark) are allowed. | V `[IRX1305]` |
| 3.6 | `shellcheck` SHOULD report no errors (severity `error`). Warnings are informational. | W `[IRX1306]` |

## 4. Block syntax

### 4.1 Grammar

Iranux blocks are Bash no-op heredocs. The runner locates them with these regular
expressions (`.NET` syntax, `Multiline` option; `^` and `$` match at line boundaries):

```text
IRANUX_METADATA       ^\s*:\s*<<'IRANUX_METADATA'\s*\r?\n([\s\S]*?)\r?\nIRANUX_METADATA\s*$
IRANUX_PARAM          ^\s*:\s*<<'IRANUX_PARAM'\s*\r?\n([\s\S]*?)\r?\nIRANUX_PARAM\s*$
IRANUX_CERTIFICATION  ^\s*:\s*<<'IRANUX_CERTIFICATION'\s*\r?\n([\s\S]*?)\r?\nIRANUX_CERTIFICATION\s*$
```

Consequences, each a rule **[R]** because a block that does not match is simply not
seen:

- the opening line is `:` followed by `<<'NAME'` with single quotes, nothing else on the
  line; `<<-`, `<<"NAME"` and unquoted `<<NAME` are not recognised;
- the opening line MAY be indented; the closing `NAME` line MUST start in column 1 and
  MAY be followed only by whitespace;
- the body (group 1) is trimmed and parsed as JSON.

A block is syntactically a no-op for Bash, so it may appear anywhere a command may
appear. Blocks SHOULD appear at the top level of the file (not inside a function or
conditional) **[W `[IRX1011]`]**. `IRANUX_PARAM` blocks SHOULD appear either all
together after the metadata block or each immediately before the assignment that
reads the parameter **[A]**.

### 4.2 Block counts

| Block | Count | Level |
|---|---|---|
| `IRANUX_METADATA` | exactly one | R `[IRX1012]` (more than one), R (none: the script is Plain) |
| `IRANUX_PARAM` | zero or more | — |
| `IRANUX_CERTIFICATION` | at most one | R `[IRX1013]` |

### 4.3 JSON rules

| # | Rule | Level |
|---|---|---|
| 4.3.1 | Each body is strict JSON (RFC 8259): no comments, no trailing commas, no single quotes, no unquoted keys. | R for metadata (a body that does not parse makes the script Plain, see note), V `[IRX1014]` |
| 4.3.2 | Keys are lowercase `snake_case` exactly as written in this document. | V `[IRX1015]` (the runner matches keys case-insensitively) |
| 4.3.3 | No keys other than those defined here. | V `[IRX1016]` (the runner ignores unknown keys) |
| 4.3.4 | No duplicate keys in one object. | V `[IRX1017]` (the runner keeps the last value) |
| 4.3.5 | Every string value is NFC-normalised UTF-8 without control characters other than U+0009 and U+000A, and without the characters listed in §3.5. | V `[IRX1018]` |

Note on 4.3.1: the current runner treats a metadata body that is not valid JSON as
"no metadata" (the script becomes Plain) and silently skips an `IRANUX_PARAM` body
that is not valid JSON. The standard treats both as errors `[IRX1014]`; the Validator
reports them.

## 5. Metadata (`IRANUX_METADATA`)

The root object has the members `standard`, `script`, `risk`, `ui` (all required) and
`requirements` (optional, SHOULD be present).

### 5.1 `standard`

| Field | Type | Rule | Level |
|---|---|---|---|
| `name` | string | exactly `iranux-script-metadata` | R |
| `schema_version` | string | exactly `1.2` for a v1.2 document | R |

### 5.2 `script`

| Field | Type | Rule | Level |
|---|---|---|---|
| `id` | string | matches `^[a-z][a-z0-9-]*$`; no numeric folder prefix (`network`, not `04-network`); unique in a catalog; 3–64 characters | R (pattern), V `[IRX1201]` (length), V `[IRX1202]` (catalog uniqueness) |
| `name` | string | non-empty English display name; ≤ 80 characters; no trailing "(Iranux Compatible)" or similar status words, status is not metadata | R (non-empty), V `[IRX1203]` |
| `version` | string | semantic version `^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$`; build metadata (`+…`) is not allowed | R |
| `description` | string | non-empty English, one to three sentences, ≤ 500 characters, says what the script does to the server | R (non-empty), V `[IRX1204]` |
| `estimated_minutes` | integer | optional; 1–240; the expected run time on a typical server with normal network speed, including downloads | R |
| `i18n` | object | optional; see §6 | R |

### 5.3 `risk`

| Field | Type | Rule | Level |
|---|---|---|---|
| `level` | string | one of `safe`, `low`, `medium`, `high`, `dangerous`, chosen by §12 | R (value), W `[IRX1501]` (lower than the operations imply) |

### 5.4 `requirements`

| Field | Type | Rule | Level |
|---|---|---|---|
| `requires_root` | boolean | `true` when any command needs root. Default `false`. | V `[IRX1221]` when the script contains a root check or a privileged command and the field is false |
| `requires_internet` | boolean | `true` when the script downloads or calls a network service. Default `false`. | W `[IRX1222]` |
| `supported_os` | array of strings | each item matches `^[a-z][a-z0-9-]*$` and is an `/etc/os-release` `ID` value (§11); unique; an empty or absent array means the script does not restrict the operating system | R (pattern), W `[IRX1223]` (empty) |
| `required_commands` | array of strings | non-empty command names the script needs and does not install itself; unique | R (non-empty strings) |

### 5.5 `ui`

Required, with exactly the members `category`, `action` and `icon`.

| Field | Type | Rule | Level |
|---|---|---|---|
| `category.id`, `action.id` | string | `^[a-z][a-z0-9-]*$`, no numeric prefix | R |
| `category.name`, `action.name` | string | non-empty English label | R |
| `icon.library` | string | exactly `mdi` | R |
| `icon.name` | string | canonical Pictogrammers Material Design Icons name without `mdi-`, matching `^[a-z0-9]+(?:-[a-z0-9]+)*$`; MUST exist in the MDI catalogue the Validator uses | R (syntax), V `[IRX1107]` |

Category is the primary grouping and action the secondary grouping of the library:

```text
Supported operating system → Category → Action → Script button (icon + name)
```

Across a catalog, one category id maps to one category name, one action id maps to
one action name and to one category id **[V, collection level]**. A suggested
category list is in `docs/implementation/ui-metadata-v1.1.md`; it is a convention,
not a closed enum.

When the icon cannot be resolved at runtime the application renders
`script-text-outline`. The fallback never makes invalid metadata valid.

### 5.6 Complete metadata example

```json
{
  "standard": { "name": "iranux-script-metadata", "schema_version": "1.2" },
  "script": {
    "id": "install-nginx-protected-site",
    "name": "Nginx with a protected status page",
    "version": "1.0.0",
    "description": "Installs Nginx, serves a site for your domain and protects the server status page with a username and password.",
    "estimated_minutes": 3,
    "i18n": {
      "fa": {
        "name": "Nginx با صفحه‌ی وضعیت محافظت‌شده",
        "description": "Nginx را نصب می‌کند، سایت دامنه‌ی شما را راه می‌اندازد و صفحه‌ی وضعیت سرور را با نام کاربری و رمز محافظت می‌کند."
      }
    }
  },
  "risk": { "level": "medium" },
  "requirements": {
    "requires_root": true,
    "requires_internet": true,
    "supported_os": ["ubuntu", "debian"],
    "required_commands": ["apt-get", "systemctl"]
  },
  "ui": {
    "category": { "id": "web", "name": "Web Servers" },
    "action": { "id": "web-server-management", "name": "Web Server Management" },
    "icon": { "library": "mdi", "name": "web" }
  }
}
```

## 6. Localized text (`i18n`)

### 6.1 Where it appears

| Place | Localizable fields |
|---|---|
| `script.i18n.{lang}` | `name`, `description` |
| parameter `i18n.{lang}` | `label`, `description`, `placeholder` |
| result output `i18n.{lang}` (§9) | `label` |

The English fields (`name`, `description`, `label`, `placeholder`) remain required and
are the default text.

### 6.2 Rules

| # | Rule | Level |
|---|---|---|
| 6.2.1 | A language key matches `^[a-z]{2,3}(-[A-Z]{2})?$` (`fa`, `en`, `fa-IR`). | R |
| 6.2.2 | A `script.i18n` entry sets `name` or `description` (at least one, non-blank). | R |
| 6.2.3 | Lookup order: exact tag, then its base language (`fa-IR` → `fa`), then the English default. An empty or whitespace string counts as missing and falls back. | runner behaviour, normative |
| 6.2.4 | Use the base language `fa`; use a region tag only when the text really differs by region. | W `[IRX1401]` |
| 6.2.5 | Localized values are plain text: no HTML, Markdown, ANSI escapes or line breaks. | V `[IRX1402]` |
| 6.2.6 | A localized value has the same meaning as the English value. Do not add or remove information. | A |

### 6.3 Persian text for non-expert users

The Iranux web application is used by people who are not Linux experts and read
Persian. These rules apply to every `fa` value:

| # | Rule | Level |
|---|---|---|
| 6.3.1 | Use Persian letters: ی (U+06CC) and ک (U+06A9), not the Arabic ي (U+064A) and ك (U+0643). | W `[IRX1403]` |
| 6.3.2 | Use U+200C (zero-width non-joiner) for the half-space (می‌کند, دامنه‌ی). Do not use spaces or U+200B in its place. | A |
| 6.3.3 | Do not include bidirectional control characters (§3.5). The user interface sets text direction. Latin identifiers (domain names, `Nginx`, `3x-ui`) may appear inside Persian text as they are. | V `[IRX1305]` |
| 6.3.4 | A label is at most 60 characters, a description one or two sentences that say what to enter and what it is for. Do not describe how the script works internally ("the Bash script expects Y or N" is not user text). | W `[IRX1404]` (length) |
| 6.3.5 | Digits in Persian text MAY be Persian or ASCII. Values the user types are normalised by the Iranux applications: for `port`, `int`, `float`, `ip`, `ipv4`, `ipv6`, `cidr`, `date`, `time`, `datetime`, `duration`, `size` and `cron`, Persian and Arabic-Indic digits and the Arabic decimal separator become ASCII before the value reaches the script. Other types are passed unchanged. | runner behaviour, normative |
| 6.3.6 | Boolean words the user types (`yes`, `no`, `1`, `0`) are normalised to `true`/`false` for `bool` parameters by the runner. | runner behaviour, normative |

### 6.4 Catalog expectation

Scripts published in an Iranux catalog SHOULD provide `fa` text for the script name
and description, for the label and description of every basic parameter and for every
result output label (§16 makes this an error for the Catalog profile).

## 7. Parameters (`IRANUX_PARAM`)

Each parameter is one block. Blocks are shown to the user in file order; parameters
with the same `group` are shown together in the order of first appearance.

### 7.1 Fields

| Field | Type | Required | Rule | Level |
|---|---|---|---|---|
| `name` | string | yes | `^[a-z][a-z0-9_]*$`; unique in the script; ≤ 64 characters | R (pattern, uniqueness), V `[IRX1205]` (length) |
| `label` | string | yes | non-empty English label, ≤ 60 characters | R (non-empty), W `[IRX1404]` |
| `description` | string | yes | non-empty English, says what to enter | R (non-empty) |
| `type` | string | yes | one of §7.2 | R (value), V `[IRX1206]` (missing: the runner defaults to `string`) |
| `required` | boolean | yes | see §7.4 | V `[IRX1207]` (missing: the runner defaults to `false`) |
| `default` | string, number, boolean or array | no | compatible with `type` (§7.4) | V `[IRX1208]`; arrays only for `multi_select` |
| `example` | string, number or boolean | no | a realistic example, never a real secret | V `[IRX1209]` (secret-like example on a sensitive parameter) |
| `placeholder` | string | no | hint shown in the empty field | R (must be a string: a number here breaks the block) |
| `group` | string | no | English group label | — |
| `sensitive` | boolean | no | see §7.6 | — |
| `options` | array | for `enum`, `multi_select` | see §7.7 | R |
| `validation` | object | no | see §7.8 | V `[IRX1210]` (unknown key) |
| `level` | string | no | `basic` (default) or `advanced` (§7.9) | R |
| `generate` | string | no | `password`, `port` or `uuid` (§7.10) | R |
| `i18n` | object | no | §6; keys `label`, `description`, `placeholder` | R |

### 7.2 Types

Every value reaches the script as text (§7.12). The "Format" column is the text the
script receives after the runner has validated it.

| Type | Meaning | Format received by the script | Runner validation |
|---|---|---|---|
| `string` | free text, one line | as typed | none |
| `multiline` | free text, several lines | as typed, LF line breaks | none |
| `int` | integer | ASCII digits with optional `-` | parses as a 64-bit integer |
| `float` | decimal number | ASCII, `.` decimal separator | parses as a number |
| `bool` | true or false | `true` or `false` | one of the two |
| `enum` | one of `options` | the chosen option `value` | value is in `options` |
| `multi_select` | several of `options` | option values joined with `,` and no spaces | every value is in `options` |
| `password` | a human password; always sensitive | as typed | none |
| `secret` | API key, token, license key; always sensitive | as typed | none |
| `port` | TCP/UDP port | ASCII digits | 1–65535 |
| `email` | email address | as typed | address syntax |
| `url` | absolute `http`/`https` URL | as typed | absolute URI with `http` or `https` |
| `domain` | DNS name with at least one dot | as typed | labels of letters, digits and `-`, ≤ 253 characters |
| `hostname` | RFC 1123 host name | as typed | host-name syntax |
| `ip` | IPv4 or IPv6 | as typed | parses as an address |
| `ipv4` | IPv4 | dotted decimal | IPv4 only |
| `ipv6` | IPv6 | as typed | IPv6 only |
| `cidr` | address and prefix | `a.b.c.d/n` | address parses, prefix 0–32 |
| `mac` | MAC address | `AA:BB:CC:DD:EE:FF` or with `-` | six hex pairs |
| `path` | absolute or relative path on the server | as typed | no NUL, CR or LF |
| `date` | calendar date | `YYYY-MM-DD` recommended | parses as a date |
| `time` | time of day | `HH:MM` or `HH:MM:SS` | parses as a time |
| `datetime` | date and time | ISO 8601 | parses as a date and time |
| `duration` | time span | `30s`, `5m`, `2h`, `1d` or `HH:MM:SS` | one of those forms |
| `size` | byte size | number with optional unit `B`, `KB`, `MB`, `GB`, `TB`, `KiB`, `MiB`, `GiB`, `TiB` | that form |
| `cron` | cron schedule | five fields | five fields of cron syntax |
| `json` | JSON document | as typed | parses as JSON |
| `ssh_public_key` | OpenSSH public key | one line | `ssh-rsa`, `ssh-ed25519` or `ecdsa-sha2-nistp*` key |
| `private_key` | PEM private key; always sensitive | PEM text | contains `-----BEGIN … PRIVATE KEY-----` and `-----END` |
| `certificate` | PEM certificate | PEM text | contains `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----` |

Type selection rules **[A]**:

- use the most specific type the runner can validate; when the value can only be
  checked on the server (a service name, a package name, a user name), use `string`;
- use `bool` only when the script compares the variable with `true`/`false`. When the
  script expects `Y`/`N`, `yes`/`no`, `1`/`0` or menu numbers, use `enum` with the
  exact values the script compares against, and user-facing labels such as "Yes" and
  "No". The runner shows labels and sends values;
- use `secret` for API keys and tokens, `password` for passwords a human may type.

### 7.3 Empty values and `${NAME:-}`

The execution layer MAY omit the variable of a parameter the user left empty instead
of exporting an empty string. A script MUST therefore read every parameter with a
default expansion, `"${NAME:-}"` or `"${NAME:-default}"`, so that `set -u` does not
abort and the two cases behave the same **[W `[IRX1212]`]**.

### 7.4 `required` and `default`

The runner resolves a parameter's value in this order, and this order is normative:

1. a non-empty value the user entered (validated by type and `validation`);
2. otherwise, when `generate` is set, a generated value (§7.10);
3. otherwise, `default` (converted to its text form);
4. otherwise, when `required` is `true`, the run is refused with the message that the
   field is required;
5. otherwise the parameter is empty (variable unset or empty, §7.3).

Consequences:

- `required: true` with a `default` means the field is pre-filled and the user may
  change it but not clear it;
- a `default` MUST be compatible with the type **[V `[IRX1208]`]**: `bool` →
  `true`/`false`; `int`/`port`/`float` → a number of that kind; `enum` → one of
  `options[].value`; `multi_select` → an array whose items are all option values;
  `password`, `secret`, `private_key` → no default at all (a default secret is a shared
  secret) **[V `[IRX1209]`]**;
- the Bash fallback MUST use the same default: `"default": "N"` pairs with
  `X="${X:-N}"` **[W `[IRX1213]`]**.

### 7.5 `example` and `placeholder`

`example` is a realistic value shown as help; `placeholder` is the grey text in an
empty field. Neither is used as a value. A sensitive parameter MUST NOT carry a
realistic secret as example or placeholder **[V `[IRX1209]`]**.

### 7.6 Sensitive parameters

| # | Rule | Level |
|---|---|---|
| 7.6.1 | `password`, `secret` and `private_key` are sensitive whether or not `sensitive` is set; the runner sets the flag. | R (runner behaviour) |
| 7.6.2 | Any other parameter whose value must not be shown (for example a `string` holding a token) MUST set `"sensitive": true`. | A; W `[IRX1214]` when the name contains `password`, `passwd`, `passphrase`, `secret`, `token`, `api_key`, `apikey`, `private_key`, `credential` and the parameter is not sensitive |
| 7.6.3 | The runner masks sensitive values in forms, logs, previews, history, reports and error messages, and redacts them from captured output. | runner behaviour, normative |
| 7.6.4 | The script's obligations for sensitive values are in §10.1. | V/W |

### 7.7 `options`

For `enum` and `multi_select`, `options` is a non-empty array of objects
`{ "label", "value", "description"? }`:

| # | Rule | Level |
|---|---|---|
| 7.7.1 | `label` is a non-empty string shown to the user. | R |
| 7.7.2 | `value` is a non-empty string, number or boolean; the script receives its text form. | R |
| 7.7.3 | values are unique within the parameter. | V `[IRX1215]` |
| 7.7.4 | a value MUST NOT contain `,` (the `multi_select` separator) or a line break. | V `[IRX1216]` |
| 7.7.5 | `description` is optional help for the option. | — |
| 7.7.6 | options MAY be localized through the parameter's `i18n` only as a whole label set in a later version; v1.2 has no per-option `i18n`. Keep option labels short and recognisable (`Yes`, `No`, product names). | — |

### 7.8 `validation`

Extra constraints the runner applies after the type check. Only these keys are
defined **[V `[IRX1210]` for others]**:

| Key | Type | Applies to | Check |
|---|---|---|---|
| `min_length` | integer | text types | value length ≥ |
| `max_length` | integer | text types | value length ≤ |
| `min_value` | number | numeric types | value ≥ |
| `max_value` | number | numeric types | value ≤ |
| `pattern` | string | text types | the whole value matches the regular expression |

`pattern` is evaluated by the runner with .NET regular expressions and a 250 ms time
limit; a pattern that does not compile or times out refuses the value. Use the common
subset of .NET and ECMAScript syntax, anchor with `^` and `$`, and avoid nested
quantifiers **[A]**. Do not repeat a check the type already performs **[W
`[IRX1217]`]**.

### 7.9 `level`

`"level": "basic"` (default) or `"advanced"`. The web setup wizard shows basic
parameters and hides advanced ones behind "Advanced settings", filling them from their
defaults or generators. Therefore:

| # | Rule | Level |
|---|---|---|
| 7.9.1 | An advanced parameter with `required: true` MUST have a `default` or a `generate`. | R |
| 7.9.2 | A parameter a non-expert must decide (domain, email, a choice that changes what gets installed) is basic. A tuning value with a sensible default (port, path, version tag) is advanced. | A |
| 7.9.3 | At most eight basic parameters per script. | W `[IRX1218]` |

### 7.10 `generate`

The platform can create a value when the user leaves the field empty:

| `generate` | Allowed `type` | Value the script receives |
|---|---|---|
| `password` | `password`, `secret`, `string` | 20 characters from `ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789` (no `0`, `1`, `I`, `O`, `l`; no symbols, safe in URLs, shells and config files) |
| `port` | `port`, `int` | a random port in 20000–60999 not used by another generated parameter of the same job |
| `uuid` | `string`, `secret` | RFC 4122 version 4 UUID, lowercase, hyphenated |

| # | Rule | Level |
|---|---|---|
| 7.10.1 | `generate` is one of the three values and compatible with `type` per the table. | R |
| 7.10.2 | A generated parameter SHOULD NOT also have a `default`; the generator takes precedence and the default is never used by a generating runner. | W `[IRX1219]` |
| 7.10.3 | The platform stores the generated value encrypted, passes it to the script like any other value, redacts it from output when the type is sensitive, and shows it to the user once when the script lists the parameter in `show_generated` (§9). | runner behaviour, normative |
| 7.10.4 | Not every execution layer generates values (the desktop runner does not). A script SHOULD handle an empty generated parameter: either create a value itself or exit with code 64. | A |

### 7.11 `i18n`

Keys `label`, `description` and `placeholder`; rules of §6.

### 7.12 Transport: how a value reaches the script

The execution layer exports each resolved value as an environment variable before
starting the script:

| # | Rule | Level |
|---|---|---|
| 7.12.1 | The variable name is the parameter `name` in upper case: `panel_port` → `PANEL_PORT`. The desktop runner additionally exports the lowercase name; scripts MUST read the uppercase one. | normative; V `[IRX1211]` when a declared parameter's uppercase name never appears in the script |
| 7.12.2 | Values are exported with POSIX single-quote escaping (`export NAME='value'` with `'` written as `'\''`), so any character except NUL survives. The runner refuses values that contain NUL or exceed its length limit. | execution layer |
| 7.12.3 | The script MUST NOT read parameters from positional arguments, `read`, or files written by the user. It MAY accept positional arguments as a fallback for manual use: `TARGET="${TARGET:-${1:-}}"`. | V `[IRX1220]` (prompting), A |
| 7.12.4 | The script MUST NOT re-export or print sensitive variables (§10.1). | V |
| 7.12.5 | The script MUST quote every expansion of a parameter: `"$DOMAIN"`, `"${PANEL_PORT:-}"`. Unquoted expansions change behaviour for values with spaces or glob characters and are the usual injection path. | V `[IRX1602]` |

Reading pattern:

```bash
: <<'IRANUX_PARAM'
{ "name": "site_domain", "label": "Domain", "description": "The domain this site answers for.", "type": "domain", "required": true }
IRANUX_PARAM

SITE_DOMAIN="${SITE_DOMAIN:-}"
```

## 8. Execution contract

### 8.1 Environment

The runner uploads the file to the server, converts line endings, runs `bash -n`,
makes it executable and runs it from the login user's home directory with the
parameter variables exported. The desktop runner uses a pseudo-terminal; the web
runner captures stdout and stderr. Scripts MUST NOT depend on the current directory,
on `$0` or on a terminal **[A]**.

### 8.2 Non-interactive

| # | Rule | Level |
|---|---|---|
| 8.2.1 | The normal path MUST NOT wait for terminal input. There is no user at the keyboard; a prompt hangs until the execution layer's timeout and the run fails. Every input is a declared parameter. | V `[IRX1220]`: a `read` builtin whose simple command has no input redirection (`<`, `<<<`, `<<`) and is not in a pipeline, or `select`, or `read -p` |
| 8.2.2 | Package managers run non-interactively: `DEBIAN_FRONTEND=noninteractive apt-get install -y`, `dnf -y`, `pacman --noconfirm`, `zypper -n`. | W `[IRX1224]` (`apt-get install` without `-y`, and so on) |
| 8.2.3 | The script MUST NOT call `clear` or move the cursor; the web runner shows the raw log. Colour codes are allowed. | W `[IRX1225]` |

### 8.3 Root and `sudo`

| # | Rule | Level |
|---|---|---|
| 8.3.1 | When `requires_root` is `true`, the execution layer runs the script as root (the Iranux runners use a root login or `sudo -i` with a stored password). The script SHOULD still check `[[ $(id -u) -eq 0 ]]` and exit 77 otherwise, so a manual run fails clearly. | A |
| 8.3.2 | When `requires_root` is `false`, the script MUST NOT require root for its normal path. It MAY use `sudo -n` for an optional step and MUST handle its failure. | V `[IRX1221]` |
| 8.3.3 | The script MUST NOT call `sudo` without `-n`; an interactive `sudo` prompt hangs (§8.2.1). | W `[IRX1226]` |
| 8.3.4 | The script MUST NOT store, print or echo the sudo password; the execution layer handles it. | V (§10.1) |

### 8.4 Exit codes

| # | Rule | Level |
|---|---|---|
| 8.4.1 | Exit code 0 means the script reached its intended end and printed the final marker. Any failure exits non-zero and does not print the marker. | A; the runner treats "exit 0 and marker" as success and everything else as failure |
| 8.4.2 | Exit codes SHOULD follow the table below (sysexits.h values). | W `[IRX1227]` (a literal exit code outside the table, other than 1) |
| 8.4.3 | Exit codes 126, 127 and 128 and above MUST NOT be used; Bash reserves them. | V `[IRX1228]` |

| Code | Name | Use |
|---|---|---|
| 0 | OK | the normal path completed |
| 1 | FAIL | a failure the other codes do not cover |
| 64 | USAGE | a parameter is missing, empty or invalid for the script's own rules |
| 65 | DATAERR | downloaded or read data is malformed, or a checksum does not match |
| 69 | UNAVAILABLE | a download, API or service the script needs could not be reached |
| 70 | SOFTWARE | an internal error the script detected (an assertion) |
| 73 | CANTCREAT | a file or directory could not be created |
| 75 | TEMPFAIL | a temporary failure; running again later may succeed |
| 77 | NOPERM | not root or insufficient permission |
| 78 | CONFIG | unsupported operating system, missing required command, or the server is in a state the script cannot work with |

### 8.5 Final marker

| # | Rule | Level |
|---|---|---|
| 8.5.1 | The script prints the marker on its own line, to stdout, exactly: `echo "__IRANUX_REACHED_END_V1__"`. Nothing else is on that output line. | R (static check: the file contains a line matching `echo\s+['"]?__IRANUX_REACHED_END_V1__['"]?`); V `[IRX1231]` (the `echo` prints anything else on the same line) |
| 8.5.2 | The marker is printed only on a successful path, after all work is done and after the `IRANUX_RESULT` line (§9). When the path ends with `exit 0`, the marker is the line before it. Every successful path prints it; no failure path prints it. | A; W `[IRX1232]` when an `echo` of the marker is followed within three lines by a non-zero `exit` |
| 8.5.3 | The marker MUST NOT appear in comments, strings or other output. The runner detects it by substring in the output and by regular expression in the file. | V `[IRX1233]` (second occurrence outside an `echo`) |
| 8.5.4 | The marker is stdout. The runner reads stdout and stderr together; the web runner stops reading `IRANUX_RESULT` at the first line equal to the marker. | normative |

The marker means "execution reached the intended final point". It does not by
itself prove that every operation succeeded; exit code and `IRANUX_RESULT` complete
the picture.

### 8.6 Retries, timeouts and idempotency

| # | Rule | Level |
|---|---|---|
| 8.6.1 | The execution layer MAY run the script again after a failed attempt or after an attempt that exited 0 without the marker (the desktop runner retries up to five times). A script MUST therefore be idempotent: a second run with the same inputs on the same server completes without error and without duplicating its effects. | A |
| 8.6.2 | Patterns that break idempotency: appending to a file in `/etc` without first checking the line exists; `mkdir` without `-p`; `useradd` without checking `id`; `mv` into a path that exists; `wget -O` into a path then `tar` that fails when files exist. | W `[IRX1701]`–`[IRX1704]` |
| 8.6.3 | Scripts write configuration files whole (`cat > file <<EOF`) or edit them in place with an idempotent `sed`, and start services with `systemctl enable --now` or `restart`, which are repeatable. | A |
| 8.6.4 | The execution layer enforces a timeout. `estimated_minutes` SHOULD be a realistic upper estimate; a script whose work may take longer than ten minutes states so in `estimated_minutes` and in its description. | A |

### 8.7 Output

| # | Rule | Level |
|---|---|---|
| 8.7.1 | Print a short progress line before each major step (`echo "== Installing Nginx"`) so the user can follow the log. | A |
| 8.7.2 | Print errors to stderr with a plain-language sentence and exit with the matching code. | A |
| 8.7.3 | Do not print more than a few hundred lines on the normal path; redirect verbose tool output to a log file under `/var/log` or `/tmp` and name the file in an `IRANUX_RESULT` output when it helps. | A |

## 9. Structured result (`IRANUX_RESULT`)

The script MAY print one line that the Iranux result page renders. Without it the
user sees only the log.

### 9.1 Format

```text
IRANUX_RESULT <json>
```

exactly: the literal `IRANUX_RESULT`, one space, and a JSON object on the same line,
to stdout, before the final marker.

```json
{
  "outputs": [
    { "key": "site_url", "label": "Site address", "value": "https://example.com/", "type": "url",
      "i18n": { "fa": { "label": "آدرس سایت" } } },
    { "key": "admin_username", "label": "Username", "value": "admin", "type": "copy",
      "i18n": { "fa": { "label": "نام کاربری" } } }
  ],
  "show_generated": ["admin_password"]
}
```

### 9.2 Fields

| Field | Type | Rule |
|---|---|---|
| `outputs` | array | 0–20 items |
| `outputs[].key` | string | non-empty, unique within the result; SHOULD match `^[a-z][a-z0-9_]*$` `[W IRX1801]` |
| `outputs[].label` | string | non-empty English label |
| `outputs[].value` | string | the value as text. Numbers and booleans MUST be written as JSON strings; a non-string makes the whole result invalid |
| `outputs[].type` | string | optional: `text` (default), `url` (an absolute `http`/`https` URL the page links), `copy` (a value the user will paste, shown with a copy button) |
| `outputs[].i18n.{lang}.label` | string | localized label (§6) |
| `show_generated` | array of strings | names of parameters that have `generate` whose values the result page shows once, from the platform's encrypted copy |

### 9.3 Rules

| # | Rule | Level |
|---|---|---|
| 9.3.1 | The line is at most 16 384 characters. | runner: a longer line is refused and reported |
| 9.3.2 | The JSON is strict and matches §9.2. | runner: invalid JSON or a broken rule is reported and no result is shown; the run can still succeed |
| 9.3.3 | The last `IRANUX_RESULT` line before the final marker wins; lines after the marker are ignored. Print it once, immediately before the marker. | normative; W `[IRX1802]` (more than one `IRANUX_RESULT` in the file) |
| 9.3.4 | A `url` value is an absolute `http` or `https` URL. | runner |
| 9.3.5 | Every `show_generated` entry names a parameter with `generate`. | runner |
| 9.3.6 | Secrets never go in `outputs`: not passwords, tokens, keys, nor the values of sensitive parameters. Generated secrets are shown through `show_generated`. A script that creates a secret itself (not through `generate`) writes it to a root-only file and names the path in a `text` output. | V `[IRX1803]` (a sensitive parameter's variable inside the `IRANUX_RESULT` line) |
| 9.3.7 | Values are built with proper JSON escaping. Use `jq -nc` when `jq` is a required command, otherwise the helper in Appendix C. | A |

## 10. Security rules

### 10.1 Sensitive values

| # | Rule | Level |
|---|---|---|
| 10.1.1 | A sensitive parameter's value MUST NOT be printed: no `echo`, `printf`, `cat <<EOF` to stdout, log line or error message containing `$NAME`/`${NAME…}` of a sensitive parameter. | V `[IRX1601]` |
| 10.1.2 | `set -x` / `set -o xtrace` MUST NOT be enabled while a sensitive variable is in scope; the trace prints values. | V `[IRX1603]` |
| 10.1.3 | A sensitive value SHOULD NOT be passed as a command-line argument to another program, because arguments are visible to every user in `ps`. Prefer stdin (`printf '%s' "$PW" \| tool --password-stdin`), an environment variable the tool reads, or a file created with mode 0600. | W `[IRX1604]` |
| 10.1.4 | A file that receives a secret is created with `umask 077` or `install -m 600`, owned by the service user or root. | W `[IRX1605]` (a redirection of a sensitive variable into a file without a preceding `umask 077`, `install -m 600` or `chmod 600` on that path) |
| 10.1.5 | Sensitive values MUST NOT be included in `IRANUX_RESULT` (§9.3.6). | V `[IRX1803]` |
| 10.1.6 | Secrets the script generates itself are shown at most once, in the result, or stored in a root-only file whose path the result names. The script MUST NOT keep them in world-readable files, shell history or `/tmp`. | A |

### 10.2 Quoting and construction of commands

| # | Rule | Level |
|---|---|---|
| 10.2.1 | Every parameter expansion is double-quoted (§7.12.5). | V `[IRX1602]` |
| 10.2.2 | Parameter values MUST NOT be used with `eval`, `bash -c "…$X…"`, `sh -c`, `source`, or as a command name. | V `[IRX1606]` |
| 10.2.3 | When a value becomes part of another command string (a `sed` expression, an SQL statement, a `jq` filter), it is passed as data (`--arg`, `-v`, a here-string), not spliced into the program text. | W `[IRX1607]` |
| 10.2.4 | Paths from parameters are used with `--` before them when the tool supports it, and never joined with `rm -rf` without an absolute, non-empty check. | W `[IRX1608]` |

### 10.3 Downloads and remote code

| # | Rule | Level |
|---|---|---|
| 10.3.1 | Downloads use HTTPS. `--no-check-certificate`, `-k`/`--insecure` MUST NOT be used. | V `[IRX1611]` |
| 10.3.2 | `curl … \| bash`, `wget -O- … \| sh` and similar execution of downloaded text without saving and checking it are reported. Prefer download to a file, verify a checksum or signature when the upstream publishes one, then run. | W `[IRX1612]` |
| 10.3.3 | Versions, URLs and checksums come from the upstream project or the script author. A converter or AI tool MUST NOT invent them. | A |
| 10.3.4 | Downloaded archives are extracted into a directory the script created, not into `/` or `/usr/local` directly. | W `[IRX1613]` |

### 10.4 Strict mode

`set -euo pipefail` (optionally with `-E` and an `ERR` trap) is RECOMMENDED for new
scripts, placed after the Iranux blocks and before the first command **[W
`[IRX1621]` when absent]**. A conversion of an existing script MUST NOT add it unless
the author asks, because it changes behaviour (§15 of the migration guide, and the
converter prompt). With `set -u`, every parameter read uses `${NAME:-}` (§7.3).

### 10.5 Temporary files

Use `mktemp`/`mktemp -d` and remove the result in an `EXIT` trap. Do not write
predictable names under `/tmp` **[W `[IRX1622]`]**.

## 11. Operating systems

### 11.1 Identifiers

`requirements.supported_os` lists the `ID` values of `/etc/os-release` on which the
script is tested, lowercase, without version:

| ID | System | Notes |
|---|---|---|
| `ubuntu` | Ubuntu | |
| `debian` | Debian | |
| `rhel` | Red Hat Enterprise Linux | |
| `centos` | CentOS Stream | |
| `almalinux` | AlmaLinux | |
| `rocky` | Rocky Linux | |
| `ol` | Oracle Linux | the ID is `ol`, not `oracle` |
| `fedora` | Fedora | |
| `amzn` | Amazon Linux | |
| `arch` | Arch Linux | |
| `manjaro` | Manjaro | |
| `opensuse-leap` | openSUSE Leap | |
| `opensuse-tumbleweed` | openSUSE Tumbleweed | |
| `alpine` | Alpine Linux | `/bin/bash` is not installed by default |

Other `ID` values are allowed when they match the pattern `^[a-z][a-z0-9-]*$` and are
real `/etc/os-release` identifiers **[W `[IRX1229]` for an identifier outside this
table]**. Versions are not part of the identifier; a script that supports only some
releases checks `VERSION_ID` itself and exits 78 otherwise.

The Iranux web catalog filters by **family**: the first known family word in a
server image name (`ubuntu-22.04`, `webdock-ubuntu-noble-cloud` → `ubuntu`;
`opensuse-tumbleweed` → `opensuse`). A script whose list is empty is offered on every
server.

### 11.2 Detection inside the script

A script that behaves differently per system reads `/etc/os-release` and uses `ID`
and `ID_LIKE`:

```bash
detect_os() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-}"
    OS_LIKE="${ID_LIKE:-}"
  else
    echo "Cannot read /etc/os-release." >&2
    exit 78
  fi
}

case "$OS_ID" in
  ubuntu|debian) PKG=apt ;;
  rhel|centos|almalinux|rocky|ol|fedora|amzn) PKG=dnf ;;
  *) case " $OS_LIKE " in *" debian "*) PKG=apt ;; *" rhel "*|*" fedora "*) PKG=dnf ;; *)
       echo "Unsupported operating system: $OS_ID" >&2; exit 78 ;; esac ;;
esac
```

A script whose `supported_os` names systems MUST exit 78 with a message on any
other system instead of guessing a package manager **[W `[IRX1230]`: a `case` on the
OS id whose default branch installs packages]**.

## 12. Risk levels

`risk.level` tells the user how much the script can change or break and lets the
platform refuse or confirm. The Iranux web platform refuses `dangerous` scripts
unless an administrator allows them; the desktop app shows the level in colour.

### 12.1 Decision rule

Determine the highest level reached by **any** operation the script can perform on
**any** path, including optional steps. That is the level. When in doubt between
two levels, choose the higher one.

| Level | Choose it when the script … | Typical operations |
|---|---|---|
| `safe` | only reads: no file outside its own temporary directory is written, no service or setting changes, no network write (GET requests allowed) | `cat`, `ss`, `df`, `systemctl status`, `dig`, `curl` GET |
| `low` | writes only files it owns or creates in user, application or backup directories; starts or restarts only the service it manages; does not install system packages or open ports | create a backup, rotate an app log, restart one application service, write a file under `/opt/<app>` |
| `medium` | installs or upgrades packages or software; creates, enables or configures services for the installed software; writes that software's configuration under `/etc`; opens a firewall port only for that software | `apt-get install`, `systemctl enable --now`, Nginx/Docker/panel installers, certificate issuance |
| `high` | changes how the server can be reached or who can access it, or changes shared system state: SSH daemon configuration, firewall rules beyond one application port, users, groups, sudoers, file permissions outside the application, system network settings (interfaces, DNS resolver, routes, `sysctl`), kernel modules, system-wide cron, or changes to an external account (DNS zones, cloud resources) | `sshd_config`, `ufw`/`iptables`/`nft` rules, `useradd`/`usermod`, `chmod`/`chown -R` on system paths, Cloudflare/DNS API writes |
| `dangerous` | can destroy data or lock the operator out: removes directories it did not create, formats or writes to block devices, replaces core system services (DNS on port 53, the SSH daemon, systemd units of other software), changes the SSH port or disables password login, resets the firewall (`ufw reset`, `iptables -F` on all chains), deletes users, modifies the bootloader or kernel, or reinstalls the system | `rm -rf` on existing paths, `mkfs`, `dd of=/dev/…`, `ufw --force reset`, `userdel`, `sed -i` on `PermitRootLogin`/`PasswordAuthentication`, `Port` in `sshd_config` |

### 12.2 Mechanical check

The Validator scans the script for the patterns in the table of
`validator-rules-v1.2.md` § Risk patterns and reports `[IRX1501]` when the declared
level is lower than the level the patterns imply. The check cannot lower a level and
cannot see every risk; the author remains responsible.

### 12.3 Documenting the choice

The `description` of a `high` or `dangerous` script MUST say what it changes
(firewall, SSH, DNS, data) in one sentence the user can judge **[W `[IRX1502]`]**.

## 13. Certification

### 13.1 Statuses

| Status | Condition |
|---|---|
| Iranux Compatible | metadata, parameters and marker satisfy every R rule |
| Iranux Verified | Compatible, plus an `IRANUX_CERTIFICATION` block whose `script_hash` equals the hash of the certifiable content and whose `signature` verifies with a trusted Iranux public key identified by `signature_key_id` |
| certification present, not verified | the block exists but the hash or signature does not verify, or the key id is not trusted; the application shows the script as Compatible with that note |

Only the official Iranux Validator creates certification blocks. Script authors and AI
tools MUST NOT create, copy or edit one **[A; a block with a wrong hash or an unknown
key never verifies]**. A script with a block that lacks `validator_version`,
`script_hash` or `signature`, or whose `schema_version` is not `1.0`, is Invalid in the
runner **[R]**; a block that lacks any other field of the table fails verification and
the Validator **[V]**.

Today no Iranux signing key has been published. Until the owner creates the key pair
and publishes the public key (§13.6), no script can be Verified, and the Iranux
applications show every Compatible script as "Iranux Compatible".

### 13.2 Block format

```bash
: <<'IRANUX_CERTIFICATION'
{
  "validator_version": "1.0.0",
  "schema_version": "1.0",
  "timestamp": "2026-10-07T12:00:00Z",
  "script_hash": "3f2a…64 lowercase hexadecimal characters…",
  "hash_algorithm": "sha256",
  "signature": "…lowercase hexadecimal…",
  "signature_key_id": "iranux-2026-01"
}
IRANUX_CERTIFICATION
```

| Field | Rule | Level |
|---|---|---|
| `validator_version` | non-empty; the Validator's semantic version | R (non-empty) |
| `schema_version` | exactly `1.0` | R |
| `timestamp` | UTC, `YYYY-MM-DDTHH:MM:SSZ`; not in the future | V (format); verification fails when missing, unparseable or in the future |
| `script_hash` | SHA-256 of the certifiable content, 64 lowercase hex characters | R (non-empty; compared case-insensitively), V (format) |
| `hash_algorithm` | exactly `sha256` | V; the runner assumes `sha256` |
| `signature` | hex-encoded signature (§13.4) | R (non-empty) |
| `signature_key_id` | `^iranux-[0-9]{4}-[0-9]{2}$`; identifies a published key | V (format); verification fails when the id is missing or not trusted |

### 13.3 Certifiable content and hash

1. Take the file text as UTF-8.
2. Replace `\r\n` with `\n`, then any remaining `\r` with `\n`.
3. Remove every match of
   `^\s*:\s*<<'IRANUX_CERTIFICATION'\s*\n[\s\S]*?\nIRANUX_CERTIFICATION\s*$`
   (`Multiline`) by replacing it with the empty string. Do not trim the remainder.
4. `script_hash` = SHA-256 of the UTF-8 bytes of the result, lowercase hex.

Because `\s*` at both ends of the pattern absorbs adjacent blank lines, the block is
placed at the very end of the file, after the final `exit 0` line, separated by one
blank line. Then the certifiable content is the file as it was before certification.
Any change to the file after certification, including a changed icon or a Persian
label, changes the hash and voids the certification.

### 13.4 Signature

The Validator signs the canonical string

```text
validator_version=<value>\n
schema_version=<value>\n
timestamp=<value>\n
script_hash=<value>\n
hash_algorithm=<value>\n
signature_key_id=<value>
```

(six lines joined with `\n`, no trailing newline, UTF-8) with **RSASSA-PKCS1-v1_5
over SHA-256**. `signature` is the signature bytes as lowercase hexadecimal. This is
the algorithm the Iranux runner verifies; a different algorithm cannot be Verified.
Keys are RSA with a modulus of at least 3072 bits.

### 13.5 Verification by an application

1. Parse the block; if any field of §13.2 is missing, the script is Invalid.
2. `schema_version` is `1.0`.
3. Compute the hash of §13.3 and compare with `script_hash` (case-insensitive).
4. Look up `signature_key_id` in the application's trusted key list. Unknown key:
   not verified.
5. Verify the signature of §13.4 with that public key.
6. `timestamp` parses and is not in the future.
7. All steps pass: the script is Iranux Verified.

### 13.6 Trust anchors (to be created by the owner)

- Key ids follow `iranux-YYYY-NN` (year of creation and a sequence number).
- Public keys are published in the standard repository under `keys/<key-id>.pem`
  (PEM `SubjectPublicKeyInfo`) together with their SHA-256 fingerprints in
  `keys/README.md`, and are embedded in Iranux application releases. The private key
  stays offline with the Validator operator; a hardware token is recommended.
- A compromised or retired key is listed as revoked in `keys/README.md` with a date;
  applications stop trusting it and scripts signed with it return to Compatible.
- Nothing in this document is a key. Any `signature_key_id` in a sample or fixture
  is illustrative and MUST NOT be trusted.

## 14. Validation outcomes

A v1.2 script is **Invalid** (R) when any of the following holds: more than one
metadata or certification block; wrong `standard.name` or an unknown
`schema_version`; a missing or malformed required field of §5; a parameter with an
invalid name, duplicate name, unknown type, missing options for `enum`/`multi_select`,
option without label or value, invalid `level`, invalid or incompatible `generate`, or
an advanced required parameter without default or generate; an invalid language key,
or an `i18n` script entry with neither name nor description; `estimated_minutes` out
of range; a certification block missing a field; no final-marker `echo`.

A v1.2 script **cannot be certified** (V) when any V rule of this document fails.
Warnings (W) are listed in the Validator report and do not block certification,
except under the Catalog profile (§16).

## 15. Versioning policy

- Fields are only added, never redefined, within the 1.x line.
- A runner that knows v1.2 parses v1.0 and v1.1 documents by their own rules and
  never injects v1.2 fields into them.
- The web catalog lists schema 1.1 and later; the desktop app also lists 1.0.
- A future version that removes or redefines a field is 2.0 and uses a new
  `standard.name` or a new marker if the execution contract changes.

## 16. Catalog profile

A catalog such as `Iranux-Master/Just-Bash` applies these rules on top of the
standard. The Validator runs them with `--profile catalog`; each is an error there.

| # | Rule |
|---|---|
| 16.1 | `schema_version` is `1.2`. |
| 16.2 | `script.i18n.fa.name` and `script.i18n.fa.description` are present. |
| 16.3 | every basic parameter has `i18n.fa.label` and `i18n.fa.description`; every advanced parameter has `i18n.fa.label`. |
| 16.4 | every `IRANUX_RESULT` output in the file has `i18n.fa.label`. |
| 16.5 | `estimated_minutes` is present. |
| 16.6 | `supported_os` is non-empty. |
| 16.7 | `script.id` is unique across the catalog; category and action mappings are consistent (§5.5). |
| 16.8 | file names are `<script-id>.sh`; the status words "(Iranux Compatible)" are not part of the file name or `script.name`. |
| 16.9 | no W rule of §10 (security) is open. |

## 17. Complete minimal example

```bash
#!/usr/bin/env bash

: <<'IRANUX_METADATA'
{
  "standard": { "name": "iranux-script-metadata", "schema_version": "1.2" },
  "script": {
    "id": "show-disk-usage",
    "name": "Show disk usage",
    "version": "1.0.0",
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
  "name": "mount_point",
  "label": "Folder to check",
  "description": "The folder whose disk is reported. Leave the default to check the whole system.",
  "type": "path",
  "required": true,
  "default": "/",
  "level": "advanced",
  "i18n": { "fa": { "label": "پوشه‌ی موردنظر", "description": "پوشه‌ای که فضای دیسک آن گزارش می‌شود. برای کل سیستم مقدار پیش‌فرض را نگه دارید." } }
}
IRANUX_PARAM

set -euo pipefail

MOUNT_POINT="${MOUNT_POINT:-/}"

if [[ ! -d "$MOUNT_POINT" ]]; then
  echo "Folder not found: $MOUNT_POINT" >&2
  exit 64
fi

echo "== Disk usage for $MOUNT_POINT"
df -h -- "$MOUNT_POINT"

used_percent="$(df --output=pcent -- "$MOUNT_POINT" | tail -n 1 | tr -dc '0-9')"

echo "IRANUX_RESULT {\"outputs\":[{\"key\":\"used_percent\",\"label\":\"Used\",\"value\":\"${used_percent}%\",\"type\":\"text\",\"i18n\":{\"fa\":{\"label\":\"استفاده‌شده\"}}}]}"
echo "__IRANUX_REACHED_END_V1__"
exit 0
```

The `used_percent` value contains only digits and `%`, so it needs no JSON
escaping. Values that may contain `"` or `\` use Appendix C.

## Appendix A. Exit codes

See §8.4. The script MUST NOT exit 0 on any failure and MUST NOT print the marker
before a non-zero exit.

## Appendix B. Operating-system identifiers

See §11.1.

## Appendix C. Building the result line in Bash

With `jq` (list it in `required_commands`):

```bash
result="$(jq -nc \
  --arg url "https://${SITE_DOMAIN}/" \
  --arg user "$ADMIN_USERNAME" \
  '{outputs:[
     {key:"site_url",label:"Site address",value:$url,type:"url",i18n:{fa:{label:"آدرس سایت"}}},
     {key:"admin_username",label:"Username",value:$user,type:"copy",i18n:{fa:{label:"نام کاربری"}}}],
    show_generated:["admin_password"]}')"
echo "IRANUX_RESULT ${result}"
```

Without `jq`, escape each value with this function, which handles `\`, `"`, tab,
carriage return and newline (the characters a parameter or hostname can contain;
other control characters are not allowed in values):

```bash
iranux_json_string() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\n'/\\n}"
  printf '"%s"' "$s"
}

echo "IRANUX_RESULT {\"outputs\":[{\"key\":\"site_url\",\"label\":\"Site address\",\"value\":$(iranux_json_string "https://${SITE_DOMAIN}/"),\"type\":\"url\",\"i18n\":{\"fa\":{\"label\":\"آدرس سایت\"}}}]}"
```

## Appendix D. Summary of differences from v1.1

| Topic | v1.1 | v1.2 |
|---|---|---|
| Localized text | none | `i18n` on script, parameters, result outputs |
| Parameter visibility | all shown | `level` basic/advanced |
| Generated values | none | `generate` password/port/uuid |
| Result | out of scope | `IRANUX_RESULT` line |
| Run time | none | `estimated_minutes` |
| Certification block | three-field example that no runner reads | seven fields, hash, signature algorithm, key ids |
| Exit codes | undefined | table of §8.4 |
| Marker | `echo` statement | exact own line, placement rules, static check defined |
| Transport | "out of scope" | uppercase environment variable, `${NAME:-}` |
| `supported_os` | "lowercase stable IDs", `minItems: 1` | `/etc/os-release` `ID`; empty means any |
| Risk level | typical interpretation | decision rule and pattern check |
| `validation` | any object | five defined keys |
| Options | `label`, `value` | plus `description`; value is a scalar |
| Security | sensitive types masked by the app | script obligations (§10) |
| File | — | UTF-8 without BOM, shebang, no bidi controls |
