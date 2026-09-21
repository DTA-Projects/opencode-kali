#!/usr/bin/env bash
# =============================================================================
# opencode-kali — single-command installer
#
# Turns Kali Linux into an opencode-driven security lab with the `kali` agent.
# Works on: Kali WSL (Windows), bare-metal Kali, and Kali VMs.
#
#   WSL (from Windows PowerShell; first part needs admin):
#     wsl --install -d kali-linux --no-launch; wsl -d kali-linux -u root -- bash -c '$(curl -fsSL https://raw.githubusercontent.com/DTA-Projects/opencode-kali/main/scripts/kali-opencode-install.sh)'
#
#   Inside any Kali (your own WSL user, bare metal, or VM):
#     curl -fsSL https://raw.githubusercontent.com/DTA-Projects/opencode-kali/main/scripts/kali-opencode-install.sh | sudo bash
#
#   Options (env vars):
#     OPENCODE_KALI_MINIMAL=1  -> lean tool subset instead of kali-linux-headless
#     INSTALL_GH=1             -> also install GitHub CLI (not in Kali's repos)
#     KALI_USER_PASS=<pw>      -> password for the auto-created `kali` WSL user (default: kali)
#
# Idempotent — safe to re-run at any time.
# =============================================================================
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root:  curl -fsSL <this script> | sudo bash" >&2
  exit 1
fi

# --- detect platform ---
IS_WSL=0
grep -qi microsoft /proc/version 2>/dev/null && IS_WSL=1
echo "==> Platform: $([ "$IS_WSL" = "1" ] && echo 'WSL2' || echo 'native / VM')"

# --- resolve the user who will own opencode ---
TARGET_USER=root
if [ -n "${SUDO_USER:-}" ]; then
  TARGET_USER="$SUDO_USER"
elif [ "$IS_WSL" = "1" ]; then
  DFLT=$(awk -F= '/^default[[:space:]]*=/ {gsub(/ /,"",$2); print $2; exit}' /etc/wsl.conf 2>/dev/null || true)
  if [ -n "$DFLT" ] && id -u "$DFLT" >/dev/null 2>&1; then
    TARGET_USER="$DFLT"
  elif id -u kali >/dev/null 2>&1; then
    TARGET_USER=kali
  fi
fi

# --- WSL only: create a `kali` user + default when nothing is configured ---
if [ "$IS_WSL" = "1" ] && ! grep -qs '^default[[:space:]]*=' /etc/wsl.conf; then
  if ! id -u kali >/dev/null 2>&1; then
    PASS="${KALI_USER_PASS:-kali}"
    echo "==> Creating user 'kali' (password: $PASS — change it with \`passwd\`)"
    useradd -m -s /bin/bash kali
    echo "kali:$PASS" | chpasswd
    usermod -aG sudo kali
  fi
  printf '\n[user]\ndefault=kali\n' >> /etc/wsl.conf
  echo "==> /etc/wsl.conf:"; cat /etc/wsl.conf
  TARGET_USER=kali
fi

TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
echo "==> Target user: $TARGET_USER ($TARGET_HOME)"

# --- apt: update + tools ---
echo "==> apt-get update"
apt-get update -y
if [ "${OPENCODE_KALI_MINIMAL:-0}" = "1" ]; then
  echo "==> Installing lean tool set (OPENCODE_KALI_MINIMAL=1)"
  apt-get install -y git curl nmap sqlmap gobuster ffuf hydra john hashcat metasploit-framework
else
  echo "==> Installing kali-linux-headless (full CLI toolset, ~2 GB; OPENCODE_KALI_MINIMAL=1 for a leaner set)"
  apt-get install -y kali-linux-headless git curl
fi

# --- optional GitHub CLI (not packaged in Kali) ---
if [ "${INSTALL_GH:-0}" = "1" ] && ! command -v gh >/dev/null 2>&1; then
  echo "==> Installing GitHub CLI from the official .deb"
  VER=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])")
  curl -fsSL -o /tmp/gh.deb "https://github.com/cli/cli/releases/download/${VER}/gh_${VER#v}_linux_amd64.deb"
  dpkg -i /tmp/gh.deb
  rm -f /tmp/gh.deb
fi

# --- opencode for the target user ---
cat > /tmp/opencode-user-install.sh <<'OUTER'
#!/bin/bash
set -e
export HOME="$1" PATH="$HOME/.opencode/bin:$PATH"
if ! command -v opencode >/dev/null 2>&1 && [ ! -x "$HOME/.opencode/bin/opencode" ]; then
  curl -fsSL https://opencode.ai/install | bash
fi
opencode --version
OUTER
echo "==> Installing opencode for $TARGET_USER"
sudo -u "$TARGET_USER" bash /tmp/opencode-user-install.sh "$TARGET_HOME"
rm -f /tmp/opencode-user-install.sh

# --- kali agent into the user's opencode config ---
AGENT_DIR="$TARGET_HOME/.config/opencode/agent"
mkdir -p "$AGENT_DIR"
echo "==> Installing the kali agent -> $AGENT_DIR/kali.md"
curl -fsSL https://raw.githubusercontent.com/DTA-Projects/opencode-kali/main/agent/kali.md -o "$AGENT_DIR/kali.md"

echo ""
echo "==============================================================="
echo " opencode + Kali is ready for user '$TARGET_USER'"
echo "==============================================================="
echo " 1. Open a shell as $TARGET_USER and run:"
echo "      opencode auth login    # one-time model-provider auth"
echo "      opencode               # agent picker -> choose 'kali'"
echo " 2. Keep Kali current (rolling release):  sudo apt full-upgrade -y"
echo " 3. If the installer created the kali user just now:  passwd"
echo "    (agent: $AGENT_DIR/kali.md)"