# Research: how to read each source

Loaded by `SKILL.md` step 1. Research agents read their sources **in full**;
the main agent reads only their reports, and opens a source itself only to
verify a specific citation.

## Scratchpad layout

Two sibling folders in the scratchpad, so the reviewer's folder never
contains or points at the research:

```
<scratch>/db-shared/          given to the reviewer
  transcript.md               Lovable prompt history, merged mechanically (jq)
  raw/                        originals the user handed over, copied as-is:
                              screenshots, Slack exports, meeting notes
  notes/                      your reading of the sources, marked as such:
                              struck-out.md (only with a SOW), decisions.md
  reviews/                    each reviewer report, verbatim (R<run>-<group>.md)
<scratch>/db-research/        never given to the reviewer
  brief.md, <group>.md        research brief and agent reports
                              plus your drafts and reasoning
```

The reviewer has no shell, so `transcript.md` must exist before step 5, and
every client original a decision rests on must be in `raw/`: the reviewer
verifies `notes/` against `raw/` and the SOW, never the other way round.

## Research agents

Run independent groups in parallel with `general-purpose` agents (they need
the `lovable` MCP). Write one brief to `<scratch>/db-research/brief.md`
(project, absolute repo paths, scope, sources and their paths, whether there
is a SOW, the precedence rule from `SKILL.md`, the report format below) and
have each agent write `<scratch>/db-research/<group>.md`.

Suggested groups for `all`: the ones the project notes list; otherwise follow
`docs/user-stories/` and the BE modules folder.

## Sources

- **PDF** (SOW, BA): `Read` with `pages`, 20 pages per call, to the last
  page. Pages are rendered as images, so struck-out text stays visible. With
  a SOW, write every struck-out section (page and heading) to
  `<scratch>/db-shared/notes/struck-out.md`.
- **BA Markdown:** `docs/user-stories/<module>.md`, plus the modules it
  touches.
- **Lovable code:** `list_files` until `next_cursor` is null. For each module
  read its route/screen files to the end plus the data/lib files they import
  (the notes say where Lovable keeps its data model). Also read
  `drizzle/schema.ts` and `drizzle/migrations/*.sql` if present (a hint, not a
  design to copy), `roadmap.md`, `AGENTS.md` and `.lovable/plan/*.md`. Large
  results are saved to disk; read them in chunks and note the line range
  covered.
- **Lovable prompt history** (the designer's and the client's prompts):
  `list_messages` with `limit: 100`, paginating with `pagination.next_cursor`
  until `has_more` is false. Each raw page lands in a tool-result file; merge
  them into one chronological transcript with tool calls stripped:

  ```bash
  jq -rs '[.[].messages[]] | unique_by(.message_id) | sort_by(.created_at)[]
    | "\n===== \(.created_at) [\(.role)] =====\n"
      + (.content | tostring | gsub("<lov-[\\s\\S]*?</lov-[a-z-]+>"; ""))' \
    <tool-result files> > <scratch>/db-shared/transcript.md
  ```

  Later prompts override earlier ones. Prompts that only say "please do all
  attached change" have unreadable attachments: use the assistant reply that
  follows.

- **Client decisions:** Slack threads, meeting notes or screenshots the user
  gives in step 0. Copy the originals unchanged into
  `<scratch>/db-shared/raw/`, then summarise the decisions with their date
  and source in `<scratch>/db-shared/notes/decisions.md`.
- **Existing schema:** the entities, enums, permission constants and
  migrations at the paths the notes give, the services that write each table,
  and the current `docs/database/*.md`.
- **The FE's view of the data:** the FE API types (the shapes the screens
  consume), or the mock stores and seed types in a UI-first module.
- **In-flight work:** `git branch -a`, `git log --oneline -20` in every repo,
  and a grep of remote branches for the domain's entities before claiming a
  table doesn't exist.

## Report format (one per group)

Per module:

1. Purpose and roles, with what each role can see and do
2. Core flows, step by step
3. Entities with every field (type, required, meaning) and **all** enum
   values; derived values with their formula; which module owns each entity
4. Relationships with cardinality
5. Status machines (states, transitions, guards), calculations, constraints,
   defaults, permissions
6. Integrations and cross-module side effects
7. What the existing entities already have, and where they differ from the
   sources (missing, extra, different type or rule)
8. Conflicts between sources, and Lovable bugs not to port
9. Open questions

Every claim cites its source: `file:line`, BA section, SOW page, transcript
timestamp or decision id. The agent ends with a ten-line summary and the
report path.
