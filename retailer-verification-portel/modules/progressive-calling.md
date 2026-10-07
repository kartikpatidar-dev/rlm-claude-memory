# progressive-calling (Working Module)

**Purpose:** Auto-dialer queue for agents: fetch queue, start/end session, dial next lead, open the lead on connect, blocking disposition,
cooldown/break/skip; manager stats and live session tracking.

**Entry points:** `/progressive-calling` -> `src/pages/agent/ProgressiveCalling.tsx`; manager `/manager/progressive-calling`
(`src/pages/manager/ProgressiveModule.tsx`, stats) and `/manager/progressive-tracking` (`ProgressiveTracking.tsx`).

**Key files:** `src/contexts/ProgressiveCallingContext.tsx` (thin provider, agent tree only), `src/hooks/useProgressiveQueue.ts` (core logic),
`src/lib/queueOrder.ts` (+ test), `src/contexts/QueueSocketContext.tsx`, `src/hooks/useQueueSocket.ts`, `src/hooks/useAdminQueueSocket.ts`,
`src/components/call/GlobalProgressiveIndicator.tsx`. Deep-dive doc in repo: `PROGRESSIVE_CALLING.md` (mostly current).

**Data:** no Supabase. Firebase RTDB `calls/{uuid}`, `agents/{topic}` (via call-voip). Queue state in local/persisted state.

**Depends on:** auth-session, call-voip (dial, call status, pending disposition), profiled (navigates to `leadWorkspaceUrl(..., {progressive:true})` on connect).
**Used by:** layout-shell (indicator), my-leads, LeadDetail/KYCWorking (context consumers).

**External services / endpoints:**
- ko-sales: `GET /leads/progressive-queue`, `POST /leads/progressive/session/start`, `POST /leads/progressive/session/end`,
  `GET /leads/progressive/tracking?date&agent_id` (manager), `GET /leads`, `GET /leads/:id`, `PATCH /calls/uuid/:uuid/disposition`,
  `POST /calls/dispositions`.
- ko-sales socket.io `/ws/queue`: `lqs-changed`, `lead-assigned`, `admin:session-changed`, `admin:progress-requested` -> emit
  `agent:progress-report`; `admin:progress-report` (admin hook); ping/pong.
- utils `/verification/rlm/*` stats (ProgressiveModule).

**Gotchas:**
- Flags: VITE_TEST_MODE (test phone), VITE_QUEUE_REALTIME (`'false'` disables the socket).
- Manager tree has no ProgressiveCallingProvider — don't use the context in manager pages.
- The queue owns the disposition for progressive calls; CallWidget must not file a second one on `/profiled`.
- `isOnLeadWorkspace` accepts `/profiled` and `/kyc-working` so an agent mid-call is not yanked back to the queue.

Last verified: 2026-10-07 @ 6e2113d (kartik)
