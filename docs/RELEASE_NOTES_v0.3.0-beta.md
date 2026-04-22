# KibriaOS v0.3.0-beta — AI Agent Runtime

## Release Date
2026-04-22

## What is KibriaOS
KibriaOS is an AI-powered Ubuntu 24.04 LTS-based Linux distribution by Dr. ABM Asif Kibria
(Dhaka, Bangladesh). This beta release ships the first interactive AI capability as a
system service.

## What Changed in v0.3.0-beta

- **`agents/ask-kibria/main.py`** — FastAPI service on `localhost:8765` that proxies prompts
  to a local Ollama instance with a KibriaOS-aware system prompt.
- **Endpoints** — `GET /` (service info), `GET /health` (Ollama connectivity check),
  `GET /models` (list available models), `POST /ask` (non-streaming JSON or streaming SSE).
- **Streaming** — `POST /ask` with `"stream": true` returns Server-Sent Events
  (`data: {"token": "..."}` per chunk, terminated by `data: [DONE]`).
- **Configuration** — three env vars: `KIBRIA_OLLAMA_URL` (default `http://localhost:11434`),
  `KIBRIA_MODEL` (default `qwen3.5:9b-q4_K_M`), `KIBRIA_AGENT_PORT` (default `8765`).
- **`agents/ask-kibria/kibria-agent.service`** — hardened systemd unit:
  `NoNewPrivileges`, `PrivateTmp`, `ProtectSystem=strict`, `ProtectHome`,
  runs as dedicated `kibria-agent` system user.
- **`agents/ask-kibria/install.sh`** — one-command installer: creates `kibria-agent`
  system user, copies files to `/usr/lib/kibria-os/agents/ask-kibria/`, creates Python
  virtualenv, installs deps, enables and starts the service.

## Quick Install

```bash
git pull origin main
sudo bash agents/ask-kibria/install.sh
```

## Quick Test

```bash
# Health check (Ollama must be running)
curl http://localhost:8765/health

# Non-streaming ask
curl -s -X POST http://localhost:8765/ask \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What is KibriaOS?"}'
```

## Known Limitations

- Ollama must be pre-installed and the model must be pulled before starting the service
  (`ollama pull qwen3.5:9b-q4_K_M`).
- The service binds to `127.0.0.1` only; no remote access by default.

## What is Next (v0.4.0)

A GNOME panel applet or desktop widget will surface Ask-Kibria directly in the desktop
UI, making the AI assistant accessible without a terminal.
