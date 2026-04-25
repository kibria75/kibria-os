"""Ask-Kibria — KibriaOS built-in AI assistant (FastAPI, port 8765)."""
import json
import time
from typing import AsyncGenerator, Optional

import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from config import settings

app = FastAPI(
    title="Ask-Kibria",
    description="KibriaOS built-in AI assistant backed by local Ollama",
    version="0.4.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

# 3-tier ladder: (model, max_attempts_before_escalating)
# 9B×2 → 14B×2 → 27B×1 → escalate to Claude
_TIERS: list[tuple[str, int]] = [
    (settings.model_primary, 2),
    (settings.model_middle, 2),
    (settings.model_heavy, 1),
]

_ESCALATE = {
    "error": "all_tiers_exhausted",
    "action": "escalate_to_claude",
    "reason": "9B×2 → 14B×2 → 27B×1 all failed; pass this request to Claude with the error context",
}


# ── Request / response models ────────────────────────────────────────────────

class AskRequest(BaseModel):
    prompt: str
    model: Optional[str] = None  # explicit override bypasses the fallback ladder
    stream: bool = False
    system: Optional[str] = None


class AskResponse(BaseModel):
    response: str
    model: str
    duration_ms: int


# ── Ollama helpers ───────────────────────────────────────────────────────────

def _payload(prompt: str, model: str, system: str) -> dict:
    return {
        "model": model,
        "prompt": f"{system}\n\nUser: {prompt}\nAssistant:",
        "stream": True,
        "think": False,
    }


async def _collect(payload: dict) -> tuple[str, int]:
    """Stream Ollama tokens into a string. Raises httpx.HTTPError on failure."""
    t0 = time.monotonic()
    buf: list[str] = []
    async with httpx.AsyncClient(timeout=180) as client:
        async with client.stream(
            "POST", f"{settings.ollama_url}/api/generate", json=payload
        ) as resp:
            resp.raise_for_status()
            async for line in resp.aiter_lines():
                if not line:
                    continue
                try:
                    chunk = json.loads(line)
                    buf.append(chunk.get("response", ""))
                    if chunk.get("done"):
                        break
                except json.JSONDecodeError:
                    continue
    return "".join(buf).strip(), int((time.monotonic() - t0) * 1000)


async def _collect_with_fallback(prompt: str, system: str) -> tuple[str, int, str]:
    """Try each model tier in order. Returns (text, ms, model_used)."""
    for model, max_tries in _TIERS:
        for _ in range(max_tries):
            try:
                text, ms = await _collect(_payload(prompt, model, system))
                if text:
                    return text, ms, model
            except Exception:
                pass
    raise HTTPException(status_code=503, detail=_ESCALATE)


async def _sse_direct(payload: dict) -> AsyncGenerator[str, None]:
    """SSE stream for an explicit model override — no fallback."""
    try:
        async with httpx.AsyncClient(timeout=180) as client:
            async with client.stream(
                "POST", f"{settings.ollama_url}/api/generate", json=payload
            ) as resp:
                resp.raise_for_status()
                async for line in resp.aiter_lines():
                    if not line:
                        continue
                    try:
                        chunk = json.loads(line)
                        token = chunk.get("response", "")
                        if token:
                            yield f"data: {json.dumps({'token': token})}\n\n"
                        if chunk.get("done"):
                            yield "data: [DONE]\n\n"
                            return
                    except json.JSONDecodeError:
                        continue
    except httpx.HTTPError as exc:
        yield f"data: {json.dumps({'error': str(exc)})}\n\n"


async def _sse_with_fallback(prompt: str, system: str) -> AsyncGenerator[str, None]:
    """SSE stream that escalates through model tiers on connection failure."""
    for model, max_tries in _TIERS:
        for _ in range(max_tries):
            try:
                async with httpx.AsyncClient(timeout=180) as client:
                    async with client.stream(
                        "POST", f"{settings.ollama_url}/api/generate",
                        json=_payload(prompt, model, system),
                    ) as resp:
                        resp.raise_for_status()
                        got_token = False
                        async for line in resp.aiter_lines():
                            if not line:
                                continue
                            try:
                                chunk = json.loads(line)
                                token = chunk.get("response", "")
                                if token:
                                    got_token = True
                                    yield f"data: {json.dumps({'token': token, 'model': model})}\n\n"
                                if chunk.get("done"):
                                    if got_token:
                                        yield "data: [DONE]\n\n"
                                        return
                            except json.JSONDecodeError:
                                continue
            except Exception:
                pass
    yield f"data: {json.dumps(_ESCALATE)}\n\n"


# ── Endpoints ────────────────────────────────────────────────────────────────

@app.get("/")
async def root():
    return {
        "service": "ask-kibria",
        "version": "0.4.0",
        "description": "KibriaOS AI assistant — backed by local Ollama",
        "model_tiers": {
            "primary": settings.model_primary,
            "middle": settings.model_middle,
            "heavy": settings.model_heavy,
        },
        "endpoints": {
            "POST /ask": "Ask a question; set stream=true for SSE",
            "GET  /health": "Liveness + Ollama connectivity check",
            "GET  /models": "List models available in Ollama",
        },
    }


@app.get("/health")
async def health():
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            r = await client.get(f"{settings.ollama_url}/api/tags")
            r.raise_for_status()
            models = [m["name"] for m in r.json().get("models", [])]
        return {"status": "ok", "ollama": "reachable", "models": models}
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Ollama unreachable: {exc}")


@app.get("/models")
async def list_models():
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            r = await client.get(f"{settings.ollama_url}/api/tags")
            r.raise_for_status()
            return r.json()
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc))


@app.post("/ask", response_model=None)
async def ask(req: AskRequest):
    system = req.system or settings.system_prompt

    # Explicit model override — bypasses the fallback ladder
    if req.model:
        payload = _payload(req.prompt, req.model, system)
        if req.stream:
            return StreamingResponse(
                _sse_direct(payload),
                media_type="text/event-stream",
                headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
            )
        try:
            text, ms = await _collect(payload)
        except httpx.HTTPError as exc:
            raise HTTPException(status_code=503, detail=f"Ollama error: {exc}")
        return AskResponse(response=text, model=req.model, duration_ms=ms)

    # Auto 3-tier fallback
    if req.stream:
        return StreamingResponse(
            _sse_with_fallback(req.prompt, system),
            media_type="text/event-stream",
            headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
        )

    text, ms, model_used = await _collect_with_fallback(req.prompt, system)
    return AskResponse(response=text, model=model_used, duration_ms=ms)
