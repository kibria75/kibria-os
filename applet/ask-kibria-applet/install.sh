#!/usr/bin/env bash
set -euo pipefail

EXTENSION_UUID="ask-kibria@kibria-os"
DEST="$HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID"

echo "Installing Ask-Kibria GNOME extension..."

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

mkdir -p "$DEST"

cp -r "$SCRIPT_DIR/"* "$DEST/"

gnome-extensions enable "$EXTENSION_UUID" 2>/dev/null || true

echo "Log out and back in, or run: gnome-shell --replace &"
echo "Done. Ask-Kibria extension installed."
echo "NOTE: kibria-agent.service must be running for the applet to work."
