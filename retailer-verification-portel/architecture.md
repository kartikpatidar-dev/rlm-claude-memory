# Architecture — retailer-verification-portel

Last verified: 2026-10-07 @ 6e2113d (kartik)

## Layers
```
pages (src/pages/agent, src/pages/manager)  +  global widgets (src/components/layout, components/call, ...)
   |
state/data:  React Contexts (5)  |  Redux store: filters slice (persisted) + 10 RTK Query APIs  |  TanStack Query (Supabase hooks, a few REST hooks)
   |                                      |  local UI state: hooks/usePersistedState (localStorage), hooks/useIdbPersistedState
services / integrations:  services/backendApi.ts (fetchBackend), services/managerApi.ts, services/saathiApi.ts, services/ssoAuth.ts,
   |                      integrations/rlm/*, integrations/supabase/*, lib/callerapp.ts, lib/firebase.ts, hooks/useVoipEngine.ts
   v
backends:  ko-sales-backend | rlm-backend-nest v2 | utils server | sales-operation | SSO | CallerApp | HRMS | Saathi | Stockship
           + Supabase (3 projects) + Firebase (RTDB/Firestore/Storage) directly from the browser
```

## Provider tree (src/main.tsx, src/App.tsx)
`Provider(store)` -> `PersistGate` -> `QueryClientProvider` -> `AuthProvider` -> `QueueSocketProvider` -> `BrowserRouter` ->
`TooltipProvider` (+ Toaster, Sonner) -> `NotificationProvider` -> `PlatformVersionAlert` -> `AppRoutes`.
`ProtectedRoutes` runs `useAutoLogout`, fires `useGetRlmAgentsQuery` (utils `GET /kyc/agent_v2`, cached in localStorage `rlm_agents`)
on every protected render, then renders the **manager tree** (`isManager`) or the **agent tree** (wrapped in `ProgressiveCallingProvider`).
`MainLayout` adds `EventNotificationProvider` + popup, FMSidebar/AgentSidebar, AppHeader, CallWidget, VoipStatusBar, VoiceIssueReporter,
GlobalPendingDisposition + GlobalProgressiveIndicator (agents), WhatsAppLauncher, ProfiledDraftsLauncher (agents), EdgeRailToggle.

## Multi-backend reality
| Env var | Service | Used for | Auth header |
|---|---|---|---|
| VITE_NEST_V2_URL (base includes `/api/v2`) | rlm-backend-nest v2 (api.retailers.ko-tech.in) | retailers/KYC module, approve/reject KYC, notes, document rejections/verifications, retailer alerts, events socket | Bearer `sso_token` (fallback `ssoAccessToken`) |
| VITE_BACKEND_URL (`.../api/v1`) | ko-sales-backend (api.b2bsales.ko-tech.in) | login, leads, PII/docs, calls/dispositions, progressive queue, messages, tags, statistics, wallet, audits, agronomy, sockets | `fetchBackend`: Bearer `ssoAccessToken` only; RTK slices prefer `sso_token` |
| VITE_BASE_URL | "utils"/verification server (utils.ko-tech.in); serving repo UNVERIFIED | `/verification/*`, `/rlm/*`, `/retailer-admin/*`, `/kyc/agent_v2`, `/notifications`, `/blacklist`, `/pincode` | Bearer `sso_token` mostly; some none |
| VITE_SALES_OPERATION_API_URL | sales-operation backend (FastAPI per docs) | agronomy audit list/tests, verification-transfer | Bearer `sso_token` |
| VITE_SSO_URL | SSO (sso.ko-tech.in) | verify-otp (MFA), refresh | — |
| VITE_CRM_BASE_URL | CRM (api.crm.ko-tech.in) | code exists (`services/crmAuth.ts`), not in active login path | CRM token |
| VITE_CALL_API_URL | CallerApp (api.caller.ko-tech.in) | send-single-call, call-control, agent app status/version | none |
| VITE_RECORDING_API_URL | CRM recording search | `GET /call/search` | none |
| VITE_HRMS_BASE_URL / VITE_HRMS_API_URL (+ host hard-coded in 7 pages) | HRMS (api.hrms.on.ko-tech.in) | clock-in/out, KPI targets, skills, grievances, hierarchy RPC | varies |
| VITE_SAATHI_URL / VITE_SAATHI_WS_URL | Saathi / CropTalk (croptalk.ko-tech.in fallback) | WhatsApp inbox | Saathi token or SSO token + `X-Channel-Id` |
| VITE_STOCKSHIP_URL | Stockship | `POST /retailer` on approval (legacy pages) | — |
| VITE_AGRI_SALES_HUB_URL / VITE_TICKETING_EMBED_URL | agri-sales-hub / customer-success iframes | LiveAgents, WorkflowMaster, LeadBuckets (host hard-coded), Sahiyog | SSO token in query string |
| VITE_SUPABASE_* / VITE_MARKETING_* | Supabase (3 projects) | see database.md | anon; attendance prefers service_role |
| VITE_FIREBASE_* | Firebase | RTDB call status, Firestore `Retailer Users`, Storage | — |

Fallback gotcha: NEST v2 fallback is `http://localhost:4001/api/v2` in some files and the prod host in others — env must be set.

## Realtime
- ko-sales socket.io `/ws/queue` (QueueSocketContext, useQueueSocket, useAdminQueueSocket): `lqs-changed`, `lead-assigned`,
  `admin:session-changed`, `admin:progress-requested`, `admin:progress-report`, emit `agent:progress-report`, ping/pong. Off if `VITE_QUEUE_REALTIME==='false'`.
- ko-sales socket.io `/ws/notifications`: `notification.new` (NotificationContext).
- NEST socket.io `/notifications` namespace: `auth:ok`, `auth:error`, `event:created` (EventNotificationContext).
- Saathi native WebSocket `/ws` (text ping). Firebase RTDB `calls/*`, `agents/*`. Supabase channels: see database.md.

## Calling architecture
- `lib/callerapp.ts` (protected file): `initiate_call` — if localStorage `isVoip==='true'` dispatches window event `voip-call-request`
  (handled by JsSIP in `hooks/useVoipEngine.ts`, mounted only by CallWidget); else `POST {CALLER}/send-single-call` and dispatches
  `call-initiated` / `call-uuid-received`. `call_control` (end/mute/speaker/pick). `end_call_verified` re-checks RTDB after 4s and
  force-closes the agent's own stranded node.
- `hooks/useCallStatus.ts` listens on RTDB `calls/{uuid}` (initiate -> ringing -> on_call -> ended/failed). `hasReceivedDataRef`:
  a null snapshot is only treated as "ended (node_deleted)" if data was seen before — WHY: the node does not exist yet right after
  dialing, so an early null must not end the call; a later deletion means the dialer cleaned up.
- `is_voip` and `extension` come from the ko-sales `/auth/login` agent payload; Dialer page only for VoIP agents.
- Firebase RTDB status: still the source of call status for CallerApp calls at 6e2113d. Commit d83114d made app version come from the
  lead API only, not Firebase. Branch `origin/migration` removes direct Firebase/Supabase (see status.md) — not merged.

## Key decisions and WHY (where known)
- **Profiled is the canonical lead workspace** (`lib/leadWorkspace.ts`: `LEAD_WORKSPACE_PATH='/profiled'`): it replaced KYC Working for
  every lead-driven flow (Working module, dialer, pending disposition); `/kyc-working` still reachable by kycId (resubmit), so
  `isOnLeadWorkspace` accepts both so an agent mid-call is not yanked back to the queue.
- Blocking pending disposition (`hooks/usePendingDisposition.ts`, GlobalPendingDisposition) — agent must disposition before the next call. WHY: UNVERIFIED (presumably data completeness).
- Login via ko-sales `/auth/login` in AuthContext (RTK `authApi` and CRM login unused).
- Redux persist uses IndexedDB (idb-keyval) only for the `filters` slice.

## Known contradictions
1. Old CLAUDE.md says "DB: MongoDB" — FE never touches Mongo; it is behind ko-sales / nest. Supabase is used heavily from the browser.
2. Two notes systems: ko-sales `/notes` + `/notes/pii/:id` (KYCWorking) vs NEST `/notes` + `/notes/by-pii/:id` (Profiled, KYCModuleDetail, CallWidget).
3. `VITE_BASE_URL` used as both "verification API" and "utils" server; RTK default ports differ (3002/3010/3001).
4. Token inconsistency (`ssoAccessToken` vs `sso_token`); several calls send no auth.
5. Deploy: Vercel (vercel.json, CLAUDE.md) vs S3/CloudFront CI on `aws-v4`.
6. HRMS host hard-coded in 7+ pages despite env vars.
7. Three overlapping lead workspaces: `/profiled` (canonical), `/kyc-working`, `/lead/:leadId`.
8. Two WhatsApp stacks: Saathi inbox vs ko-sales `/messages`.
9. Main Supabase client (`integrations/supabase/client.ts`) hard-codes URL/anon key while `sopDataClient.ts` reads env for the SAME project.
