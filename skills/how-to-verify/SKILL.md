---
name: how-to-verify
description: "Write a manual verification guide for a module or feature of any alpha project: step-by-step test scenarios a person follows in the UI (which screen, what to click and type, as which role), what each step must show, which API calls and database rows to check, which other screens the action affects, and what to suspect when the result differs. Reads the user stories, plans, Lovable, the FE, the API and the DB design separately, walks the real screens in Chrome first, and saves the guide to docs/plans/<module>.verify.md (git-ignored). The guide is also the input of /automation-test. Use when the user asks how to test or verify a module, 'test thế nào', 'kiểm tra', 'kịch bản test', acceptance or QA scenarios."
argument-hint: "<project> <module> [US ids] [phase: mock|api] [environment URL]"
model: sonnet
effort: medium
---

# Verify (write the guide)

Produce a guide a developer, the BA or a tester follows by hand to confirm a
module works end to end; `/automation-test` runs the same guide in the browser. This
skill writes no application code and no automated tests; its only output is
`docs/plans/<module>.verify.md`, git-ignored like every plan (never commit it,
never link to it from committed files).

## 0. Load the project

Follow `$ALPHA_HOME/shared/load-project.md` with skill name `how-to-verify`. The
notes (`notes/how-to-verify.md`) name the concrete paths for each research agent,
the dev accounts and seed commands, and project-specific setup (time zone,
ports).

Write the guide in the profile's `language.docs`, keeping UI labels exactly
as the app shows them and identifiers, routes, endpoints, tables and columns
in English. Headings may be translated, but keep the structure of
[verify-template.md](verify-template.md) exactly: `/automation-test` parses it.

Inputs, from the arguments or the conversation:

- **Module** (kebab-case key) and optionally the **stories** to cover
  (`US01-US05`). Default: all stories of the module.
- **Phase** (feature `mock_phase`): `mock` (the FE runs on mock stores;
  nothing reaches the API or the DB) or `api`. If unstated, find it from the
  code (does the screen call the API layer?) and say which you found. Without
  the feature, find per screen whether it still runs on mock data and say so.
- **Environment** (optional): the FE base URL. Default: `environments.local`
  from the profile (or the user's override in their credentials file).

If the module is missing, ask once with `AskUserQuestion`.

## Prerequisites

Check these first; if one is missing, stop and tell the user what to do.

- The **Chrome tools** (`mcp__claude-in-chrome__*`): load them with one
  `ToolSearch` call and run `tabs_context_mcp`. If unavailable, ask the user
  to open Chrome with the Claude extension (or run `/mcp`).
- The **`lovable` MCP** is connected.
- The **apps are running** at the environment URL (`commands.dev`). If not,
  ask the user to start them; don't start long-running servers yourself
  without asking.
- Login accounts for the roles in scope: the user's credentials file
  (`~/.config/alpha/credentials/<project>.yaml`, see `/automation-test`), the dev
  seed accounts the notes or the `ui` agent find, or ask. Never type real
  customer data. Never write a password into the guide; name the account
  (email) and point to the seed or the team for the password.

## 1. Read each source separately

Run these research agents in parallel (`general-purpose` with
`model: "sonnet"`, or `Explore` with `model: "haiku"` for pure code sweeps).
Give each only its own source (the concrete paths come
from the notes) and the report format below, so each source is read on its
own terms and gaps between them show up. Each writes
`<scratch>/how-to-verify-<module>/<source>.md` and replies with a short summary.

| Agent       | Reads | Reports |
| ----------- | ----- | ------- |
| **stories** | `docs/user-stories/<module>.md` in full, plus the modules it references; the Decisions of `docs/plans/<module>.fe.md` / `.be.md` | Per story: roles, the user flow, every field with its rules (required, format, default), success criteria, business rules and error messages, what each role may and may not do. Decisions override the user story. |
| **ui**      | The FE routes, screens/feature folder, the components, stores, API modules and hooks they use, the nav definition, the i18n files (if any), the mock seed | How to reach each screen (nav label, route, buttons), exact labels of fields, buttons, tabs, filters and messages, what each action calls (API or mock store), which permission or role hides what, seed records usable as test data. Marks stories with no screen yet and screens still on mock data. **Value map:** for every input a user types or picks, every screen that shows it or a value computed from it (KPI cards, counters, badges, totals, balances, lists in other modules), with the path to reach it and the formula from the code. |
| **api**     | The BE module (controller, DTOs, services), the entities it writes, the permission constants, tests if any, shared contract types | Every endpoint (method, path, permission), request validation and error responses, response shape, side effects in the services (other tables, activity/audit, stock, integrations, email). Marks what doesn't exist yet. |
| **lovable** | The Lovable project at HEAD: the module's route/component files and the data/lib files they import; grep the prompt history (`list_messages`) for the module | The intended screens and flows as the client reviewed them: labels, fields, buttons, states, messages, role differences, and every place Lovable differs from the user story or from the FE (Lovable's own bugs are flagged, not copied). |
| **db**      | `docs/database/<domain>.md` and the domains it links to (if written), otherwise the module's entities (and migrations) | Tables and columns each action writes, constraints that reject bad input, derived values with their formulas (stored or computed, what recomputes them), status machines, and **Cross-domain links**: which other tables and modules change or read this data. SQL to inspect each change. |

When a source has nothing (no API yet, no BA doc, no DB doc), the agent says
so; it never invents behaviour.

## 2. Walk the screens in Chrome (mandatory)

Before writing any scenario, look at the real app, so the steps describe what
is on screen, not what the code suggests:

1. Open a new tab (`tabs_create_mcp`) on the environment URL and log in as the
   main role.
2. Reach every screen in scope **the way a user would**: from the sidebar or
   the buttons the `ui` report names, not by typing the route. Use
   `read_page` / `find` to record exact labels, the default state (empty list,
   seed rows, filters), and where each result appears.
3. Try each main action once **in the local environment only** (create, edit,
   status change) and note what the screen shows after it (toasts, badges,
   counters). In the `api` phase, watch `read_network_requests` for the call.
   Don't run actions in a shared environment without the user's OK. For each
   input in the value map, go to every screen it affects, the way a user
   would, and note the value **before** and **after** the action. A mismatch
   with the formula is a finding for **Known gaps**.
4. Repeat the visible-differences check as the other roles in scope (hidden,
   read-only or refused).
5. Compare with the `lovable` report and note the differences. Don't open the
   Lovable preview in Chrome: it needs a Lovable login, and the MCP gives the
   code.
6. **Visual check** (feature `ui_spec`). For each screen, take a screenshot
   and go through the plan's **UI spec (Lovable)** rows (if the plan has none,
   use the `lovable` report): container, control type, icon, labels, order,
   popover content, active/empty states, formats, case, colours, density.
   Compare with Lovable screenshots the user shared, too. Record each mismatch
   with the row id, or as "missing row".

Never trigger browser `alert`/`confirm` dialogs (they block the tools); if a
button is known to open one, skip it and note it. If a page doesn't load or
the tools fail twice, stop and ask the user. Record what you saw in
`<scratch>/how-to-verify-<module>/walkthrough.md`.

## 3. Reconcile before writing

- **Expected behaviour** comes from the Decisions, then the user stories, then
  Lovable where the story is silent. The app, API and DB tell you **how to
  observe** it, never what is right.
- Where the story and Lovable disagree, the expectation follows the story and
  the difference goes under **Known gaps** with both sources.
- Where the code differs from the story (a missing field, another label, a
  rule not enforced), keep the story's expectation and list the difference
  under **Known gaps**, so the tester knows the failure is expected. A
  `TODO(<module>)` in the code that explains the gap is cited there.
- Where no source defines the expected result, write an open question in the
  guide instead of guessing.

## 4. Write the scenarios

Use [verify-template.md](verify-template.md). The reader is a tester who does
not know the code: everything a developer needs goes into the closing **For
developers** section, or a collapsed `<details>` block inside a scenario.

### Organise by business flow, not by user story

Group scenarios into **chapters that follow the life of the module's main
record**, in the order the business lives it (for work orders: create →
schedule and dispatch → do the work → bill → invoice and payment → close or
cancel). Then the cross-cutting chapters: roles and permissions, settings that
change other records, effects on other modules. A story that spans several
steps is checked in each chapter where it happens; story ids go only in the
scenario's info table, never in its title.

Each chapter starts with its **own data**: the seed records it uses, or the
earlier scenario it continues from. A chapter never depends on a later one,
and a failure in one chapter must not break the others; say how to start a
chapter on its own.

Mark each scenario **P0** (the flow is broken without it), **P1** (main rules
and calculations) or **P2** (edge cases, look). The P0 scenarios together are
the **Smoke test** (about 15–30 minutes), listed at the top.

### Follow every value to where it shows up

The heart of the guide. Whenever a step enters or changes a value (quantity,
rate, hours, status, date, customer), the scenario checks **every screen that
shows that value or a number computed from it** (the value map, the db
report's derived values, the walkthrough):

1. **Before the action**, the tester writes down the current value on each
   affected screen (a `Before` column), because seed data and earlier tests
   change the numbers.
2. **The action**, with concrete inputs (`Hours = 5`, not "some hours").
3. **After**, per affected screen: how to get there from the sidebar or a
   button, the exact field or card, the expected value as a number or a
   formula on `Before` (`Before + 1`, `5 × $140 = $700.00`), and why (the
   rule, with its source). Use the format the screen shows.
4. The screens that must **not** change, when a wrong change is a likely bug.

Write this as the scenario's **Trace** table. One input that affects five
screens has five rows; never shorten it to "check the other screens".

### What the chapters cover

1. **Happy path**: the main flow as the main role, with full traces.
2. **Validation**: each required field empty, each format rule broken, each
   limit (length, range, duplicate key).
3. **Roles**: the same action as each role the stories name, including the
   ones that must be refused or must not see something.
4. **States and edge cases**: status rules, empty lists, long values,
   cancel/back, reload (in the `mock` phase data is lost on reload; say so),
   pagination and sort.
5. **Effects on other modules**: from the db report's Cross-domain links and
   the api report's side effects. For each: the screen to open, what to look
   for, why it should change.
6. **Look matches Lovable** (feature `ui_spec`): one P2 scenario per screen
   that walks its UI spec rows. Visual mismatches from step 2.6 go under
   **Known gaps** with the `UI-L` id, unless a Decision backs them.

### Every scenario has

- an id `VER-<module>-<chapter>.<nn>` (`VER-orders-2.03`), numbered in run
  order. A new scenario takes the next number of its chapter; never renumber
  the others to make room. Refer to other scenarios by these ids. A short name
  a tester understands, the priority and the role to log in as;
- **data**: which seed record, or which earlier scenario created it, with
  concrete values. Never hard-code a value generated at run time (a new
  number, an id): write "the order just created (write its number: ____)",
  give it a short **name** (`WO-A`), and refer to it by that name afterwards;
- **everything in tables**: an info table (priority, role, data needed,
  story) under the heading, then a step table `# | Action | Expected | Pass`.
  Prose only for the chapter intro and short notes;
- **steps**: at most about 8 per scenario (split longer ones), each row one
  action on a named screen (menu label, button label, field label, value
  typed), never "fill in the form";
- **checks**: one row per thing to look at (step number and action only on
  its first row), never several facts in one cell, each with a ☐. Quote
  on-screen text exactly only for messages that matter (errors, warnings). An
  action with nothing to check has an empty Expected cell;
- a **Trace** table whenever a step enters or changes a value;
- a **Must not happen** table when a wrong effect is a likely bug;
- a `⚠️ G-nn` mark on the check itself when it is a known gap;
- inside `<details>` (phase `api`): the request in the Network tab (method,
  path, status, key response fields), the SQL with expected row values, and
  the likely cause by layer if it doesn't match;
- the story and decision ids it covers, in the info table.

Results go in the single **Progress** table at the top, not in a table per
scenario.

## 5. Check the guide against the app

- Every menu label, button, field label and message the steps name is what the
  walkthrough saw (and exists in the i18n files, if any); every endpoint and
  column exists in the api and db reports. A step whose label doesn't exist
  yet is marked `(not built yet)` instead of deleted: the guide doubles as
  acceptance criteria.
- Every input in the value map is traced in at least one scenario; every
  expected number is recomputed from its formula.
- **Fresh-reader check:** give the draft (only the guide) to a
  `general-purpose` agent (`model: "sonnet"`) playing a tester new to the project. It reports every
  step where it would not know which screen to open, what to click, where to
  look or what value to expect. Fix each one.

## 6. Save and summarise

Write `docs/plans/<module>.verify.md`. If it exists, keep the results the
tester filled in and the ids of scenarios that stay in their chapter; add new
ones at the end of their chapter. When chapters are reorganised (scenarios
move, merge or are dropped), or the old guide uses another id scheme
(`VER-<module>-<nn>`), number again in run order and add an **Id changes**
table (old → new), moving each filled-in result to its new id.

In chat: the chapters with their scenario count and P0 count, the values
traced across modules, the known gaps, the open questions, and which
scenarios can't run yet (not built, or `api` checks in the `mock` phase).
Offer to run the guide in the browser with `/automation-test`.
