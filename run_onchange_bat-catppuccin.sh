#!/bin/bash
# Install Catppuccin Latte and Macchiato themes for bat.
# run_onchange: re-runs if this file changes.

set -euo pipefail

themes_dir="$(bat --config-dir)/themes"
mkdir -p "$themes_dir"

base_url="https://github.com/catppuccin/bat/raw/main/themes"
curl -fsSL "${base_url}/Catppuccin%20Macchiato.tmTheme" -o "$themes_dir/Catppuccin Macchiato.tmTheme" \
    || { echo "Failed to download Catppuccin Macchiato theme" >&2; exit 1; }
curl -fsSL "${base_url}/Catppuccin%20Latte.tmTheme" -o "$themes_dir/Catppuccin Latte.tmTheme" \
    || { echo "Failed to download Catppuccin Latte theme" >&2; exit 1; }

bat cache --build || { echo "Failed to rebuild bat cache" >&2; exit 1; }
