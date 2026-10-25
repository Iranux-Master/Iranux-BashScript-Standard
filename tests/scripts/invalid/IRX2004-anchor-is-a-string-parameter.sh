#!/usr/bin/env bash
# Test script for the DNS rules of specification v1.3; it only prints the names it received.

: <<'IRANUX_METADATA'
{
  "standard": {
    "name": "iranux-script-metadata",
    "schema_version": "1.3"
  },
  "script": {
    "id": "dns-irx2004-anchor-is-a-string-parameter",
    "name": "DNS records example",
    "version": "1.0.0",
    "description": "Prints the DNS names the runner created for this server.",
    "estimated_minutes": 1,
    "i18n": {
      "fa": {
        "name": "نمونه‌ی رکوردهای DNS",
        "description": "نام‌های DNS که برای این سرور ساخته شده را نشان می‌دهد."
      }
    }
  },
  "risk": {
    "level": "medium"
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
      "id": "network",
      "name": "Network"
    },
    "action": {
      "id": "dns-records",
      "name": "DNS Records"
    },
    "icon": {
      "library": "mdi",
      "name": "dns"
    }
  },
  "dns": {
    "records": [
      {
        "id": "site",
        "anchor": "site_label",
        "name": "{anchor}",
        "type": "A",
        "value": "{server.ipv4}",
        "purpose": "Needed by this example.",
        "i18n": {
          "fa": {
            "purpose": "برای این نمونه لازم است."
          }
        }
      }
    ]
  }
}
IRANUX_METADATA

: <<'IRANUX_PARAM'
{
  "name": "site_label",
  "label": "Site label",
  "description": "The site label the records are created for.",
  "type": "string",
  "required": true,
  "placeholder": "example.com",
  "i18n": {
    "fa": {
      "label": "برچسب سایت",
      "description": "نامی که رکوردها برای آن ساخته می‌شوند."
    }
  }
}
IRANUX_PARAM

set -euo pipefail

SITE_LABEL="${SITE_LABEL:-}"
IRANUX_DNS_STATUS="${IRANUX_DNS_STATUS:-none}"

echo "== DNS status: ${IRANUX_DNS_STATUS}"
echo "== SITE_LABEL: ${SITE_LABEL}"
echo "__IRANUX_REACHED_END_V1__"
exit 0
