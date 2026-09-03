#!/usr/bin/env python3
"""Independent Python transcription of the FOL specification, checked against
the golden vectors in tests/vectors.json.

This is a third independent implementation, alongside Catala and Lean. Its
job is not to be trusted, but to disagree: if this file and the Lean
definitions ever return different answers for the same beneficiary, one of
the two transcriptions of the specification is wrong.

It is also the seed of stage 5 of the pipeline (see docs/ARCHITECTURE.md):
once the Catala Python backend is wired in, `spec_eligible` becomes the
oracle that the generated code is tested against with Hypothesis.

Usage:
    python3 tools/check_vectors.py [path/to/vectors.json]

Exit status 0 if every vector agrees, 1 otherwise.
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from pathlib import Path

# --- FOL specification, transcribed -----------------------------------------
# GP(b) <-> years(b) >= 15      [Art. 19]
# NA(b) <-> age(b)   >= 65      [Art. 20]
# E(b)  <-> GP(b) and NA(b)     [Art. 10(1), partial]

GUARANTEE_PERIOD_YEARS = 15
NORMAL_AGE = 65


@dataclass(frozen=True)
class Beneficiary:
    age: int
    years: int

    def __post_init__(self) -> None:
        if self.age < 0 or self.years < 0:
            raise ValueError("age and years are natural numbers")


def meets_guarantee_period(b: Beneficiary) -> bool:
    """Art. 19 — guarantee period of 15 civil years."""
    return b.years >= GUARANTEE_PERIOD_YEARS


def meets_normal_age(b: Beneficiary) -> bool:
    """Art. 20 — normal age of access, original 2007 wording."""
    return b.age >= NORMAL_AGE


def spec_eligible(b: Beneficiary) -> bool:
    """Art. 10(1) — substantive conditions only. See docs/INTERPRETATION.md D3."""
    return meets_guarantee_period(b) and meets_normal_age(b)


def deciding_articles(b: Beneficiary) -> list[str]:
    """Which articles refused the case. Empty when the case is granted.

    Stage 6 of the pipeline needs the reason, not just the boolean: an
    auditor cannot act on `false`.
    """
    failed = []
    if not meets_guarantee_period(b):
        failed.append("19")
    if not meets_normal_age(b):
        failed.append("20")
    return failed


def decide(b: Beneficiary) -> str:
    """The stage 6 output: a decision with the article that produced it."""
    if spec_eligible(b):
        return (
            f"DEFERIDO — Art. 19 satisfied ({b.years} >= {GUARANTEE_PERIOD_YEARS} years); "
            f"Art. 20 satisfied ({b.age} >= {NORMAL_AGE})."
        )
    reasons = []
    if not meets_guarantee_period(b):
        reasons.append(f"Art. 19 NOT satisfied ({b.years} < {GUARANTEE_PERIOD_YEARS} years)")
    else:
        reasons.append(f"Art. 19 satisfied ({b.years} >= {GUARANTEE_PERIOD_YEARS} years)")
    if not meets_normal_age(b):
        reasons.append(f"Art. 20 NOT satisfied ({b.age} < {NORMAL_AGE})")
    else:
        reasons.append(f"Art. 20 satisfied ({b.age} >= {NORMAL_AGE})")
    return "INDEFERIDO — " + "; ".join(reasons) + "."


# --- Vector checking ---------------------------------------------------------

def main(argv: list[str]) -> int:
    root = Path(__file__).resolve().parent.parent
    path = Path(argv[1]) if len(argv) > 1 else root / "tests" / "vectors.json"

    if not path.exists():
        print(f"FAIL  golden vectors not found: {path}", file=sys.stderr)
        return 1

    data = json.loads(path.read_text(encoding="utf-8"))
    cases = data["cases"]

    failures = 0
    for case in cases:
        b = Beneficiary(age=case["age"], years=case["years"])
        got = spec_eligible(b)
        want = case["eligible"]
        status = "ok  " if got == want else "FAIL"
        if got != want:
            failures += 1
        print(f"  {status}  {case['id']:<7} age={b.age:<3} years={b.years:<3} "
              f"expected={str(want):<5} got={str(got):<5}  {decide(b)}")

        expected_articles = case.get("deciding_article")
        if expected_articles is not None:
            got_articles = " and ".join(deciding_articles(b))
            if got_articles != expected_articles:
                print(f"  FAIL  {case['id']} deciding article: "
                      f"expected {expected_articles!r}, got {got_articles!r}")
                failures += 1

    print()
    if failures:
        print(f"{failures} divergence(s) between the Python transcription and the golden vectors.")
        return 1
    print(f"All {len(cases)} golden vectors agree with the Python transcription.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
