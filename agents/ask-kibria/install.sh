#!/usr/bin/env bash
# Install Ask-Kibria agent on a KibriaOS / Ubuntu 24.04 system.
# Requires: python3.12+, pip, Ollama running on localhost:11434
# Run as root.
set -euo pipefail

INSTALL_DIR="/usr/lib/kibria-os/agents/ask-kibria"
SERVICE_NAME="kibria-agent"
AGENT_USER="kibria-agent"

log() { echo "[ask-kibria install] $*"; }
die() { echo "[ask-kibria install] ERROR: $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Must be run as root."

# ── 1. System user ───────────────────────────────────────────────────────────
if ! id "$AGENT_USER" &>/dev/null; then
    useradd --system --no-create-home --shell /usr/sbin/nologin "$AGENT_USER"
    log "Created system user: $AGENT_USER"
fi

# ── 2. Copy files ────────────────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/main.py"         "$INSTALL_DIR/"
cp "$SCRIPT_DIR/config.py"       "$INSTALL_DIR/"
cp "$SCRIPT_DIR/requirements.txt" "$INSTALL_DIR/"
log "Files copied to $INSTALL_DIR"

# ── 3. Python virtualenv ─────────────────────────────────────────────────────
if [[ ! -d "$INSTALL_DIR/venv" ]]; then
    python3 -m venv "$INSTALL_DIR/venv"
    log "Virtualenv created."
fi
"$INSTALL_DIR/venv/bin/pip" install --quiet --upgrade pip
"$INSTALL_DIR/venv/bin/pip" install --quiet -r "$INSTALL_DIR/requirements.txt"
log "Python dependencies installed."

# ── 4. Permissions ───────────────────────────────────────────────────────────
chown -R "$AGENT_USER:$AGENT_USER" "$INSTALL_DIR"
chmod 750 "$INSTALL_DIR"
log "Permissions set."

# ── 5. systemd service ───────────────────────────────────────────────────────
cp "$SCRIPT_DIR/kibria-agent.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"
log "Service enabled and started."

# ── 6. Smoke test ────────────────────────────────────────────────────────────
sleep 2
if curl -sf http://localhost:8765/health >/dev/null; then
    log "Smoke test passed — Ask-Kibria is running on http://localhost:8765"
else
    log "WARNING: Health check failed. Check: journalctl -u $SERVICE_NAME -n 30"
fi
