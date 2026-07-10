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
#                                              (also registers the loop with Cortex)
#   state_read        <loop_dir>               init if missing, print STATE.md
#   state_get         <loop_dir> <key>         print one metadata value
#   state_write       <loop_dir> <status> <gate_exit> [gate_output]
#   brakes_check      <loop_dir> [tokens]      0=iterate 2=max_iter 3=no_progress
#                                              4=flip_flop 5=killed-via-cortex
#                                              10=done 11=blocked. [tokens] = the
#                                              cumulative token estimate to heartbeat
#                                              (fuels the LP-07 budget kill switch).
#   gate_run          <loop_dir>               run the gate with timeout, print exit
#   loop_report       <loop_dir> [accepted] [tokens]   end-of-loop summary (+ final
#                                              Cortex report with LP-07 cost accounting)
#   cortex_register   <loop_dir>               register loop in the Cortex control plane
#   cortex_heartbeat  <loop_dir> [tokens]      heartbeat; exit 5 = Cortex ordered a kill
#   cortex_report     <loop_dir> [accepted] [tokens]   send the final verdict + LP-07
#                                              cost accounting to Cortex
#
# Workflow loop (LP-09) — a CONTRACT.md may declare a "## Workflow" section
# (pipe table: | step | gate | checkpoint |). The kernel then advances step by
# step: a step's gate passing crosses that step's gate; checkpoint=human (and
# EVERY step at autonomy L1/L2) HALTs until a human records a per-step approval.
#   workflow_status   <loop_dir>               current step, position, checkpoint
#   workflow_advance  <loop_dir> [tokens]      one transition: run current step gate,
#                                              then ADVANCE / retry (1) / HALT
#                                              checkpoint (12) / brake codes above.
#                                              [tokens] = cumulative token estimate,
#                                              heartbeated for the LP-07 budget kill.
#   workflow_approve  <loop_dir> <step>        HUMAN-run: record traceable approval
#                                              (.genius/loops/<slug>/approvals/<step>)
#
# Control plane (LP-06): if the `cortex` CLI is reachable (override with
# $CORTEX_BIN), the kernel registers the loop, heartbeats on every
# brakes_check and reports the final verdict — Cortex is the police: a
# heartbeat answering kill:true halts the loop (STATE set to blocked, final
# report sent, brakes_check exits 5). GRACEFUL DEGRADATION: when cortex is
# absent or fails, the loop still runs — a warning is logged to stderr and
# every cortex_* helper returns 0.
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

# ------------------------------------------------- workflow helpers (LP-09) --

_workflow_rows() {
  # _workflow_rows <contract> -> TSV "name<TAB>checkpoint<TAB>gate", in order.
  # Parses the pipe table of "## Workflow": | step | gate | checkpoint |
  # Gate commands must not contain a literal '|' — wrap them in a script.
  _section "$1" "Workflow" | awk -F'|' '
    /^\|/ {
      s = $2; g = $3; c = $4
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", g)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", c)
      if (s == "" || s == "step" || s ~ /^:?-+:?$/) next
      print s "\t" c "\t" g
    }
  '
}

_workflow_field() {
  # _workflow_field <contract> <step> <checkpoint|gate> -> value
  local row
  row=$(_workflow_rows "$1" | awk -F'\t' -v s="$2" '$1 == s { print; exit }')
  [ -n "$row" ] || return 1
  case "$3" in
    checkpoint) echo "$row" | cut -f2 ;;
    gate)       echo "$row" | cut -f3 ;;
    *)          return 1 ;;
  esac
}

_workflow_next() {
  # _workflow_next <contract> <step> -> next step name ("" if <step> is last)
  _workflow_rows "$1" | awk -F'\t' -v s="$2" '
    found { print $1; exit }
    $1 == s { found = 1 }
  '
}

_state_set_meta() {
  # _state_set_meta <loop_dir> <key> <value> — update (or insert after the
  # status line) a single "- key: value" metadata line in STATE.md.
  local dir="$1" key="$2" val="$3" state tmp
  dir=$(_resolve_loop_dir "$dir")
  state=$(_state_path "$dir")
  [ -f "$state" ] || _state_init "$dir"
  tmp="$state.tmp.$$"
  if grep -qE "^- $key:" "$state"; then
    awk -v k="$key" -v v="$val" '
      index($0, "- " k ":") == 1 { print "- " k ": " v; next }
      { print }
    ' "$state" > "$tmp" && mv "$tmp" "$state"
  else
    awk -v k="$key" -v v="$val" '
      { print }
      /^- status: / && !done { print "- " k ": " v; done = 1 }
    ' "$state" > "$tmp" && mv "$tmp" "$state"
  fi
}

# ------------------------------------------------ cortex control plane (LP-06)

CORTEX_BIN="${CORTEX_BIN:-cortex}"
_CORTEX_TIMEOUT="${CORTEX_TIMEOUT:-10}"
_CORTEX_WARNED=0

_cortex_available() { command -v "$CORTEX_BIN" >/dev/null 2>&1; }

_cortex_call() {
  # _cortex_call <secs> <register|heartbeat|report> <json> — run
  # `$CORTEX_BIN loops --<sub> <json>` under a BOUNDED timeout so a HUNG cortex
  # can't stall the loop (graceful degradation covered an absent/refusing binary,
  # not a hanging one). Reuses the gate timeout machinery (_exec_gate), which on
  # stock macOS kills the whole process group. Prints cortex's captured output
  # and returns its exit code; a timeout is a non-zero exit, which the callers
  # already treat as "cortex unreachable" (warn + continue). The json is passed
  # via an EXPORTED var so arbitrary JSON needs no shell re-quoting.
  local secs="$1" sub="$2" json="$3" log rc=0
  export CORTEX_BIN CORTEX_NO_UPDATE_CHECK=1 _LK_CORTEX_JSON="$json"
  log="${TMPDIR:-/tmp}/loop-kernel.cortex.$$.${RANDOM}"
  _exec_gate '"$CORTEX_BIN" loops --'"$sub"' "$_LK_CORTEX_JSON"' "$secs" "$log" || rc=$?
  [ -f "$log" ] && { cat "$log"; rm -f "$log"; }
  unset _LK_CORTEX_JSON
  return "$rc"
}

_cortex_warn() {
  [ "$_CORTEX_WARNED" -eq 1 ] && return 0
  _CORTEX_WARNED=1
  echo "loop-kernel: WARNING: cortex CLI not reachable — loop runs WITHOUT the control plane (no heartbeat, no kill switch)" >&2
}

_json_escape() {
  # stdin/arg -> JSON-string-safe (backslash, quote, newlines)
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr '\n' ' '
}

_loop_id() {
  # <loop_dir> -> "<repo>/<slug>" — must match Cortex's default id convention
  echo "$(basename "$(_project_root)")/$(basename "$(_resolve_loop_dir "$1")")"
}

_state_set_status() {
  # _state_set_status <loop_dir> <status> — rewrite ONLY the status line
  local dir="$1" new="$2" state tmp
  dir=$(_resolve_loop_dir "$dir")
  state=$(_state_path "$dir")
  [ -f "$state" ] || _state_init "$dir"
  tmp="$state.tmp.$$"
  awk -v s="$new" '/^- status: / { print "- status: " s; next } { print }' "$state" > "$tmp" && mv "$tmp" "$state"
}

cortex_register() {
  # Registers the loop in the Cortex control plane. Never blocks the loop:
  # unreachable/refusing cortex -> warning on stderr, exit 0.
  local dir contract id repo goal level json out
  dir=$(_resolve_loop_dir "${1:-}")
  contract=$(_contract_path "$dir")
  [ -f "$contract" ] || _die "contract not found: $contract"
  _cortex_available || { _cortex_warn; return 0; }
  id=$(_loop_id "$dir")
  repo=$(basename "$(_project_root)")
  goal=$(_section "$contract" "Goal" | sed '/^[[:space:]]*$/d' | head -1)
  level=$(_autonomy "$contract")
  json=$(printf '{"id":"%s","repo":"%s","contractPath":"%s","goal":"%s","autonomyLevel":"%s"}' \
    "$(_json_escape "$id")" \
    "$(_json_escape "$repo")" \
    "$(_json_escape "$(cd "$dir" && pwd -P)/CONTRACT.md")" \
    "$(_json_escape "$goal")" \
    "$(_json_escape "${level:-L2}")")
  if out=$(_cortex_call "$_CORTEX_TIMEOUT" register "$json" 2>/dev/null); then
    echo "loop-kernel: cortex: registered loop $id" >&2
  else
    echo "loop-kernel: WARNING: cortex refused/failed loop registration (${out:-no output}) — loop runs without control plane" >&2
  fi
  return 0
}

cortex_heartbeat() {
  # cortex_heartbeat <loop_dir> [token_estimate]
  # exit 0 = continue (or cortex unreachable), exit 5 = Cortex ordered a kill.
  local dir state id iteration gate_exit verdict tokens json out reason
  dir=$(_resolve_loop_dir "${1:-}")
  tokens="${2:-}"
  _cortex_available || { _cortex_warn; return 0; }
  state=$(_state_path "$dir")
  [ -f "$state" ] || _state_init "$dir"
  id=$(_loop_id "$dir")
  iteration=$(_state_meta "$state" "iteration")
  case "$iteration" in (''|-|*[!0-9]*) iteration=0 ;; esac
  gate_exit=$(_state_meta "$state" "last_gate_exit")
  case "$gate_exit" in
    0) verdict="pass" ;;
    ''|-) verdict="-" ;;
    *) verdict="fail" ;;
  esac
  json=$(printf '{"id":"%s","iteration":%s,"gateVerdict":"%s"' \
    "$(_json_escape "$id")" "$iteration" "$verdict")
  case "$tokens" in
    (''|*[!0-9]*) json="$json}" ;;
    (*) json="$json,\"tokenEstimate\":$tokens}" ;;
  esac
  if ! out=$(_cortex_call "$_CORTEX_TIMEOUT" heartbeat "$json" 2>/dev/null); then
    echo "loop-kernel: WARNING: cortex heartbeat failed/timed out — continuing without control plane" >&2
    return 0
  fi
  if echo "$out" | grep -qE '"kill"[[:space:]]*:[[:space:]]*true'; then
    reason=$(echo "$out" | sed -n 's/.*"reason":"\([^"]*\)".*/\1/p')
    echo "KILL: cortex ordered a kill${reason:+ — $reason}"
    return 5
  fi
  return 0
}

cortex_report() {
  # cortex_report <loop_dir> [accepted] [tokens_used]
  # LP-07: accepted (changes accepted this run) and tokens_used feed the
  # cost-per-accepted-change stats (`cortex loops --stats`). Both optional:
  # omitted -> Cortex keeps the live estimate and reports no acceptance rate.
  local dir state id status cstatus gate_exit verdict json out accepted tokens
  dir=$(_resolve_loop_dir "${1:-}")
  accepted="${2:-}"
  tokens="${3:-}"
  _cortex_available || { _cortex_warn; return 0; }
  state=$(_state_path "$dir")
  [ -f "$state" ] || _state_init "$dir"
  id=$(_loop_id "$dir")
  status=$(_state_meta "$state" "status")
  case "$status" in
    done) cstatus="completed" ;;
    *)    cstatus="halted" ;;
  esac
  gate_exit=$(_state_meta "$state" "last_gate_exit")
  case "$gate_exit" in
    0) verdict="pass" ;;
    ''|-) verdict="-" ;;
    *) verdict="fail" ;;
  esac
  json=$(printf '{"id":"%s","status":"%s","verdict":"%s"' \
    "$(_json_escape "$id")" "$cstatus" "$verdict")
  case "$accepted" in
    (''|*[!0-9]*) : ;;
    (*) json="$json,\"accepted\":$accepted" ;;
  esac
  case "$tokens" in
    (''|*[!0-9]*) : ;;
    (*) json="$json,\"tokensUsed\":$tokens" ;;
  esac
  json="$json}"
  if ! out=$(_cortex_call "$_CORTEX_TIMEOUT" report "$json" 2>/dev/null); then
    echo "loop-kernel: WARNING: cortex final report failed/timed out" >&2
  fi
  return 0
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
  elif echo "$gate" | grep -qE '<[A-Za-z][A-Za-z0-9_ -]*[A-Za-z0-9_-]>'; then
    # Match an actual unfilled template tag (<exact command>, <slug>, <gate>) —
    # NOT legitimate shell '<' (redirection `< file`, heredoc `<<EOF`, process
    # substitution `<(...)`, or comparison `[[ a < b ]]`).
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

  # --- workflow (LP-09): if a ## Workflow table is present, every step needs
  # --- a real deterministic gate and a checkpoint of auto|human ---------------
  if grep -qE '^## Workflow' "$contract"; then
    local rows name cp wgate wtok dupes
    rows=$(_workflow_rows "$contract")
    if [ -z "$rows" ]; then
      echo "❌ workflow: ## Workflow section has no step rows (| step | gate | checkpoint |)"
      errors=$((errors + 1))
    else
      dupes=$(echo "$rows" | cut -f1 | sort | uniq -d)
      if [ -n "$dupes" ]; then
        echo "❌ workflow: duplicate step name(s): $(echo "$dupes" | tr '\n' ' ')"
        errors=$((errors + 1))
      fi
      while IFS=$'\t' read -r name cp wgate; do
        [ -n "$name" ] || continue
        case "$cp" in
          auto|human) : ;;
          *) echo "❌ workflow: step '$name' checkpoint must be auto|human, got '$cp'"
             errors=$((errors + 1)) ;;
        esac
        if [ -z "$wgate" ]; then
          echo "❌ workflow: step '$name' has no gate command"
          errors=$((errors + 1))
        elif echo "$wgate" | grep -qE '<[A-Za-z][A-Za-z0-9_ -]*[A-Za-z0-9_-]>'; then
          # actual unfilled tag only — legitimate shell '<' (redirect/heredoc/
          # process-substitution/comparison) is allowed (see ## Gate check above)
          echo "❌ workflow: step '$name' gate has an unfilled placeholder '<...>'"
          errors=$((errors + 1))
        else
          wtok=$(echo "$wgate" | awk '{print $1}')
          if ! command -v "$wtok" >/dev/null 2>&1; then
            echo "❌ workflow: step '$name' gate '$wtok' is not an executable command"
            errors=$((errors + 1))
          fi
        fi
      done <<EOF
$rows
EOF
    fi
  fi

  if [ "$errors" -gt 0 ]; then
    echo "contract_validate: FAIL ($errors error(s)) — no gate, no loop."
    return 1
  fi
  echo "contract_validate: PASS (gate + brakes + blast_radius + autonomy=$level)"

  # LP-06: a runnable contract gets registered with the control plane
  # (no-op with a warning when cortex is unreachable).
  cortex_register "$dir" || true
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

  # preserve metadata lines the kernel does not own (e.g. LP-09 step/awaiting)
  local extra
  extra=$(awk '/^## /{exit} /^- /{print}' "$state" \
    | grep -vE '^- (status|iteration|last_gate_exit|gate_hash|gate_hash_history|updated):' || true)

  cat > "$state" <<EOF
# Loop State: $slug

- status: $status
- iteration: $iteration
- last_gate_exit: $gate_exit
- gate_hash: $hash
- gate_hash_history: $history
- updated: $(_now)
${extra:+$extra
}
$body
EOF
  echo "state_write: iteration=$iteration status=$status gate_exit=$gate_exit hash=$hash"
}

# ------------------------------------------------------------ brakes_check ---

brakes_check() {
  # brakes_check <loop_dir> [cumulative_tokens]
  local dir contract state tokens
  dir=$(_resolve_loop_dir "${1:-}")
  tokens="${2:-}"
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
    # LP-06/LP-07: the terminal iteration (the one whose gate PASSED and set
    # status=done) is otherwise NEVER heartbeated — brakes_check returns here
    # before the heartbeat below, and cortex_report carries no iteration. Send
    # exactly one final heartbeat so the terminal iteration count reaches Cortex;
    # without it the attempts counter feeding the LP-07 cost stats is under-counted
    # by 1, which can flip the losingMoney verdict at the 0.5 threshold. Idempotent:
    # a STATE flag makes it fire once even if brakes_check is polled again. A kill
    # answer is moot on a finished loop, so the heartbeat's stdout/exit are ignored.
    if [ "$(_state_meta "$state" "final_heartbeat")" != "yes" ]; then
      cortex_heartbeat "$dir" "$tokens" >/dev/null || true
      _state_set_meta "$dir" "final_heartbeat" "yes"
    fi
    echo "HALT: DONE — gate passed, loop finished"; return 10
  fi
  if [ "$status" = "blocked" ]; then
    echo "HALT: BLOCKED — needs human input"; return 11
  fi

  # LP-06: heartbeat the Cortex control plane. kill:true is an order:
  # write STATE (blocked), send the final report, halt cleanly (exit 5).
  local hb_rc=0
  cortex_heartbeat "$dir" "$tokens" || hb_rc=$?
  if [ "$hb_rc" -eq 5 ]; then
    _state_set_status "$dir" "blocked"
    cortex_report "$dir" || true
    echo "HALT: KILLED — kill requested via Cortex control plane"
    return 5
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

_exec_gate() {
  # _exec_gate <gate_cmd> <timeout_secs> <log_file> — run a gate command with a
  # timeout (hung gate = FAIL, silent-death guard). Returns the gate's exit code.
  local gate="$1" secs="$2" log="$3" rc=0
  if command -v timeout >/dev/null 2>&1; then
    timeout "$secs" bash -c "$gate" > "$log" 2>&1 || rc=$?
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$secs" bash -c "$gate" > "$log" 2>&1 || rc=$?
  else
    # No timeout/gtimeout (stock macOS ships neither): run the gate in its OWN
    # process group and POLL its liveness, killing the WHOLE group if it outlives
    # the timeout — so a gate that spawns children (or is a shell pipeline)
    # leaves no orphans (killing only the immediate PID does). setsid (Linux)
    # makes pid==pgid directly; on stock macOS setsid is absent, so we enable job
    # control (set -m), under which each backgrounded job gets a fresh process
    # group whose PGID equals the job-leader PID — then `kill -<pid>` (negative =
    # the group) reaps the entire tree. A poll loop — not a second background
    # watcher — is deliberate: a backgrounded `( sleep … )` watcher inherits this
    # function's stdout, and its orphaned `sleep` child keeps that fd open, so
    # under `$(_exec_gate …)` command substitution (the kernel's own documented
    # calling convention) the capture would block for the FULL timeout even after
    # the gate returns.
    local pid start had_m=0
    if command -v setsid >/dev/null 2>&1; then
      setsid bash -c "$gate" > "$log" 2>&1 &
      pid=$!
    else
      case "$-" in *m*) had_m=1 ;; esac
      set -m
      bash -c "$gate" > "$log" 2>&1 &
      pid=$!
      [ "$had_m" -eq 1 ] || set +m
    fi
    start=$SECONDS
    while kill -0 "$pid" 2>/dev/null; do
      if [ $((SECONDS - start)) -ge "$secs" ]; then
        # TERM the whole group, give it a beat to clean up, then KILL survivors.
        kill -TERM "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
        sleep 0.3
        kill -KILL "-$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null || true
        break
      fi
      sleep 0.2
    done
    wait "$pid" 2>/dev/null || rc=$?
  fi
  return "$rc"
}

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

  _exec_gate "$gate" "$secs" "$log" || rc=$?

  echo "gate_exit: $rc (log: $log, timeout: ${secs}s)"
  return "$rc"
}

# --------------------------------------------------- workflow loop (LP-09) ---
# The product pipeline (Interview → Specs → Architecture → Dev → Review →
# Deploy) as ONE self-advancing loop. Each step's gate is deterministic (the
# existing guard/review IS the gate: review pass = gate crossed). Human
# checkpoints are explicit: checkpoint=human in the table — and at autonomy
# L1/L2 EVERY step is a human checkpoint. A human checkpoint HALTs (exit 12)
# until workflow_approve records a traceable per-step approval (GUARD-POLICY
# §5.5: per-action, never a permanent global override). Even L4 never skips a
# human checkpoint — L4 removes prompts on auto steps, never the review.

workflow_status() {
  local dir contract state cur total idx cp
  dir=$(_resolve_loop_dir "${1:-}")
  contract=$(_contract_path "$dir")
  state=$(_state_path "$dir")
  [ -f "$contract" ] || _die "contract not found: $contract"
  [ -f "$state" ] || _state_init "$dir"
  [ -n "$(_workflow_rows "$contract")" ] || _die "no ## Workflow section in $contract"
  cur=$(_state_meta "$state" "step")
  [ "$cur" = "-" ] && cur=$(_workflow_rows "$contract" | head -1 | cut -f1)
  total=$(_workflow_rows "$contract" | wc -l | tr -d ' ')
  idx=$(_workflow_rows "$contract" | awk -F'\t' -v s="$cur" '$1 == s { print NR; exit }')
  cp=$(_workflow_field "$contract" "$cur" checkpoint || echo "?")
  echo "workflow: step $cur (${idx:-?}/$total, checkpoint=$cp) status=$(_state_meta "$state" "status") awaiting=$(_state_meta "$state" "awaiting")"
}

workflow_approve() {
  # HUMAN-run: record an explicit, traceable, per-step approval.
  local dir step="${2:-}"
  dir=$(_resolve_loop_dir "${1:-}")
  [ -n "$step" ] || _die "usage: workflow_approve <loop_dir> <step>"
  _workflow_field "$(_contract_path "$dir")" "$step" gate >/dev/null \
    || _die "unknown workflow step '$step'"
  mkdir -p "$dir/approvals"
  printf 'step: %s\napproved: %s\napproved-by: human (workflow_approve)\n' \
    "$step" "$(_now)" > "$dir/approvals/$step"
  echo "workflow_approve: step '$step' approved ($dir/approvals/$step)"
}

workflow_advance() {
  # One workflow transition. Exit codes:
  #   0  = advanced (or resumed/completed) — call again for the next transition
  #   1  = current step's gate FAILED — iterate on the step (fix, re-run)
  #   12 = HALT: human checkpoint — approval required (workflow_approve)
  #   2/3/4/5/10/11 = brake verdicts propagated from brakes_check
  local dir contract state level cur next cp gate secs rc=0 tokens
  dir=$(_resolve_loop_dir "${1:-}")
  tokens="${2:-}"
  contract=$(_contract_path "$dir")
  state=$(_state_path "$dir")
  [ -f "$contract" ] || _die "contract not found: $contract"
  [ -f "$state" ] || _state_init "$dir"
  [ -n "$(_workflow_rows "$contract")" ] || _die "no ## Workflow section in $contract"

  level=$(_autonomy "$contract"); level="${level:-L2}"
  cur=$(_state_meta "$state" "step")
  if [ "$cur" = "-" ] || [ -z "$cur" ]; then
    cur=$(_workflow_rows "$contract" | head -1 | cut -f1)
    _state_set_meta "$dir" "step" "$cur"
  fi
  _workflow_field "$contract" "$cur" gate >/dev/null \
    || _die "STATE step '$cur' not found in the ## Workflow table"

  # -- resume: a blocked checkpoint whose approval has since been recorded ----
  if [ "$(_state_meta "$state" "status")" = "blocked" ] \
     && [ "$(_state_meta "$state" "awaiting")" = "checkpoint:$cur" ]; then
    if [ -f "$dir/approvals/$cur" ]; then
      _state_set_meta "$dir" "awaiting" "-"
      next=$(_workflow_next "$contract" "$cur")
      if [ -z "$next" ]; then
        _state_set_status "$dir" "done"
        echo "CHECKPOINT APPROVED: $cur — WORKFLOW DONE (all steps passed)"
        cortex_report "$dir" || true
        return 0
      fi
      _state_set_meta "$dir" "step" "$next"
      _state_set_status "$dir" "in-progress"
      echo "CHECKPOINT APPROVED: $cur → step $next"
      return 0
    fi
    echo "HALT: CHECKPOINT — step '$cur' awaits human approval"
    echo "approve with: bash scripts/loop-kernel.sh workflow_approve $dir $cur"
    return 12
  fi

  # -- brakes first (includes the LP-06 Cortex heartbeat + kill switch) -------
  local brakes_out brakes_rc=0
  brakes_out=$(brakes_check "$dir" "$tokens") || brakes_rc=$?
  if [ "$brakes_rc" -ne 0 ]; then
    echo "$brakes_out"
    return "$brakes_rc"
  fi

  # -- run the CURRENT step's gate (deterministic; timeout = contract Gate's) -
  gate=$(_workflow_field "$contract" "$cur" gate)
  secs=$(_gate_timeout "$contract")
  _exec_gate "$gate" "$secs" "$dir/last-gate.log" || rc=$?

  if [ "$rc" -ne 0 ]; then
    state_write "$dir" "in-progress" "$rc" "workflow step=$cur gate FAILED" >/dev/null
    echo "STEP GATE FAIL: step '$cur' exit $rc — iterate on this step (log: $dir/last-gate.log)"
    return 1
  fi

  # -- gate passed: checkpoint? (human step, or ANY step at L1/L2) ------------
  cp=$(_workflow_field "$contract" "$cur" checkpoint)
  local need_human=false
  [ "$cp" = "human" ] && need_human=true
  case "$level" in L1|L2) need_human=true ;; esac
  if [ "$need_human" = true ] && [ ! -f "$dir/approvals/$cur" ]; then
    state_write "$dir" "blocked" 0 "workflow step=$cur gate PASSED — awaiting human checkpoint" >/dev/null
    _state_set_meta "$dir" "awaiting" "checkpoint:$cur"
    echo "HALT: CHECKPOINT — step '$cur' gate PASSED; human approval required before advancing (autonomy=$level, checkpoint=$cp)"
    echo "approve with: bash scripts/loop-kernel.sh workflow_approve $dir $cur"
    return 12
  fi

  # -- advance (or finish) -----------------------------------------------------
  next=$(_workflow_next "$contract" "$cur")
  if [ -z "$next" ]; then
    state_write "$dir" "done" 0 "workflow step=$cur gate PASSED — final step" >/dev/null
    echo "WORKFLOW DONE: all steps passed (last: $cur)"
    cortex_report "$dir" || true
    return 0
  fi
  state_write "$dir" "in-progress" 0 "workflow step=$cur gate PASSED" >/dev/null
  _state_set_meta "$dir" "step" "$next"
  echo "ADVANCE: $cur → $next"
  return 0
}

# -------------------------------------------------------------- loop_report --

loop_report() {
  # loop_report <loop_dir> [accepted] [tokens_used]
  local dir contract state accepted tokens
  dir=$(_resolve_loop_dir "${1:-}")
  accepted="${2:-}"
  tokens="${3:-}"
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
tokens_used:     ${tokens:-not reported} / accepted changes: ${accepted:-not reported}
brakes verdict:  $verdict (code $rc)
state file:      $state
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

  # LP-06/LP-07: final verdict + cost accounting go to the control plane too
  # (warn-only on failure). accepted/tokens_used are forwarded when supplied.
  cortex_report "$dir" "$accepted" "$tokens" || true
}

# -------------------------------------------------------------------- main ---

usage() {
  sed -n '2,43p' "$0" | sed 's/^# \{0,1\}//'
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
  cortex_register)   cortex_register "$@" ;;
  cortex_heartbeat)  cortex_heartbeat "$@" ;;
  cortex_report)     cortex_report "$@" ;;
  workflow_status)   workflow_status "$@" ;;
  workflow_advance)  workflow_advance "$@" ;;
  workflow_approve)  workflow_approve "$@" ;;
  *)                 usage ;;
esac
