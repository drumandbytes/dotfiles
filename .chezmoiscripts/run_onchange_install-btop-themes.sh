#!/bin/bash
# Install all four Catppuccin flavour themes for btop.
# Named install-* to ensure it runs after brew-bundle installs btop.
# run_onchange: re-runs if this file changes.

set -euo pipefail

# Chezmoi scripts run without the user's shell profile. Add Homebrew to PATH.
export PATH="/opt/homebrew/bin:$PATH"

if ! command -v btop &>/dev/null; then
    echo "btop not found — skipping theme install"
    exit 0
fi

themes_dir="${XDG_CONFIG_HOME:-$HOME/.config}/btop/themes"
mkdir -p "$themes_dir"

base_url="https://github.com/catppuccin/btop/raw/main/themes"
for flavor in latte frappe macchiato mocha; do
    curl -fsSL "${base_url}/catppuccin_${flavor}.theme" -o "${themes_dir}/catppuccin_${flavor}.theme" ||
        {
            echo "Failed to download catppuccin_${flavor} btop theme" >&2
            exit 1
        }
done
echo "btop Catppuccin themes installed to ${themes_dir}"
