# call-voip

**Purpose:** Placing and controlling calls (CallerApp mobile dialer or JsSIP WebRTC softphone), live call status, global call bar,
blocking dispositions, dialer page, voice-issue reports, recordings.

**Entry points:** global `CallWidget` (in MainLayout); `/dialer` -> `src/pages/agent/Dialer.tsx` (VoIP agents only);
`/events/:eventId/call` (CallScreen, legacy mock); `/dev/call-preview` (DEV only).

**Key files:** `src/lib/callerapp.ts` (**do not modify without explicit user permission**), `src/hooks/useVoipEngine.ts` (JsSIP; mounted only
by CallWidget), `src/hooks/useCallStatus.ts` (RTDB listener), `src/hooks/useActiveCall.ts`, `src/hooks/usePendingDisposition.ts` (+ test),
`src/hooks/useCallService.ts`, `src/components/call/` (CallWidget, DispositionDialog, PendingDispositionBar, GlobalPendingDisposition,
VoipStatusBar, VoiceIssueReporter, IncomingCallModal, ActiveCallBar, CallWorkspaceDrawer, RetailerTimeline/V2, callFlags + test).

**Data:** Supabase `voice_issue_reports` (write). Firebase RTDB `calls/{uuid}`, `calls`, `agents/{topic}`.

**Depends on:** auth-session (`isVoip`, extension, email), profiled (CallWidget navigates to `/profiled?leadId=` on connect).
**Used by:** layout-shell, my-leads, profiled, lead-detail-legacy, kyc-module, progressive-calling.

**External services / endpoints:**
- CallerApp (VITE_CALL_API_URL): `POST /send-single-call`, `POST /call-control` (call_end | mute_toggle | speaker_toggle | call_pick).
- JsSIP: WSS VITE_VOIP_WS_URL, `sip:{extension}@{VITE_VOIP_SIP_DOMAIN}`, VITE_TURN_URL/USER/PASS, VITE_SIP_PASSWORD (or localStorage `voipSipPassword`).
- ko-sales: `GET /calls?…`, `GET /calls/pii/:piiId`, `PATCH /calls/uuid/:uuid/disposition`, `POST /calls/dispositions`,
  `GET /leads/find-by-phone?phone=`, `GET /query-flow/config`, `GET /pii/:piiId`, `GET /leads/:id`.
- rlm-backend-nest: `POST /notes` (call notes in CallWidget), `GET /retailers/timeline` (RetailerTimelineV2, CallWorkspaceDrawer).
- Recording API (VITE_RECORDING_API_URL): `GET /call/search`.

**Gotchas:**
- `initiate_call`: if localStorage `isVoip==='true'` -> window event `voip-call-request` (JsSIP); else CallerApp + events `call-initiated`, `call-uuid-received`.
- `useCallStatus.hasReceivedDataRef`: a null RTDB snapshot ends the call (`node_deleted`) only if data was seen first (node doesn't exist yet right after dialing).
- `end_call_verified` re-checks RTDB after 4s and force-closes the agent's own stranded node.
- Pending disposition is blocking; don't double-disposition progressive calls.
- Order dialogs (CreateOrderDialog/OrderCreationDialog/EnhancedOrderFlow) use mockData.
- SIP/TURN creds end up in the browser bundle.

Last verified: 2026-10-07 @ 6e2113d (kartik)
