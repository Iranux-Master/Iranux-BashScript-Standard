#!/usr/bin/env bash
# Test script for the DNS rules of specification v1.3; it only prints the names it received.

: <<'IRANUX_METADATA'
{
  "standard": {
    "name": "iranux-script-metadata",
    "schema_version": "1.3"
  },
  "script": {
    "id": "dns-irx2003-duplicate-record-id",
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
        "anchor": "site_domain",
        "name": "{anchor}",
        "type": "A",
        "value": "{server.ipv4}",
        "purpose": "Needed by this example.",
        "i18n": {
          "fa": {
            "purpose": "برای این نمونه لازم است."
          }
        }
      },
      {
        "id": "site",
        "anchor": "site_domain",
        "name": "www.{anchor}",
        "type": "CNAME",
        "value": "{anchor}",
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
  "name": "site_domain",
  "label": "Site domain",
  "description": "The site domain the records are created for.",
  "type": "domain",
  "required": true,
  "placeholder": "example.com",
  "i18n": {
    "fa": {
      "label": "دامنه‌ی سایت",
      "description": "نامی که رکوردها برای آن ساخته می‌شوند."
    }
  }
}
IRANUX_PARAM

set -euo pipefail

SITE_DOMAIN="${SITE_DOMAIN:-}"
IRANUX_DNS_STATUS="${IRANUX_DNS_STATUS:-none}"

echo "== DNS status: ${IRANUX_DNS_STATUS}"
echo "== SITE_DOMAIN: ${SITE_DOMAIN}"
echo "__IRANUX_REACHED_END_V1__"
exit 0
