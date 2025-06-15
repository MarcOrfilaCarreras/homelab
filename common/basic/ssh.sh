#!/bin/bash

set -euo pipefail

# === Configuration ===
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SSH_CONFIG="/etc/ssh/sshd_config"
PUBLIC_KEY="$REPO_DIR/files/ssh-key.pub"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

# === Utilities ===
log() {
  echo "[+] $*"
}

# === Core Functions ===

replace_or_add_line() {
  local file=$1
  local regexp=$2
  local line=$3

  if grep -E "$regexp" "$file"; then
    sed -i -E "s|$regexp|$line|" "$file"
  else
    echo "$line" >> "$file"
  fi
}

# === Main ===
if [ ! -f "$PUBLIC_KEY" ]; then
  log "Public key file $PUBLIC_KEY does not exist!"
  exit 1
fi

for home in /home/*; do
  if [ -d "$home" ]; then
    username=$(basename "$home")
    ssh_dir="$home/.ssh"
    
    log "Setting up authorized_keys for user: $username"

    mkdir -p "$ssh_dir"
    cat "$PUBLIC_KEY" > "$ssh_dir/authorized_keys"
    chown -R "$username:$username" "$ssh_dir"
    chmod 700 "$ssh_dir"
    chmod 600 "$ssh_dir/authorized_keys"
  fi
done

log "Public key deployed to all users in /home."

# Backup sshd_config once
if [ ! -f "${SSH_CONFIG}${BACKUP_SUFFIX}" ]; then
  cp "$SSH_CONFIG" "${SSH_CONFIG}${BACKUP_SUFFIX}"
fi

log "Configuring SSH daemon..."

replace_or_add_line "$SSH_CONFIG" '^#?Port .*' "Port 717"
replace_or_add_line "$SSH_CONFIG" '^PermitRootLogin .*' "PermitRootLogin no"
replace_or_add_line "$SSH_CONFIG" '^#?ClientAliveInterval .*' "ClientAliveInterval 360"
replace_or_add_line "$SSH_CONFIG" '^#?ClientAliveCountMax .*' "ClientAliveCountMax 0"
replace_or_add_line "$SSH_CONFIG" '^#?PermitEmptyPasswords .*' "PermitEmptyPasswords no"
replace_or_add_line "$SSH_CONFIG" '^Protocol .*' "Protocol 2"
replace_or_add_line "$SSH_CONFIG" '^X11Forwarding .*' "X11Forwarding no"
replace_or_add_line "$SSH_CONFIG" '^#?PubkeyAuthentication .*' "PubkeyAuthentication yes"
replace_or_add_line "$SSH_CONFIG" '^PasswordAuthentication .*' "PasswordAuthentication no"

# Ensure ssh.socket override directory exists
mkdir -p /etc/systemd/system/ssh.socket.d

# Override ssh.socket port config
cat <<EOF > /etc/systemd/system/ssh.socket.d/port.conf
[Socket]
ListenStream=
ListenStream=717
EOF

# Reload systemd and restart ssh service
systemctl daemon-reload
systemctl restart ssh

log "SSH security hardening completed."