#!/bin/bash
# Bootstrap script: installs Homebrew (if missing) then applies dotfiles via chezmoi.
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

# --- dotfiles ---
echo "Applying dotfiles..."
chezmoi init --apply https://github.com/drumandbytes/dotfiles
