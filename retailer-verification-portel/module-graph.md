# Module graph — retailer-verification-portel
Last verified: 2026-10-07 @ 6e2113d (kartik)

Arrow `A --> B` = A depends on / calls B. Every module also depends on `auth-session` (tokens, role) and is rendered inside
`layout-shell`; only the meaningful edges are drawn. Rounded = FE module, cylinder = backend/data store, hexagon = external app.

```mermaid
flowchart LR
  auth[auth-session]
  shell[layout-shell]
  myleads[my-leads]
  profiled[profiled]
  legacy[lead-detail-legacy]
  kycapp[kyc-approval]
  kycmod[kyc-module]
  prog[progressive-calling]
  call[call-voip]
  transfer[transfer]
  wa[whatsapp]
  notif[notifications]
  perf[agent-performance]
  mgr[manager-reporting]
  targets[targets-incentives]
  learn[learning-community]
  mock[legacy-mock-pages]

  KOS[(ko-sales-backend)]
  NEST[(rlm-backend-nest v2)]
  UTILS[(utils API)]
  SALESOP[(sales-operation)]
  SUPA[(Supabase)]
  FB[(Firebase)]
  CALLER{{CallerApp}}
  VOIP{{JsSIP / SIP WSS}}
  HRMS[(HRMS)]
  SAATHI[(Saathi / CropTalk)]
  SSO[(SSO)]
  STOCK[(Stockship)]
  EMBED{{iframes: agri-sales-hub / ticketing / b2bsales}}

  auth -->|login| KOS
  auth -->|verify-otp, refresh| SSO
  auth -->|clock-in/out| HRMS
  shell -->|session| auth
  shell --> notif
  shell --> call
  shell --> wa
  shell --> prog
  shell -->|drafts launcher| profiled
  shell -->|app version| CALLER
  myleads --> KOS
  myleads --> UTILS
  myleads -->|dial| call
  myleads --> prog
  myleads --> wa
  myleads -->|open lead| profiled
  myleads -->|board links| legacy
  profiled --> KOS
  profiled -->|approve-kyc, upsert, notes, docs| NEST
  profiled --> SALESOP
  profiled -->|FAQs, drafts| SUPA
  profiled -->|Retailer Users| FB
  profiled -->|dial| call
  profiled --> transfer
  profiled --> wa
  legacy --> KOS
  legacy -->|upsert| NEST
  legacy --> UTILS
  legacy --> SUPA
  legacy --> FB
  legacy --> STOCK
  legacy -->|dial| call
  kycapp --> KOS
  kycapp -->|approve-kyc / reject-kyc| NEST
  kycapp --> UTILS
  kycapp -->|states/districts| SUPA
  kycapp -->|links| legacy
  kycmod --> NEST
  kycmod --> UTILS
  kycmod --> FB
  kycmod -->|dial| call
  prog -->|queue, /ws/queue| KOS
  prog -->|dial| call
  prog -->|navigates on connect| profiled
  prog --> FB
  call -->|send-single-call| CALLER
  call -->|calls/*, agents/*| FB
  call -->|isVoip| VOIP
  call -->|dispositions| KOS
  call -->|notes| NEST
  call -->|voice_issue_reports| SUPA
  call -->|navigates on connect| profiled
  transfer --> SALESOP
  transfer --> KOS
  wa --> SAATHI
  wa -->|/messages| KOS
  wa --> SUPA
  notif -->|/ws/notifications| KOS
  notif -->|retailer-alerts, socket| NEST
  notif --> UTILS
  notif -->|links| legacy
  perf --> KOS
  perf --> UTILS
  perf --> SALESOP
  perf --> HRMS
  perf --> SUPA
  mgr --> KOS
  mgr --> UTILS
  mgr --> HRMS
  mgr --> SUPA
  mgr -->|agents/*| FB
  mgr --> EMBED
  targets --> KOS
  targets --> SUPA
  learn --> KOS
  learn --> SALESOP
  learn --> HRMS
  learn --> SUPA
  learn --> EMBED
  mock --> SUPA
```

| Module | Depends on | Used by | Backends / tables touched |
|---|---|---|---|
| auth-session | — | all modules | KOS `/auth/login`; SSO; HRMS attendance; localStorage session keys |
| layout-shell | auth-session, notifications, call-voip, whatsapp, progressive-calling, profiled | all pages | CallerApp `/app/*`; NEST `/retailer-alerts/unread-count` (via notifications) |
| my-leads | call-voip, progressive-calling, whatsapp, profiled, lead-detail-legacy | layout-shell (nav) | KOS `/leads`, `/agents/my-scope`; UTILS `/kyc/agent_v2` |
| profiled | call-voip, transfer, whatsapp | my-leads, progressive-calling, call-voip, transfer, layout-shell | KOS leads/pii/pipelines/calls/tags; NEST retailers/notes/document-*; SALESOP transfer; Supabase query_master, query_usage_logs (FAQs), verification_draft_info (drafts launcher); Firestore `Retailer Users` |
| lead-detail-legacy | call-voip | my-leads, notifications, kyc-approval, layout-shell (drafts) | KOS; NEST `/retailers/upsert`; UTILS `/rlm/*`, `/verification/retailers/:id/update`; Stockship; Supabase verification_draft_info, query_*; Firebase |
| kyc-approval | lead-detail-legacy | — (FM + agent pages) | KOS `/verification/submissions*`; NEST `/retailers`, approve/reject-kyc; UTILS `/verification/*`; marketing Supabase states/districts |
| kyc-module | call-voip | — | NEST `/retailers*`, `/notes*`, `/retailer-events/recent`; UTILS `/rlm/*`, `/retailer-admin/*`; Firestore + Storage |
| progressive-calling | call-voip, profiled | layout-shell, my-leads | KOS `/leads/progressive*`, `/calls*`, `/ws/queue`; RTDB |
| call-voip | profiled | progressive-calling, my-leads, profiled, lead-detail-legacy, kyc-module, layout-shell | CallerApp; RTDB `calls`/`agents`; KOS `/calls*`; NEST `POST /notes`; Supabase voice_issue_reports; JsSIP |
| transfer | profiled | profiled | SALESOP `/verification-transfer/*`; KOS `/leads/lookup`, `/agents/all` |
| whatsapp | — | layout-shell, my-leads, profiled | Saathi REST + WS; KOS `/messages/*`, `/templates`; Supabase messages, whatsapp_conversations |
| notifications | lead-detail-legacy (links) | layout-shell | KOS `/ws/notifications`; NEST `/retailer-alerts*` + socket; UTILS `/notifications*` |
| agent-performance | — | — | KOS stats; UTILS `/verification/rlm/*`; SALESOP audit-list; HRMS RPC; Supabase targets, certificates |
| manager-reporting | — | — | KOS `/statistics/*`, `/leads` assign/upsert; UTILS rlm stats; HRMS; Supabase attendance project + bandwidth_settings; RTDB `agents`; iframes |
| targets-incentives | — | — | KOS `/level-config`, `/wallet*`, `/cs/audits*`; Supabase monthly_targets, agent_target_overrides, tenure_targets, target_change_logs, kpi_data_view |
| learning-community | — | — | KOS `/agronomy/*`, `/crops`, `/slack/send-dm`; SALESOP agronomy; HRMS skills/grievances; Supabase training/forum/ideas/grievances/onboarding/attendance tables; iframes |
| legacy-mock-pages | — | — | Supabase agents, orders, retailers, rps_tasks, products, coupons, ivr_calls, app_events; `src/data/mockData.ts` |
