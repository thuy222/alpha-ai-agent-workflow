# Test-run report template

Saved as `docs/plans/<module>.test-run-<runId>.md` (git-ignored). Written in
the profile's `language.docs`; identifiers and on-screen text verbatim. No
passwords anywhere.

````markdown
# Test run <Module> — <runId>

- **Guide:** `docs/plans/<module>.verify.md` (updated YYYY-MM-DD)
- **Environment:** local | dev — <baseUrl>
- **Code:** <repo> `<branch>` @ `<sha>` (per repo)
- **Selection:** smoke | P0 | … (<n> scenarios)
- **Accounts:** Admin `<email>`, Technician `<email>`
- **Machine:** time zone <tz>; browser <version>
- **Run tag (dev):** `#<runId>` | none
- **Started / finished:** HH:mm – HH:mm

## Summary

| PASS | FAIL | XFAIL | XPASS | BLOCKED | SKIPPED |
| ---- | ---- | ----- | ----- | ------- | ------- |
|      |      |       |       |         |         |

## Results

| ID                | Scenario | P   | Role  | Result | Failed checks | Note |
| ----------------- | -------- | --- | ----- | ------ | ------------- | ---- |
| VER-<module>-1.01 |          | P0  | Admin | PASS   |               |      |

## Failures

### VER-<module>-1.01 · step 3 (check 2)

- **Expected:** <from the guide>
- **Actual:** <what the screen showed>
- **Where:** <URL, screen, element>
- **Network:** `POST /api/v1/…` → 500 `{ message: … }` | not called
- **Console:** <relevant errors>
- **SQL (local):** <query → rows> | not run
- **Likely layer:** <from the guide's triage table>
- **Screenshot:** taken (describe it)

## Trace values

| Scenario | Where / look at | Before | Expected after | Actual after | Result |
| -------- | --------------- | ------ | -------------- | ------------ | ------ |

## Known gaps seen

| Gap  | Scenario / step | XFAIL / XPASS | Note |
| ---- | --------------- | ------------- | ---- |

## Skipped / blocked

| ID | Why (can't run yet / no account / destructive on dev / login / manual dialog / left env) |
| -- | ------------------------------------------------------------------------------------------ |

## Named values

| Name | Value | Created in |
| ---- | ----- | ---------- |
| WO-A | WO-10234 | VER-<module>-1.01 |

## Data created

Records this run created (find them by the values above or the run tag), for cleanup.
````
