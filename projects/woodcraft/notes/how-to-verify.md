# Woodcraft: verify addendum

The guide lives in `woodcraft-tech-be/docs/plans/<module>.verify.md` and
covers the SPA in `woodcraft-tech-fe` running on this API end to end. There
are no automated tests: the guide is the acceptance check.

Older guides use `VER-<module>-<nn>` ids and a Results table per scenario.
When rewriting one, move to the standard chapter format and add an **Id
changes** table (old → new) that carries the filled-in results over.

## Research agent paths

| Agent  | Paths |
| ------ | ----- |
| ui     | `woodcraft-tech-fe`: `src/routes/_erp/<module>*.tsx`, `src/features/<module>/`, `src/hooks/use<Domain>.ts`, `src/apis/<domain>.ts`, the sidebar in `src/components/erp/AppShell.tsx` (`navSections`). ERP screens hardcode their labels (no i18n). |
| api    | `woodcraft-tech-be`: `src/modules/<module>/` (controller, DTOs, services), the entities it writes, `src/constants/permissions.constant.ts` |
| lovable| The module's route/component files and the `src/components/erp/*-data.ts` / `*-store.ts` they import |
| db     | `docs/database/<domain>.md` if written, otherwise `src/database/entities/` |

## Environment

- FE `npm run dev` in `woodcraft-tech-fe` (port `VITE_PORT` from its `.env`,
  default 3000); API `npm run start:dev` in `woodcraft-tech-be` (`PORT` from
  `.env`), prefix `/api/v1`, Swagger at `/api/docs`.
- Screens not yet wired to the API still run on Lovable mock data
  (`src/components/erp/*-data.ts`): say per screen which you found, and skip
  API/SQL checks on them.
- Behind-the-UI checks can also use Swagger (e.g. to try a value the UI
  blocks).

## Accounts

The first admin comes from `SEED_ADMIN_EMAIL` / `SEED_ADMIN_PASSWORD`; other
roles are created by hand. Ask the user for the accounts per role.
