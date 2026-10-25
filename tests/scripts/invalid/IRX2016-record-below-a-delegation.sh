#!/usr/bin/env bash
# Test script for the DNS rules of specification v1.3; it only prints the names it received.

: <<'IRANUX_METADATA'
{
  "standard": {
    "name": "iranux-script-metadata",
    "schema_version": "1.3"
  },
  "script": {
    "id": "dns-irx2016-record-below-a-delegation",
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
        "id": "tunnel-glue",
        "anchor": "tunnel_domain",
        "name": "{anchor.label}-ns.{anchor.parent}",
        "type": "A",
        "value": "{server.ipv4}",
        "ttl": 300,
        "purpose": "Needed by this example.",
        "i18n": {
          "fa": {
            "purpose": "برای این نمونه لازم است."
          }
        }
      },
      {
        "id": "tunnel-ns",
        "anchor": "tunnel_domain",
        "name": "{anchor}",
        "type": "NS",
        "value": "{anchor.label}-ns.{anchor.parent}",
        "ttl": 300,
        "purpose": "Needed by this example.",
        "i18n": {
          "fa": {
            "purpose": "برای این نمونه لازم است."
          }
        }
      },
      {
        "id": "probe",
        "anchor": "tunnel_domain",
        "name": "_probe.{anchor}",
        "type": "TXT",
        "value": "hello",
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
  "name": "tunnel_domain",
  "label": "Tunnel subdomain",
  "description": "The tunnel subdomain the records are created for.",
  "type": "domain",
  "required": true,
  "placeholder": "t.example.com",
  "i18n": {
    "fa": {
      "label": "زیردامنه‌ی تونل",
      "description": "نامی که رکوردها برای آن ساخته می‌شوند."
    }
  }
}
IRANUX_PARAM

set -euo pipefail

TUNNEL_DOMAIN="${TUNNEL_DOMAIN:-}"
IRANUX_DNS_STATUS="${IRANUX_DNS_STATUS:-none}"

echo "== DNS status: ${IRANUX_DNS_STATUS}"
echo "== TUNNEL_DOMAIN: ${TUNNEL_DOMAIN}"
echo "__IRANUX_REACHED_END_V1__"
exit 0
