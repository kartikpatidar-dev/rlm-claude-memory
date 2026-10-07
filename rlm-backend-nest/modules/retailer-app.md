# retailer-app

## Purpose
Backend for the retailer (KSR, Flutter) app features: "My Farmers" customer book, retailer inventory and farmer
sales bills, profit calculator per SKU, and server-side file upload to Firebase Storage.
Nest modules: farmers, inventory, profit-calculator, files.

## Entry points (all `/api/v2`)
- `farmers` (class RetailerScopeGuard; retailer from `phone`): GET `/`, `stats`; POST `/`, `delete` (soft), `import-contacts`; PUT `:id`
- `inventory` (class RetailerScopeGuard): GET/POST `/`, PUT `:id`, POST `delete` (soft), POST/GET `sales`,
  PUT `sales/:id/received`, GET `stats`
- `profit-calculator` (class RetailerScopeGuard): POST `/` (upsert {phone, sku}), GET `/` (paginated)
- `files`: POST `/` (multipart `file`, `owner_type` retailer|lead|pc-request, `owner_id`, `purpose`; scope checked in handler)

## Key files
- `src/modules/farmers/{controllers,services,repositories,schemas}/`, `src/modules/inventory/{controllers,services,repositories,schemas}/`
- `src/modules/profit-calculator/{controllers,services,repositories,schemas}/`
- `src/modules/files/{files.service.ts, upload-file.interceptor.ts}`; guard `src/modules/retailer-scope/`

## Data
- R/W `retailer_farmers`, `retailer_inventory`, `retailer_inventory_sales`, `retailer_profits` (unique phone+sku)
- R `retailers_v2`, `piis` (via RetailerScopeGuard), `leads_v2` (files: lead id -> pii_id)

## Depends on
retailers-core (RetailerScopeModule, global); inventory -> farmers (FarmersRepository); files -> Firebase, access
(RetailerAccessService), raw-db.

## Used by
- Frontends: no consumer found in RVP/portal/admin repos — likely the KSR retailer app (farmers, inventory,
  profit-calculator) and RVP/PORTAL migration branches (files) UNVERIFIED.

## External services
Firebase Storage (`FIREBASE_STORAGE_BUCKET`): paths `retailers/{owner_id}/{purpose}_{unixMs}.{ext}`,
`pc-requests/{owner_id}/{purpose}/{unixMs}-{name}`; download-token metadata kept compatible with `getDownloadURL()`.
Env: `FILES_MAX_MB` (default 8; 413 above).

## Gotchas
- Phone keys normalised to bare 10 digits (`retailer_phone`). Exact error messages are a Flutter contract (`docs/my_farmers_backend.md`
  referenced; not in `docs/`, UNVERIFIED).
- Repository comments name `farmers` / `inventory_items`; real collections are `retailer_farmers` / `retailer_inventory`.
- Stock decremented atomically, floored at 0; farmer aggregates fire-and-forget; `markReceived` only from DUE.
- Files: mime sniffed from magic bytes (jpeg/png/webp/pdf); a lead without PII is allowed; paths never logged (contain phone).

Last verified: 2026-10-07 @ 278fe58 (kartik)
