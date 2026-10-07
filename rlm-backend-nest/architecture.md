# rlm-backend-nest architecture

Last verified: 2026-10-07 @ 278fe58 (kartik)

## Layers
`src/main.ts` bootstrap -> `src/app.module.ts` (global config, logger, throttler, schedule, global guards, common
modules, ~51 feature modules) -> `src/modules/<feature>/` (controller -> service -> Mongoose model or RawDbService)
-> `src/common/*` shared services. One Mongo connection (`src/database/database.module.ts`).

## Request pipeline
1. Middleware: cookie-parser, `X-Response-Envelope: v1` header, drafts body parser (15 MB only for portal drafts)
2. `ThrottlerGuard` (global; one in-memory bucket per worker, `RATE_LIMIT_*`)
3. `SsoAuthGuard` (global, `src/modules/auth/guards/sso-auth.guard.ts`): skipped by `@Public()`; `@AllowWebhook()` also accepts `x-webhook-secret`
4. Route guards from `src/common/access` / `src/common/guards`: `ScopedGuard` + `@ScopedBy`, `AdminOnlyGuard`,
   `MaintenanceGuard` (+`@NeverOpen`, `@CalledFromOutside`), `PublicWriteGuard`, `SsoOrWebhookSecretGuard`,
   `WebhookSecretGuard`, `RetailerScopeGuard` (`src/modules/retailer-scope`), `PortalDataGuard` (portal-*)
5. Global `ValidationPipe` (`src/config/validation-pipe.ts`)
6. Controller -> service -> Mongoose model or `RawDbService` (`src/common/raw-db`) / Supabase / Firebase
7. `ResponseInterceptor` (`src/common/interceptors`) wraps output in the envelope (`docs/response-envelope.md`);
   `RequestLogInterceptor` (logs module) records to an in-memory ring buffer and `[slow]` lines
8. Errors: `AppError` hierarchy (`src/common/errors`) -> `AllExceptionsFilter` (`src/common/filters`) maps HTTP and Mongo errors to the envelope

## Auth model
- SSO JWT: `JwksService` fetches `${SSO_BASE_URL}/.well-known/jwks.json`, RS256 only, `email` claim required.
  No issuer/audience check. Token from `Authorization: Bearer` or cookie `token`.
- `@Public()` skips SSO. `@AllowWebhook()` accepts `KO_SALES_WEBHOOK_SECRET` (server-to-server from ko-sales);
  sets `req.user = {email:'ko-sales-webhook', webhook:true}`. The guard has a hard-coded fallback secret when the
  env var is unset (see status.md risks; never copy the value).
- `WebhookSecretGuard` (`PIPELINE_WEBHOOK_SECRET`, constant-time, fail-closed); `SsoOrWebhookSecretGuard` (SSO or
  `NETCORE_SECRET_KEY`/`PIPELINE_WEBHOOK_SECRET`); `MaintenanceGuard` (admin token or maintenance secret).
- Authorization (`src/common/access`, global AccessModule): caller email -> `agents_v2` row (`user_role`,
  `agent_manager` hierarchy, `is_active`). Role codes `USR-xxxx`: admin USR-1000/1001/1002 (`ACCESS_ADMIN_ROLES`),
  dashboard/read-all USR-1021/1003/1019 (`ACCESS_DASHBOARD_ROLES`), open-any-retailer USR-1020/1030/1012
  (`ACCESS_OPEN_RETAILER_ROLES`); everyone else sees self + transitive reports. FO = USR-1029, RO = USR-1022.
- `ACCESS_SCOPE_MODE` = off | **warn (default: logs and allows)** | enforce. `ACCESS_PUBLIC_WRITES` = open|warn|closed.
  `ACCESS_SERVICE_EMAILS` = program logins (retailer app). `RetailerAccessService` checks per-entity ownership.
- Some modules use their own admin list (retailer-alerts: token `user_role` USR-1000/1001/1002; bug-reports: USR-1000 only).

## Sockets (`src/config/socket-io.adapter.ts`, handshake token in `auth.token`)
| Namespace | Gateway | Auth | Consumers |
|---|---|---|---|
| `/notifications` | `modules/notifications/notifications.gateway.ts` | SSO verified | RVP + PORTAL `hooks/useEventNotificationSocket.ts` |
| `/bug-reports` | `modules/bug-reports/bug-reports.gateway.ts` | **none** | PORTAL `hooks/useBugReportsSocket.ts` |
| `/calls` | `modules/calls/calls.gateway.ts` | SSO verified | none found (designed to replace browser RTDB listeners) |
| `/reconcile` | `modules/retailers/reconcile.gateway.ts` | **none** (auto-join, progress only) | none found (ops) |
| `/lead-assignment` | `modules/lead-assignment/lead-assignment.gateway.ts` | **none** | none found (ops) |
Without `SOCKET_REDIS_URL` emits only reach sockets on the same worker.

## Crons and timers (`@nestjs/schedule`, Asia/Kolkata)
- `retailers/pipeline-scheduler.service.ts`: `PIPELINE_SWEEP_CRON` (default `0 2 * * *`); no-op unless `PIPELINE_SWEEP_ENABLED=true` (normally an external cron calls `POST /retailers/pipeline/sweep-inactive`). Cross-worker lock: UNVERIFIED.
- `retailers/order-info-recompute.service.ts`: `ORDER_INFO_CRON` (default `30 2 * * *`), `ORDER_INFO_RECOMPUTE` off|dry-run|on; lock doc in `job_locks` (2 h).
- `@Interval` keep-warm: `common/lqs-score`, `common/address-values`.
- "Cron" routes in lead-assignment are HTTP, called by an external scheduler (UNVERIFIED which).

## Process model
`cluster.js` forks `min(cpus, 2)` workers per host; prod = 2 EC2 hosts (spot + fallback, see AGENTS.md). Per worker:
throttler counters, caches, log ring buffer, socket rooms, `@Cron` jobs (run in every worker on every host), Mongo pool
of 20 (so up to 40 per host). The rps sync `syncing` flag is in-process only.

## Caching (in-memory, per worker)
`common/utils/recent.ts` (TTL by key), `in-flight.ts` (dedupe concurrent identical lookups), `gate.ts` (concurrency
limiter). Used by access (agent org map), lqs-score (~60 s snapshot), lead-ownership, order-status, address-values,
orders-v2, phone-search, rps-dashboard (20 s), district-wise (5 min), sales-potential (10 min), product-category,
pincode check (6 h), retailer-events, portal-onboarding/drafts, HRMS identity (10 min).

## Fail-soft secondary writes
The Mongo write is the source of truth; follow-on effects are best-effort and never roll it back: Firestore app-user
mirror, contact profile, Netcore events, Slack posts, socket notifications, CH-sync staging, legacy `retailers` mirror,
farmer aggregates. There are no Mongo transactions anywhere.

## Key decisions and WHY (from code comments)
- Boot index builds in `onModuleInit` are fire-and-forget (skipped in development): awaiting them delayed
  `app.listen()` and Render failed the deploy with "No open ports detected".
- `POST /orders` returns 410: `orders_v2` is written by Stockship; nest only reads and maps to the legacy shape.
- Lead owner and kyc_agent are not stored on `retailers_v2`; they are derived from `leads_v2` at read time
  (`common/lead-ownership`). `role` lives only on `leads_v2`.
- `retailer_pipelines` is the history source of truth; `retailers_v2.pipeline_info` is a mirror.
- `PIPELINE_EVIDENCE_MODE` defaults to warn because ~79% of `calls_v2` rows lack a usable `pii_id`.
- Phone search uses `phone_number_rev` because a phone regex "took the API down on 02 Sep"; heavy reads gated (12 of 20 pool connections).
- Explicit `dbName` in DatabaseModule fixes the old `//CRM-Database` namespace bug.
- OTel config is read from `.env` directly because systemd mis-parses the multi-line `FIREBASE_PRIVATE_KEY` (2026-09-17 RCA).
- `/portal/*` modules exist so browsers stop holding Supabase keys; identity comes from the token, not the body.
- Mongoose `populate()` is avoided; joins use `$lookup` or follow-up finds (project README).

## src/common/* map
- `access`: caller identity/scope, ScopedGuard, AdminOnly, Maintenance, PublicWrite, RetailerAccessService
- `address-values`: cached distinct place values from `addresses`
- `boot`: boot log, DNS override, drafts body parser
- `dto`: ApiResponse DTO for Swagger
- `errors`: AppError hierarchy
- `filters`: AllExceptionsFilter
- `firebase`: FirebaseService (Firestore, RTDB, Storage, app-user mirror), storage-url, app-user shape
- `guards`: webhook-secret, sso-or-webhook-secret
- `interceptors`: response envelope + header
- `lead-ownership`: owner / kyc agent from `leads_v2`
- `logging`: LogBuffer, RequestLogInterceptor, slow-request log
- `lqs-score`: LQS snapshot from `leads_v2` (the "RPS" score)
- `order-status`: `status` master catalogue
- `orders-v2`: `orders_v2` source / compat / legacy fallback (`ORDERS_LEGACY_FALLBACK_DISABLED`)
- `phone-search`: pii ids by phone term
- `raw-db`: RawDbService (schema-less collection access, counters)
- `search`: retailer regex search util
- `supabase`: SupabaseRestService (PostgREST + Storage) and filter builder
- `utils`: document-entry, email, gate, identity-number, in-flight, recent, sanitize-output
