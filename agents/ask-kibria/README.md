# ask-kibria

FastAPI service (port 8765) that proxies prompts to a local Ollama instance for KibriaOS,
with a 3-tier model fallback ladder.

## Requirements

- Python 3.12+
- Ollama running with the desired models pulled:
  ```bash
  ollama pull qwen3.5:9b-q4_K_M
  ollama pull qwen2.5:14b-instruct-q4_K_M
  ollama pull qwen3.5:27b-q4_K_M
  ```

## Quick Start

**Development:**
```bash
pip install -r requirements.txt
uvicorn main:app --port 8765 --reload
```

**Production (Ubuntu 24.04):**
```bash
sudo bash install.sh
```

## 3-Tier Model Routing

Requests without an explicit `model` field are routed through an automatic fallback ladder:

| Tier | Model | Attempts | Use for |
|------|-------|----------|---------|
| Primary | `qwen3.5:9b-q4_K_M` | 2 | Boilerplate, READMEs, SVGs, install scripts |
| Middle | `qwen2.5:14b-instruct-q4_K_M` | 2 | Code, voice rewrites, sales copy |
| Heavy | `qwen3.5:27b-q4_K_M` | 1 | Last local resort |

**Escalation:** 9B fails ×2 → 14B. 14B fails ×2 → 27B. 27B fails → 503 with
`action: escalate_to_claude`. "Fails" means HTTP/connection error or empty response.

Provide an explicit `model` in the request body to bypass the ladder entirely.

## API Reference

### `GET /`
Service info, version, and model tier names.

### `GET /health`
Verifies Ollama connectivity. Returns `503` if Ollama is unreachable.

### `GET /models`
Lists all models available in the local Ollama instance.

### `POST /ask`

**Body (JSON):**
```json
{
  "prompt": "How do I list all running services?",
  "model": "qwen3.5:9b-q4_K_M",
  "stream": false,
  "system": "Optional system prompt override"
}
```

`model` and `system` are optional. Omitting `model` enables 3-tier fallback.

**Non-streaming:**
```bash
curl -s -X POST http://localhost:8765/ask \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What is KibriaOS?"}'
```

Response includes `model` field showing which tier answered.

**Streaming SSE:**
```bash
curl -s -X POST http://localhost:8765/ask \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{"prompt": "Explain systemd.", "stream": true}'
```

Each SSE token event includes `model` showing which tier produced it.
Stream ends with `data: [DONE]`. On full ladder exhaustion, emits the escalation payload instead.

## Configuration

| Variable | Default | Description |
|:---|:---|:---|
| `KIBRIA_OLLAMA_URL` | `http://localhost:11434` | Ollama API endpoint |
| `KIBRIA_MODEL_PRIMARY` | `qwen3.5:9b-q4_K_M` | Tier 1 model |
| `KIBRIA_MODEL_MIDDLE` | `qwen2.5:14b-instruct-q4_K_M` | Tier 2 model |
| `KIBRIA_MODEL_HEAVY` | `qwen3.5:27b-q4_K_M` | Tier 3 model |
| `KIBRIA_AGENT_PORT` | `8765` | Service listening port |

Override in `/etc/systemd/system/kibria-agent.service` under `[Service] Environment=`.
