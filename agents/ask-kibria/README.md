# ask-kibria

FastAPI service (port 8765) that proxies prompts to a local Ollama instance for KibriaOS.

## Requirements

- Python 3.12+
- Ollama running with `qwen3.5:9b-q4_K_M` pulled (`ollama pull qwen3.5:9b-q4_K_M`)

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

## API Reference

### `GET /`
Service info and endpoint listing.

### `GET /health`
Verifies Ollama connectivity. Returns `503` if Ollama is unreachable.

### `GET /models`
Lists all models available in the local Ollama instance.

### `POST /ask`
Proxies a prompt to Ollama. `model` and `system` are optional.

**Body (JSON):**
```json
{
  "prompt": "How do I list all running services?",
  "model": "qwen3.5:9b-q4_K_M",
  "stream": false,
  "system": "Custom system prompt override (optional)"
}
```

**Non-streaming response:**
```bash
curl -s -X POST http://localhost:8765/ask \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What is KibriaOS?"}'
```

**Streaming response (SSE):**
```bash
curl -s -X POST http://localhost:8765/ask \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{"prompt": "Explain systemd in one paragraph.", "stream": true}'
```

Each SSE event is `data: {"token": "..."}`. The stream ends with `data: [DONE]`.

## Configuration

| Variable | Default | Description |
|:---|:---|:---|
| `KIBRIA_OLLAMA_URL` | `http://localhost:11434` | Ollama API endpoint |
| `KIBRIA_MODEL` | `qwen3.5:9b-q4_K_M` | Default model |
| `KIBRIA_AGENT_PORT` | `8765` | Service listening port |

Override in `/etc/systemd/system/kibria-agent.service` under `[Service] Environment=`.
