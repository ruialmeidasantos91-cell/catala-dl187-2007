# Interpretation log

Every formalization decision that was not forced by the text is recorded
here, with the alternatives that were rejected and the reason. This file is
the authoritative output of stage 1 of the pipeline (see
`docs/ARCHITECTURE.md`).

**Method.** A language model proposes a candidate reading and lists the
ambiguities it detects; a jurist adjudicates. The adjudication is what is
recorded below. Where an entry is marked *pending*, the decision has not yet
been made and the current code embodies a provisional reading that must not
be relied upon.

**Legal source.** Decreto-Lei n.º 187/2007, de 10 de Maio, original wording,
before the 2014 amendments.

---

## D1 — "15 civil years" as `years ≥ 15`

**Article.** Art. 19 — guarantee period.

**Text.** "O prazo de garantia para atribuição da pensão de velhice é de 15
anos civis, seguidos ou interpolados, com registo de remunerações."

**Decision.** `GP(b) ↔ years(b) ≥ 15`, where `years(b)` is a natural number.

**Rejected alternatives.**

- `years > 15` — rejected. "É de 15 anos" states the period, and a beneficiary
  with exactly 15 years has completed it. The threshold is inclusive.
- Modelling the record as a set of years and counting it — deferred, not
  rejected. This is the correct model once Art. 12 enters scope, because
  "seguidos ou interpolados" and the density rules operate on the record
  itself, not on its cardinality. For the current scope the cardinality is
  sufficient and the reduction is sound.

**Consequence.** `years` is a derived quantity. The reduction from a
contribution record to a single integer is *itself* an interpretive step, and
it is the first thing that must be revisited when Art. 12 is formalized.

---

## D2 — "65 years of age" as `age ≥ 65`

**Article.** Art. 20 — normal age of access.

**Text.** "O reconhecimento do direito à pensão de velhice depende ainda de o
beneficiário ter idade igual ou superior a 65 anos."

**Decision.** `NA(b) ↔ age(b) ≥ 65`.

**Notes.** This one is forced by the text: "igual ou superior" is explicit.
It is recorded anyway, because the *absence* of an entry must mean "not yet
considered", never "obvious".

**Open point.** `age` is modelled as a natural number, which discards the
reference date. Age is a function of a date of birth and a date of
assessment; the current model presumes the assessment date is given and the
age already computed. When the anticipation regimes enter scope this will not
survive, because they turn on age *at specific moments*.

---

## D3 — Conjunction in Art. 10(1)

**Article.** Art. 10(1) — common conditions.

**Decision.** `E(b) ↔ GP(b) ∧ NA(b)`.

**Status: partial, and knowingly incomplete.**

Art. 10(1) makes the right depend on the guarantee period **and on the
submission of a request** ("apresentação do requerimento"). The request is
not modelled. The current formalization therefore states a *necessary*
condition, not a sufficient one: `E(b)` as implemented answers "does the
beneficiary meet the substantive conditions", not "is the pension due".

This is the most significant known gap in the current scope and is flagged in
the README rather than buried here.

**Rejected alternative.** Adding a `request_submitted` input now — rejected
for this increment. A procedural condition modelled as a boolean input adds
no formal content and creates the false impression that the procedure is
covered. It enters when the procedural articles are formalized properly.

---

## D4 — Fixing the 2007 wording

**Decision.** The original 2007 text is formalized; the 2014 amendments
(sustainability factor, normal age indexed to life expectancy) are excluded.

**Reason.** A proof of concept needs a fixed target. The post-2014 normal age
is a function of a yearly administrative act, which turns a constant into a
time-indexed parameter and changes the shape of the formalization without
adding to the methodological contribution.

**Consequence.** Nothing in this repository should be used to assess a real
present-day entitlement. This is stated in the README.

---

## D5 — Totality of the eligibility function

**Decision.** `isEligible` is total over `Beneficiary` and no input is
rejected as malformed.

**Reason.** `age` and `years` are natural numbers, so every value in the type
is a legally meaningful input. There is no partiality to handle.

**Open point.** This stops being true as soon as dates enter: not every pair
of dates is a valid (birth, assessment) pair. Totality will then have to be
re-established over a refined type, and `isEligible_total` will need a real
proof rather than a trivial one.

---

## Pending

| Id | Question | Blocks |
|---|---|---|
| P1 | How is the contribution record modelled, so that "seguidos ou interpolados" and Art. 12 density are expressible? | Art. 12 |
| P2 | How are dates and reference moments represented? | Art. 20(a)–(d) |
| P3 | Does the procedural requirement of Art. 10(1) belong in the same predicate as the substantive conditions, or in a separate layer? | Art. 10 completion |
| P4 | Which anticipation regimes are exceptions in the Catala sense, and which are separate rules? | Art. 20(a)–(d) |
