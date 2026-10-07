# transfer

**Purpose:** Transfer leads between verification and KYC agents (agent requests, FM resolves), search, and transfer history.

**Entry points:** `/transferred-leads` (agent and FM trees) -> `src/pages/agent/TransferredLeads.tsx`; Profiled transfer action +
`ProfiledTransferHistoryTab`.

**Key files:** `src/pages/agent/TransferredLeads.tsx`, `src/components/transfer/` (FmResolveDialog, TransferLeadsGrid, TransferStatusStrip),
`src/lib/transferSearch.ts` (+ test), `src/hooks/useAgentDirectory.ts`, `src/redux/api/salesOperationSlice.ts` (+ 2 tests),
`src/components/profiled/ProfiledTransferHistoryTab.tsx`. Repo doc: `docs/verification-transfer-summary.md`.

**Data:** no Supabase/Firebase.

**Depends on:** auth-session, profiled (opens transferred lead at `/profiled?leadId&piiId`).
**Used by:** profiled.

**External services / endpoints:**
- sales-operation (VITE_SALES_OPERATION_API_URL, Bearer `sso_token`): `POST /verification-transfer/update-profile`,
  `POST /verification-transfer/assign`, `GET /verification-transfer/my-transferred-leads` (also used for search), `POST /verification-transfer/fm-resolve`.
- ko-sales: `GET /leads/lookup?pii_id=`, `GET /leads/find-by-phone?phone=`, `GET /agents/all`, `GET /agents/search?q=`.

**Gotchas:**
- Transfer lives on the sales-operation FastAPI service, not on ko-sales or nest.
- salesOperationSlice has logic deciding whether a my-transferred-leads reply is a real answer (see comments around it).

Last verified: 2026-10-07 @ 6e2113d (kartik)
