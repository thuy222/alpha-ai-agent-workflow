# Shamrock: review addendum

## FE (`apps/web`, conventions in `apps/web/CLAUDE.md`)

- Import aliases: no `@/components`, `@/utils`, `@/pages`.
- File layout: `pages/<Module>`, pure logic in `.ts` next to the screen.
- i18n: English sentence as key, every key in both `en` and `es`, plurals
  `_one/_other`.
- dayjs with local `format('YYYY-MM-DD')`; no `window.confirm/alert`.
- Mock-first zustand stores with API-shaped actions.
- Shared components in `src/components` (Modal, DatePicker, Select,
  SegmentedSwitch, StatCard, StatusBadge, PageHeader, FilterBar, Calendar,
  WorkOrder/*…). Screen-specific pieces that Dispatch, Dashboard or Jobs will
  need move there.
- UI mapping doc: `docs/web/lovable-ui-mapping.md`.
- Logic pitfalls: date math (local day keys, week starts Monday, month grid
  spill-over, midnight), multi-technician jobs, cancelled jobs, combined
  filters.

## BE (`apps/api`, conventions in `apps/api/CLAUDE.md`)

- Enums in `src/constants/database-enums.ts` (`as const`), DTO `EnumField`.
- Permissions in `permissions.constant.ts`; migrations for every schema
  change; e2e tests per endpoint.

## Contract

Shared types in `packages/api` (`@repo/api`) must match both apps.
