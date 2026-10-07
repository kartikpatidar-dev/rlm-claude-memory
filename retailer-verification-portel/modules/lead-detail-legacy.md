# lead-detail-legacy (LeadDetail + KYCWorking)

**Purpose:** The two older lead workspaces that Profiled replaced but which are still reachable: `/lead/:leadId` (LeadDetail) and
`/kyc-working` (KYCWorking, reached by kycId in the resubmit flow). Verification form, documents, remarks, events, approval to Stockship.

**Entry points:** `src/pages/agent/LeadDetail.tsx` (~6.3k lines), `src/pages/agent/KYCWorking.tsx` (~4.4k lines).

**Key files:** the two pages, `src/components/lead/` (RetailerInfoPanel, AddressPanel, TagsPanel, NearbyBuyersPanel, LeadPipelineDisplay,
RetailerRemarksButton, WhatsApp*), `src/components/kyc/DocumentsPanel.tsx`, `src/components/kyc/FarmerProfileForm.tsx`,
`src/hooks/useVerificationDrafts.ts`, root `firebase/connection.ts` + `firebase/storage.ts` (KYCWorking only).

**Data:** Supabase `verification_draft_info` (drafts: LeadDetail, RetailerInfoPanel, useVerificationDrafts), `query_master` / `query_usage_logs`
(KYCWorking). Firestore `Retailer Users`; Firebase Storage doc uploads.

**Depends on:** auth-session, call-voip (dial, dispositions), whatsapp (lead-level chat panel).
**Used by:** my-leads (LeadBoard), notifications (`lib/notification-meta.ts` -> `/lead/:id`), kyc-approval (KYCDetail link), agent-performance
(Dashboard SLA breach link), layout-shell (FloatingDraftIcon, ProfiledDraftsLauncher for old drafts).

**External services / endpoints:**
- rlm-backend-nest: `POST /retailers/upsert` (LeadDetail).
- ko-sales: `GET/PUT /leads/:id`, `GET /pii/:piiId`, `POST /pii/:piiId/upload-document/:docType`, `GET /pii/:piiId/document-requirements/:profile`,
  `GET /profile-doc-config`, `GET /calls/pii/:piiId`, `PATCH /calls/uuid/:uuid/disposition`, `POST /calls/dispositions`, tags endpoints,
  `POST /notes` + `GET /notes/pii/:piiId` (KYCWorking — ko-sales notes, NOT nest), `GET /query-flow/config`, `GET /conversion-funnel`.
- utils: `PATCH /verification/retailers/:id/update`, `PUT /rlm/update-profile/:retailerId`, `GET /rlm/:retailerIdOrPhone`,
  `GET /rlm/event/:phone`, `GET /retailer-admin/timeline?phone`.
- Stockship (VITE_STOCKSHIP_URL): `POST /retailer` on approval.

**Gotchas:**
- Duplicates much of Profiled; prefer changing Profiled. `lib/leadWorkspace.isOnLeadWorkspace` treats `/kyc-working` as a lead page.
- Two Firebase init paths (src/lib/firebase.ts and root firebase/).
- `components/LeadDetail.tsx` (component, not the page) is dead code.
- Old CLAUDE.md says progressive opens `/kyc-working` — stale; it opens `/profiled`.

Last verified: 2026-10-07 @ 6e2113d (kartik)
