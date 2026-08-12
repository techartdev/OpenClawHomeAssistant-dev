#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# oc-health — publish OpenClaw add-on health as Home Assistant sensors
#
# Pushes a handful of states to the Home Assistant REST API so users can build
# automations/alerts on gateway health instead of watching the add-on log.
#
# Usage:
#   oc-health show    Print what would be published (no token needed)
#   oc-health once    Publish one round of states
#   oc-health loop    Publish every HA_HEALTH_INTERVAL seconds (used by run.sh)
#
# Deliberately implemented as a short bash + curl round rather than a resident
# process: on a 1 GB Pi an idle Node/Python daemon costs more than the work.
# ──────────────────────────────────────────────────────────────
# NOTE: no `set -e` — a transient HA/API failure must never kill the loop.
set -uo pipefail

HA_TOKEN_FILE="${HA_TOKEN_FILE:-/config/secrets/homeassistant.token}"
OPENCLAW_CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-/config/.openclaw/openclaw.json}"
CERT_PATH="${CERT_PATH:-/config/certs/gateway.crt}"
INTERVAL="${HA_HEALTH_INTERVAL:-60}"

# Context passed in by run.sh (all optional — `oc-health` also works standalone).
ADDON_VERSION="${ADDON_VERSION:-unknown}"
ACCESS_MODE="${ACCESS_MODE:-custom}"
GATEWAY_BIND_MODE="${GATEWAY_BIND_MODE:-loopback}"
GATEWAY_INTERNAL_PORT="${GATEWAY_INTERNAL_PORT:-18789}"
RESOURCE_PROFILE="${RESOURCE_PROFILE:-auto}"
NODE_HEAP_MB="${NODE_HEAP_MB:-}"
ENABLE_HTTPS_PROXY="${ENABLE_HTTPS_PROXY:-false}"

CURL_RC=""
HA_API=""

cleanup() {
  [ -n "$CURL_RC" ] && rm -f "$CURL_RC"
}
trap cleanup EXIT INT TERM

# ── Credentials ──────────────────────────────────────────────
# Prefer the Supervisor proxy when the add-on has API access; otherwise fall
# back to the user's long-lived token against the host's HA instance
# (reachable on localhost because the add-on runs with host_network: true).
resolve_api() {
  local token=""

  if [ -n "${SUPERVISOR_TOKEN:-}" ]; then
    token="$SUPERVISOR_TOKEN"
    HA_API="http://supervisor/core/api"
  elif [ -r "$HA_TOKEN_FILE" ]; then
    token="$(cat "$HA_TOKEN_FILE" 2>/dev/null || true)"
    HA_API="${HA_BASE_URL:-http://localhost:8123}/api"
  fi

  if [ -z "$token" ]; then
    return 1
  fi

  # Reject anything that could break out of the curl config quoting.
  case "$token" in
    *\"*|*$'\n'*|*$'\r'*)
      echo "ERROR: Home Assistant token contains invalid characters; refusing to use it." >&2
      return 1
      ;;
  esac

  # Pass the token via a 0600 config file so it never appears in `ps` / argv.
  local previous_umask
  previous_umask="$(umask)"
  umask 077
  CURL_RC="$(mktemp /tmp/.oc-health-XXXXXX)" || { umask "$previous_umask"; return 1; }
  printf 'header = "Authorization: Bearer %s"\nheader = "Content-Type: application/json"\n' \
    "$token" > "$CURL_RC"
  umask "$previous_umask"
  return 0
}

# ── Metric collection ────────────────────────────────────────
gateway_pid() {
  local pid=""
  if command -v ss >/dev/null 2>&1; then
    pid=$(ss -tlnp 2>/dev/null \
      | grep ":${GATEWAY_INTERNAL_PORT} " \
      | sed -n 's/.*pid=\([0-9]*\).*/\1/p' \
      | head -1)
  fi
  if [ -z "$pid" ]; then
    pid=$(pgrep -f "openclaw-gateway" 2>/dev/null | head -1)
  fi
  printf '%s' "${pid:-}"
}

openclaw_version() {
  openclaw --version 2>/dev/null | head -n 1 \
    | grep -oE '[0-9]{4}\.[0-9]+\.[0-9]+(-[0-9]+)?' | head -n 1
}

# Resident set size of the gateway process, in MB.
gateway_rss_mb() {
  local pid="$1" rss_kb=""
  [ -n "$pid" ] || return 0
  rss_kb=$(awk '/^VmRSS:/{print $2}' "/proc/${pid}/status" 2>/dev/null)
  [ -n "$rss_kb" ] && printf '%d' $((rss_kb / 1024))
}

cert_days_remaining() {
  [ -r "$CERT_PATH" ] || return 0
  local end_date end_epoch now_epoch
  end_date=$(openssl x509 -enddate -noout -in "$CERT_PATH" 2>/dev/null | cut -d= -f2)
  [ -n "$end_date" ] || return 0
  end_epoch=$(date -d "$end_date" +%s 2>/dev/null) || return 0
  now_epoch=$(date +%s)
  printf '%d' $(( (end_epoch - now_epoch) / 86400 ))
}

# ── Publishing ───────────────────────────────────────────────
post_state() {
  local entity="$1" state="$2" attrs="$3" payload code

  payload=$(jq -nc --arg s "$state" --argjson a "$attrs" '{state: $s, attributes: $a}' 2>/dev/null)
  if [ -z "$payload" ]; then
    echo "WARN: Could not build payload for ${entity}" >&2
    return 1
  fi

  if [ "$MODE" = "show" ]; then
    printf '%s -> %s\n' "$entity" "$payload"
    return 0
  fi

  code=$(curl -sS -m 10 -o /dev/null -w '%{http_code}' -K "$CURL_RC" \
    -X POST "${HA_API}/states/${entity}" -d "$payload" 2>/dev/null)

  case "$code" in
    200|201) return 0 ;;
    401|403)
      echo "WARN: Home Assistant rejected the token (HTTP ${code}) while updating ${entity}" >&2
      return 1
      ;;
    *)
      echo "WARN: Could not update ${entity} (HTTP ${code:-no response})" >&2
      return 1
      ;;
  esac
}

publish_round() {
  local pid state rss version disk_pct disk_total disk_used disk_avail cert_days

  pid="$(gateway_pid)"
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    state="running"
  else
    state="stopped"
    pid=""
  fi

  post_state "sensor.openclaw_gateway" "$state" "$(jq -nc \
    --arg pid "${pid:-}" \
    --arg bind "$GATEWAY_BIND_MODE" \
    --arg access "$ACCESS_MODE" \
    --arg port "$GATEWAY_INTERNAL_PORT" \
    --arg profile "$RESOURCE_PROFILE" \
    '{friendly_name: "OpenClaw Gateway", icon: "mdi:robot",
      pid: $pid, bind_mode: $bind, access_mode: $access,
      port: $port, resource_profile: $profile}')"

  version="$(openclaw_version)"
  post_state "sensor.openclaw_version" "${version:-unknown}" "$(jq -nc \
    --arg addon "$ADDON_VERSION" \
    '{friendly_name: "OpenClaw Version", icon: "mdi:tag-outline", addon_version: $addon}')"

  rss="$(gateway_rss_mb "$pid")"
  if [ -n "$rss" ]; then
    post_state "sensor.openclaw_gateway_memory" "$rss" "$(jq -nc \
      --arg cap "${NODE_HEAP_MB:-unlimited}" \
      --arg profile "$RESOURCE_PROFILE" \
      '{friendly_name: "OpenClaw Gateway Memory", icon: "mdi:memory",
        unit_of_measurement: "MB", state_class: "measurement",
        heap_limit_mb: $cap, resource_profile: $profile}')"
  fi

  if df -h /config >/dev/null 2>&1; then
    disk_total=$(df -h /config | awk 'NR==2{print $2}')
    disk_used=$(df -h /config  | awk 'NR==2{print $3}')
    disk_avail=$(df -h /config | awk 'NR==2{print $4}')
    disk_pct=$(df -h /config   | awk 'NR==2{gsub(/%/,"",$5); print $5}')
    post_state "sensor.openclaw_disk_used" "${disk_pct:-0}" "$(jq -nc \
      --arg total "$disk_total" --arg used "$disk_used" --arg avail "$disk_avail" \
      '{friendly_name: "OpenClaw Disk Used", icon: "mdi:harddisk",
        unit_of_measurement: "%", state_class: "measurement",
        total: $total, used: $used, available: $avail}')"
  fi

  if [ "$ENABLE_HTTPS_PROXY" = "true" ]; then
    cert_days="$(cert_days_remaining)"
    if [ -n "$cert_days" ]; then
      post_state "sensor.openclaw_certificate_expiry" "$cert_days" "$(jq -nc \
        '{friendly_name: "OpenClaw Certificate Expiry", icon: "mdi:certificate",
          unit_of_measurement: "d", state_class: "measurement"}')"
    fi
  fi
}

# ── Entry point ──────────────────────────────────────────────
MODE="${1:-once}"

case "$MODE" in
  show)
    publish_round
    exit 0
    ;;
  once|loop)
    if ! resolve_api; then
      echo "INFO: oc-health needs a Home Assistant token."
      echo "INFO: Set 'homeassistant_token' in the add-on Configuration and restart."
      echo "INFO: Run 'oc-health show' to preview the states without publishing."
      exit 1
    fi
    ;;
  help|-h|--help)
    cat <<'EOF'
Usage: oc-health <show|once|loop>

show   Print the states that would be published (no token required)
once   Publish a single round of states to Home Assistant
loop   Publish every HA_HEALTH_INTERVAL seconds (default 60)

Entities published:
  sensor.openclaw_gateway             running / stopped
  sensor.openclaw_version             OpenClaw runtime version
  sensor.openclaw_gateway_memory      gateway RSS in MB
  sensor.openclaw_disk_used           /config usage in %
  sensor.openclaw_certificate_expiry  days left (lan_https only)
EOF
    exit 0
    ;;
  *)
    echo "Unknown command: $MODE" >&2
    echo "Run: oc-health help" >&2
    exit 2
    ;;
esac

if [ "$MODE" = "once" ]; then
  publish_round
  exit 0
fi

# Sanity-clamp the interval so a bad option can't busy-loop the CPU.
if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [ "$INTERVAL" -lt 15 ]; then
  echo "WARN: Invalid ha_health_interval '${INTERVAL}'; using 60s" >&2
  INTERVAL=60
fi

echo "INFO: Publishing OpenClaw health sensors to Home Assistant every ${INTERVAL}s"
while true; do
  publish_round
  sleep "$INTERVAL"
done
