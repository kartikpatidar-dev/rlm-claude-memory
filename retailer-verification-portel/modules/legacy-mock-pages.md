# legacy-mock-pages

**Purpose:** Early Lovable-generated RLM screens kept in the router but not part of the current agent workflow (mostly not in the sidebar;
reachable by URL). Mock data or direct Supabase reads of legacy tables.

**Entry points:** agent `/events` (MyEvents), `/events/:eventId/call` (CallScreen), `/retailers`, `/retailers/:retailerId`, `/orders`,
`/orders/:orderId`, `/rps`, `/wallet/transaction/:transactionId`, `/profile` (MyProfile); manager `/manager/retailers`,
`/manager/orders`, `/manager/orders/:orderId`, `/manager/rps`, `/manager/events/create`, `/manager/messaging`, `/manager/forecast(er)`
(SalesForecaster), `/manager/kps-config`, `/manager/settings` (SLAIntegrations), `/manager/user-roles`, `/manager/template-master`,
`/manager/pipeline(s)`, `/manager/workflow-execution`.

**Key files:** `src/hooks/supabase/` (useAgents, useAgentMetrics, useAppEvents, useAttendance, useCallHistory, useCoupons, useEvents,
useNotifications, useOrders, useProducts, useRetailers, useWallet), `src/data/mockData.ts`.

**Data:** main Supabase `agents`, `agent_roster`, `agent_coin_transactions`, `agent_feedback`, `orders`, `order_items`, `retailers`, `rps_tasks`,
`products`, `coupons`, `ivr_calls`, `app_events` (+ realtime `app_events_realtime`), `attendance`, `notifications` — mostly no migrations here (types.ts only).

**Depends on:** auth-session.
**Used by:** — .

**External services / endpoints:** none beyond Supabase (MyProfile also hits HRMS `/api/employee-skills` with a hard-coded host).

**Gotchas:**
- Do not assume these screens reflect production data; confirm with the user before investing in them.
- Dead/unrouted siblings: `pages/Index.tsx`, `pages/auth/Login.tsx`, `pages/manager/OrderDetails.tsx`, `pages/manager/CourseFeedback.tsx`,
  `components/LeadTable.tsx`, `components/LeadDetail.tsx`.
- Which of these routes real users still open is UNVERIFIED.

Last verified: 2026-10-07 @ 6e2113d (kartik)
