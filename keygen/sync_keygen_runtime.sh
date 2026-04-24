#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUNTIME_DIR="$SCRIPT_DIR"
BACKUP_DIR="$RUNTIME_DIR/backups"
DATA_DIR="$RUNTIME_DIR/data"
KEEP_BACKUPS="${KEYGEN_BACKUP_KEEP:-5}"

prune_old_backups() {
	if ! [[ "$KEEP_BACKUPS" =~ ^[0-9]+$ ]]; then
		echo "Invalid KEYGEN_BACKUP_KEEP: $KEEP_BACKUPS" >&2
		exit 1
	fi

	if [ "$KEEP_BACKUPS" -le 0 ]; then
		find "$BACKUP_DIR" -maxdepth 1 -type f -name 'keygen-runtime-data-*.tgz' -delete
		echo "Removed all runtime backups because KEYGEN_BACKUP_KEEP=$KEEP_BACKUPS"
		return
	fi

	local backup_files=()
	while IFS= read -r backup_file; do
		backup_files+=("$backup_file")
	done < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'keygen-runtime-data-*.tgz' | sort)

	local backup_count remove_count index
	backup_count="${#backup_files[@]}"
	if [ "$backup_count" -le "$KEEP_BACKUPS" ]; then
		return
	fi

	remove_count=$((backup_count - KEEP_BACKUPS))
	for ((index=0; index<remove_count; index++)); do
		rm -f "${backup_files[$index]}"
		echo "Removed old runtime backup ${backup_files[$index]}"
	done
}

backup_runtime_data() {
	mkdir -p "$BACKUP_DIR"

	if [ ! -d "$DATA_DIR" ]; then
		return
	fi

	if ! find "$DATA_DIR" -type f ! -name '.gitkeep' | grep -q .; then
		return
	fi

	local timestamp backup_file
	timestamp="$(date +%Y%m%d-%H%M%S)"
	backup_file="$BACKUP_DIR/keygen-runtime-data-$timestamp.tgz"

	tar czf "$backup_file" -C "$DATA_DIR" .
	echo "Backed up runtime data to $backup_file"
	prune_old_backups
}

backup_runtime_data

bash "$ROOT_DIR/source/keygen-source/refresh_keygen_layout.sh"

cd "$RUNTIME_DIR"
KEYGEN_PORT="${KEYGEN_PORT:-19090}" \
KEYGEN_CONTAINER_NAME="${KEYGEN_CONTAINER_NAME:-keygen-runtime}" \
bash "$RUNTIME_DIR/install-docker.sh"

echo "Source build info: $ROOT_DIR/source/keygen-source/BUILD_INFO.json"
echo "Runtime build info: $ROOT_DIR/soft/keygen/BUILD_INFO.json"