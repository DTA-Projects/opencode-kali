# Homelab improvements (Kali-focused)

This folder documents Kali-related homelab improvements as short write-ups — one file per improvement. Examples: adding a lab target VM, wiring WSL Kali to the homelab network, standing up a CTF-style playground, tooling upgrades, automation.

## Conventions

- **One file per improvement** in this folder: `homelab/<slug>.md`
- **Start from the template**: copy `homelab/_TEMPLATE.md` → rename → fill in
- **This is a PUBLIC repo** — keep every write-up secret-free:
  - No real credentials, tokens, API keys, or passwords (root user names are fine)
  - Sanitize IPs: use documentation ranges (`192.0.2.0/24`, `198.51.100.x`) or mask ranges (`10.10.x.x`)
  - Scrub identifying hostnames, domains, and geolocation details
- **Commands must be copy-pasteable and verified** — test before committing a write-up
- **Keep it Kali-relevant** — the repo is about opencode + Kali, so every improvement should tie back to the lab setup in [SETUP.md](../SETUP.md)

## Current docs

(Add entries as improvements land, linking the file.)

## TEMPLATE.md

The starter for new write-ups lives at `_TEMPLATE.md`. Copy it, rename, fill in the sections, and keep it under the conventions above.