# Iranux v1.1 UI Metadata Implementation Guide

## Purpose

The v1.1 UI metadata extension lets Iranux organise locally stored Bash scripts and generate a predictable library interface before any SSH execution occurs.

The intended discovery hierarchy is:

```text
Supported operating system
└── Category
    └── Action
        └── Script button: icon + script name
```

## Required metadata

Every script declaring `schema_version: "1.1"` contains:

```json
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
```

## Discovery sequence

A conforming application should:

1. locate Bash files in its script library;
2. detect exactly one `IRANUX_METADATA` block;
3. parse strict JSON;
4. select the matching schema from `standard.schema_version`;
5. reject invalid v1.1 metadata;
6. compare `requirements.supported_os` with the connected server;
7. group compatible scripts by `ui.category.id`;
8. group each category by `ui.action.id`;
9. display each script as a button using `script.name` and `ui.icon.name`;
10. show full metadata and parameter forms before execution.

## Stable IDs versus display names

IDs are stable machine keys. Names are human-readable labels.

Use IDs for grouping, persistence, search indexes, localisation keys, and compatibility checks. Use names for display.

Correct:

```json
{
  "id": "software-installation",
  "name": "Software Installation"
}
```

Incorrect:

```json
{
  "id": "19-software-installation",
  "name": "19 - Software Installation"
}
```

Folder names may retain numeric sort prefixes, but those prefixes are not metadata.

## Consistency rules across a script collection

Within one library release:

- one category ID maps to one category name;
- one action ID maps to one action name;
- one action ID belongs to one category ID;
- script IDs are globally unique;
- icon names are validated independently for every script.

A library validator should report conflicting mappings, for example two scripts using category ID `network` with different names.

## MDI resolution

The metadata stores the canonical icon name only:

```text
dns
server-security
lan-connect
web
package-variant-closed
```

Do not store:

- `mdi-dns` CSS class names;
- Unicode codepoints;
- WPF enum values;
- font file paths;
- package-specific version strings.

The UI adapter maps the canonical name to the icon package used by the application.

## Runtime fallback

Validated metadata should normally resolve directly. To prevent an empty button if the installed UI icon package is older or damaged, use:

```text
script-text-outline
```

Fallback algorithm:

```text
Resolve metadata icon
→ if resolved, render it
→ otherwise render script-text-outline
→ record a warning for diagnostics
```

The fallback is a rendering safeguard. It must not cause the Validator to accept a missing or unknown icon.

## Suggested category catalogue

The standard does not freeze a global category list, but consistent IDs are recommended:

```text
dashboard
performance
storage
network
diagnostics
dns
services
logs
packages
users
security
web
ssl
databases
docker
scheduled-tasks
backup
power
software-installation
```

## Suggested action examples

```text
system-overview
resource-monitoring
disk-analysis
network-information
network-diagnostics
dns-tools
service-control
log-viewing
package-maintenance
user-management
firewall-management
web-server-management
certificate-management
database-management
container-management
backup-management
web-servers
databases-and-caches
development-runtimes
```

These are conventions rather than closed enums.

## Migration from v1.0

For each v1.0 script:

1. preserve all Bash logic and parameter blocks;
2. remove any existing certification before modification;
3. change metadata schema version from `1.0` to `1.1`;
4. add category and action IDs and names;
5. select the most semantically related canonical MDI icon;
6. validate the icon against the official catalogue;
7. validate the complete script;
8. request new certification when required.

Do not add Bash logic solely to support category, action, or icon metadata.
