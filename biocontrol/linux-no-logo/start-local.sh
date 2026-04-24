#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$0")" && pwd)"
[ -f .env.local ] || cp .env.local.example .env.local
  if grep -q '^BIOCONTROL_HTTP_PORT=' .env.local 2>/dev/null; then
    sed -i.bak 's/^BIOCONTROL_HTTP_PORT=.*/BIOCONTROL_HTTP_PORT=18080/' .env.local && rm -f .env.local.bak
  else
    printf '\nBIOCONTROL_HTTP_PORT=18080\n' >> .env.local
  fi
  if [ -f biocontrol.pid ] && kill -0 "$(cat biocontrol.pid)" >/dev/null 2>&1; then
    kill "$(cat biocontrol.pid)" >/dev/null 2>&1 || true
    rm -f biocontrol.pid
  fi
  if command -v lsof >/dev/null 2>&1; then
    port_pids="$(lsof -ti tcp:18080 2>/dev/null || true)"
    if [ -n "$port_pids" ]; then
      kill $port_pids >/dev/null 2>&1 || true
      port_pids="$(lsof -ti tcp:18080 2>/dev/null || true)"
      if [ -n "$port_pids" ]; then
        kill -9 $port_pids >/dev/null 2>&1 || true
      fi
    fi
  fi
mkdir -p logs
nohup bash ./start-local-foreground.sh > logs/biocontrol.log 2>&1 &
echo $! > biocontrol.pid
echo "Started BioControl locally, PID=$(cat biocontrol.pid)"
