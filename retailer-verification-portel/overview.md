# Overview — retailer-verification-portel

Last verified: 2026-10-07 @ 6e2113d (kartik)

## What it is
"Verification Portal - Agent" (`index.html` title). Agents call retailer leads, verify identity/KYC documents,
profile them, record dispositions, and transfer leads between verification and KYC teams. Managers (FMs) get
reporting, lead assignment, KYC approval, targets/incentives, call audit, training/onboarding and attendance screens.
Started as a Lovable project (Lovable boilerplate README, `lovable-tagger`, `.lovable/`, Lovable `types.ts`); many
early Lovable pages are still mock (see modules/legacy-mock-pages.md).

## Users and roles (src/contexts/AuthContext.tsx)
- Role code comes from the JWT `user_role` claim.
- ADMIN_ROLES = USR-1000 -> admin. MANAGER_ROLES = USR-1021, USR-1002, USR-1019 -> manager. Anything else -> agent.
- Access gate ALLOWED_ROLES = USR-1000, 1001, 1002, 1012, 1019, 1020, 1021, 1030 + a hard-coded 2-email allow-list.
- USR-1030 forces `agent_category = "retailer_kyc"`.
- Admin/manager can "Switch to Agent" (localStorage `crmRoleView=agent`).
- "Soon" sidebar items hidden for `lib/soonModules.HIDE_SOON_ROLES` (USR-1020/1021/1022/1029/1030).

## Stack
React 18.3, TypeScript, Vite 5 (`@vitejs/plugin-react-swc`), Tailwind 3 + shadcn/ui (Radix), react-router-dom 6,
Redux Toolkit 2 + RTK Query + redux-persist (IndexedDB via idb-keyval), TanStack Query 5, React Context (5),
supabase-js, firebase 12 (RTDB/Firestore/Storage), socket.io-client 4, JsSIP, react-hook-form + zod, recharts,
leaflet, jspdf / pdf-lib / @react-pdf/renderer / html2canvas (certificates), framer-motion, jwt-decode.
Path alias `@` -> `./src`. Package name `vite_react_shadcn_ts`. Lock files: package-lock.json AND bun.lockb.

## Entry points
- `index.html` -> `src/main.tsx` (`<Provider store>` -> `<PersistGate>` -> `<App/>`).
- `src/App.tsx` — provider tree + all routes (manager tree vs agent tree). See architecture.md.
- `src/components/layout/MainLayout.tsx` — shell for every protected page.

## Commands (package.json)
| Command | Does |
|---|---|
| `npm run dev` | vite dev server, port 8005, host `::` |
| `npm run build` | `vite build` (manual chunks: vendor, supabase, redux, jssip, query) |
| `npm run build:dev` | `vite build --mode development` |
| `npm run lint` | `eslint .` |
| `npm run preview` | vite preview |
| `npm test` | `vitest run` (no vitest config; defaults) |

## Env var NAMES (values never recorded here)
- Backends: VITE_NEST_V2_URL, VITE_NEST_V2_NOTIFICATION_SOCKET_URL, VITE_BACKEND_URL, VITE_BASE_URL, VITE_SALES_OPERATION_API_URL,
  VITE_SSO_URL, VITE_CRM_BASE_URL, VITE_CALL_API_URL, VITE_RECORDING_API_URL, VITE_HRMS_BASE_URL, VITE_HRMS_API_URL,
  VITE_SAATHI_URL, VITE_SAATHI_WS_URL, VITE_STOCKSHIP_URL, VITE_AGRI_SALES_HUB_URL, VITE_TICKETING_EMBED_URL,
  VITE_SLACK_DM_URL, VITE_SLACK_SESSION_MSG_TEMPLATE
- VoIP: VITE_VOIP_WS_URL, VITE_VOIP_SIP_DOMAIN, VITE_TURN_URL, VITE_TURN_USER, VITE_TURN_PASS, VITE_SIP_PASSWORD
- Supabase: VITE_SUPABASE_URL, VITE_SUPABASE_PUBLISHABLE_KEY, VITE_SUPABASE_ATTENDANCE_URL, VITE_SUPABASE_ATTENDANCE_SERVICE_ROLE,
  VITE_SUPABASE_ATTENDANCE_ANON_KEY, VITE_MARKETING_SUPABASE_URL, VITE_MARKETING_SUPABASE_KEY
- Firebase: VITE_FIREBASE_{API_KEY, AUTH_DOMAIN, DATABASE_URL, PROJECT_ID, STORAGE_BUCKET, MESSAGING_SENDER_ID, APP_ID}
- Feature flags: VITE_TEST_MODE (test phone + **OTP/MFA bypass at login**), VITE_KYC_SHOW, VITE_KYC_LOCK, VITE_KYC_ROLE,
  VITE_CONDITION_ROLE, VITE_V4_HIDE, VITE_OUTCOME_LOCK, VITE_SINGLE_CALL_ALLOWED, VITE_SHOW_PIPELINE_TABS, VITE_SHOW_LEAD_BOARD,
  VITE_SHOW_SESSION_WIDGET, VITE_QUEUE_REALTIME, VITE_MODE, VITE_APP_VERSION, VITE_VERSION_CHECK_INTERVAL_MIN,
  VITE_VERSION_TICKET_URL, VITE_VARTALAP_APK_URL; plus `import.meta.env.DEV`.
- **Read by code but missing from tracked .env** (fallbacks apply): VITE_HRMS_BASE_URL, VITE_KYC_ROLE, VITE_MODE,
  VITE_NEST_V2_NOTIFICATION_SOCKET_URL, VITE_QUEUE_REALTIME, VITE_SAATHI_URL, VITE_SAATHI_WS_URL, VITE_SHOW_LEAD_BOARD,
  VITE_SHOW_SESSION_WIDGET, VITE_SLACK_DM_URL, VITE_SLACK_SESSION_MSG_TEMPLATE, VITE_TICKETING_EMBED_URL, VITE_VARTALAP_APK_URL.
- **In .env but not read by code**: VITE_B2B_API_URL, VITE_VERIFICATION_API_URL, VITE_EXCLUDE_AGENT, VITE_COURSE_FEEDBACK_SHOW,
  VITE_FIREBASE_MEASUREMENT_ID, VITE_SUPABASE_PROJECT_ID, VITE_SUPABASE_ATTENDANCE_PROJECT_ID, and non-VITE
  AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_REGION / S3_BUCKET_NAME (tracked — see status.md).
- Gotcha: tracked .env defines the Firebase keys twice (two projects); effective prod Firebase project is UNVERIFIED.

## Tests (vitest, 9 files, ~1.4k lines)
`src/hooks/usePendingDisposition.test.ts`, `src/lib/transferSearch.test.ts`, `src/lib/auth.test.ts`, `src/lib/queueOrder.test.ts`,
`src/components/profiled/docCategories.test.ts`, `src/components/profiled/draft.test.ts`, `src/components/call/callFlags.test.ts`,
`src/redux/api/salesOperationSlice.test.ts`, `src/redux/api/salesOperationSlice.transfer.test.ts`.
No component/page tests; most pages are untested.

## CI / deploy
`.github/workflows/main.yml` "Build and Deploy": on push to `aws-v4`; Node 24; `npm i`; `npm run build`; AWS creds from
GitHub secrets; `aws s3 sync dist/ s3://<bucket> --delete`; CloudFront invalidation `/*`. **No lint or test step.**
The build uses the tracked `.env` (CI injects no env). `vercel.json` (SPA rewrite) also exists; Vercel-as-prod is UNVERIFIED.
