# CLAUDE.md

**macOS-only, chezmoi-managed dotfiles that apply directly to the user's real machine.** Assumes Apple Silicon (`/opt/homebrew`), Homebrew, and macOS-only tools (`pbcopy`, Hammerspoon, etc.). There is no staging environment — `chezmoi apply` writes straight to `~`.

## Source vs. target naming (read this before touching anything)

This repo is chezmoi's **source** directory, not the live config. chezmoi renders source paths to **target** paths on `~` using its naming convention:

- `dot_` prefix → literal `.` in the target. `dot_zshrc.tmpl` → `~/.zshrc`. `dot_config/` → `~/.config/`. `dot_hammerspoon/` → `~/.hammerspoon/`. `dot_zsh/` → `~/.zsh/`.
- `.tmpl` suffix → the file is a Go template chezmoi renders (vars like `{{ if .dev_apps }}`), not literal output. `dot_zshrc.tmpl` → rendered → `~/.zshrc`; `dot_Brewfile.tmpl` → rendered → `~/Brewfile`; `dot_zsh/env.zsh.tmpl` → rendered → `~/.zsh/env.zsh`.

So: never edit `~/.zshrc`, `~/.config/...`, or any other rendered file on disk directly — edits get clobbered on the next `chezmoi apply` and never make it back to this repo. Always edit the `dot_*`/`*.tmpl` source file here, then apply. To pull a manual on-disk edit back into source, use `chezmoi re-add <target>` (or `dots-add`, see below).

## Workflow (aliases defined in `dot_zsh/aliases.zsh.tmpl`)

```zsh
dots-diff     # chezmoi diff — preview what would change, run before apply
dots-apply    # chezmoi apply — renders source and OVERWRITES the matching files on ~ live, no prompt
dots-status   # chezmoi status — what's out of sync
dots-edit     # chezmoi edit <file>
dots-add      # chezmoi add <file> — pull an existing ~ file into source
```

**`chezmoi apply` / `dots-apply` touches the real machine.** It silently overwrites the target files (`~/.zshrc`, `~/.config/...`, etc.) with the rendered source — always run `dots-diff` first when unsure, and never run apply as a "let's see what happens" step.

Bootstrap (fresh machine only): `install.sh` runs `chezmoi init <repo>` + `chezmoi apply`, then launches `dots-setup` (`dot_local/bin/executable_dots-setup`), the fzf wizard that picks the package profile and writes `~/.config/chezmoi/chezmoi.toml`.

## Layout

- `dot_zsh/` — modular shell config (`env`, `aliases`, `functions`), deferred/pre-generated for startup speed
- `dot_config/` — per-tool configs (atuin, bat, ghostty, git, k9s, lazygit, mise, opencode, sheldon, starship)
- `dot_hammerspoon/` — auto-reload config, macOS appearance → theme sync
- `dot_local/` — `bin/` scripts, incl. `dots-setup`
- `dot_Brewfile.tmpl` — Homebrew bundle, gated per-package by `{{ if .category }}` flags set via `dots-setup`
