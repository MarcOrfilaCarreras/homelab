#!/bin/bash

set -euo pipefail

# === Configuration ===
ALLOWED_PORTS=(717)
UFW_CONF="/etc/default/ufw"

# === Utilities ===

log() {
  echo "[+] $*"
}

# === Core Functions ===

install() {
  log "Installing ufw..."
  apt-get update -qq
  apt-get install -y ufw
}

reset() {
  log "Resetting UFW..."
  echo y | ufw reset
  log "Waiting for UFW reset to finish..."
  sleep 5
}

enable() {
  log "Setting default policy to deny incoming..."
  ufw default deny incoming
  ufw default allow outgoing

  log "Enabling UFW..."
  ufw --force enable
}

set_logging() {
  log "Enabling UFW logging..."
  ufw logging on
}

allow_ports() {
  for port in "${ALLOWED_PORTS[@]}"; do
    log "Allowing port $port..."
    ufw allow "$port" comment "Configured by script"
  done
}

disable_ipv6() {
  log "Disabling IPv6 in $UFW_CONF..."
  if grep -q '^IPV6=yes' "$UFW_CONF"; then
    sed -i.bak 's/^IPV6=yes/IPV6=no/' "$UFW_CONF"
    log "IPv6 disabled."
  else
    log "IPv6 already disabled or not found."
  fi
}

# === Main ===

install
reset
disable_ipv6
set_logging
allow_ports
enable

log "UFW configuration complete."
