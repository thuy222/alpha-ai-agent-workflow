# Verify guide template

The guide is `docs/plans/<module>.verify.md` (git-ignored). Write it in the
profile's `language.docs`: translate the headings and prose; keep UI labels
exactly as on screen and identifiers in English. Drop sections that don't
apply.

**Fixed structure (parsed by `/automation-test`):** keep the order of the sections,
the scenario heading `### VER-<module>-<chapter>.<nn> · <name>`, the info
table (priority, role, data, story) right under it, the step table with four
columns (`#`, action, expected, pass ☐), the Trace table with five columns
(where, look at, before, expected after, why), and the Progress table columns
(ID, scenario, chapter, P, role, result, date, tester, bug) in that order.

The first screen of the file must tell a tester how to start, what to run
first and where to tick results. Everything for developers sits at the end or
inside `<details>`.

````markdown
# Verify <Module>

- **Scope:** <business flow covered> (`docs/user-stories/<module>.md`, <version>; Decisions …)
- **Phase:** mock (data in mock stores, lost on reload) | api — screens still on mock: none | <screen>
- **Environment:** FE http://localhost:<port>, API http://localhost:<port> (Swagger …) · accounts: see **Test data**
- **Updated:** YYYY-MM-DD, walked in the app on <date> (branch `<b>` @ `<sha>`), Lovable HEAD `<sha>`

## How to use

| # | What to do |
| --- | --- |
| 1 | <machine setup the module needs, e.g. time zone> |
| 2 | Reset the demo data once before each round (see **Test data**). |
| 3 | Log in with the account the scenario names. |
| 4 | Run the **Smoke test** first. If one fails, report it before going on. |
| 5 | Run the chapters in order; each says what data it needs and how to start it on its own. |
| 6 | Write the **Before** column of a Trace table before step 1; after the action, compare with **Expected after**. |
| 7 | A check marked ⚠️ G-nn is a known gap: it is expected to fail. |
| 8 | Tick results in **Progress** below. |

## Progress

| ID                | Scenario                  | Chapter | P   | Role  | Result | Date | Tester | Bug |
| ----------------- | ------------------------- | ------- | --- | ----- | ------ | ---- | ------ | --- |
| VER-<module>-1.01 | Create a job to the queue | 1       | P0  | Admin |        |      |        |     |

## Smoke test (~15 min)

VER-<module>-1.01 → 2.01 → 4.01 → 5.01 (the P0 scenarios, in run order)

## Test data

**Reset (local only, never on a shared environment):**

```bash
<seed / reset commands>
```

**Accounts:** <role → email; where the password comes from (seed, team). Never write a real password here.>

| Record                       | Why it is useful                       |
| ---------------------------- | -------------------------------------- |
| Customer "Demo — Bayou …"    | Labor $120/h, tax-exempt               |

## Impact map

| Action in this module | Other module / screen affected | Where to check | Expected |
| --------------------- | ------------------------------ | -------------- | -------- |

## Chapter 1: <first step of the business flow>

**Data for this chapter:** <seed records; or "continues from VER-…"; how to start this chapter on its own>

### VER-<module>-1.01 · <short name a tester understands>

| Priority | Role  | Data needed                    | Story                    |
| -------- | ----- | ------------------------------ | ------------------------ |
| **P0**   | Admin | customer `Demo — Bayou …`      | US01, US02 · Decision D8 |

| #   | Action                                                        | Expected                                                    | Pass |
| --- | ------------------------------------------------------------- | ----------------------------------------------------------- | ---- |
| 1   | Sidebar **Work Orders** → button **+ New Work Order**         | The "New work order" modal opens                            | ☐    |
| 2   | **CUSTOMER** = `Demo — Bayou …`                               | Info strip shows "Labor rate: $120.00/hr"                   | ☐    |
| 3   | **SCOPE OF WORK** = `VER-1.01 test` → **Create work order**   | Toast "WO-… created". Write the number: **WO-\_\_\_\_\_** (call it **WO-A**) | ☐    |
|     |                                                               | The badge of the new row is **Created** ⚠️ G-02             | ☐    |

**Trace** (fill **Before** before step 1):

| Where (how to get there)             | Look at                  | Before | Expected after         | Why                          |
| ------------------------------------ | ------------------------ | ------ | ---------------------- | ---------------------------- |
| Sidebar **Dashboard**                | Card OPEN WORK ORDERS    |        | Before + 1             | New WO is open               |
| Sidebar **Dispatch**                 | UNASSIGNED QUEUE, last   | –      | Card WO-A, 4.0h        | No technician → queue (D8)   |
| Sidebar **Schedule**                 | This week                |        | **Unchanged**          | No date, not on the calendar |

| Must not happen                      | Pass |
| ------------------------------------ | ---- |
| WO-A shows on the Schedule           | ☐    |

<details><summary>For developers</summary>

- Network: `POST /api/v1/work-orders` → `201`, `data.status = "CREATED"`.
- SQL:
  ```sql
  SELECT number, status FROM work_orders WHERE scope = 'VER-1.01 test';
  -- 1 row, status 'CREATED'
  ```
- If it differs: toast but no queue card → the Dispatch query is not
  invalidated after create.

</details>

## Chapter 2: <next step of the flow>

…

## Chapter N: Roles and permissions

…

## Known gaps

Where the app (or Lovable) doesn't match the user story. Scenarios keep the
story's expectation, so the checks marked with these ids are expected to
**fail** until fixed.

| Id   | Scenario / step       | The story says | The app / Lovable does | Source (incl. `TODO(<module>)`) |
| ---- | --------------------- | -------------- | ---------------------- | ------------------------------- |
| G-02 | VER-<module>-1.01 / 3 |                |                        |                                 |

## Can't run yet

| Scenario          | Why                  |
| ----------------- | -------------------- |
| VER-<module>-2.03 | Screen not built yet |

## Open questions

Where no source says what the right result is.

## For developers

### Behind the UI (phase `api`)

Endpoints, settings and SQL shared by several scenarios.

### Triage when the result differs

| Symptom                                      | Suspect layer                           | Where to look                                         |
| -------------------------------------------- | --------------------------------------- | ----------------------------------------------------- |
| Button / field missing, wrong label          | UI not built, or differs from the story | The user story and Lovable; see Known gaps            |
| Clicking sends no request (phase `api`)      | The screen still uses mock data         | The screen's store / hook                             |
| Request returns 400                          | DTO validation                          | The response `message`; the module's DTOs             |
| Request returns 401 / 403                    | Login or permission                     | The account's role; the permission constants; seed    |
| Request 2xx but the screen doesn't change    | The FE doesn't refresh after the call   | Query invalidation / the store action                 |
| Number right on one screen, wrong on another | Different formula or stale cache        | The Trace row's formula; the query each screen uses   |
| Screen right, database wrong or missing      | Service or entity                       | The module's service; the scenario's SQL              |
| Right after create, gone after reload        | Mock phase (expected) or not saved      | The module's phase                                    |
| Another module doesn't see the change        | Cross-module link                       | Impact map; `docs/database/<domain>.md` → Cross-domain links |
| A `TODO(<module>)` explains the behaviour    | Known, deferred work                    | `git grep "TODO(<module>)"`                           |

Report a bug with: scenario id, step number, expected, actual, a screenshot,
and the request/response if any.

### Id changes

| Old id | New id | Why |
| ------ | ------ | --- |
````
