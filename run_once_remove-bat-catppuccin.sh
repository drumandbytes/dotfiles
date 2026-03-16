#!/bin/bash
# One-time cleanup: remove the old run_onchange_bat-catppuccin.sh from the
# chezmoi source directory if it was left behind as an untracked file after
# the rename to run_onchange_install-bat-themes.sh. git pull does not delete
# untracked files, so chezmoi kept finding and re-running it.

src=$(chezmoi source-path 2>/dev/null) || exit 0
old="$src/run_onchange_bat-catppuccin.sh"

if [[ -f "$old" ]]; then
    rm -f "$old"
    echo "Removed leftover $old"
fi
