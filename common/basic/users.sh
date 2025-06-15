#!/bin/bash

set -euo pipefail

# === Configuration ===
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="$REPO_DIR/.env"
LOCK_USERS=("pi" "ubuntu" "test")

# === Utilities ===
log() {
  echo "[+] $*"
}

user_exists() {
  id "$1" &>/dev/null
}

# === Core Functions ===
create_home_directory() {
  local user=$1
  local home="/home/$user"

  if [[ ! -d "$home" ]]; then
    log "Creating home directory for '$user'."
    mkdir -p "$home"
    chown "$user:$user" "$home"
    chmod 700 "$home"
  else
    log "Home directory for '$user' already exists."
  fi
}

make_user_sudo() {
  local user=$1
  if ! id -nG "$user" | grep -qw "sudo"; then
    log "Adding '$user' to sudo group."
    usermod -aG sudo "$user"
  else
    log "User '$user' already in sudo group."
  fi
}

create_user() {
  local user=$1
  local password=$2
  if ! user_exists "$user"; then
    log "Creating user '$user'."
    useradd -m -s /bin/bash "$user"
    echo "$user:$password" | chpasswd
  else
    log "User '$user' already exists."
  fi
}

lock_user() {
  local user=$1
  if user_exists "$user"; then
    log "Locking user $user..."
    usermod -L "$user"
    log "User $user has been locked."
  else
    log "User $user does not exist, nothing to lock."
  fi
}

# === Main ===
if [[ -f "$ENV_FILE" ]]; then
  log "Loading environment from $ENV_FILE"
  set -a
  source "$ENV_FILE"
  set +a
else
  log ".env file not found at $ENV_FILE"
  exit 1
fi

create_user "$USER" "$PASSWORD"
create_home_directory "$USER"
make_user_sudo "$USER"

for u in "${LOCK_USERS[@]}"; do
  [[ "$u" == "$USER" ]] && continue
  lock_user "$u"
done

log "User configuration complete."