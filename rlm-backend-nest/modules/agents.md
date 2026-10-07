# agents

## Purpose
Staff directory and CRUD on `agents_v2`, owner-by-phone lookup, per-agent and team performance reports; plus
server-side read and whitelisted mirror-write of the retailer app's Firestore `Retailer Users` doc (app-users).
Nest modules: agents, app-users.

## Entry points (all `/api/v2`)
- `agents`: GET `/` (projection widened for admins/managers), `admin-list`, `all` (legacy drop-ins), `me`,
  `directory?agent_email=`; GET `owner-by-phone?phone=` (`@Public()` + SsoOrWebhookSecretGuard);
  GET `:idOrAgentId/team-report`, `:idOrAgentId/self-report` (Scoped agents); GET `:idOrAgentId`;
  POST `/`, PATCH `:idOrAgentId`, DELETE `:idOrAgentId` (AdminOnly; DELETE is soft)
- `app-users` (Scoped phone): GET `:phone`, PATCH `:phone` (merge into existing doc; `is_verified` refused 422)

## Key files
- `src/modules/agents/{agents.controller.ts, agents.service.ts (~1.1k lines), schemas/agent.schema.ts}`
- `src/modules/app-users/{app-users.service.ts, app-user.normalise.ts}`; `src/common/firebase/{firebase.service.ts, app-user.shape.ts}`

## Data
- R/W `agents_v2`, `app_counters` (`_id:'agents'`, ids `AG-xxxxx`; password bcrypt-hashed)
- R `calls_v2`, `piis`, `leads_v2` (raw `lead_owner.agent_id`), `retailers_v2` (vip tier), `orders_v2` + legacy `orders`
- app-users: no Mongo; Firestore `Retailer Users`

## Depends on
auth (JwksService for SsoOrWebhookSecretGuard), Call schema (calls), Pii schema, `VIP_TIER_ENUM` (retailers);
common raw-db, lead-ownership, orders-v2, access, Firebase.

## Used by
- Modules: retailer-events, orders, rps, statics (AgentsService).
- PORTAL: `/agents`, `/agents/:idOrAgentId` (`redux_v2/apis/agents_api.service.ts`).
- ADMIN: `/agents/:idOrAgentId`, `/agents/all` (`src/redux/agents.v2.api.ts`).
- RVP: none. `owner-by-phone`: likely server-to-server (webhook secret) UNVERIFIED.
- app-users: no consumer found in RVP/portal/admin repos — likely RVP/PORTAL migration branches UNVERIFIED.

## External services
Firebase Firestore (app-users).

## Gotchas
- Explicit projection allow-lists (SAFE/PUBLIC/STAFF) keep legacy secrets on old docs (SIP password, tokens,
  device_token, order_history) from leaking. Keep using them.
- Agent id formats differ: legacy `A0-1539` vs new `AG-00012`.
- owner-by-phone reads raw `leads_v2.lead_owner.agent_id` on purpose (LeadOwnershipService maps sentinel `A0-1126` to '-').
- Orders filter on `orders_v2.date`; cancelled [10,12,13]; date-only `to` = end of IST day.
- Static routes (`me`, `owner-by-phone`) must stay declared before `:idOrAgentId`.
- app-users: document URLs not on our bucket are dropped; contract `docs/firebase-apis.md` §3-4.

Last verified: 2026-10-07 @ 278fe58 (kartik)
