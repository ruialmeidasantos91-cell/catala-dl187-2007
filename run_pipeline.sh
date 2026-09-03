#!/usr/bin/env bash
# End-to-end check of the DL 187/2007 verification pipeline.
#
#   ./run_pipeline.sh              run every stage that has a toolchain
#   ./run_pipeline.sh --diagnose   also print toolchain diagnostics
#
# Exit status 0 only if every stage that ran, passed.

set -uo pipefail
cd "$(dirname "$0")"

DIAGNOSE=0
[ "${1:-}" = "--diagnose" ] && DIAGNOSE=1

FAILURES=0
SKIPPED=0

blue()  { printf '\n\033[1;34m== %s\033[0m\n' "$1"; }
pass()  { printf '   \033[0;32mPASS\033[0m  %s\n' "$1"; }
fail()  { printf '   \033[0;31mFAIL\033[0m  %s\n' "$1"; FAILURES=$((FAILURES+1)); }
skip()  { printf '   \033[0;33mSKIP\033[0m  %s\n' "$1"; SKIPPED=$((SKIPPED+1)); }

# ---------------------------------------------------------------------------
blue "Stage 5b — Python transcription vs. golden vectors"
# ---------------------------------------------------------------------------
if command -v python3 >/dev/null 2>&1; then
  if python3 tools/check_vectors.py; then
    pass "Python transcription agrees with tests/vectors.json"
  else
    fail "Python transcription diverges from tests/vectors.json"
  fi
else
  skip "python3 not found"
fi

# ---------------------------------------------------------------------------
blue "Stage 3 — Catala implementation"
# ---------------------------------------------------------------------------
if command -v clerk >/dev/null 2>&1; then
  for scope in TestCase1 TestCase2 TestCase3 TestCase4 TestCase5 TestCase6; do
    if out=$(clerk run Pensoes.catala_en --scope="$scope" 2>&1); then
      pass "clerk run --scope=$scope"
      [ "$DIAGNOSE" = 1 ] && printf '%s\n' "$out" | sed 's/^/         /'
    else
      fail "clerk run --scope=$scope"
      printf '%s\n' "$out" | sed 's/^/         /'
    fi
  done
elif command -v catala >/dev/null 2>&1; then
  skip "clerk not found, but catala is — build system not configured"
else
  skip "Catala toolchain not found (expected inside the WSL opam switch)"
fi

# ---------------------------------------------------------------------------
blue "Stage 5a — Lean 4 verification"
# ---------------------------------------------------------------------------
if command -v lake >/dev/null 2>&1; then
  if out=$(cd lean && lake build 2>&1); then
    pass "lake build — all theorems check, no sorry"
    [ "$DIAGNOSE" = 1 ] && printf '%s\n' "$out" | sed 's/^/         /'
  else
    fail "lake build"
    printf '%s\n' "$out" | sed 's/^/         /'
  fi
elif command -v lean >/dev/null 2>&1; then
  if out=$(lean lean/DL187/Eligibility.lean 2>&1); then
    pass "lean lean/DL187/Eligibility.lean"
  else
    fail "lean lean/DL187/Eligibility.lean"
    printf '%s\n' "$out" | sed 's/^/         /'
  fi
else
  skip "Lean toolchain not found (install via elan)"
fi

# An axiom or a sorry silently voids every proof in the file.
if grep -rn --include='*.lean' -E '\bsorry\b|^\s*axiom\b' lean/ >/dev/null 2>&1; then
  fail "lean/ contains 'sorry' or 'axiom' — proofs are not closed"
  grep -rn --include='*.lean' -E '\bsorry\b|^\s*axiom\b' lean/ | sed 's/^/         /'
else
  pass "no 'sorry' or 'axiom' in lean/"
fi

# ---------------------------------------------------------------------------
blue "Stages not yet implemented"
# ---------------------------------------------------------------------------
printf '   \033[0;33mTODO\033[0m  Stage 1 — neurosymbolic interpretation harness\n'
printf '   \033[0;33mTODO\033[0m  Stage 4 — Catala OCaml / Python backends\n'
printf '   \033[0;33mTODO\033[0m  Stage 5c — Hypothesis differential testing\n'
printf '   \033[0;33mTODO\033[0m  Stage 6 — decision layer wired to the Catala output\n'
printf '           (see docs/ARCHITECTURE.md)\n'

# ---------------------------------------------------------------------------
if [ "$DIAGNOSE" = 1 ]; then
  blue "Toolchain diagnostics"
  for c in catala clerk lean lake opam python3; do
    if command -v "$c" >/dev/null 2>&1; then
      printf '   %-8s %s\n' "$c" "$($c --version 2>&1 | head -1)"
    else
      printf '   %-8s not found\n' "$c"
    fi
  done
  if command -v clerk >/dev/null 2>&1; then
    blue "clerk --help"
    clerk --help 2>&1 | head -40 | sed 's/^/   /'
  fi
fi

# ---------------------------------------------------------------------------
blue "Summary"
if [ "$FAILURES" -eq 0 ]; then
  printf '   %s stage(s) skipped, no failures.\n' "$SKIPPED"
  exit 0
else
  printf '   %s failure(s), %s skipped.\n' "$FAILURES" "$SKIPPED"
  exit 1
fi
