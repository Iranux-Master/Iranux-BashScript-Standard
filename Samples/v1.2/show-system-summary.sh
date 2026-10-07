#!/usr/bin/env bash
# Iranux v1.2 sample: a read-only (risk "safe") report with Persian text, a basic
# and an advanced parameter, no root, no network, and an IRANUX_RESULT line.

: <<'IRANUX_METADATA'
{
  "standard": {
    "name": "iranux-script-metadata",
    "schema_version": "1.2"
  },
  "script": {
    "id": "show-system-summary",
    "name": "Show system summary",
    "version": "1.0.0",
    "description": "Shows the operating system, uptime, load, memory, disk usage and the busiest processes. Changes nothing.",
    "estimated_minutes": 1,
    "i18n": {
      "fa": {
        "name": "خلاصه‌ی وضعیت سیستم",
        "description": "سیستم‌عامل، مدت روشن بودن، بار پردازنده، حافظه، فضای دیسک و پرمصرف‌ترین پردازه‌ها را نشان می‌دهد. چیزی را تغییر نمی‌دهد."
      }
    }
  },
  "risk": {
    "level": "safe"
  },
  "requirements": {
    "requires_root": false,
    "requires_internet": false,
    "supported_os": [],
    "required_commands": ["df", "free", "ps"]
  },
  "ui": {
    "category": {
      "id": "diagnostics",
      "name": "Diagnostics"
    },
    "action": {
      "id": "system-overview",
      "name": "System Overview"
    },
    "icon": {
      "library": "mdi",
      "name": "information-outline"
    }
  }
}
IRANUX_METADATA

: <<'IRANUX_PARAM'
{
  "name": "top_processes",
  "label": "Number of processes to show",
  "description": "How many of the busiest processes are listed.",
  "type": "int",
  "required": true,
  "default": 5,
  "validation": {
    "min_value": 1,
    "max_value": 20
  },
  "i18n": {
    "fa": {
      "label": "تعداد پردازه‌های نمایش‌داده‌شده",
      "description": "چند پردازه‌ی پرمصرف فهرست شود."
    }
  }
}
IRANUX_PARAM

: <<'IRANUX_PARAM'
{
  "name": "include_services",
  "label": "List failed services",
  "description": "Also list system services that are in a failed state.",
  "type": "bool",
  "required": true,
  "default": true,
  "level": "advanced",
  "i18n": {
    "fa": {
      "label": "نمایش سرویس‌های ناموفق",
      "description": "سرویس‌های سیستمی را که در وضعیت خطا هستند هم فهرست کند."
    }
  }
}
IRANUX_PARAM

set -euo pipefail

TOP_PROCESSES="${TOP_PROCESSES:-5}"
INCLUDE_SERVICES="${INCLUDE_SERVICES:-true}"

fail() {
  echo "$2" >&2
  exit "$1"
}

iranux_json_string() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\n'/\\n}"
  printf '"%s"' "$s"
}

[[ "$TOP_PROCESSES" =~ ^[0-9]+$ && "$TOP_PROCESSES" -ge 1 && "$TOP_PROCESSES" -le 20 ]] \
  || fail 64 "Number of processes must be between 1 and 20."
case "$INCLUDE_SERVICES" in
  true|false) ;;
  *) fail 64 "List failed services must be true or false." ;;
esac

for cmd in df free ps; do
  command -v "$cmd" >/dev/null 2>&1 || fail 78 "Required command '$cmd' was not found."
done

OS_NAME="unknown"
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  OS_NAME="${PRETTY_NAME:-${ID:-unknown}}"
fi

echo "== Host"
echo "Hostname: $(hostname)"
echo "System:   ${OS_NAME}"
echo "Kernel:   $(uname -r)"

echo "== Uptime and load"
UPTIME_TEXT="$(uptime -p 2>/dev/null || uptime)"
echo "$UPTIME_TEXT"
echo "Load average: $(cut -d ' ' -f 1-3 /proc/loadavg)"

echo "== Memory"
free -h
MEMORY_LINE="$(free -m | awk '/^Mem:/ { printf "%d MB used of %d MB", $3, $2 }')"

echo "== Disk"
df -h -x tmpfs -x devtmpfs
DISK_USED_PERCENT="$(df --output=pcent / | tail -n 1 | tr -dc '0-9')"

echo "== Top ${TOP_PROCESSES} processes by CPU"
ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -n "$((TOP_PROCESSES + 1))"

FAILED_SERVICES="not checked"
if [[ "$INCLUDE_SERVICES" == "true" ]] && command -v systemctl >/dev/null 2>&1; then
  echo "== Failed services"
  FAILED_LIST="$(systemctl --failed --no-legend --plain 2>/dev/null || true)"
  if [[ -n "$FAILED_LIST" ]]; then
    echo "$FAILED_LIST"
    FAILED_SERVICES="$(printf '%s\n' "$FAILED_LIST" | wc -l | tr -d ' ')"
  else
    echo "none"
    FAILED_SERVICES="0"
  fi
fi

echo "IRANUX_RESULT {\"outputs\":[{\"key\":\"system\",\"label\":\"System\",\"value\":$(iranux_json_string "$OS_NAME"),\"type\":\"text\",\"i18n\":{\"fa\":{\"label\":\"سیستم\"}}},{\"key\":\"uptime\",\"label\":\"Uptime\",\"value\":$(iranux_json_string "$UPTIME_TEXT"),\"type\":\"text\",\"i18n\":{\"fa\":{\"label\":\"مدت روشن بودن\"}}},{\"key\":\"memory\",\"label\":\"Memory\",\"value\":$(iranux_json_string "$MEMORY_LINE"),\"type\":\"text\",\"i18n\":{\"fa\":{\"label\":\"حافظه\"}}},{\"key\":\"disk_used_percent\",\"label\":\"Root disk used\",\"value\":$(iranux_json_string "${DISK_USED_PERCENT}%"),\"type\":\"text\",\"i18n\":{\"fa\":{\"label\":\"فضای استفاده‌شده‌ی دیسک اصلی\"}}},{\"key\":\"failed_services\",\"label\":\"Failed services\",\"value\":$(iranux_json_string "$FAILED_SERVICES"),\"type\":\"text\",\"i18n\":{\"fa\":{\"label\":\"سرویس‌های ناموفق\"}}}]}"
echo "__IRANUX_REACHED_END_V1__"
exit 0
