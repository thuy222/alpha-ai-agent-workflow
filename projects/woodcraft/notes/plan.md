# Woodcraft: plan addendum

## Layout

Split repos: `woodcraft-tech-be` (NestJS + TypeORM + Postgres) and
`woodcraft-tech-fe` (React + Vite + TanStack Router + antd). **All docs of
both repos live in the BE repo** (`woodcraft-tech-be/docs/`), including the
FE plan `docs/plans/<module>.fe.md`. A BA doc brought in from the FE side is
still written to and committed in the BE repo.

## Lovable

The data model and rules live in `src/components/erp/*-data.ts`,
`*-store.ts` and the other `.ts` files there; screens are route files under
`src/routes/` and `src/components/erp/*.tsx`.

## BE plan specifics

- Entities in `src/database/entities/` (exported from `index.ts`), enums in
  `src/database/enums/index.ts`, modules and DTOs in `src/modules/<name>/`,
  permission codes in `PERMISSIONS` (`src/constants/permissions.constant.ts`,
  format `module.action`).
- **No migrations** before go-live: `dev` runs `synchronize: true`
  (see `CLAUDE.md`). Plans list entity changes only.
- Responses are wrapped in `{ statusCode, message, data, timestamp }`; lists
  return `{ items, total, page, limit }`, `limit` ≤ 100.
- Read the FE's `src/apis/<domain>.ts` (read-only): its types are an existing
  contract to stay compatible with; mirror the screen's sort keys and filters
  in `sortBy`/filters.
- Keep the BE plan's **DB design** section (written by `/db-design`) as
  it is when rewriting the plan.
- The BE plan is the contract the FE plan consumes; get it right.

## FE plan specifics

- Is there a `src/features/<module>/`, or is the screen still a monolithic
  `src/routes/_erp/*.tsx` with mock `src/components/erp/*-data.ts`? If so,
  plan the FE repo's own `refactor-erp-module` skill
  (`woodcraft-tech-fe/.claude/skills/refactor-erp-module/SKILL.md`) as the
  first step of US00, before any new behaviour.
- API wiring: `src/apis/<domain>.ts` + `src/hooks/use<Domain>.ts`; do their
  types match the BE plan's contract?
- Nav in `src/components/erp/AppShell.tsx`; route files under
  `src/routes/_erp/` (thin).
- Reuse `Ramsay*` wrappers (`src/components/`) and ERP primitives
  (`src/components/erp/`: `StatTile`, `TableColumns`, `TablePagination`,
  `ConfirmDialog`, `RecordLinks`, badges…). Shared components live in
  `src/components/erp/` or a `Ramsay*` wrapper.
- **Feature layout** for the plan:

  ```
  src/features/<module>/
    index.ts
    <Module>Page.tsx
    components/…
    hooks/…
    data/…
    types.ts  constants.ts
  src/apis/<domain>.ts  src/hooks/use<Domain>.ts
  src/routes/_erp/<module>….tsx   # thin
  ```

  Keep each file under ~300 lines.

## Tests

No automated tests for now: verification is manual (Swagger for the BE,
browser for the FE), and the FE plan's **Test scenarios** is the acceptance
script. Before the FE PR, run the Test scenarios and report each row's
PASS/FAIL.

## TODOs

Follow `CLAUDE.md` § TODO comments. While coding, write each story's Code
TODOs into the code; add a TODO for anything else deferred mid-way and list it
in the plan. When a story finishes work an existing TODO describes
(`git grep -n "TODO("` in both repos), delete that TODO in the same PR.
