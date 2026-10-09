---
name: checkpoint
description: Save or load a per-topic progress checkpoint to a local markdown file, so work survives /clear without paying to keep it in conversation context. Use when the user runs /checkpoint.
disable-model-invocation: true
---

# Checkpoint

Personal cost-optimization tool. Purpose: let the user run `/clear` freely between
tasks without losing progress, instead of keeping a long paid conversation alive
just to remember state. Checkpoints live outside the conversation, in
`~/.claude/checkpoints/<project-slug>/<topic-slug>.md`, where `<project-slug>` is
the current working directory with `/` replaced by `-` (matches Claude Code's own
project-folder naming).

## Arguments

The skill receives free-text args after `/checkpoint`:

- **(no args)**: list existing checkpoints for the current project (filenames +
  first-line goal + last-modified time). Tell the user which ones exist; don't
  dump full contents.
- **`save <topic>`** or **`<topic>`** where no checkpoint with that slug exists yet:
  write a new checkpoint (see "What to save" below).
- **`<topic>`** matching an existing checkpoint file: read that file back in full
  and summarize it to the user as "resuming from checkpoint: ...". This is how
  the user picks up work after a `/clear`.
- **`update <topic>`**: re-save an existing checkpoint, merging new progress into
  what's already there rather than starting over — don't just append, rewrite
  each section with current state.

Slugify topics as lowercase kebab-case.

## What to save

Mirror the compact-instructions convention already in this user's global
CLAUDE.md — same four categories, written concisely, no filler:

1. **Goal** — one or two sentences on what this thread of work is trying to
   accomplish.
2. **Decisions & rationale** — choices made and why, especially anything
   non-obvious or where an alternative was rejected.
3. **Code changes so far** — files touched and what changed, not full diffs.
4. **Test/build output** — verbatim failures or key results, only if relevant.
5. **Open TODOs / next steps** — what's unfinished, in priority order.

Write the file with `Write`, creating the project checkpoint directory first if
needed (`mkdir -p ~/.claude/checkpoints/<project-slug>`). Keep it tight — this
file gets read back in full on resume, so bloat here defeats the purpose.

## After saving

Tell the user the checkpoint path and that it's now safe to `/clear`. Don't
suggest `/clear` unprompted — that's the user's call.
