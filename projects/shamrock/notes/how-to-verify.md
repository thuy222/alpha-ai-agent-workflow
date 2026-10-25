# Shamrock: verify addendum

## Research agent paths

| Agent  | Paths |
| ------ | ----- |
| ui     | `apps/web/src/routes/`, `src/pages/<Module>/`, components and stores they use, `src/layouts/MainLayout/navigation.ts`, `src/locales/en/*.json` (and `es`), the mock seed |
| api    | `apps/api/src/modules/<module>/` (controller, DTOs, service, entities), `src/constants/permissions.constant.ts`, the e2e test if any, `packages/api` types |
| lovable| `src/routes/<module>*.tsx` and imports from `src/data/*`, `src/lib/*`, `src/components/*` |
| db     | `docs/database/<domain>.md` and linked domains, the module's entities and migrations |

## Environment

- `pnpm run dev` → web :3333, API :5000 by default. Thuý's machine uses web
  :3000, API :5002 (5000 clashes with AirPlay): use the URL override in the
  credentials file.
- Set the test machine's time zone to **America/Chicago**: the screen shows
  times in the machine's zone, the server writes history and invoice lines in
  Chicago time.
- "View as" in the header only changes the UI; real permission checks need a
  real login.

## Test data

```bash
pnpm --filter api run seed:dev-user        # dev accounts (Admin, Technician)
pnpm --filter api run seed:demo -- --reset # demo customers "Demo —", technicians, WOs in every status
```

Seeded WO dates are relative to the seed day. WO and invoice numbers are not
stable (sequences move after e2e runs): find a WO by its **scope** text.

## Phase

Feature `mock_phase`: say per module whether it runs on mock zustand stores
(`src/stores/*Store.ts`) or the API (`src/apis/*`).
