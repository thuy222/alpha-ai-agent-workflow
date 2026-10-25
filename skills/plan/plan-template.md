# Plan template

One template for both sides. Keep the blocks marked for your side
(`<!-- BE -->`, `<!-- FE -->`) and for the features the profile enables
(`<!-- feature: x -->`); delete the rest and the markers. Write the plan in the
profile's `language.docs`, identifiers in English.

````markdown
# <BE|FE> plan: <Module>

- **Status:** Draft | Questions open | Agreed
- **Updated:** YYYY-MM-DD
- **BA doc:** `docs/user-stories/<module>.md` (version, date)
- **Other side:** `docs/plans/<module>.fe.md` / `.be.md` (exists / not yet — contract provisional)

## 0. Overview

### Sources read

| Source                                     | Coverage            | Notes                              |
| ------------------------------------------ | ------------------- | ---------------------------------- |
| `docs/user-stories/<module>.md`            | all sections        |                                    |
| `docs/plans/<module>.be.md` <!-- FE -->    | contract, Decisions |                                    |
| `docs/database/<domain>.md`                | —                   | designed tables, enums, statuses   |
| Lovable `src/routes/<module>.tsx`          | lines 1–N / N       | plus imported data/lib/components  |
| BE code (entities, modules)                | —                   | what already exists                |
| FE code (screens, API modules, hooks)      | —                   | existing contract / wiring         |
| git branches (every repo)                  | —                   | in-flight work                     |

### Decisions

| Date | Question | Decision | By  |
| ---- | -------- | -------- | --- |

(Decisions in the other side's plan also apply; not repeated here.)

### Open questions index

| ID    | Story  | Tag  | One-line summary |
| ----- | ------ | ---- | ---------------- |
| Q00.1 | global | Tech | …                |

### BA delta <!-- feature: ba_delta; only when the BA changed after code was built -->

| Change | Old rule | New rule | BA section | Story / task | Checklist items unticked |
| ------ | -------- | -------- | ---------- | ------------ | ------------------------ |

### Enum / label mapping

| Item | BA doc | Lovable | API value | UI label <!-- FE --> | Decision / proposal |
| ---- | ------ | ------- | --------- | -------------------- | ------------------- |

### Data model <!-- BE -->

DB design: `docs/database/<domain>.md` (designed / not yet; `/db-design` needed: yes / no, why).

| Entity (table) | Key columns | Relations | Soft delete | Story |
| -------------- | ----------- | --------- | ----------- | ----- |

### API contract <!-- BE -->

| Method | Path | Permission | Request (DTO fields) | Response (`data`) | Story |
| ------ | ---- | ---------- | -------------------- | ----------------- | ----- |

List endpoints: `search` on …; filters …; `sortBy` = … (mirrors the FE table);
`sortDir`; `page`; `limit` → `{ items, total, page, limit }`.

Breaking changes to existing endpoints / FE types: none | …

### New permission codes <!-- BE -->

| Code | Constant | Used by |
| ---- | -------- | ------- |

### Contract check (against the BE plan) <!-- FE -->

| UI need | Endpoint / field | Status (ok / missing / mismatch) | Proposal |
| ------- | ---------------- | -------------------------------- | -------- |

### Feature layout <!-- FE -->

```
<the files the notes' layout prescribes: feature folder, API module, hook, thin routes>
```

### Global questions and assumptions

- **Q00.1 [Tech|UI|BA] <Topic>**: context (`file:line` / BA section).
  Options: A … / B ….
  **Recommendation:** A, because ….
- Assumption: … (source: …; reversible: easy / hard)

---

## US00: Refactor + shared components (built first) <!-- FE -->

- **Refactor step** (only if the notes require one before new behaviour): structure only, no behaviour change.

| Component | Location | Props / API | Used by (stories) | Reused by (other screens) |
| --------- | -------- | ----------- | ----------------- | ------------------------- |

- **Files:** …
- **Verification:** …

---

## US01: <BA title, verbatim>

**BA:** As a … I want … so that … ([doc § US01](../user-stories/<module>.md))

### Acceptance checklist (from the BA)

- [ ] UI: <component row> (<BA business rule>) <!-- FE -->
- [ ] Rule: …
- [ ] Validation: … <!-- BE -->
- [ ] Permission: … <!-- BE -->
- [ ] Success: …
- [ ] UI-L1: <element> looks and behaves as in the UI spec row below <!-- FE, feature: ui_spec -->

### UI spec (Lovable) <!-- FE, feature: ui_spec -->

One row per visible element of the story's screens; each row is a `UI-L`
checkbox above. Local component and variant come from the project's
Lovable-to-local mapping doc.

| #     | Element                | Lovable (`file:line`, label, control, icon, states, format)                                                | Local component / variant       | Match / Deviation (Decision or Q id) |
| ----- | ---------------------- | ---------------------------------------------------------------------------------------------------------- | ------------------------------- | ------------------------------------ |
| UI-L1 | Filter: Status         | `jobs.index.tsx:948`; outline chip h-8, sliders icon, "Status", count badge, popover: title, ✓ rows, Clear | `FilterDropdown variant="chip"` | Match                                |
| UI-L2 | Table column "Created" | `:1343`; `MM/DD/YY`, mono 11px, default sort desc                                                          | `formatShortDate()`             | Deviation → Q01.2                    |

### Lovable mapping

- … (`src/routes/<module>.tsx:L120-L180`)

### Gaps (BA vs Lovable vs local)

| Item | BA  | Lovable | Local | Resolution (Decision / Q id) |
| ---- | --- | ------- | ----- | ---------------------------- |

### API used <!-- FE -->

| Endpoint | Status (exists / planned / missing) |
| -------- | ----------------------------------- |

### Tasks

- [ ] API + hook: … ; UI: … ; uses US00 `<Component>` <!-- FE -->
- [ ] Entity / enum: … ; DTO: … ; Endpoint: `GET /<plural>` — `<permission code>` <!-- BE -->
- [ ] Migration: … <!-- BE, feature: migrations -->
- [ ] Tests: … <!-- feature: automated_tests -->

### Lovable bugs fixed here

- …

### Questions and assumptions

- **Q01.1 [BA] <Topic>**: context. Options: A / B. **Recommendation:** A, because ….
- Assumption: … (source: …; reversible: easy / hard)

### Code TODOs <!-- feature: code_todos -->

| Where (file › symbol) | `TODO(<module>): …` text | Removed by |
| --------------------- | ------------------------ | ---------- |

### Verification

- [ ] Tests: … (unit for pure logic / e2e per endpoint) <!-- feature: automated_tests -->
- [ ] Manual (browser): … including empty, loading and error states <!-- FE -->
- [ ] Visual: each screen in Chrome against its UI spec rows <!-- FE, feature: ui_spec -->
- [ ] Manual (Swagger / HTTP): … ; 403 without `<code>`; 400 on … <!-- BE -->

**Depends on:** US00 (<components>), BE `<endpoint>`, …

<!-- repeat one section per BA story, same IDs, titles and order as the BA doc -->

---

## Backend notes for the later `.be.md` <!-- FE plan of a UI-first module only -->

Entities and key columns, endpoints, permission codes, per story.

## Risks and dependencies

- …

## PR split

- PR1: US00
- PR2: US01 … (after BE PR …)

---

## Test scenarios (manual, browser) <!-- FE, feature: fe_test_scenarios -->

### Setup

- BE: branch …, seed …, start command.
- FE: start command, login as … (role …). DevTools → Network, filter `…`.
- Sample data (same as the BE plan's test data): … (id, number, name).
- Read the starting numbers first; compare deltas, not absolutes.

### Scenarios

| ID      | Story  | Screen / entry point     | Steps (what to click)      | Expected result                    | Cross-check on another screen            |
| ------- | ------ | ------------------------ | -------------------------- | ---------------------------------- | ---------------------------------------- |
| UI-01   | US01   | `/route` → rail          | Click …                    | URL …; shows …; Network: `GET …?…` | —                                        |
| ERR-01  | global | DevTools: block `…`      | Open tab …                 | Error + Retry                      | —                                        |
| PERM-01 | global | User with only `….view`  | Click …                    | 403 message from BE                | —                                        |

### Teardown

- [ ] Typecheck and lint (profile commands) clean.
- [ ] Every row PASS, or the reason recorded in the PR.
- [ ] Data put back: …
````
