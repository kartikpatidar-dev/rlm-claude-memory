# verification-kyc

## Purpose
KYC approve/reject and lead-lost; per-attempt document verification outcomes and KYC signed URLs; reviewer
document rejections; PII record read/patch; retailer addresses (CRUD + full sync, Firestore link).
Nest modules: verification, document-verifications, document-rejections, pii, addresses.

## Entry points (all `/api/v2`)
- `verification`: POST `approve-kyc/:id`, POST `reject-kyc/:id` (Scoped retailerAny), POST `lead-lost` (Scoped phone)
- `document-verifications`: POST `/`, GET `/` (Scoped pii), GET `summary` (SSO only), GET `by-pii/:pii_id`,
  `by-pii/:pii_id/:document_type`, `by-pii/:pii_id/:document_type/history` (Scoped)
- `document-rejections`: POST `/`, GET `/` (Scoped pii), GET `summary` (SSO only), GET `by-pii/:pii_id`, `by-pii/:pii_id/:label`
- `pii`: GET/PATCH `:id` (Scoped piiAny), POST `:id/addresses`, PATCH/DELETE `:id/addresses/:address_id`
- `addresses`: POST `/`, PUT `sync` (+ `@AllowWebhook`, ko-sales / RVP server-to-server), GET `by-pii/:pii_id`,
  GET/PATCH/DELETE `:id` (all Scoped; DELETE is hard)

## Key files
- `src/modules/verification/verification.service.ts`
- `src/modules/document-verifications/{document-verifications.service.ts, kyc-signed-url.service.ts, schemas/}`
- `src/modules/document-rejections/{document-rejections.service.ts, schemas/}`
- `src/modules/pii/{pii.service.ts, schemas/pii.schema.ts}` (Pii schema shared by many modules)
- `src/modules/addresses/{addresses.service.ts (~1.1k lines), pincode-check.service.ts, schemas/address.schema.ts}`

## Data
- W: `retailers_v2` (is_verified, approval_date, write-once kyc_agent, updated_data, lost -> pipeline_info, has_address,
  profile_score), `leads_v2` (is_kyc, contact_profile), `contacts_v2.profile`, `notes_v2` (audit notes via NotesService),
  `piis` (patch, `addresses[]`), `addresses`, `document_verifications`, `document_rejections`, `app_counters` (addresses)
- R: `piis`, `agents_v2`, `leads_v2`, `pincode_map_v2` (cached 6 h)

## Depends on
notes (NotesService), ops/netcore (NetcoreService); pii -> document-verifications (KycSignedUrlService) + addresses;
document-rejections -> document-verifications; addresses -> Pii/Retailer schemas, `retailers/utils/profile-score`;
common raw-db, Firebase, access.

## Used by
- Modules: retailers-core (VerificationService, DocumentVerificationsService, KycSignedUrlService, AddressesService),
  analytics/retailer-admin (`POST /retailer-admin/lost` -> markLeadLost), retailer (singular) (addresses sync, doc services).
- RVP: `/verification/approve-kyc|reject-kyc/:id`, `/document-rejections(+by-pii)` (`src/services/backendApi.ts`),
  `/document-verifications/by-pii/:pii_id` (`src/components/profiled/documentVerifications.ts`).
- PORTAL: `/verification/*` (`redux_v2/apis/verification_api.service.ts`), `/addresses*` (`addresses_api.service.ts`),
  `/pii/:id` (`src/redux/api/contactsSlice.ts`).
- ADMIN: none found.

## External services
Firestore `Retailer Users` (is_verified mirror, address id linking); Firebase Storage V4 signed URLs
(`KYC_SIGNED_URLS`, `KYC_SIGNED_URL_BUCKETS`); Netcore `Kyc_verification_completed` + account-manager attributes.
Env: `ADDRESS_PINCODE_CHECK` (off|warn|enforce).

## Gotchas
- `kyc_agent` is write-once, kept on reject. `:id` resolves `_id`, `retailer_id` or `pii_id`.
- Secondary writes (Firestore, contact profile, Netcore) are fail-soft; no rollback.
- Addresses: `is_active` absent on ~98% of legacy docs -> query `$ne:false`; by-pii returns archived rows too, clients
  must filter before `/sync` or archived rows get reactivated; canonical fields `address1/2/3`, `zipcode`, `label`.
- document_verifications: TTL on `expire_at` (non-verified ~90 days); `recordIfChanged` avoids a row per app save.
- document_rejections: 1-minute duplicate window; strict ISO dates; date-only = IST day.
- PII `documents` patch is additive (dotted `$set`); `pii_id`/`phone_number` not patchable.
- Signing only when the stored token matches the file's own download token.

Last verified: 2026-10-07 @ 278fe58 (kartik)
