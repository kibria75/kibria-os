#!/usr/bin/env bash
# KibriaOS first-boot branding installer
# Runs once as root via kibria-first-boot.service on a fresh Ubuntu 24.04 install.
# Installs wallpaper, Plymouth theme, and GNOME dconf defaults.
set -euo pipefail

BRANDING_SRC="/usr/lib/kibria-os/branding"
WALLPAPER_DST="/usr/share/backgrounds/kibria"
PLYMOUTH_DST="/usr/share/plymouth/themes/kibria"
DCONF_LOCAL="/etc/dconf/db/local.d"
DONE_FLAG="/var/lib/kibria-os/first-boot-done"

log() { echo "[kibria-first-boot] $*"; }

# ── Guard: run only once ─────────────────────────────────────────────────────
if [[ -f "$DONE_FLAG" ]]; then
    log "Already ran — exiting."
    exit 0
fi

log "Starting KibriaOS first-boot branding pass..."

# ── 1. Wallpaper ─────────────────────────────────────────────────────────────
log "Installing wallpaper..."
mkdir -p "$WALLPAPER_DST"

# Convert SVG → PNG if rsvg-convert is available, else copy SVG as-is
if command -v rsvg-convert &>/dev/null; then
    rsvg-convert -w 1920 -h 1080 \
        "$BRANDING_SRC/wallpaper/kibria-wallpaper.svg" \
        -o "$WALLPAPER_DST/kibria-wallpaper.png"
    log "Wallpaper converted to PNG."
elif command -v inkscape &>/dev/null; then
    inkscape --export-type=png \
        --export-width=1920 --export-height=1080 \
        --export-filename="$WALLPAPER_DST/kibria-wallpaper.png" \
        "$BRANDING_SRC/wallpaper/kibria-wallpaper.svg"
    log "Wallpaper converted to PNG via Inkscape."
else
    # Fallback: copy SVG and reference it directly in dconf
    cp "$BRANDING_SRC/wallpaper/kibria-wallpaper.svg" "$WALLPAPER_DST/"
    # Update dconf to point to SVG (GNOME 44+ supports SVG backgrounds)
    sed -i "s|kibria-wallpaper\.png|kibria-wallpaper.svg|g" \
        "$DCONF_LOCAL/90_kibria-defaults" 2>/dev/null || true
    log "WARNING: rsvg-convert/inkscape not found — using SVG wallpaper directly."
fi

# ── 2. Plymouth theme ────────────────────────────────────────────────────────
log "Installing Plymouth theme..."
mkdir -p "$PLYMOUTH_DST"
cp "$BRANDING_SRC/plymouth/kibria.plymouth" "$PLYMOUTH_DST/"
cp "$BRANDING_SRC/plymouth/kibria.script"   "$PLYMOUTH_DST/"

# Set kibria as the active Plymouth theme
if command -v update-alternatives &>/dev/null; then
    update-alternatives --install \
        /usr/share/plymouth/themes/default.plymouth \
        default.plymouth \
        "$PLYMOUTH_DST/kibria.plymouth" 200
    update-alternatives --set default.plymouth "$PLYMOUTH_DST/kibria.plymouth" || true
fi

if command -v update-initramfs &>/dev/null; then
    update-initramfs -u 2>/dev/null || log "WARNING: update-initramfs failed — Plymouth may not apply until next kernel update."
fi

# ── 3. GNOME dconf system defaults ──────────────────────────────────────────
log "Applying GNOME dconf defaults..."
mkdir -p "$DCONF_LOCAL"
cp "$BRANDING_SRC/dconf/90_kibria-defaults" "$DCONF_LOCAL/"

# Ensure dconf db directory is listed in /etc/dconf/profile/user
PROFILE_DIR="/etc/dconf/profile"
mkdir -p "$PROFILE_DIR"
if [[ ! -f "$PROFILE_DIR/user" ]]; then
    printf 'user-db:user\nsystem-db:local\n' > "$PROFILE_DIR/user"
fi
if ! grep -q "system-db:local" "$PROFILE_DIR/user" 2>/dev/null; then
    echo "system-db:local" >> "$PROFILE_DIR/user"
fi

if command -v dconf &>/dev/null; then
    dconf update
    log "dconf database updated."
else
    log "WARNING: dconf not found — settings will apply after dconf is installed."
fi

# ── 4. Mark complete ─────────────────────────────────────────────────────────
mkdir -p "$(dirname "$DONE_FLAG")"
date -u +"KibriaOS first-boot completed at %Y-%m-%dT%H:%M:%SZ" > "$DONE_FLAG"
log "First-boot branding complete. Flag written to $DONE_FLAG."
