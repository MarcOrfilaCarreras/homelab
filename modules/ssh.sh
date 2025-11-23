#!/usr/bin/env bash

set -euo pipefail

readonly RED="\e[31m"
readonly GREEN="\e[32m"
readonly YELLOW="\e[33m"
readonly RESET="\e[0m"

readonly HOSTS_FILE="/etc/hosts"
readonly PROFILE_D_FILE="/etc/profile.d/99-custom-term.sh"
readonly SSH_CONFIG="/etc/ssh/sshd_config"
readonly SYSTEMD_SOCKET_DIR="/etc/systemd/system/ssh.socket.d"

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

backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp -a "$file" "${file}.bak.$(date +%F_%T)"
    fi
}

replace_or_append_line() {
    # Safely replace or append a line in a file using a regex pattern.
    # $1: file path
    # $2: regex pattern to search for
    # $3: replacement/new line

    local file="$1"
    local pattern="$2"
    local line="$3"

    if grep -qE "$pattern" "$file"; then
        sed -i "s|$pattern|$line|" "$file"
    else
        echo "$line" >> "$file"
    fi
}

# --- Main Configuration Steps ---

configure_hostname() {
    log "INFO" "Starting Hostname configuration..."

    local current_hostname
    if command -v hostnamectl >/dev/null 2>&1; then
        current_hostname=$(hostnamectl --static)
    else
        current_hostname=$(hostname)
    fi

    local default_new_hostname="${current_hostname}-server"

    echo
    read -rp "Enter a new hostname [default: ${default_new_hostname}]: " input_hostname
    local new_hostname="${input_hostname:-${default_new_hostname}}"

    if command -v hostnamectl >/dev/null 2>&1; then
        hostnamectl set-hostname "$new_hostname"
    else
        hostname "$new_hostname"
    fi

    backup_file "$HOSTS_FILE"

    replace_or_append_line "$HOSTS_FILE" "^127\.0\.1\.1[[:space:]].*" "127.0.1.1       $new_hostname"
}

configure_term() {
    log "INFO" "Configuring TERM variable..."

    echo 'export TERM=xterm-256color' > "$PROFILE_D_FILE"
    chmod 644 "$PROFILE_D_FILE"
}

configure_systemd_socket() {
    local ssh_port="$1"
    local port_conf="${SYSTEMD_SOCKET_DIR}/port.conf"

    mkdir -p "$SYSTEMD_SOCKET_DIR"

    cat <<EOF > "$port_conf"
[Socket]
ListenStream=
ListenStream=$ssh_port
EOF

    chmod 644 "$port_conf"
}

configure_ssh() {
    log "INFO" "Starting SSH Server configuration..."

    if ! dpkg -s openssh-server >/dev/null 2>&1; then
        echo
        log "WARN" "openssh-server not installed. Installing..."
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq openssh-server >/dev/null 2>&1
    fi

    local default_port="717"
    local ssh_port

    echo
    while true; do
        read -rp "Enter a new SSH port [default: ${default_port}]: " input_port
        ssh_port="${input_port:-${default_port}}"

        if [[ "$ssh_port" =~ ^[0-9]+$ ]]; then
            break
        else
            echo
            log "WARN" "Invalid port. Please enter a number."
            echo
        fi
    done

    backup_file "$SSH_CONFIG"

    declare -A ssh_config_lines=(
        ["^#Port .*"]="Port $ssh_port"
        ["^Port .*"]="Port $ssh_port"
        ["^PermitRootLogin .*"]="PermitRootLogin no"
        ["^#PermitRootLogin .*"]="PermitRootLogin no"
        ["^#ClientAliveInterval .*"]="ClientAliveInterval 360"
        ["^#ClientAliveCountMax .*"]="ClientAliveCountMax 0"
        ["^#PermitEmptyPasswords .*"]="PermitEmptyPasswords no"
        ["^Protocol .*"]="Protocol 2"
        ["^#Protocol .*"]="Protocol 2"
        ["^X11Forwarding .*"]="X11Forwarding no"
        ["^#X11Forwarding .*"]="X11Forwarding no"
        ["^PubkeyAuthentication .*"]="PubkeyAuthentication yes"
        ["^#PubkeyAuthentication .*"]="PubkeyAuthentication yes"
        ["^PasswordAuthentication .*"]="PasswordAuthentication no"
        ["^#PasswordAuthentication .*"]="PasswordAuthentication no"
    )

    for pattern in "${!ssh_config_lines[@]}"; do
        replace_or_append_line "$SSH_CONFIG" "$pattern" "${ssh_config_lines[$pattern]}"
    done

    if sshd -t; then
        configure_systemd_socket "$ssh_port"
    else
        log "ERROR" "SSH configuration syntax check failed! Restoring backup..."
        cp "${SSH_CONFIG}.bak*" "$SSH_CONFIG"
        return 1
    fi
}

# --- Execution ---

main() {
    echo
    configure_term

    echo
    configure_hostname

    echo
    configure_ssh
}

main
