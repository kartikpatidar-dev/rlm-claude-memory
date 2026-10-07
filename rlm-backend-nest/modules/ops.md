# ops

## Purpose
Operational and integration endpoints: health check, in-memory request log viewer, Mongo index admin, internal bug
tracker with realtime socket, and the Netcore (Smartech) integration. Nest modules: health, logs, db-indexes, bug-reports, netcore.

## Entry points (all `/api/v2`)
- `health`: GET `/` (`@Public()`, `@SkipThrottle()`; status, uptime, Mongo readyState) — CI polls it after deploy
- `logs` (class AdminOnlyGuard): GET `/` (JSON filters), GET `view` (HTML, auto-refresh 5 s)
- `db/indexes` (class `@Public()` + MaintenanceGuard + `@NeverOpen()`): GET `/?collection=`, POST `/` (build; `dry_run`)
- `bug-reports` (SSO only): POST `/`, GET `/`, GET/PATCH/DELETE `:id`, POST/GET `:id/messages`
- Socket `/bug-reports`: auto-join `all`; client `subscribe`/`unsubscribe` any room (`agent:<id>`, `priority:<p>`, `bug:<id>`);
  emits `bug:created|updated|deleted`, `bug:message:created`; **no handshake auth**
- `netcore` (class `@AllowWebhook`): POST `trigger-event`, `profile-update`, `account-manager-assigned`,
  `contact/set-attributes`, `contact/create`

## Key files
`src/modules/health/`, `src/modules/logs/` + `src/common/logging/{log-buffer.service.ts, request-log.interceptor.ts}`,
`src/modules/db-indexes/db-indexes.service.ts`, `src/modules/bug-reports/{bug-reports.service.ts, bug-reports.gateway.ts, schemas/}`,
`src/modules/netcore/netcore.service.ts (~1.3k lines)`

## Data
- bug-reports R/W `bug_reports_v2`, `bug_messages_v2`, `app_counters` (`BR-` ids); R `agents_v2`
- netcore R `piis`, `agents_v2`, `leads_v2`, `retailers_v2` (read-only)
- db-indexes: any collection (incl. legacy `retailers`, `skp_owners`, `app_counters`); health/logs: none

## Depends on
auth (JwksService, MaintenanceGuard), common raw-db, logging; netcore: Pii + Agent schemas, ConfigModule.

## Used by
- Modules: NetcoreService -> lead-assignment (fo, foro), verification-kyc (VerificationService), retailers-core (indirect).
- PORTAL: `/health` (`redux_v2/apis/health_api.service.ts`), `/bug-reports*` (`bug_reports_api.service.ts`) + socket
  (`src/hooks/useBugReportsSocket.ts`), `/netcore/trigger-event` (`netcore_api.service.ts`).
- ADMIN: `/netcore/trigger-event` (`src/redux/netcore.api.ts`).
- logs, db-indexes: no consumer found in RVP/portal/admin repos — ops tooling / browser by admins UNVERIFIED.

## External services
Netcore APIs (activity upload, v5 contact create/update; two accounts, `NETCORE_ACCOUNT2_EVENTS` routed to B; 3 retries).
Env names: `NETCORE_*` (see overview.md). Supabase: bug attachment URLs must be on `SUPABASE_URL` host (client uploads).

## Gotchas
- **bug-reports PATCH/DELETE are not owner-checked** (any SSO user); DELETE is hard and cascades messages. Admin = USR-1000 only.
- **`/bug-reports` socket is unauthenticated**; anyone can join any room.
- db-indexes has no collection allow-list: TTL/unique indexes can delete data or block writes.
- Log buffer is per worker, non-persistent; logged URLs contain PII (hence admin-only). Slow-request tail = last 50.
- Netcore responses are byte-identical to legacy node (body has its own `success` key; envelope passes through).
  Bearer falls back to the secret key when no API key is configured.

Last verified: 2026-10-07 @ 278fe58 (kartik)
