# rlm-backend-nest (memory entry point)

Last verified: 2026-10-07 @ 278fe58 (kartik)

NestJS 10 API for the RLM (retailer lifecycle) CRM. Every route lives under `/api/v2` (prefix derived from
`API_DOCS_VERSION`). Primary store: MongoDB database `CRM-Database` (Atlas), plus Supabase (portal screens) and
Firebase (retailer app mirror, call state, file storage). Shared by three frontends:
`retailer-verification-portel` (RVP), `rlm-portal` (PORTAL) and `rlm-admin-final` (ADMIN). Other likely callers
(no consumer found in the 3 FE repos): the retailer (KSR) mobile app, ko-sales/Stockship webhooks and an external
cron scheduler. UNVERIFIED.

Root rules: [`../README.md`](../README.md). Cross-project links: [`../system-map.md`](../system-map.md).

## Quick facts
| | |
|---|---|
| Repo | Katyayani-Organics/rlm-backend-nest (local `../rlm-backend-nest`) |
| Production branch | `aws-deployed` (CI `.github/workflows/deploy.yml` deploys on push). **Never push to `aws-deployed` (or `main`) directly; use a PR.** |
| `main` | stale: 138 commits behind `aws-deployed`, 0 ahead (at 278fe58) |
| Runtime | Node >= 24 (package.json engines; Dockerfile node:24-alpine) |
| Prod entry | `cluster.js` (2 workers/host) under systemd `deploy/rlm-backend.service`; hosts and DNS in `AGENTS.md` |
| API docs | Swagger at `/api-doc`; SSO sign-in helper page at `GET /` |
| Auth | SSO JWT (RS256 via JWKS) on every route unless `@Public()`; role scoping in `src/common/access` |
| Size | 52 module folders, 58 controllers, ~369 route handlers, 5 socket namespaces, ~61 Mongo collections |

## Reading order
1. `status.md` (current state, risks, unmerged work)
2. `module-graph.md` (who calls what; Last verified hash for the staleness check)
3. `modules/<domain>.md` for the task (15 domains, see module-graph table)
4. `architecture.md` (pipeline, auth, sockets, crons, decisions) and `database.md` for any DB work
5. `overview.md` for commands and env var names

## Protected / reference files in the project repo (read, do not rewrite casually)
- **There is no `CLAUDE.md`** (and no `.claude/`) in the project repo. Memory lives here.
- `AGENTS.md`: infra/deploy notes (EC2 fleet, DNS chain, SSM, Caddy, health failover, manual deploy, OTel) plus its
  own changelog. **Stale** on: deploy branch (says `main`, actual `aws-deployed`), "deploys both hosts" (CI matrix is
  `[fallback]` only), Node 20 (now 24), `//CRM-Database` URI-slash sharp edge (now mitigated by explicit `dbName`).
  Noted here; not fixed.
- `README.md`: Collection ER diagram, edge catalogue, invariants, module-to-collection matrix. Partly stale
  (`addresses_v2` vs real `addresses`, `piis.address_ids` vs `addresses`, `parent_agent_id` vs `agent_manager`;
  matrix covers only early modules).
- `docs/db-tasks-runbook.md`: runbook for `scripts/db` DB-01..DB-45 (current).
- `docs/firebase-apis.md`: files / app-users / pc-requests / calls (RTDB + `/calls` socket) contract (current).
- `docs/parity-utils-vs-nest.md`: NEST-09 utils-host vs nest parity check (point-in-time).
- `docs/portal-data-apis.md`: `/portal` routes replacing browser Supabase access (current).
- `docs/response-envelope.md`: NEST-22 response envelope, header `X-Response-Envelope: v1` (current).
- `docs/retailer-360-fields.md`: admin Retailer360 field audit (point-in-time).
- `docs/slow-requests.md`: NEST-21 slow-request log and 3 hot routes (2026-10-01, current).
- `docs/supabase-tasks-runbook.md`: SUPA-01..16 for the two Supabase projects (current).
- `docs/token-check-result.md`: NEST-02 forged-token check results (point-in-time).
- Never read or print `.env` / `.env.local` (secrets). Env var NAMES are listed in `overview.md`.
