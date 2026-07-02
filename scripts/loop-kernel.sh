#!/usr/bin/env bash
# loop-kernel.sh — Loop Engineering runtime for Genius Team (LP-02)
#
# Bash helpers called by the genius-loop skill. Materializes the loop contract
# (goal / gate / brakes / blast_radius / state / autonomy_level / checker)
# produced by genius-goal-contract at .genius/loops/<slug>/CONTRACT.md.
#
# Namespace: everything lives under .genius/loops/<slug>/ — the kernel NEVER
# touches .genius/state.json or .claude/plan.md (owned by the Stop hook sync).
#
# Commands:
#   contract_validate <loop_dir|CONTRACT.md>   exit 0 = contract is runnable
#   state_read        <loop_dir>               init if missing, print STATE.md
#   state_get         <loop_dir> <key>         print one metadata value
#   state_write       <loop_dir> <status> <gate_exit> [gate_output]
#   brakes_check      <loop_dir>               0=iterate 2=max_iter 3=no_progress
#                                              4=flip_flop 10=done 11=blocked
#   gate_run          <loop_dir>               run the gate with timeout, print exit
#   loop_report       <loop_dir>               end-of-loop summary
#
# The 4 deaths this kernel prevents:
#   runaway recursion -> max_iterations cap (brakes_check)
#   silent death      -> gate timeout (gate_run); a hung gate FAILS the run
#   random walk       -> gate is an objective command, never agent opinion
#   comprehension debt-> autonomy_level gates human approval (enforced by skill)

set -euo pipefail

HISTORY_KEEP=10

# ---------------------------------------------------------------- helpers ----

_die() { echo "loop-kernel: ERROR: $*" >&2; exit 1; }

_now() { date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z'; }

_project_root() { git rev-parse --show-toplevel 2>/dev/null || pwd -P; }

_hash() {
  # stdin -> short deterministic hash
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print substr($1,1,12)}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print substr($1,1,12)}'
  else
    cksum | awk '{print $1}'
  fi
}

_resolve_loop_dir() {
  # accept either the loop dir or a direct path to CONTRACT.md
  local arg="${1:-}"
  [ -n "$arg" ] || _die "missing <loop_dir> argument"
  if [ -f "$arg" ]; then dirname "$arg"; else echo "${arg%/}"; fi
}

_contract_path() { echo "$1/CONTRACT.md"; }
_state_path()    { echo "$1/STATE.md"; }

_section() {
  # _section <file> <header-regex> -> body of "## <header>" section
  awk -v h="$2" '
    $0 ~ "^## " h { insec = 1; next }
    insec && /^## / { exit }
    insec { print }
  ' "$1"
}

_gate_cmd() {
  # command inside the fenced block of the Gate section
  _section "$1" "Gate" | awk '/^```/ { f = !f; next } f { print }' \
    | sed '/^[[:space:]]*$/d'
}

_gate_timeout() {
  # "- Timeout: 300s" in the Gate section; default 300
  local t
  t=$(_section "$1" "Gate" | grep -iE '^- *Timeout:' | head -1 \
      | sed -E 's/^- *[Tt]imeout: *([0-9]+).*/\1/' || true)
  case "$t" in (''|*[!0-9]*) echo 300 ;; (*) echo "$t" ;; esac
}

_brake() {
  # _brake <contract> <field> -> numeric value or empty
  grep -E "^- *$2: *[0-9]+" "$1" | head -1 \
    | sed -E "s/^- *$2: *([0-9]+).*/\1/" || true
}

_autonomy() {
  grep -E '^- *autonomy_level: *L[1-4]' "$1" | head -1 \
    | sed -E 's/^- *autonomy_level: *(L[1-4]).*/\1/' || true
}

_allowed_files() {
  _section "$1" "Blast radius" | awk '
    /^- allowed_files:/ { f = 1; next }
    /^- / { f = 0 }
    f && /^[[:space:]]+- / { sub(/^[[:space:]]+- /, ""); print }
  '
}

_state_meta() {
  # _state_meta <state_file> <key> -> value ("-" if unset)
  local v
  v=$(grep -E "^- $2:" "$1" | head -1 | sed -E "s/^- $2: *//" || true)
  echo "${v:--}"
}

# ------------------------------------------------------- contract_validate ---

contract_validate() {
  local dir contract errors=0
  dir=$(_resolve_loop_dir "${1:-}")
  contract=$(_contract_path "$dir")

  [ -f "$contract" ] || _die "contract not found: $contract"

  local sec
  for sec in "Goal" "Gate" "Brakes" "Blast radius" "Checker" "State"; do
    if ! grep -qE "^## $sec" "$contract"; then
      echo "❌ missing section: ## $sec"; errors=$((errors + 1))
    fi
  done

  # --- gate: must be a real, executable pass/fail command -------------------
  local gate first_line first_tok
  gate=$(_gate_cmd "$contract")
  if [ -z "$gate" ]; then
    echo "❌ gate: no command found in the fenced block of ## Gate"
    errors=$((errors + 1))
  elif echo "$gate" | grep -q '<'; then
    echo "❌ gate: unfilled placeholder '<...>' — the gate must be a real command"
    errors=$((errors + 1))
  else
    first_line=$(echo "$gate" | head -1)
    first_tok=$(echo "$first_line" | awk '{print $1}')
    if ! command -v "$first_tok" >/dev/null 2>&1; then
      echo "❌ gate: '$first_tok' is not an executable command on this machine"
      errors=$((errors + 1))
    fi
  fi

  # --- brakes: hard caps must be numeric -------------------------------------
  local field val
  for field in max_iterations no_progress_after; do
    val=$(_brake "$contract" "$field")
    if [ -z "$val" ] || [ "$val" -lt 1 ]; then
      echo "❌ brakes: '$field' missing or not a positive integer"
      errors=$((errors + 1))
    fi
  done
  if ! grep -qE '^- *token_budget:' "$contract"; then
    echo "❌ brakes: 'token_budget' missing"
    errors=$((errors + 1))
  fi

  # --- autonomy_level: must be declared, L1-L4 -------------------------------
  local level
  level=$(_autonomy "$contract")
  if [ -z "$level" ]; then
    echo "❌ autonomy_level: missing or invalid (expected L1|L2|L3|L4)"
    errors=$((errors + 1))
  fi

  # --- blast_radius: refuse paths outside the project ------------------------
  local root p files
  root=$(_project_root)
  files=$(_allowed_files "$contract")
  if [ -z "$files" ]; then
    echo "❌ blast_radius: 'allowed_files' list is empty"
    errors=$((errors + 1))
  else
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      case "$p" in
        *..*)
          echo "❌ blast_radius: '$p' contains '..' — refused"
          errors=$((errors + 1)) ;;
        "~"*)
          echo "❌ blast_radius: '$p' targets the home directory — refused"
          errors=$((errors + 1)) ;;
        /*)
          case "$p" in
            "$root"/*|"$root") : ;;
            *)
              echo "❌ blast_radius: '$p' is outside the project root ($root) — refused"
              errors=$((errors + 1)) ;;
          esac ;;
      esac
    done <<EOF
$files
EOF
  fi

  if [ "$errors" -gt 0 ]; then
    echo "contract_validate: FAIL ($errors error(s)) — no gate, no loop."
    return 1
  fi
  echo "contract_validate: PASS (gate + brakes + blast_radius + autonomy=$level)"
}

# ------------------------------------------------------- state read / write --

_state_init() {
  local dir="$1" state slug
  state=$(_state_path "$dir")
  slug=$(basename "$dir")
  mkdir -p "$dir"
  cat > "$state" <<EOF
# Loop State: $slug

- status: in-progress
- iteration: 0
- last_gate_exit: -
- gate_hash: -
- gate_hash_history:
- updated: $(_now)

## Done

## In Progress

## Blocked

## Next
EOF
}

state_read() {
  local dir state
  dir=$(_resolve_loop_dir "${1:-}")
  state=$(_state_path "$dir")
  [ -f "$state" ] || _state_init "$dir"
  cat "$state"
}

state_get() {
  local dir state key="${2:-}"
  dir=$(_resolve_loop_dir "${1:-}")
  state=$(_state_path "$dir")
  [ -n "$key" ] || _die "usage: state_get <loop_dir> <key>"
  [ -f "$state" ] || _die "state not found: $state (run state_read first)"
  _state_meta "$state" "$key"
}

state_write() {
  # state_write <loop_dir> <status> <gate_exit> [gate_output]
  local dir status="${2:-}" gate_exit="${3:-}" gate_output="${4:-}"
  dir=$(_resolve_loop_dir "${1:-}")
  local state slug iteration history hash body
  state=$(_state_path "$dir")
  slug=$(basename "$dir")

  case "$status" in
    done|in-progress|blocked) : ;;
    *) _die "invalid status '$status' (done|in-progress|blocked)" ;;
  esac
  case "$gate_exit" in
    (''|*[!0-9]*) _die "gate_exit must be a number, got '$gate_exit'" ;;
  esac

  [ -f "$state" ] || _state_init "$dir"

  iteration=$(_state_meta "$state" "iteration")
  case "$iteration" in (''|-|*[!0-9]*) iteration=0 ;; esac
  iteration=$((iteration + 1))

  # hash of the gate result -> fuel for no-progress / flip-flop detection
  hash=$(printf '%s\n%s' "$gate_exit" "$gate_output" | _hash)

  history=$(_state_meta "$state" "gate_hash_history")
  [ "$history" = "-" ] && history=""
  history=$(echo "$history $hash" | tr -s ' ' | sed 's/^ //;s/ $//')
  # keep only the last $HISTORY_KEEP entries
  history=$(echo "$history" | awk -v k="$HISTORY_KEEP" \
    '{ s = (NF > k) ? NF - k + 1 : 1; out = ""; for (i = s; i <= NF; i++) out = out (out ? " " : "") $i; print out }')

  # preserve the markdown body (## Done / In Progress / Blocked / Next)
  body=$(awk '/^## /{f=1} f{print}' "$state")
  [ -n "$body" ] || body=$(printf '## Done\n\n## In Progress\n\n## Blocked\n\n## Next')

  cat > "$state" <<EOF
# Loop State: $slug

- status: $status
- iteration: $iteration
- last_gate_exit: $gate_exit
- gate_hash: $hash
- gate_hash_history: $history
- updated: $(_now)

$body
EOF
  echo "state_write: iteration=$iteration status=$status gate_exit=$gate_exit hash=$hash"
}

# ------------------------------------------------------------ brakes_check ---

brakes_check() {
  local dir contract state
  dir=$(_resolve_loop_dir "${1:-}")
  contract=$(_contract_path "$dir")
  state=$(_state_path "$dir")
  [ -f "$contract" ] || _die "contract not found: $contract"
  [ -f "$state" ]    || _state_init "$dir"

  local status iteration max_iter no_progress history
  status=$(_state_meta "$state" "status")
  iteration=$(_state_meta "$state" "iteration")
  max_iter=$(_brake "$contract" "max_iterations")
  no_progress=$(_brake "$contract" "no_progress_after")
  history=$(_state_meta "$state" "gate_hash_history")
  [ "$history" = "-" ] && history=""
  case "$iteration" in (''|-|*[!0-9]*) iteration=0 ;; esac

  if [ "$status" = "done" ]; then
    echo "HALT: DONE — gate passed, loop finished"; return 10
  fi
  if [ "$status" = "blocked" ]; then
    echo "HALT: BLOCKED — needs human input"; return 11
  fi
  if [ -n "$max_iter" ] && [ "$iteration" -ge "$max_iter" ]; then
    echo "HALT: MAX_ITERATIONS — $iteration/$max_iter iterations used"; return 2
  fi

  # no-progress: last N gate hashes identical
  if [ -n "$no_progress" ] && [ -n "$history" ]; then
    local n uniq_last
    n=$(echo "$history" | wc -w | tr -d ' ')
    if [ "$n" -ge "$no_progress" ]; then
      uniq_last=$(echo "$history" | tr ' ' '\n' | tail -n "$no_progress" | sort -u | wc -l | tr -d ' ')
      if [ "$uniq_last" -eq 1 ]; then
        echo "HALT: NO_PROGRESS — gate result unchanged for $no_progress iterations"
        return 3
      fi
    fi
  fi

  # flip-flop: last 3 hashes form A -> B -> A (oscillation)
  if [ -n "$history" ]; then
    local h1 h2 h3
    set -- $(echo "$history" | tr ' ' '\n' | tail -3 | tr '\n' ' ')
    if [ "$#" -eq 3 ]; then
      h1=$1; h2=$2; h3=$3
      if [ "$h1" = "$h3" ] && [ "$h1" != "$h2" ]; then
        echo "HALT: FLIP_FLOP — gate results oscillate A→B→A"
        return 4
      fi
    fi
  fi

  echo "OK: ITERATE (iteration $iteration/${max_iter:-∞})"
}

# ---------------------------------------------------------------- gate_run ---

gate_run() {
  # runs the contract's gate with its timeout; hung gate = FAIL (silent-death guard)
  local dir contract gate secs log rc=0
  dir=$(_resolve_loop_dir "${1:-}")
  contract=$(_contract_path "$dir")
  [ -f "$contract" ] || _die "contract not found: $contract"

  gate=$(_gate_cmd "$contract")
  [ -n "$gate" ] || _die "no gate command in $contract"
  secs=$(_gate_timeout "$contract")
  log="$dir/last-gate.log"

  if command -v timeout >/dev/null 2>&1; then
    timeout "$secs" bash -c "$gate" > "$log" 2>&1 || rc=$?
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$secs" bash -c "$gate" > "$log" 2>&1 || rc=$?
  else
    bash -c "$gate" > "$log" 2>&1 &
    local pid=$! watcher
    ( sleep "$secs" && kill -9 "$pid" 2>/dev/null ) &
    watcher=$!
    wait "$pid" || rc=$?
    kill "$watcher" 2>/dev/null || true
    wait "$watcher" 2>/dev/null || true
  fi

  echo "gate_exit: $rc (log: $log, timeout: ${secs}s)"
  return "$rc"
}

# -------------------------------------------------------------- loop_report --

loop_report() {
  local dir contract state
  dir=$(_resolve_loop_dir "${1:-}")
  contract=$(_contract_path "$dir")
  state=$(_state_path "$dir")
  [ -f "$contract" ] || _die "contract not found: $contract"
  [ -f "$state" ]    || _state_init "$dir"

  local slug status iteration max_iter gate_exit token_budget level verdict rc=0
  slug=$(basename "$dir")
  status=$(_state_meta "$state" "status")
  iteration=$(_state_meta "$state" "iteration")
  gate_exit=$(_state_meta "$state" "last_gate_exit")
  max_iter=$(_brake "$contract" "max_iterations")
  token_budget=$(grep -E '^- *token_budget:' "$contract" | head -1 \
    | sed -E 's/^- *token_budget: *//' || true)
  level=$(_autonomy "$contract")
  verdict=$(brakes_check "$dir") || rc=$?

  cat <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
LOOP REPORT: $slug
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
status:          $status
iterations:      $iteration / ${max_iter:-?}
last gate exit:  $gate_exit $( [ "$gate_exit" = "0" ] && echo '(PASS)' || echo '(FAIL)' )
autonomy_level:  ${level:-?}
token_budget:    ${token_budget:-undeclared} (approx. cost ≤ budget × iterations used)
brakes verdict:  $verdict (code $rc)
state file:      $state
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# -------------------------------------------------------------------- main ---

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

cmd="${1:-}"
shift || true
case "$cmd" in
  contract_validate) contract_validate "$@" ;;
  state_read)        state_read "$@" ;;
  state_get)         state_get "$@" ;;
  state_write)       state_write "$@" ;;
  brakes_check)      brakes_check "$@" ;;
  gate_run)          gate_run "$@" ;;
  loop_report)       loop_report "$@" ;;
  *)                 usage ;;
esac
