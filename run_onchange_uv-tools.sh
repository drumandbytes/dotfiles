#!/bin/bash
# Installs global Python tools via `uv tool install`.
# Runs whenever this file changes (chezmoi run_onchange_).
#
# To add a tool: add a `uv tool install` line below, then `chezmoi apply`.

set -euo pipefail

if ! command -v uv &>/dev/null; then
    echo "uv not found — skipping. Run 'mise install' first."
    exit 0
fi

echo "Installing uv tools..."

# Python LSP server with type-checking and formatting plugins
uv tool install "python-lsp-server[pylsp-mypy,python-lsp-black]"

echo "✅ uv tools installed."
