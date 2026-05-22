# Formal Verification of Old-Age Pension Eligibility (DL 187/2007)

![Catala](https://img.shields.io/badge/Catala-1.1.0-blue)
![Lean](https://img.shields.io/badge/Lean-4.29.1-purple)
![License](https://img.shields.io/badge/License-CC%20BY%204.0-green)
![Status](https://img.shields.io/badge/Status-Work%20in%20Progress-yellow)

## Overview

This repository contains a formal specification and verification pipeline for the old-age pension eligibility rules of the Portuguese General Social Security Regime, as defined in Decreto-Lei n.º 187/2007, of 10 May.

The goal is to produce a faithful-by-construction formalization of the law, grounded in First-Order Logic, implemented in Catala, and formally verified in Lean 4.

## Pipeline

The pipeline follows the canonical sequence:
FOL → Catala → Lean 4
(specify) (implement) (verify)
| Step | Tool | Role |
|------|------|------|
| 1 | First-Order Logic (FOL) | Mathematical specification of the law |
| 2 | Catala | Executable legal implementation |
| 3 | Lean 4 | Formal verification of correctness |

> Python (Hypothesis) will be added in a later phase as a property-based testing harness to detect divergences across implementations.

## Current Scope

Articles formalized (original 2007 wording, before 2014 amendments):

| Article | Description | Status |
|---------|-------------|--------|
| Art. 19 | Guarantee period (15 civil years) | ✓ |
| Art. 20 | Normal age of access (65 years) | ✓ |
| Art. 10(1) | Common eligibility conditions | ✓ partial |

**Exclusions (current phase):**
- Anticipation regimes (Art. 20 a-d)
- Art. 12 density rules
- Survivor's pension

## Repository Structure
Pensoes.catala_en        # Catala implementation (includes FOL header)
lean/DL187/              # Lean 4 formal verification
run_pipeline.sh          # End-to-end pipeline test script
clerk.toml               # Catala build configuration

## How to Run

### Prerequisites

- [Catala 1.1.0](https://catala-lang.org)
- [Lean 4.29.1](https://leanprover.github.io) via `elan`

### Full pipeline

```bash
./run_pipeline.sh
```

### Individual steps

```bash
# Catala tests
clerk run Pensoes.catala_en --scope=TestCase1
clerk run Pensoes.catala_en --scope=TestCase2
clerk run Pensoes.catala_en --scope=TestCase3

# Lean 4 verification
lean lean/DL187/Eligibility.lean
```

## Academic Context

This work is part of a PhD research project titled *"Verificação Formal das Pensões de Velhice e Invalidez"*, situated within the Rules as Code paradigm (INRIA, OECD).

The pipeline implements a triple formalization strategy: FOL (specification) → Catala (legal implementation) → Lean 4 (formal verification).

The Tribunal de Contas (Portugal) serves as the institutional anchor for the practical utility of this work in Social Security auditing and oversight.

## Legal Scope

| Field | Value |
|-------|-------|
| Diploma | Decreto-Lei n.º 187/2007, de 10 de Maio |
| Regime | Regime Geral de Segurança Social |
| Wording | Original 2007 (pre-2014 amendments) |
| Coverage | Partial — work in progress |

## License

This work is licensed under [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).
