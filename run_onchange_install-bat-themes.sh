#!/bin/bash
# Install Catppuccin Latte and Macchiato themes for bat.
# Named install-* to ensure it runs after brew-bundle installs bat.
# run_onchange: re-runs if this file changes.

set -euo pipefail

# Chezmoi scripts run in plain bash without the shell profile, so Homebrew
# may not be in PATH. Use the explicit binary to avoid picking up a wrong bat.
bat=/opt/homebrew/bin/bat

[[ -x "$bat" ]] || { echo "bat not found at $bat — skipping theme install"; exit 0; }

themes_dir="$("$bat" --config-dir)/themes"
mkdir -p "$themes_dir"

base_url="https://github.com/catppuccin/bat/raw/main/themes"
curl -fsSL "${base_url}/Catppuccin%20Macchiato.tmTheme" -o "$themes_dir/Catppuccin Macchiato.tmTheme"
curl -fsSL "${base_url}/Catppuccin%20Latte.tmTheme" -o "$themes_dir/Catppuccin Latte.tmTheme"

"$bat" cache --build
