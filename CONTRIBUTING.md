# Contributing

This repo is built to be **forked** — most people are better served maintaining
their own copy than sending a PR here (see [Forking](README.md#forking)). That
said, fixes and broadly useful improvements are welcome upstream.

## What's useful to contribute

- Bug fixes (broken scripts, incorrect chezmoi templates, etc.)
- Compatibility improvements
- New `comp-add` / `uv-add` patterns that don't work yet
- Documentation fixes

## What might be merged

- Tool suggestions (replacements or additions) — open to discussion if there's a good case for it

## What won't be merged

- Changes that break the macOS-only scope
- Personal preferences better kept in your own fork (specific package picks,
  profile presets, theme choices)

## How to contribute

1. Fork the repo and clone your fork
2. Create a branch: `git checkout -b fix/describe-your-change`
3. Make your change and verify it:
   - **Preview the effect** with `dots-diff` (alias for `chezmoi diff`)
   - **Render templates** the way CI does — e.g. `chezmoi execute-template < path/to/file.tmpl` (see the full matrix in [`.github/workflows/ci.yml`](.github/workflows/ci.yml))
   - Shell scripts are linted with `shellcheck` and `shfmt -i 4`
4. Open a pull request with a clear description

## Reporting issues

Use the issue templates — they keep things structured and make it easier to help.
