# agent-performance

**Purpose:** Agent-facing performance: home dashboard (stats, tasks, SLA breaches, attendance panel, quotes), My Performance,
Report Card, Leaderboard, Audit Report.

**Entry points:** agent `/` -> `src/pages/agent/Dashboard.tsx`; `/performance` (MyPerformance), `/report-card` (ReportCard),
`/leaderboard` (Leaderboard), `/audit-report` (AuditReport) in `src/pages/agent/`.

**Key files:** the pages above, `src/services/managerApi.ts`, `src/redux/api/b2bApi.ts`, `src/services/backendApi.ts`,
`src/services/hrmsAttendance.ts`, `src/hooks/useMotivationalQuotes.ts`, `src/integrations/supabase/certificatesService.ts`,
`src/redux/slices/filtersSlice.ts` (`agentDashboard`).

**Data:** Supabase `monthly_targets`, `agent_target_overrides` (targets), `issued_certificates` (MyPerformance), `grievances` (MyPerformance),
`motivational_quotes` (via sopSupabase).

**Depends on:** auth-session; Dashboard links to lead-detail-legacy (`/lead/:id` on SLA breach).
**Used by:** — (navigation only).

**External services / endpoints:**
- ko-sales: `GET /verification/dashboard-stats?period`, `GET /tasks?…`, `GET /calls/pii/:piiId`, `GET /statistics/manager-team-report`
  (b2bApi: Dashboard, Leaderboard, MyPerformance), `GET /leaderboard/profiling`.
- utils: `GET /verification/rlm/*` (info, summary, statics, leaderboards, kyc-leaderboard ... via managerApi), `GET /verification/leaderboard`.
- sales-operation: `GET /agronomy/audit-list` (AuditReport, Dashboard).
- HRMS: `POST /api/rpc/get_hierarchy_with_attendance` (HARD-CODED host in Dashboard, MyPerformance, Leaderboard), clock/KPI endpoints.

**Gotchas:**
- HRMS host hard-coded in several pages despite VITE_HRMS_* env vars.
- Same stats come from both ko-sales `/statistics/*` and utils `/verification/rlm/*`; check which one a widget uses.

Last verified: 2026-10-07 @ 6e2113d (kartik)
