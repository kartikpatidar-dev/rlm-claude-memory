# manager-reporting (incl. lead-assignment / buckets / workflows)

**Purpose:** FM/admin reporting and team control: Master Report (CallReporting), command centre, agent analysis/detail, call/lead analysis,
KYC funnel/forecast, bandwidth, live agents, leaderboard mgmt, RPS/events, FAQ master; plus lead assignment, lead buckets and workflows.

**Entry points (src/pages/manager/):** `/` + `/manager` + `/manager/call-reporting` -> CallReporting; `/manager/command-centre` -> Dashboard;
`/manager/agents`, `/manager/agent-analysis` -> AgentAnalysis; `/manager/agent/:agentId` -> AgentDetail; CallAnalysis, LeadAnalysis, KYCFunnel,
KYCForecast, BandwidthDetector, LiveAgents, LeaderboardMgmt, TeamRPSAction, TeamEvents, QueryMaster, FMReport.
Assignment: `/manager/lead-assignment` -> LeadAssignment; `/manager/leads` -> LeadBuckets (iframe); `/manager/workflows` -> WorkflowMaster (iframe);
`/manager/workflow-execution`, `/manager/pipeline(s)` (mock).

**Key files:** pages above, `src/services/managerApi.ts`, `src/services/backendApi.ts`, `src/hooks/useAgents.ts` (RTDB agents),
`src/hooks/useBandwidthSettings.ts`, `src/hooks/useAdminQueueSocket.ts`, `src/integrations/supabase/attendance.ts`, `src/redux/slices/filtersSlice.ts` (`agentAnalysis`).

**Data:** main Supabase: `bandwidth_settings`, `monthly_targets`, `query_master`/`query_usage_logs` (QueryMaster); AgentDetail reads `calls`,
`daily_agent_metrics`, `kyc_audit_scores`, `activity_logs`, `agent_levels`, `whatsapp_conversations`, `grievances`, `agents`.
HRMS Supabase (attendanceSupabase): `employees`, `attendance`. Firebase RTDB `agents` (LiveAgents).

**Depends on:** auth-session.
**Used by:** — (manager navigation only).

**External services / endpoints:**
- ko-sales: `GET /statistics/manager-team-report`, `GET /statistics/attendance`, `GET /statistics/calls/summary`, `GET /statistics/calls/history`,
  `GET /agent-analysis`, `GET /messages?…limit=1`, `POST /forecast/manager` (KYCForecast), `GET /conversion-funnel`, `GET /leads/progressive/tracking`;
  assignment: `GET /leads`, `POST /leads/:id/assign`, `POST /leads/upsert` (bulk upload), `GET /agents?…`, `GET /agents/search?q=`, `GET /tasks/workflows`.
- utils: `GET /verification/rlm/{info,summary,call-analysis,statics,kyc-funnel,leaderboards,kyc-leaderboard,lead-status-distribution,
  lead-daily-trend,lead-bucket-summary,agent-lead-performance,lead-geography,lead-tag-performance}`, `GET /verification/call-recordings`,
  `GET /verification/leaderboard`, `GET /rlm/retailer-events` (TeamEvents).
- HRMS: `POST /api/rpc/get_hierarchy_with_attendance` (HARD-CODED host in AgentAnalysis, CallReporting, BandwidthDetector, Dashboard).
- iframes with SSO token in query string: VITE_AGRI_SALES_HUB_URL (LiveAgents, WorkflowMaster), LeadBuckets (host hard-coded).

**Gotchas:**
- React Query used in AgentDetail and LeadAssignment; others use fetch/RTK.
- `/manager/ask-katyayani` linked from FMSidebar has no route. Many FM items are "Coming Soon".
- Repo docs ENHANCED_SEARCH_PROCESS.md / PAGINATION_IMPLEMENTATION.md are old (UNVERIFIED vs LeadAssignment).

Last verified: 2026-10-07 @ 6e2113d (kartik)
