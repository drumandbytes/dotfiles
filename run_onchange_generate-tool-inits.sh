#!/bin/bash
# Runs once on fresh install and whenever this file changes (chezmoi run_onchange_).
# Generates static init files and completions so the shell never spawns subprocesses at startup.

set -euo pipefail

mkdir -p ~/.zsh/completions

cmd() { command -v "$1" &>/dev/null; }

# --- Static init files (sourced deferred at startup) ---
cmd zoxide  && zoxide init zsh > ~/.zsh/zoxide_init.zsh
cmd carapace && carapace _carapace zsh > ~/.zsh/carapace_init.zsh

# --- Tool completions -> ~/.zsh/completions/ ---
cmd uv       && uv generate-shell-completion zsh       > ~/.zsh/completions/_uv
cmd colima   && colima completion zsh                  > ~/.zsh/completions/_colima
cmd kubectl  && kubectl completion zsh                 > ~/.zsh/completions/_kubectl
cmd helm     && helm completion zsh                    > ~/.zsh/completions/_helm
cmd gh       && gh completion -s zsh                   > ~/.zsh/completions/_gh
cmd flux     && flux completion zsh                    > ~/.zsh/completions/_flux
# --- end completions --- (marker used by comp-add; do not remove or move)

echo "✅ Tool inits and completions generated."
