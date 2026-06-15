# AI Application Integration Guide for Iranux v1.1

## Objective

Implement Iranux v1.1 script discovery, form generation, UI grouping, MDI icon rendering, and remote execution without inventing a parallel metadata format. Each Bash file remains the source of truth.

## Required flow

1. Detect the connected server operating system.
2. Discover Bash files in the local application library.
3. Read each file as UTF-8 text without executing it.
4. Extract exactly one `IRANUX_METADATA` heredoc and parse it as strict JSON.
5. Select the schema identified by `standard.schema_version`.
6. Extract every `IRANUX_PARAM` block in source order and parse each independently.
7. Filter scripts by `requirements.supported_os`.
8. Group scripts by `ui.category.id`, then `ui.action.id`.
9. Render one Button per script using `script.name` and `ui.icon.name`.
10. Generate the parameter form, validate input, show metadata and risk, and request confirmation.
11. Send the complete selected Bash file through the existing SSH execution channel.
12. Stream stdout and stderr, capture the exit code, and detect `__IRANUX_REACHED_END_V1__`.

## Parsing rules

Use a strict JSON parser. Do not permit comments, trailing commas, JSON5, YAML, or silent repair. Do not execute or source a script during discovery. Do not infer parameters from Bash assignments or terminal prompts.

For schema version 1.1, require `ui.category`, `ui.action`, and `ui.icon`. Use IDs as stable keys and names as display labels. Folder numbers are not metadata.

## MDI icons

`ui.icon.library` must be `mdi`. `ui.icon.name` is the canonical Pictogrammers MDI name without the `mdi-` prefix. The Validator confirms exact existence in the approved official catalogue. The WPF adapter maps the portable name to its local icon package.

When a previously validated icon cannot be resolved at runtime, render `script-text-outline` and record a warning. Never display an empty icon. Runtime fallback does not make missing or invalid metadata valid.

## Form controls

- Text input: string, email, URL, domain, host, IP, CIDR, MAC, path, cron.
- Multiline editor: multiline, JSON, certificates, public keys, private keys.
- Numeric input: integer, float, port, duration, size.
- Toggle: boolean.
- Single selection: enum.
- Multiple selection: multi_select.
- Secure masked input: password and secret.
- Date and time controls: date, time, datetime.

Display label, description, default, placeholder, example, group, options, and validation feedback. For choices, display `options[].label` and supply `options[].value` unchanged.

Treat password, secret, and private_key values as sensitive. Exclude them from logs, history, previews, reports, telemetry, and error details.

## Parameter convention

The standard leaves transport to the application. The Ubuntu VPS Actions package uses uppercase environment-variable names derived from parameter names, for example `dns_server` becomes `DNS_SERVER`. The app must transmit values using its existing safe execution mechanism.

## Execution rules

Scripts are stored locally and sent in full through the existing SSH connection. No runner, shared Bash library, or package installation is required on the server. The JSON heredocs stay inside the script because Bash treats them as no-op input to the `:` builtin.

The normal Iranux path is non-interactive. Inputs are collected before execution rather than requested with `read`.

The application remains responsible for privilege selection, safe value transport, timeout, cancellation, output streaming, exit-code capture, connection-loss handling, and audit history.

## Result model

Keep the following independent: script ID, server identity, start and end time, exit code, stdout, stderr, final-marker detection, timeout, cancellation, connection loss, and a non-sensitive parameter summary.

The final marker means the script reached its intended final point. It does not independently prove that every external dependency succeeded.

## Prohibited shortcuts

Do not use a sidecar manifest as the authoritative source. Do not install all scripts on the target server. Do not require `runner.sh` or `common.sh`. Do not invent missing icons. Do not manually create certification. Do not modify a Verified script without invalidating its certification.
