#!/usr/bin/env bash
# Test script for the option labels of specification v1.3; it only prints the choice it received.

: <<'IRANUX_METADATA'
{
  "standard": {
    "name": "iranux-script-metadata",
    "schema_version": "1.2"
  },
  "script": {
    "id": "choice-irx2017-v1-2",
    "name": "Choice example",
    "version": "1.0.0",
    "description": "Prints the choice the user made.",
    "estimated_minutes": 1,
    "i18n": {
      "fa": {
        "name": "نمونه‌ی انتخاب",
        "description": "گزینه‌ای را که کاربر انتخاب کرده نشان می‌دهد."
      }
    }
  },
  "risk": {
    "level": "low"
  },
  "requirements": {
    "requires_root": false,
    "requires_internet": false,
    "supported_os": [
      "ubuntu",
      "debian"
    ],
    "required_commands": []
  },
  "ui": {
    "category": {
      "id": "system",
      "name": "System"
    },
    "action": {
      "id": "choices",
      "name": "Choices"
    },
    "icon": {
      "library": "mdi",
      "name": "form-select"
    }
  }
}
IRANUX_METADATA

: <<'IRANUX_PARAM'
{
  "name": "enable_feature",
  "label": "Turn the feature on?",
  "description": "Choose Yes to turn the feature on.",
  "type": "enum",
  "required": true,
  "default": "N",
  "options": [
    {
      "label": "Yes",
      "value": "Y",
      "i18n": {
        "fa": {
          "label": "بله"
        }
      }
    },
    {
      "label": "No",
      "value": "N",
      "i18n": {
        "fa": {
          "label": "خیر"
        }
      }
    }
  ],
  "i18n": {
    "fa": {
      "label": "این قابلیت روشن شود؟",
      "description": "برای روشن کردن قابلیت «بله» را انتخاب کنید."
    }
  }
}
IRANUX_PARAM

set -euo pipefail

ENABLE_FEATURE="${ENABLE_FEATURE:-N}"

echo "== ENABLE_FEATURE: ${ENABLE_FEATURE}"
echo "__IRANUX_REACHED_END_V1__"
exit 0
