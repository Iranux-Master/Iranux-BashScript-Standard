# Iranux Bash Script Standard v1.1 Specification

## 1. Status and scope

Version 1.1 is a backward-compatible metadata extension to Iranux Bash Script Standard v1.0. It adds machine-readable UI library placement and icon selection without changing Bash execution semantics, parameter transport, certification hashing, or the runtime end marker.

A script declares v1.1 with:

```json
{
  "standard": {
    "name": "iranux-script-metadata",
    "schema_version": "1.1"
  }
}
```

A document declaring v1.1 must satisfy this specification. A document declaring v1.0 remains governed by the v1.0 rules.

## 2. Design constraints

The standard remains a descriptive metadata standard. It does not define SSH transport, remote file transfer, stdin framing, environment-variable injection, command-line arguments, output streaming, shell quoting, privilege escalation, rollback, or workflow execution.

All Iranux JSON blocks must contain strict JSON.

## 3. Bash block syntax

A Compatible v1.1 script contains:

- exactly one `IRANUX_METADATA` block;
- zero or more `IRANUX_PARAM` blocks;
- at most one validator-generated `IRANUX_CERTIFICATION` block;
- the final marker `__IRANUX_REACHED_END_V1__` on the successful normal path.

Blocks use quoted Bash heredoc no-op syntax:

```bash
: <<'IRANUX_METADATA'
{ "strict": "json" }
IRANUX_METADATA
```

## 4. Required metadata

The metadata root must contain:

- `standard`
- `script`
- `risk`
- `ui`

`requirements` is optional.

### 4.1 Standard

```json
"standard": {
  "name": "iranux-script-metadata",
  "schema_version": "1.1"
}
```

No alternative values are valid for a v1.1 document.

### 4.2 Script

```json
"script": {
  "id": "test-remote-port",
  "name": "Test Remote Port",
  "version": "1.0.0",
  "description": "Tests whether a TCP port is reachable on a remote host."
}
```

`script.id` must match:

```regex
^[a-z][a-z0-9-]*$
```

`script.version` must use semantic-version form.

### 4.3 Risk

```json
"risk": {
  "level": "safe"
}
```

Allowed values are `safe`, `low`, `medium`, `high`, and `dangerous`.

### 4.4 Requirements

```json
"requirements": {
  "requires_root": false,
  "requires_internet": true,
  "supported_os": ["ubuntu", "debian"],
  "required_commands": ["nc"]
}
```

Operating-system identifiers should be lowercase stable IDs. Folder names and numeric sort prefixes must not be used as OS identifiers.

## 5. UI metadata extension

The v1.1 `ui` object is required and has exactly three members:

```json
"ui": {
  "category": {
    "id": "network",
    "name": "Network and IP"
  },
  "action": {
    "id": "network-diagnostics",
    "name": "Network Diagnostics"
  },
  "icon": {
    "library": "mdi",
    "name": "lan-connect"
  }
}
```

### 5.1 Category

Category is the primary functional grouping shown after operating-system filtering.

Both `category.id` and `category.name` are required. The ID must match:

```regex
^[a-z][a-z0-9-]*$
```

The ID must not contain folder numbering such as `04-network`. Use `network`.

### 5.2 Action

Action is the secondary functional grouping inside a category. It identifies the set of script buttons presented together.

Both `action.id` and `action.name` are required. The same identifier pattern applies.

For a script collection, an action ID must map consistently to one category ID and one action name.

### 5.3 Icon

Every v1.1 script must declare an icon:

```json
"icon": {
  "library": "mdi",
  "name": "dns"
}
```

Requirements:

- `library` is exactly `mdi`;
- `name` is the canonical Pictogrammers MDI name without an `mdi-` prefix;
- `name` matches `^[a-z0-9]+(?:-[a-z0-9]+)*$`;
- the validator confirms the canonical name exists in its approved official MDI catalogue;
- missing, empty, malformed, deprecated-without-policy, or unknown names are validation errors.

The application must not derive an icon from the script title when valid v1.1 icon metadata exists.

`script-text-outline` is the required application-level defensive fallback when a previously validated icon cannot be resolved at runtime. This fallback does not allow a validator to accept missing or unknown icon metadata.

## 6. Icon catalogue policy

The canonical source is Pictogrammers Material Design Icons:

https://pictogrammers.com/library/mdi/

A validator implementation must record or expose the MDI catalogue version used for validation. The version is validator state and is not repeated in every Bash script.

A script remains syntactically valid after an MDI update. Revalidation may warn when an icon becomes deprecated. A removed or unknown icon fails strict v1.1 validation unless the validator maintains an explicit compatibility alias policy.

## 7. Parameter blocks

Each parameter is represented by one `IRANUX_PARAM` block. Required fields are `name`, `label`, `description`, `type`, and `required`.

The parameter name must match:

```regex
^[a-z][a-z0-9_]*$
```

Parameter names must be unique inside a script.

Optional fields are `default`, `example`, `placeholder`, `group`, `sensitive`, `options`, and `validation`.

The supported type list remains unchanged from v1.0.

## 8. Non-interactive compatibility

A Compatible script should not require terminal prompts in the normal Iranux execution path. Declared values are read from variables populated by the execution layer:

```bash
DOMAIN="${DOMAIN:-example.com}"
```

How the execution layer supplies the variable is intentionally out of scope.

## 9. Final marker

The successful normal path must print:

```bash
echo "__IRANUX_REACHED_END_V1__"
```

The marker version remains V1. Metadata schema v1.1 does not require a new marker because marker semantics have not changed.

## 10. Certification

Certification is generated only by the official deterministic Iranux Validator. Certifiable content remains the complete Bash file after removing the `IRANUX_CERTIFICATION` block and normalising line endings to LF.

Changing category, action, icon, or any other file content invalidates an existing certification and requires revalidation and resigning.

## 11. Validation outcomes

A v1.1 metadata document fails validation when any of the following applies:

- `ui` is missing;
- category, action, or icon is missing;
- category or action ID is malformed;
- icon library is not `mdi`;
- icon name is empty, malformed, or absent from the official catalogue used by the validator;
- required v1.0 metadata is missing;
- JSON is invalid;
- block count rules are violated;
- the successful final marker is absent.

## 12. Backward compatibility

An application supporting v1.1 should also support v1.0 when required by product policy. It must parse each version against the matching schema and must not silently inject v1.1 fields into signed v1.0 scripts.

Migration from v1.0 to v1.1 consists of:

1. changing `standard.schema_version` to `1.1`;
2. adding a complete `ui` object;
3. choosing and validating a canonical MDI icon;
4. validating the full script;
5. removing stale certification and requesting new certification.

## 13. Complete metadata example

```json
{
  "standard": {
    "name": "iranux-script-metadata",
    "schema_version": "1.1"
  },
  "script": {
    "id": "dns-query",
    "name": "DNS Query",
    "version": "1.0.0",
    "description": "Queries a DNS record using a selected resolver."
  },
  "risk": {
    "level": "safe"
  },
  "requirements": {
    "requires_root": false,
    "requires_internet": true,
    "supported_os": ["ubuntu", "debian"],
    "required_commands": ["dig"]
  },
  "ui": {
    "category": {
      "id": "network",
      "name": "Network and IP"
    },
    "action": {
      "id": "dns-tools",
      "name": "DNS Tools"
    },
    "icon": {
      "library": "mdi",
      "name": "dns"
    }
  }
}
```
