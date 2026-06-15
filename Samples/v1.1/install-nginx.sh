#!/usr/bin/env bash

: <<'IRANUX_METADATA'
{
  "standard": {
    "name": "iranux-script-metadata",
    "schema_version": "1.1"
  },
  "script": {
    "id": "install-nginx",
    "name": "Install Nginx",
    "version": "1.0.0",
    "description": "Installs Nginx and optionally enables and starts the service."
  },
  "risk": {
    "level": "medium"
  },
  "requirements": {
    "requires_root": true,
    "requires_internet": true,
    "supported_os": [
      "ubuntu",
      "debian"
    ],
    "required_commands": [
      "apt-get",
      "systemctl"
    ]
  },
  "ui": {
    "category": {
      "id": "software-installation",
      "name": "Software Installation"
    },
    "action": {
      "id": "web-servers",
      "name": "Web Servers"
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
  "name": "enable_service",
  "label": "Enable Nginx at Startup",
  "description": "Choose whether the Nginx service should start automatically after reboot.",
  "type": "bool",
  "required": false,
  "default": true,
  "group": "Service Settings"
}
IRANUX_PARAM

ENABLE_SERVICE="${ENABLE_SERVICE:-true}"

: <<'IRANUX_PARAM'
{
  "name": "start_service",
  "label": "Start Nginx Now",
  "description": "Choose whether Nginx should be started immediately after installation.",
  "type": "bool",
  "required": false,
  "default": true,
  "group": "Service Settings"
}
IRANUX_PARAM

START_SERVICE="${START_SERVICE:-true}"

set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 77
fi

case "$ENABLE_SERVICE" in
  true|false) ;;
  *)
    echo "ENABLE_SERVICE must be true or false." >&2
    exit 64
    ;;
esac

case "$START_SERVICE" in
  true|false) ;;
  *)
    echo "START_SERVICE must be true or false." >&2
    exit 64
    ;;
esac

echo "=== UPDATE PACKAGE INDEX ==="
apt-get update

echo "=== INSTALL NGINX ==="
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

if [[ "$ENABLE_SERVICE" == "true" ]]; then
  echo "=== ENABLE NGINX ==="
  systemctl enable nginx
fi

if [[ "$START_SERVICE" == "true" ]]; then
  echo "=== START NGINX ==="
  systemctl start nginx
fi

echo "=== NGINX STATUS ==="
systemctl is-enabled nginx 2>/dev/null || true
systemctl is-active nginx 2>/dev/null || true
nginx -v 2>&1

echo "__IRANUX_REACHED_END_V1__"
exit 0
