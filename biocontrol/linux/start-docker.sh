#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$0")" && pwd)"
  FIXED_PUBLISHED_PORT="18080"

gen_password() { LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24 2>/dev/null || true; }
normalize_mac() { echo "$1" | tr '[:lower:]' '[:upper:]'; }
is_valid_mac() { [[ "$1" =~ ^([0-9A-F]{2}:){5}[0-9A-F]{2}$ ]] && [[ "$1" != "00:00:00:00:00:00" ]]; }
  set_env_value() {
    local key="$1"
    local value="$2"
    if grep -q "^${key}=" .env 2>/dev/null; then
      sed -i.bak "s|^${key}=.*|${key}=${value}|" .env && rm -f .env.bak
    else
      printf '\n%s=%s\n' "$key" "$value" >> .env
    fi
  }
  cleanup_port_conflicts() {
    local ids=""
    ids="$(docker ps -q --filter "publish=${FIXED_PUBLISHED_PORT}" 2>/dev/null || true)"
    if [ -n "$ids" ]; then
      docker rm -f $ids >/dev/null 2>&1 || true
    fi
    if command -v lsof >/dev/null 2>&1; then
      ids="$(lsof -ti tcp:${FIXED_PUBLISHED_PORT} 2>/dev/null || true)"
      if [ -n "$ids" ]; then
        kill $ids >/dev/null 2>&1 || true
        ids="$(lsof -ti tcp:${FIXED_PUBLISHED_PORT} 2>/dev/null || true)"
        if [ -n "$ids" ]; then
          kill -9 $ids >/dev/null 2>&1 || true
        fi
      fi
    fi
  }
detect_physical_address() {
  local mac=""
  local dev=""
  if command -v ip >/dev/null 2>&1; then
    dev="$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')"
    if [ -n "$dev" ] && [ -r "/sys/class/net/${dev}/address" ]; then
      mac="$(normalize_mac "$(tr -d '\n' < "/sys/class/net/${dev}/address")")"
      if is_valid_mac "$mac"; then echo "$mac"; return 0; fi
    fi
  fi
  if [ -d /sys/class/net ]; then
    for path in /sys/class/net/*/address; do
      [ -r "$path" ] || continue
      dev="$(basename "$(dirname "$path")")"
      case "$dev" in lo|docker*|br-*|veth*|virbr*|zt*|tailscale*|wg*) continue ;; esac
      mac="$(normalize_mac "$(tr -d '\n' < "$path")")"
      if is_valid_mac "$mac"; then echo "$mac"; return 0; fi
    done
  fi
  if command -v ifconfig >/dev/null 2>&1; then
    mac="$(ifconfig 2>/dev/null | awk '
      /^[A-Za-z0-9]/ { iface=$1; sub(":", "", iface) }
      /ether / {
        if (iface != "lo" && iface !~ /^docker/ && iface !~ /^bridge/ && iface !~ /^veth/ && iface !~ /^utun/ && iface !~ /^awdl/) {
          print toupper($2)
          exit
        }
      }
    ')"
    if is_valid_mac "$mac"; then echo "$mac"; return 0; fi
  fi
  return 1
}

if [ ! -f .env ]; then
  db_pass="$(gen_password)"
  root_pass="$(gen_password)"
  sed -e "s/BIOCONTROL_DB_PASSWORD=AUTO_GENERATED/BIOCONTROL_DB_PASSWORD=${db_pass}/" \
      -e "s/BIOCONTROL_MYSQL_ROOT_PASSWORD=AUTO_GENERATED/BIOCONTROL_MYSQL_ROOT_PASSWORD=${root_pass}/" \
      .env.example > .env
fi

    set_env_value "BIOCONTROL_FRONTEND_PUBLISHED_PORT" "$FIXED_PUBLISHED_PORT"

if ! grep -q '^BIOCONTROL_LICENSE_PHYSICAL_ADDRESS=' .env 2>/dev/null; then
  printf '\nBIOCONTROL_LICENSE_PHYSICAL_ADDRESS=\n' >> .env
fi

mac="$(grep -E '^BIOCONTROL_LICENSE_PHYSICAL_ADDRESS=' .env | tail -n1 | cut -d= -f2-)"
mac="$(normalize_mac "$mac")"
if ! is_valid_mac "$mac"; then
  detected="$(detect_physical_address || true)"
  if is_valid_mac "$detected"; then
    sed -i.bak "s|^BIOCONTROL_LICENSE_PHYSICAL_ADDRESS=.*|BIOCONTROL_LICENSE_PHYSICAL_ADDRESS=${detected}|" .env && rm -f .env.bak
  fi
fi

docker compose down --remove-orphans >/dev/null 2>&1 || true
cleanup_port_conflicts
docker compose up --build -d --remove-orphans
docker compose ps
