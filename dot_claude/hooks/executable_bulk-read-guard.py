#!/usr/bin/env python3
"""PreToolUse(Read): block whole-file reads of big text files in the main agent.

Subagents (hook input carries agent_id) are exempt, so delegating to one works.
Threshold: BULK_READ_MIN_LINES env, default 400.
"""
import json
import os
import sys

SKIP_EXT = {".pdf", ".png", ".jpg", ".jpeg", ".gif", ".webp", ".ipynb", ".svg"}

try:
    data = json.load(sys.stdin)
except ValueError:
    sys.exit(0)

if data.get("agent_id"):
    sys.exit(0)

inp = data.get("tool_input") or {}
path = inp.get("file_path", "")
if inp.get("offset") or inp.get("limit") or os.path.splitext(path)[1].lower() in SKIP_EXT:
    sys.exit(0)

try:
    with open(path, "rb") as f:
        lines = sum(chunk.count(b"\n") for chunk in iter(lambda: f.read(1 << 20), b""))
except OSError:
    sys.exit(0)

limit = int(os.environ.get("BULK_READ_MIN_LINES", "400"))
if lines > limit:
    print(
        f"Blocked: {path} has {lines} lines (> {limit}). To understand/summarize it, "
        "delegate to an Explore subagent (model haiku) with the question. "
        "To edit a specific region, re-Read with offset/limit.",
        file=sys.stderr,
    )
    sys.exit(2)
