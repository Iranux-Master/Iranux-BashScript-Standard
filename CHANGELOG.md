# Changelog

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
- valid and invalid v1.1 fixtures.

Compatibility notes:

- v1.0 metadata remains governed by v1.0;
- v1.1 requires the complete `ui` object;
- existing parameter blocks and parameter types are unchanged;
- the certification model is unchanged;
- the final marker remains `__IRANUX_REACHED_END_V1__`;
- SSH execution and parameter transport remain outside the metadata standard.

## Version 1.0 - 2026-05

Initial draft defining metadata, parameter, certification, compatibility, validation, and final-marker concepts.
