#!/usr/bin/env bash

set -euo pipefail

readonly RED="\e[31m"
readonly GREEN="\e[32m"
readonly YELLOW="\e[33m"
readonly RESET="\e[0m"

readonly REPO_OWNER="MarcOrfilaCarreras"
readonly REPO_NAME="homelab"
readonly REPO_PATH="files/docker"
readonly GITHUB_API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/contents/${REPO_PATH}"

readonly DEPLOY_BASE_DIR="/opt"

# Create a secure temporary directory and ensure cleanup on exit
readonly TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

# --- Utility Functions ---

log() {
    # Function for standardized logging
    # $1: level (INFO, WARN, ERROR)
    # $2: message

    local level="$1"
    local message="$2"
    local color=""

    case "$level" in
        "INFO") color="$GREEN"; prefix="[i]";;
        "WARN") color="$YELLOW"; prefix="[!]" ;;
        "ERROR") color="$RED"; prefix="[x]";;
        *) color="$RESET"; prefix="[?]";;
    esac

    echo -e "${color}${prefix} ${message}${RESET}" >&2
}

install_dependencies() {
    # Install prereqs needed for the script logic (curl, jq) before doing anything else

    if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq >/dev/null 2>&1
        apt-get install -y -qq curl jq ca-certificates gnupg lsb-release >/dev/null 2>&1
    fi
}

# --- Main Configuration Steps ---

ensure_docker_installed() {
    if command -v docker >/dev/null 2>&1; then
        return 0
    fi

    echo
    log "WARN" "Docker not found. Starting installation..."

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    tee /etc/apt/sources.list.d/docker.sources <<EOF > /dev/null
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null 2>&1

    log "INFO" "Starting Docker service..."
    if [[ -d /run/systemd/system ]]; then
        systemctl start docker >/dev/null 2>&1 || log "WARN" "Failed to start Docker via systemd."
        systemctl enable docker >/dev/null 2>&1 || true
    fi
}

acquire_compose_files() {
    local local_repo_path="./${REPO_PATH}"

    local download_dest="${TEMP_DIR}/files/docker"
    mkdir -p "$download_dest"

    if [[ -d "$local_repo_path" ]]; then
        if [[ -n "$(find "$local_repo_path" -maxdepth 1 -type f -print -quit)" ]]; then
            cp "$local_repo_path"/* "$download_dest/"
            return 0
        fi
    fi

    local api_response
    if ! api_response=$(curl -fsSL "$GITHUB_API_URL"); then
        log "ERROR" "Failed to connect to GitHub API."
        return 1
    fi

    if ! echo "$api_response" | jq -e 'if type == "array" then true else false end' >/dev/null; then
        log "ERROR" "Invalid response from GitHub API (Rate limit or wrong path?)."
        return 1
    fi

    local download_count=0

    while read -r filename download_url; do
        if curl -fsSL "$download_url" -o "${download_dest}/${filename}"; then
            download_count=$((download_count + 1))
        else
            log "ERROR" "Failed to download $filename"
        fi
    done < <(echo "$api_response" | jq -r '.[] | select(.type == "file") | .name + " " + .download_url')

    if [[ "$download_count" -eq 0 ]]; then
        log "ERROR" "No files were downloaded."
        return 1
    fi
}

deploy_stacks() {
    local source_dir="${TEMP_DIR}/files/docker"

    if ! find "$source_dir" -maxdepth 1 -type f -exec true \; -quit 2>/dev/null; then
        log "WARN" "No Docker Compose files found to deploy."
        return 0
    fi

    if ! mkdir -p "$DEPLOY_BASE_DIR"; then
        log "ERROR" "Failed to create deployment base: $DEPLOY_BASE_DIR"
        return 1
    fi

    if ! find "$source_dir" -maxdepth 1 -type f -exec true \; -quit 2>/dev/null; then
        log "WARN" "No Compose files found in ${source_dir}. Skipping deployment prompt."
        return 0
    fi

    find "$source_dir" -maxdepth 1 -type f -print0 | while IFS= read -r -d $'\0' source_file; do
        local filename=$(basename "$source_file")
        local deploy_stack_input=""

        echo
        read -rp "Do you want to deploy the compose file **${filename}**? (y/n): " deploy_stack_input < /dev/tty

        if [[ "${deploy_stack_input,,}" =~ ^y|yes$ ]]; then
            local service_name="${filename%.*}"
            local deploy_dir="${DEPLOY_BASE_DIR}/${service_name}"

            if ! mkdir -p "$deploy_dir"; then
                echo
                log "ERROR" "Failed to create service directory: ${deploy_dir}"
                continue
            fi

            local final_compose_path="${deploy_dir}/docker-compose.yml"
            if ! cp "$source_file" "$final_compose_path"; then
                echo
                log "ERROR" "Failed to copy and rename file to ${final_compose_path}."
                continue
            fi

            (
                cd "$deploy_dir" || exit 1

                local COMPOSE_CMD
                if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
                    COMPOSE_CMD="docker compose"
                else
                    echo
                    log "ERROR" "Docker Compose command not found. Skipping deployment."
                    exit 1
                fi

                if ! $COMPOSE_CMD up -d >/dev/null 2>&1; then
                    echo
                    log "ERROR" "Deployment failed for **${service_name}**. Check logs."
                fi
            )

        else
            echo
            log "INFO" "Skipping deployment for **${filename}**."
        fi
    done
}

# --- Main Execution ---

main() {
    install_dependencies
    ensure_docker_installed
    acquire_compose_files
    deploy_stacks
}

main
