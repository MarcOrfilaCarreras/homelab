#!/bin/bash

set -euo pipefail

# === Utilities ===

log() {
  echo "[+] $*"
}

# === Main ===

log "Updating package list (apt update)..."
apt update -y

log "Upgrading all packages to latest versions..."
apt upgrade -y
apt full-upgrade -y
apt autoremove -y
apt autoclean -y

log "System update complete."
