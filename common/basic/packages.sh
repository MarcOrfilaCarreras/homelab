#!/bin/bash

set -euo pipefail

# === Utilities ===

log() {
  echo "[+] $*"
}

# === Main ===

log "Installing basic packages..."
apt install -y \
    curl wget git btop ca-certificates net-tools python3 python3-pip