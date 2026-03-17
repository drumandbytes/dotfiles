# dotfiles

Personal **macOS** dotfiles managed with [chezmoi](https://chezmoi.io).

> **macOS only.** Assumes Homebrew, Apple Silicon paths (`/opt/homebrew`), and macOS-specific tools (`pbcopy`, `mac-cleanup`, etc.). Not tested on Linux.

## What's included

| Config | Description |
| -------- | ----------- |
| `~/.zshrc` | Zsh entrypoint — modular, deferred, fast |
| `~/.zsh/env.zsh` | Exports, PATH, editor |
| `~/.zsh/aliases.zsh` | Shell aliases (eza, k8s, git, etc.) |
| `~/.zsh/functions.zsh` | Functions: `mnt`, `comp-add`, `bw-search`, lazy loaders |
| `~/.config/sheldon/plugins.toml` | Zsh plugin manager config |
| `~/.config/starship.toml` | Prompt |
| `~/.config/kitty/` | Terminal (kitty.conf + Catppuccin themes) |
| `~/.config/git/config` | Git: delta pager, diff3 merge style |
| `~/.config/bat/` | bat config + Catppuccin themes |
| `~/.config/eza/` | eza color theme (Catppuccin symlink) |
| `~/.config/lazygit/` | lazygit config + Catppuccin theme |
| `~/.config/atuin/` | Shell history config + Catppuccin themes |
| `~/.hammerspoon/init.lua` | Auto-reload config; theme sync on macOS appearance change |

## Runtime version management

Language runtimes are managed by [mise](https://mise.jdx.dev) rather than Homebrew, so versions can be pinned per project via `.mise.toml`:

| Runtime | Global version |
| --------- | --------------- |
| `node` | LTS |
| `uv` | latest |
| `ruff` | latest |
| `java` | temurin-21 *(optional)* |

Ruby is not pinned globally — add it per-project with `mise use ruby@3.4` inside a project directory.

## Install

On a fresh machine (installs Homebrew and chezmoi if needed, then applies dotfiles):

```zsh
bash <(curl -fsSL https://raw.githubusercontent.com/drumandbytes/dotfiles/main/install.sh)
```

If Homebrew is installed but chezmoi isn't:

```zsh
brew install chezmoi && chezmoi init --apply https://github.com/drumandbytes/dotfiles
```

If Homebrew and chezmoi are already installed:

```zsh
chezmoi init --apply https://github.com/drumandbytes/dotfiles
```

During `chezmoi init` you'll be prompted for optional features (answers are saved locally and never committed):

| Prompt | What it does |
| -------- | ----------- |
| `Preferred editor` | Sets `$EDITOR`; controls which editor is installed (fresh, nvim, vim, code) |
| `Install modern CLI replacements` | Installs eza, bat, fd, ripgrep, fzf, delta, etc. and enables them in shell config |
| `Install macOS utilities` | Installs Raycast, Alt-Tab, Hammerspoon, mac-cleanup, etc. |
| `Install cosmetic macOS apps` | Installs Boring Notch, AirBattery, Cork |
| `Install media & communication apps` | Installs Brave, Spotify, Telegram, Slack, spicetify |
| `Install dev apps` | Installs VSCodium, DBeaver, GIMP, GitLab CLI, GitHub CLI |
| `Install BetterTouchTool` | For TouchBar Macs only |
| `Enable Bitwarden integration` | Writes `BW_USER` to env and installs `bw-vault` script |
| `Bitwarden account email` | Your Bitwarden login email (only asked if above is yes) |
| `Enable Touch ID for sudo` | Runs a one-time script to add `pam_tid.so` to sudo PAM config |
| `Install Docker + Colima` | Installs Docker daemon via Colima (lightweight alternative to Docker Desktop); on Apple Silicon uses `vmType=vz` + Rosetta for native speed and x86 image support |
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

Tool inits (atuin, zoxide, direnv, navi, etc.) are pre-generated once rather than evaluated on every shell start. Regenerate them with `mnt` (full maintenance) or by running `chezmoi apply` after touching `run_onchange_generate-tool-inits.sh.tmpl`.

## Key functions

| Function | Description |
| ---------- | ----------- |
| `mnt` | Full maintenance: brew upgrade, sheldon update, regenerate inits & completions, recompile, backup, reload |
| `comp-add <tool>` | Auto-detect and add zsh completions for a new tool; persists to chezmoi source |
| `uv-add <package>` | Install a global uv tool and persist it to `run_onchange_uv-tools.sh` |
| `sh-add <user/repo>` | Add a deferred sheldon plugin; persists to sheldon config |
| `bw-search` | fzf Bitwarden item search |
| `help-cmd` | fzf search over all aliases and functions (personal shortcuts only) |
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
```

## Troubleshooting chezmoi update

**`chezmoi update` fails with "no tracking information", merge conflicts, or "git: exit status 1"**

This happens when the chezmoi source directory is on the wrong branch or has local
commits that diverge from `origin/main` (causing rebase conflicts). Fix it with a
hard reset to the remote:

```zsh
src=$(chezmoi source-path)
git -C "$src" fetch origin main
git -C "$src" checkout -B main origin/main
chezmoi apply
```

Or just run `mnt` — it calls `_chezmoi_sync` automatically as its first step, which
handles wrong branch, missing tracking, and diverged commits without conflicts.

**chezmoi apply is prompting about an unexpected diff**

If chezmoi shows a diff you didn't expect, use `chezmoi diff` first to review it,
then choose `overwrite` to apply the source, or `skip` to keep the current file and
run `chezmoi re-add ~/.config/...` to pull the current state back into source.

## Adding things

```zsh
comp-add <toolname>        # add a zsh completion; auto-detects syntax, persists to chezmoi source
uv-add <package>           # install a global uv tool and persist it to run_onchange_uv-tools.sh
sh-add <user/repo>          # add a deferred sheldon plugin and persist it to plugins.toml
```

## Navi

[navi](https://github.com/denisidoro/navi) is a command-line cheatsheet tool bound to a key widget (Ctrl+G by default). It lets you search, fill in variables, and insert commands into the prompt — complementing `help-cmd` which only covers personal aliases and functions.

On first `chezmoi apply`, `run_onchange_navi-cheats.sh.tmpl` auto-generates `~/.local/share/navi/cheats/personal.cheat` from your aliases and functions, and clones the [denisidoro/cheats](https://github.com/denisidoro/cheats) community repo. The personal cheat file is regenerated automatically whenever `aliases.zsh` or `functions.zsh` changes.

| Source | What it covers |
| ------ | -------------- |
| `personal.cheat` | All your aliases and functions, organised by section |
| `denisidoro/cheats` | Community-maintained general shell cheatsheets |
| `navi --cheatsh` | On-demand access to the full [cheat.sh](https://cheat.sh) database |

## Theme

[Catppuccin](https://github.com/catppuccin/catppuccin) across kitty, bat, delta, btop, and k9s — Macchiato (dark) / Latte (light).

| Tool | Theme location |
| ------ | --------------- |
| kitty | `~/.config/kitty/theme.conf` (symlink: Macchiato or Latte) |
| bat | `~/.config/bat/themes/` (Macchiato + Latte, loaded automatically) |
| delta | inherits bat theme via `~/.config/git/config` |
| eza | `~/.config/eza/theme.yml` (symlink: Macchiato or Latte) *(alt_tools only)* |
| lazygit | `~/.config/lazygit/theme.yml` (symlink: Macchiato or Latte) |
| atuin | `~/.config/atuin/themes/` (Macchiato + Latte) |
| starship | palette set in `~/.config/starship.toml` (Macchiato or Latte) |
| zsh-syntax-highlighting | `~/.zsh/catppuccin_*.zsh` (sourced from env.zsh based on appearance) |
| btop | `~/.config/btop/themes/` (all four flavours: latte, frappé, macchiato, mocha) |
| k9s | `~/Library/Application Support/k9s/skins/` (all flavours; follows macOS appearance via `sync-theme`) *(kubernetes only)* |

`sync-theme` (a script in `~/.config/kitty/`) switches kitty and k9s between Latte and Macchiato. It is called by Hammerspoon (`~/.hammerspoon/init.lua`) which watches `AppleInterfaceThemeChangedNotification` — so all tools switch instantly when you toggle macOS appearance. Hammerspoon also updates the fresh editor theme via `~/.config/fresh/config.json`.
