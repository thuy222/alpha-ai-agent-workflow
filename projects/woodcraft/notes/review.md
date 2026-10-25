# Woodcraft: review addendum

Docs of both repos live in `woodcraft-tech-be/docs/`. Each side is reviewed
in its own repo; read the other repo only to check the contract.

## BE (`woodcraft-tech-be`)

- `@RequirePermissions` on every route; codes in `PERMISSIONS`
  (`src/constants/permissions.constant.ts`).
- Money as numeric with `numericTransformer`; `whitelist` DTOs declaring
  every accepted field; `PartialType` update DTOs; list DTO shape.
- Entities in `src/database/entities/` exported from `index.ts`, explicit
  snake_case column names, varchar enums in `src/database/enums/`.
- **No migrations pre-launch** (`synchronize: true` on dev).
- Contract: compare with `../woodcraft-tech-fe/src/apis/<domain>.ts`.
- `npm run lint` runs `eslint --fix`: never run it; use the profile command.

## FE (`woodcraft-tech-fe`)

- `src/features/<module>/` shape; imports only through the feature barrel;
  thin route files under `src/routes/_erp/`.
- `Ramsay*` wrappers over raw antd; design tokens instead of raw hex; ERP
  primitives in `src/components/erp/`.
- Pure logic in `data/` / `hooks/`, not in JSX; files under ~300 lines; no
  `any`; no index keys; hooks above early returns; no dead code.
- No Lovable localStorage / mock persistence as the data layer.
- Contract: compare `src/apis/<domain>.ts` with the BE plan and
  `../woodcraft-tech-be/src/modules/<name>/` DTOs and controllers.
- Never run `npm run lint:fix` or `npm run dev` (it regenerates files).
