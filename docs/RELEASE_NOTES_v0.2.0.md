# KibriaOS v0.2.0 — Branding Milestone

## Release Date
2026-04-22

## What is KibriaOS
KibriaOS is an AI-powered Ubuntu 24.04 LTS-based Linux distribution developed solo by
Dr. ABM Asif Kibria from Dhaka, Bangladesh. This release establishes the distribution's
visual identity and automated branding installation pipeline.

## What Changed in v0.2.0

- **Logo** — `branding/logo/kibria-logo.svg` — 512×512 flat-top hexagon with white K
  letterform on teal (#0F766E) background, KibriaOS wordmark below.
- **Wallpaper** — `branding/wallpaper/kibria-wallpaper.svg` — 1920×1080 teal radial
  gradient (#0F766E→#0D3331) with subtle grid overlay, centred hex-K mark, wordmark,
  and tagline.
- **Plymouth boot splash** — `branding/plymouth/kibria.plymouth` +
  `kibria.script` — full-screen teal gradient, pixel-drawn hex-K mark, and an
  animated thin progress bar at 82% screen height.
- **GNOME dconf defaults** — `branding/dconf/90_kibria-defaults` — system-wide
  dark mode (`prefer-dark`), Yaru-teal-dark GTK theme, left-side dock, Ubuntu fonts,
  sane power and touchpad defaults.
- **First-boot service** — `branding/first-boot/kibria-first-boot.sh` +
  `kibria-first-boot.service` — systemd `oneshot` unit that runs once on first boot
  to install wallpaper (SVG→PNG via rsvg-convert/Inkscape), Plymouth theme
  (update-alternatives + update-initramfs), and dconf defaults. Guards against
  re-execution via `/var/lib/kibria-os/first-boot-done`.

## Upgrade from v0.1.0

A full ISO rebuild is required to ship branding in the installed image. If working
against an existing installation:

```bash
git pull origin main
sudo cp -r branding /usr/lib/kibria-os/
sudo systemctl enable --now kibria-first-boot.service
```

## Known Limitations

- Plymouth is rendered in software at boot time; hardware acceleration is not yet
  configured.
- Wallpaper PNG conversion requires `rsvg-convert` (librsvg2-bin) or Inkscape;
  falls back to SVG if neither is present.
- GNOME Yaru-teal theme requires the `yaru-theme-gtk` package to be pre-installed
  in the ISO.

## What is Next (v0.3.0-beta)

v0.3.0 will introduce the AI agent runtime: a FastAPI service on `localhost:8765`
(`agents/ask-kibria/`) backed by the Ollama bridge, providing the first interactive
AI capability shipped with the OS.
