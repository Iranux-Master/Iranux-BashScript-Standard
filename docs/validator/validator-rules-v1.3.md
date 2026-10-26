# Iranux Validator Rules v1.3

This document lists the rules that v1.3 adds to
[`validator-rules-v1.2.md`](validator-rules-v1.2.md). Every v1.2 rule applies to a v1.3
document unchanged, in the same validation order. Levels are those of specification
§0.2: **R** runner error, **V** Validator error, **W** warning, **A** author rule.

## Changes to the validation order

- Step 6 selects the schema set `1.0`, `1.1`, `1.2` or `1.3` (IRX1001). A v1.3 document
  uses `schemas/iranux-metadata-v1.3.schema.json` for its metadata,
  `schemas/iranux-param-v1.3.schema.json` for its parameters and the v1.2 result schema.
- After step 8 (cross-block rules), apply the DNS rules (IRX2001–IRX2016) to the `dns`
  member and IRX2017–IRX2018 to the options of every parameter.
- In step 10 (localization rules), also apply IRX2019.
- The run-time rules (IRX2021–IRX2023) need the anchor's value and the zone. The
  Validator cannot apply them; the runner applies them before it writes anything, and
  reports them in the same form.

## Rule table

### Blocks and JSON

| Id | Level | Check | Message |
|---|---|---|---|
| IRX1001 | R | `standard.schema_version` not in `1.0`, `1.1`, `1.2`, `1.3` | Unsupported schema version `<v>`. |
| IRX2001 | R | a `1.0`, `1.1` or `1.2` document has a `dns` member | `dns` requires schema version 1.3. |

### DNS records (IRX20xx)

The JSON Schema enforces the record shape (required fields, `type`, `ttl`, `proxy`,
`phase`, `when`, the name and value patterns per type, `priority` for MX only, and
`{output.…}` only in an `after_run` TXT record). Those violations are reported with the
schema path under the identifier given below; a member the specification does not define, in `dns` or in a
record, is reported as IRX1016.

| Id | Level | Check | Message |
|---|---|---|---|
| IRX2002 | R | `dns.records` empty or longer than 10 | dns.records must hold 1 to 10 records. |
| IRX2003 | R | a record `id` fails `^[a-z][a-z0-9-]{0,31}$`, is `status`, or two records share an `id` | DNS record id `<id>` is invalid or repeated. |
| IRX2004 | R | `anchor` names no declared parameter, or a parameter whose `type` is not `domain` or `hostname` | DNS record `<id>`: anchor `<name>` must be a domain or hostname parameter. |
| IRX2005 | R | a record without `"optional": true` whose anchor parameter is not `required: true` | DNS record `<id>`: its anchor `<name>` must be required, or the record optional. |
| IRX2006 | R | `name` is not a template of specification §5.7.3 | DNS record `<id>`: name `<name>` is not an allowed template. |
| IRX2007 | R | `value` is not allowed for the record type (§5.7.4) | DNS record `<id>`: value `<value>` is not allowed for type `<type>`. |
| IRX2008 | R | an `AAAA` record without `"when": "server.ipv6"`, or `when` on another type | DNS record `<id>`: an AAAA record needs "when": "server.ipv6", and only AAAA takes when. |
| IRX2009 | R | an `MX` record without `priority`, or `priority` on another type | DNS record `<id>`: priority is required for MX and allowed only there. |
| IRX2010 | R | `proxy` other than `off` | DNS record `<id>`: proxy must be "off" in v1.3. |
| IRX2011 | R | `{output.<key>}` outside the whole value of an `after_run` TXT record | DNS record `<id>`: {output.…} is allowed only as the value of an after_run TXT record. |
| IRX2012 | R | two records with the same `anchor`, `name` template and `type`; a `CNAME`, `NS` or `exclusive` record whose `anchor` and `name` template another record also uses; `"exclusive": false` on a `CNAME` or `NS` record | DNS records `<id>` and `<id>` collide on `<name>`. |
| IRX2013 | R | `purpose` missing, blank, longer than 200 characters, or containing a control character; an `i18n` entry without `purpose` | DNS record `<id>`: purpose must be one plain sentence of up to 200 characters. |
| IRX2014 | W | a parameter whose name matches `(cloudflare\|cf\|dns\|desec\|hetzner\|digitalocean\|bunny\|vultr)_?(api_?)?(token\|key)` (case-insensitive) | Parameter `<name>` asks for a DNS account credential; declare the records in `dns` instead. |
| IRX2015 | W | an `after_run` record's `{output.<key>}` whose key appears in no literal `IRANUX_RESULT` line of the file | DNS record `<id>`: no IRANUX_RESULT line prints output `<key>`. |
| IRX2016 | R | an `NS` record whose `name` is a beside-the-anchor template, whose `value` is its own name or below it, or whose name another record of the same `anchor` uses or lies below | DNS record `<id>`: a delegation is a name under the anchor that holds nothing else. |

### Option labels (IRX2017–IRX2019)

The v1.3 parameter schema enforces the shape of `options[].i18n`; a violation inside it
is reported as IRX2018 with the schema path.

| Id | Level | Check | Message |
|---|---|---|---|
| IRX2017 | R | a `1.0`, `1.1` or `1.2` document has an option with `i18n` | Parameter `<name>`: options[].i18n requires schema version 1.3. |
| IRX2018 | R | an option `i18n` that is empty, has a key that is not a language tag, an entry without a non-blank `label` (up to 80 characters, no control character), or an entry member other than `label` | Parameter `<name>`, option `<value>`: each i18n entry needs a label and nothing else. |
| IRX2019 | W | the script has a `fa` or `fa-XX` entry in `script.i18n` or in any parameter's `i18n`, and an option of an `enum` or `multi_select` parameter has no `i18n.fa.label` | Parameter `<name>`: the script has Persian text but options `<values>` have no i18n.fa.label. |

### Run-time rules (applied by the runner)

| Id | Level | Check | Message |
|---|---|---|---|
| IRX2021 | R (run) | the anchor value is not ASCII after lower-casing or has an `xn--` label; a rendered label is outside 1–63 characters, starts or ends with `-` or starts with `xn--`; or a rendered name is longer than 253 | DNS record `<id>`: `<name>` is not a valid DNS name. |
| IRX2022 | R (run) | a rendered name is neither the zone nor below it, or a beside-the-anchor template is used with the zone apex as anchor | DNS record `<id>`: `<name>` is outside the zone `<zone>`. |
| IRX2023 | R (run) | the rendered name of an `NS`, `CNAME` or `exclusive` record is the zone apex | DNS record `<id>`: this record cannot be at the zone apex. |
| IRX2024 | R (run) | across all records of the run: two with the same rendered name and type, another record at the rendered name of a `CNAME`, `NS` or `exclusive` record, or a record at or below the rendered name of an `NS` record | DNS records `<id>` and `<id>` collide on `<name>`. |

### Catalog profile (errors with `--profile catalog`)

| Id | Check |
|---|---|
| IRX1901 | `schema_version` is not `1.2` or `1.3`. |
| IRX1909 | a `dns` record without `i18n.fa.purpose`. |

## Fixture checker

`tools/check_fixtures.py` adds: the v1.3 metadata schema for `metadata-v1.3-` fixtures
and v1.3 scripts; IRX2001, IRX2003 (duplicate ids), IRX2004, IRX2005, IRX2012, IRX2014,
IRX2015, IRX2016, IRX2017, IRX2019 on scripts, IRX2018 through the v1.3 parameter schema, IRX1016 for undefined members, the schema-enforced IRX20xx rules through the schema, and IRX1909
with `--profile catalog`. Scripts under `tests/scripts/valid/` must pass; each script
under `tests/scripts/invalid/` is named `<rule id>-<what it shows>.sh` and must fail
with that rule only (the catalog profile applies to it only for an `IRX19xx` rule). The
checker does not apply IRX1212 (default expansion), to parameters or to `IRANUX_DNS_*`.
