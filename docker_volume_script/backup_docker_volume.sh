#!/usr/bin/env bash
set -euo pipefail

# Simple backup of Docker named volumes using rsync.

command -v rsync  >/dev/null 2>&1 || { echo "Error: rsync is not installed." >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "Error: docker is not installed." >&2; exit 1; }
command -v du     >/dev/null 2>&1 || { echo "Error: du is not installed." >&2; exit 1; }

if [ "$(id -u)" -ne 0 ]; then echo "Please run as root." >&2; exit 1; fi

DEST_ROOT="${1:-/backup/docker-volumes}"
TS="$(date +%Y%m%d-%H%M%S)"

DOCKER_ROOT="$(docker info --format '{{.DockerRootDir}}')"
VOLUMES_DIR="${DOCKER_ROOT}/volumes"
DEST="${DEST_ROOT}/${TS}"

mkdir -p "${DEST}"

for vol in $(docker volume ls -q); do
  src="${VOLUMES_DIR}/${vol}/_data"
  if [[ -d "${src}" ]]; then
    mkdir -p "${DEST}/${vol}"
    rsync -a --delete --info=progress2 "${src}/" "${DEST}/${vol}/"
  fi
done

SIZE="$(du -sh "${DEST}" | awk '{print $1}')"

echo "Backup created at: ${DEST}"
echo "Backup size: ${SIZE}"
echo
echo "Restore SINGLE volume command:"
echo "sudo rsync -a --delete ${DEST}/<VOLUME_NAME>/ \"${DOCKER_ROOT}/volumes/<VOLUME_NAME>/_data/\""
echo "--------------------------------"
# Keep only the 2 most recent backups
echo "Cleaning old backups (keeping last 2)..."
ls -1dt "${DEST_ROOT}/"* | tail -n +3 | xargs -r rm -rf
echo "Old backups cleaned."
