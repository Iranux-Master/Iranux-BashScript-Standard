# MDI Icon Validation for Iranux v1.1

## Canonical source

Iranux v1.1 uses Pictogrammers Material Design Icons (MDI):

https://pictogrammers.com/library/mdi/

The canonical metadata value is the official icon `name`, without the `mdi-` prefix.

Examples:

```text
dns
server-security
network
firewall
restart
script-text-outline
```

## Validation requirements

For every script declaring schema v1.1, Validator must:

1. confirm that `ui.icon` exists;
2. confirm that `ui.icon.library` equals `mdi`;
3. confirm that `ui.icon.name` is a non-empty string;
4. confirm that the name matches `^[a-z0-9]+(?:-[a-z0-9]+)*$`;
5. confirm that the canonical name exists in the official MDI catalogue loaded by the Validator;
6. apply the configured deprecated-icon policy;
7. report the MDI catalogue version used for validation.

A missing or unknown icon is an error, not a warning.

## Catalogue acquisition

A Validator release should package or securely retrieve an official machine-readable MDI catalogue. The catalogue should contain at least:

- canonical name;
- deprecation state;
- optional aliases;
- source catalogue version.

The Validator must not use fuzzy title matching as proof that an icon exists.

## Recommended selection process

When assigning an icon to a script:

1. identify the primary user-visible action;
2. prefer a specific action icon over a broad category icon;
3. prefer stable, non-deprecated icons;
4. validate the exact canonical name;
5. use the same icon for scripts only when their actions are genuinely similar.

Examples:

| Script purpose | Recommended icon |
|---|---|
| DNS query | `dns` |
| Complete network information | `network` |
| Remote port test | `lan-connect` |
| Server security setup | `server-security` |
| Firewall status | `firewall` |
| Restart service | `restart` |
| View logs | `text-box-search-outline` |
| Install package | `package-variant-closed-plus` |
| Database backup | `database-export` |
| Reboot server | `restart-alert` |

Every recommendation must still be checked against the catalogue used by the Validator.

## Deprecated icons

Recommended strict policy:

- unknown icon: error;
- malformed icon: error;
- deprecated icon with a current replacement: warning during migration, error for newly certified library content;
- deprecated icon without a replacement: warning, subject to release policy.

Aliases may be accepted only when the Validator has an explicit canonicalisation rule. Certification should record the canonical name.

## Runtime fallback

The application should always include a built-in mapping for:

```text
script-text-outline
```

If a validated icon cannot be resolved at runtime because the installed UI icon package is older, unavailable, or inconsistent, Iranux should render `script-text-outline` and record a diagnostic warning.

Runtime fallback rules:

- never display an empty icon area;
- never replace the script title;
- never silently rewrite the Bash metadata;
- never treat fallback rendering as successful metadata validation.

## Version independence

Bash metadata does not contain MDI codepoints, CSS classes, WPF enum names, or library version numbers. These details belong to the Validator and UI adapter.

This keeps scripts portable across webfont, SVG, WPF, and other MDI integrations.

## Example valid icon block

```json
"icon": {
  "library": "mdi",
  "name": "server-security"
}
```

## Invalid examples

Prefix included:

```json
"name": "mdi-server-security"
```

Empty name:

```json
"name": ""
```

Display title instead of canonical name:

```json
"name": "Server Security"
```

Unverified invented name:

```json
"name": "iranux-super-server-action"
```
