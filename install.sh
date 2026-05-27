#!/bin/bash
# Bootstrap script: installs Homebrew + chezmoi, applies base dotfiles, then
# runs the interactive machine setup wizard (dots-setup).
#
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/drumandbytes/dotfiles/main/install.sh)

set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
    echo "This dotfiles repo targets macOS only." >&2
    exit 1
fi

# --- Homebrew ---
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "Homebrew already installed: $(brew --version | head -1)"
fi

# --- chezmoi ---
if ! command -v chezmoi &>/dev/null; then
    echo "Installing chezmoi..."
    brew install chezmoi
fi

# --- Phase 1: init + base apply ---
# chezmoi init clones the repo and writes ~/.config/chezmoi/chezmoi.toml with
# safe defaults (all feature flags off). The first apply installs only base
# packages — importantly including fzf, which dots-setup needs.
echo "Initialising dotfiles (base pass)..."
chezmoi init https://github.com/drumandbytes/dotfiles
chezmoi apply

# --- Phase 2: interactive machine setup ---
# dots-setup runs the profile wizard, writes the real chezmoi.toml, then calls
# chezmoi apply again to install the selected packages.
echo ""
echo "Launching machine setup wizard..."
~/.local/bin/dots-setup
