#!/bin/bash

set -euo pipefail

# === Configuration ===
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="$REPO_DIR/.env"

# === Utilities ===

log() {
  echo "[+] $*"
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

echo "https://$GIT_USERNAME:$GIT_PASSWORD@github.com" > "/home/$USER/.git-credentials"
cat <<EOF > "/home/$USER/.gitconfig"
[credential]
    helper = store
EOF
chown "$USER:$USER" "/home/$USER/.git-credentials"
chown "$USER:$USER" "/home/$USER/.gitconfig"

log "Git configuration complete."