---
name: plan
description: "Plan a module or user story of any alpha project BEFORE writing code. Loads the project profile, reads the BA doc in docs/user-stories, the Lovable prototype, the DB design and the codebase(s), then writes a BE and/or FE plan broken into the BA's user stories (shared components first), with the API contract, explicit open questions and assumptions for the user to confirm. Use when the user hands over BA user stories, asks to plan, 'lên kế hoạch', break down a module, or before any new screen, feature or API."
argument-hint: "<project> <module> [be|fe|fullstack] [lovable route] [BA doc path or link]"
model: opus
effort: high
---

# Plan

Produce a plan the team can review **before any code is written**. This skill
writes no application code. Its only file outputs are the BA module doc (when
bringing one in) and the plan document(s).

## 0. Load the project

Follow `$ALPHA_HOME/shared/load-project.md` with skill name `plan`. Below,
`docs/…` means the docs root of the project, `<be>` and `<fe>` the code roots
of each side, and "the notes" the project's `notes/plan.md`.

Inputs, from the arguments or the conversation:

- **Module / story**, e.g. "Purchase Orders" (kebab-case key in file names).
- **Scope**: `be`, `fe` or `fullstack`. Default: the side of the repo the
  session runs in; for a monorepo or when unclear, ask.
- **Lovable route or URL** (optional).
- **BA doc** (optional): a Markdown file, a PDF path or a link (Google Docs,
  Confluence…).
- **Story list**: the BA doc's story IDs and titles (`US01: View Purchase
  Orders`). Use a breakdown the user supplies only when the module has no BA
  doc.

**Existing plans.** Before anything else, read `docs/plans/<module>.be.md` and
`docs/plans/<module>.fe.md` if they exist. They hold decisions already made:

- The **Decisions** of **both** plans are settled. Don't re-ask them.
- If a newer BA doc or new code contradicts a decision, raise it as a new
  question that cites the decision.
- When you rewrite a plan, keep its Decisions table and add to it; never drop
  rows. Keep sections other skills own (e.g. a "DB design" section written by
  `/db-design`) as they are.
- Writing only one side? Never edit the other side's plan.

If the module or scope is missing, ask once with `AskUserQuestion` and carry
on with everything else meanwhile.

## 1. Read every source. Do not skim.

Do 1a–1c in parallel. Use `Explore` agents (`model: "haiku"`) for wide codebase sweeps and keep
the conclusions, not file dumps. Read Lovable and the docs yourself, because
the details matter.

### 1a. Docs

The BA doc lives at `docs/user-stories/<module>.md`. Read it in full. Never
hand-edit or reformat it: the only change allowed is replacing it wholesale
with a newer BA version (plus any team section the notes allow at its end).

**If a BA doc was given as a file elsewhere, a PDF or a link, bring it in
first**, following `docs/user-stories/README.md` (another plan run may have
done it already: check first):

1. Read it **in full**:
   - **Markdown file:** copy it as-is.
   - **PDF:** `Read` with `pages`, at most 20 pages per call, to the last page.
   - **Link:** the matching connector (e.g. the Atlassian MCP for Confluence)
     or `WebFetch`.
2. If it can't be read (a PDF needs `poppler`: `brew install poppler`; the
   link needs a login), stop and tell the user. Never plan from a doc you did
   not read.
3. Write `docs/user-stories/<module>.md`: a
   `> Source: <file or link>, received <date>` line, then the BA's content
   with its IDs, wording, acceptance criteria and tables unchanged, no
   interpretation. Diagrams and screenshots become text or tables where you
   can, `[Figure: …]` with a short description where you can't.
4. If the file already existed, overwrite it, then tell the user what changed
   (`git -C <docs repo> diff`), because those changes may affect existing
   plans. In a `split` layout, remind the user the file is committed in the
   docs repo.
5. **BA delta** (feature `ba_delta`): if a plan exists and code was already
   built on it, add a **BA delta** section to the plan: one row per change
   (old rule, new rule, BA section). Turn each row into a task in the story it
   belongs to (in the FE and the BE plan) and untick every checklist item the
   change invalidates, so the change is tracked as work instead of being found
   later.

**Then read** the module files of modules this one touches, the other plans
in `docs/plans/` for related modules, the DB design in `docs/database/` (the
index plus the domain files this module touches; its decisions are settled),
and any other docs the notes list.

**Extract**, each with a section reference into the module file: actors and
roles, user stories and acceptance criteria, the BA's UI-components tables,
business rules and validations, states and statuses (and allowed
transitions), permissions, out-of-scope items.

If there is no module file and no BA doc was given, say so in the plan and
treat Lovable as the only spec.

### 1b. The Lovable prototype

Project id: `lovable_project` in the profile (the BA doc's "Design Link" also
points to it). Use the `lovable` MCP; load its tools with `ToolSearch` first.
If it isn't connected, ask the user to run `/mcp`.

1. `list_files`, paginating until `next_cursor` is null. Find the module's
   route files (`src/routes/<module>*.tsx` or what the notes say).
2. Read each route file **to the end**. Large results are saved to disk; read
   them in sequential chunks and note the line count you covered.
3. Follow imports one level into data, lib and component files and read those
   too. Go deeper when a rule lives there (status rules, guards).
4. Note everything that touches the module from **other** routes: deep links,
   shared stores, modals reused elsewhere, record links.
5. Record, by side:
   - **Both:** data shapes and enums with exact values; business rules and
     calculations (quote the code comment, `file:line`); mutations (create,
     edit, delete, status changes, bulk actions, what writes history);
     **Lovable bugs** (an enum missing from a filter, UTC vs local date keys,
     a KPI label that doesn't match its computation, totals computed
     differently in two places, navigation that ignores the view mode);
     **prototype-only mechanics** not to port (localStorage persistence, mock
     data, floating seed dates, `window.confirm`).
   - **FE plan:** the **UI inventory**: header, KPIs, filters, search, sort,
     views, table columns, drawer tabs, modals, forms and fields, empty and
     loading states, exact labels, what navigates where. With feature
     `ui_spec`, go element by element with `file:line`, not a summary: the
     plan's UI checklist is built from it, and anything left out will not be
     built. Cover page header (container, title, subtitle, buttons), KPI cards
     (label, value colour, computation, roles), filters (control type, icon,
     label, order, popover content, active state and count, clear actions),
     search (placeholder, width), sort (control, options, default), view
     toggles, tables (column order, header style, cell content and format of
     dates, money and enums, avatars, badges and their case, density, zebra,
     empty state, pagination), Kanban (column look, card content), every tab
     and its sections, every dialog (title, fields, buttons, warnings), and
     what each role sees.
   - **BE plan:** what the screens need from the API: list filters, sort
     columns, search fields, KPIs/stats, lookups.
6. If screenshots were shared, compare them with the code. Behaviour the user
   points at must be in the plan.

### 1c. The codebase(s)

Follow each repo's `CLAUDE.md` and the notes, which name the concrete
folders. Whatever the scope, read both sides:

- **BE:** which entities, enums, modules, DTOs, permission codes, migrations
  and tests already exist for this domain; what is missing; which existing
  entities it relates to.
- **FE:** is the screen already routed and in the nav? Existing page, feature
  folder, store, API module and hook, i18n entries? Which shared components
  fit, and which exist only inline in another screen and should be promoted?
  Do the existing FE API types match the BE (an existing contract you must
  stay compatible with)? Which sort keys and filters does the screen's table
  use, so the BE `sortBy`/filters mirror them?
- **Shared contract** package, if the profile names one.
- **In-flight work**, in every repo: `git log --oneline -20`, `git branch -a`,
  and `git grep` across remote branches for the module's keywords. Before
  claiming something exists or doesn't, check every branch. If the user says
  "X is already built", verify it and report exactly what you found.

## 2. Analyse

- **Gap table, three-way**: BA doc vs Lovable vs local code (names, enums,
  fields, columns, behaviour). Precedence: Decisions (both plans) > BA doc >
  Lovable > local code, unless the project's `CLAUDE.md` says otherwise.
  - **BA vs Lovable conflicts become questions**, each with a recommendation
    (the BA requires a link Lovable lacks; the BA says filters reset on open
    but the code persists them).
  - Where local code (often a teammate's) differs, prefer an **additive**
    change: extra enum values, optional props/fields.
  - Keep a local synonym only when the BA doesn't name the value; if it does,
    raise a question. Show the mapping in the plan.
- **Deviations from Lovable are never silent** (FE). Where the BA is silent,
  Lovable's UI is the spec. Everything the plan would not reproduce exactly
  (another control, a missing element, another format) is backed by a
  Decision or raised as a question with a recommendation; a "Proposal" column
  alone never settles it.
- **Shared components first** (FE). Every piece another screen could reuse
  goes in **US00**, with its props, location and the screens that will reuse
  it. Promote only what a second screen actually needs.
- **Data model** (BE): entities with key columns, relations, soft delete or
  not, money as numeric, varchar enums (follow the BE conventions). Tables
  already designed in `docs/database/` are taken from there. When the module
  needs new tables or changes a table's relations, statuses or delete policy
  beyond the DB design, add a [Tech] question recommending an
  `/db-design` run first (or say why it can be skipped, e.g. one additive
  column).
- **API contract** (BE): per endpoint, method + path, permission code, request
  DTO fields with validation, response shape (inside the project's response
  envelope), list query params (`search`, filters, `sortBy` values,
  `sortDir`, `page`, `limit`). Flag every breaking change to an existing
  endpoint or FE type. New permission codes and the endpoints that use them.
- **Contract check** (FE): every field, enum value, filter and sort key the UI
  needs, against the BE plan's contract. If there is no BE plan yet, say so,
  derive what the screens need into a "Needs from the API" section, and raise
  a [Tech] question: plan the backend first, or proceed on a provisional
  contract. A mismatch is a question (it changes the BE plan), never something
  to work around in the FE.
- **Scope split** (monorepo, FE-only modules with feature `mock_phase`): mock
  store and seed data shaped like the future API, no backend tasks; note what
  the backend will need later in one short section.
- **Bugs to fix in the port**: each Lovable bug and how the port fixes it.

## 3. Write the plan

Use [plan-template.md](plan-template.md). Save to `docs/plans/<module>.be.md`
and/or `docs/plans/<module>.fe.md` (kebab-case). For `fullstack`, write the
`.be.md` first: the `.fe.md` builds on its contract. Show a condensed version
in chat. The plans folder is git-ignored: don't commit it. Anything teammates
need goes into committed files (the DB design, the code).

**Structure the plan by the BA's user stories**: one section per BA story,
same ID, title and order as the BA doc. The only extra story is **US00**
(FE: any refactor step the notes require, then shared components), which
comes first. Each `USxx` section has:

- **BA summary** with a link to its section in the module doc.
- **Acceptance checklist**, one checkbox per item in the BA's wording. FE:
  each row of the UI-components table, each UI rule, each success criterion,
  plus one `UI-L` row per UI spec element (feature `ui_spec`). BE: each
  business rule, validation, state transition and permission the API must
  enforce. Coding follows this checklist; review ticks it off.
- **UI spec (Lovable)** (FE, feature `ui_spec`): one row per element of the
  story's screens: element, Lovable (`file:line`, exact label, control, icon,
  states, format), local component and variant (from the mapping doc the notes
  name), and **Match** or **Deviation (Decision or Q id)**.
- **Lovable mapping** with `file:line` references.
- **Gaps** for this story; the last column names the Decision or question
  that settles each row.
- **Tasks**. FE: files to create or modify, the API module and hook, routes,
  the US00 components the story consumes; **API used** with each endpoint's
  status (exists / planned / missing). BE: entities/enums, DTOs, endpoints,
  permission codes, migrations (feature `migrations`), tests (feature
  `automated_tests`).
- **Lovable bugs fixed here**, if any.
- **Questions and assumptions for this story** (`Q02.1`, …).
- **Code TODOs** (feature `code_todos`): every item that will ship unfinished
  (BA items put off, placeholder values, mock data standing in for an
  endpoint, fallbacks waiting on another module, known limitations). For each:
  the file and symbol where its `TODO(<module>)` comment goes and the comment
  text, following the project's `CLAUDE.md` § TODO comments. "none" if
  nothing.
- **Verification**: automated tests (feature `automated_tests`, with the
  commands from the profile) and the manual checks: FE in the browser
  (including empty, loading and error states, and with `ui_spec` a
  side-by-side check of each screen against its UI spec rows: the local app in
  Chrome, Lovable through its code or the user's screenshots, never its
  preview); BE through Swagger or HTTP calls, including a 403 without the
  permission and the validation errors.
- **Depends on**: US00 components, other stories, BE endpoints, modules.

Global sections: sources read, decisions, open questions index, enum/label
mapping, BE: data model, **API contract** (the full endpoint table the FE plan
consumes), new permission codes; FE: contract check, feature layout; risks and
dependencies; PR split (US00 first, then one PR per story or group of small
stories; FE after the BE PR it depends on); BA delta (feature `ba_delta`).

### Test scenarios (FE, feature `fe_test_scenarios`)

The last section of an FE plan is a manual browser test script someone who
never read the plan can run before the PR. It says exactly *how* to check what
the per-story Verification lists say must hold. Use the BE plan's test data
(seed records, ids) so FE and BE test the same records.

- **Setup**: BE branch and seed commands, which user and role to log in as,
  sample records, DevTools filters, and "read the starting numbers first,
  compare deltas, not absolutes".
- **One row per scenario**: `ID` (prefix per area: `UI-01`, `TR-03`),
  `Story`, `Screen / entry point` (route plus where on the page), `Steps`
  (exact clicks and values typed), `Expected result` (exact labels, toasts,
  disabled states, URL changes, the request the Network tab should show with
  query params), `Cross-check` (another screen where the same data must
  match).
- **Coverage**: every BA success criterion and every decision visible in the
  UI; the happy path per action; each validation; empty, loading and error
  states; permissions/403; cross-screen consistency; URL/refresh/back; date
  filters around the UTC boundary; export; regressions on other screens the PR
  touches.
- **Teardown**: how to put the data back, plus a final checklist (the
  profile's typecheck and lint, every row PASS or a recorded reason).

### Questions and assumptions (mandatory)

**Questions** are decisions only the user can make. The user, not the BA,
answers them, so make each concrete and self-contained. Number them by story
(`Q02.1`; cross-story ones `Q00.1` in the global section) and tag each:
**[BA]** business behaviour or a gap in the BA doc, **[UI]** a design choice
the BA and Lovable leave open or disagree on, **[Tech]** an implementation
choice. Each gives the context and where it was seen (`file:line` or BA
section), 2–3 options, and **your recommendation and why**. Don't ask what the
code or docs already answer, nor what either plan already decided. About 10
questions at most; fold minor ones into assumptions. The **open questions
index** lists every open question with a one-line summary, so the user can
answer them in one pass.

**Assumptions** are what you will do unless told otherwise: concrete, with a
source and how hard they are to reverse (enum/label mapping, dropped prototype
behaviour, mock vs real data, permission codes, timezone and week start,
money/date formatting, component placement, PR split).

**Risks / dependencies**: modules or endpoints this one depends on that
aren't built yet.

## 4. Iterate. Do not code.

- Stop after presenting the plan. On each answer: update the plan file, move
  the answered question into **Decisions** with the date, re-ask only what is
  still open. A skipped question stays open; repeat it briefly at the end of
  each reply.
- "You decide": research it, decide, record the reasoning in Decisions, and
  report it back.
- When a decision changes the API contract and the other side's plan exists,
  tell the user that plan needs a refresh.
- Start coding only when the user explicitly says so, through
  `/implement`.
