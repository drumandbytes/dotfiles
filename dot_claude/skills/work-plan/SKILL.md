---
name: work-plan
description: Write a checklist plan to PLAN.md in the repo, then work through it task by task, ticking items off. Use when the user runs /work-plan.
disable-model-invocation: true
---

# Work plan

Lightweight plan -> execute loop. State lives in `PLAN.md` at the repo root, so it
survives `/clear` (pair with `/checkpoint` for decisions and context).

## Args

- **`<goal text>`**: no PLAN.md yet -> draft it, research its open questions (see
  below), revise it, show it, and stop for approval. PLAN.md already exists -> ask whether to replace it.
- **(no args)**: read PLAN.md, report done/remaining, and execute.
- **`next`**: do only the next unchecked task, then stop.

## PLAN.md format

```
# <goal, one line>

## Context
<2-4 lines: why, constraints, key files>

## Open questions
- <unknown that could change the plan>

## Tasks
- [ ] 1. <small, verifiable step> (files: a.py, b.py)
- [ ] 2. ...

## Verify
<the exact command(s) that prove it works>
```

Rules: 3-10 tasks, each finishable in one sitting and checkable by a command or a
diff. No sub-phases, no ceremony.

## Research (after the draft)

Draft first from what you already know; list real unknowns under `## Open questions`
(skip the section if there are none). Then resolve them, in parallel where
independent: an Explore subagent for codebase questions, WebSearch/WebFetch for
docs and prior art. Replace each question with a one-line finding (`- Q -> answer,
source`), then revise Tasks to match. Cap it at one round; anything still unknown
becomes an explicit task or a question to the user. Skip research entirely for
tasks with no real unknowns.

## Executing

1. Take the first unchecked task. Do it. Run its check.
2. Tick it (`- [x]`) in PLAN.md; add a one-line note under it only for surprises.
3. Commit per task only if the user asked for commits.
4. If the plan is wrong, edit PLAN.md first, tell the user why, then continue.
5. When all tasks are ticked, run `## Verify`, report the result, and ask whether
   to delete PLAN.md.

First time in a repo: add `PLAN.md` to `.git/info/exclude` (local, not `.gitignore`)
unless the user wants it tracked.
