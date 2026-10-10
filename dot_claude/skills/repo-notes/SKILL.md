---
name: repo-notes
description: Crawl a repo once, cache architecture notes per module keyed to the git commit that produced them, and update only the modules whose paths changed since. Use when the user runs /repo-notes.
disable-model-invocation: true
---

# Repo notes

Personal cost-optimization tool. Purpose: stop paying to re-explore the same
codebase areas every session. Crawls once, writes per-module notes to
`~/.claude/repo-notes/<project-slug>/`, and on later runs only re-crawls
modules whose files actually changed since the note was written — checked via
`git diff --name-only <stored-commit> HEAD -- <module paths>`.

`<project-slug>` = current working directory with `/` replaced by `-`.

## Defer to existing docs first — do not duplicate them

Before crawling anything, check whether the repo already documents itself.
For this repo (scoro-base): read `docs/README.md` for the full doc index, and
`AGENTS.md` for the domain list. Any module with a `docs/<module>*.md` file is
**docs-backed** — do not crawl or summarize it yourself. Record only a
pointer: the doc path and the commit that last touched that doc file
(`git log -1 --format=%H -- docs/<module>.md`). Docs are the maintained
source of truth; a personal shadow copy would drift and contradict them.

Only modules with **no** existing doc get a personal note written by this
skill (**note-backed**).

## Arguments

- **(no args)**: show the index — every module, whether it's docs-backed or
  note-backed, and for note-backed modules whether HEAD has diverged from the
  stored commit (run `git diff --quiet <stored-commit> HEAD -- <paths>` per
  module; report which ones are stale).
- **`crawl`**: full run. Enumerate modules (domains under `/src`, top-level
  dirs under `/inc`, top-level areas under `/app`). For each:
  - docs-backed → write a pointer entry only, no crawl.
  - note-backed → dispatch one Agent (read-only, Explore or general-purpose)
    per module to produce a concise note (architecture, key files/entry
    points, non-obvious invariants — skip anything a doc-comment already
    says). Run a handful concurrently, not all at once — this is a real
    one-time cost, keep it bounded and tell the user progress as modules
    finish.
  - Write `~/.claude/repo-notes/<project-slug>/<module-slug>.md` with
    frontmatter:
    ```
    ---
    module: <slug>
    kind: note | docs-pointer
    commit: <sha this reflects>
    paths:
      - <path>
    doc_path: <only for docs-pointer>
    ---
    ```
  - Write `~/.claude/repo-notes/<project-slug>/index.md` listing every module,
    its kind, and its stored commit.
- **`update`**: incremental. For every note-backed module, diff stored commit
  against HEAD over its `paths`. Unchanged → leave alone. Changed → re-crawl
  just that module the same way `crawl` does, and overwrite its note +
  bump its stored commit. For docs-pointer modules, only refresh the stored
  commit if the doc file itself changed; never crawl code for these.
- **`diff <module>`**: show `git diff <stored-commit>..HEAD -- <paths>` for
  that module (or `git log --oneline <stored-commit>..HEAD -- <paths>` if the
  full diff is large) — lets the user see what moved before deciding whether
  a re-crawl is worth it.
- **`show <module>`**: print the module's note, or point to its doc file if
  docs-backed.

## Keep notes tight

Same bar as the compact-instructions convention in this user's global
CLAUDE.md: decisions and non-obvious invariants over restated code. A note
that just re-describes what a competent reader would get from opening the
file isn't worth its token cost on every future read.
