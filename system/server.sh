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
    # 1. Basic Package Installation
    echo
    read -rp "Do you want to install basic utility packages? (y/n, default: y): " install_pkgs_input
    local install_pkgs="${install_pkgs_input:-y}"

    if [[ "${install_pkgs,,}" =~ ^y|yes$ ]]; then
        echo
        log "INFO" "Installing packages: curl wget git ca-certificates net-tools sqlite3"
        (
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -y -qq >/dev/null 2>&1
            apt-get install -y -qq curl wget git ca-certificates net-tools sqlite3 >/dev/null 2>&1
        )
    else
        echo
        log "INFO" "Skipping basic package installation."
    fi

    # 2. User Management Prompt
    echo
    read -rp "Do you want to configure users (create admin/remove defaults)? (y/n, default: y): " configure_users_input
    local configure_users="${configure_users_input:-y}"

    local module_to_run="modules/users"

    case "${configure_users,,}" in
        y|yes)
            run_module "$module_to_run"
            ;;
        n|no|"")
            echo
            log "INFO" "Skipping User configuration."
            ;;
        *)
            echo
            log "WARN" "Invalid input ('${configure_users}'). Skipping **${module_to_run}**."
            ;;
    esac

    # 3. SSH Configuration Prompt
    echo
    read -rp "Do you want to configure SSH? (y/n, default: n): " configure_ssh

    local module_to_run="modules/ssh"

    case "${configure_ssh,,}" in
        y|yes)
            run_module "$module_to_run"
            ;;
        n|no|"")
            echo
            log "INFO" "Skipping SSH configuration."
            ;;
        *)
            echo
            log "WARN" "Invalid input ('${configure_ssh}'). Skipping **${module_to_run}**."
            ;;
    esac

    # 4. UFW Configuration Prompt
    echo
    read -rp "Do you want to configure UFW (Firewall)? (y/n, default: n): " configure_ufw_input
    local configure_ufw="${configure_ufw_input:-n}"

    local module_to_run="modules/ufw"

    case "${configure_ufw,,}" in
        y|yes)
            run_module "$module_to_run"
            ;;
        n|no|"")
            echo
            log "INFO" "Skipping UFW configuration."
            ;;
        *)
            echo
            log "WARN" "Invalid input ('${configure_ufw}'). Skipping **${module_to_run}**."
            ;;
    esac

    # 5. Docker Installation and Deployment Prompt
    echo
    read -rp "Do you want to install Docker and deploy the Compose files? (y/n, default: n): " configure_docker_input
    local configure_docker="${configure_docker_input:-n}"

    local module_to_run="modules/docker"

    case "${configure_docker,,}" in
        y|yes)
            run_module "$module_to_run"
            ;;
        n|no|"")
            echo
            log "INFO" "Skipping Docker configuration."
            ;;
        *)
            echo
            log "WARN" "Invalid input ('${configure_docker}'). Skipping **${module_to_run}**."
            ;;
    esac

    echo
    log "" "✨ Setup complete! Please reboot your system."
}

main
