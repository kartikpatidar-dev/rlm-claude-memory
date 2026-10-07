# retailer-events-alerts

## Purpose
Append-only retailer app/telemetry events (`retailevents`) with timeline and CH-sync staging; durable alert feed for
agents (e.g. `app_downloaded` posted by ko-sales); authenticated per-user realtime notifications socket.
Nest modules: retailer-events, retailer-alerts, notifications.

## Entry points (all `/api/v2`)
- `retailer-events`: POST `/` (**`@Public()`** + OptionalSsoAuthGuard), GET `/`, `timeline`, `event-names`,
  `recent/:pii_id`, `:id`; PATCH `:id`; DELETE `:id` (hard; `assertMayOpenRecord`)
- `retailer-alerts`: POST `/` (`@AllowWebhook`, idempotent for app_downloaded), GET `/`, GET `unread-count`,
  PATCH `read`, PATCH `read-all`
- Socket `/notifications`: SSO token verified on handshake; room `user:<email>`; emits `auth:ok`, `auth:error`,
  `event:created`, requested-cart status event (`REQUESTED_CART_STATUS_EVENT`)

## Key files
- `src/modules/retailer-events/{retailer-events.service.ts (~1.6k lines), retailer-events-staging.service.ts, timeline.presenter.ts, schemas/}`
- `src/modules/retailer-alerts/{retailer-alerts.service.ts, schemas/retailer-alert.schema.ts}`
- `src/modules/notifications/{notifications.gateway.ts, notifications.service.ts}` (no controller)

## Data
- R/W `retailevents` (boot indexes), `retailers_alerts` (unique partial {pii_id, alert_type} for app_downloaded)
- R: `retailers_v2`, `piis`, `contacts_v2`, `addresses`, `cases`, `products`, `dynamicdatas`
  (`ch_sync.retailer_events.threshold_rows`, cached 60 s), `leads_v2` (owner), `agents_v2`

## Depends on
agents (resolveAgent/resolveTeam), auth (JwksService), common lead-ownership, lqs-score, access, raw-db,
`utils/{recent,in-flight,gate}`, `search/retailer-search.util`.

## Used by
- Modules: orders-commerce/requested-carts (NotificationsService), analytics/retailer-admin (writes `retailevents` via `rps-event`).
- RVP: `/retailer-alerts*` (`src/hooks/useRetailerAlerts.ts`), `/retailer-events/recent/:pii_id`
  (`src/redux/api/kycModuleApi.ts`), socket `/notifications` (`src/hooks/useEventNotificationSocket.ts`).
- PORTAL: `/retailer-events`, `/:id`, `/recent/:pii_id` (`redux_v2/apis/retailer_events_api.service.ts`), socket
  `/notifications` (`src/hooks/useEventNotificationSocket.ts`).
- ADMIN: none found. POST `/retailer-events` likely from the KSR app; POST `/retailer-alerts` from ko-sales (UNVERIFIED).

## External services
Supabase CH-sync staging (`public.retailer_events`; `CH_SYNC_SUPABASE_URL`, `CH_SYNC_SUPABASE_SERVICE_ROLE_KEY`);
Stockship forced flush to ClickHouse above threshold (`STOCKSHIP_V3_BASE_URL`, `CRON_X_API_KEY`,
`CH_SYNC_RETAILER_EVENTS_THRESHOLD_ROWS` default 50000, `CH_SYNC_RETAILER_EVENTS_COUNT_EVERY` default 500).
Socket allowlist `SOCKET_NOTIFY_EVENTS`; Redis adapter if `SOCKET_REDIS_URL`.

## Gotchas
- Staging and notifications are fire-and-forget/fail-soft; without CH_SYNC config staging is a no-op.
- `mdrId` now holds the phone. Open POST accepted because payload is telemetry.
- Perf caps: list grouping <= 40 s, scope <= 3000 retailers, short caches (15-30 s).
- Alerts admin roles come from the token `user_role` (USR-1000/1001/1002), unlike bug-reports (USR-1000 only).
  Feed polled every 30 s by 3 RVP components; ETag/fingerprint; "unread" = `{$in:[false,null]}`.
- Without Redis adapter, notifications only reach sockets on the emitting worker.
- `docs/rlm-retailer-events-integration.md` is referenced in comments but missing.

Last verified: 2026-10-07 @ 278fe58 (kartik)
