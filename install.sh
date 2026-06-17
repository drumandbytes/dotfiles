#!/bin/bash
# Bootstrap script: installs Homebrew + chezmoi, applies base dotfiles, then
# runs the interactive machine setup wizard (dots-setup).
#
# Usage (original repo):
#   bash <(curl -fsSL https://raw.githubusercontent.com/drumandbytes/dotfiles/main/install.sh)
#
# Usage (fork):
#   bash <(curl -fsSL https://raw.githubusercontent.com/drumandbytes/dotfiles/main/install.sh) \
#     yourusername/dotfiles
#
# When run from inside a cloned fork, the repo is detected automatically
# from the git remote — no arguments needed.

set -euo pipefail

# ── Repo detection ────────────────────────────────────────────────────────────
# Accepts: username/repo slug, full HTTPS URL, or auto-detects from git remote.
# chezmoi init accepts both slugs and full URLs natively.
_default="drumandbytes/dotfiles"
if [[ -n "${1:-}" ]]; then
    # Expand bare username → username/dotfiles
    [[ "$1" != */* ]] && DOTFILES_REPO="${1}/dotfiles" || DOTFILES_REPO="$1"
elif [[ -n "${DOTFILES_REPO:-}" ]]; then
    : # already set
elif git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    DOTFILES_REPO=$(git remote get-url origin 2>/dev/null || echo "$_default")
else
    DOTFILES_REPO="$_default"
fi
unset _default

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
