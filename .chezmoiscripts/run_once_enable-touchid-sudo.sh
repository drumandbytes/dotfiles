#!/bin/bash
# Enables Touch ID authentication for sudo on macOS 14+ (Sonoma).
#
# Uses /etc/pam.d/sudo_local — a file that survives OS updates.
#
# run_once_ means chezmoi runs this once per machine. To re-run:
#   chezmoi state delete-bucket --bucket=scriptState
#   chezmoi apply

set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
    echo "Not macOS — skipping Touch ID sudo setup."
    exit 0
fi

major_version=$(sw_vers -productVersion | cut -d. -f1)
if ((major_version < 14)); then
    echo "macOS < 14 detected — sudo_local not supported, skipping."
    exit 0
fi

SUDO_LOCAL="/etc/pam.d/sudo_local"
TID_LINE="auth       sufficient     pam_tid.so"

if grep -qF "pam_tid.so" "$SUDO_LOCAL" 2>/dev/null; then
    echo "Touch ID for sudo already configured ($SUDO_LOCAL)."
    exit 0
fi

echo "Enabling Touch ID for sudo via $SUDO_LOCAL..."
printf '# sudo_local: local config file which survives system update and is included for sudo\n%s\n' "$TID_LINE" |
    sudo tee "$SUDO_LOCAL" >/dev/null
echo "Done."
