# rlm-backend-nest status

Last verified: 2026-10-07 @ 278fe58 (kartik)

## Current state
- HEAD `278fe58` ("all-changes", 2026-10-07) on local branch `claude-memory-setup`; identical to `aws-deployed` and
  `origin/aws-deployed` (0 ahead / 0 behind). `main` is 138 commits behind (stale).
- Recent themes: portal Supabase moved behind nest (`/portal`, 11 modules), Firebase behind nest (files, app-users,
  pc-requests, calls RTDB + socket), `app_version` kept in step between `leads_v2` and `retailers_v2`, NEST-02..30
  open tasks (envelope, slow-request log, Supabase SQL packs, `scripts/db`), boot DNS fallback.

## Recent commits (`git log --oneline -25`)
```
278fe58 all-changes
f7b0899 all changes
081e5a5 Merge PR #134 app-version-retailer-sync
de9499c feat(retailer): keep retailers_v2.app_version in step with the lead on PATCH
1c65a67 Merge branch 'beta' into aws-deployed
f1e9387 Merge PR #132 fix-app-version-only-update
9756a6e fix(retailer): report the app_version outcome on PATCH, not "No fields to update"
957987c Merge PR #131 nitesh-lead-app-version
5d1cd59 feat(leads): store app_version on leads_v2 and read it lead-first
e1a10e5 Merge PR #130 query-event-opt
aca8d4c Merge migration into query-event-opt: every Supabase call of rlm-portal and the verification portal goes through nest
3a6aa15 feat(portal): the verification portal's Supabase behind nest (97 routes, 10 modules)
aa1803c docs(portal-data): the settings a server needs for /portal
2fad479 feat(portal-data): rlm-portal's Supabase tables behind nest (24 /portal routes)
dc1f55c Merge PR #129 query-event-opt
7109df2 fix(boot): a start that cannot reach the database says so at once, and DNS falls back to the system resolver
28f9809 Merge PR #128 query-event-opt
08e575c feat(firebase-apis): e2e tests, PC requests on the real data, calls fail fast, live read-only check
49f5cab fix(swagger): the app died at boot on a response DTO property typed null
e0ab4bd Merge PR #127 query-event-opt
bf31411 Merge branch 'migration' into query-event-opt: Firebase behind nest
594cfcc feat(firebase-apis): Firebase behind nest for rlm-portal and the verification portal
4fa6416 Merge PR #126 query-event-opt
e92aae7 feat(open-tasks): NEST-02…30 in code, Supabase SQL packs, MongoDB task scripts
c5f1b59 Merge remote-tracking branch 'origin/aws-deployed' into query-event-opt
```

## Notable unmerged remote branches (commits not in HEAD)
- `origin/feat/orders-foro-status-breakdown` (f12c3c5): adds a `geography` module (`/geography/crops...`). **ADMIN
  `src/redux/crops.v2.api.ts` (Crop Master page) already calls it; it 404s against prod until merged.**
- `origin/feat/geo-cluster-analytics` (GeoAnalyticsModule), `origin/nitesh-retailers-list-optimize` (3, GET /retailers perf),
  `origin/feat/upsert-failure-log`, `origin/fix/reconcile-fo-to-ro-delivered-only`, `origin/duplicate_id_fix` (2),
  `origin/feat/sso-firewall-rollout` / `origin/shell`, `origin/beta` and `origin/app-version-retailer-sync` (1 each).
  Whether these are abandoned or superseded: UNVERIFIED.
- FE side: RVP/PORTAL branches `origin/migration`, `origin/query-event-opt` would consume the portal-* modules;
  ADMIN `origin/feat/sales-potential-nest-integration` would consume `sales-potential`.

## Known issues / risks
Security
- Hard-coded fallback webhook secret used when `KO_SALES_WEBHOOK_SECRET` is unset, in 3 places:
  `src/modules/auth/guards/sso-auth.guard.ts`, `src/modules/retailer/retailer.service.ts`,
  `src/modules/retailers/retailer-lead.service.ts`. The guard compare is not constant-time.
- Sockets `/bug-reports`, `/lead-assignment` and `/reconcile` accept unauthenticated connections (any room on `/bug-reports`).
- `PATCH`/`DELETE /bug-reports/:id` are not owner-checked (any SSO user).
- `ACCESS_SCOPE_MODE` defaults to `warn` (scope violations logged, not blocked). Prod value UNVERIFIED.
- JWKS verify has no issuer/audience check; `GET /auth/debug-token` is public (decode only).
- `POST /retailer-events` is public (telemetry); `/db/indexes` can build any index (incl. TTL/unique) with the maintenance secret.
Ops / correctness
- CI deploys only the `fallback` host; AGENTS.md says both hosts and branch `main` (stale). No lint/test in CI.
- Crons run in every cluster worker on every host; only order-info-recompute takes a `job_locks` lock.
- `app_counters` drift: retailers counter far below real max `KP-` id; `retailer_id` index not unique (repair tooling `retailers/duplicate-ids`).
- No transactions for multi-collection writes; caches/throttler/socket rooms are per worker (Redis adapter only if configured).
- Slow endpoints (`docs/slow-requests.md`): `GET /retailer-admin/rps-dashboard`, `/retailer-admin/distinct-wise`, `/retailer-admin/agent-with-leads`.
- `test_recordings` Supabase bucket missing (portal test recording uploads fail).
- Dockerfile `EXPOSE 4003` vs app port 4000 (Dockerfile unused).
- ADMIN leaderboard client calls a hard-coded Render host, not the env base URL (liveness UNVERIFIED).

## In progress / next steps
- (placeholder) Fill in at the next `/proj-handoff`.
