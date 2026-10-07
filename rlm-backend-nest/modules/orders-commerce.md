# orders-commerce

## Purpose
Read-only orders over Stockship's `orders_v2` (answered in the legacy `orders` contract), return/refund lookup,
agent-sent "requested cart" cards mirrored to the retailer app, and Pesticide Certificate (PC) requests in Firestore.
Nest modules: orders, return-refunds, requested-carts, pc-requests.

## Entry points (all `/api/v2`)
- `orders`: GET `/` (Scoped agents), **POST `/` -> 410 Gone**, GET `statuses` (SSO, 5 min cache), GET `by-customer`,
  `retailer-summary` (Scoped pii/contact), `by-retailer/:retailer_id`, `by-pii/:pii_id`, `legacy/:order_id` (SSO only), `:id` (record)
- `return-refunds`: GET `search` (SSO only; `phone` is an ownership check)
- `requested-carts` (class `@AllowWebhook`, Scoped pii/phone/record except `distributor-threshold`): POST `/`, POST `card-sync`,
  GET `history/:pii_id`, `history/by-phone/:phone`, `cart/by-pii/:pii_id`, `cart/by-phone/:phone`; PATCH `by-pii/:pii_id`,
  `by-phone/:phone`; GET `distributor-threshold`, `app-request/by-pii/:pii_id`, `app-request/by-phone/:phone`; POST `withdraw`;
  GET/PATCH/DELETE `:id`; POST `by-pii/:pii_id/status`, `by-phone/:phone/status`, `:id/status`
- `pc-requests`: GET `/` (`@OpenToAll`, scoped in service), GET/PUT `:phone` (Scoped phone)

## Key files
- `src/modules/orders/{orders.service.ts (~1.2k lines), order-outcome.ts, schemas/order.schema.ts}`
- `src/common/orders-v2/` (source, compat, legacy fallback), `src/common/order-status/`
- `src/modules/return-refunds/`, `src/modules/requested-carts/requested-carts.service.ts`, `src/modules/pc-requests/pc-requests.service.ts`

## Data
- orders R: `orders_v2` (+ `$unionWith` legacy `orders`), `status`, `retailers_v2`, `agents_v2`, `products`, `categories` (purpose UNVERIFIED). No writes.
- return-refunds R: `return_refunds`, legacy `orders`, `products(_v2)`, `combos(_v2)`, `bankinfos`
- requested-carts R/W `carts_requests` (partial unique: one pending card per customer), `carts` (raw, no unique index); R `piis`, `agents_v2`
- pc-requests: Mongo R `agents_v2`; Firestore R/W `Retailer Pesticide Certificate`

## Depends on
agents (AgentsService), retailer-events-alerts (NotificationsService), retailers-core (RetailerScopeService),
common orders-v2, order-status, lead-ownership, Firebase, access.

## Used by
- PORTAL: `/orders*` (`redux_v2/apis/orders_api.service.ts`, `retailers_api.service.ts`), `/requested-carts*`
  (`src/lib/salesCartApi.ts`), `/return-refunds/search` (`return_refunds_api.service.ts`).
- ADMIN: `/orders`, `by-customer`, `legacy/:order_id`, `retailer-summary`, `statuses` (`src/redux/orders.v2.api.ts`, `buketMaster.v2.api.ts`).
- RVP: none. pc-requests: no consumer found in RVP/portal/admin repos (PORTAL migration branches; UNVERIFIED).
  requested-carts `card-sync` / webhook calls likely ko-sales (UNVERIFIED).

## External services
Firestore `Retailer Users/{+91phone}/Cart Items/Requested Items`, `Retailer Dynamic Section V2/distributor`
(fallback 20,000 / 40 kg), `Retailer Pesticide Certificate`; Firebase Storage URL validation; Socket.IO via notifications.

## Gotchas
- Orders: legacy numeric status ids, default source `Retailer`; totals exclude merged (12) / split (13); cancelled [10,12,13]; IST.
- Requested-carts failure codes (`RETAILER_NOT_FOUND`, `PENDING_EXISTS`, `REQUEST_CHANGED`, `LINES_REJECTED`, `FIRESTORE`) are a portal contract.
- Firestore calls time out at 20 s. pc-requests: <= 2000 docs filtered in memory, else indexed queries (missing index -> 503 with link).
- return-refunds: every mismatch returns the same 404 (anti-enumeration).

Last verified: 2026-10-07 @ 278fe58 (kartik)
