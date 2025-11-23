#!/usr/bin/env bash

set -euo pipefail

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

# --- Execution ---

main() {
    echo
    if ! dpkg -s ufw >/dev/null 2>&1; then
        log "WARN" "UFW not found. Installing UFW..."
        (
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -y -qq >/dev/null 2>&1
            apt-get install -y -qq ufw >/dev/null 2>&1
        )
    fi

    if ! echo y | ufw reset > /dev/null 2>&1; then
        log "ERROR" "Failed to reset UFW. Check UFW status."
        return 1
    fi

    replace_or_append_line "/etc/default/ufw" "^IPV6=yes" "IPV6=no"

    ufw logging on > /dev/null 2>&1
    ufw allow ssh comment "Configured by modules/ufw.sh for SSH" > /dev/null 2>&1
    ufw default deny incoming > /dev/null 2>&1
    ufw default allow outgoing > /dev/null 2>&1

    if ! ufw --force enable > /dev/null 2>&1; then
        log "ERROR" "Failed to enable UFW. Check service status."
        return 1
    fi
}

main
