# Iranux Validator Rules v1.2

This document lists every rule of the v1.2 specification with its identifier, level,
mechanical check and message, in the order a Validator applies them. It is the
reference for the Validator implementation and for `tools/check_fixtures.py`, which
implements the subset marked "fixture checker" for this repository's samples and
fixtures.

Levels: **R** runner error (script Invalid in the Iranux applications), **V**
Validator error (no certification), **W** warning, **A** author rule with a heuristic
only. See specification §0.2.

## Validation order

1. read the file as UTF-8; check BOM, line endings, shebang, bidirectional controls
   (IRX13xx);
2. run `bash -n`; optionally `shellcheck`;
3. locate the blocks with the regular expressions of specification §4.1;
4. enforce block counts (IRX1012, IRX1013);
5. parse each body as strict JSON with duplicate-key detection (IRX1014, IRX1017);
6. read `standard.schema_version`; select the schema set: `1.0`, `1.1` or `1.2`
   (IRX1001);
7. validate the metadata against `schemas/iranux-metadata-v<version>.schema.json`
   and each parameter against the matching parameter schema (IRX1015, IRX1016 and the
   R rules of the specification come out of the schema);
8. apply the cross-block rules (IRX12xx);
9. apply the UI and icon rules (IRX1101–IRX1110);
10. apply the localization rules (IRX14xx);
11. apply the execution-contract rules on the Bash text (IRX1220–IRX1233, IRX17xx);
12. apply the security rules (IRX16xx) and the risk check (IRX15xx);
13. apply the result rules on `IRANUX_RESULT` lines found in the file (IRX18xx);
14. with `--profile catalog`, apply IRX19xx and the collection rules;
15. report errors and warnings; when verification was requested and no R or V error
    exists, compute the hash, sign and append the certification block (specification
    §13).

Each report line has the form `IRXnnnn <level> <location> <message>`; `<location>` is
`metadata`, `param:<name>`, `line <n>` or `file`.

## Rule table

### File (IRX13xx)

| Id | Level | Check | Message |
|---|---|---|---|
| IRX1301 | V | file starts with EF BB BF | File starts with a byte-order mark; save as UTF-8 without BOM. |
| IRX1302 | W | any `\r\n` in the file | File uses CRLF line endings; use LF. |
| IRX1303 | V | first line is not `#!/usr/bin/env bash` or `#!/bin/bash` | First line must be a Bash shebang. |
| IRX1304 | V | `bash -n file` exits non-zero | Bash syntax error: `<bash output>`. |
| IRX1305 | V | any code point in U+202A–U+202E or U+2066–U+2069 | Bidirectional control character at line `<n>`; remove it. |
| IRX1306 | W | `shellcheck -S error` reports a finding | shellcheck error `<code>` at line `<n>`. |

### Blocks and JSON (IRX10xx)

| Id | Level | Check | Message |
|---|---|---|---|
| IRX1001 | R | `standard.schema_version` not in `1.0`, `1.1`, `1.2` | Unsupported schema version `<v>`. |
| IRX1002 | V | a `1.0` or `1.1` document uses `i18n`, `estimated_minutes`, `level`, `generate`, or the file prints `IRANUX_RESULT` | `<field>` requires schema version 1.2. |
| IRX1011 | W | an opening block line has leading whitespace | Iranux block at line `<n>` is indented; put blocks at the top level. |
| IRX1012 | R | more than one metadata block | Multiple IRANUX_METADATA blocks were found. Keep exactly one metadata block. |
| IRX1013 | R | more than one certification block | Multiple IRANUX_CERTIFICATION blocks were found. Keep at most one certification block. |
| IRX1014 | V | a body is not strict JSON (the runner then treats the metadata as absent or skips the parameter) | Block at line `<n>` is not valid JSON: `<reason>`. |
| IRX1015 | V | a key differs from its defined spelling only by case | Key `<key>` must be written `<expected>`. |
| IRX1016 | V | a key is not defined for its object (schema `additionalProperties: false`) | Unknown key `<path>`. |
| IRX1017 | V | an object repeats a key | Duplicate key `<path>`. |
| IRX1018 | V | a string contains a control character other than U+0009/U+000A, or a character of IRX1305 | Invalid character in `<path>`. |

### Metadata and parameters (IRX12xx)

Rules the JSON Schemas already enforce (patterns, enums, required fields, `generate`
compatibility, advanced-required-needs-default) are not repeated here; the schema
message is reported with the schema path.

| Id | Level | Check | Message |
|---|---|---|---|
| IRX1201 | V | `script.id` length outside 3–64 | script.id must be 3 to 64 characters. |
| IRX1202 | V (collection) | two files share `script.id` | Duplicate script.id `<id>` in `<file>` and `<file>`. |
| IRX1203 | V | `script.name` longer than 80 characters or containing `Iranux Compatible`, `Iranux Ready`, `Iranux Verified`, `(Iranux` | script.name must not carry a status word; status is not metadata. |
| IRX1204 | V | `script.description` longer than 500 characters | script.description is longer than 500 characters. |
| IRX1205 | V | parameter `name` longer than 64 | Parameter name `<name>` is longer than 64 characters. |
| IRX1206 | V | parameter without `type` | Parameter `<name>` has no type (the runner would assume string). |
| IRX1207 | V | parameter without `required` | Parameter `<name>` has no required flag (the runner would assume false). |
| IRX1208 | V | `default` not compatible with `type` (specification §7.4) | Parameter `<name>` default `<value>` is not a valid `<type>`. |
| IRX1209 | V | a sensitive parameter has `default`, or `example`/`placeholder` longer than 3 characters that is not a placeholder word such as `********` | Sensitive parameter `<name>` must not carry a default or example value. |
| IRX1210 | V | a `validation` key other than `min_length`, `max_length`, `min_value`, `max_value`, `pattern` | Unknown validation key `<key>` in parameter `<name>`. |
| IRX1211 | V | the token `NAME` (upper case of the parameter name) does not occur as `$NAME`, `${NAME`, or as a word in the script after the parameter block | Parameter `<name>` is declared but `<NAME>` is never read. |
| IRX1212 | W | `$NAME` or `${NAME}` occurs before any `${NAME:-` or `${NAME-` and the script has `set -u` | `<NAME>` is used without a default before it is assigned; use `${NAME:-}`. |
| IRX1213 | W | the first `${NAME:-X}` has `X` different from the declared default's text form (missing default means empty `X`) | Bash fallback for `<NAME>` is `<X>` but the declared default is `<default>`. |
| IRX1214 | W | a non-sensitive parameter whose name contains `password`, `passwd`, `passphrase`, `secret`, `token`, `api_key`, `apikey`, `private_key`, `credential` | Parameter `<name>` looks like a secret but is not sensitive. |
| IRX1215 | V | duplicate `options[].value` | Parameter `<name>` has duplicate option value `<value>`. |
| IRX1216 | V | an option value contains `,` or a line break | Option value `<value>` of `<name>` must not contain a comma or line break. |
| IRX1217 | W | `validation.pattern` on a type with a built-in format (`port`, `email`, `url`, `domain`, `hostname`, `ip*`, `cidr`, `mac`, `date`, `time`, `datetime`, `cron`) | Parameter `<name>` repeats the `<type>` check with a pattern. |
| IRX1218 | W | more than eight parameters without `"level": "advanced"` | `<n>` basic parameters; move tuning values to advanced. |
| IRX1219 | W | `generate` together with `default` | Parameter `<name>` has both generate and default; the default is never used. |
| IRX1220 | V | a `read` builtin whose simple command has no `<`, `<<<`, `<<` and is not inside a pipeline (`\| … read`), or `read -p`, or `select … in` | Line `<n>` waits for terminal input; declare the value as a parameter. |
| IRX1221 | V | `requires_root` is false (or absent) and the script contains `id -u`/`$EUID` compared with 0, or a command from the privileged list (`apt-get install`, `dnf install`, `yum install`, `pacman -S`, `zypper install`, `systemctl enable/start/restart/stop`, `useradd`, `ufw`, `iptables`, `nft`, writes under `/etc/`) outside a `sudo -n` call | requirements.requires_root must be true: line `<n>` needs root. |
| IRX1222 | W | `requires_internet` is false and the script contains `curl`, `wget`, `apt-get update/install`, `dnf/yum install`, `pip install`, `git clone`, `npm install` | requirements.requires_internet should be true: line `<n>` uses the network. |
| IRX1223 | W | `supported_os` absent or empty | supported_os is empty; the script is offered on every operating system. |
| IRX1224 | W | `apt-get install` / `apt install` without `-y`; `dnf`/`yum install` without `-y`; `pacman -S` without `--noconfirm`; `zypper install` without `-n`/`--non-interactive`/`-y` | Line `<n>`: package command may prompt; add the non-interactive flag. |
| IRX1225 | W | `clear` or `tput` as a command | Line `<n>`: `clear`/`tput` has no effect in the web log; remove it. |
| IRX1226 | W | `sudo` without `-n` | Line `<n>`: sudo without -n may prompt for a password. |
| IRX1227 | W | a literal `exit <n>` with `<n>` not in {0, 1, 64, 65, 69, 70, 73, 75, 77, 78} and below 126 | Line `<n>`: exit code `<n>` is outside the standard table. |
| IRX1228 | V | a literal `exit <n>` with `<n>` in {126, 127} or ≥ 128 | Line `<n>`: exit code `<n>` is reserved by Bash. |
| IRX1229 | W | a `supported_os` item outside the table of specification §11.1 | OS identifier `<id>` is not a known /etc/os-release ID. |
| IRX1230 | W | a `case` on an OS-id variable (`$ID`, `$release`, `$OS_ID`, `$os`) whose `*)` branch runs a package manager | Line `<n>`: unsupported systems fall through to a package manager; exit 78 instead. |
| IRX1231 | V | an `echo`/`printf` line that contains `__IRANUX_REACHED_END_V1__` and any other non-whitespace text inside the quoted argument | Line `<n>`: the final marker must be alone on its line. |
| IRX1232 | W | a marker `echo` followed within three lines by `exit <n>` with `<n>` ≠ 0 | Line `<n>`: the final marker is printed on a failure path. |
| IRX1233 | V | `__IRANUX_REACHED_END_V1__` occurs outside an `echo`/`printf` statement (comment, string, heredoc) | Line `<n>`: the final marker may only be printed by echo. |

### UI and icon (IRX11xx, kept from v1.1)

| Id | Level | Check | Message |
|---|---|---|---|
| IRX1101 | R | `ui` missing | Missing required 'ui' object. |
| IRX1102 | R | category missing or id/name invalid | ui.category is missing or invalid. |
| IRX1103 | R | action missing or id/name invalid | ui.action is missing or invalid. |
| IRX1104 | R | icon missing | ui.icon is missing. |
| IRX1105 | R | `icon.library` ≠ `mdi` | ui.icon.library must be 'mdi'. |
| IRX1106 | R | `icon.name` fails `^[a-z0-9]+(?:-[a-z0-9]+)*$` | ui.icon.name syntax is invalid. |
| IRX1107 | V | `icon.name` not in the MDI catalogue the Validator loaded (the Validator records the catalogue version) | Icon `<name>` is not in Material Design Icons `<version>`. |
| IRX1108 | W | icon deprecated in the catalogue | Icon `<name>` is deprecated; use `<replacement>`. |
| IRX1109 | V (collection) | one category id with two names, in the collection | Category `<id>` has conflicting names. |
| IRX1110 | V (collection) | one action id with two names or two categories | Action `<id>` has a conflicting mapping. |

### Localization (IRX14xx)

| Id | Level | Check | Message |
|---|---|---|---|
| IRX1401 | W | a language key with a region (`fa-IR`) when no plain `fa` exists | Use the base language `fa`. |
| IRX1402 | V | an `i18n` value contains `<`, `>`, `\n`, `\x1b`, or Markdown emphasis markers `**`, `` ` `` | Localized text `<path>` must be plain text. |
| IRX1403 | W | a `fa` value contains U+064A or U+0643 | Persian text `<path>` uses Arabic ي/ك; use ی/ک. |
| IRX1404 | W | a label (`label` or `i18n.*.label`, `script.name`, `i18n.*.name`) longer than 60 characters | Label `<path>` is longer than 60 characters. |

### Risk (IRX15xx)

| Id | Level | Check | Message |
|---|---|---|---|
| IRX1501 | W | a pattern of the table below implies a level higher than `risk.level` | risk.level `<declared>` is lower than `<implied>` implied by line `<n>` (`<pattern>`). |
| IRX1502 | W | `high` or `dangerous` and the description contains none of: `firewall`, `ssh`, `dns`, `user`, `permission`, `network`, `delete`, `remove`, `format`, `reset`, `disable`, `port`, `password`, `zone`, `record`, `kernel`, `reinstall` | Describe what a `<level>` script changes in script.description. |

#### Risk patterns

The Validator scans command lines (comments excluded). A match sets the minimum
level; the highest minimum is the implied level.

| Implied minimum | Pattern (extended regex on a command line) |
|---|---|
| dangerous | `\brm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)\b` on a path that is not under `/tmp`, `$TMP`, `$(mktemp` or a directory the script created with `mkdir` earlier |
| dangerous | `\bmkfs(\.|\b)`, `\bdd\s+.*\bof=/dev/`, `\bwipefs\b`, `\bparted\b`, `\bfdisk\b` |
| dangerous | `\bufw\s+(--force\s+)?reset\b`, `\biptables\s+(-F|--flush)\b`(no chain), `\bnft\s+flush\s+ruleset\b` |
| dangerous | `\buserdel\b`, `\bgroupdel\b` |
| dangerous | `sshd_config` together with `Port\b`, `PasswordAuthentication`, `PermitRootLogin`, `AllowUsers`, `PubkeyAuthentication` |
| dangerous | listens on or replaces port 53 (`:53\b`, `port\s*=?\s*53\b`, `systemd-resolved` stop/disable), `/etc/resolv.conf` rewrite with `>`/`tee` |
| dangerous | `\bgrub\b`, `update-grub`, `/boot/`, `\bmodprobe\s+-r\b`, `\brmmod\b` |
| high | `sshd_config` (any other edit), `systemctl\s+(restart|reload)\s+(ssh|sshd)\b` |
| high | `\bufw\b`, `\biptables\b`, `\bnft\b`, `\bfirewall-cmd\b` (other than `ufw allow <port>` for a port the script installs) |
| high | `\buseradd\b`, `\badduser\b`, `\busermod\b`, `\bpasswd\b`, `\bchpasswd\b`, `/etc/sudoers`, `\bvisudo\b` |
| high | `\bchmod\s+(-R\s+)?[0-7]*777\b`, `\bchown\s+-R\b` on a path outside `/opt/`, `/var/www/`, `/srv/`, `/home/`, `/usr/local/<app>` |
| high | `\bsysctl\s+-w\b`, `/etc/sysctl`, `\bip\s+(link|addr|route)\s+(add|del|set)\b`, `/etc/netplan`, `/etc/network/interfaces`, `/etc/hosts` rewrite, `\bhostnamectl\b` |
| high | `/etc/cron`, `\bcrontab\b` writes, `/etc/systemd/system/*.timer` |
| high | HTTP methods other than GET to an external API: `curl` with `-X\s*(POST|PUT|PATCH|DELETE)` or `--data`/`-d` to a host that is not localhost |
| medium | `apt-get\s+install`, `apt\s+install`, `dnf\s+install`, `yum\s+install`, `pacman\s+-S`, `zypper\s+install`, `pip3?\s+install`, `npm\s+install\s+-g`, `snap\s+install`, `curl .* \| (ba)?sh` |
| medium | `systemctl\s+(enable|start|restart|reload|daemon-reload)`, writes under `/etc/` (`>`, `tee`, `sed -i`, `cp` to `/etc/`), `/etc/systemd/system/*.service` |
| medium | `\bcertbot\b`, `\bacme\.sh\b`, `openssl req` |
| low | writes (`>`, `>>`, `tee`, `cp`, `mv`, `mkdir`, `tar x`) under `/opt/`, `/var/www/`, `/srv/`, `/home/`, `/var/backups/`, `/var/log/` |
| low | `systemctl\s+(restart|reload)` of a service the script does not install |
| safe | none of the above |

### Security (IRX16xx)

For these rules a "sensitive variable" is the upper-case name of a parameter whose
type is `password`, `secret` or `private_key`, or that has `"sensitive": true`, and
any variable assigned directly from one (`X="$SECRET"`, `X="${SECRET:-}"`).

| Id | Level | Check | Message |
|---|---|---|---|
| IRX1601 | V | an `echo`, `printf`, `cat <<` heredoc to stdout, `logger`, or `tee` to stdout whose text contains `$VAR`/`${VAR` of a sensitive variable | Line `<n>` prints the sensitive value `<VAR>`. |
| IRX1602 | V | an unquoted `$NAME`/`${NAME…}` of any parameter variable outside `[[ ]]`, arithmetic `(( ))`, a `case` word, or an assignment right-hand side | Line `<n>`: `<NAME>` is expanded without quotes. |
| IRX1603 | V | `set -x`, `set -o xtrace`, `bash -x` or `#!/bin/bash -x` | Line `<n>`: xtrace prints parameter values. |
| IRX1604 | W | a sensitive variable appears as an argument of an external command other than a redirection or `printf`/`echo` piped into the command | Line `<n>`: `<VAR>` is passed on a command line; use stdin or a 0600 file. |
| IRX1605 | W | a redirection or heredoc containing a sensitive variable targets a file, and no `umask 0?77`, `install -m 6?00`, `chmod 6?00` or `chmod 6?40` applies to that path earlier in the file | Line `<n>`: secret written to `<path>` without restricting its mode. |
| IRX1606 | V | `eval`, `bash -c`, `sh -c`, `source`/`.` with a parameter variable in the argument, or a parameter variable in command position | Line `<n>`: parameter `<NAME>` is executed as code. |
| IRX1607 | W | a parameter variable inside a `sed`/`awk`/`jq`/`mysql -e`/`psql -c` program argument | Line `<n>`: pass `<NAME>` as data (`--arg`, `-v`), not inside the program text. |
| IRX1608 | W | `rm -rf` whose path contains a parameter variable without a preceding `[[ -n "$VAR" && "$VAR" == /* ]]`-style check | Line `<n>`: `rm -rf` with a parameter path; check it is absolute and non-empty first. |
| IRX1611 | V | `--no-check-certificate`, `-k`, `--insecure`, `http://` download URL, `GIT_SSL_NO_VERIFY`, `PYTHONHTTPSVERIFY=0` | Line `<n>` disables TLS verification or downloads over plain HTTP. |
| IRX1612 | W | `curl`/`wget` output piped to `bash`/`sh`/`python`, or `bash <(curl` | Line `<n>` executes downloaded text directly; download, check, then run. |
| IRX1613 | W | `tar`/`unzip` extracting with `-C /`, `-C /usr`, `-C /usr/local`, `-C /etc`, or in a `cd /usr/local` context | Line `<n>` extracts an archive into a system directory. |
| IRX1621 | W | no `set -e` (or `set -euo pipefail`) before the first command after the Iranux blocks | No strict mode; new scripts should use `set -euo pipefail`. |
| IRX1622 | W | a fixed path under `/tmp/` that is created or written (not `mktemp`) | Line `<n>` uses a predictable temporary path; use mktemp. |

### Idempotency (IRX17xx)

| Id | Level | Check | Message |
|---|---|---|---|
| IRX1701 | W | `>>` (or `tee -a`) to a file under `/etc/` without an earlier `grep -q`/`grep -F` on the same path | Line `<n>` appends to `<file>` on every run. |
| IRX1702 | W | `mkdir` without `-p` | Line `<n>`: mkdir without -p fails on the second run. |
| IRX1703 | W | `useradd`/`adduser` without an earlier `id <user>` or `getent passwd` check | Line `<n>`: useradd fails when the user exists. |
| IRX1704 | W | `ln -s` without `-f` or `-n` | Line `<n>`: ln -s fails when the link exists. |

### Result (IRX18xx)

The Validator extracts every `IRANUX_RESULT` occurrence from `echo`/`printf` lines.
When the JSON is a literal (no `$` expansions inside the braces other than inside
`value` strings) it is validated against `schemas/iranux-result-v1.2.schema.json`.

| Id | Level | Check | Message |
|---|---|---|---|
| IRX1801 | W | an output `key` fails `^[a-z][a-z0-9_]*$` | Result key `<key>` should be snake_case. |
| IRX1802 | W | more than one `IRANUX_RESULT` echo in the file (the last before the marker wins at run time) | `<n>` IRANUX_RESULT lines; print one, immediately before the marker. |
| IRX1803 | V | a sensitive variable appears in an `IRANUX_RESULT` line | Line `<n>`: sensitive value `<VAR>` in IRANUX_RESULT; use show_generated or a root-only file. |

### Catalog profile (IRX19xx, errors with `--profile catalog`)

| Id | Check |
|---|---|
| IRX1901 | `schema_version` is not `1.2`. |
| IRX1902 | `script.i18n.fa.name` or `script.i18n.fa.description` missing. |
| IRX1903 | a basic parameter without `i18n.fa.label` and `i18n.fa.description`, or an advanced parameter without `i18n.fa.label`. |
| IRX1904 | an `IRANUX_RESULT` output without `i18n.fa.label`. |
| IRX1905 | `estimated_minutes` missing. |
| IRX1906 | `supported_os` empty. |
| IRX1907 | file name is not `<script.id>.sh`, or `script.name` or the file name contains a status word (IRX1203). |
| IRX1908 | any open IRX16xx warning. |
| plus | IRX1202, IRX1109, IRX1110 across the collection. |

## Certification rules

- Certification is produced only when no R or V finding exists.
- The certifiable content and hash are those of specification §13.3; the signed
  string and algorithm those of §13.4.
- The Validator records the MDI catalogue version and its own version in the
  report; only `validator_version` goes into the block.
- An existing `IRANUX_CERTIFICATION` block in the input is removed before
  validation and reported as `IRX1013`-adjacent information: "Existing certification
  removed; the file will be re-certified."
- A script author or AI tool that writes a certification block produces a block that
  never verifies (wrong hash or unknown key); the Validator reports it and replaces it.

## Fixture checker

`tools/check_fixtures.py` in this repository implements: schema validation of every
fixture and of the blocks in every sample; block extraction with the runner's
regular expressions; IRX1012, IRX1013, IRX1014, IRX1017, IRX1211, IRX1301, IRX1303,
IRX1305, IRX1403, IRX1601, IRX1602 (parameter variables only), IRX1603, IRX1611,
IRX1231, the marker presence check, and IRX1107 when an MDI name list is supplied.
It is a test aid for this repository, not the Validator.
