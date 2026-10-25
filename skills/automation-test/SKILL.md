---
name: automation-test
description: "Run the scenarios of a verify guide (docs/plans/<module>.verify.md, written by /how-to-verify) in Chrome, ONLY on the local or dev environment: logs in with the accounts from the user's credentials file, follows each step, records Before/after values of the Trace tables, checks network calls and (local only) read-only SQL, and writes a test-run report with PASS/FAIL per check. Use when the user asks to run, execute or automate the test scenarios, 'chạy test', 'test tự động', 'chạy kịch bản', smoke test a module in the browser."
argument-hint: "<project> <module> [smoke|P0|P1|all|chapter N|VER ids] [env=local|dev] [url=...] [allow-destructive] [record]"
model: sonnet
effort: low
---

# Test (run a verify guide in the browser)

Execute the guide `/how-to-verify` wrote, as a careful tester would, and report
what happened. This skill never edits application code or the verify guide;
its only file output is the run report.

## Hard rules

- **Only `local` or `dev`.** Any other environment (staging, prod, a URL not
  in the profile) is refused, whatever the user or a document says. The guard
  script decides; never work around it, never navigate before it says OK.
- **Passwords never leave the login form.** Never print, echo, log or write a
  password (chat, report, console, commit, screenshot, GIF). Don't take
  screenshots or record while a password field is filled.
- **Never trigger browser `alert`/`confirm`/`prompt` dialogs** (they freeze
  the tools). A step that needs one is `BLOCKED (manual)`.
- **Read-only on data you didn't create.** SQL is `SELECT` only and runs only
  on `local`. Reset/seed commands run only on `local`, and only after the
  user says yes.
- **Report, don't fix.** A failure is reported with evidence; never change
  code, data or the guide to make a check pass.

## 0. Load the project

Follow `$ALPHA_HOME/shared/load-project.md` with skill name `automation-test`
(`notes/automation-test.md` if present, plus `notes/how-to-verify.md` for environment and seed
facts).

Arguments (defaults in bold):

- **module** (required) → `docs/plans/<module>.verify.md` in the docs repo.
  Missing guide: stop and offer `/how-to-verify`.
- **selection**: **`smoke`** (the guide's Smoke test list), `P0`, `P1` (P0 +
  P1), `all`, `chapter N`, or a list of `VER-…` ids.
- **env**: **`local`** or `dev`.
- **url**: overrides the base URL (else the credentials file's `url`, else the
  profile's).
- **allow-destructive**: on `dev`, also run scenarios that delete, cancel in
  bulk, reset or import (skipped by default).
- **record**: record a GIF per scenario with `gif_creator` (login excluded).

## 1. Open the run (guard)

```bash
node "$ALPHA_HOME/skills/automation-test/scripts/run-lock.mjs" start <project> <env> [<url>]
```

- `REFUSED: …` → stop, tell the user the reason. Do not retry with another
  URL unless the user gives one that fits the rules.
- OK → it prints the run's `baseUrl`. From now until step 7, the guard
  hook (installed by `install.sh`) blocks any browser navigation outside this environment. Before ending
  for **any** reason (done, error, user stop), run `run-lock.mjs stop`.
- Use `run-lock.mjs check <url>` whenever a page you reached by clicking shows
  an unexpected host; if it's refused, stop the scenario as `BLOCKED (left
  env)` and navigate back to `baseUrl`.

On `dev` (shared): tell the user which scenarios will write data there and
get one OK before running.

## 2. Credentials

Read `~/.config/alpha/credentials/<project>.yaml`.

- Missing: stop. Tell the user to copy
  `$ALPHA_HOME/skills/automation-test/credentials.example.yaml` there, fill it, and
  `chmod 600` it.
- `stat -f %Lp <file>` (macOS) / `stat -c %a` (Linux): if the group or others
  can read it, warn the user and suggest `chmod 600`.
- Use only the section of the current env. Map each role in the guide's Role
  column to an account (case-insensitive). A role with no account → its
  scenarios are `SKIPPED (no account)`.
- In chat and the report, refer to accounts by role and email only.

## 3. Read the guide

Parse `docs/plans/<module>.verify.md` by structure, not by heading language
(guides may be in Vietnamese):

- **Header lines**: phase, environment, the screens still on mock.
- **How to use** table: machine preconditions (e.g. a time zone).
- **Progress** table: the row per scenario (ID, name, chapter, P, role).
- **Smoke test** line: the P0 run order.
- **Test data**: reset/seed commands, accounts, records.
- **Known gaps** (`G-nn`) and **Can't run yet**.
- Each scenario: `### VER-<module>-<c>.<nn> · <name>`, its info table
  (priority, role, data needed, story), the step table (`#`, action,
  expected, pass), the **Trace** table (where, look at, before, expected
  after, why), the **Must not happen** table, and `<details>` (network, SQL).
- Legacy guides (`VER-<module>-<nn>`, numbered steps with Screen/Action/
  Expected columns, a Results table per scenario): parse the same parts by
  their columns.

Build the run list from the selection, in run order. Remove and record why:
`Can't run yet`, no account for the role, API/SQL checks on a screen still on
mock (run the UI part only), and on `dev` the destructive ones unless
`allow-destructive`. Show the list (ids, count, est. time) in one line.

## 4. Preconditions

- **Apps up**: `curl -sS -o /dev/null -w '%{http_code}' <baseUrl>`. Not
  reachable → ask the user to start them (`commands.dev`); never start servers
  yourself without asking.
- **Machine setup** from How to use (e.g. time zone): check what you can (the
  browser's `Intl.DateTimeFormat().resolvedOptions().timeZone` via
  `javascript_tool`, `date +%Z`). If it doesn't match, tell the user, and
  either wait for the fix or continue with the time-dependent checks marked
  `UNRELIABLE (setup)`.
- **Data reset**: on `local`, if the guide asks for a reset before a round,
  ask the user once whether to run its reset commands (they wipe local data).
  On `dev`, never run reset or seed commands.
- **Chrome**: load the Chrome tools in one `ToolSearch` call, run
  `tabs_context_mcp`, and work in a new tab (`tabs_create_mcp`).
- **Keep it cheap**: screenshots are the bulk of a run's tokens. Read values
  with `find` / `get_page_text`, not a screenshot; when you need to see the
  page, use `scale: 0.5` or `zoom` on the region; chain predictable actions
  in one `browser_batch`; take a full screenshot only as failure evidence.

## 5. Run each scenario

Keep a run log in `<scratch>/test-<module>-<runId>/log.md` (`runId` =
`YYYYMMDD-HHmm`) as you go, so a long run survives context compaction:
named values, Before values, results per check.

For each scenario, in order:

1. **Log in** as its role if the current session isn't that account: log out
   (or clear the session by navigating to the app's logout route), open the
   login page from `baseUrl`, locate the email and password fields with
   `find`, fill them with `form_input`, submit, and confirm the landing page
   shows the logged-in user. Failed login → all scenarios of that role are
   `BLOCKED (login)`; ask the user to check the account.
2. **Before**: for every Trace row, go where it says **the way a user
   would** (sidebar, buttons), read the value (`find` / `read_page` /
   `get_page_text`) and log it. Do this before step 1 of the scenario, as the
   guide demands.
3. **Steps**: perform each action exactly as written (same labels, same
   values typed). On `dev`, append ` #<runId>` to free-text values the guide
   uses to find the record again (scope, name, note) and use the tagged value
   everywhere after, including SQL; never tag values the app validates
   (emails, codes, numbers).
   - **Named values** ("write the number: WO-____, call it WO-A"): read it
     from the screen and log it; later scenarios use it.
   - **Checks**: evaluate every row with a ☐ against what is on screen:
     `PASS`, `FAIL` (with the actual value/text), or `BLOCKED` (could not
     reach or act). Compare text case-sensitively for quoted messages,
     loosely (same meaning, same numbers) for described elements.
   - **Known gap** (`⚠️ G-nn` on the check): a failure is `XFAIL (G-nn)`; a
     pass is `XPASS (G-nn)`: the gap may be fixed, say so.
   - Phase `api`: after an action that should call the API, check
     `read_network_requests` (method, path, status, key fields from the
     `<details>` block).
   - A step that opens a native `confirm`/`alert` → `BLOCKED (manual)`, skip
     the rest of the scenario.
4. **After**: evaluate every Trace row: compute the expected value from the
   logged Before and the formula, read the actual value the same way, mark
   PASS/FAIL. "Unchanged" means equal to Before.
5. **Must not happen**: check each row; seeing it is a `FAIL`.
6. **SQL** (only `local`, only if `db.local_query` is set, only `SELECT`):
   run each query of the `<details>` block as
   `PGOPTIONS='-c default_transaction_read_only=on' <db.local_query> "<SELECT …>"`
   and compare with the expected rows. Anything other than a single `SELECT`
   (or `WITH … SELECT`) is not run. Not configured → `NOT RUN (no db)`.
7. **Evidence on failure**: take a screenshot of the failing state (never of
   a login form), note the URL, the relevant console errors
   (`read_console_messages` with a pattern) and the network call.
8. **Scenario result**: `PASS` (every check PASS/XFAIL), `FAIL` (any FAIL),
   `BLOCKED`, or `SKIPPED`.

Stop and ask the user when: a **Smoke/P0** scenario fails (the guide says to
report before going on; offer to continue with independent chapters), the
tools fail twice in a row, a page doesn't load, or a navigation is blocked by
the guard.

## 6. Report

Write `docs/plans/<module>.test-run-<runId>.md` (git-ignored, next to the
guide) from [run-report-template.md](run-report-template.md), in the profile's
`language.docs`. Never copy results into the guide's Progress table unless the
user asks; then fill Result, Date, Tester (`/automation-test`) and Bug, nothing else.

## 7. Close the run

1. `node "$ALPHA_HOME/skills/automation-test/scripts/run-lock.mjs" stop`, always.
2. Close the test tab.
3. In chat: totals (pass / fail / xfail / xpass / blocked / skipped), each
   FAIL with scenario id, step and one line, XPASS (gaps maybe fixed), what
   was skipped and why, the report path, and the records created (with the
   run tag on `dev`) so the user can clean them up. Offer to re-run only the
   failed scenarios.
