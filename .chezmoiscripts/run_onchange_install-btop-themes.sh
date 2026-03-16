#!/bin/bash
# Install all four Catppuccin flavour themes for btop.
# Named install-* to ensure it runs after brew-bundle installs btop.
# run_onchange: re-runs if this file changes.

set -euo pipefail

themes_dir="${XDG_CONFIG_HOME:-$HOME/.config}/btop/themes"
mkdir -p "$themes_dir"

base_url="https://github.com/catppuccin/btop/raw/main/themes"
for flavor in latte frappe macchiato mocha; do
    curl -fsSL "${base_url}/catppuccin_${flavor}.theme" -o "${themes_dir}/catppuccin_${flavor}.theme"
done
echo "btop Catppuccin themes installed to ${themes_dir}"
