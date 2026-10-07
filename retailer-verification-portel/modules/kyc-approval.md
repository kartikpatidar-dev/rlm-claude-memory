# kyc-approval

**Purpose:** Agent "My Verification/KYC" list and the FM approval queue: list KYC submissions/retailers, approve or reject KYC, reassign.

**Entry points:** `/my-kyc` -> `src/pages/agent/MyKYC.tsx`; `/manager/kyc-approval` -> `src/pages/manager/KYCApproval.tsx`;
`/kyc/:kycId` -> `src/pages/agent/KYCDetail.tsx`.

**Key files:** `src/integrations/rlm/retailers.ts`, `src/integrations/rlm/api.ts`, `src/components/kyc/KYCRetailerTable.tsx`,
`src/redux/api/kycModuleApi.ts`, `src/services/backendApi.ts` (`approveKycV2`, `rejectKycV2`).

**Data:** marketing Supabase `states`, `districts` (filters).

**Depends on:** auth-session, lead-detail-legacy (KYCDetail links `/lead/:id`); MyKYC uses `leadWorkspaceUrl` (profiled).
**Used by:** — (navigation only).

**External services / endpoints:**
- rlm-backend-nest: `GET /retailers?{filters}` (sends `kyc_only=true` so the agent filter uses `kyc_agent`), `GET /retailers/:retailer_id`,
  `POST /verification/approve-kyc/:id`, `POST /verification/reject-kyc/:id`.
- ko-sales: `GET /verification/submissions`, `GET /verification/submissions/:leadId`, `POST /verification/submissions/:leadId/approve`,
  `POST /verification/submissions/:leadId/reject`, `POST /leads/:id/assign`,
  `GET /leads/:id/activity`, `GET /leads/my-tags`, `GET /leads/sources` (MyKYC).
- utils: `GET /verification/kyc-stats`, `POST /verification/team-kyc-count`, `GET /verification/kps-score`, `POST /verification/bulk-kps`,
  `GET /verification/dashboard?contact=` (no auth), `GET /rlm/lead-pipeline/:phone`.

**Gotchas:**
- Approval exists in two places: NEST `/verification/approve-kyc` (this module) vs Profiled's "Approve KYC" (`POST /retailers/upsert`).
- Some utils calls send no auth header.

Last verified: 2026-10-07 @ 6e2113d (kartik)
