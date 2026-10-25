# Shamrock: db-design addendum

## Sources

The project **always has a SOW**: with no record, ask for its path; "no SOW"
is not an accepted answer. Scope tags use the SOW set.

## Questions

Default mode: open `DB-Qnn` questions in `docs/plans/database.md`
(git-ignored); answered ones become **Design decisions** rows in the domain
doc. Pass `docs/plans/database.md` to the reviewer.

## Conventions (follow `apps/api/CLAUDE.md` and the existing entities)

- `id uuid` (v7, set app-side by `AbstractEntity`), `created_at`,
  `updated_at`; `SoftDeleteAbstractEntity` (`deleted_at`) for business
  records.
- Money `numeric(12,2)`, rates/percentages `numeric(5,2)` (or what existing
  columns use).
- Enums: `as const` objects in `apps/api/src/constants/database-enums.ts`,
  validated by DTO `EnumField` plus the union type.
- Lookup tables get `is_active`.
- FKs are `uuid` with `ON DELETE NO ACTION`, every FK column indexed.
  Exception: a pure junction table (only the two FKs plus assignment
  metadata) may `CASCADE` towards a hard-deleted parent; write the reason.
- Composite FK such as `(unit_id, customer_id) → units (id, customer_id)` is
  the one allowed exception to single-uuid FKs; it needs
  `UNIQUE (id, customer_id)` on the parent.
- Concurrency: `version` column (TypeORM `@VersionColumn`) on work orders,
  invoices, time entries under approval, customer billing settings.
- History: `audit_logs` for generic history.
- Sensitive data: password and PIN hashes only.

## Existing schema to read

`apps/api/src/modules/**/*.entity.ts`, `apps/api/src/database/migrations/`,
`apps/api/src/constants/database-enums.ts`, `permissions.constant.ts`, the
current `docs/database/*.md`, and for the FE view the `apps/web` mock stores
and seed types.

## Lovable

Module = `src/routes/<module>*.tsx` plus imports from `src/data/*`,
`src/lib/*`, `src/components/*`.

## Research groups for `all`

work orders; dispatch/schedule/dashboard; customers/equipment; parts/purchase
orders; time & attendance; invoices/AR/accounting;
portal/users/settings/messages/reports.

## Cross-domain flows for the reviewer

- work order → time entries → billing lines → invoice → payment → AR aging →
  QuickBooks sync, and the work order's status along the way
- customer status (credit hold, inactive, deleted) → new work orders,
  scheduling, portal access
- technician (user) deactivated → open assignments, time entries, payroll
- a unit transferred to another customer → its open and past work orders,
  portal visibility

## Docs and hand-off

- Index status `Implemented (<migration name>)`. Keep the index's
  **Migrations** section accurate (baseline, `synchronize` off,
  `migration:generate`, `db:drift`, `db:reset`).
- Format: `pnpm exec prettier --write <changed docs>`.
- When a migration lands, set the status and run
  `pnpm --filter api run db:drift`.
- Entity notes: a partial unique key is
  `@Index(['number'], { unique: true, where: '"deleted_at" IS NULL' })`; an
  upsert's `ON CONFLICT` only matches it when it repeats the same `WHERE`. A
  composite FK needs the parent's `UNIQUE (id, customer_id)` in the same
  migration, created before the FK.
