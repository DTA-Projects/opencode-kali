# opencode + Kali Linux

Run [opencode](https://opencode.ai) inside Kali Linux and get an AI lab partner with direct access to the full Kali toolset — nmap, Metasploit, hashcat, gobuster, responder, and 2,000+ more packages. One command gets you there on Windows (WSL2), bare-metal Kali, or a Kali VM.

## What you get

- **opencode CLI** installed for your user (official installer, no Node needed)
- **The full Kali CLI toolset** (`kali-linux-headless`), or a lean set with `OPENCODE_KALI_MINIMAL=1`
- **The `kali` agent** installed to `~/.config/opencode/agent/kali.md` — an offensive-security assistant with authorization rules, WSL-aware workflow, and lab documentation habits ([see agent/kali.md](agent/kali.md))
- **An idempotent installer** — re-run it any time; it only adds what's missing

## Single-command installs

### 1. Windows + WSL2

One line from PowerShell. The first part needs admin (reboot once if asked):

```powershell
wsl --install -d kali-linux --no-launch; wsl -d kali-linux -u root -- bash -c '$(curl -fsSL https://raw.githubusercontent.com/DTA-Projects/opencode-kali/main/scripts/kali-opencode-install.sh)'
```

This skips the Kali setup wizard entirely: it creates a `kali` user (password `kali`, change it with `passwd`), makes it the default WSL user, and installs the toolset + opencode + the agent. If you already ran the Kali wizard and made your own user, just use the "inside any Kali" line below as that user.

### 2. Any Kali — bare metal or VM

```bash
curl -fsSL https://raw.githubusercontent.com/DTA-Projects/opencode-kali/main/scripts/kali-opencode-install.sh | sudo bash
```

For a VM: boot the Kali ISO, run the graphical installer, open a terminal, paste the line. GUI tools work out of the box in a VM; in WSL they need WSLg.

## First run

```bash
opencode auth login   # one-time model-provider auth
opencode              # open the agent picker and choose "kali"
```

Example prompts:

- "Scan the lab subnet, find the target VM, and enumerate services"
- "Teach me how you'd approach this CTF box step by step"
- "Crack this hash file from the lab with hashcat"

Troubleshooting: if `opencode` isn't on your PATH yet, log out/in or run `export PATH="$HOME/.opencode/bin:$PATH"`.

## The kali agent

`agent/kali.md` is what makes this setup different from plain Kali + a terminal:

- **Authorization rules** baked in — only touches machines you own or are authorized to test (CTF platforms count)
- **Environment awareness** — root via `sudo` for raw-socket scans, WSL NAT networking, headless CLI preference
- **Phase-based methodology** — recon/enumeration → exploitation → post-exploitation → documentation
- **Findings in `~/labs/<lab-name>/`** by default, summarized in tables
- **Refuses out-of-scope targets** — that's a feature (see Legal below)

Install it manually on an existing opencode setup:

```bash
mkdir -p ~/.config/opencode/agent
curl -fsSL https://raw.githubusercontent.com/DTA-Projects/opencode-kali/main/agent/kali.md -o ~/.config/opencode/agent/kali.md
```

## Installer options

| Env var | Effect |
|---|---|
| `OPENCODE_KALI_MINIMAL=1` | lean tool set (nmap, sqlmap, gobuster, ffuf, hydra, john, hashcat, metasploit-framework) instead of `kali-linux-headless` |
| `INSTALL_GH=1` | also install GitHub CLI (`gh` is not packaged in Kali; installed from the official .deb) |
| `KALI_USER_PASS=<pw>` | password for the auto-created WSL `kali` user (default `kali`) |

Example:

```bash
OPENCODE_KALI_MINIMAL=1 INSTALL_GH=1 curl -fsSL https://raw.githubusercontent.com/DTA-Projects/opencode-kali/main/scripts/kali-opencode-install.sh | sudo bash
```

## Notes and gotchas

- **WSL2 hides Kali behind NAT** (`172.x`). Lab targets on your LAN are reachable through the Windows host — scan their LAN IPs; raw-socket scans need `sudo`.
- **Windows and Kali keep separate opencode auth** (`~/.local/share/opencode`) — that's expected; authenticate per OS.
- **Kali is a rolling release** — stay current with `sudo apt full-upgrade -y`.
- **Uninstall**: remove `~/.opencode/bin`, `~/.config/opencode/agent/kali.md`, and `sudo apt purge kali-linux-headless` if you want the tools gone too.

## Documenting homelab improvements

Kali-related homelab work gets documented in this repo's [`homelab/`](homelab/) folder as replicable tutorials — one short write-up per improvement (new lab VM, safer networking between WSL Kali and the lab, tooling upgrades, ...). See [`homelab/README.md`](homelab/README.md) for the conventions and start from [`homelab/_TEMPLATE.md`](homelab/_TEMPLATE.md). The first one is [`homelab/lab-01-kali-wsl-opencode.md`](homelab/lab-01-kali-wsl-opencode.md).

This is a **public** repo, and sanitization is **enforced**: every commit runs [`hooks/scan.sh`](hooks/scan.sh) via the [pre-commit hook](hooks/pre-commit) (install once: `bash hooks/install-hooks.sh`) and again in CI on every push. It blocks private IPs, credential shapes, and secret-bearing filenames; documentation ranges (`192.0.2.x`, `198.51.100.x`, `203.0.113.x`) are allowed. Run `sh hooks/scan.sh` to check by hand.

## Legal

Only use this against systems you own or have written permission to test (CTF platforms you're enrolled on count). Scanning or attacking machines without authorization is illegal in most jurisdictions. That's why the kali agent has authorization rules baked in.