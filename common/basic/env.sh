#!/bin/bash

set -euo pipefail

# === Configuration ===
PROFILE_FILE='/etc/profile'

# === Utilities ===

log() {
  echo "[+] $*"
}

# === Main ===
if grep -q '^export TERM=' "$PROFILE_FILE"; then
  log "TERM is already set in $PROFILE_FILE. Skipping modification."
else
  log "Adding TERM setting to $PROFILE_FILE..."
  echo "" | sudo tee -a "$PROFILE_FILE" > /dev/null
  echo "# Set TERM variable globally to avoid xterm-kitty unknown terminal error" | sudo tee -a "$PROFILE_FILE" > /dev/null
  echo "export TERM=xterm-256color" | sudo tee -a "$PROFILE_FILE" > /dev/null
fi

log "Reloading $PROFILE_FILE..."
source "$PROFILE_FILE"