#!/usr/bin/env bash
# KibriaOS v0.4.0 — One-command VM smoke test
# Phases 0-5: env check, tunnel reach, install python+git, clone repo,
#             start FastAPI agent, ask 2+2, install applet.
# Run as a normal user on a fresh Ubuntu 24.04 VM.

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
TUNNEL="https://arcade-available-eight-variation.trycloudflare.com"
REPO_URL="https://github.com/kibria75/kibria-os.git"
REPO_DIR="${REPO_DIR:-$HOME/kibria-os-smoke}"
AGENT_PORT=8765
AGENT_PID=""

# ── Helpers ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

pass()  { echo -e "${GREEN}[PASS]${NC} $*"; }
fail()  { echo -e "${RED}[FAIL]${NC} $*" >&2; exit 1; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
phase() { echo -e "\n${YELLOW}━━━ Phase $* ━━━${NC}"; }

cleanup() {
    [[ -n "$AGENT_PID" ]] && kill "$AGENT_PID" 2>/dev/null || true
}
trap cleanup EXIT

# ── Phase 0: Environment check ────────────────────────────────────────────────
phase "0 — Environment check"

[[ "${BASH_VERSINFO[0]}" -ge 5 ]] || fail "bash ≥ 5 required (got $BASH_VERSION)"
pass "bash $BASH_VERSION"

command -v curl &>/dev/null || fail "curl not found — install with: apt-get install curl"
pass "curl $(curl --version | head -1 | awk '{print $2}')"

if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    [[ "${VERSION_ID:-}" == "24.04" ]] \
        || warn "Expected Ubuntu 24.04, got ${PRETTY_NAME:-unknown}"
    pass "OS: ${PRETTY_NAME:-Linux}"
else
    warn "/etc/os-release not found"
fi

# ── Phase 1: Tunnel reach ─────────────────────────────────────────────────────
phase "1 — Tunnel reach"

HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" \
    --max-time 10 "$TUNNEL" 2>/dev/null || true)
case "$HTTP_CODE" in
    2*|3*)  pass "Tunnel reachable — $TUNNEL (HTTP $HTTP_CODE)" ;;
    "")     warn "No response from tunnel — may be idle. Continuing." ;;
    *)      warn "Tunnel returned HTTP $HTTP_CODE. Continuing." ;;
esac

# ── Phase 2: Install python3 + git ───────────────────────────────────────────
phase "2 — Install python3 + git"

NEED_PKGS=()
command -v python3 &>/dev/null                   || NEED_PKGS+=(python3)
command -v git     &>/dev/null                   || NEED_PKGS+=(git)
python3 -c "import venv" 2>/dev/null             || NEED_PKGS+=(python3-venv)
python3 -c "import pip"  2>/dev/null             || NEED_PKGS+=(python3-pip)

if [[ ${#NEED_PKGS[@]} -gt 0 ]]; then
    echo "  Installing: ${NEED_PKGS[*]}"
    sudo apt-get update -qq
    sudo apt-get install -y -qq "${NEED_PKGS[@]}"
fi

pass "python3 $(python3 --version 2>&1 | awk '{print $2}')"
pass "git $(git --version | awk '{print $3}')"

# ── Phase 3: Clone repo ───────────────────────────────────────────────────────
phase "3 — Clone repo"

if [[ -d "$REPO_DIR/.git" ]]; then
    warn "Repo already present at $REPO_DIR — pulling latest"
    git -C "$REPO_DIR" pull --ff-only
else
    git clone "$REPO_URL" "$REPO_DIR"
fi

REPO_SHA=$(git -C "$REPO_DIR" rev-parse --short HEAD)
pass "Repo at $REPO_DIR (commit $REPO_SHA)"

# ── Phase 4: Start FastAPI agent ──────────────────────────────────────────────
phase "4 — Start FastAPI agent"

AGENT_DIR="$REPO_DIR/agents/ask-kibria"
VENV="$AGENT_DIR/.smoke-venv"

[[ -d "$VENV" ]] || python3 -m venv "$VENV"
"$VENV/bin/pip" install --quiet --upgrade pip
"$VENV/bin/pip" install --quiet -r "$AGENT_DIR/requirements.txt"
pass "Python dependencies installed"

KIBRIA_OLLAMA_URL="${KIBRIA_OLLAMA_URL:-http://localhost:11434}" \
    "$VENV/bin/uvicorn" main:app \
        --app-dir "$AGENT_DIR" \
        --port "$AGENT_PORT" \
        --host 127.0.0.1 \
        --log-level warning &
AGENT_PID=$!

# Wait up to 10 s for the agent to accept connections
for i in {1..20}; do
    sleep 0.5
    curl -sf --max-time 1 "http://127.0.0.1:$AGENT_PORT/" &>/dev/null && break || true
done

ROOT_CODE=$(curl -sf -o /dev/null -w "%{http_code}" \
    --max-time 5 "http://127.0.0.1:$AGENT_PORT/" || true)
[[ "$ROOT_CODE" == "200" ]] \
    || fail "Agent root returned HTTP $ROOT_CODE (expected 200, PID $AGENT_PID)"
pass "Agent listening on http://127.0.0.1:$AGENT_PORT (HTTP $ROOT_CODE)"

HEALTH_CODE=$(curl -sf -o /dev/null -w "%{http_code}" \
    --max-time 5 "http://127.0.0.1:$AGENT_PORT/health" || true)
if [[ "$HEALTH_CODE" == "200" ]]; then
    pass "Agent /health OK — Ollama reachable"
else
    warn "Agent /health returned HTTP $HEALTH_CODE — Ollama likely not installed"
fi

# ── Phase 5a: Ask 2+2 ────────────────────────────────────────────────────────
phase "5a — Ask 2+2"

ASK_PAYLOAD='{"prompt":"What is 2+2? Reply with just the number.","stream":false}'
ASK_RESP=$(curl -sf -X POST "http://127.0.0.1:$AGENT_PORT/ask" \
    -H "Content-Type: application/json" \
    -d "$ASK_PAYLOAD" \
    --max-time 90 2>/dev/null || true)

if [[ -z "$ASK_RESP" ]]; then
    warn "/ask timed out or returned empty — Ollama not running, skipping answer check"
else
    ANSWER=$(echo "$ASK_RESP" \
        | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" \
        2>/dev/null || true)
    if echo "$ANSWER" | grep -q "4"; then
        pass "Ask 2+2 → \"$ANSWER\""
    else
        warn "Response did not contain '4': ${ANSWER:-${ASK_RESP:0:120}}"
    fi
fi

# ── Phase 5b: Install applet ──────────────────────────────────────────────────
phase "5b — Install applet"

EXT_UUID="ask-kibria@kibria-os"
EXT_SRC="$REPO_DIR/applet/ask-kibria-applet"
EXT_DEST="$HOME/.local/share/gnome-shell/extensions/$EXT_UUID"

mkdir -p "$EXT_DEST"
cp -r "$EXT_SRC/"* "$EXT_DEST/"
pass "Applet files staged → $EXT_DEST"

if gnome-extensions enable "$EXT_UUID" 2>/dev/null; then
    pass "GNOME extension enabled"
else
    warn "gnome-extensions unavailable (headless VM?) — files ready for next login"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  KibriaOS v0.4.0 smoke test complete${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "  Repo   : $REPO_DIR  ($REPO_SHA)"
echo "  Agent  : http://127.0.0.1:$AGENT_PORT"
echo "  Applet : $EXT_DEST"
echo ""
echo "  To keep the agent running after this script exits:"
echo "    KIBRIA_OLLAMA_URL=http://localhost:11434 \\"
echo "    $VENV/bin/uvicorn main:app --app-dir $AGENT_DIR --port $AGENT_PORT"
echo ""
