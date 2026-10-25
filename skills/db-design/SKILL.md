---
name: db-design
description: "Design or extend the Postgres schema / data model of any alpha project from the latest SOW (if any), BA docs, client decisions and the Lovable prototype; have it reviewed by the independent alpha-db-design-reviewer agent; write the committed docs (docs/database/README.md + docs/database/<domain>.md). Always confirms with the user that the sources are the latest before designing. Use when the user asks to design the DB or schema, 'thiết kế db', draw an ERD, add tables for a new module, document the existing schema, or review the schema against new requirements."
argument-hint: "<project> [all | <module> ...] [path to SOW] [paths/links to new BA docs]"
---

# DB design

Design the database **before** entities (and migrations) are written, and
leave a committed design doc the whole team can read. This skill writes no
application code: no entities, DTOs or migrations.

## 0. Load the project

Follow `$ALPHA_HOME/shared/load-project.md` with skill name `db-design`. All
`docs/…` paths are in the docs repo; the schema lives on the `be` side. The
notes (`notes/db-design.md`) give the concrete conventions (id type, enum
location, money precision, FK rules, how the schema reaches `dev`) and the
suggested research groups.

| Output                          | Committed | What                                                                   |
| ------------------------------- | --------- | ---------------------------------------------------------------------- |
| `docs/database/README.md`       | yes       | Index: sources used, conventions, domain map, overall ERD, table index |
| `docs/database/<domain>.md`     | yes       | One file per domain: ERD, tables, enums, indexes, rules                |
| `docs/user-stories/<module>.md` | yes       | Only when the user hands over a new BA doc (converted, see step 0)     |
| Decisions, open questions       | **no**    | See "Where questions and decisions live" below                         |

**Where questions and decisions live.** Open questions never go into a
committed file.

- Default: open `DB-Qnn` questions in full in `docs/db_questions` from the
  profile (e.g. `docs/plans/database.md`, git-ignored) with an index table;
  committed docs carry only `Provisional (DB-Qnn)` markers and, once a
  question is answered, a row in the domain doc's **Design decisions** table.
- Feature `db_questions_in_be_plan`: the **DB design decisions**, **Not
  ported from Lovable**, **DB open questions** and **DB design changelog**
  live only in the "DB design" section of the owning module's local BE plan
  (`docs/plans/<module>.be.md`; create the section if missing, keep its rows
  across rewrites). Committed docs mark affected columns `Provisional` with
  no question id and cite no decision ids or plan files; the domain doc
  states each rule itself with its BA, SOW, Lovable or entity source.

Scope from the arguments: `all` (the whole product), or one or more modules
(kebab-case keys). If missing, ask once.

When most of the schema already exists as entities, the job for an existing
domain is to **document what is there**, check it against the sources, and
design only the additions; never redesign an implemented table silently.

Speak the profile's chat language with the user. Everything written to the
repo is English.

## Prerequisites

Check these first. If one is missing, stop and tell the user what to do.

- The `lovable` MCP is connected (load its tools with `ToolSearch`; otherwise
  ask the user to run `/mcp`).
- `jq` on the PATH.
- `poppler` when a source is a PDF, so `Read` can open it:
  `! brew install poppler` on macOS, `sudo apt install poppler-utils` on Linux.
- The `alpha-db-design-reviewer` agent.
- This skill's files: [references/research.md](references/research.md) and
  [db-doc-template.md](db-doc-template.md). BA-doc conversion follows
  `/plan` step 1a.

## 0. Source freshness gate (mandatory, every run)

Never design from what happens to be in the repo: the repo copies go stale and
the SOW (if there is one) is not in the repo at all. Before any research:

1. Read **Sources used** in `docs/database/README.md` (if it exists) to know
   which versions the current design was built on.
2. List what the repo has: every `docs/user-stories/*.md` with its
   `> Source:` line (version, received date), and the Decisions of any local
   `docs/plans/*.be.md` / `.fe.md`.
3. Ask the user in **one** `AskUserQuestion` call, showing those versions, and
   wait. Always ask, even if the last confirmation was recent; it is only
   shorter then.
   - **Full form** (first run, a new module, or no confirmation in the last
     14 days), one question each:
     - **SOW:** "The last design used SOW <title, version, date> | no SOW. Is
       it the latest? Give the path or link of the newest one" (or "no SOW",
       a valid answer unless the notes say the project always has one).
     - **BA docs:** "These BA docs are in the repo: <module, version, date>.
       Are they the latest? Any new or updated ones (path/link)?" For a new
       module, ask for its BA doc by name.
     - **Client decisions:** "Any client answers or agreed changes since
       <date> (Slack threads, meeting notes, screenshots) not yet in the
       design?"
     - **Lovable:** "Is project <lovable_project> still the current
       prototype?" Lovable is always read live at HEAD.
   - **Short form** (confirmed within 14 days): one question listing every
     source and its version, "Still the latest, or is there something new?",
     options "All still latest" / "There's something new". On the latter, ask
     which changed, then the full-form question for each changed one only.
4. Handle the answers:
   - **New or updated BA doc:** convert it into `docs/user-stories/<module>.md`
     exactly as `/plan` step 1a describes, then show the `git diff`
     summary.
   - **SOW given:** read it from the given path. It is confidential: never copy
     it, or quotes longer than a short phrase, into the repo. Record only its
     title, version and date in **Sources used**.
   - **No SOW:** record "SOW: not provided" and use the no-SOW scope tags.
   - **Client decisions:** read them in full, screenshots too. Copy every
     original unchanged into `<scratch>/db-shared/raw/` so the reviewer can
     check it. Decisions that settle scope go into the module plan's
     Decisions once the user confirms them.
   - "All still latest": record today as the confirmation date.
5. Never continue on a source the user hasn't confirmed, nor on a document you
   could not read in full.

## 1. Research

Follow [references/research.md](references/research.md): the scratchpad
layout (`<scratch>/db-shared/`, given to the reviewer; `<scratch>/db-research/`,
never given to it), the research agents and their brief, how to read each
source, and the report format. `<scratch>` is this session's scratchpad.

Research agents read their sources in full. You read their reports, and open
a source yourself only to verify a citation a decision rests on.

### Precedence

1. Confirmed client decisions and the Decisions sections of local plans
2. BA docs
3. SOW (when there is one)
4. Lovable: code comments, then code, then the prompt history
5. Existing local code (entities, FE types / mock stores)

- **Source 1 settles a point** against any other. A newer source that
  contradicts a decision becomes a question citing that decision.
- **Between sources 2, 3 and 4, always ask.** The order only picks the
  recommendation; never settle such a conflict silently.
- **Source 5 loses** to all the others. Where it differs, plan an additive
  change; a breaking one is a question.

### Struck-out SOW sections (only with a SOW)

Text struck out in the SOW is **not in the SOW scope**. If the feature still
appears elsewhere: the client asked for it (a decision, call notes, a client
prompt in Lovable) → tag its tables `Client-requested` with date and source;
only Lovable or a BA doc has it → tag `Pending scope` and raise a [Client]
question.

## 2. Design rules

Follow the BE `CLAUDE.md`, the notes' conventions and the existing entities.

**Shape**

- Tables and columns snake_case, plural table names; the project's id type
  and base entity (`created_at`, `updated_at`); a soft-delete base
  (`deleted_at`) for business records that are soft-deleted.
- Money and quantities are `numeric` (reuse the precision existing columns of
  the same kind use); never floats. Say whether an amount is per unit or a
  line total.
- Keep the timestamp type the existing entities use; changing an existing
  column's type is a [Tech] question. Business-day keys (schedule day, due
  date, pay period) are dates in the company time zone, never cut from a UTC
  instant.
- **Human-readable numbers** (`WO-#####`, `SO-#####`) come from a Postgres
  sequence or a counter, with a unique constraint; follow how existing
  modules number their documents.

**Enums and lookup tables**

- **Enum** when values are fixed by business rules and code branches on them
  (statuses, entry/movement types, visibility): stored as `varchar`, defined
  where the notes say; never a Postgres ENUM type.
- **No `CHECK` on enum columns.** Validation lives in the app (DTO), so that
  adding a value stays a code change with no migration.
- **Lookup table** when an admin can add, rename or retire values at runtime
  (categories, price levels, cancel reasons): an active flag instead of
  deletes, FKs point at it.

**Keys, constraints and FKs**

- FK columns use the project's id type with an explicit snake_case name;
  every FK column used to filter, join or check a delete is indexed.
- `ON DELETE` follows the notes: by default `NO ACTION`/`RESTRICT`; `CASCADE`
  only for children owned by a hard-deleted parent (pure junctions, lines,
  notes) with the reason written next to it; `SET NULL` for optional actor
  references where the notes allow.
- **Unique business keys on soft-deleted tables are partial:**
  `UNIQUE (...) WHERE deleted_at IS NULL`. Say so for every unique key on
  such a table.
- **Named business `CHECK` constraints** (`ck_<table>_<rule>`) for invariants
  that never change: amounts and quantities `>= 0` or `> 0`,
  `ended_at > started_at`, percentages 0–100, columns required together.
- Cross-table invariants a plain FK can't express (a unit on a work order
  belongs to that work order's customer; a transfer's two warehouses differ)
  are written down with how they are enforced: a composite FK, a check, a
  trigger or the service layer. A composite FK needs a `UNIQUE (id, …)` on
  the parent; write both next to each other.

**Behaviour**

- **Stored vs derived:** for every status, total and stock figure, decide
  whether it is stored (and what updates it, on every path) or computed on
  read. A status that follows other records names the rule and the trigger;
  a stored stock figure names its single writer and how it stays consistent
  with its ledger.
- **Snapshots:** prices, costs, rates, tax, fees, discounts and customer
  terms are copied onto documents and their lines when used, so later changes
  never rewrite issued documents.
- **Concurrency:** records several roles edit at once get a `version` column
  (optimistic locking) or a stated row lock. Confirm the approach once as a
  [Tech] question for the whole design.
- **Delete policy per table:** hard delete, soft delete, or never deleted
  (archive/deactivate/discontinue), with the source of the rule.
- **History:** a generic audit log for change history; a dedicated history
  table only where the business reads it (status history with a reason, rate
  or cost log). Say which.
- **Volume and retention** for tables that grow without bound (audit, time
  entries, movements, messages, files, sync logs, webhook events): an
  order-of-magnitude row estimate per year with its basis (from a source),
  how long rows are kept and why (legal retention for payroll and tax), and
  whether archiving is needed. With no basis, ask a [Client] question instead
  of guessing. Partitioning only if the estimate calls for it.

**Safety and scope**

- **Sensitive data:** never full card or bank numbers (last 4 plus the
  provider's token); public links use a random token, never a sequential id;
  password and PIN hashes only; integration secrets encrypted or kept out of
  API responses.
- **Indexes** for every filter, sort and search the BA docs or SOW list.
- **Scope tag on every table**, with its source:
  - With a SOW: `SOW` (the SOW text requires it; cite the page and check it
    really says so), `SOW (BA only)` (the SOW covers the module but only its
    BA doc asks for this table; cite the story), `Client-requested` (outside
    the SOW, asked by the client; date and source), `Pending scope` (only
    Lovable has it).
  - Without a SOW: `BA`, `Client-requested`, `Pending scope`.

  Keep client-requested and pending-scope tables in their own clusters, with
  no FK from the core into them, so they can be dropped.
- **Existing tables are additive by default:** renaming, retyping or dropping
  an implemented column is a question to the user first (the FE consumes
  these shapes).
- Don't port Lovable mechanics: localStorage persistence, seed backfills,
  name-matching auto-creation, read-time status "corrections". List what was
  left out under **Not ported from Lovable** (domain doc, or the plan section
  with `db_questions_in_be_plan`).

## 3. Questions

Questions are decisions only the user, the BA or the client can make. Number
them `DB-Q<nn>` (stable across runs, never reused) and tag each: **[Client]**
scope or business behaviour, **[BA]** a gap in a BA doc, **[Tech]** an
implementation choice the dev lead can decide. Each gives the context with
sources, 2–3 options, and **your recommendation and why**. Don't ask what a
source already answers; fold small points into assumptions.

**The local file is the record, not the chat.** Write every open question in
full where the "Where questions and decisions live" rule says. In chat, list
the open questions once in full, then end each later reply with only the ids
and a one-line summary of those still open.

## 4. Write the docs

Use [db-doc-template.md](db-doc-template.md).

- `docs/database/README.md` is the index; keep its schema-sync / migrations
  section accurate for the project.
- One `docs/database/<domain>.md` per domain (kebab-case, matching the module
  key where there is one, plus `iam`, `system`, `shared` as needed).
- Every table in the index has a **Status**: `Implemented (<migration name>)`
  with feature `migrations`, otherwise `Implemented (entity)`; `Designed`; or
  `Provisional` (`Provisional (DB-Qnn)` in the default question mode).
- Keep the template's section names exactly (**Status machines**,
  **Cross-domain links**, each table's delete policy, concurrency and volume
  lines, and **Design decisions** in the default mode): the reviewer looks
  them up by name.
- ERDs are Mermaid `erDiagram` blocks: one overall diagram in the index
  (tables and relationships only), one per domain with key columns.
- Cite the source of each business rule. Never paste SOW or BA text beyond a
  short phrase.
- Run the project's Prettier on the changed `docs/database/*.md` (the notes
  name the command). Never format `docs/user-stories/*`.

## 5. Independent review (mandatory before presenting)

Run the `alpha-db-design-reviewer` agent. It has no shell, and it must run on
a different model from this session: its definition pins `sonnet`, so when
this session runs on Sonnet, start it with the Agent tool's `model: "opus"`.
For a small scope, one reviewer in `domain` mode. For `all` or several
domains, run in parallel one reviewer per domain group (the research groups)
plus one in `cross-domain` mode for end-to-end flows.

Before starting them, check that `<scratch>/db-shared/transcript.md` exists
and `raw/` holds every client original a decision rests on. Pass each reviewer
**only**:

- the project name, the absolute path of `$ALPHA_HOME` (the agent has no
  shell to read it), and the absolute paths of the docs repo and the BE code
  root; it loads the profile and `notes/db-design.md` itself
- the mode and the domain files to review
- the run number, and from run 2 on the previous findings: each id with its
  label (`fixed`, `disputed`, or `became DB-Qnn`) and the path of the earlier
  review reports, so it re-checks every finding against its own original
  text. Never add your counter-arguments or how you fixed it.
- the path of `<scratch>/db-shared/`
- where the open questions live (the questions file, or the plan(s) holding
  the "DB design" section)
- the SOW path, or "no SOW"
- the source versions the user confirmed

Save every reviewer report verbatim to
`<scratch>/db-shared/reviews/R<run>-<group>.md` as soon as it returns. Never
pass the research folder, your reports, drafts or reasoning.

When it returns:

- Fix every finding you agree with.
- A finding you disagree with stays in front of the user: its id, the
  reviewer's point, and your counter-argument with sources. Never drop one
  silently.
- Findings of severity **Question** become `DB-Qnn` questions.
- If the fixes changed relationships, statuses or delete policies, run the
  reviewer again on the affected domains (and cross-domain, if a flow
  changed). **At most two re-runs.** After the second, list the findings still
  open for the user to decide.

Then summarise in chat: domains, table count by status, main design choices,
the reviewer's findings and what happened to each (fixed / disputed / became
a question), its impact map for the core tables, and the open questions.

## 6. Iterate

- On each answer: update the domain doc, record the answer as a decision (id,
  decision, date, "Decided by": `user`, `client` or `designer`) where the
  question mode says, remove it from the open questions, flip affected
  columns from Provisional to Designed, update the index, and (plan mode) add
  a changelog row, also one per run (initial design, fixes after each review).
- "You decide" on a [Tech] question: decide, record the reasoning with
  "Decided by: designer", and report it. The reviewer treats `user` and
  `client` rows as settled but may still challenge `designer` rows. On a
  [Client] or [BA] question, recommend but don't decide.
- Commit only when the user asks (branch `chore/db-design` or
  `docs/<domain>-db` from the base branch). Before a commit, check that no
  committed file under `docs/database/` holds question text, an open-question
  index or a link to a plan.

## 7. Hand-off and later runs

- Implementation follows the module's `.be.md` (`/plan`,
  `/implement`) and must match the domain doc. When the table lands, set
  its status to `Implemented (…)` and run the notes' drift check if any.
- **New module later:** run with the module name. Step 0 runs in its full
  form. Design the new domain, then check every existing domain for impact
  (new FKs, statuses, shared enums) and list those changes as additive or
  breaking.
- **Re-run after new docs:** compare the new sources with **Sources used**,
  list what changed, and update only the affected domains.
