# Lab 01 — Kali + opencode on Windows/WSL2

- Date: 2026-09-21
- Status: done
- Time: ~30–45 min (mostly package downloads)

## Goal

Stand up the reference lab: a Kali Linux WSL2 distro on a Windows machine, with the full headless toolset and opencode driving the `kali` agent — ready to point at lab VMs on the same home network. This is the exact setup [SETUP.md](../SETUP.md) automates; this lab explains what the commands do and how to verify each stage.

## What you need

- Windows 10/11 with virtualization enabled (WSL2)
- Admin rights for the `wsl --install` step; one reboot if WSL isn't enabled yet
- An opencode model provider account (any of the providers opencode supports)
- Optional: a lab target VM or a CTF platform account to point the agent at

## Setup / changes

The lab has five stages. The one-liners do all of them; the notes below explain each.

1. **Install Kali as a WSL2 distro** — `wsl --install -d kali-linux --no-launch` registers Kali without launching the first-run wizard, so the bootstrap can create a clean, scriptable user instead of an interactive one.
2. **Create the day-to-day `kali` user** — a normal user in the `sudo` group, set as the default WSL user in `/etc/wsl.conf` (with `systemd=true`). Working as `kali` + `sudo` mirrors how Kali is normally used.
3. **Install the toolset** — `kali-linux-headless` pulls the full CLI toolset (~2,000 packages: nmap, Metasploit, hashcat, john, hydra, sqlmap, gobuster, responder, impacket, ...). The installer's `OPENCODE_KALI_MINIMAL=1` path installs a lean subset instead.
4. **Install opencode** — the official installer drops a self-contained binary in `~/.opencode/bin` (no Node required) and wires it into `~/.bashrc`.
5. **Install the `kali` agent** — a markdown agent file at `~/.config/opencode/agent/kali.md`, so opencode can pick it when you're doing lab work.

## Commands (verified)

Run from Windows PowerShell (first part needs admin):

```powershell
wsl --install -d kali-linux --no-launch
wsl -d kali-linux -u root -- bash -c '$(curl -fsSL https://raw.githubusercontent.com/DTA-Projects/opencode-kali/main/scripts/kali-opencode-install.sh)'
```

Already have a Kali user (WSL wizard, bare metal, or VM)? Use the same installer from inside Kali:

```bash
curl -fsSL https://raw.githubusercontent.com/DTA-Projects/opencode-kali/main/scripts/kali-opencode-install.sh | sudo bash
```

Then, as the `kali` user, first-run setup:

```bash
passwd                  # change the default password if the installer created the account
opencode auth login     # one-time model-provider auth (separate from Windows)
opencode                # agent picker -> choose "kali"
```

Sanity-check the lab session — point the agent at a target in a documentation range as a dry run:

```bash
sudo nmap -sV -p- --reason 192.0.2.10    # replace with a lab VM you are authorized to scan
```

## Verification

Confirmed on the reference build (2026-09-21):

| Check | Result |
|---|---|
| `nmap --version` | Nmap version 7.99 |
| `sqlmap --version` | 1.10.8 |
| `msfconsole --version`, `hashcat --version`, `john`, `hydra`, `gobuster`, `responder` | all present on PATH |
| `opencode --version` | 1.18.31 |
| Agent file | `~/.config/opencode/agent/kali.md` present |
| Distro packages | ~2,047 installed with the full headless toolset |

## Gotchas / lessons

- **`gh` isn't packaged in Kali.** If you want the GitHub CLI (to clone private config repos), install the official `.deb` — the installer does this with `INSTALL_GH=1`.
- **opencode auth is per-machine and per-OS.** Windows and Kali have separate credential stores (`~/.local/share/opencode`), so authenticate once inside Kali even if Windows opencode is already set up.
- **WSL2 networking is NAT.** Kali sits behind `172.x` and reaches your LAN through the Windows host — scan the lab target's **LAN** IP, not loopback. Raw-socket scans need `sudo`; the `kali` user has it.
- **The first `apt full-upgrade` is the slow part.** Kali is a rolling release; a fresh distro image can be a few hundred MB behind. Run it once before a lab session: `sudo apt full-upgrade -y`.
- **Keep shell scripts LF.** If you add scripts, the repo's [`.gitattributes`](../.gitattributes) pins `*.sh` to LF so hooks and installers keep working on both Windows and Linux.
- **Findings live under `~/labs/<lab-name>/`.** The agent writes per-lab notes there by default; when you want to publish a write-up, sanitize it through the scanner first (see [homelab/README.md](README.md)).

## Next labs

- Lab 02 (idea): stand up a target VM and wire it into the lab network
- Lab 03 (idea): CTF-platform workflow with the `kali` agent
- Lab 04 (idea): add a second Kali box (laptop) and keep the setup in sync