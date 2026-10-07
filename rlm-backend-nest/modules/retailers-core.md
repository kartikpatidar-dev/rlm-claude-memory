# retailers-core

## Purpose
Core retailer domain on `retailers_v2`: register/upsert (KYC Save & Verify), list/search, counts, timeline, detail,
update, VIP, pipeline state/cycles, order webhooks, app-version sync, duplicate-id repair, nightly jobs. Also the
KSR app's lead hooks (`retailer`), phone->retailer scope guard, legacy `retailers` writes, contacts schema.

## Entry points (all `/api/v2`)
- `retailers`: POST `lead`, POST `register` (Public + PublicWriteGuard + Scoped); POST `upsert` (Scoped); GET `/`,
  `pipeline-stage-counts`, `bucket-summary`, `stats`, `timeline`, `:id` (scoped in service); PATCH `lead/update` (phone),
  PATCH `:id`, `:id/vip` (retailerAny); POST `app-version/sync-all`, `:id/app-version/sync`; GET `:id/audit-history`,
  `:id/pipeline`, `:id/pipeline/cycles`; PATCH `:id/pipeline`
  - Webhooks (Public + SsoOrWebhookSecretGuard): POST `vip/recalculate`, `webhook/order-delivered`, `webhook/order-shipped`
  - Maintenance (Public + MaintenanceGuard): POST `pipeline/sweep-inactive`, `pipeline/reconcile-all`,
    `kyc-agent/normalize-date`, `:id/pipeline/reconcile`; GET `pipeline/reconcile-all/progress`
- `pipeline-cycles` (Scoped): POST `/`, GET `/`, GET/PATCH/DELETE `:id`
- `retailers/duplicate-ids` (Public + MaintenanceGuard): GET `/`, POST `repair`, POST `unique-index`
- `retailer` (singular): POST `/`, PATCH `:contact` (Public + PublicWriteGuard + Scoped, newOk)
- `legacy-update`: PATCH `retailers/:pii_id` (Scoped pii)
- Socket `/reconcile` (room `reconcile`; `reconcile:start|progress|done|error`; no handshake auth)
- Crons: `pipeline-scheduler.service.ts` (`PIPELINE_SWEEP_CRON`, needs `PIPELINE_SWEEP_ENABLED=true`),
  `order-info-recompute.service.ts` (`ORDER_INFO_CRON`, `ORDER_INFO_RECOMPUTE`, `job_locks` lock)

## Key files
- `src/modules/retailers/`: `retailers.service.ts` (~9.1k lines), `retailers.controller.ts`, `pipeline-cycles.controller.ts`,
  `retailer-id-repair.{controller,service}.ts`, `order-info-recompute.service.ts`, `pipeline-scheduler.service.ts`,
  `reconcile.gateway.ts`, `vip.{module,service}.ts`, `retailer-lead.service.ts`, `schemas/`, `utils/` (lqs, pipeline rules, profile-score, vip-tiers)
- `src/modules/retailer/retailer.service.ts` (class `RetailerLeadService`, ~2.2k lines), `documents-meta.ts`
- `src/modules/retailer-scope/` (@Global RetailerScopeGuard, `@CurrentRetailer()`), `src/modules/legacy-update/`
- `src/modules/contacts/schemas/contact.schema.ts` (schema only; no module)

## Data
- W: `retailers_v2`, `piis`, `addresses`, `retailer_pipeline_cycles`, `log_foro`, `leads_v2` (role mirror, app_version),
  `app_counters` (PI/KP/ADDR), `job_locks`, legacy `retailers` (is_verified mirror, legacy-update), `alerts`, `contacts_v2.profile`;
  repair cascade of `retailer_id` across pipelines/cycles/alerts/groups/lost_feedback/orders_v2/calls_v2/skp_owners/retailers (per run UNVERIFIED)
- R: `retailevents`, `calls_v2`, `contacts_v2`, `notes_v2`, `agents_v2`, `status`, `orders_v2` + legacy `orders`, `leads_v2`

## Depends on
verification-kyc (DocumentVerifications, Verification, Addresses), pipeline, lead-assignment (forwardRef; FO/default
owner assign), ops/netcore, VipModule, auth; common orders-v2, Firebase, phone-search, lqs-score, lead-ownership,
address-values, access.

## Used by
- Modules: lead-assignment (VipService, LegacyUpdateService), retailer-app + orders-commerce (RetailerScopeGuard/Service).
- RVP: `/retailers`, `/retailers/:id`, `/:id/audit-history`, `/lead/update`, `/timeline`, `/upsert`
  (`src/services/backendApi.ts`, `src/redux/api/kycModuleApi.ts`, `src/components/profiled/useProfiledLead.ts`).
- PORTAL: `/retailers`, `/:id`, `/register`, `/pipeline-stage-counts`, `/timeline`, `/:id/pipeline(/cycles)`,
  `/:id/app-version/sync` (`src/redux_v2/apis/retailers_api.service.ts`, `useCustomerLookup.ts`).
- ADMIN: `/retailers`, `/:id`, `/timeline` (`src/redux/buketMaster.v2.api.ts`).
- No FE consumer: `retailer`, `legacy-update`, webhooks, maintenance, pipeline-cycles, duplicate-ids: likely KSR app,
  Stockship/ko-sales webhooks and ops scripts (UNVERIFIED).

## External services
Firestore `Retailer Users` mirror (`APP_USER_MIRROR`); ko-sales `{KO_SALES_BACKEND_URL}/leads/upsert` and
`/leads/by-phone/{10}` (header `x-webhook-secret`); Netcore via VerificationService; Slack via lead-assignment.

## Gotchas
- **Hard-coded fallback webhook secret** in `retailer/retailer.service.ts` and `retailers/retailer-lead.service.ts`.
- Two different classes named `RetailerLeadService` (retailer/ vs retailers/). `LEAD_V2_ENABLED` gates the retailers one.
- Owner and kyc_agent are NOT on `retailers_v2`; derived from `leads_v2`. `role` only on `leads_v2`.
- `app_counters` drift; `retailer_id` not unique; `allocateId` retries 25x. Use duplicate-ids tooling before a unique index.
- Upsert returns an `UpsertCheck` stage trace (upsert_core -> approve_kyc -> owner assign -> netcore).
- Delivered = status 15, source Retailer. Search lookups capped ~2 s; heavy work gated (12 of 20 pool connections).
- legacy-update: explicit `is_verified:false` is ignored (never un-verifies).

Last verified: 2026-10-07 @ 278fe58 (kartik)
