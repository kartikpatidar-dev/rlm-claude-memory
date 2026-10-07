# analytics

## Purpose
Admin/manager dashboards and reports: agent stats, orders/KYC stats, lost and at-risk retailers, retailer groups,
events/traffic, district-wise, RPS (= LQS) scores and sync, FO/RO stats, sales potential, leaderboard.
Nest modules: retailer-admin, rps, statics, sales-potential, leaderboard. Ports of node `utilities` controllers.

## Entry points (all `/api/v2`)
- `retailer-admin` (class ScopedGuard), grouped:
  - Agents/calls: GET `dashboard`, `calls-today`, `all-agents` (OpenToAll), `agent-with-leads`, `agent-summary` (AdminOnly),
    `agent-statics`, `agent-analytics-summary`; PATCH `call-outcome`
  - Orders/KYC: GET `orders`, `order-status-dashboard`, `kyc-statics`, `language-statistics`, `verification-statistics`, `verification-retailers`
  - Lost/risk: GET/POST `lost` (POST -> VerificationService.markLeadLost), POST `lost-feedback`, GET `risk-overview`; GET `timeline`
  - Groups: GET `group-retailers`, `group-states`, `group-districts`; POST `retailer-groups`, `retailer-groups/summary` (AdminOnly);
    GET/POST `groups`; GET/POST `groups/:id/members`; DELETE `groups/:id/members/:retailerId`; GET `groups/:id/logs`; DELETE `groups/:id`
  - Events/products: GET `events`, `event-statistics`, `product-overview`, `traffic`, `orders-without-calls`, `organic-trend`,
    `distinct-wise` (sic), `recent-events`; PATCH `change-visibility/:sku` (**NotImplemented**)
  - RPS/FO-RO: GET `rps-score`, `rps-dashboard`; POST `rps-event`, `rps-sync`; GET `statics/foro`
- `rps`: GET `score`, `analysis`, `team-analysis`; POST `sync` (Scoped)
- `statics` (class Scoped): GET `report`, `rps-analytics`, `call-statics`, `retailer/:retailer_id`, `events-statics`
- `sales-potential` (class Scoped, read-all callers): GET `summary`, `states`, `districts`, `funnel`, `revenue-breakdown`;
  POST `scenario`; GET `scenarios`; DELETE `scenario/:scenarioId`
- `leaderboard`: GET `/` (SSO)

## Key files
`src/modules/retailer-admin/{retailer-admin.controller.ts, services/retailer-admin-{dashboard,list,events,rps,foro}.service.ts, schemas/}`,
`src/modules/rps/{rps.service.ts, rps-sync.service.ts, rps.scoring.ts}`, `src/modules/statics/`, `src/modules/sales-potential/{state-names.ts}`, `src/modules/leaderboard/`

## Data
- W: `retailers_v2` (call-outcome counters; rps sync bulkWrite of order_info/call_info/vip_level), `lost_feedback`,
  `retailer_groups`, `retailer_group_logs`, `retailevents` (rps-event), `salesscenarios`
- R: `retailers_v2`, `piis`, `agents_v2`, `calls_v2`, `leads_v2`, `orders_v2` + legacy `orders`, `retailevents`, `addresses`,
  `notes_v2`, `products`, `categories`, `contacts_v2`, `states_v2`, `districts_v2`, `pincode_map_v2`, `retailer_pipeline_cycles`, `retailer_leaderboard`

## Depends on
verification-kyc (VerificationModule), agents, calls; rps <- retailer-admin; common orders-v2, order-status, lqs-score,
lead-ownership, phone-search, access, `utils/{recent,in-flight}`.

## Used by
- PORTAL: ~30 `/retailer-admin/*` routes (`redux_v2/apis/retailer_admin_api.service.ts`, `hooks/useTeamBandwidth.ts`),
  `/rps/score|analysis|team-analysis` (`rps_api.service.ts`), `/statics/report` (`statistics_api.service.ts`).
- ADMIN: dashboard, groups, lost, rps-dashboard, statics/foro, traffic... (`src/redux/{agents,buketMaster,dashboard,organic,products}.v2.api.ts`);
  `/leaderboard` via hard-coded Render host in `pages/katyayani-partner/pages/leaderboard/leaderboard.client.ts`.
- RVP: none (its `/retailer-admin/*` calls go to the utils API). sales-potential: no consumer on current branches
  (ADMIN `origin/feat/sales-potential-nest-integration`).

## External services
None.

## Gotchas
- "RPS" routes return the lead's LQS from `leads_v2`; `retailers_v2.rps_info` is not read.
- Slow: `rps-dashboard`, `distinct-wise`, `agent-with-leads` (`docs/slow-requests.md`).
- FO/RO rule counts orders by attributed agent role (USR-1029/1030 FO, USR-1022 RO): open product decision.
- rps sync `syncing` flag is in-process (not safe across workers). Lost thresholds 91; at-risk 46/91.
- Leaderboard nightly compute job lives outside this repo (UNVERIFIED). sales-potential cached 10 min.

Last verified: 2026-10-07 @ 278fe58 (kartik)
