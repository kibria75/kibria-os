# KibriaOS v0.4.0 Release Notes
**Released:** 2026-04-23

## What is KibriaOS?
KibriaOS is an AI-powered Ubuntu 24.04 LTS-based Linux distribution built by Dr. ABM Asif Kibria (Dhaka, Bangladesh). It ships a curated set of local AI agents backed by Ollama — all running offline, zero cloud dependency.

## Highlights
- **GNOME Shell 46 Panel Applet**: Click the K icon in the top bar, type a question, and get an answer powered by local Ollama.
- Seamless integration with `kibria-agent.service`
- Offline-first architecture with no external dependencies

## Files shipped
| File | Purpose |
|------|---------|
| `applet/ask-kibria-applet/metadata.json` | Extension metadata (UUID, shell-version, name) |
| `applet/ask-kibria-applet/extension.js` | GNOME Shell 46 extension — panel button, popup, Soup 3 HTTP to agent |
| `applet/ask-kibria-applet/stylesheet.css` | Applet popup styling (Catppuccin Mocha palette) |
| `applet/ask-kibria-applet/icons/kibria-panel-symbolic.svg` | 16×16 symbolic K icon for the top bar |
| `applet/ask-kibria-applet/install.sh` | Installs extension to `~/.local/share/gnome-shell/extensions/` and enables it |

## Requires
- GNOME Shell 46 (Ubuntu 24.04)
- `kibria-agent.service` running (`systemctl --user status kibria-agent`)

## Install
```bash
cd applet/ask-kibria-applet && bash install.sh
```

## Upgrade
```bash
git pull && cd applet/ask-kibria-applet && bash install.sh
```

## Note
Builds on v0.3.0, which introduced the Ask-Kibria FastAPI agent on `localhost:8765`. The backend API is unchanged — v0.4.0 adds native GNOME panel integration for direct user interaction without a terminal.
