#!/bin/bash
# Install Catppuccin Latte and Macchiato themes for bat.
# Named install-* to ensure it runs after brew-bundle installs bat.
# run_onchange: re-runs if this file changes.

set -euo pipefail

# Chezmoi scripts run without the user's shell profile. Add Homebrew to PATH.
export PATH="/opt/homebrew/bin:$PATH"

if ! command -v bat &>/dev/null; then
    echo "bat not found — skipping theme install"
    exit 0
fi

themes_dir="$(bat --config-dir)/themes"
mkdir -p "$themes_dir"

base_url="https://github.com/catppuccin/bat/raw/main/themes"
curl -fsSL "${base_url}/Catppuccin%20Macchiato.tmTheme" -o "$themes_dir/Catppuccin Macchiato.tmTheme" ||
    {
        echo "Failed to download Catppuccin Macchiato theme" >&2
        exit 1
    }
curl -fsSL "${base_url}/Catppuccin%20Latte.tmTheme" -o "$themes_dir/Catppuccin Latte.tmTheme" ||
    {
        echo "Failed to download Catppuccin Latte theme" >&2
        exit 1
    }

bat cache --build
echo "✅ bat Catppuccin themes installed and cache rebuilt."
