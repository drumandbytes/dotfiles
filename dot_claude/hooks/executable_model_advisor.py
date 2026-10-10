#!/usr/bin/env python3
"""Claude Code model advisor: blocks a prompt once when the current model
doesn't fit the task, and suggests one. Resending the same prompt within
10 minutes, or prefixing "!", lets it through. Fails open on any error.
"""

import json
import re
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
LOG_FILE = HERE / "model-advisor.log"
STATE_FILE = HERE / ".model-advisor-state.json"
MODEL_FILE = HERE / ".model-advisor-current-model.json"

RESEND_WINDOW_SECONDS = 600
IMAGE_SUFFIXES = (".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".svg")

# Bare acknowledgements continue the last turn; never advise on them.
FOLLOWUP = re.compile(
    r"^(yes|y|ok|okay|do it|continue|go ahead|thanks|please|sure|proceed)[\s.!?]*$",
    re.I,
)
# Short questions are lookups. An imperative verb makes it a task instead.
QUESTION_START = re.compile(r"^(do|does|did|is|are|was|were|where|what|which|who|can|have|has)\b")
IMPERATIVE = re.compile(
    r"\b(refactor|write|add|fix|implement|create|build|change|update|rename|delete|remove|make|move)\b"
)

FABLE, OPUS, SONNET, HAIKU = "Fable 5.1", "Opus 5.5", "Sonnet 5.5", "Haiku 5.5"

# name, suggested model, substrings that count as a fit, trigger regexes.
# First match wins, so order runs from highest stakes down to the cheap lookups.
JOBS = [
    ("prod incident", FABLE, ["fable", "opus"], [
        r"\b(prod(uction)?|sev[0-3]|p[0-1]|outage|incident|hotfix|rollback)\b",
        r"\b(site|service|app) (is )?(down|on fire)\b",
    ]),
    ("need to read images", SONNET, ["sonnet", "opus"], [
        r"\b(screenshot|figma|diagram|whiteboard|mockup)s?\b",
        r"\b(read|from|in) (this |the )?(image|photo|png|jpg)\b",
        r"\berror popup\b",
        r"\.(png|jpe?g|webp|gif)\b",
    ]),
    ("execute a clear plan", SONNET, ["sonnet", "opus"], [
        r"\b(execute|implement|follow|build|run) (the |this |our )?plan\b",
        r"\bdo (exactly )?what the plan says\b",
    ]),
    ("write a plan", SONNET, ["sonnet", "opus"], [
        r"\b(write|make|create|draft) (a |the )?plan\b",
        r"\bplan (for|how|mode)\b",
    ]),
    ("architecture / hard constraints", OPUS, ["opus"], [
        r"\barchitect",
        r"\bdesign (a |the )?(system|service|api|schema)\b",
        r"\b(don'?t|do not) (touch|change|break)\b",
        r"\bhard constraint",
        r"\btrade-?offs?\b",
    ]),
    ("security review", OPUS, ["opus"], [
        r"\bsecurity (review|audit)\b",
        r"\bwould i ship\b",
        r"\bthreat model",
    ]),
    ("hard debug", OPUS, ["opus", "sonnet"], [
        r"\broot cause\b",
        r"\brace condition",
        r"\bdeadlock",
        r"\b(heisenbug|flaky|intermittent(ly)?)\b",
    ]),
    ("math / algorithms / crypto", OPUS, ["opus"], [
        r"\balgorithm",
        r"\bcrypto\b",
        r"\bcombinator",
    ]),
    ("tests / lint / mechanical", HAIKU, ["haiku", "sonnet"], [
        r"\b(lint|linting|format(ting)?|typo|docstring|reformat)\b",
        r"\b(add|write|fix|update) (the |some |more |these )?tests?\b",
    ]),
    ("UI / frontend", SONNET, ["sonnet", "opus"], [
        r"\b(ui|css|scss|vue|frontend|layout|spacing|padding|margin|stylesheet|sui)\b",
        r"\bdesign system\b",
    ]),
    ("research / docs", SONNET, ["sonnet", "opus"], [
        r"\bresearch\b",
        r"\b(pdf|documentation)\b",
        r"\bwhat does .{0,40}\b(say|mean|describe)\b",
    ]),
    ("large repo / 1M context", SONNET, ["sonnet", "opus", "fable"], [
        r"\b(whole|entire|full) (codebase|repo|monorepo|project)\b",
        r"\bacross (the )?(codebase|repo|all services)\b",
    ]),
    ("complex implementation", SONNET, ["sonnet", "opus"], [
        r"\bimplement (the )?(spec|ticket|plan)\b",
        r"\balready (scoped|planned|specified)\b",
    ]),
    ("long agent loop", OPUS, ["opus", "fable"], [
        r"\b(keep going|don'?t stop|until (the )?tests pass)\b",
    ]),
    ("lookup / mechanical", HAIKU, ["haiku", "sonnet"], [
        r"\bgit\s+(status|diff|log|show|branch|stash|blame)\b",
        r"\b(check|show|print|dump|what'?s|what is)\b.{0,60}\b(git\s+)?status\b",
        r"\bdo we have\b",
        r"\bwhere (is|are|does)\b",
        r"\b(what|which).{0,50}\bin (the )?(code|repo|project|codebase)\b",
        r"\bcurrent branch\b",
        r"\bworking tree\b",
        r"\buncommitted\b",
    ]),
]

JOB = {job[0]: job for job in JOBS}
EVERYDAY = ("everyday iterate", SONNET, ["sonnet", "haiku"])

# Each case must classify to the named job; add one whenever a misfire is found.
CASES = [
    ("do we have integrations in the code", "lookup / mechanical"),
    ("what does this function return", "lookup / mechanical"),
    ("can you refactor the whole auth module", "everyday iterate"),
    ("fix the tests in the parser", "tests / lint / mechanical"),
    ("architect a payments service", "architecture / hard constraints"),
    ("production is down, fix it", "prod incident"),
    ("why is the worker deadlocking", "hard debug"),
]


def matches_any(patterns, text):
    return any(re.search(p, text) for p in patterns)


def has_image(payload):
    for att in payload.get("attachments") or []:
        path = (att.get("file_path") or att.get("path") or "").lower()
        if path.endswith(IMAGE_SUFFIXES) or str(att.get("type") or "").lower() in {"image", "figure"}:
            return True
    return False


def classify(prompt, payload):
    text = prompt.lower()
    if has_image(payload):
        return JOB["need to read images"][:3]
    if payload.get("permission_mode") == "plan":
        return JOB["write a plan"][:3]
    for job in JOBS:
        if matches_any(job[3], text):
            return job[:3]
    if len(prompt.split()) <= 14 and QUESTION_START.match(text) and not IMPERATIVE.search(text):
        return JOB["lookup / mechanical"][:3]
    return EVERYDAY


def model_fits(model, allow):
    if not model:
        return True
    m = model.lower()
    return any(n in m for n in allow)


def log(entry):
    try:
        HERE.mkdir(parents=True, exist_ok=True)
        with LOG_FILE.open("a") as f:
            f.write(json.dumps(entry) + "\n")
    except OSError:
        pass


def already_advised(prompt):
    try:
        state = json.loads(STATE_FILE.read_text())
        if state.get("prompt") == prompt and time.time() - state.get("ts", 0) < RESEND_WINDOW_SECONDS:
            STATE_FILE.unlink(missing_ok=True)
            return True
    except (OSError, ValueError):
        pass
    return False


def remember_advised(prompt):
    try:
        STATE_FILE.write_text(json.dumps({"prompt": prompt, "ts": time.time()}))
    except OSError:
        pass


def remember_model(model):
    if not model:
        return
    try:
        MODEL_FILE.write_text(json.dumps({"model": model, "ts": time.time()}))
    except OSError:
        pass


def stored_model():
    try:
        return json.loads(MODEL_FILE.read_text()).get("model") or ""
    except (OSError, ValueError):
        return ""


def resolve_model(payload):
    for key in ("model", "model_id", "to_model"):
        value = payload.get(key)
        if value:
            return str(value)
    return stored_model()


def allow():
    print("{}")


def block(message, prompt):
    remember_advised(prompt)
    print(json.dumps({"decision": "block", "reason": message}))


def handle_model_event(payload):
    event = payload.get("hook_event_name") or ""
    if event == "SessionStart":
        remember_model(payload.get("model") or "")
        allow()
        return True
    if event == "PostModelSwitch":
        remember_model(payload.get("to_model") or payload.get("model") or "")
        allow()
        return True
    return False


def main():
    payload = json.load(sys.stdin)
    if handle_model_event(payload):
        return

    prompt = (payload.get("prompt") or "").strip()
    model = resolve_model(payload)

    if not prompt or prompt.startswith(("!", "/")) or FOLLOWUP.match(prompt):
        allow()
        return

    if already_advised(prompt):
        log({"ts": int(time.time()), "decision": "allow-resend", "model": model})
        allow()
        return

    job, suggested, fits = classify(prompt, payload)
    if model_fits(model, fits):
        log({"ts": int(time.time()), "decision": "allow-fit", "model": model, "job": job})
        allow()
        return

    log({"ts": int(time.time()), "decision": "block-mismatch", "model": model,
         "job": job, "prompt": prompt[:120]})
    block(
        f"Model advisor: this looks like {job}. Use {suggested} "
        f"(you're on '{model or 'unknown'}'). Switch and resend, or press Enter again to keep "
        f"this model. Prefix ! also skips the warning.",
        prompt,
    )


def selftest():
    for prompt, expected in CASES:
        got = classify(prompt, {})[0]
        assert got == expected, f"{prompt!r}: got {got!r}, want {expected!r}"
    print("selftest ok")


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        selftest()
        sys.exit(0)
    try:
        main()
    except Exception:
        allow()
    sys.exit(0)
