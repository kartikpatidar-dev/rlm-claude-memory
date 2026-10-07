# my-leads

**Purpose:** Agent's lead list: filters, pipeline-stage tabs, optional board view, start calls / open the lead workspace.

**Entry points:** routes `/leads`, `/my-leads` -> `src/pages/agent/MyLeads.tsx`.

**Key files:** `src/pages/agent/MyLeads.tsx`, `src/components/lead/` (LeadBoard, PipelineStageBar, PartialResultsBanner, SLATimer),
`src/redux/slices/filtersSlice.ts` (`myLeads` filter state, persisted in IndexedDB), `src/redux/api/koSalesApi.ts`, `src/services/backendApi.ts`.

**Data:** no Supabase. Filters in redux-persist (IndexedDB).

**Depends on:** auth-session, call-voip (`lib/callerapp.ts`, useActiveCall, pending disposition), progressive-calling (context),
whatsapp (WhatsAppFloatChat), profiled (row link `/profiled?leadId=`), lead-detail-legacy (LeadBoard links `/lead/:id`).
**Used by:** layout-shell (navigation).

**External services / endpoints:**
- ko-sales: `GET /leads?{params}`, `GET /leads/my-tags`, `GET /leads/sources`, `GET /agents/my-scope`.
- utils: `GET /kyc/agent_v2` (agent list).

**Gotchas:**
- Flags: VITE_SHOW_PIPELINE_TABS, VITE_SHOW_LEAD_BOARD.
- Both backendApi `getMyLeads` and koSalesApi `getMyLeads` exist for the same endpoint.
- LeadBoard still links to the legacy `/lead/:id` page while the list links to `/profiled`.

Last verified: 2026-10-07 @ 6e2113d (kartik)
