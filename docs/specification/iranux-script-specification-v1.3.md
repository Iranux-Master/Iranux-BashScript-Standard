# Iranux Script Specification v1.3

Status: current version. Published 2026-10. Supersedes v1.2 as the version new scripts
that need DNS records should declare. Scripts that declare `1.0`, `1.1` or `1.2` remain
valid under their own specifications.

v1.3 adds one optional feature, the **`dns` block**: a script declares the DNS records it
needs (an address record for its site, a delegation for a DNS tunnel, a DKIM record it
creates while it runs), and the runner creates them in the user's own DNS before or
after the run. The script never receives a DNS account credential.

This document is the delta to v1.2. Every rule of
[`iranux-script-specification-v1.2.md`](iranux-script-specification-v1.2.md) applies to
a v1.3 document unchanged, with its section numbers, except where this document says
otherwise. Section numbers below that already exist in v1.2 (for example §5.7, §8.1)
extend that section; §5.7 is new.

## 0. How to read this document

Requirement words, enforcement levels (**R**, **V**, **W**, **A**) and terms are those of
v1.2 §0. Rule identifiers in square brackets refer to
[`../validator/validator-rules-v1.3.md`](../validator/validator-rules-v1.3.md). The new
rules are in the range `IRX20xx`.

Additional terms:

| Term | Meaning |
|---|---|
| Anchor | The parameter of type `domain` or `hostname` whose value a record is placed under. |
| Zone | The DNS zone that holds the anchor's records: a domain the user registered through the platform, or a zone in one of the user's own DNS hosting accounts. The runner finds it; the script never names it. |
| Record set | All records of one name and one type. |
| DNS host | Where the zone is served: the registrar's DNS, a DNS hosting account the user connected, or somewhere the runner cannot write ("external"). |

## 1. Scope

### 1.1 What v1.3 adds

- The optional `dns` member of `IRANUX_METADATA` (§5.7): up to ten records with a closed
  vocabulary of names and values, written by the runner, never by the script.
- The environment variables `IRANUX_DNS_STATUS` and `IRANUX_DNS_<ID>` (§8.1).
- Records created after a successful run from the script's own `IRANUX_RESULT` outputs
  (§5.7.6), for values only the script can produce, such as a DKIM key.
- A warning for scripts that ask the user for a DNS account token (§10.6).

Nothing else changes. Parameters, the result line, certification and the final marker
are as in v1.2.

## 2. Compatibility statement

- A v1.3 document keeps every v1.2 rule and adds the rules of this document.
- `dns` is defined only for documents that declare `"schema_version": "1.3"`. The
  metadata schemas of v1.0, v1.1 and v1.2 allow no additional properties, so the
  Validator rejects `dns` there `[IRX2001]`. A script that uses `dns` MUST declare `1.3`
  **[V]**. A runner that knows v1.3 SHOULD still read a `dns` member it finds in an
  older document only to report it; it MUST NOT act on it.
- A v1.3 document that has no `dns` member is a v1.2 document in every respect except
  the version string.
- Parameters keep the v1.2 parameter schema; the result line keeps the v1.2 result
  schema. There is no new block type.
- A runner that does not know v1.3 rejects the script (`[IRX1001]`, v1.2 §2). Catalog
  authors therefore publish v1.3 scripts only to runners that read it.

## 5. Metadata (`IRANUX_METADATA`)

The root object has the members of v1.2 §5 plus the optional `dns` (§5.7).

### 5.1 `standard`

| Field | Type | Rule | Level |
|---|---|---|---|
| `schema_version` | string | exactly `1.3` for a v1.3 document | R |

### 5.7 `dns`

#### 5.7.1 Shape

```json
"dns": {
  "records": [
    {
      "id": "site",
      "anchor": "site_domain",
      "name": "{anchor}",
      "type": "A",
      "value": "{server.ipv4}",
      "purpose": "Points the site name at this server.",
      "i18n": { "fa": { "purpose": "نام سایت را به این سرور وصل می‌کند." } }
    },
    {
      "id": "site-v6",
      "anchor": "site_domain",
      "name": "{anchor}",
      "type": "AAAA",
      "value": "{server.ipv6}",
      "when": "server.ipv6",
      "purpose": "Points the site name at this server's IPv6 address.",
      "i18n": { "fa": { "purpose": "نام سایت را به نشانی IPv6 این سرور وصل می‌کند." } }
    }
  ],
  "wait": "authoritative"
}
```

| Field | Type | Rule | Level |
|---|---|---|---|
| `records` | array | 1–10 record objects (§5.7.2) | R |
| `wait` | string | `authoritative` (default): the runner starts the script only after every `before_run` record is answered by all authoritative name servers of the zone (§5.7.7). `none`: the runner writes the records and starts the script at once; the script waits itself. | R |

No other member is defined `[IRX1016]`.

#### 5.7.2 Record fields

| Field | Type | Required | Rule | Level |
|---|---|---|---|---|
| `id` | string | yes | `^[a-z][a-z0-9-]{0,31}$`; unique among the records of the script | R `[IRX2003]` |
| `anchor` | string | yes | the `name` of a declared parameter of type `domain` or `hostname` | R `[IRX2004]` |
| `name` | string | yes | a name template (§5.7.3) | R `[IRX2006]` |
| `type` | string | yes | one of `A`, `AAAA`, `CNAME`, `TXT`, `MX`, `CAA`, `NS` | R |
| `value` | string | yes | a value template allowed for the type (§5.7.4) | R `[IRX2007]` |
| `priority` | integer | for `MX` only | 0–65535; required for `MX`, not allowed for any other type | R `[IRX2009]` |
| `ttl` | integer | no | seconds, 60–86400; default 300 | R |
| `proxy` | string | no | `off` (default). The only value in v1.3: the runner always writes the record "DNS only", never through a CDN proxy. Other values are reserved for a later version. | R `[IRX2010]` |
| `phase` | string | no | `before_run` (default) or `after_run` (§5.7.6) | R |
| `when` | string | no | `server.ipv6`: the record exists only when the server has an IPv6 address | R `[IRX2008]` |
| `optional` | boolean | no | default `false`. When the runner cannot create an optional record, the run continues and the record is listed as missing. | R |
| `exclusive` | boolean | no | default `false`; always `true` for `CNAME` and `NS`. The name holds no record of another type (§5.7.5). | R |
| `purpose` | string | yes | one English sentence, at most 200 characters, that tells the user why the record is needed | R `[IRX2013]` |
| `i18n` | object | no | v1.2 §6; the only key is `purpose` | R |

| # | Cross-field rule | Level |
|---|---|---|
| 5.7.2.1 | The anchor parameter of a record that is not `optional` MUST be `required: true`; otherwise an empty value would leave the record without a name. | R `[IRX2005]` |
| 5.7.2.2 | An `AAAA` record whose value is `{server.ipv6}` MUST carry `"when": "server.ipv6"`; a server without IPv6 would otherwise fail every run. | R `[IRX2008]` |
| 5.7.2.3 | No two records of a script have the same `name` template and `type`. | V `[IRX2012]` |
| 5.7.2.4 | A `CNAME`, `NS` or `exclusive` record shares its `name` template with no other record. | V `[IRX2012]` |

#### 5.7.3 Name templates

A record's name is built from the anchor's value. A template has exactly one of two
forms:

| Form | Template | Example (anchor `t.example.com`) | Meaning |
|---|---|---|---|
| Under the anchor | `{anchor}` or `<label>.….{anchor}` | `{anchor}` → `t.example.com`; `_acme-challenge.{anchor}` → `_acme-challenge.t.example.com` | the anchor itself, or a name below it |
| Beside the anchor | `<label>.….<sibling>.{anchor.parent}` | `{anchor.label}-ns.{anchor.parent}` → `t-ns.example.com` | a name next to the anchor, under the anchor's parent |

- `<label>` is a fixed label: `^[a-z0-9_](?:[a-z0-9_-]{0,61}[a-z0-9])?$`.
- `<sibling>` is a fixed label or a label that contains `{anchor.label}` (the anchor's
  first label) exactly once, with fixed characters `[a-z0-9-]` before or after it:
  `{anchor.label}-ns`, `ns-{anchor.label}`, `ns1`.
- `{anchor.parent}` is the anchor's value without its first label. It is used only as
  the last part of a beside-the-anchor template.
- Nothing else is allowed: no other placeholder, no upper case, no trailing dot, no
  `*` `[IRX2006]`.

Therefore a script can write only the anchor, names below it, and names one label
below the anchor's parent. It cannot write the zone apex unless the user chose the apex
as the anchor, and it cannot reach any other name. The runner shows every rendered name before it
writes anything (§5.7.7).

Rendering rules, checked by the runner when it knows the anchor value and the zone
(errors are reported for the run, before anything is written):

| # | Rule | Level |
|---|---|---|
| 5.7.3.1 | The anchor value is lower-cased; it is ASCII; a label starting `xn--` is refused (internationalized names are a later version). | R at run time `[IRX2021]` |
| 5.7.3.2 | Each rendered label is 1–63 characters and the rendered name at most 253 characters. | R at run time `[IRX2021]` |
| 5.7.3.3 | A beside-the-anchor template needs an anchor below the zone apex, so that `{anchor.parent}` is the zone or inside it. | R at run time `[IRX2022]` |
| 5.7.3.4 | Every rendered name is the zone or ends with `.` followed by the zone. | R at run time `[IRX2022]` |
| 5.7.3.5 | An `NS` record's rendered name is never the zone apex. Delegating the apex would move the whole domain. | R at run time `[IRX2023]` |

#### 5.7.4 Value templates

| Type | Allowed value | Notes |
|---|---|---|
| `A` | exactly `{server.ipv4}` | the public IPv4 address of the server the script runs on |
| `AAAA` | exactly `{server.ipv6}` | with `"when": "server.ipv6"` |
| `CNAME`, `NS` | a name template (§5.7.3) | the target is written as a fully qualified name; for `NS` it is normally the name of an `A` record of the same script (the glue) |
| `MX` | a name template (§5.7.3) | with `priority` |
| `TXT` | fixed text: 1–512 printable ASCII characters (U+0020–U+007E) without `"`, `\` and `{`; or exactly `{output.<key>}` in an `after_run` record (§5.7.6) | the runner splits long text into 255-character strings |
| `CAA` | fixed text matching `^(0\|128) (issue\|issuewild\|iodef) "[\x20\x21\x23-\x7E]{0,255}"$` | for example `0 issue "letsencrypt.org"` |

`{output.<key>}` is allowed only as the whole value of an `after_run` `TXT` record
`[IRX2011]`. The address of any server other than the one the script runs on cannot be
written: a script has no way to point a user's name at a third party.

#### 5.7.5 How the runner applies a record (record-set semantics)

| Type | Effect | Conflict when the name already has… |
|---|---|---|
| `A`, `AAAA` | the record set equals exactly the server's address | a different value of the same type; an `AAAA` (for an `A` record) or an `A` (for an `AAAA` record) that points elsewhere, because clients prefer IPv6 and certificate checks follow it; a `CNAME` |
| `CNAME` | the record set equals exactly the target | any other record |
| `NS` | the record set equals exactly the target | any other record at that name (a delegation hides the parent zone's other data at that name) |
| `TXT` | the value is added to the record set; other values stay | another value starting `v=spf1` when this value starts `v=spf1` (a name has one SPF policy) |
| `MX` | the value and priority are added; other values stay | — |
| `CAA` | the value is added; other values stay | — |

A record whose value is already present needs no change and is never a conflict. A
conflict is never resolved silently: the runner shows it and writes only after the user
explicitly accepts the replacement for that record; without acceptance the run is
refused before it starts **[R, runner behaviour]**.

#### 5.7.6 Records after the run (`after_run`)

- The runner applies an `after_run` record only after a successful run (exit 0 and the
  final marker).
- `{output.<key>}` takes the `value` of the output with that `key` in the run's
  `IRANUX_RESULT` (v1.2 §9). The output MUST NOT be of type `secret`; a DKIM public key
  or a verification token is public data. The value is 1–2048 printable ASCII
  characters without `"` and `\`; anything else fails that record.
- A missing output fails that record. Failing an `after_run` record does not turn a
  successful run into a failure: the runner shows the record as missing, with a way to
  try again.
- The Validator warns when no `IRANUX_RESULT` line in the file names the key
  **[W `[IRX2015]`]**.

#### 5.7.7 What the runner does (normative runner behaviour)

1. **Plan, before the run is accepted.** The runner finds the zone and the DNS host of
   every anchor value, renders the names (§5.7.3) and values, and compares them with the
   records that exist. It shows the user every record it will write, its DNS host and
   every conflict (§5.7.5).
2. **DNS host.** When the zone is hosted where the runner may write (the registrar's DNS
   of a domain the user registered through the platform, or a zone that is active in a
   DNS hosting account the user connected), the runner writes the records itself. When
   it cannot, it shows the records for the user to create by hand, with their exact
   names and values, and waits.
3. **Write.** Records are written "DNS only" (§5.7.2 `proxy`), with the declared TTL,
   before the script starts (`before_run`) or after it succeeded (`after_run`). Writing
   is idempotent: running the same script again with the same anchor and server changes
   nothing.
4. **Wait.** With `"wait": "authoritative"`, the runner starts the script only when every
   authoritative name server of the zone answers each `before_run` record with its value
   (for `NS`, when the parent zone's name servers return the delegation). It does not
   use a recursive resolver, because a cached negative answer would delay the check.
   When the records do not appear in time, the run waits for the user, who can check
   again or start the script without the check.
5. **No credential reaches the server.** The runner never passes a DNS account token,
   key, account or zone identifier, or DNS host name to the script.
6. **Clean-up.** When the server is deleted, or the user removes what the script
   installed, the runner removes the records it wrote, only if they still hold the value
   it wrote. This keeps a released address from answering for the user's name.

Nothing here changes the zone's name servers. Moving a domain to another DNS host is not
part of a script run.

### 5.8 Complete metadata example

```json
{
  "standard": { "name": "iranux-script-metadata", "schema_version": "1.3" },
  "script": {
    "id": "install-dns-tunnel-example",
    "name": "DNS tunnel server (example)",
    "version": "1.0.0",
    "description": "Installs a DNS tunnel server that answers on UDP port 53 for a subdomain and replaces the system DNS stub listener.",
    "estimated_minutes": 4,
    "i18n": { "fa": {
      "name": "سرور تونل DNS (نمونه)",
      "description": "یک سرور تونل DNS نصب می‌کند که برای یک زیردامنه روی پورت UDP ۵۳ پاسخ می‌دهد و شنونده‌ی DNS سیستم را جایگزین می‌کند."
    } }
  },
  "risk": { "level": "dangerous" },
  "requirements": { "requires_root": true, "requires_internet": true, "supported_os": ["ubuntu", "debian"] },
  "ui": {
    "category": { "id": "vpn", "name": "VPN" },
    "action": { "id": "dns-tunnel", "name": "DNS Tunnel" },
    "icon": { "library": "mdi", "name": "dns" }
  },
  "dns": {
    "records": [
      {
        "id": "tunnel-glue",
        "anchor": "tunnel_domain",
        "name": "{anchor.label}-ns.{anchor.parent}",
        "type": "A",
        "value": "{server.ipv4}",
        "purpose": "The address of this server's DNS listener.",
        "i18n": { "fa": { "purpose": "نشانی شنونده‌ی DNS این سرور." } }
      },
      {
        "id": "tunnel-ns",
        "anchor": "tunnel_domain",
        "name": "{anchor}",
        "type": "NS",
        "value": "{anchor.label}-ns.{anchor.parent}",
        "purpose": "Hands the tunnel subdomain to this server.",
        "i18n": { "fa": { "purpose": "زیردامنه‌ی تونل را به این سرور می‌سپارد." } }
      }
    ]
  }
}
```

With `tunnel_domain` = `t.example.com` the runner writes `t-ns.example.com A <IPv4>` and
`t.example.com NS t-ns.example.com.`. More examples are in
`tests/scripts/valid/` and `Samples/v1.3/`.

## 8. Execution contract

### 8.1 Environment

In addition to v1.2 §8.1, the execution layer exports, for a script that has a `dns`
block:

| Variable | Value |
|---|---|
| `IRANUX_DNS_STATUS` | `applied`: the runner wrote the `before_run` records and saw them on the authoritative name servers. `manual`: the user created them by hand and the runner saw them. `unverified`: the records were written or shown, and the user started the script before they were seen. `none`: the runner did not process the `dns` block (for example the desktop runner). |
| `IRANUX_DNS_<ID>` | the rendered name of each `before_run` record that exists, where `<ID>` is the record `id` in upper case with `-` replaced by `_`: `tunnel-ns` → `IRANUX_DNS_TUNNEL_NS=t.example.com` |

A script without a `dns` block receives none of these variables.

| # | Rule | Level |
|---|---|---|
| 8.1.1 | A script MUST read these variables with a default expansion (`"${IRANUX_DNS_STATUS:-none}"`), like parameters (v1.2 §7.3). | W `[IRX1212]` |
| 8.1.2 | A script whose work depends on its records (a certificate request, a DNS listener test) SHOULD, when `IRANUX_DNS_STATUS` is `unverified` or `none`, check the name against the zone's authoritative name servers (`dig +short @<server> <name>`) and retry for a few minutes instead of failing at once, and exit 75 if the name never resolves. It MUST NOT query a recursive resolver once and give up: a negative answer may be cached for up to an hour. | A |
| 8.1.3 | A script MUST NOT create, change or delete DNS records itself through a DNS provider's API. It declares them in `dns`. | A; W `[IRX2014]` (§10.6) |

## 10. Security rules

### 10.6 DNS account credentials

| # | Rule | Level |
|---|---|---|
| 10.6.1 | A script MUST NOT ask for a DNS account token or key (a Cloudflare API token, a deSEC token and so on). A token on the server gives whoever controls the server the user's whole DNS account. Declare the records in `dns` instead. | W `[IRX2014]`: a parameter whose name matches `(cloudflare\|cf\|dns\|desec\|hetzner\|digitalocean\|bunny\|vultr)_?(api_?)?(token\|key)` |
| 10.6.2 | A certificate that needs a DNS-01 challenge (a wildcard certificate) is out of scope for v1.3. A later version may define a narrowly scoped, user-approved credential for it. | — |

## 12. Risk levels

A `dns` block writes to the user's own DNS through the runner, after the user has seen
and accepted every record. It does not by itself raise the script's `risk.level`: the
level still follows what the script does on the server (v1.2 §12.1). A script that
binds UDP or TCP port 53 or replaces the system DNS resolver is `dangerous` as before.

## 14. Validation outcomes

In addition to v1.2 §14, a v1.3 script is **Invalid** (R) when its `dns` member breaks a
rule marked R in §5.7, and a run is refused before anything is written when a run-time
rule of §5.7.3 fails.

## 15. Versioning policy

- The runner that knows v1.3 parses v1.0, v1.1 and v1.2 documents by their own rules.
- Reserved for later versions: `proxy` values other than `off`, the record types `SRV`
  and `HTTPS`, placeholders other than those of §5.7.3 and §5.7.4, and records outside the
  anchor and its parent.

## 16. Catalog profile

v1.2 §16 applies, with these changes:

| # | Rule |
|---|---|
| 16.1 | `schema_version` is `1.2` or `1.3`. |
| 16.10 | every `dns` record has `i18n.fa.purpose` `[IRX1909]`. |

## Appendix E. Summary of differences from v1.2

| Topic | v1.2 | v1.3 |
|---|---|---|
| DNS records | the script description asks the user to create them by hand | declared in `dns`; the runner writes, waits for and removes them |
| Environment | parameters only | plus `IRANUX_DNS_STATUS` and `IRANUX_DNS_<ID>` |
| DNS credentials | not addressed | a script never asks for them (warning `IRX2014`) |
| Catalog profile | schema `1.2` | `1.2` or `1.3`; Persian purpose for every record |
