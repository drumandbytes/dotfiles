#!/bin/bash
# Enables Touch ID authentication for sudo on macOS.
#
# On macOS 14+ (Sonoma) uses /etc/pam.d/sudo_local — a file that survives
# OS updates. On older macOS, edits /etc/pam.d/sudo directly (gets reset on
# major upgrades; re-run `chezmoi apply` after upgrading).
#
# run_once_ means chezmoi runs this once per machine. If it gets reset after
# an OS update, delete the state entry and re-apply:
#   chezmoi state delete-bucket --bucket=scriptState
#   chezmoi apply

set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
    echo "Not macOS — skipping Touch ID sudo setup."
    exit 0
fi

TID_LINE="auth       sufficient     pam_tid.so"
SUDO_LOCAL="/etc/pam.d/sudo_local"
SUDO_PAM="/etc/pam.d/sudo"

# macOS 14+ (Sonoma): use sudo_local — not overwritten by OS updates
major_version=$(sw_vers -productVersion | cut -d. -f1)
if (( major_version >= 14 )); then
    if grep -qF "pam_tid.so" "$SUDO_LOCAL" 2>/dev/null; then
        echo "Touch ID for sudo already configured ($SUDO_LOCAL)."
        exit 0
    fi
    echo "Enabling Touch ID for sudo via $SUDO_LOCAL..."
    printf '# sudo_local: local config file which survives system update and is included for sudo\n%s\n' "$TID_LINE" \
        | sudo tee "$SUDO_LOCAL" > /dev/null
    echo "Done."
    exit 0
fi

# macOS < 14: edit /etc/pam.d/sudo directly
if grep -qF "pam_tid.so" "$SUDO_PAM" 2>/dev/null; then
    echo "Touch ID for sudo already enabled ($SUDO_PAM)."
    exit 0
fi

echo "Enabling Touch ID for sudo in $SUDO_PAM..."
# Insert pam_tid.so as the first auth line (after the comment header)
sudo awk -v line="$TID_LINE" '
    /^# sudo:/ { print; print line; next }
    1
' "$SUDO_PAM" | sudo tee "$SUDO_PAM" > /dev/null
echo "Done. Note: this will be reset on major macOS upgrades."
