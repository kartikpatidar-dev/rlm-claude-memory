# kyc-module

**Purpose:** Retailer 360 / partner profile: retailer list, detail (timeline, events, notes, remarks, follow-up, RPS score, blacklist check),
and edit (profile + documents).

**Entry points:** `/kyc-module`, `/kyc-module/:retailerId`, `/kyc-module/:retailerId/edit` (agent; all gated by `VITE_KYC_SHOW==='true'`);
`/manager/kyc-module` (gated), `/manager/kyc-module/:retailerId` and `/edit` (always). Pages `src/pages/agent/KYCModule{,Detail,Edit}.tsx`.

**Key files:** `src/redux/api/kycModuleApi.ts`, `src/components/call/RetailerTimelineV2.tsx`, `src/components/EventValueCard.tsx`.

**Data:** Firestore `Retailer Users` + Firebase Storage (KYCModuleEdit). No Supabase.

**Depends on:** auth-session, call-voip (call from detail).
**Used by:** — (KYCApproval reuses kycModuleApi queries).

**External services / endpoints:**
- rlm-backend-nest: `GET /retailers?{filters}`, `GET /retailers/:retailer_id`, `GET /retailers/:retailer_id/audit-history?limit=`,
  `PATCH /retailers/lead/update`, `GET /retailers/timeline?pii_id&page&limit&tz&startDate&endDate&retailer_id`,
  `GET /retailer-events/recent/:pii_id?page&limit`, `GET /notes/by-pii/:pii_id`, `POST /notes`, `PATCH /notes/:id/pin`.
- utils: `POST /rlm/add-remarks/:retailerId` (remarks + dispositions), `POST /rlm/follow-up`, `GET /rlm/event/:phone`,
  `GET /retailer-admin/rps-score` (used), `GET /retailer-admin/orders`, `GET /retailer-admin/coupons`, `POST /retailer-admin/lost` (exported),
  `GET /blacklist/check/pincode?pincode&channel=crm`.

**Gotchas:**
- kycModuleApi base: VITE_BASE_URL (fallback localhost:3001) plus absolute VITE_NEST_V2_URL (fallback localhost:4001/api/v2).
- `getKYCTimeline` hook export is unused. Old `KYC_MODULE_CHANGES.md` is stale (module now on NEST v2).

Last verified: 2026-10-07 @ 6e2113d (kartik)
