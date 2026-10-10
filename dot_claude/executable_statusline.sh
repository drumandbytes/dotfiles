#!/bin/bash
# Custom Claude Code statusline: model, cwd, git branch/dirty/ahead-behind,
# context-window usage %, session cost/duration. Appends the RTK gain badge
# (real measured token savings from rtk's own log, not an estimate).

INPUT=$(cat)

DIM='\033[2m'
CYAN='\033[38;5;73m'
YELLOW='\033[38;5;179m'
RED='\033[38;5;167m'
GREEN='\033[38;5;108m'
RESET='\033[0m'

MODEL=$(printf '%s' "$INPUT" | jq -r '.model.display_name // "?"')
DIR=$(printf '%s' "$INPUT" | jq -r '.workspace.current_dir // .cwd // "."')
DIRNAME=$(basename "$DIR")

GIT_PART=""
if git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
  [ -z "$BRANCH" ] && BRANCH="detached"

  DIRTY=""
  if [ -n "$(git -C "$DIR" status --porcelain 2>/dev/null)" ]; then
    DIRTY="*"
  fi

  AHEAD_BEHIND=""
  read -r BEHIND AHEAD <<< "$(git -C "$DIR" rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null)"
  if [ -n "$AHEAD" ] || [ -n "$BEHIND" ]; then
    [ "$AHEAD" != "0" ] && [ -n "$AHEAD" ] && AHEAD_BEHIND="${AHEAD_BEHIND}↑${AHEAD}"
    [ "$BEHIND" != "0" ] && [ -n "$BEHIND" ] && AHEAD_BEHIND="${AHEAD_BEHIND}↓${BEHIND}"
  fi

  GIT_PART=" ${DIM}|${RESET} ${CYAN}${BRANCH}${DIRTY}${RESET}"
  [ -n "$AHEAD_BEHIND" ] && GIT_PART="${GIT_PART} ${DIM}${AHEAD_BEHIND}${RESET}"
fi

INPUT_TOKENS=$(printf '%s' "$INPUT" | jq -r '.context_window.total_input_tokens // empty')
CTX_USED=$(printf '%s' "$INPUT" | jq -r '.context_window.used_percentage // empty')
if [ -z "$CTX_USED" ]; then
  WINDOW_SIZE=$(printf '%s' "$INPUT" | jq -r '.context_window.context_window_size // empty')
  if [ -n "$INPUT_TOKENS" ] && [ -n "$WINDOW_SIZE" ] && [ "$WINDOW_SIZE" != "0" ]; then
    CTX_USED=$(awk -v u="$INPUT_TOKENS" -v s="$WINDOW_SIZE" 'BEGIN{printf "%.0f", (u/s)*100}')
  fi
fi

CTX_PART=""
if [ -n "$CTX_USED" ]; then
  CTX_COLOR="$GREEN"
  if [ "$CTX_USED" -ge 80 ] 2>/dev/null; then
    CTX_COLOR="$RED"
  elif [ "$CTX_USED" -ge 50 ] 2>/dev/null; then
    CTX_COLOR="$YELLOW"
  fi
  CTX_PART=" ${DIM}|${RESET} ${CTX_COLOR}ctx ${CTX_USED}%${RESET}"
fi

# Checkpoint reminder: tiered on ABSOLUTE input tokens, not % of window.
# With a 1M window, % is a bad proxy for cost -- every turn resends the
# full token count regardless of how big the ceiling is.
if [ -n "$INPUT_TOKENS" ]; then
  if [ "$INPUT_TOKENS" -ge 300000 ] 2>/dev/null; then
    CTX_PART="${CTX_PART} ${RED}CHECKPOINT NOW${RESET}"
  elif [ "$INPUT_TOKENS" -ge 150000 ] 2>/dev/null; then
    CTX_PART="${CTX_PART} ${YELLOW}checkpoint soon${RESET}"
  elif [ "$INPUT_TOKENS" -ge 50000 ] 2>/dev/null; then
    CTX_PART="${CTX_PART} ${DIM}chk?${RESET}"
  fi
fi

# Haiku 5.5 bills a prompt at the long rate once it passes 100K input tokens
# (cache read $0.01 -> $0.05 per M). Prompt size = this request's full input,
# not the session total, so prefer current_usage and fall back to the total.
PROMPT_TOKENS=$(printf '%s' "$INPUT" | jq -r '
  .context_window.current_usage as $u
  | if $u then (($u.input_tokens // 0) + ($u.cache_read_input_tokens // 0) + ($u.cache_creation_input_tokens // 0))
    else (.context_window.total_input_tokens // empty) end')
MODEL_ID=$(printf '%s' "$INPUT" | jq -r '.model.id // ""')
HAIKU_PART=""
if [[ "${MODEL_ID} ${MODEL}" == *[Hh]aiku* ]] && [ -n "$PROMPT_TOKENS" ] 2>/dev/null; then
  if [ "$PROMPT_TOKENS" -gt 100000 ] 2>/dev/null; then
    HAIKU_COST=$(awk -v t="$PROMPT_TOKENS" 'BEGIN{printf "%.3f", t*0.05/1000000}')
    HAIKU_PART=" ${RED}>100k 5x${RESET} ${DIM}~\$${HAIKU_COST}/turn cached${RESET}"
  elif [ "$PROMPT_TOKENS" -ge 80000 ] 2>/dev/null; then
    HAIKU_PART=" ${YELLOW}100k in $(( 100000 - PROMPT_TOKENS ))${RESET}"
  fi
fi

COST=$(printf '%s' "$INPUT" | jq -r '.cost.total_cost_usd // empty')
COST_PART=""
if [ -n "$COST" ]; then
  COST_FMT=$(awk -v c="$COST" 'BEGIN{printf "%.2f", c}')
  COST_PART=" ${DIM}|${RESET} \$${COST_FMT}"
fi

DURATION_MS=$(printf '%s' "$INPUT" | jq -r '.cost.total_duration_ms // empty')
DUR_PART=""
if [ -n "$DURATION_MS" ]; then
  DUR_MIN=$(awk -v d="$DURATION_MS" 'BEGIN{printf "%.0f", d/60000}')
  DUR_PART=" ${DIM}${DUR_MIN}m${RESET}"
fi

LINES_ADDED=$(printf '%s' "$INPUT" | jq -r '.cost.total_lines_added // empty')
LINES_REMOVED=$(printf '%s' "$INPUT" | jq -r '.cost.total_lines_removed // empty')
LINES_PART=""
if [ -n "$LINES_ADDED" ] || [ -n "$LINES_REMOVED" ]; then
  LINES_PART=" ${DIM}|${RESET} ${GREEN}+${LINES_ADDED:-0}${RESET} ${RED}-${LINES_REMOVED:-0}${RESET}"
fi

printf "${CYAN}[%s]${RESET} ${DIM}%s${RESET}%b%b%b%b%b%b" \
  "$MODEL" "$DIRNAME" "$GIT_PART" "$CTX_PART" "$HAIKU_PART" "$COST_PART" "$DUR_PART" "$LINES_PART"

if command -v rtk >/dev/null 2>&1; then
  RTK_JSON=$(rtk gain --format json 2>/dev/null)
  RTK_SAVED=$(printf '%s' "$RTK_JSON" | jq -r '.summary.total_saved // empty' 2>/dev/null)
  if [ -n "$RTK_SAVED" ]; then
    RTK_PCT=$(printf '%s' "$RTK_JSON" | jq -r '.summary.avg_savings_pct // 0')
    RTK_SAVED_FMT=$(awk -v n="$RTK_SAVED" 'BEGIN{
      if (n >= 1000000) printf "%.1fM", n/1000000;
      else if (n >= 1000) printf "%.1fk", n/1000;
      else printf "%d", n;
    }')
    RTK_PCT_FMT=$(awk -v p="$RTK_PCT" 'BEGIN{printf "%.0f", p}')
    printf ' %b|%b ⚡ %s (%s%%)' "$DIM" "$RESET" "$RTK_SAVED_FMT" "$RTK_PCT_FMT"
  fi
fi

printf '\n'
