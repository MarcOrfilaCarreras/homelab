#!/usr/bin/env bash

set -euo pipefail

readonly RED="\e[31m"
readonly GREEN="\e[32m"
readonly YELLOW="\e[33m"
readonly RESET="\e[0m"

readonly CADDY_DOWNLOAD_URL="https://caddyserver.com/api/download?os=linux&arch=amd64&p=github.com%2Fcaddy-dns%2Fcloudflare&idempotency=81625310887894"
readonly CADDY_BIN_PATH="/usr/local/bin/caddy"
readonly CADDY_ETC_PATH="/etc/caddy"
readonly CADDY_SSL_PATH="/etc/ssl/caddy"
readonly CADDY_SERVICE_PATH="/lib/systemd/system"
readonly CADDY_CONFIG_FILE="${CADDY_ETC_PATH}/Caddyfile"

readonly REPO_OWNER="MarcOrfilaCarreras"
readonly REPO_NAME="homelab"
readonly REPO_PATH="files/caddy"
readonly GITHUB_API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/contents/${REPO_PATH}"

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
    # Ensure curl and libcap2-bin are installed

    if ! command -v curl >/dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq curl >/dev/null 2>&1
    fi

    if ! command -v setcap >/dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq libcap2-bin >/dev/null 2>&1
    fi
}

# --- Main Configuration Steps ---

install_caddy_binary() {
    local temp_file
    temp_file=$(mktemp)

    if ! curl -fsSL "$CADDY_DOWNLOAD_URL" -o "$temp_file"; then
        log "ERROR" "Failed to download Caddy binary."
        return 1
    fi

    if ! mv "$temp_file" "$CADDY_BIN_PATH"; then
        log "ERROR" "Failed to move Caddy binary. Check the downloaded URL/file format."
        rm -f "$temp_file"
        return 1
    fi

    rm -f "$temp_file"
    chmod a+x "$CADDY_BIN_PATH"
    setcap 'cap_net_bind_service+ep' "$CADDY_BIN_PATH"

    log "SUCCESS" "Caddy binary installed and configured."
}

configure_directories() {
    mkdir -p "$CADDY_ETC_PATH"
    chown root:root "$CADDY_ETC_PATH"

    mkdir -p "$CADDY_SSL_PATH"
    chown root:root "$CADDY_SSL_PATH"
    chmod 0770 "$CADDY_SSL_PATH"
}

acquire_config_files() {
    local local_repo_path="./${REPO_PATH}"

    local download_dest="${TEMP_DIR}/files/caddy"
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

install_config_files() {
    local source_dir="${TEMP_DIR}/files/caddy"

    if ! find "$source_dir" -maxdepth 1 -type f -exec true \; -quit 2>/dev/null; then
        log "WARN" "No config files found."
        return 0
    fi

    find "$source_dir" -maxdepth 1 -type f -print0 | while IFS= read -r -d $'\0' source_file; do
        local filename=$(basename "$source_file")
        local copy_file_input=""

        echo
        read -rp "Do you want to copy the config file **${filename}**? (y/n): " copy_file_input < /dev/tty

        if [[ "${copy_file_input,,}" =~ ^y|yes$ ]]; then
            if [[ "${filename}" =~ Caddyfile ]]; then
                local final_config_path="${CADDY_ETC_PATH}/Caddyfile"
                if ! cp "$source_file" "$final_config_path"; then
                    echo
                    log "ERROR" "Failed to copy and rename file to ${final_config_path}."
                    continue
                fi
            fi

            if [[ "${filename}" =~ caddy.service ]]; then
                local final_config_path="${CADDY_SERVICE_PATH}/caddy.service"
                if ! cp "$source_file" "$final_config_path"; then
                    echo
                    log "ERROR" "Failed to copy and rename file to ${final_config_path}."
                    continue
                fi
            fi
        else
            echo
            log "INFO" "Skipping config file **${filename}**."
        fi
    done

    if [[ -d /run/systemd/system ]]; then
        systemctl daemon-reload >/dev/null 2>&1 || log "WARN" "Failed to reload the daemon."
        systemctl enable caddy  >/dev/null 2>&1 || log "WARN" "Failed to enable Caddy via systemd."
        systemctl restart caddy  >/dev/null 2>&1 || log "WARN" "Failed to restart Caddy via systemd."
    fi
}

# --- Main Execution ---

main() {
    install_dependencies

    echo
    install_caddy_binary
    configure_directories
    acquire_config_files
    install_config_files
}

main
