#!/usr/bin/env bash
# Test script for the DNS rules of specification v1.3; it only prints the names it received.

: <<'IRANUX_METADATA'
{
  "standard": {
    "name": "iranux-script-metadata",
    "schema_version": "1.3"
  },
  "script": {
    "id": "dns-mail-dkim-after-run",
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
        "id": "mail-host",
        "anchor": "mail_domain",
        "name": "mail.{anchor}",
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
        "id": "mail-mx",
        "anchor": "mail_domain",
        "name": "{anchor}",
        "type": "MX",
        "value": "mail.{anchor}",
        "priority": 10,
        "purpose": "Needed by this example.",
        "i18n": {
          "fa": {
            "purpose": "برای این نمونه لازم است."
          }
        }
      },
      {
        "id": "mail-spf",
        "anchor": "mail_domain",
        "name": "{anchor}",
        "type": "TXT",
        "value": "v=spf1 mx -all",
        "purpose": "Needed by this example.",
        "i18n": {
          "fa": {
            "purpose": "برای این نمونه لازم است."
          }
        }
      },
      {
        "id": "mail-dmarc",
        "anchor": "mail_domain",
        "name": "_dmarc.{anchor}",
        "type": "TXT",
        "value": "v=DMARC1; p=quarantine",
        "purpose": "Needed by this example.",
        "i18n": {
          "fa": {
            "purpose": "برای این نمونه لازم است."
          }
        }
      },
      {
        "id": "mail-caa",
        "anchor": "mail_domain",
        "name": "mail.{anchor}",
        "type": "CAA",
        "value": "0 issue \"letsencrypt.org\"",
        "optional": true,
        "purpose": "Needed by this example.",
        "i18n": {
          "fa": {
            "purpose": "برای این نمونه لازم است."
          }
        }
      },
      {
        "id": "mail-dkim",
        "anchor": "mail_domain",
        "name": "mail._domainkey.{anchor}",
        "type": "TXT",
        "value": "{output.dkim_txt}",
        "phase": "after_run",
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
  "name": "mail_domain",
  "label": "Mail domain",
  "description": "The mail domain the records are created for.",
  "type": "domain",
  "required": true,
  "placeholder": "example.com",
  "i18n": {
    "fa": {
      "label": "دامنه‌ی ایمیل",
      "description": "نامی که رکوردها برای آن ساخته می‌شوند."
    }
  }
}
IRANUX_PARAM

set -euo pipefail

MAIL_DOMAIN="${MAIL_DOMAIN:-}"
IRANUX_DNS_MAIL_HOST="${IRANUX_DNS_MAIL_HOST:-}"
IRANUX_DNS_STATUS="${IRANUX_DNS_STATUS:-none}"

echo "== DNS status: ${IRANUX_DNS_STATUS}"
echo "== MAIL_DOMAIN: ${MAIL_DOMAIN}"
echo "== IRANUX_DNS_MAIL_HOST: ${IRANUX_DNS_MAIL_HOST}"
echo "IRANUX_RESULT {\"outputs\":[{\"key\":\"dkim_txt\",\"label\":\"DKIM record\",\"value\":\"v=DKIM1; k=rsa; p=MIIB\",\"type\":\"copy\",\"i18n\":{\"fa\":{\"label\":\"رکورد DKIM\"}}}]}"
echo "__IRANUX_REACHED_END_V1__"
exit 0
