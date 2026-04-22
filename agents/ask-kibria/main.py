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
    version="0.3.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


# ── Request / response models ────────────────────────────────────────────────

class AskRequest(BaseModel):
    prompt: str
    model: Optional[str] = None
    stream: bool = False
    system: Optional[str] = None


class AskResponse(BaseModel):
    response: str
    model: str
    duration_ms: int


# ── Ollama proxy helpers ─────────────────────────────────────────────────────

def _build_payload(prompt: str, model: str, system: str) -> dict:
    full_prompt = f"{system}\n\nUser: {prompt}\nAssistant:"
    return {"model": model, "prompt": full_prompt, "stream": True, "think": False}


async def _sse_stream(payload: dict) -> AsyncGenerator[str, None]:
    """Proxy Ollama token stream as Server-Sent Events."""
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


async def _collect(payload: dict) -> tuple[str, int]:
    """Collect all Ollama tokens into a single string, return (text, duration_ms)."""
    t0 = time.monotonic()
    buf: list[str] = []
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
                        buf.append(chunk.get("response", ""))
                        if chunk.get("done"):
                            break
                    except json.JSONDecodeError:
                        continue
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=503, detail=f"Ollama error: {exc}")
    return "".join(buf).strip(), int((time.monotonic() - t0) * 1000)


# ── Endpoints ────────────────────────────────────────────────────────────────

@app.get("/")
async def root():
    return {
        "service": "ask-kibria",
        "version": "0.3.0",
        "description": "KibriaOS AI assistant — backed by local Ollama",
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
    model = req.model or settings.default_model
    system = req.system or settings.system_prompt
    payload = _build_payload(req.prompt, model, system)

    if req.stream:
        return StreamingResponse(
            _sse_stream(payload),
            media_type="text/event-stream",
            headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
        )

    text, duration_ms = await _collect(payload)
    return AskResponse(response=text, model=model, duration_ms=duration_ms)
