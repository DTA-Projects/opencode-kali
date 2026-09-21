# Homelab labs (Kali-focused)

This folder holds step-by-step **tutorials** for the Kali-related homelab work we do — one file per lab/improvement, written so anyone can replicate it. Examples: standing up the Kali + opencode lab, adding a target VM, wiring WSL Kali to the lab network, tooling upgrades, automation.

## Conventions

- **One file per tutorial** in this folder, numbered: `homelab/lab-NN-<slug>.md`
- **Start from the template**: copy `homelab/_TEMPLATE.md` → rename → fill in
- **Commands must be copy-pasteable and verified** — test before committing a write-up
- **Keep it Kali-relevant** — every tutorial ties back to the lab setup in [SETUP.md](../SETUP.md)
- **List every new tutorial** under "Current labs" below

## Sanitization policy (enforced)

This is a **PUBLIC** repo, so every commit is scanned for leaks — there is no "be careful" version of this; it's automated:

- **Locally:** the [`pre-commit` hook](../hooks/pre-commit) runs [`hooks/scan.sh`](../hooks/scan.sh) on staged files and **refuses the commit** on a hit. Install it once per clone:
  ```bash
  bash hooks/install-hooks.sh
  ```
- **In CI:** [`.github/workflows/sanitize.yml`](../.github/workflows/sanitize.yml) runs the same scanner on every push/PR, so a machine without hooks still can't slip anything through unnoticed.
- **Check by hand any time:** `sh hooks/scan.sh` (whole repo) or `sh hooks/scan.sh path/to/file`.

What the scanner rejects, and what to write instead:

| Don't ship | Write instead |
|---|---|
| Real private IPv4 (`10.x.x.x`, `172.16–31.x.x`, `192.168.x.x`, CGNAT `100.64–127.x.x`) | Documentation ranges: `192.0.2.x` (TEST-NET-1), `198.51.100.x` (TEST-NET-2), `203.0.113.x` (TEST-NET-3), or masked forms like `192.168.x.x` / `10.x.x.x` |
| Credentials, tokens, API keys, cookies, hashes tied to real accounts | Describe the mechanism ("export your token in the environment"), never a live value |
| Secret-bearing files (`.env`, `*.pem`, `*.key`, `*.p12`, `*.pcap`, `id_rsa`, ...) | `.env.example` templates with placeholder values, or instructions to create the file locally |
| Identifying hostnames / domains / geolocation | Generic names (`lab-target`, `kali-desktop`) |

If the scanner flags your write-up: mask or remove the content, re-stage, and commit again. Don't bypass the hook — a leaked credential in git history needs rotation, not a revert.

## Current labs

| Lab | What it covers |
|---|---|
| [Lab 01 — Kali + opencode on Windows/WSL2](lab-01-kali-wsl-opencode.md) | The reference setup: Kali WSL2 distro, full headless toolset, opencode, the `kali` agent, first verified lab session. |

## _TEMPLATE.md

The starter for new tutorials lives at `_TEMPLATE.md`. Copy it, rename to `lab-NN-<slug>.md`, fill in the sections, and keep it under the conventions above.