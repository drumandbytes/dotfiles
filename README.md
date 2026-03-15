# dotfiles

Personal macOS dotfiles managed with [chezmoi](https://chezmoi.io).

## What's included

| Config | Description |
|--------|-------------|
| `~/.zshrc` | Zsh entrypoint — modular, deferred, fast |
| `~/.zsh/env.zsh` | Exports, PATH, editor |
| `~/.zsh/aliases.zsh` | Shell aliases (eza, k8s, git, etc.) |
| `~/.zsh/functions.zsh` | Functions: `mnt`, `comp-add`, `bw-search`, lazy loaders |
| `~/.config/sheldon/plugins.toml` | Zsh plugin manager config |
| `~/.config/starship.toml` | Prompt |
| `~/.config/kitty/` | Terminal (kitty.conf + Catppuccin themes) |
| `~/.config/git/config` | Git: delta pager, diff3 merge style |

## Prerequisites

- macOS with [Homebrew](https://brew.sh)
- [chezmoi](https://chezmoi.io): `brew install chezmoi`

Core tools (installed via Homebrew):

```
sheldon atuin zoxide carapace mise direnv navi fzf
eza bat fd ripgrep delta starship kitty lazygit
```

## Install

```zsh
chezmoi init --apply drumandbytes
```

On first apply, `run_onchange_generate-tool-inits.sh` runs automatically and generates:
- Static init files for each tool (`~/.zsh/*_init.zsh`)
- Shell completions (`~/.zsh/completions/`)

## Shell architecture

Startup is optimised for speed using `zsh-defer` and pre-generated static files:

```
.zshrc
├── env.zsh            # immediate — sets PATH, exports
├── functions.zsh      # immediate — defines functions
├── aliases.zsh        # immediate — defines aliases
├── sheldon.zsh        # immediate — pre-rendered plugin source (sheldon source)
└── *_init.zsh         # deferred  — tool hooks (atuin, zoxide, mise, …)
```

Tool inits (atuin, zoxide, etc.) are pre-generated once rather than evaluated on every shell start. Regenerate them with `mnt` (full maintenance) or by running `chezmoi apply` after touching `run_onchange_generate-tool-inits.sh`.

## Key functions

| Function | Description |
|----------|-------------|
| `mnt` | Full maintenance: brew upgrade, sheldon update, regenerate inits & completions, recompile, backup, reload |
| `comp-add <tool>` | Auto-detect and add zsh completions for a new tool; persists to chezmoi source |
| `shadd <user/repo>` | Add a deferred sheldon plugin |
| `bw-search` | fzf Bitwarden item search |
| `help-cmd` | fzf search over all aliases and functions |
| `fkill` | fzf process killer |
| `zsh-bak` | Zip backup of zsh config to `~/Backups/zsh/` |

## History

Shell history is managed by [atuin](https://atuin.sh) with sqlite backend and optional sync. Import existing history with:

```zsh
atuin import auto
atuin sync
```

## Day-to-day chezmoi workflow

```zsh
# Edit a file and apply immediately
chezmoi edit ~/.zshrc --apply

# See what would change
chezmoi diff

# Apply all pending changes
chezmoi apply

# After editing source files directly
chezmoi apply
```

## Adding a new tool completion

```zsh
comp-add <toolname>   # auto-detects syntax, writes file, persists to chezmoi source
```

## Theme

[Catppuccin Macchiato](https://github.com/catppuccin/catppuccin) across kitty, bat, and delta.
The active kitty theme is set by `sync-theme` (a script in `~/.config/kitty/`) and is not tracked by chezmoi — it switches between Latte (light) and Macchiato (dark).
