# profiled

**Purpose:** Canonical single-lead workspace (Profiled): retailer info, KYC documents (v4: Digio online vs manual proof, rejections),
address, GST, notes, FAQs, nearby buyers, recordings, follow-up, transfer history, pipeline stage, Approve KYC, move/transfer lead.

**Entry points:** route `/profiled?leadId&piiId&progressive` -> `src/pages/agent/Profiled.tsx` (~4.8k lines).
URL built by `src/lib/leadWorkspace.ts` (`LEAD_WORKSPACE_PATH='/profiled'`).

**Key files:** `src/pages/agent/Profiled.tsx`, `src/components/profiled/` (~42 files: useProfiledLead, ProfiledDocsGrid, DocReview,
documentVerifications, docCategories, draft, firebaseRetailer, syncFirebaseRetailer, firebaseDocumentsMeta, v4Hide, ProfiledGstField,
ProfiledAddressTab, ProfiledNotesTab, ProfiledFaqsTab, ProfiledTransferHistoryTab ...), `src/lib/leadWorkspace.ts`,
`src/lib/addressValidation.ts`, `src/lib/gstNumbers.ts`.

**Data:** Supabase query_master + query_usage_logs (FAQs). Form drafts in IndexedDB (`components/profiled/draft.ts`).
Firestore `Retailer Users` (sync of docs/address), RTDB call status.

**Depends on:** auth-session, call-voip, transfer, whatsapp.
**Used by:** my-leads, progressive-calling (navigates on connect), call-voip (CallWidget navigates), transfer, layout-shell (drafts launcher).

**External services / endpoints:**
- rlm-backend-nest (VITE_NEST_V2_URL): `GET /retailers/:retailer_id` (by piiId), `POST /retailers/upsert` (Approve KYC),
  `GET /retailers/timeline` (ProfiledAppTimeline), `GET /notes/by-pii/:pii_id`, `POST /notes`, `PATCH /notes/:id/pin` (ProfiledNotesTab),
  `POST /document-rejections`, `GET /document-rejections/by-pii/:piiId`, `GET /document-rejections/by-pii/:piiId/:label` (DocReview),
  `GET /document-verifications/by-pii/:piiId`.
- ko-sales: `GET/PUT /leads/:id`, `GET /leads/:id/activity`, `GET /leads` (ProfiledPicker), `GET /pipelines/lead/:id/stage`,
  `POST /pipelines/lead/:id/recompute`, `GET /pipelines/lead/:id/linked`, `POST /pii/:piiId/upload-document/:docType`, `PUT /pii/:piiId/documents/:docType`,
  `GET /pii/:piiId/document-requirements/:profile`, `POST /pii/gst-lookup/:gst`, `POST /pii/:piiId/gst`, `POST /pii/:piiId/address`,
  `PUT /pii/:piiId/address/:addressId`, `GET /calls/pii/:piiId`, tags endpoints, `GET /pincode-customers`.
- sales-operation: `POST /verification-transfer/update-profile`, `/assign`, `/fm-resolve`, `GET /verification-transfer/my-transferred-leads`.

**Gotchas:**
- Flags: VITE_KYC_LOCK, VITE_KYC_ROLE, VITE_CONDITION_ROLE (Move Lead), VITE_V4_HIDE (`true` in tracked .env: hides rejection history, Reject button and manual detail inputs except doc number; see components/profiled/v4Hide.ts), VITE_SINGLE_CALL_ALLOWED.
- `/profiled` has no disposition flow of its own — CallWidget must show it; a progressive call's disposition is owned by the queue.
- NEST base fallback differs by file (localhost:4001 vs prod) — env must be set.
- Approved KYC is final/frozen (recent commits); online (Digio) and manual proof must not mix.
- Very large file; overlapping logic with lead-detail-legacy.

Last verified: 2026-10-07 @ 6e2113d (kartik)
