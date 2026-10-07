# retailer-verification-portel (Verification Portal - Agent)

Last verified: 2026-10-07 @ 6e2113d (kartik)

React + Vite SPA used by Katyayani's tele-calling **agents** (verification / KYC / profiling of retailer leads)
and their **field managers (FM) / admins** (reporting, assignment, approval, targets, training). It holds no
database of its own: it calls several REST backends (ko-sales-backend, rlm-backend-nest v2, a "utils" server,
sales-operation, CallerApp, HRMS, Saathi) and also reads/writes Supabase and Firebase directly from the browser.
Calls are placed either via the CallerApp mobile dialer (status over Firebase RTDB) or a JsSIP WebRTC softphone.

## Quick facts
| | |
|---|---|
| Repo | Katyayani-Organics/retailer-verification-portel |
| Stack | React 18 + TS + Vite 5 (SWC), Tailwind + shadcn/ui, Redux Toolkit + RTK Query + redux-persist, TanStack Query 5, Supabase JS, Firebase 12, socket.io-client, JsSIP |
| Dev | `npm run dev` -> http://localhost:**8005** |
| Production branch | **`aws-v4`** — NEVER push to it directly (PR only) |
| Base work branch | `kartik` (== aws-v4 == 6e2113d at baseline) |
| Deploy | GitHub Actions `.github/workflows/main.yml` on push to `aws-v4` -> `npm run build` -> S3 sync + CloudFront invalidation |
| vercel.json | Also exists (SPA rewrite) and old CLAUDE.md says `npx vercel --prod`. Whether Vercel still serves prod is UNVERIFIED — CI says AWS. |

## Rules
Root rules and formats: [`../README.md`](../README.md) (single source of truth). Cross-project links: `../system-map.md`.

## Reading order
1. [status.md](status.md) — where things stand, risks, next steps
2. [module-graph.md](module-graph.md) — modules, edges, backends (staleness hash lives here)
3. `modules/<x>.md` for the module(s) you touch
4. [database.md](database.md) — Supabase / Firebase / client storage access
5. [overview.md](overview.md), [architecture.md](architecture.md) when you need the big picture

## Protected things in the project repo (do not edit/delete without explicit user request)
- `CLAUDE.md` (2026-03-19) — PARTLY STALE: says DB is MongoDB, only 2 contexts, Vercel-only deploy, progressive
  navigates to `/kyc-working` (now `/profiled`). Prefer these memory docs.
- `.claude/settings.local.json` — tracked in git and contains secrets (see status.md: rotate). Never copy from it.
- `docs/` — AGENT_NUMBER_IN_CALL_PAYLOAD.md (STALE: feature not in src), CALL_ANALYSIS_REQUIREMENTS.md (spec),
  profiled-role-condition-plan.md (implemented), verification-transfer-summary.md (implemented).
- Root guides: README.md (Lovable boilerplate, stale), FLOW.md (roughly current), rlm_flow.md (about a DIFFERENT app, RLM Portal),
  WORKFLOW.md (partly stale), DATA_FLOW_GUIDE.md / FORUM_STRUCTURE.md / ATTACHMENTS_GUIDE.md / SUPABASE_STORAGE_SETUP.md (forum, narrow),
  ENHANCED_SEARCH_PROCESS.md / PAGINATION_IMPLEMENTATION.md (old, UNVERIFIED vs current LeadAssignment), HIERARCHICAL_TEAM_MEMBERS.md (plausible),
  KYC_MODULE_CHANGES.md (stale: module now on NEST v2), MY_PROFILE_CHANGES.md (narrow), PROGRESSIVE_CALLING.md (mostly current),
  IS-VOIP-FLOW.md / VOIP-CHANGES-FOR-PM.md / DEPLOYMENT-NEW-FEATURES.md (current-ish), v4.md (most current; v4 KYC documents),
  queries.md (ops notes with real emails — do not copy). Also `requirements/*.md` (snapshot, partly stale),
  `supabase/md/PROGRESS.md` (stale auth log), `.lovable/plan.md` (stale).
- `.env` — tracked; contains secrets. Never print or copy values.

## Hard rule
**Do not modify `src/lib/callerapp.ts` without explicit user permission** (call initiation / control / verified end-call).
