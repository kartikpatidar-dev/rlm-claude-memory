# layout-shell

**Purpose:** App shell for every protected page: routing, sidebars, header (search, notification bell, session widget),
global widgets, stale-bundle / agent-app-version guard.

**Entry points:** `src/App.tsx` (provider tree + all routes), `src/components/layout/MainLayout.tsx`.

**Key files:** `src/components/layout/` (MainLayout, AgentSidebar, FMSidebar, AppHeader, EdgeRailToggle ...),
`src/components/shared/PlatformVersionAlert.tsx`, `src/services/agentAppStatus.ts`, `src/hooks/useAgentAppStatus.ts`, `src/lib/soonModules.ts`.

**Data:** none directly. Mounts `ProfiledDraftsLauncher` (reads drafts, see profiled / lead-detail-legacy).

**Depends on:** auth-session (session, role), notifications (EventNotificationProvider + popup, bell), call-voip (CallWidget, VoipStatusBar,
VoiceIssueReporter, GlobalPendingDisposition), progressive-calling (GlobalProgressiveIndicator), whatsapp (WhatsAppLauncher), profiled (drafts launcher).
**Used by:** all pages.

**External services / endpoints:**
- CallerApp (VITE_CALL_API_URL): `GET /app/agent/:email`, `POST /app/version-check` (PlatformVersionAlert; VITE_APP_VERSION,
  VITE_VERSION_CHECK_INTERVAL_MIN, VITE_VERSION_TICKET_URL, VITE_VARTALAP_APK_URL).
- rlm-backend-nest: `GET /retailer-alerts/unread-count` (badge, via hooks/useRetailerAlerts — see notifications).
- HRMS: session widget / attendance panel (VITE_SHOW_SESSION_WIDGET) — see auth-session endpoints.

**Gotchas:**
- Manager tree (`isManager`) is NOT wrapped in ProgressiveCallingProvider; agent tree is.
- FMSidebar links `/manager/ask-katyayani` -> no route (404). Many FM items badged "Coming Soon".
- AgentSidebar hides `/dialer` unless `isVoip`; "Soon" items hidden for HIDE_SOON_ROLES.
- AppHeader global search contains hard-coded mock entries.
- `components/layout/AppSidebar.tsx` is dead; `WhatsNewDialog` import commented out.
- `/kyc-module*` routes only exist when `VITE_KYC_SHOW==='true'` (manager detail/edit always).

Last verified: 2026-10-07 @ 6e2113d (kartik)
