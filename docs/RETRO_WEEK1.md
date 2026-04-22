# KibriaOS Week 1 Retrospective

*2026-04-15 → 2026-04-22 · Dr. ABM Asif Kibria*

---

## At a Glance

| Metric | Value |
|:---|:---|
| Milestones shipped | 3 — v0.1.0 pipeline · v0.2.0 branding · v0.3.0-beta agent |
| Commits | 6 |
| Tracked files / lines | 52 files · 2 545 lines (178 Python · 149 shell · 144 SVG · 153 Plymouth script · 1 115 Markdown) |

---

## Kept

Things that worked and will continue unchanged:

- **Ubuntu 24.04 Noble base** — stable, familiar, large package ecosystem
- **`live-build` toolchain** — produces reproducible ISOs from text config; keep it
- **AGPL-3.0 license** — correct choice for an OS with embedded AI services
- **Teal `#0F766E` brand palette** — reads well on dark and light; no changes needed
- **SVG-only visual assets** — zero binary blobs, fully reproducible from source
- **Ollama + Qwen local AI stack** — free inference, no API cost, privacy-respecting
- **WSL2 as build host** — works; constraints are known
- **systemd for all daemons** — `kibria-first-boot.service`, `kibria-agent.service`; keep the pattern
- **FastAPI for agent services** — clean, async, easy to extend

---

## Changed

Things adjusted mid-week based on reality:

- **ISO hosting** — GitHub Releases has a 2 GB per-asset cap; the ISO is 6.2 GB. Moved
  to Internet Archive + Cloudflare R2 plan for v0.4.0 onwards.
- **Plymouth theme approach** — switched from image-based (PNG sprites) to pure-script
  for full reproducibility. No external asset files, no binary blobs.
- **`live-build` distribution flag** — must always pass `--distribution noble` explicitly.
  The default is `precise` (Ubuntu 12.04). Burned two hours discovering this; now baked
  into `auto/config`.
- **VirtualBox test workflow** — Windows 11 with Hyper-V active prevents 64-bit VMs in
  VirtualBox. Now: `bcdedit /set hypervisorlaunchtype off` → reboot → test → re-enable.
  Documented in build notes.

---

## Dropped

Ideas that didn't survive contact with sprint-1 reality:

- **Ubuntu Minimal base** — too many missing desktop packages; would have consumed the
  whole week just making it usable. Deferred indefinitely.
- **Windows `.exe` installer wrapper** — out of scope for a zero-budget solo sprint.
  Dropped without a target date.
- **Plymouth PNG sprite assets** — replaced by script-drawn graphics. No PNG files will
  ship in the branding layer.
- **Separate branding-only ISO release** — v0.3.0 GA consolidates all three milestones
  into one tag. Splitting the release added no value.

---

## Next Week (v0.4.0 target)

- **GNOME panel applet** surfacing Ask-Kibria on the desktop; no terminal required
- **Full ISO rebuild** with branding baked in at image-build time
- **Ollama auto-install hook** in `kibria-first-boot.sh` — pull `qwen3.5:9b-q4_K_M` on first boot
- **ISO binary on Internet Archive** with download link in README

---

## One Thing I Would Tell Week-1-Me

Set up an automated boot-test loop on day one — manually running `live-build`, copying
the ISO, toggling Hyper-V, and rebooting VirtualBox cost more time than all the actual
code combined.
