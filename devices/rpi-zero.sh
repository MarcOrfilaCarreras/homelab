#!/bin/bash

set -euo pipefail

# === Configuration ===
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMMON_BASIC_DIR="$REPO_DIR/common/basic"
COMMON_APPS_DIR="$REPO_DIR/common/apps"

# === Utilities ===
log() {
  echo "[+] $*"
}

# === Main ===
bash "$COMMON_BASIC_DIR/env.sh"
bash "$COMMON_BASIC_DIR/update.sh"
bash "$COMMON_BASIC_DIR/users.sh"
bash "$COMMON_BASIC_DIR/ssh.sh"
bash "$COMMON_BASIC_DIR/ufw.sh"
bash "$COMMON_BASIC_DIR/packages.sh"
bash "$COMMON_BASIC_DIR/git.sh"

bash "$COMMON_APPS_DIR/skyfare.sh"