# rlm-backend-nest overview

Last verified: 2026-10-07 @ 278fe58 (kartik)

## What it is
NestJS port of the older node "utilities" / retailer-backend APIs for the RLM CRM: retailers (KYC, pipeline, VIP),
leads ownership, notes, calls, orders (read-only over Stockship's `orders_v2`), analytics dashboards, retailer app
features (farmers, inventory, profit calculator), and a `/portal` layer that moves browser Supabase access server-side.

## Stack
- NestJS 10, TypeScript; `@nestjs/mongoose` 10 + mongoose ^8.7 + native `mongodb` ~6.20 (RawDbService)
- nestjs-pino logging, @nestjs/throttler 6, @nestjs/schedule 4 (crons), class-validator ValidationPipe
- socket.io 4 (optional Redis adapter via `SOCKET_REDIS_URL`)
- firebase-admin 13 (Firestore, RTDB, Storage); Supabase over raw PostgREST with axios (no supabase-js)
- jwks-rsa + jsonwebtoken (SSO), OpenTelemetry NodeSDK (OTLP gRPC traces), Swagger
- Node >= 24, npm >= 11 (package.json `engines`)

## Bootstrap order (`src/main.ts`, order matters)
1. `process.env.TZ ||= 'Asia/Kolkata'`
2. `applyDnsOverride()` (`src/common/boot/dns.ts`): public resolvers for `mongodb+srv`; `DNS_SERVERS=system` disables; falls back to OS resolver
3. `import './tracing'` (`src/tracing.ts`) before any Nest/mongoose import; disabled when `OTEL_EXPORTER_OTLP_ENDPOINT` unset
4. `NestFactory.create(AppModule)` with `[boot]` progress lines while waiting for Mongo (`src/common/boot/boot-log.ts`)
5. Global prefix `api/v{major of API_DOCS_VERSION}` -> `/api/v2`; cookie-parser; `X-Response-Envelope: v1` header
6. Global ValidationPipe (`src/config/validation-pipe.ts`), AllExceptionsFilter, interceptors (serializer, pino, ResponseInterceptor)
7. CORS from `CORS_ORIGIN` (allowlist only in host `.env`); 15 MB body only for `PUT /api/v2/portal/drafts`
8. `SocketIoAdapter` (`src/config/socket-io.adapter.ts`); Swagger at `/api-doc`; SSO helper page at `GET /`
9. `app.listen(PORT ?? 4000, '0.0.0.0')`
Config: `src/config/configuration.ts` + `src/config/env.validation.ts`; env files `.env.local`, `.env`.

## Commands
| Task | Command |
|---|---|
| Install | `npm install --legacy-peer-deps` (what CI runs) |
| Dev (watch) | `npm run dev` |
| Build | `npm run build` (nest build -> `dist/`) |
| Prod start | `npm run start:prod` (single process) or `node cluster.js` (systemd, 2 workers) |
| Lint / types | `npm run lint` (eslint --fix), `npm run typecheck` |
| Unit tests | `npm test` (jest, 36 `*.spec.ts` under `src/`) |
| E2E tests | `npm run test:e2e` (`test/firebase-apis.e2e-spec.ts`, `test/portal-data.e2e-spec.ts`; fakes in `test/support/`) |
Local `.env` has no `SUPABASE_*`, so `/portal` routes answer 503 locally.

## Env var NAMES (values live only in host `.env`; never record them)
- Core: NODE_ENV, PORT, TZ, DNS_SERVERS, API_DOCS_VERSION (required), API_DOCS_TITLE, API_DOCS_DESCRIPTION
- Mongo: MONGODB_URI (required), MONGODB_DB_NAME
- Auth/SSO: SSO_BASE_URL (required), SSO_ID, SSO_SECRET, SSO_PLATFORM, KO_SALES_WEBHOOK_SECRET, PIPELINE_WEBHOOK_SECRET, NETCORE_SECRET_KEY, RETAILER_APP_USER_EMAIL
- Access: ACCESS_SCOPE_MODE, ACCESS_PUBLIC_WRITES, ACCESS_ADMIN_ROLES, ACCESS_DASHBOARD_ROLES, ACCESS_OPEN_RETAILER_ROLES, ACCESS_SERVICE_EMAILS
- HTTP: CORS_ORIGIN, RATE_LIMIT_WINDOW_MS, RATE_LIMIT_MAX
- Logging/OTel: LOG_LEVEL, LOG_PRETTY, LOG_EXPAND, SLOW_REQUEST_LOG_MS, RETAILER_LOG_RAW_BODY, OTEL_EXPORTER_OTLP_ENDPOINT, OTEL_EXPORTER_OTLP_HEADERS, OTEL_SERVICE_NAME
- Socket: SOCKET_ENABLED, SOCKET_PATH, SOCKET_CORS_ORIGIN, SOCKET_TRANSPORTS, SOCKET_PING_INTERVAL, SOCKET_PING_TIMEOUT, SOCKET_CONNECT_TIMEOUT, SOCKET_MAX_HTTP_BUFFER_SIZE, SOCKET_REDIS_URL, SOCKET_REDIS_KEY_PREFIX, SOCKET_NOTIFY_EVENTS
- Supabase: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, SUPABASE_SERVICE_KEY, MARKETING_SUPABASE_URL, MARKETING_SUPABASE_SERVICE_KEY, MARKETING_SUPABASE_KEY, VITE_MARKETING_SUPABASE_URL, VITE_MARKETING_SUPABASE_KEY, PORTAL_DATA
- CH sync / Stockship: CH_SYNC_SUPABASE_URL, CH_SYNC_SUPABASE_SERVICE_ROLE_KEY, STOCKSHIP_V3_BASE_URL, CRON_X_API_KEY, CH_SYNC_RETAILER_EVENTS_THRESHOLD_ROWS, CH_SYNC_RETAILER_EVENTS_COUNT_EVERY, EVENTS_DEFAULT_WINDOW_DAYS
- Firebase: FIREBASE_SERVICE_ACCOUNT_JSON, FIREBASE_SERVICE_ACCOUNT_PATH, FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY, FIREBASE_STORAGE_BUCKET, FIREBASE_DATABASE_URL, FIREBASE_RTDB_PROJECT_ID, FIREBASE_RTDB_CLIENT_EMAIL, FIREBASE_RTDB_PRIVATE_KEY, APP_USER_MIRROR, FILES_MAX_MB, KYC_SIGNED_URLS, KYC_SIGNED_URL_BUCKETS
- Pipeline/jobs: PIPELINE_EVIDENCE_MODE, PIPELINE_SWEEP_ENABLED, PIPELINE_SWEEP_CRON, PIPELINE_SWEEP_BATCH, PIPELINE_AR_MIN_DAYS, PIPELINE_LR_MIN_DAYS, PIPELINE_RECONCILE_CONCURRENCY, PIPELINE_RECONCILE_MAX, ORDER_INFO_CRON, ORDER_INFO_BATCH, ORDER_INFO_RECOMPUTE, ORDERS_LEGACY_FALLBACK_DISABLED, LEAD_V2_ENABLED, ADDRESS_PINCODE_CHECK
- Integrations: HRMS_BASE_URL, HRMS_SERVICE_KEY, SLACK_RLM_BOT_TOKEN, SLACK_RLM_CHANNEL_ID, SLACK_RLM_FO_CHANNEL_ID, KO_SALES_BACKEND_URL
- Netcore: NETCORE_RETAILER_API_KEY, NETCORE_API_KEY, NETCORE_API_KEY_2, NETCORE_ASSET_ID, NETCORE_ASSET_ID_2, NETCORE_BASE_URL, NETCORE_BASE_URL_2, NETCORE_ACCOUNT2_EVENTS, NETCORE_CONTACT_API_BASE_URL, NETCORE_CONTACT_API_KEY, NETCORE_CONTACT_CREATE_API_KEY, NETCORE_CONTACT_CREATE_URL, NETCORE_CONTACT_UPDATE_URL, NETCORE_RETAILER_APP_ID, NETCORE_SECRET
- In local `.env` but not found read by `src/` (UNVERIFIED): VITE_SHOW_APPROVAL_AUDIT, DEFAULT_ACCOUNT_MANAGER_ID

## CI / deploy (details and hosts: `AGENTS.md`)
- `.github/workflows/deploy.yml` "Deploy to Production": on push to `aws-deployed` (+ manual dispatch). AWS OIDC role,
  host IP from SSM, matrix role **`[fallback]` only** (spot host not deployed by CI). Steps: rsync (excludes `.env`,
  `node_modules`, `dist`) -> `npm install --legacy-peer-deps` -> `npm run build` -> `systemctl restart rlm-backend`
  -> poll `localhost:4000/api/v2/health`. **No lint or test step.**
- `deploy/rlm-backend.service`: systemd, `EnvironmentFile=.env`, `ExecStart=/usr/bin/node cluster.js`. Caddy fronts :4000.
- `Dockerfile`: node:24-alpine, runs `node dist/main.js` (no cluster), `EXPOSE 4003` (mismatch vs PORT 4000). Not used by CI.
- Older Render deployment references exist (boot-index comments; ADMIN leaderboard client host). Current status UNVERIFIED.

## scripts/
- `scripts/db/`: DB-01..DB-45 data-quality and index tasks (+ `_common.mjs`, `_indexes.mjs`, `run-all-dry.mjs`). Dry-run by default. See `database.md`.
- `scripts/perf/`: index-usage, note-id-index, phone-number-rev, postcode-field (same dry/apply rules).
- `scripts/seed-{fo,ro,ar,lr}-pipeline-workflow.ts`: upsert `pipelines_workflow` (npx ts-node; needs a write-capable URI).
- `scripts/firebase/smoke-readonly.ts`, `scripts/supabase/` (census, portal smoke, SQL packs per project).
- `scripts/parity/` (utils vs nest), `scripts/security/` (token-check, swagger-check, portal-modules-di-check).
