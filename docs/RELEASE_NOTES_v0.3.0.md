# KibriaOS v0.3.0 — Week 1 GA Release

**Release Date:** 2026-04-22  
**Status:** General Availability — Week 1 complete

---

KibriaOS is an AI-powered Ubuntu 24.04 LTS-based Linux distribution by Dr. ABM Asif Kibria
(Dhaka, Bangladesh). v0.3.0 is the Week 1 general-availability release, consolidating
three milestones — pipeline, branding, and first AI agent runtime — into a single stable
tag.

---

## What is in This Release

### v0.1.0 — Pipeline Milestone

Proved the full delivery pipeline end to end:

- WSL2 build environment with `live-build` targeting Ubuntu 24.04.4 LTS (Noble) amd64
- Git repository structure: `branding/`, `agents/`, `docs/`, `build/`, `scripts/`
- SHA-256 manifest for ISO integrity verification
- GitHub Actions workflow scaffold (`.github/`)
- Tagged release workflow functional

> **Note on the ISO binary:** GitHub release assets are capped at 2 GB per file.
> The KibriaOS ISO is 6.2 GB. The binary will be hosted on Internet Archive for v0.4.0
> once branding is baked in. For now, the v0.1.0 ISO is a passthrough of the unmodified
> Ubuntu 24.04.4 desktop image.

---

### v0.2.0 — Branding Milestone

Full teal visual identity, zero binary blobs — all assets are SVG or plain text:

| Asset | Path | Notes |
|---|---|---|
| Logo | `branding/logo/kibria-logo.svg` | 512×512, flat-top hex with white K mark, teal #0F766E fill |
| Wallpaper | `branding/wallpaper/kibria-wallpaper.svg` | 1920×1080, teal radial gradient, grid overlay, hex-K, wordmark |
| Boot splash | `branding/plymouth/kibria.script` | Script-drawn gradient + K mark + animated progress bar |
| Plymouth descriptor | `branding/plymouth/kibria.plymouth` | Points to `script` module |
| GNOME defaults | `branding/dconf/90_kibria-defaults` | Dark mode, Yaru-teal-dark, left dock, Ubuntu fonts |
| First-boot installer | `branding/first-boot/kibria-first-boot.sh` | Installs wallpaper, Plymouth, dconf on first boot |
| First-boot service | `branding/first-boot/kibria-first-boot.service` | systemd oneshot; guarded by done-flag |

Install on an existing Ubuntu 24.04 system:

```bash
git pull origin main
sudo cp -r branding /usr/lib/kibria-os/
sudo cp branding/first-boot/kibria-first-boot.service /etc/systemd/system/
sudo systemctl enable --now kibria-first-boot.service
```

---

### v0.3.0-beta → v0.3.0 — AI Agent Runtime

`agents/ask-kibria/` — the first interactive AI capability shipped as a system service:

| File | Purpose |
|---|---|
| `main.py` | FastAPI on `localhost:8765`; four endpoints (see below) |
| `config.py` | Settings dataclass; configurable via env vars |
| `requirements.txt` | `fastapi`, `uvicorn[standard]`, `httpx`, `pydantic` |
| `kibria-agent.service` | Hardened systemd unit; `NoNewPrivileges`, `PrivateTmp`, `ProtectSystem=strict` |
| `install.sh` | Creates `kibria-agent` user, Python venv, installs deps, starts service |

**Endpoints:**

```
GET  /          → service info + endpoint listing
GET  /health    → Ollama connectivity check + model list
GET  /models    → raw Ollama /api/tags passthrough
POST /ask       → proxy prompt to Ollama; stream=true returns SSE
```

**Install:**

```bash
# Requires: Ollama running, model pulled
ollama pull qwen3.5:9b-q4_K_M

git clone https://github.com/kibria75/kibria-os
cd kibria-os
sudo bash agents/ask-kibria/install.sh
```

**Quick test:**

```bash
curl http://localhost:8765/health

curl -s -X POST http://localhost:8765/ask \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What is KibriaOS?"}'

# Streaming (SSE):
curl -s -X POST http://localhost:8765/ask \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{"prompt": "Explain systemd in one paragraph.", "stream": true}'
```

**Configuration (env vars, override in `/etc/systemd/system/kibria-agent.service`):**

| Variable | Default | Purpose |
|---|---|---|
| `KIBRIA_OLLAMA_URL` | `http://localhost:11434` | Ollama API endpoint |
| `KIBRIA_MODEL` | `qwen3.5:9b-q4_K_M` | Default model |
| `KIBRIA_AGENT_PORT` | `8765` | Listening port |

---

## Known Limitations

- **ISO binary not hosted:** 6.2 GB ISO exceeds GitHub's 2 GB asset limit. Will be on
  Internet Archive for v0.4.0.
- **Branding not yet baked into ISO:** First-boot service installs assets post-install;
  a full live-build rebuild is needed to ship them in the image.
- **Ask-Kibria requires pre-installed Ollama:** `sudo bash agents/ask-kibria/install.sh`
  does not auto-install Ollama or pull the model. That hook arrives in v0.4.0.
- **Plymouth rendered in software:** No hardware acceleration configured at boot yet.
- **Ask-Kibria binds to 127.0.0.1 only:** No remote access by default.

---

## Repository at v0.3.0

```
6 commits  ·  3 tags  ·  52 tracked files  ·  2 545 lines
Python 178  ·  Shell 149  ·  SVG 144  ·  Plymouth script 153  ·  Markdown 1 115
```

---

## What is Next (v0.4.0)

- GNOME panel applet / desktop widget surfacing Ask-Kibria without a terminal
- ISO rebuild with branding baked in (logo, wallpaper, Plymouth, first-boot pre-installed)
- Ollama auto-install + model pull hook in `kibria-first-boot.sh`
- ISO binary hosted on Internet Archive, download link in README
