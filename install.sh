#!/bin/bash
# Bootstrap script: installs Homebrew + chezmoi, applies base dotfiles, then
# runs the interactive machine setup wizard (dots-setup).
#
# Usage (original repo):
#   bash <(curl -fsSL https://raw.githubusercontent.com/drumandbytes/dotfiles/main/install.sh)
#
# Usage (fork):
#   bash <(curl -fsSL https://raw.githubusercontent.com/drumandbytes/dotfiles/main/install.sh) \
#     yourusername
#
# Pass your GitHub username (or username/repo, or a full URL) as the first
# argument; it is expanded to <username>/dotfiles when no "/" is present.

set -euo pipefail

# ── Repo detection ────────────────────────────────────────────────────────────
# Accepts a GitHub username, a username/repo slug, or a full URL ($1 or
# $DOTFILES_REPO). chezmoi init understands bare slugs and full URLs natively.
DOTFILES_REPO="${1:-${DOTFILES_REPO:-drumandbytes/dotfiles}}"
# Expand a bare username → username/dotfiles (slugs and URLs already contain "/")
[[ "$DOTFILES_REPO" != */* ]] && DOTFILES_REPO="${DOTFILES_REPO}/dotfiles"

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
echo "Initialising dotfiles from ${DOTFILES_REPO} (base pass)..."
chezmoi init "$DOTFILES_REPO"
chezmoi apply

# --- Phase 2: interactive machine setup ---
# dots-setup runs the profile wizard, writes the real chezmoi.toml, then calls
# chezmoi apply again to install the selected packages.
echo ""
echo "Launching machine setup wizard..."
~/.local/bin/dots-setup
