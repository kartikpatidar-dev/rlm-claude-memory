# auth-access

## Purpose
SSO authentication (JWKS-verified JWT), webhook/maintenance secrets, and role/scope authorization used by every route.
Covers `src/modules/auth`, `src/common/access`, `src/common/guards`.

## Entry points
- `POST /api/v2/auth/sso-login`: `@Public()`; email+password -> SSO `/login` + `/generate-tokens` (`SSO_PLATFORM`, default `rlm-backend`); empty body blocked (else server creds would be used)
- `GET /api/v2/auth/me`: SSO; claims enriched from `agents_v2` (agent_id, katyayani_id, role, team, manager, phone)
- `GET /api/v2/auth/debug-token`: `@Public()`; decodes bearer WITHOUT verifying (diagnostic)
- `GET /` (outside prefix, `main.ts`): HTML SSO sign-in helper that stores tokens for Swagger
- Global guards (APP_GUARD in `app.module.ts`): `ThrottlerGuard`, then `SsoAuthGuard`

## Key files
- `src/modules/auth/`: `guards/sso-auth.guard.ts`, `guards/optional-sso-auth.guard.ts`, `services/jwks.service.ts`,
  `decorators/{public,current-user,allow-webhook}.decorator.ts`, `auth.service.ts`, `auth.controller.ts`
- `src/common/access/`: `access.service.ts` (caller -> agents_v2, roles, covered agents), `scoped.guard.ts` (`@ScopedBy`),
  `admin-only.guard.ts`, `maintenance.guard.ts`, `public-write.guard.ts`, `retailer-access.service.ts`, `access.module.ts`
- `src/common/guards/`: `webhook-secret.guard.ts` (`PIPELINE_WEBHOOK_SECRET`), `sso-or-webhook-secret.guard.ts`
- Related: `src/modules/retailer-scope/` (RetailerScopeGuard, see retailers-core), `portal-data/portal-data.guard.ts` (see portal-supabase)

## Data
- R `agents_v2` (identity, `user_role`, `agent_manager` hierarchy, `is_active`)
- `RetailerAccessService` / `AccessService` R: `retailers_v2`, `piis`, `retailevents`, `retailer_pipeline_cycles`,
  `orders_v2`, `notes_v2`, `calls_v2`, `carts_requests` (per-entity ownership checks)

## Depends on
SSO service (JWKS), ConfigModule, RawDbService, LeadOwnershipService (ownership derived from `leads_v2`).

## Used by
Every module (global guards; `ScopedGuard`/`AdminOnlyGuard` in ~38 modules). Auth module exports `JwksService`,
`SsoAuthGuard`, `OptionalSsoAuthGuard` (agents, calls, db-indexes, notifications, retailers, retailer, retailer-events).
Frontends: PORTAL `src/redux_v2/apis/auth_api.service.ts` (`/auth/sso-login`, `/auth/me`, `/auth/debug-token`).
RVP and ADMIN log in to SSO directly (not via nest).

## External services
SSO (`SSO_BASE_URL`: `/login`, `/generate-tokens`, `/.well-known/jwks.json`). Env: `SSO_BASE_URL`, `SSO_ID`, `SSO_SECRET`,
`SSO_PLATFORM`, `KO_SALES_WEBHOOK_SECRET`, `PIPELINE_WEBHOOK_SECRET`, `NETCORE_SECRET_KEY`, `ACCESS_*`, `RETAILER_APP_USER_EMAIL`.

## Gotchas
- Roles: admin USR-1000/1001/1002, dashboard/read-all USR-1021/1003/1019, open-any-retailer USR-1020/1030/1012, FO USR-1029,
  RO USR-1022 (env overrides `ACCESS_*_ROLES`). Others see self + transitive reports via `agent_manager`.
- `ACCESS_SCOPE_MODE` default **warn** (logs, allows). `ACCESS_PUBLIC_WRITES` open|warn|closed for public create routes.
- `ScopedGuard` with no named target allows only admin/dashboard roles; not checked for webhook-secret calls without login.
- `@OpenToAll()` exempts from AdminOnly/Scoped. `MaintenanceGuard` is always paired with `@Public()` + `@NeverOpen()`.
- **Hard-coded fallback webhook secret** constant in `sso-auth.guard.ts` when `KO_SALES_WEBHOOK_SECRET` is unset;
  compare is not constant-time. Never copy the value.
- JWKS verify has no iss/aud check: any RS256 token from the SSO with an `email` passes. Token also read from cookie `token`.
- retailer-alerts and bug-reports use their own admin role lists (not AccessService).

Last verified: 2026-10-07 @ 278fe58 (kartik)
