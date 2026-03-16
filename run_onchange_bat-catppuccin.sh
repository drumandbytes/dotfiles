#!/bin/bash
# Install Catppuccin Macchiato theme for bat.
# run_onchange: re-runs if this file changes.

set -euo pipefail

themes_dir="$(bat --config-dir)/themes"
mkdir -p "$themes_dir"

curl -fsSL \
    "https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Macchiato.tmTheme" \
    -o "$themes_dir/Catppuccin Macchiato.tmTheme"

bat cache --build
