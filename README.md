# dotfiles

Personal **macOS** dotfiles managed with [chezmoi](https://chezmoi.io).

> **macOS only.** Assumes Homebrew, Apple Silicon paths (`/opt/homebrew`), and macOS-specific tools (`pbcopy`, `mac-cleanup`, etc.). Not tested on Linux.

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

Everything else is installed automatically on first `chezmoi apply`.

## Runtime version management

Language runtimes are managed by [mise](https://mise.jdx.dev) rather than Homebrew, so versions can be pinned per project via `.mise.toml`:

| Runtime | Global version |
|---------|---------------|
| `node` | LTS |
| `ruby` | latest |
| `uv` | latest |
| `java` | temurin-21 *(optional)* |

Add per-project overrides with `mise use node@22` inside a project directory.

## Install

On a fresh machine (installs chezmoi and applies dotfiles in one shot):

```zsh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/drumandbytes/dotfiles
```

If chezmoi is already installed:

```zsh
chezmoi init --apply https://github.com/drumandbytes/dotfiles
```

During `chezmoi init` you'll be prompted for optional features (answers are saved locally and never committed):

| Prompt | What it does |
|--------|-------------|
| `Enable Bitwarden integration` | Writes `BW_USER` to env and installs `bw-vault` script |
| `Bitwarden account email` | Your Bitwarden login email (only asked if above is yes) |
| `Enable Touch ID for sudo` | Runs a one-time script to add `pam_tid.so` to sudo PAM config |
| `Install Docker + Colima` | Installs Docker daemon via Colima (lightweight alternative to Docker Desktop) |
| `Install Kubernetes tools` | Installs kubectl, kubectx, k9s, vault, gcloud CLI |
| `Install Java via mise` | Adds `temurin-21` to mise global config and installs libpq |

On first apply, chezmoi automatically:

1. Runs `brew bundle --global` to install all Homebrew packages
2. Runs `mise install` to set up language runtimes
3. Generates static init files and completions (`~/.zsh/*_init.zsh`, `~/.zsh/completions/`)

## Shell architecture

Startup is optimised for speed using `zsh-defer` and pre-generated static files:

```text
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

## Optional: Bitwarden

When Bitwarden is enabled, `~/.local/bin/bw-vault` is installed — a thin wrapper around the `bw` CLI that caches the session token in `/var/root/.bitwarden.session` so non-interactive scripts (cron jobs, etc.) can call it without prompting.

```zsh
bw-vault list items            # auto-authenticates, returns items JSON
bw-vault get password <id>     # get a specific credential
bw-vault --regen               # force re-login and refresh session
```

The `bw-search` shell function (in `functions.zsh`) uses this for interactive fzf-based vault search with clipboard copy.

## Optional: Touch ID for sudo

When Touch ID for sudo is enabled, a one-time script writes `/etc/pam.d/sudo_local` — a macOS 14+ (Sonoma) file that survives OS updates. To re-run it:

```zsh
chezmoi state delete-bucket --bucket=scriptState
chezmoi apply
```

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

## Troubleshooting chezmoi update

**`chezmoi update` fails with "no tracking information", merge conflicts, or "git: exit status 1"**

This happens when the chezmoi source directory is on the wrong branch or has local
commits that diverge from `origin/main` (causing rebase conflicts). Fix it with a
hard reset to the remote:

```zsh
src=$(chezmoi source-path)
git -C "$src" checkout main
git -C "$src" fetch origin main
git -C "$src" reset --hard origin/main
chezmoi apply
```

Or just run `mnt` — it calls `_chezmoi_sync` automatically as its first step, which
handles wrong branch, missing tracking, and diverged commits without conflicts.

**chezmoi apply is prompting about an unexpected diff**

If chezmoi shows a diff you didn't expect, use `chezmoi diff` first to review it,
then choose `overwrite` to apply the source, or `skip` to keep the current file and
run `chezmoi re-add ~/.config/...` to pull the current state back into source.

## Adding a new tool completion

```zsh
comp-add <toolname>   # auto-detects syntax, writes file, persists to chezmoi source
```

## Theme

[Catppuccin Macchiato](https://github.com/catppuccin/catppuccin) across kitty, bat, and delta.
The active kitty theme is set by `sync-theme` (a script in `~/.config/kitty/`) and is not tracked by chezmoi — it switches between Latte (light) and Macchiato (dark).
