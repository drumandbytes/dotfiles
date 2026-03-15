# Homebrew & Editor
export HOMEBREW_NO_ENV_HINTS=true
export EDITOR="fresh"
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1
export CARAPACE_LENIENT=1

# fzf configuration
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git --exclude node_modules --exclude .DS_Store'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --preview 'bat --color=always --style=numbers --line-range :500 {}'"
# Note: CTRL+R is handled by atuin (not fzf)

# Paths
export PATH="/opt/homebrew/opt/openjdk@21/bin:$HOME/.local/bin:/opt/homebrew/opt/libpq/bin:/opt/homebrew/opt/ruby/bin:${KREW_ROOT:-$HOME/.krew}/bin:$HOME/.lmstudio/bin:$PATH"
export JAVA_HOME="/opt/homebrew/opt/openjdk@21"

# Fpath (Completions)
fpath=(~/.zsh/completions $HOME/.docker/completions /opt/homebrew/share/zsh/site-functions $fpath)

# App specific
export BW_USER="maris.popens@bwt.ee"
export LESSHSTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/lesshst"
export DOCKER_DEFAULT_PLATFORM=linux/amd64
