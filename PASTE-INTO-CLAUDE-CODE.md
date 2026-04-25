# KibriaOS — Ollama Bridge Reference Card
<!-- Paste this into a Claude Code session to load the routing policy. -->

## Bridge URL

```
https://ruby-contacts-shame-gaps.trycloudflare.com
```

> URL rotates each Cloudflare tunnel session. Verify before use:
> ```bash
> curl -s -A "Mozilla/5.0" https://ruby-contacts-shame-gaps.trycloudflare.com/api/tags \
>   | python3 -m json.tool
> ```

---

## 3-Tier Model Routing

| Tier | Model | Route here |
|------|-------|------------|
| **Primary** | `qwen3.5:9b-q4_K_M` | Boilerplate, READMEs, SVGs, install scripts, config files, shell one-liners, simple Q&A |
| **Middle** | `qwen2.5:14b-instruct-q4_K_M` | Code 9B fumbles, voice rewrites, sales copy, structured JSON generation, multi-step reasoning |
| **Heavy** | `qwen3.5:27b-q4_K_M` | Only when 14B fails twice — complex architecture, long-form doc synthesis |

**Escalation rule:**
- 9B fails ×2 → promote to 14B
- 14B fails ×2 → promote to 27B
- 27B fails → escalate to Claude; state which tier failed and why

"Fails" means: HTTP/connection error, empty response, or clearly incoherent output.

---

## Curl Templates

### Primary — 9B (default, use first)
```bash
curl -s -A "Mozilla/5.0" \
  -X POST https://ruby-contacts-shame-gaps.trycloudflare.com/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen3.5:9b-q4_K_M","prompt":"<PROMPT>","stream":false,"think":false}'
```

### Middle — 14B
```bash
curl -s -A "Mozilla/5.0" \
  -X POST https://ruby-contacts-shame-gaps.trycloudflare.com/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5:14b-instruct-q4_K_M","prompt":"<PROMPT>","stream":false,"think":false}'
```

### Heavy — 27B (last resort)
```bash
curl -s -A "Mozilla/5.0" \
  -X POST https://ruby-contacts-shame-gaps.trycloudflare.com/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen3.5:27b-q4_K_M","prompt":"<PROMPT>","stream":false,"think":false}'
```

### Via ask-kibria agent (auto-fallback, recommended)
```bash
# Non-streaming — agent handles tier escalation automatically
curl -s -X POST http://localhost:8765/ask \
  -H "Content-Type: application/json" \
  -d '{"prompt":"<PROMPT>"}'

# Streaming SSE — each token includes the model that produced it
curl -s -X POST http://localhost:8765/ask \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{"prompt":"<PROMPT>","stream":true}'

# Override model (bypasses fallback ladder)
curl -s -X POST http://localhost:8765/ask \
  -H "Content-Type: application/json" \
  -d '{"prompt":"<PROMPT>","model":"qwen2.5:14b-instruct-q4_K_M"}'
```

---

## Required Headers (direct bridge calls)
| Header | Value |
|--------|-------|
| `User-Agent` | `Mozilla/5.0` |
| `think` | `false` (JSON body field — disables chain-of-thought padding) |

---

## Routing Decision Guide

```
Task → 9B first?
  YES: docs, READMEs, SVGs, install scripts, config files, changelog entries,
       simple shell commands, boilerplate Python/bash
  NO → 14B: multi-file code edits, voice/tone rewrites, structured data gen,
             sales copy, anything requiring nuanced instruction-following
  NO → 27B: only after 14B fails twice
  NO → Claude: architecture decisions, security review, SVG geometry,
               final polish, anything all 3 tiers failed on
```

---

## Environment Variables (ask-kibria agent)

| Variable | Default | Description |
|----------|---------|-------------|
| `KIBRIA_OLLAMA_URL` | `http://localhost:11434` | Ollama API endpoint |
| `KIBRIA_MODEL_PRIMARY` | `qwen3.5:9b-q4_K_M` | Tier 1 model |
| `KIBRIA_MODEL_MIDDLE` | `qwen2.5:14b-instruct-q4_K_M` | Tier 2 model |
| `KIBRIA_MODEL_HEAVY` | `qwen3.5:27b-q4_K_M` | Tier 3 model |
| `KIBRIA_AGENT_PORT` | `8765` | Agent listen port |

Override in `/etc/systemd/system/kibria-agent.service` under `[Service] Environment=`.
