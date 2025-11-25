#!/usr/bin/env bash

set -euo pipefail

readonly REPO_BASE="https://raw.githubusercontent.com/MarcOrfilaCarreras/homelab/master"

readonly RED="\e[31m"
readonly GREEN="\e[32m"
readonly YELLOW="\e[33m"
readonly RESET="\e[0m"

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

download_module() {
    # Downloads a module from the repo or copies it from local file system.
    # $1: module path (e.g., "modules/ssh")
    # Returns: The path to the executable module, or error if failed.

    local module_path="$1"
    local local_file="./${module_path}.sh"
    local remote_url="${REPO_BASE}/${module_path}.sh"
    local destination_file="/tmp/${module_path}.sh"

    if ! mkdir -p "$(dirname "$destination_file")"; then
        log "ERROR" "Failed to create directory: $(dirname "$destination_file")"
        return 1
    fi

    # Check for local file first
    if [[ -f "$local_file" ]]; then
        if ! cp "$local_file" "$destination_file"; then
            log "ERROR" "Failed to copy local module: ${local_file}"
            return 1
        fi
    else
        if ! curl -fsSL "$remote_url" -o "$destination_file"; then
            log "ERROR" "Failed to download module from ${remote_url}"
            return 1
        fi
    fi

    if ! chmod +x "$destination_file"; then
        log "ERROR" "Failed to make module executable: ${module_path}"
        return 1
    fi

    printf "%s" "$destination_file"
}

run_module() {
    # Executes a module script.
    # $1: module path (e.g., "modules/ssh")

    local module="$1"
    local script_path

    echo -e "\n${GREEN}▶ Running ${module}${RESET}"
    script_path=$(download_module "$module") || return 1
    "$script_path"
}

# --- Main Execution ---

main() {
    # 1. Caddy Installation Prompt
    echo
    read -rp "Do you want to install Caddy? (y/n, default: n): " install_caddy_input
    local install_caddy="${install_caddy_input:-n}"

    local module_to_run="modules/apps/caddy"

    case "${install_caddy,,}" in
        y|yes)
            run_module "$module_to_run"
            ;;
        n|no|"")
            echo
            log "INFO" "Skipping Caddy installation."
            ;;
        *)
            echo
            log "WARN" "Invalid input ('${install_caddy}'). Skipping **${module_to_run}**."
            ;;
    esac
}

main
