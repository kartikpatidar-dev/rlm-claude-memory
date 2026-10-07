# calls

## Purpose
Mongo call log (`calls_v2`) plus a bridge to Firebase RTDB live call state (REST + `/calls` socket) that replaces
browser `onValue` listeners.

## Entry points (all `/api/v2/calls`; `CallsRtdbController` registered first so the UUID route wins)
- GET `agents/:topic`: SSO; RTDB `agents/{topic}`; scope check in service
- GET `:uuid` (regex: UUID or `evt-<digits>-<digits>`): RTDB `calls/{uuid}`
- POST `:uuid/force-end`: SSO; marks RTDB call ended (`portal_forced`)
- POST `/`: Scoped (pii_id, retailer_id, agent_id); creates `CL-n`
- GET `by-pii/:pii_id`, GET `by-retailer/:retailer_id`, GET `:id` (Scoped)
- Socket `/calls`: SSO token verified on handshake; rooms `call:<uuid>` (`call:status`), `agent:<topic>`
  (`agent:current`), `agents` (`agents:all`), `calls:latest[:<prefix>]`; `auth:ok|expired`, `calls:error`

## Key files
`src/modules/calls/{calls.controller.ts, calls.service.ts, calls-rtdb.controller.ts, calls-rtdb.service.ts,
calls.gateway.ts, schemas/call.schema.ts}`; contract `docs/firebase-apis.md`.

## Data
- R/W `calls_v2`; R/W `app_counters` (`_id:'calls'`)
- W `retailers_v2.call_info.{call_type,last_call_date}` on every retailer of the PII

## Depends on
auth (JwksService), Retailer schema, common raw-db, Firebase, access. Exports CallsService + Call model (agents, statics).

## Used by
- Modules: agents (Call model), analytics/statics (CallsModule).
- PORTAL: `/calls`, `/:id`, `/:uuid`, `/by-pii/:pii_id`, `/by-retailer/:retailer_id` (`redux_v2/apis/calls_api.service.ts`).
- ADMIN: `/calls/by-pii/:pii_id` (`src/redux/buketMaster.v2.api.ts`).
- RVP: none (still reads RTDB directly). Socket `/calls`: no consumer found in the 3 FE repos.

## External services
Firebase RTDB in a separate project (`FIREBASE_DATABASE_URL`, optional `FIREBASE_RTDB_PROJECT_ID`,
`FIREBASE_RTDB_CLIENT_EMAIL`, `FIREBASE_RTDB_PRIVATE_KEY`); data written by the CallerApp (VoIP).

## Gotchas
- RTDB 8 s timeout; a failed probe is remembered 1 min (fast 503). Incident 2026-10-03: main service account refused by the other project's DB.
- One RTDB listener per room, ref-counted; emits are per worker (`server.local`).
- Real `calls_v2` fields are `call_type`/`call_time`; schema `direction`/`started_at` largely unpopulated; ~79% rows lack usable `pii_id`.
- Nodes without `agent_email` are open to any logged-in agent. Phone digits masked in logs.

Last verified: 2026-10-07 @ 278fe58 (kartik)
