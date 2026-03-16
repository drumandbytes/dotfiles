#!/bin/bash
# Install Catppuccin Latte and Macchiato themes for bat.
# Named install-* to ensure it runs after brew-bundle installs bat.
# run_onchange: re-runs if this file changes.

set -euo pipefail

# Chezmoi scripts run in plain bash without the shell profile, so Homebrew
# may not be in PATH. Prefer the explicit Homebrew path, fall back to PATH.
if [[ -x /opt/homebrew/bin/bat ]]; then
    bat=/opt/homebrew/bin/bat
elif command -v bat &>/dev/null; then
    bat=$(command -v bat)
else
    echo "bat not found — skipping theme install"
    exit 0
fi

echo "Using bat: $bat ($("$bat" --version 2>&1 | head -1))"

themes_dir="$("$bat" --config-dir)/themes"
mkdir -p "$themes_dir"

base_url="https://github.com/catppuccin/bat/raw/main/themes"
curl -fsSL "${base_url}/Catppuccin%20Macchiato.tmTheme" -o "$themes_dir/Catppuccin Macchiato.tmTheme"
curl -fsSL "${base_url}/Catppuccin%20Latte.tmTheme"    -o "$themes_dir/Catppuccin Latte.tmTheme"

# Rebuild theme cache. 'bat cache --build' requires sharkdp/bat; skip gracefully
# if this is a different binary or an old version that lacks the cache subcommand.
if "$bat" cache --build 2>/dev/null; then
    echo "bat cache rebuilt."
else
    echo "Warning: 'bat cache --build' failed (bat version: $("$bat" --version 2>&1 | head -1))."
    echo "Themes downloaded to $themes_dir — run 'bat cache --build' manually once the correct bat is active."
fi
