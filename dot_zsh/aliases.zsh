# --- File Management (Eza + Rust tools) ---
alias ls='eza --icons --group-directories-first'
alias l='eza -lh --git --icons --group-directories-first'
alias la='eza -la --git --icons --group-directories-first'
alias tree='eza --tree --icons'
alias df='duf'
alias du='dust'
alias find='fd'
alias grep='rg'
alias dig='doggo'
alias man='tldr'

# --- Kubernetes ---
alias k='kubectl'
alias kx='kubectx'
alias kn='kubens'
alias kgp='k get pods'
alias kgd='k get deployments'
alias kgs='k get service'
alias kga='k get all'
alias kl='k logs -f'
alias kex='k exec -it'

# --- Git & Workflow ---
alias lg='lazygit'
alias copylast="fc -ln -1 | sed 's/^[ \t]*//' | pbcopy"

# --- Config Management ---
alias zshconfig="fresh ~/.zshrc"
alias envconfig="fresh ~/.zsh/env.zsh"
alias aliasconfig="fresh ~/.zsh/aliases.zsh"
alias funcconfig="fresh ~/.zsh/functions.zsh"
alias sheldonconfig="fresh ~/.config/sheldon/plugins.toml"
alias reload="exec zsh"
alias dbt_creds="source ~/.dbt_creds.sh"

# --- Maintenance & Updates ---
alias sheldon-up="sheldon lock --update && sheldon source > ~/.zsh/sheldon.zsh && echo 'Sheldon updated.'"

# --- Global Aliases ---
alias -g L='| less'
alias -g G='| grep'
alias -g H='| head'
alias -g T='| tail'
alias -g CJ='| jid'
