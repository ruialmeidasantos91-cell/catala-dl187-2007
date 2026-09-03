-- SPDX-FileCopyrightText: 2026 Rui Almeida Santos
-- SPDX-License-Identifier: Apache-2.0
--
-- Library root. Lake builds the module named after the library (DL187), so
-- this file must exist and import every module of the package. Without it
-- `lake build` fails with "some modules have bad imports", which says nothing
-- about the proofs themselves.

import DL187.Eligibility
