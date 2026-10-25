# Woodcraft: db-design addendum

## Sources

A SOW is optional: "no SOW" is a valid answer; scope tags then use the no-SOW
set (`BA`, `Client-requested`, `Pending scope`).

## Questions

Feature `db_questions_in_be_plan`: decisions, not-ported list, open questions
and changelog live in the "DB design" section of `docs/plans/<module>.be.md`.

## Existing schema

Most of the schema already exists as entities: for an existing domain,
document what is there, check it against the sources, and design only the
additions.

## Conventions (follow `CLAUDE.md` § Module shape and the existing entities)

- Entities in `src/database/entities/<name>.entity.ts`, one per table;
  every column has an explicit snake_case `name`.
- `id` is a serial integer; `created_at`, `updated_at` from `BaseEntity`;
  `SoftDeleteBaseEntity` (`deleted_at`) for soft-deleted business records.
- Money and quantities `numeric` with `numericTransformer`; reuse existing
  precision (money on orders, quotes and products; percentages on price
  levels).
- Business instants `timestamptz`; business-day keys (count date, due date)
  are `date`.
- Enums: TS `enum` in `src/database/enums/index.ts`, validated by `@IsEnum`.
- FKs are integer columns; `onDelete` `RESTRICT`/`NO ACTION` by default,
  `CASCADE` for children owned by a hard-deleted parent (lines, notes,
  activity of one record), `SET NULL` for optional actor references
  (`created_by`).
- Named checks: `@Check('ck_<table>_<rule>', '"qty" >= 0')` on the entity.
- Stock on hand per warehouse names its single writer (the inventory movement
  ledger) and how it stays consistent with it.
- Concurrency: `version` column (`@VersionColumn`) or a row lock in the
  service, for orders, quotes, stock counts, product stock.
- History: activity / audit tables only where the business reads them (order
  activity, product audit log, cost history).
- Sensitive: Shopify tokens encrypted or kept out of API responses.

## Existing schema to read

`src/database/entities/*.entity.ts`, `src/database/enums/index.ts`,
`src/constants/permissions.constant.ts`, the services that write each table
(`src/modules/<module>/*.service.ts`), the current `docs/database/*.md`, and
the FE's `../woodcraft-tech-fe/src/apis/*.ts`.

## Lovable

Data model and rules in `src/components/erp/*-data.ts`, `*-store.ts` and the
other `.ts` files there; screens are route files under `src/routes/` and
`src/components/erp/*.tsx`.

## Research groups for `all`

customers and price levels; products (catalog, BOM, fitment, custom fields,
costs, relations); quotes, orders and command center; warehouses, inventory
and inventory counts (stock, movements, transfers, adjustments); shopify
sync; iam (users, roles, permissions, tokens).

## Cross-domain flows for the reviewer

- quote → order (conversion, price and customer-term snapshots) → payment and
  transactions → fulfilment → stock out of a warehouse → inventory movement →
  Shopify stock push
- Shopify paid order received → order created → stock reserved or moved,
  without double-counting against ERP-entered orders
- product with BOM → buildable quantity → build/unbuild → component and
  finished-good stock per warehouse
- stock transfer and adjustment → per-warehouse on hand → movement ledger →
  inventory count variance
- customer price level / type → line pricing on quotes and orders
- product discontinued / superseded → open quotes and orders, Shopify
  listing, search

## Docs and hand-off

- Index status `Implemented (entity)` when the entity exists on `dev`. The
  index has a **Schema sync** section: `synchronize: true` on `dev` until the
  go-live cutover, then migrations (`npm run migration:generate`).
- Format: `npx prettier --write` on the changed `docs/database/*.md`.
- Never commit; the user commits.
