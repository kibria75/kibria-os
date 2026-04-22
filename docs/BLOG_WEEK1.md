# Building KibriaOS: Week 1 — Pipeline, Branding, and a Talking OS

*By Dr. ABM Asif Kibria — Dhaka, Bangladesh — 2026-04-22*

---

I'm building a Linux distribution from scratch with zero budget, working alone from Dhaka,
Bangladesh. No investors, no cloud credits, no team. The reason is plain: the AI-powered
tools I want to use daily don't exist in a form I can run locally, own fully, and customise
for my context. So I'm building them into the OS itself.

---

## The Plan for Week 1

The first week had one non-negotiable goal: prove that three hard things actually work.
First, the automated build pipeline — `live-build` on WSL2 — must produce a bootable ISO.
Second, the OS must have a distinct visual identity, not look like stock Ubuntu. Third, the
system must be able to answer questions using local AI, no cloud API, no subscription.

The stack: Ubuntu 24.04 Noble as base, `live-build` to construct the ISO, WSL2 on my
Windows 11 machine as the build host, VirtualBox for boot testing, FastAPI for the agent
endpoint, Ollama + Qwen 3.5 9B for inference.

Three milestones, seven days.

---

## Win: The Pipeline

The `live-build` script finished after a long background run, and the ISO appeared in the
output directory. I mounted it in VirtualBox and watched it boot. It was stock Ubuntu
24.04.4 — not yet branded, not yet intelligent — but it booted from an image I had built
from configuration files I had written. The commit message I chose was deliberately plain:
`pipeline milestone - ubuntu 24.04.4 passthrough`. Pipeline proved. Ship it.

---

## Scar: `live-build` and the Precise Trap

This one cost me two hours.

`live-build`'s default `--distribution` flag is `precise` — Ubuntu 12.04 LTS, released
in 2012. If you forget to pass `--distribution noble` explicitly, the tool silently
targets a twelve-year-old package archive. My first build attempt produced a near-working
image that failed with kernel and library mismatches I couldn't explain. The fix, once I
found it, was a single line in `auto/config`:

```bash
lb config --distribution noble --arch amd64 ...
```

The lesson: never assume a build tool defaults to "current." Always be explicit.

---

## Scar: The 2 GB Wall

The ISO weighs 6.2 GB. GitHub Releases caps individual file uploads at 2 GB. That's it —
no upload, no binary on GitHub.

I spent an evening evaluating alternatives: Internet Archive (free, permanent, no size
limit), Cloudflare R2 (cheap, fast egress), SourceForge (legacy but still works). The
v0.4.0 ISO will go to Internet Archive. For v0.3.0 the binary stays off GitHub entirely —
just code, documentation, and a SHA-256 manifest pointing users to the upstream Ubuntu
image for now.

It's not elegant, but shipping a tag with no binary beats not shipping.

---

## Scar: Hyper-V and VirtualBox on Windows 11

Windows 11 ships with Hyper-V enabled. VirtualBox cannot manage the hypervisor directly
when Hyper-V is active, which means 64-bit VMs simply don't start. Fix:

```cmd
bcdedit /set hypervisorlaunchtype off
```

Reboot. Run the VirtualBox test. Then:

```cmd
bcdedit /set hypervisorlaunchtype auto
```

Reboot again. Two reboots every test cycle, on the only machine I have. This is the
reality of zero-budget development on a single Windows 11 host — no bare-metal Linux,
no KVM, no CI runner to offload the boot test to.

I wrote it into the workflow documentation and moved on.

---

## Win: Branding in Pure Text

The v0.2.0 branding pass delivered every visual asset as SVG or a Plymouth script.
No binary blobs — no PNGs, no ICO files, nothing that isn't plain text.

- `branding/logo/kibria-logo.svg` — 512×512 flat-top hexagon with a white K letterform,
  wordmark below. Designed directly as SVG geometry.
- `branding/wallpaper/kibria-wallpaper.svg` — 1920×1080 teal radial gradient with a
  subtle grid overlay and the same hex-K centred on screen.
- `branding/plymouth/kibria.script` — boot splash drawn entirely in Plymouth's scripting
  language: per-line background gradient, pixel-drawn K mark, animated progress bar.

The primary colour is `#0F766E` — a deep teal that reads well on both dark and light
backgrounds. All assets are reproducible from the repo with no external tooling.

---

## Win: Ask-Kibria — The OS Talks Back

`agents/ask-kibria/` is 178 lines of Python. It's a FastAPI service running on
`localhost:8765` that proxies prompts to a local Qwen 3.5 9B model via Ollama, with a
KibriaOS-aware system prompt baked in.

```bash
# Non-streaming
curl -s -X POST http://localhost:8765/ask \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What is KibriaOS?"}'

# Streaming SSE
curl -s -X POST http://localhost:8765/ask \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{"prompt": "Explain systemd in one paragraph.", "stream": true}'
```

The systemd unit (`kibria-agent.service`) is hardened: dedicated `kibria-agent` system
user, `NoNewPrivileges`, `PrivateTmp`, `ProtectSystem=strict`. The installer creates the
user, sets up a Python virtualenv, installs dependencies, and smoke-tests the `/health`
endpoint. One command:

```bash
sudo bash agents/ask-kibria/install.sh
```

It's small. It only answers questions. But it's the first time this OS produces an
intelligent response to a natural-language query, running entirely on local hardware,
with no external API calls.

---

## What Week 2 Looks Like

Version 0.4.0 targets three things. First: a GNOME panel applet so Ask-Kibria appears
on the desktop without opening a terminal — AI assistance should be one click away.
Second: a full `live-build` rebuild with branding baked into the image at install time,
not applied by a first-boot script after the fact. Third: an Ollama auto-install hook
in `kibria-first-boot.sh` so the model pulls itself on first boot.

Still solo. Still zero budget. Still shipping from Dhaka.

---

*KibriaOS is open source under AGPL-3.0.*  
*Repository: https://github.com/kibria75/kibria-os*
