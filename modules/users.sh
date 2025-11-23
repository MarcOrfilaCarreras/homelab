#!/usr/bin/env bash

set -euo pipefail

readonly RED="\e[31m"
readonly GREEN="\e[32m"
readonly YELLOW="\e[33m"
readonly RESET="\e[0m"

readonly DEFAULT_SHELL="/bin/bash"

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
    # Ensure OpenSSL is installed for password hashing

    if ! command -v openssl >/dev/null 2>&1; then
        echo
        log "WARN" "OpenSSL not found. Installing..."
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq openssl >/dev/null 2>&1
    fi
}

get_sudo_group() {
    # Determine the correct sudo group (sudo vs wheel)

    if getent group sudo >/dev/null 2>&1; then
        echo "sudo"
    elif getent group wheel >/dev/null 2>&1; then
        echo "wheel"
    else
        log "WARN" "Neither 'sudo' nor 'wheel' group found. Creating 'sudo' group."
        groupadd -f sudo
        echo "sudo"
    fi
}

# --- Main Configuration Steps ---

get_user_credentials() {
    local username_input

    echo
    while true; do
        read -rp "Enter new admin username [default: admin]: " username_input
        NEW_USER="${username_input:-admin}"

        # Validate username (lowercase, numbers, dashes, no spaces)
        if [[ "$NEW_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
            break
        else
            log "WARN" "Invalid username. Use lowercase letters, numbers, and underscores only."
        fi
    done

    while true; do
        echo
        read -rsp "Enter password for ${NEW_USER}: " password_input
        echo
        read -rsp "Confirm password for ${NEW_USER}: " password_confirm
        echo

        if [[ "$password_input" == "$password_confirm" ]] && [[ -n "$password_input" ]]; then
            break
        else
            echo
            log "WARN" "Passwords do not match or cannot be empty. Try again."
        fi
    done

    # Generate SHA-512 password hash
    NEW_PASSWORD_HASH=$(openssl passwd -6 "$password_input")

    echo
    read -rp "Enter SSH Public Key (leave blank for none): " pubkey_input
    NEW_PUBLIC_KEY="${pubkey_input}"
}

create_user_and_group() {
    local sudo_group
    sudo_group=$(get_sudo_group)

    # 1. Create Primary Group
    if ! getent group "$NEW_USER" >/dev/null 2>&1; then
        groupadd "$NEW_USER"
    fi

    # 2. Create or Update User
    if id -u "$NEW_USER" >/dev/null 2>&1; then
        usermod -a -G "$sudo_group" "$NEW_USER"
        echo "$NEW_USER:$NEW_PASSWORD_HASH" | chpasswd -e
    else
        local user_shell="$DEFAULT_SHELL"
        if [[ ! -x "$user_shell" ]]; then
            log "WARN" "$user_shell not found, falling back to /bin/sh"
            user_shell="/bin/sh"
        fi

        useradd -m -s "$user_shell" -g "$NEW_USER" -G "$sudo_group" -p "$NEW_PASSWORD_HASH" "$NEW_USER"
    fi
}

add_ssh_key() {
    if [[ -z "$NEW_PUBLIC_KEY" ]]; then
        return 0
    fi

    local user_home="/home/${NEW_USER}"
    local ssh_dir="${user_home}/.ssh"
    local auth_file="${ssh_dir}/authorized_keys"

    if [[ ! -d "$user_home" ]]; then
        mkdir -p "$user_home"
        chown "$NEW_USER":"$NEW_USER" "$user_home"
    fi

    mkdir -p "$ssh_dir"

    if [ ! -f "$auth_file" ] || ! grep -Fq "$NEW_PUBLIC_KEY" "$auth_file"; then
        echo "$NEW_PUBLIC_KEY" >> "$auth_file"
    fi

    chmod 700 "$ssh_dir"
    chmod 600 "$auth_file"
    chown -R "$NEW_USER":"$NEW_USER" "$ssh_dir"
}

remove_default_users() {
    local default_users=("pi" "ubuntu")

    for user in "${default_users[@]}"; do
        if id -u "$user" >/dev/null 2>&1; then
            if [[ "$user" == "$NEW_USER" ]]; then
                echo
                log "WARN" "Skipping removal of '$user' because it matches the new admin user."
                continue
            fi

            if command -v pkill >/dev/null 2>&1; then
                pkill -u "$user" || true
            fi

            userdel -r "$user" 2>/dev/null || log "ERROR" "Failed to remove $user. Check manually."
        fi
    done
}

# --- Execution ---

main() {
    install_dependencies

    get_user_credentials

    echo
    create_user_and_group

    add_ssh_key
    remove_default_users
}

main
