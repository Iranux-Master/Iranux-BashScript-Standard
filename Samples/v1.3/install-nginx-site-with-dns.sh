#!/usr/bin/env bash
# Iranux v1.3 sample: installs Nginx and serves a site for a domain. The runner creates
# the domain's address records before the script starts (the dns block), so the user
# does not have to point the domain at the server by hand.
#
# Demonstrates: the dns block (A, AAAA only when the server has IPv6, and a www CNAME),
# the IRANUX_DNS_* variables, a fallback check when the records were not confirmed, and
# the v1.2 features (i18n, exit codes, OS detection, idempotent configuration,
# IRANUX_RESULT).

: <<'IRANUX_METADATA'
{
  "standard": {
    "name": "iranux-script-metadata",
    "schema_version": "1.3"
  },
  "script": {
    "id": "install-nginx-site-with-dns",
    "name": "Nginx site with automatic DNS",
    "version": "1.0.0",
    "description": "Installs Nginx and serves a site for your domain and its www name on port 80. The domain's address records are created for you before the install.",
    "estimated_minutes": 3,
    "i18n": {
      "fa": {
        "name": "سایت Nginx با DNS خودکار",
        "description": "Nginx را نصب می‌کند و سایت دامنه‌ی شما و نام www آن را روی پورت ۸۰ راه می‌اندازد. رکوردهای نشانی دامنه پیش از نصب برای شما ساخته می‌شوند."
      }
    }
  },
  "risk": {
    "level": "medium"
  },
  "requirements": {
    "requires_root": true,
    "requires_internet": true,
    "supported_os": ["ubuntu", "debian"],
    "required_commands": ["apt-get", "systemctl"]
  },
  "ui": {
    "category": {
      "id": "web",
      "name": "Web Servers"
    },
    "action": {
      "id": "web-server-management",
      "name": "Web Server Management"
    },
    "icon": {
      "library": "mdi",
      "name": "web"
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
        "purpose": "Points your domain at this server.",
        "i18n": { "fa": { "purpose": "دامنه‌ی شما را به این سرور وصل می‌کند." } }
      },
      {
        "id": "site-v6",
        "anchor": "site_domain",
        "name": "{anchor}",
        "type": "AAAA",
        "value": "{server.ipv6}",
        "when": "server.ipv6",
        "purpose": "Points your domain at this server's IPv6 address.",
        "i18n": { "fa": { "purpose": "دامنه‌ی شما را به نشانی IPv6 این سرور وصل می‌کند." } }
      },
      {
        "id": "www",
        "anchor": "site_domain",
        "name": "www.{anchor}",
        "type": "CNAME",
        "value": "{anchor}",
        "optional": true,
        "purpose": "Makes the www name open the same site.",
        "i18n": { "fa": { "purpose": "نام www را هم به همین سایت می‌برد." } }
      }
    ]
  }
}
IRANUX_METADATA

: <<'IRANUX_PARAM'
{
  "name": "site_domain",
  "label": "Domain",
  "description": "The domain the site answers on, for example example.com or blog.example.com.",
  "type": "domain",
  "required": true,
  "example": "example.com",
  "placeholder": "example.com",
  "i18n": {
    "fa": {
      "label": "دامنه",
      "description": "دامنه‌ای که سایت روی آن پاسخ می‌دهد، مثلاً example.com یا blog.example.com.",
      "placeholder": "example.com"
    }
  }
}
IRANUX_PARAM

set -euo pipefail

SITE_DOMAIN="${SITE_DOMAIN:-}"
IRANUX_DNS_STATUS="${IRANUX_DNS_STATUS:-none}"
IRANUX_DNS_WWW="${IRANUX_DNS_WWW:-}"

fail() {
  echo "$2" >&2
  exit "$1"
}

# Appendix C helper: JSON string for the result line.
iranux_json_string() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\n'/\\n}"
  printf '"%s"' "$s"
}

# --- Checks ------------------------------------------------------------------

[[ "$(id -u)" -eq 0 ]] || fail 77 "This script must run as root."

[[ -n "$SITE_DOMAIN" ]] || fail 64 "Domain is required."
SITE_DOMAIN="${SITE_DOMAIN,,}"
[[ "$SITE_DOMAIN" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$ ]] \
  || fail 64 "Domain '$SITE_DOMAIN' is not a valid domain name."

OS_ID=""
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  OS_ID="${ID:-}"
fi
case "$OS_ID" in
  ubuntu|debian) ;;
  *) fail 78 "Unsupported operating system '${OS_ID:-unknown}'. This script supports Ubuntu and Debian." ;;
esac

for cmd in apt-get systemctl; do
  command -v "$cmd" >/dev/null 2>&1 || fail 78 "Required command '$cmd' was not found."
done

# --- DNS ---------------------------------------------------------------------
# "applied" and "manual" mean the runner saw the records on the domain's authoritative
# name servers. Otherwise this site still works over HTTP once the records appear, so
# the script only reports the state; a script that requests a certificate would check
# the authoritative servers here and exit 75 if the name never resolves (spec §8.1.2).

case "$IRANUX_DNS_STATUS" in
  applied|manual) echo "== DNS records for ${SITE_DOMAIN} are in place" ;;
  unverified) echo "== DNS records for ${SITE_DOMAIN} were not confirmed yet; the site answers once they appear" ;;
  *) echo "== Point ${SITE_DOMAIN} at this server's address if you have not done so" ;;
esac

SERVER_NAMES="$SITE_DOMAIN"
if [[ -n "$IRANUX_DNS_WWW" ]]; then
  SERVER_NAMES="${SITE_DOMAIN} ${IRANUX_DNS_WWW}"
fi

# --- Install -----------------------------------------------------------------

echo "== Installing Nginx"
apt-get update -q
DEBIAN_FRONTEND=noninteractive apt-get install -y -q nginx

WEB_ROOT="/var/www/${SITE_DOMAIN}"
mkdir -p "$WEB_ROOT"
if [[ ! -f "${WEB_ROOT}/index.html" ]]; then
  cat > "${WEB_ROOT}/index.html" <<EOF
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>${SITE_DOMAIN}</title></head>
<body><h1>${SITE_DOMAIN}</h1><p>This site is served by Nginx.</p></body></html>
EOF
fi
chown -R www-data:www-data "$WEB_ROOT"

echo "== Writing the Nginx site configuration"
SITE_CONF="/etc/nginx/sites-available/${SITE_DOMAIN}.conf"
cat > "$SITE_CONF" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${SERVER_NAMES};
    root ${WEB_ROOT};
    index index.html;
}
EOF
ln -sfn "$SITE_CONF" "/etc/nginx/sites-enabled/${SITE_DOMAIN}.conf"
# The stock default site also claims port 80; it would compete with this site.
rm -f /etc/nginx/sites-enabled/default

echo "== Checking the configuration and starting Nginx"
nginx -t
systemctl enable --now nginx
systemctl reload nginx

# --- Result ------------------------------------------------------------------

SITE_URL="http://${SITE_DOMAIN}/"

echo "== Done"
echo "Site: ${SITE_URL}"

echo "IRANUX_RESULT {\"outputs\":[{\"key\":\"site_url\",\"label\":\"Site address\",\"value\":$(iranux_json_string "$SITE_URL"),\"type\":\"url\",\"i18n\":{\"fa\":{\"label\":\"آدرس سایت\"}}}]}"
echo "__IRANUX_REACHED_END_V1__"
exit 0
