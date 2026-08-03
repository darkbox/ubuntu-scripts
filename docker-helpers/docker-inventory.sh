#!/usr/bin/env bash

set -Eeuo pipefail

OUTPUT_DIR="${1:-docker-inventory-$(date +%Y%m%d-%H%M%S)}"

log() {
    printf '[INFO] %s\n' "$*"
}

error() {
    printf '[ERROR] %s\n' "$*" >&2
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

require_command() {
    if ! command_exists "$1"; then
        error "Required command not found: $1"
        exit 1
    fi
}

sanitize_filename() {
    printf '%s' "$1" | tr '/[:space:]' '__'
}

require_command docker

if ! docker info >/dev/null 2>&1; then
    error "Docker is not accessible. Check that the daemon is running and your user has permission."
    exit 1
fi

mkdir -p \
    "$OUTPUT_DIR/containers" \
    "$OUTPUT_DIR/images" \
    "$OUTPUT_DIR/networks" \
    "$OUTPUT_DIR/volumes"

log "Writing inventory to: $OUTPUT_DIR"

docker version > "$OUTPUT_DIR/docker-version.txt"
docker info > "$OUTPUT_DIR/docker-info.txt"

docker ps -a --no-trunc > "$OUTPUT_DIR/containers.txt"
docker image ls --no-trunc > "$OUTPUT_DIR/images.txt"
docker network ls --no-trunc > "$OUTPUT_DIR/networks.txt"
docker volume ls > "$OUTPUT_DIR/volumes.txt"

docker ps -aq | while read -r container_id; do
    [[ -n "$container_id" ]] || continue

    container_name="$(
        docker inspect \
            --format '{{.Name}}' \
            "$container_id" | sed 's#^/##'
    )"

    safe_name="$(sanitize_filename "$container_name")"
    container_dir="$OUTPUT_DIR/containers/$safe_name"

    mkdir -p "$container_dir"

    log "Inspecting container: $container_name"

    docker inspect "$container_id" > "$container_dir/inspect.json"

    docker inspect \
        --format '{{json .Config.Env}}' \
        "$container_id" > "$container_dir/environment.json"

    docker inspect \
        --format '{{json .Mounts}}' \
        "$container_id" > "$container_dir/mounts.json"

    docker inspect \
        --format '{{json .NetworkSettings.Networks}}' \
        "$container_id" > "$container_dir/networks.json"

    docker inspect \
        --format '{{json .NetworkSettings.Ports}}' \
        "$container_id" > "$container_dir/ports.json"

    docker inspect \
        --format '{{json .HostConfig}}' \
        "$container_id" > "$container_dir/host-config.json"

    docker inspect \
        --format '{{json .Config.Healthcheck}}' \
        "$container_id" > "$container_dir/healthcheck.json"

    docker inspect \
        --format '{{json .Config.Labels}}' \
        "$container_id" > "$container_dir/labels.json"

    docker inspect \
        --format '{{.Config.Image}}' \
        "$container_id" > "$container_dir/image.txt"

    docker inspect \
        --format '{{json .Config.Entrypoint}}' \
        "$container_id" > "$container_dir/entrypoint.json"

    docker inspect \
        --format '{{json .Config.Cmd}}' \
        "$container_id" > "$container_dir/command.json"

    docker inspect \
        --format '{{.HostConfig.RestartPolicy.Name}}' \
        "$container_id" > "$container_dir/restart-policy.txt"

    docker inspect \
        --format '{{.Config.User}}' \
        "$container_id" > "$container_dir/user.txt"

    docker inspect \
        --format '{{.Config.WorkingDir}}' \
        "$container_id" > "$container_dir/working-directory.txt"

    docker inspect \
        --format '{{.Config.Hostname}}' \
        "$container_id" > "$container_dir/hostname.txt"

    docker inspect \
        --format '{{json .HostConfig.Devices}}' \
        "$container_id" > "$container_dir/devices.json"

    docker inspect \
        --format '{{json .HostConfig.CapAdd}}' \
        "$container_id" > "$container_dir/cap-add.json"

    docker inspect \
        --format '{{json .HostConfig.CapDrop}}' \
        "$container_id" > "$container_dir/cap-drop.json"

    docker inspect \
        --format '{{.HostConfig.Privileged}}' \
        "$container_id" > "$container_dir/privileged.txt"
done

docker image ls -q --no-trunc | sort -u | while read -r image_id; do
    [[ -n "$image_id" ]] || continue

    safe_id="$(sanitize_filename "$image_id")"
    log "Inspecting image: $image_id"

    docker image inspect "$image_id" \
        > "$OUTPUT_DIR/images/$safe_id.json"
done

docker network ls -q | while read -r network_id; do
    [[ -n "$network_id" ]] || continue

    network_name="$(
        docker network inspect \
            --format '{{.Name}}' \
            "$network_id"
    )"

    safe_name="$(sanitize_filename "$network_name")"
    log "Inspecting network: $network_name"

    docker network inspect "$network_id" \
        > "$OUTPUT_DIR/networks/$safe_name.json"
done

docker volume ls -q | while read -r volume_name; do
    [[ -n "$volume_name" ]] || continue

    safe_name="$(sanitize_filename "$volume_name")"
    log "Inspecting volume: $volume_name"

    docker volume inspect "$volume_name" \
        > "$OUTPUT_DIR/volumes/$safe_name.json"
done

{
    printf 'Docker inventory\n'
    printf 'Generated: %s\n' "$(date --iso-8601=seconds 2>/dev/null || date)"
    printf 'Hostname: %s\n' "$(hostname)"
    printf '\n'

    printf 'Containers: %s\n' "$(docker ps -aq | wc -l)"
    printf 'Running containers: %s\n' "$(docker ps -q | wc -l)"
    printf 'Images: %s\n' "$(docker image ls -q | sort -u | wc -l)"
    printf 'Networks: %s\n' "$(docker network ls -q | wc -l)"
    printf 'Volumes: %s\n' "$(docker volume ls -q | wc -l)"
} > "$OUTPUT_DIR/summary.txt"

if command_exists tar; then
    archive="${OUTPUT_DIR}.tar.gz"

    log "Creating archive: $archive"
    tar -czf "$archive" "$OUTPUT_DIR"

    log "Inventory completed: $archive"
else
    log "Inventory completed: $OUTPUT_DIR"
    log "The tar command was not found, so no compressed archive was created."
fi
