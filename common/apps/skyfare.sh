#!/bin/bash

set -euo pipefail

# === Configuration ===
APP_NAME="skyfare"
APP_DIR="/opt/$APP_NAME"
REPO_URL="https://github.com/MarcOrfilaCarreras/skyfare.git"
PYTHON_APP="scripts/get_cheapest_flight.py"
SERVICE_FILE="/etc/systemd/system/$APP_NAME.service"
TIMER_FILE="/etc/systemd/system/$APP_NAME.timer"

# === Utilities ===

log() {
  echo "[+] $*"
}

# === Main ===

# Clone or update the Git repository
log "Cloning repository from $REPO_URL to $APP_DIR"
if [ -d "$APP_DIR" ]; then
  log "Directory $APP_DIR already exists. Pulling latest changes..."
  git -C "$APP_DIR" pull
else
  git clone "$REPO_URL" "$APP_DIR"
fi

# Create and activate Python virtual environment, then install app
log "Setting up Python virtual environment"
cd "$APP_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install .

# Create a shell wrapper to run the Python script inside the venv
log "Creating run.sh"
cat <<EOF | sudo tee "$APP_DIR/run.sh" > /dev/null
#!/bin/bash
cd "$APP_DIR"
source venv/bin/activate
python $PYTHON_APP
EOF
chmod +x "$APP_DIR/run.sh"

# Create the systemd service unit
log "Creating $SERVICE_FILE"
cat <<EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=Run $APP_NAME Python App

[Service]
Type=oneshot
ExecStart=$APP_DIR/run.sh
EOF

# Create the systemd timer unit to run the service every 5 minutes
log "Creating $TIMER_FILE"
cat <<EOF | sudo tee "$TIMER_FILE" > /dev/null
[Unit]
Description=Run $APP_NAME every 5 minutes

[Timer]
OnBootSec=60min
OnUnitActiveSec=60min
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Reload systemd, enable and start the timer
log "Enabling and starting systemd timer"
sudo systemctl daemon-reload
sudo systemctl enable --now "$APP_NAME.timer"

# Final status message
log "Deployment complete."
systemctl list-timers | grep "$APP_NAME"