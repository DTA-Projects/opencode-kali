# opencode-kali

Run [opencode](https://opencode.ai) inside Kali Linux and let it drive your security labs.

This repository is a working, documented example of how I run an AI lab partner on Kali — for authorized pentest practice, CTFs, and homelab experimentation:

- a **single-command installer** that turns any Kali box into an opencode lab: Windows (WSL2), bare metal, or a VM — one line, no wizard, no manual steps
- a **`kali` agent** that knows Kali's toolset and environment, enforces authorized-target rules, and follows a phased methodology (enumeration → exploitation → documentation)
- **homelab improvement docs** — a convention for writing up Kali-related homelab work with a starter template
- **secret-free by design** — no credentials, no real addresses, nothing personal in this repo (see [Security](#security))

Send the link ([github.com/DTA-Projects/opencode-kali](https://github.com/DTA-Projects/opencode-kali)) to a friend and they can stand up their own lab in one command.

---

## Install in one command

Install the prerequisites below first, then run one command to get a Kali lab with opencode and the `kali` agent.

**Prerequisite installers** (install these first if you don't have them yet):

- [Install WSL with WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) (Windows 10 21H2+ or Windows 11; `wsl --install` enables it — admin + one reboot)
- [Install Kali Linux](https://www.kali.org/get-kali/) (bare metal / VM — official ISO/images) or use an existing Kali box

Then run the one-liner for your setup:

**Windows + WSL2** (PowerShell — first part needs admin, reboot once if asked):

```powershell
wsl --install -d kali-linux --no-launch; wsl -d kali-linux -u root -- bash -c '$(curl -fsSL https://raw.githubusercontent.com/DTA-Projects/opencode-kali/main/scripts/kali-opencode-install.sh)'
```

**Any Kali already running** — bare metal, VM, or your own WSL user:

```bash
curl -fsSL https://raw.githubusercontent.com/DTA-Projects/opencode-kali/main/scripts/kali-opencode-install.sh | sudo bash
```

Variants (env vars): `OPENCODE_KALI_MINIMAL=1` (lean tool set), `INSTALL_GH=1` (also install GitHub CLI), `KALI_USER_PASS=<pw>` (auto-created WSL user password). Details in [SETUP.md](SETUP.md).

After it finishes: `opencode auth login`, then `opencode` and pick the **kali** agent.

## How it works

```
┌──────────────┐      ┌────────────────────────────────────────────────────────┐
│  You ask     │      │   opencode (CLI + AI)                                  │
│  "scan my    │      │                                                        │
│   lab VM"    │      │   agent/kali.md  (which agent, its rules, methods)     │
└──────────────┘      │  ┌────────────────────────────────────────────┐        │
       │              │  │  The kali agent knows:                     │        │
       │              │  │   •  its job (offensive-security lab partner)│      │
       │              │  │   •  authorization rules (scope first)     │        │
       │              │  │   •  the environment (WSL NAT, sudo for raw│        │
       │              │  │      sockets, headless CLI)                │        │
       │              │  │   •  the methodology (phases, tool choice, │        │
       │              │  │      where findings go)                    │        │
       │              │  └────────────────────────────────────────────┘        │
       │              │                 v  (Bash tool)                         │
       │              │  ┌─────────────────────────────┐                       │
       │              │  │  Kali's own toolset runs:   │                       │
       │              │  │  nmap, msfconsole, hashcat, │                       │
       │              │  │  gobuster, responder, ...   │                       │
       │              │  └─────────────────────────────┘                       │
       │              │                 │                                      │
       │              │   "Target 192.0.2.10: ports 22, 80 open —              │
       │              │    Apache 2.4.49 (RCE CVE-2021-41773), here's          │
       │              │    the exploit path against your lab VM..."            │
       │              └────────────────────────────────────────────────────────┘
       │
       v
  Findings land in ~/labs/<lab-name>/ and homelab/ docs
```

1. The installer puts `opencode` + the `kali` agent into your Kali box. Nothing else depends on the repo at runtime.
2. When you ask a question, opencode picks the `kali` agent from `~/.config/opencode/agent/kali.md` — a small markdown file with frontmatter that decides when it's used and what it knows.
3. The agent talks to Kali's real tools through the Bash tool: it runs `nmap`, `msfconsole`, `hashcat`, etc. against your **authorized** targets, interprets output, and iterates.
4. Findings get written to `~/labs/<lab-name>/` and, for homelab work, to `homelab/` docs in this repo — so you can reproduce any improvement later.

## What's in the box

| Path | What it is |
|---|---|
| `scripts/kali-opencode-install.sh` | The single-command installer. Idempotent, detects WSL vs native/VM, installs tools + opencode + the agent for the right user. |
| `agent/kali.md` | The offensive-security agent (installed into `~/.config/opencode/agent/`). |
| `SETUP.md` | The full setup guide — all three install paths, options, first-run, gotchas. |
| `homelab/README.md` | Conventions + sanitization policy for documenting Kali labs. |
| `homelab/_TEMPLATE.md` | Starter template for a new lab tutorial. |
| `homelab/lab-01-kali-wsl-opencode.md` | First tutorial — stands up the reference lab on Windows/WSL2. |
| `hooks/scan.sh` | Sanitization scanner — private IPs, credential shapes, secret files. |
| `hooks/pre-commit`, `hooks/install-hooks.sh` | Run the scanner automatically on every commit (`bash hooks/install-hooks.sh`). |
| `.github/workflows/sanitize.yml` | CI check — runs the same scanner on every push/PR. |
| `.gitattributes` | Pins shell scripts to LF so hooks run on every OS. |
| `LICENSE` | MIT. |

## Manual quick start

> Prefer the one-command installer? Skip to step 3.

```bash
# 1. Tools (skip if you already have what you need)
sudo apt update && sudo apt install -y kali-linux-headless git curl

# 2. opencode (official installer — no Node needed)
curl -fsSL https://opencode.ai/install | bash
export PATH="$HOME/.opencode/bin:$PATH"

# 3. The kali agent
mkdir -p ~/.config/opencode/agent
curl -fsSL https://raw.githubusercontent.com/DTA-Projects/opencode-kali/main/agent/kali.md \
  -o ~/.config/opencode/agent/kali.md

# 4. Authenticate and go
opencode auth login
opencode        # pick the kali agent
```

## The kali agent

`agent/kali.md` is the heart of it — it's just a markdown file with YAML frontmatter:

```markdown
---
description: Offensive-security lab agent, used when running inside Kali Linux WSL. ...
mode: primary
---

You are the user's offensive-security lab assistant, running inside Kali Linux. ...
```

The `description` decides when opencode picks this agent; the body is its operating manual. What it bakes in:

- **Authorization rules** — homelab lab VMs and CTF platforms you're enrolled on, nothing else; it refuses out-of-scope targets
- **Environment awareness** — `sudo` for raw-socket scans, WSL2 NAT quirks, headless-CLI preference, rolling-release updates
- **Phase-based methodology** — recon/enumeration → exploitation → post-exploitation → write-up, one phase at a time with the reasoning shown
- **Documentation habits** — findings in `~/labs/<lab-name>/`, results in tables, CVEs + mitigations on request

Example prompts to try:

- "Scan the lab subnet, find the target VM, and enumerate services"
- "Crack this hash file from the CTF box with hashcat"
- "Set up a responder capture on eth0 — WSL-safe way"
- "Write up yesterday's lab: host, services, findings, mitigations"

## Running labs on your own gear

- **WSL2 hides Kali behind NAT** (`172.x`) — your LAN lab VMs are reachable through the Windows host; scan their LAN IPs and `sudo` for raw sockets.
- **VMs** — Kali in a VM has real networking and GUI, so any tool works; run the one-liner after the graphical install.
- **CTF platforms** — TryHackMe/HTB give you a target machine; the agent treats those as in-scope and will save per-room findings.
- **Updates** — Kali is a rolling release: `sudo apt full-upgrade -y` now and then.

## Documenting homelab improvements

Kali-related homelab work (new lab VM, networking between WSL Kali and the lab, tooling upgrades) gets written up in [`homelab/`](homelab/) — one short tutorial per improvement, start from `_TEMPLATE.md`. Each write-up: goal, setup, verified commands, verification, gotchas. This keeps the "how it works" knowledge in the repo so future-you (or a friend) can rebuild it. The first one is [`homelab/lab-01-kali-wsl-opencode.md`](homelab/lab-01-kali-wsl-opencode.md).

## Security

### Sanitization is enforced, not optional

Every commit is scanned by [`hooks/scan.sh`](hooks/scan.sh) — locally via the [pre-commit hook](hooks/pre-commit) (install once per clone: `bash hooks/install-hooks.sh`) and again in CI on every push ([`.github/workflows/sanitize.yml`](.github/workflows/sanitize.yml)). The scanner rejects:

- **Private / non-public IPv4** — RFC1918 (`10.x`, `172.16–31.x`, `192.168.x`) and CGNAT (`100.64–127.x`). Documentation ranges (`192.0.2.x`, `198.51.100.x`, `203.0.113.x`) and masked forms like `172.x` are allowed, so tutorials stay realistic.
- **Credential shapes** — GitHub/AWS/OpenAI/Slack/Google tokens, private-key headers, bearer strings, and secret-style `key = value` assignments.
- **Secret-bearing filenames** — `.env`, `*.pem`, `*.key`, `*.p12`, `*.pcap`, `id_rsa`, and friends.

Run it yourself any time: `sh hooks/scan.sh` (whole repo) or `sh hooks/scan.sh path/to/file`.

- **No secrets in this repo, ever.** No credentials, tokens, keys, real IPs, or identifying hostnames. Use documentation ranges (`192.0.2.x`, `198.51.100.x`) or masked notation in write-ups.
- The installer stores nothing of yours: it downloads public artifacts and writes to normal user locations.
- `opencode auth login` keeps your model-provider credentials in `~/.local/share/opencode` — your machine only, never in this repo.
- Only scan/attack systems you own or have written permission to test. That's both the law and baked into the agent's rules.

## How this was built

Built in a single session from a real desktop homelab:

1. Installed Kali as a WSL2 distro on the desktop (`kali-linux-headless`, ~2,000 packages), set up a day-to-day `kali` user, and installed opencode inside it.
2. Wrote the `kali` agent from the real environment — the WSL NAT notes, sudo-for-raw-sockets, and tool list all came from the box itself.
3. Generalised the bootstrap steps into `scripts/kali-opencode-install.sh` and verified both documented one-liners end-to-end on the real Kali (root/WSL path and the `| sudo bash` path).
4. Added the `homelab/` documentation convention so improvements keep accumulating openly.

## License

MIT — see [LICENSE](LICENSE).

In plain English: use this freely — copy it, change it, build on it, even sell it. The one condition: if you redistribute the code (or a substantial part of it), keep the copyright notice and license text so the original credit follows it. There's no warranty — it's provided "as is", so test before you trust it with anything important.
