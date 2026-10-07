# notifications

**Purpose:** In-app notifications (ko-sales socket), retailer-event popups and retailer alerts (nest), utils notifications list, bell badge.

**Entry points:** `/notifications` (agent) and `/manager/notifications` pages; global `EventNotificationPopup` (MainLayout); header bell.

**Key files:** `src/contexts/NotificationContext.tsx`, `src/contexts/EventNotificationContext.tsx`, `src/hooks/useNotificationSocket.ts`,
`src/hooks/useEventNotificationSocket.ts`, `src/hooks/useRetailerAlerts.ts`, `src/hooks/useUtilitiesNotifications.ts`,
`src/lib/notification-cache.ts`, `src/lib/notification-meta.ts`, `src/components/notifications/`.

**Data:** localStorage notification cache. (Supabase `notifications` only via legacy hooks/supabase/useNotifications.)

**Depends on:** auth-session, lead-detail-legacy (`notification-meta` links `/lead/:id`).
**Used by:** layout-shell (providers, popup, bell/badge in AgentSidebar + AppHeader).

**External services / endpoints:**
- rlm-backend-nest: `GET /retailer-alerts?{params}`, `GET /retailer-alerts/unread-count?{params}`, `PATCH /retailer-alerts/read`,
  `PATCH /retailer-alerts/read-all`; socket.io `{nest origin}/notifications` namespace (or VITE_NEST_V2_NOTIFICATION_SOCKET_URL):
  `auth:ok`, `auth:error`, `event:created`.
- ko-sales socket.io `/ws/notifications`: `notification.new`.
- utils (no auth header): `GET /notifications`, `GET /notifications/stats`, `PATCH /notifications/:id/read`, `PATCH /notifications/read-all`.

**Gotchas:**
- Three notification sources coexist (ko-sales socket, nest alerts/socket, utils list). `hooks/useAppNotifications.ts` is dead.
- NEST socket URL fallback derives from VITE_NEST_V2_URL origin (fallback localhost:4001 if unset).

Last verified: 2026-10-07 @ 6e2113d (kartik)
