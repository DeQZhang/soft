#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
FIXED_PORT="19090"

cleanup_port_conflicts() {
	local ids=""

	ids="$(docker ps -q --filter "publish=${FIXED_PORT}" 2>/dev/null || true)"
	if [ -n "$ids" ]; then
		echo "removing containers using port ${FIXED_PORT}: $ids"
		docker rm -f $ids >/dev/null 2>&1 || true
	fi

	if command -v lsof >/dev/null 2>&1; then
		ids="$(lsof -ti tcp:"${FIXED_PORT}" 2>/dev/null || true)"
		if [ -n "$ids" ]; then
			kill $ids >/dev/null 2>&1 || true
			ids="$(lsof -ti tcp:"${FIXED_PORT}" 2>/dev/null || true)"
			if [ -n "$ids" ]; then
				kill -9 $ids >/dev/null 2>&1 || true
			fi
		fi
	fi
}

mkdir -p data
docker compose down --remove-orphans >/dev/null 2>&1 || true
cleanup_port_conflicts
KEYGEN_PORT="${KEYGEN_PORT:-19090}" docker compose up -d --build --remove-orphans
printf 'keygen source docker started: http://127.0.0.1:%s\n' "${KEYGEN_PORT:-19090}"
