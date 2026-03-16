#!/bin/bash
# Runs whenever ~/.config/mise/config.toml changes (chezmoi run_onchange_).
# Installs all runtimes declared in the mise global config.

set -euo pipefail

if ! command -v mise &>/dev/null; then
    echo "mise not found — skipping. Install via: brew install mise"
    exit 0
fi

echo "Installing mise runtimes..."
mise install --yes
echo "✅ mise install complete."
