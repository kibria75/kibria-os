# KibriaOS v0.1.0 — Pipeline Milestone

**Date:** 2026-04-22  
**Status:** Pre-alpha, passthrough image

## Summary

v0.1.0 proves the delivery pipeline is in place: WSL2 build environment, Git repo shape, release workflow, SHA-256 manifest, and tagged release slot on GitHub. The ISO payload is Ubuntu 24.04.4 LTS Desktop amd64 unmodified.

## Install or Test

Download the upstream Ubuntu ISO:

    https://releases.ubuntu.com/24.04/ubuntu-24.04.4-desktop-amd64.iso

Verify its SHA-256 matches the value in `kibria-os-0.1.0-amd64.iso.sha256` (they will match — v0.1.0 is a passthrough).

## Why no binary on GitHub

GitHub release assets are limited to 2 GB per file. The Ubuntu 24.04.4 ISO is 6.2 GB. A proper mirror (Internet Archive, SourceForge, or Cloudflare R2) will be set up for v0.2.0 when we also add branding and the first agent runtime.

## Next milestones

- v0.2.0 — Branding: volume label, Plymouth, wallpapers, .disk/info
- v0.3.0-beta — First agent: Ask KibriaOS (FastAPI + Ollama)
- v0.4.0 — Three department agents, thirty skills
