#!/bin/sh
# =============================================================================
# Sanitization scanner for the opencode-kali public repo.
#
# Fails (exit 1) when any scanned file contains:
#   - RFC1918 / CGNAT IPv4 addresses that look like real lab gear
#     (documentation ranges 192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24 are
#      allowed, and masked examples like "172.x" are fine)
#   - known credential shapes (GitHub/AWS/OpenAI/Slack/Google tokens, private
#     keys, bearer strings, secret-ish key=value assignments)
#   - filenames that typically hold secrets (.env, keys, certs, packet caps)
#
# Usage:  sh hooks/scan.sh [file...]     (no args = scan all tracked files)
# =============================================================================
set -u

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$DIR/.." && pwd)

# IPv4 octet (0-255)
OCT='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
# Private / special-use nets: 10/8, 172.16/12, 192.168/16, CGNAT 100.64/10
PRIVATE_IP="\b(10\.$OCT\.$OCT\.$OCT|192\.168\.$OCT\.$OCT|172\.(1[6-9]|2[0-9]|3[01])\.$OCT\.$OCT|100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.$OCT\.$OCT)\b"
# Credential shapes
CRED='gh[opsu]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9_-]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}|-----BEGIN (RSA|OPENSSH|EC|DSA|PGP) PRIVATE KEY-----'
# secret-ish key=value / key: value assignments with a 12+ char value
KV='(api[_-]?key|secret|access[_-]?token|client[_-]?secret|auth[_-]?token|session[_-]?token|password|passwd)[[:space:]]*[:=][[:space:]]*[A-Za-z0-9+/_=-]{12,}'
# Bearer tokens
BEARER='Bearer [A-Za-z0-9._~+/=-]{20,}'
# Filenames that typically hold secrets (bare .env allowed as template: .env.example)
BADNAMES='\.env$|\.pem$|\.key$|\.p12$|\.pfx$|\.cer$|\.pcap(ng)?$|^id_rsa$|^id_ed25519$|\.keystore$'

viol=0

checkfile() {
  f="$1"
  base=$(basename -- "$f")

  matches=$(printf '%s' "$base" | grep -iE "$BADNAMES" 2>/dev/null)
  if [ -n "$matches" ]; then
    echo "    [$f] secret-looking filename: $base"
    viol=$((viol + 1))
  fi

  matches=$(grep -nE "$PRIVATE_IP" -- "$f" 2>/dev/null)
  if [ -n "$matches" ]; then
    printf '%s\n' "$matches" | sed "s|^|    [$f] private IP: |"
    viol=$((viol + 1))
  fi

  matches=$(grep -nE "$CRED" -- "$f" 2>/dev/null)
  if [ -n "$matches" ]; then
    printf '%s\n' "$matches" | sed "s|^|    [$f] credential shape: |"
    viol=$((viol + 1))
  fi

  matches=$(grep -niE "$KV" -- "$f" 2>/dev/null)
  if [ -n "$matches" ]; then
    printf '%s\n' "$matches" | sed "s|^|    [$f] secret-ish assignment: |"
    viol=$((viol + 1))
  fi

  matches=$(grep -nE "$BEARER" -- "$f" 2>/dev/null)
  if [ -n "$matches" ]; then
    printf '%s\n' "$matches" | sed "s|^|    [$f] bearer token shape: |"
    viol=$((viol + 1))
  fi
}

if [ "$#" -gt 0 ]; then
  FILES="$*"
else
  FILES=$(git -C "$ROOT" ls-files 2>/dev/null || find "$ROOT" -type f -not -path '*/.git/*' -not -name scan.sh)
fi

for f in $FILES; do
  checkfile "$f"
done

if [ "$viol" -gt 0 ]; then
  echo ""
  echo "SANITIZE FAILED: $viol file(s) may leak private IPs or credentials."
  echo "Mask real addresses with documentation ranges (192.0.2.x / 198.51.100.x / 203.0.113.x), remove credentials, then retry."
  exit 1
fi
echo "Sanitization clean."
exit 0