# === Elite Maintenance Workflow ===
mnt() {
    echo "🚀 Starting Elite Maintenance..."

    # 1. System Updates & Cleanup
    echo "🍺 Updating Homebrew..."
    brew update && brew upgrade --greedy && brew cleanup --prune=all
    mac-cleanup
    tldr --update

    # 2. Sheldon Static Source
    echo "🛡️ Refreshing Sheldon plugins..."
    sheldon lock --update
    sheldon source > ~/.zsh/sheldon.zsh

    # 3. Static Initialization Caching (keep in sync with run_onchange_generate-tool-inits.sh)
    echo "🏎️ Caching Tool Initializations..."
    command -v zoxide   &>/dev/null && zoxide init zsh              > ~/.zsh/zoxide_init.zsh
    command -v carapace &>/dev/null && carapace _carapace zsh       > ~/.zsh/carapace_init.zsh
    command -v mise     &>/dev/null && mise activate zsh            > ~/.zsh/mise_init.zsh
    command -v atuin    &>/dev/null && atuin init zsh               > ~/.zsh/atuin_init.zsh
    command -v direnv   &>/dev/null && direnv hook zsh              > ~/.zsh/direnv_init.zsh
    command -v navi     &>/dev/null && navi widget zsh              > ~/.zsh/navi_widget.zsh
    command -v uv       &>/dev/null && uv generate-shell-completion zsh  > ~/.zsh/completions/_uv
    command -v colima   &>/dev/null && colima completion zsh             > ~/.zsh/completions/_colima
    command -v kubectl  &>/dev/null && kubectl completion zsh            > ~/.zsh/completions/_kubectl
    command -v stern    &>/dev/null && stern completion zsh              > ~/.zsh/completions/_stern
    command -v helm     &>/dev/null && helm completion zsh               > ~/.zsh/completions/_helm
    command -v gh       &>/dev/null && gh completion -s zsh              > ~/.zsh/completions/_gh
    command -v flux     &>/dev/null && flux completion zsh               > ~/.zsh/completions/_flux

    # 4. Binary Compilation (Dynamic & Automatic)
    echo "🏗️  Rebuilding binaries from a clean slate..."
    rm -f ~/.zshrc.zwc ~/.zcompdump.zwc ~/.zsh/*.zwc ~/.zsh/completions/*.zwc
    builtin zcompile ~/.zshrc
    for f in ~/.zsh/*.zsh(N); do builtin zcompile "$f"; done
    for comp_file in ~/.zsh/completions/*(N-.); do builtin zcompile "$comp_file"; done
    [[ -f ~/.zcompdump ]] && builtin zcompile ~/.zcompdump

    # 5. Backup & Reload
    zsh-bak
    echo "✅ Optimization complete. Reloading..."
    exec zsh
}

# === Bitwarden Search (ID-Based Parsing) ===
bw-search() {
    if [[ -z "$BW_SESSION" ]]; then
        echo "🔐 No session. Run 'bw-vault --regen' first."
        return 1
    fi
    local item item_id choice
    item=$(bw-vault list items 2>/dev/null | jq -r '.[] | "\(.name) (\(.login.username)) [\(.id)]"' | fzf --header "Search Bitwarden" --height 40%)
    if [[ -n "$item" ]]; then
        item_id=$(echo "$item" | sed -n 's/.*\[\(.*\)\].*/\1/p')
        choice=$(echo "Password\nUsername" | fzf --height 10% --reverse)
        case "$choice" in
            Password) bw-vault get password "$item_id" | pbcopy && echo "✅ Password copied." ;;
            Username) bw-vault get item "$item_id" | jq -r '.login.username' | pbcopy && echo "✅ Username copied." ;;
        esac
    fi
}

# === Sheldon Plugin Automation ===
shadd() {
    [[ -z "$1" ]] && return 1
    sheldon add "$1" --github "$1" --apply defer
    sheldon source > ~/.zsh/sheldon.zsh
    source ~/.zsh/sheldon.zsh
}

# === Interactive Tools (FZF) ===
help-cmd() {
    local FZF_DEFAULT_OPTS=""
    local cmd
    cmd=$( {
        alias | sed 's/^/alias: /'
        command rg '^[[:space:]]*[a-zA-Z0-9_-]+\(\)' ~/.zsh/functions.zsh | sed -E 's/^[[:space:]]*([a-zA-Z0-9_-]+).*/func:  \1/'
    } | fzf --height 40% --layout=reverse --border --ansi --header 'Search Personal Aliases & Functions' )
    if [[ -n "$cmd" ]]; then
        local final_cmd=$(echo "$cmd" | sed -E 's/^(alias|func):[[:space:]]+//' | cut -d'=' -f1)
        eval "$final_cmd"
    fi
}

fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m --ansi --layout=reverse --header 'Select process to kill' | awk '{print $2}')
    [[ -n "$pid" ]] && echo $pid | xargs kill "-${1:-9}"
}

fgb() {
    local branches branch
    branches=$(git branch --all | grep -v HEAD) &&
    branch=$(echo "$branches" | fzf-tmux -d $(( 2 + $(echo "$branches" | wc -l) )) +m \
             --preview 'git log --oneline --graph --date=short --color=always' ) &&
    git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

zsh-bak() {
    local bak_dir="$HOME/Backups/zsh"
    local marker="$bak_dir/.last_backup_check"
    mkdir -p "$bak_dir"
    local changes=$(find ~/.zshrc ~/.zsh ~/.config/kitty ~/.config/sheldon/plugins.toml ~/.config/git -newer "$marker" 2>/dev/null)
    if [[ -n "$changes" || ! -f "$marker" ]]; then
        local bak_name="zsh_bak_$(date +%Y%m%d_%H%M%S).zip"
        zip -rq "$bak_dir/$bak_name" ~/.zshrc ~/.zsh ~/.config/kitty ~/.config/sheldon/plugins.toml ~/.config/git -x "*.zwc"
        touch "$marker"
        echo "📦 Backup created: $bak_name"
    fi
}

# === Dotfiles PR helper ===
# Create a branch, commit a changed file, push, and open a PR.
# Usage: _dotfiles-pr <branch-suffix> <commit-msg> <file-to-commit> <pr-body>
_dotfiles-pr() {
    local branch="dotfiles/${1}" message="$2" file="$3" body="$4"
    local src
    src="$(chezmoi source-path)"

    if ! command -v gh &>/dev/null; then
        echo "❌ gh not found — cannot create PR. Commit manually."
        return 1
    fi

    (
        cd "$src"
        git checkout -b "$branch"
        git add "$file"
        git commit -m "$message"
        git push -u origin "$branch"
        gh pr create --title "$message" --body "$body"
        git checkout -
    )
}

# === Completion Management ===
# Detect a tool's completion syntax, generate the file, and persist it to the
# chezmoi run_onchange_ script so future installs get it automatically.
# Usage: comp-add [--commit] <toolname>
comp-add() {
    local commit=0
    [[ "${1}" == "--commit" ]] && { commit=1; shift; }
    local tool="${1:?Usage: comp-add [--commit] <toolname>}"
    local outfile="$HOME/.zsh/completions/_${tool}"
    local script
    script="$(chezmoi source-path)/run_onchange_generate-tool-inits.sh"

    # Try common completion syntax patterns in order of prevalence
    local cmd="" try
    local -a tries=(
        "$tool completion zsh"
        "$tool completion -s zsh"
        "$tool completion --shell zsh"
        "$tool completions zsh"
        "$tool generate-shell-completion zsh"
    )
    for try in "${tries[@]}"; do
        if eval "$try" > "$outfile" 2>/dev/null && [[ -s "$outfile" ]]; then
            cmd="$try"
            break
        fi
    done

    if [[ -z "$cmd" ]]; then
        rm -f "$outfile"
        echo "❌ Could not auto-detect completion syntax for '${tool}'."
        echo "   Try manually: <tool> completion zsh > ~/.zsh/completions/_${tool}"
        return 1
    fi

    builtin zcompile "$outfile" 2>/dev/null
    echo "✅ Generated ~/.zsh/completions/_${tool}  (via: ${cmd})"

    # Persist to chezmoi source script (insert before marker)
    if [[ -f "$script" ]] && ! grep -qF "_${tool}" "$script"; then
        awk -v line="cmd ${tool} && ${cmd} > ~/.zsh/completions/_${tool}" \
            '/^# --- end completions ---/{print line} 1' \
            "$script" > "${script}.tmp" && mv "${script}.tmp" "$script" && chmod +x "$script"

        if (( commit )); then
            local body="Added to \`$(basename "$script")\`:\n\`\`\`\ncmd ${tool} && ${cmd} > ~/.zsh/completions/_${tool}\n\`\`\`"
            _dotfiles-pr "comp-add-${tool}" "Add ${tool} shell completion" "$script" "$body"
        else
            echo "📝 Persisted to $(basename "$script") — commit when ready"
        fi
    fi
}

# === uv Tool Management ===
# Install a global uv tool and persist it to the chezmoi run_onchange_ script
# so future installs get it automatically.
# Usage: uv-add [--commit] <package>   e.g. uv-add httpie
#        uv-add [--commit] "<package>[extra,...]"
uv-add() {
    local commit=0
    [[ "${1}" == "--commit" ]] && { commit=1; shift; }
    local pkg="${1:?Usage: uv-add [--commit] <package>}"
    local script
    script="$(chezmoi source-path)/run_onchange_uv-tools.sh"

    uv tool install "$pkg" || return 1
    echo "✅ Installed uv tool: ${pkg}"

    if [[ -f "$script" ]] && ! grep -qF "\"${pkg}\"" "$script"; then
        awk -v line="uv tool install \"${pkg}\"" \
            '/^# --- end uv tools ---/{print line} 1' \
            "$script" > "${script}.tmp" && mv "${script}.tmp" "$script"

        # Sanitise pkg name for branch (strip extras, slashes)
        local branch_name="${pkg%%\[*}"
        branch_name="${branch_name//\//-}"
        if (( commit )); then
            local body="Added to \`$(basename "$script")\`:\n\`\`\`\nuv tool install \"${pkg}\"\n\`\`\`"
            _dotfiles-pr "uv-add-${branch_name}" "Add ${pkg} uv tool" "$script" "$body"
        else
            echo "📝 Persisted to $(basename "$script") — commit when ready"
        fi
    fi
}

# === Lazy-loaded tools (fallback when generated inits don't exist yet) ===
# Deferred inits override these on startup when the generated files are present.
z()        { unfunction z zi; eval "$(zoxide init zsh)"; z "$@" }
zi()       { z; zi "$@" }
carapace() { unfunction carapace; eval "$(carapace _carapace zsh)"; carapace "$@" }
mise()     { unfunction mise; eval "$(mise activate zsh)"; mise "$@" }

# === gcloud (lazy-loaded — SDK is large) ===
gcloud() {
    unfunction gcloud gsutil bq
    [[ -f '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc' ]] && . '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc'
    [[ -f '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc' ]] && . '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc'
    gcloud "$@"
}
gsutil() { gcloud; gsutil "$@" }
bq()     { gcloud; bq "$@" }

# === Clipboard helpers ===
copy()      { pbcopy < "$1" }
paste()     { pbpaste }
overwrite() { pbpaste > "$1" }
append()    { pbpaste >> "$1" }
