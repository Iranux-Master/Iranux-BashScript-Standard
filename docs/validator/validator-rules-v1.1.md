# Iranux Validator Rules v1.1

## Validation order

A deterministic Validator should process a candidate script in this order:

1. normalise line endings to LF for parsing;
2. locate Iranux blocks;
3. enforce block-count rules;
4. parse each block as strict JSON;
5. select the metadata schema from `standard.schema_version`;
6. validate metadata JSON Schema;
7. validate each parameter against the parameter schema;
8. apply cross-block semantic rules;
9. validate the runtime final marker;
10. validate MDI icon existence;
11. produce errors and warnings;
12. if verification is requested and no errors exist, compute the hash and generate certification.

## Block-count rules

| Block | Count |
|---|---:|
| `IRANUX_METADATA` | exactly one |
| `IRANUX_PARAM` | zero or more |
| `IRANUX_CERTIFICATION` | at most one |

## Metadata-version rules

- `1.0` is validated with the v1.0 schema and rules.
- `1.1` is validated with `iranux-metadata-v1.1.schema.json` and these rules.
- an unknown schema version is an error unless a future-version compatibility policy explicitly supports it.
- a document declaring `1.1` must not omit `ui`.

## UI rules

For v1.1:

- `ui.category.id`, `ui.category.name`, `ui.action.id`, `ui.action.name`, `ui.icon.library`, and `ui.icon.name` are required;
- IDs must match `^[a-z][a-z0-9-]*$`;
- IDs must not begin with numeric folder prefixes;
- `ui.icon.library` must be `mdi`;
- `ui.icon.name` must match canonical-name syntax;
- the exact icon name must exist in the configured official MDI catalogue.

## Collection-level consistency

When validating a library rather than one file, Validator should also enforce:

- unique `script.id` values;
- one category name per category ID;
- one action name per action ID;
- one category ID per action ID;
- non-empty supported operating-system metadata when the library requires OS filtering.

## MDI catalogue result codes

Suggested deterministic diagnostic codes:

```text
IRX1101  ui object missing
IRX1102  category missing or invalid
IRX1103  action missing or invalid
IRX1104  icon missing
IRX1105  icon library is not mdi
IRX1106  icon name syntax invalid
IRX1107  icon not found in official MDI catalogue
IRX1108  icon deprecated
IRX1109  category mapping conflict
IRX1110  action mapping conflict
```

`IRX1101` through `IRX1107` are errors. `IRX1108` is a warning or error according to the configured release policy. Mapping conflicts are errors during collection validation.

## Parameter semantic rules

- parameter names are unique;
- names match `^[a-z][a-z0-9_]*$`;
- `enum` and `multi_select` include non-empty options;
- option labels are non-empty;
- option values are unique within the parameter;
- default values are compatible with parameter types;
- default enum values exist in options;
- sensitive types are treated as sensitive regardless of an omitted `sensitive` flag.

## Final marker rule

The script must contain the literal successful-path marker:

```bash
echo "__IRANUX_REACHED_END_V1__"
```

A static Validator may confirm marker presence and placement near the intended successful end, but must not claim runtime success from static analysis.

## Certification rule

AI agents and script authors must not create certification. Validator-generated certification covers all certifiable content, including v1.1 UI metadata. Any metadata change invalidates the previous signature.

## Runtime fallback distinction

`script-text-outline` is an application rendering fallback. The Validator must not substitute it for invalid or missing metadata during certification.
