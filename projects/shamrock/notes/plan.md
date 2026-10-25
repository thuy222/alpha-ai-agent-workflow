# Shamrock: plan addendum

## Layout

Monorepo: `apps/api` (NestJS + TypeORM + Postgres), `apps/web` (React +
Vite + TanStack Router + antd + Tailwind), `packages/api` (`@repo/api`, the
HTTP contract types both apps use: check it for contract types). Conventions
in `apps/api/CLAUDE.md` and `apps/web/CLAUDE.md`.

## BA docs

The BA usually provides Markdown, pasted as-is into
`docs/user-stories/<module>.md`. A PDF or link is rewritten into that file
following `docs/user-stories/README.md`. The team may keep a **Pending client
confirmation** section at the end of a BA file: treat its items as open
questions, not BA rules, and re-add what is still open after each wholesale
replacement.

## Docs to read besides the BA doc

`docs/api/` (authentication, RBAC, PIN step-up), `docs/web/`,
`docs/database/` where relevant, and `docs/engineering/monorepo.md` when the
plan touches `packages/*`.

## Lovable

A module is `src/routes/<module>*.tsx` plus its imports from `src/data/*`,
`src/lib/*` and `src/components/*`.

## Codebase checks

- **BE (`apps/api`)**: entities, modules, permissions, migrations and e2e
  tests that already exist for the domain.
- **FE (`apps/web`)**: is the route in `src/layouts/MainLayout/navigation.ts`?
  Existing page (`src/pages/<Module>`), zustand store, mock type, i18n entry?
  Which reusable components in `src/components` fit, and which exist only
  inline in another page and should be extracted (e.g. a date navigator inside
  `pages/Dashboard`)?
- **UI mapping**: read `docs/web/lovable-ui-mapping.md`. For each Lovable
  element in the UI spec it names the local component and variant that
  reproduces it. An element with no mapping, or whose mapped variant doesn't
  exist yet, is a US00 task (build the variant once, then every screen reuses
  it) and a new row in that doc.

## Phase

The project is UI-first: many modules are FE-only on mock zustand stores and
the backend follows. For scope `fe`, plan the mock store and seed data shaped
like the future API, with no backend tasks, plus a short "Backend notes for
the later `.be.md`" section. Ask which phase a module is in if unstated.

## Verification in plans

- FE: Vitest `*.test.ts` for the story's pure logic (`pnpm --filter web
  test`), plus browser checks including the side-by-side UI spec check.
- BE: e2e cases per story (`pnpm --filter api run test:e2e`), plus Swagger
  checks.

## Coding (when the user says go)

Start with US00, then story by story in the order the user picks. Tick the
story's acceptance checklist, `UI-L` rows included, as the work lands; a story
is done only when every row is ticked or has a Decision.
