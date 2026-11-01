# shamrock: implement notes

## Live API check (step 4.2)

- Start: `cd apps/api && PORT=5099 npx nest start` in the background. The
  usual dev API (`:5000`, `:5002` on some machines) may be an older
  `dist/main`; leave it alone.
- Files (`/customers/:id/files`, `/work-orders/:id/files`, `/units/:id/files`)
  need S3. Local `.env` often holds placeholder AWS keys, so uploads fail
  with 500 "The AWS Access Key Id you provided does not exist". Start MinIO
  (`docker compose up -d minio minio-init`, bucket `shamrock-local`) and add
  on the start command, without touching `.env`:
  `AWS_S3_ENDPOINT=http://localhost:9000 AWS_REGION=us-east-1 AWS_ACCESS_KEY_ID=minioadmin AWS_SECRET_ACCESS_KEY=minioadmin AWS_S3_BUCKET=shamrock-local`
- Accounts in the credentials file: Admin and Technician (from
  `pnpm --filter api run seed:dev-user`, which resets their passwords). There
  is no Office or Manager login: their permissions are covered by the e2e
  access matrix (`permissionsOf(ROLES.X)` in `test/helpers.ts`).
- New customers: `POST /customers` needs `companyName`, `primaryContact`
  (`name`, `role`, `phone`, `email`), `billingAddress` and `taxStatus`.
- Related APIs worth re-reading: `GET /customers/:id` (`activity`:
  `unitsOnFile`, open work orders), `GET /work-orders/:numberOrId` (customer,
  unit), `GET /work-orders/:id/files`, `GET /parts/:id`.
- Records created by the script stay in the local DB; units are never
  deleted through the API. `pnpm --filter api run seed:demo -- --reset`
  rebuilds only the demo data.
