#!/bin/sh
# Installs the repo's sanitization hooks via core.hooksPath (per clone).
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
git -C "$ROOT" config core.hooksPath hooks
echo "Installed: core.hooksPath -> $(git -C "$ROOT" config core.hooksPath)"
echo "Sanitization now runs automatically on every 'git commit' in this clone."