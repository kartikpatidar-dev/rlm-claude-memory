# Status — retailer-verification-portel

Last verified: 2026-10-07 @ 6e2113d (kartik)
Edited in place. Branches at baseline: `kartik` = `aws-v4` = `origin/aws-v4` = 6e2113d. `origin/main` (bb39156, 2026-08-25) is 70 commits behind and 2 ahead of 6e2113d — not the prod line.

## Current state
Production line is v4 (aws-v4). Recent work concentrated on the **Profiled** page and v4 KYC documents (Digio online check vs
manual photo proof, document rejections/verifications on NEST, `documents_meta`), KYC approval filter, and app-version display.

## Recent work (git log --oneline, newest first)
- 6e2113d Merge PR #119 check-app-version; d83114d app version from lead API only, never Firebase
- 6f0c178 Merge PR #118 (2026-09-28); f19e7e2 kyc-approval sends `kyc_only=true` so agent filter uses `kyc_agent`
- b0e8dc3 aws-v3-version 3.0.0; 6bb2631 VITE_V4_HIDE false -> true
- 61127d1 .. 76bc005 (~19 commits): Profiled/v4 documents — gender from Aadhaar check, per-document `mode: online|manual`,
  voter_id_front alias, documents_meta per scan, approved KYC stays approved/frozen proof, online panel from `document_verifications`,
  DOB date picker, rejection logging, every document answered Yes/No.

## In-progress / unmerged branches worth knowing
- `origin/migration` (8 commits ahead of 6e2113d) and `origin/query-event-opt` (merges migration; 2026-10-03): "no Supabase or Firebase
  in the browser" — moves Supabase calls behind rlm-backend-nest `/portal/*`, replaces HRMS Supabase client with HRMS REST, removes
  direct Firebase, stops the bundler inlining every env var, nest error handling (403/422/503). Diff vs 6e2113d: 144 files.
  NOT merged to kartik/aws-v4. When merged, database.md, architecture.md and most module docs need a refresh.
- Many feature branches on origin (feat/*, fix/*, arpit-*); status of each UNVERIFIED.

## Known issues / risks
Security (ROTATE, values intentionally not recorded):
- `.env` is tracked in git and includes AWS access keys (non-VITE) plus all VITE_* values -> rotate AWS keys, untrack `.env`.
- Attendance/HRMS Supabase **service_role** key is shipped in the browser bundle (`VITE_SUPABASE_ATTENDANCE_SERVICE_ROLE`, preferred by
  `integrations/supabase/attendance.ts`) and also appears in tracked `.claude/settings.local.json` -> rotate.
- SIP password / TURN creds in env -> in bundle. Main Supabase anon key hard-coded in `integrations/supabase/client.ts`.
- SSO token passed in iframe query strings (Sahiyog, LeadBuckets, LiveAgents, WorkflowMaster, CropDetail).
- `VITE_TEST_MODE` bypasses OTP/MFA at login — must be off in prod builds.
Functional:
- FMSidebar links `/manager/ask-katyayani` -> no route (404).
- koSalesApi `getDocumentRequirements` hard-codes `PII-198664` (backendApi version is the one used).
- CI has no lint/test step; build uses tracked `.env`.
- Firebase keys defined twice in .env (two projects); effective prod project UNVERIFIED.
- Old CLAUDE.md and several root guides stale (see README.md).
Dead code (unrouted / no consumers): pages/auth/Login.tsx, pages/Index.tsx, pages/manager/OrderDetails.tsx, pages/manager/CourseFeedback.tsx,
components/LeadDetail.tsx, components/LeadTable.tsx, components/MFAVerification.tsx, components/layout/AppSidebar.tsx, services/forumApi.ts,
hooks/useMessageSSE.ts, hooks/useRoster.ts, hooks/useAppNotifications.ts; RTK `utilsApi`, `retailerApi`, `authApi`.

## Next steps
User's list (fill in):
- 

Suggestions:
- Rotate AWS keys, attendance service_role key, SIP/TURN creds; untrack `.env` and `.claude/settings.local.json`.
- Decide on merging `origin/migration` / `query-event-opt` (removes browser Supabase/Firebase); refresh memory docs after.
- Add `npm test` (and lint) to the CI workflow.
- Remove the `/manager/ask-katyayani` link or add a route; delete dead code listed above.
- Confirm whether Vercel still serves anything; update CLAUDE.md or point it to this memory.
