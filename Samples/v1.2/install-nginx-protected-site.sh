#!/usr/bin/env bash
# Iranux v1.2 sample: installs Nginx, serves a site for a domain and protects the
# server status page with a username and a generated password.
#
# Demonstrates: i18n (Persian), basic and advanced parameters, a generated password,
# a generated port, a sensitive parameter that is never printed, exit codes,
# OS detection, idempotent configuration and the IRANUX_RESULT line.

: <<'IRANUX_METADATA'
{
  "standard": {
    "name": "iranux-script-metadata",
    "schema_version": "1.2"
  },
  "script": {
    "id": "install-nginx-protected-site",
    "name": "Nginx with a protected status page",
    "version": "1.0.0",
    "description": "Installs Nginx, serves a site for your domain on port 80 and protects the server status page on a separate port with a username and password.",
    "estimated_minutes": 3,
    "i18n": {
      "fa": {
        "name": "Nginx با صفحه‌ی وضعیت محافظت‌شده",
        "description": "Nginx را نصب می‌کند، سایت دامنه‌ی شما را روی پورت ۸۰ راه می‌اندازد و صفحه‌ی وضعیت سرور را روی پورت جداگانه با نام کاربری و رمز محافظت می‌کند."
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
  }
}
IRANUX_METADATA

: <<'IRANUX_PARAM'
{
  "name": "site_domain",
  "label": "Domain",
  "description": "The domain name that points to this server. The site answers on this name.",
  "type": "domain",
  "required": true,
  "example": "example.com",
  "placeholder": "example.com",
  "group": "Site",
  "i18n": {
    "fa": {
      "label": "دامنه",
      "description": "دامنه‌ای که به این سرور اشاره می‌کند. سایت با این نام پاسخ می‌دهد.",
      "placeholder": "example.com"
    }
  }
}
IRANUX_PARAM

: <<'IRANUX_PARAM'
{
  "name": "admin_username",
  "label": "Status page username",
  "description": "The username you will type to open the server status page.",
  "type": "string",
  "required": true,
  "default": "admin",
  "group": "Status page",
  "validation": {
    "pattern": "^[a-z][a-z0-9_-]{2,31}$"
  },
  "i18n": {
    "fa": {
      "label": "نام کاربری صفحه‌ی وضعیت",
      "description": "نام کاربری‌ای که برای باز کردن صفحه‌ی وضعیت سرور وارد می‌کنید."
    }
  }
}
IRANUX_PARAM

: <<'IRANUX_PARAM'
{
  "name": "admin_password",
  "label": "Status page password",
  "description": "Leave empty to get a strong password generated for you. It is shown once after the installation.",
  "type": "password",
  "required": true,
  "generate": "password",
  "group": "Status page",
  "i18n": {
    "fa": {
      "label": "رمز صفحه‌ی وضعیت",
      "description": "خالی بگذارید تا یک رمز قوی برای شما ساخته شود. رمز یک بار پس از نصب نمایش داده می‌شود."
    }
  }
}
IRANUX_PARAM

: <<'IRANUX_PARAM'
{
  "name": "status_port",
  "label": "Status page port",
  "description": "The port the status page listens on. Leave empty to get a free random port.",
  "type": "port",
  "required": true,
  "level": "advanced",
  "generate": "port",
  "group": "Status page",
  "i18n": {
    "fa": {
      "label": "پورت صفحه‌ی وضعیت",
      "description": "پورتی که صفحه‌ی وضعیت روی آن گوش می‌دهد. خالی بگذارید تا یک پورت آزاد تصادفی انتخاب شود."
    }
  }
}
IRANUX_PARAM

: <<'IRANUX_PARAM'
{
  "name": "allowed_cidr",
  "label": "Allowed network for the status page",
  "description": "Only addresses in this network can open the status page. The default allows every address.",
  "type": "cidr",
  "required": true,
  "level": "advanced",
  "default": "0.0.0.0/0",
  "example": "203.0.113.0/24",
  "group": "Status page",
  "i18n": {
    "fa": {
      "label": "شبکه‌ی مجاز برای صفحه‌ی وضعیت",
      "description": "فقط آدرس‌های این شبکه می‌توانند صفحه‌ی وضعیت را باز کنند. مقدار پیش‌فرض همه‌ی آدرس‌ها را مجاز می‌کند."
    }
  }
}
IRANUX_PARAM

set -euo pipefail

SITE_DOMAIN="${SITE_DOMAIN:-}"
ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"
STATUS_PORT="${STATUS_PORT:-}"
ALLOWED_CIDR="${ALLOWED_CIDR:-0.0.0.0/0}"

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

[[ "$ADMIN_USERNAME" =~ ^[a-z][a-z0-9_-]{2,31}$ ]] \
  || fail 64 "Username must be 3 to 32 lowercase letters, digits, '_' or '-'."

# The Iranux web app generates the password and the port when they are left empty.
# Other runners may not, so say clearly what is missing.
[[ -n "$ADMIN_PASSWORD" ]] || fail 64 "Status page password is required."
[[ "$STATUS_PORT" =~ ^[0-9]{1,5}$ && "$STATUS_PORT" -ge 1 && "$STATUS_PORT" -le 65535 ]] \
  || fail 64 "Status page port must be a number between 1 and 65535."
[[ "$STATUS_PORT" -ne 80 ]] || fail 64 "Status page port must not be 80; the site uses it."
[[ "$ALLOWED_CIDR" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]] \
  || fail 64 "Allowed network must be an IPv4 network such as 203.0.113.0/24."

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

# --- Install -----------------------------------------------------------------

echo "== Installing Nginx"
apt-get update -q
DEBIAN_FRONTEND=noninteractive apt-get install -y -q nginx apache2-utils

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

echo "== Writing the status page credentials"
HTPASSWD_FILE="/etc/nginx/.status-htpasswd"
umask 027
# The password goes to htpasswd on stdin (-i), never on the command line.
printf '%s\n' "$ADMIN_PASSWORD" | htpasswd -i -c "$HTPASSWD_FILE" "$ADMIN_USERNAME"
chown root:www-data "$HTPASSWD_FILE"
chmod 640 "$HTPASSWD_FILE"
umask 022

echo "== Writing the Nginx site configuration"
SITE_CONF="/etc/nginx/sites-available/${SITE_DOMAIN}.conf"
cat > "$SITE_CONF" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${SITE_DOMAIN};
    root ${WEB_ROOT};
    index index.html;
}

server {
    listen ${STATUS_PORT};
    listen [::]:${STATUS_PORT};
    server_name ${SITE_DOMAIN};

    location = /status {
        stub_status;
        allow ${ALLOWED_CIDR};
        deny all;
        auth_basic "Server status";
        auth_basic_user_file ${HTPASSWD_FILE};
    }

    location / {
        return 404;
    }
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
STATUS_URL="http://${SITE_DOMAIN}:${STATUS_PORT}/status"

echo "== Done"
echo "Site: ${SITE_URL}"
echo "Status page: ${STATUS_URL} (user ${ADMIN_USERNAME}; the password is shown by Iranux)"

echo "IRANUX_RESULT {\"outputs\":[{\"key\":\"site_url\",\"label\":\"Site address\",\"value\":$(iranux_json_string "$SITE_URL"),\"type\":\"url\",\"i18n\":{\"fa\":{\"label\":\"آدرس سایت\"}}},{\"key\":\"status_url\",\"label\":\"Status page\",\"value\":$(iranux_json_string "$STATUS_URL"),\"type\":\"url\",\"i18n\":{\"fa\":{\"label\":\"صفحه‌ی وضعیت\"}}},{\"key\":\"admin_username\",\"label\":\"Username\",\"value\":$(iranux_json_string "$ADMIN_USERNAME"),\"type\":\"copy\",\"i18n\":{\"fa\":{\"label\":\"نام کاربری\"}}}],\"show_generated\":[\"admin_password\"]}"
echo "__IRANUX_REACHED_END_V1__"
exit 0
