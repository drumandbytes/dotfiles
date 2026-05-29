# dotfiles

Personal **macOS** dotfiles managed with [chezmoi](https://chezmoi.io).

> **macOS only.** Assumes Homebrew, Apple Silicon paths (`/opt/homebrew`), and macOS-specific tools (`pbcopy`, `mac-cleanup`, etc.). Not tested on Linux.

## What's included

| Config | Description |
| -------- | ----------- |
| `~/.zshrc` | Zsh entrypoint — modular, deferred, fast |
| `~/.zsh/env.zsh` | Exports, PATH, editor |
| `~/.zsh/aliases.zsh` | Shell aliases (eza, k8s, git, maintenance, etc.) |
| `~/.zsh/functions.zsh` | Functions: `mnt`, `brewsync`, `comp-add`, `bw-search`, `_fzf_menu`, lazy loaders |
| `~/.config/sheldon/plugins.toml` | Zsh plugin manager config |
| `~/.config/starship.toml` | Prompt |
| `~/.config/kitty/` | Terminal (kitty.conf + Catppuccin themes) |
| `~/.config/git/config` | Git: delta pager, diff3 merge style |
| `~/.config/bat/` | bat config + Catppuccin themes |
| `~/.config/eza/` | eza color theme (Catppuccin symlink) |
| `~/.config/lazygit/` | lazygit config + Catppuccin theme |
| `~/.config/atuin/` | Shell history config + Catppuccin themes |
| `~/.hammerspoon/init.lua` | Auto-reload config; theme sync on macOS appearance change |
| `~/.local/share/navi/cheats/custom.cheat` | Custom navi cheatsheets (macOS, docker, kubernetes) |

## Runtime version management

Language runtimes are managed by [mise](https://mise.jdx.dev) rather than Homebrew, so versions can be pinned per project via `.mise.toml`:

| Runtime | Global version |
| --------- | --------------- |
| `node` | LTS |
| `uv` | latest |
| `ruff` | latest |

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

After the initial apply, run the machine profile wizard to select packages and features:

```zsh
dots-setup
```

`dots-setup` is an interactive fzf wizard that lets you choose a starting profile (work, personal, minimal, full) and then fine-tune individual packages. It writes `~/.config/chezmoi/chezmoi.toml` and runs `chezmoi apply`.

| Profile | Included categories |
| ------- | ------------------- |
| `work` | alt_tools, bitwarden, docker, kubernetes, dev_apps, macos_utils, macos_media |
| `personal` | alt_tools, bitwarden, macos_utils, macos_cosmetic, macos_media, productivity, peripherals |
| `minimal` | alt_tools only |
| `full` | Everything |

Package categories you can toggle:

| Category | What it installs |
| -------- | ---------------- |
| `alt_tools` | Modern CLI replacements: bat, eza, fd, ripgrep, dust, duf, navi, xh… |
| `bitwarden` | Bitwarden CLI + app |
| `docker` | Docker via Colima |
| `kubernetes` | kubectl, kubectx, k9s, helm, vault, stern, kustomize, gcloud CLI |
| `macos_utils` | Raycast, Hammerspoon, AltTab, Mos, Linearmouse, NordVPN, UTM… |
| `macos_cosmetic` | AirBattery, Cork |
| `macos_media` | Brave, Slack, Spotify, Telegram, IINA |
| `dev_apps` | VSCodium, DBeaver, GIMP, GitHub CLI, GitLab CLI, Cloudflared, hcloud… |
| `touchbar` | BetterTouchTool (TouchBar Macs only) |
| `gaming` | Steam, Discord |
| `productivity` | Notion, Obsidian, Grammarly, Calibre, Flux Markdown |
| `peripherals` | 8BitDo, QMK Toolbox, BalenaEtcher, F3 |

On first apply, chezmoi automatically:

1. Runs `brew bundle --global` to install all selected Homebrew packages
2. Runs `mise install` to set up language runtimes
3. Generates static init files and completions (`~/.zsh/*_init.zsh`, `~/.zsh/completions/`)
4. Seeds a Colima config (`~/.colima/default/colima.yaml`) optimised for Apple Silicon
5. Generates navi cheatsheets and clones community repos

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

## Key functions & aliases

| Command | Description |
| ------- | ----------- |
| `mnt` | Full maintenance: sync dotfiles, brew upgrade, sheldon update, regenerate inits & completions, recompile, backup, reload |
| `brew-up` | Homebrew update + upgrade + cleanup + tldr update |
| `brewsync` | Interactively promote untracked brew packages into the chezmoi-managed Brewfile |
| `comp-add <tool>` | Auto-detect and add zsh completions for a new tool; persists to chezmoi source |
| `uv-add <package>` | Install a global uv tool and persist it to `run_onchange_uv-tools.sh` |
| `sh-add <user/repo>` | Add a deferred sheldon plugin; persists to sheldon config |
| `bw-search` | fzf Bitwarden item search |
| `help-cmd` | fzf search over all aliases and functions |
| `fkill` | fzf process killer |
| `zsh-bak` | Zip backup of zsh config to `~/Backups/zsh/` |

### dots-* aliases

| Alias | Command |
| ----- | ------- |
| `dots-setup` | Run the machine profile wizard |
| `dots-apply` | `chezmoi apply` |
| `dots-diff` | `chezmoi diff` |
| `dots-status` | `chezmoi status` |
| `dots-edit` | `chezmoi edit <file>` |
| `dots-add` | `chezmoi add <file>` |
| `dots-push` | Push chezmoi source to remote |
| `dots-log` | Last 20 commits in chezmoi source |

## Optional: Bitwarden

When Bitwarden is enabled, `~/.local/bin/bw-vault` is installed — a thin wrapper around the `bw` CLI that caches the session token in `/var/root/.bitwarden.session` so non-interactive scripts can call it without prompting.

```zsh
bw-vault list items            # auto-authenticates, returns items JSON
bw-vault get password <id>     # get a specific credential
bw-vault --regen               # force re-login and refresh session
```

The `bw-search` shell function uses this for interactive fzf-based vault search with clipboard copy.

## Optional: Touch ID for sudo

When Touch ID for sudo is enabled, a one-time script writes `/etc/pam.d/sudo_local` — a macOS 14+ (Sonoma) file that survives OS updates. To re-run it:

```zsh
chezmoi state delete-bucket --bucket=scriptState
dots-apply
```

## History

Shell history is managed by [atuin](https://atuin.sh) with sqlite backend and optional sync. Import existing history with:

```zsh
atuin import auto
atuin sync
```

## Day-to-day workflow

```zsh
dots-apply              # apply pending changes
dots-diff               # preview what would change
dots-status             # show which files are out of sync
dots-edit ~/.zshrc      # edit a managed file and apply
dots-push               # push source changes to remote
chezmoi update          # pull latest from remote and apply
```

To add a new file to chezmoi management:

```zsh
dots-add ~/.config/something
```

## Adding packages and tools

```zsh
dots-setup              # re-run wizard to change profile or toggle packages
brewsync                # detect untracked brew packages and add them to the Brewfile interactively
comp-add <toolname>     # add a zsh completion; auto-detects syntax, persists to chezmoi source
uv-add <package>        # install a global uv tool and persist it to run_onchange_uv-tools.sh
sh-add <user/repo>      # add a deferred sheldon plugin and persist it to plugins.toml
```

To remove a package permanently, delete it from `dot_Brewfile.tmpl` and from the relevant category in `dot_local/bin/executable_dots-setup`.

## Navi

[navi](https://github.com/denisidoro/navi) is a command-line cheatsheet tool. Press **Ctrl+G** mid-command to search cheatsheets and insert a command into the prompt. Or run `navi` to browse interactively.

On first `chezmoi apply`, `run_onchange_navi-cheats.sh.tmpl` auto-generates `~/.local/share/navi/cheats/personal.cheat` from your aliases and functions, and clones community repos. The personal cheat file is regenerated automatically whenever `aliases.zsh` or `functions.zsh` changes.

| Source | What it covers |
| ------ | -------------- |
| `personal.cheat` | All your aliases and functions, auto-generated |
| `custom.cheat` | macOS system/network/defaults, docker/colima, kubectl/helm |
| `denisidoro/cheats` | General shell cheatsheets |
| `denisidoro/navi-tldr-pages` | tldr pages in navi format (~2000 commands) |
| `tg-z/navi-cheats` | macOS-focused: brew, `defaults`, network tools |
| `tsologub/navi-cheats` | kubectl, helm, docker *(kubernetes only)* |

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
| k9s | `~/.config/k9s/skins/` (all flavours; follows macOS appearance via `sync-theme`) *(kubernetes only)* |

`sync-theme` (a script in `~/.config/kitty/`) switches kitty and k9s between Latte and Macchiato. It is called by Hammerspoon (`~/.hammerspoon/init.lua`) which watches `AppleInterfaceThemeChangedNotification` — so all tools switch instantly when you toggle macOS appearance.

## Troubleshooting

**`chezmoi update` fails with merge conflicts or "git: exit status 1"**

```zsh
src=$(chezmoi source-path)
git -C "$src" fetch origin main
git -C "$src" checkout -B main origin/main
dots-apply
```

Or run `mnt` — it calls `_chezmoi_sync` as its first step which handles wrong branch, missing tracking, and diverged commits.

**chezmoi apply shows an unexpected diff**

Use `dots-diff` to review it, then `overwrite` to apply the source or `skip` to keep the current file. To pull the current state back into source: `chezmoi re-add ~/.config/...`.

**Re-run a one-time script (e.g. Colima config)**

```zsh
chezmoi state delete-bucket --bucket=scriptState
dots-apply
```
