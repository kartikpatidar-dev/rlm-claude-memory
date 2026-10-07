# portal-supabase

## Purpose
`/portal/*` routes that replace direct browser access to Supabase (Sales CRM `crm` and Marketing 360 `m360`
projects) for rlm-portal and the verification portal. 11 Nest modules: portal-data + portal-agents,
-certificates, -drafts, -grievances, -ideas, -misc, -onboarding, -queries, -retail, -targets. Contract: `docs/portal-data-apis.md`.

## Entry points (all `/api/v2/portal...`; M = manager-only via `PortalAccessService`, else open to every user)
| Module | Route prefix | Routes (compact) | Supabase tables (crm unless noted) |
|---|---|---|---|
| portal-data | `portal` | products, training-videos (+`:id/view`), forum-questions; forum-threads (list/create/comments/like/attachments, M: answer/reject/restore), forum-attachments/signed-url; M: team-capacity, rps-tasks, pipeline-retailers, PUT bandwidth-settings; GET bandwidth-settings; sops, geo/states, geo/districts (m360); test-recordings/upload-url, test-sessions (M: list/delete) | notifications, motivational_quotes, products, training_videos, forum_questions(+_comments,_attachments), agents, rps_tasks, retailers, bandwidth_settings, agent_test_sessions, sops, processes, sop_categories; m360 rlm_portal_sops, states, districts |
| portal-data | `portal/notifications` | GET `/`, PATCH `read-all`, `:id/read` (own `user_id` only) | notifications |
| portal-data | `portal/quotes` | GET `/`; M: POST, PATCH `:id/toggle`, PATCH/DELETE `:id` | motivational_quotes |
| portal-data | `portal/sop-library` | GET sops, sops/count, processes, categories; M: POST/PATCH/DELETE each | sops, processes, sop_categories |
| portal-agents | `portal/agents` | GET me, bandwidth-status, `:id`, `:id/detail`, `:id/wallet` | agents, agent_levels, daily_agent_metrics, agent_coin_transactions, calls, kyc_audit_scores, grievances, activity_logs, whatsapp_conversations (R) |
| portal-certificates | `portal/certificates` | GET mine; M: GET templates, POST `/`, GET `/` | certificate_templates, issued_certificates, agents |
| portal-drafts | `portal/drafts` | GET `/`, by-lead/:leadId; PUT `/` (15 MB); POST `:id/extend`; DELETE `:id` (own only) | verification_draft_info |
| portal-grievances | `portal/grievances` | GET mine, mine/counts, `:id/timeline`; POST `/`; M: GET `/`, PATCH `:id` | grievances, grievance_timeline, agents |
| portal-ideas | `portal/ideas` | GET/POST `/`, notifications (+read-all, `:id/read`), POST `:id/vote`, `:id/comments`; M: PATCH `:id/status` | ideas, idea_comments, idea_votes, idea_notifications, agents |
| portal-misc | `portal` | POST voice-issues; M: POST app-events, GET whatsapp/analytics | voice_issue_reports, app_events, messages |
| portal-onboarding | `portal/onboarding` | batches CRUD (+next-number, by-number/:n, agents, sessions, stats), agents (+attendance), sessions/:id/attendance, sessions/:id/complete, tracker (all read-all); GET my-sessions | onboarding_batches, onboarding_batch_agents, onboarding_sessions, onboarding_session_attendance, onboarding_audit_log |
| portal-queries | `portal/queries` | GET `/`, POST `:id/use`; M: usage-logs, lead-queries, POST/PATCH/DELETE | query_master, query_usage_logs, lead_queries |
| portal-retail | `portal/retail` | GET retailers(+/:id), orders(+/:id), rps-tasks, ivr-calls, product-categories, training-videos (read-only) | retailers, orders (+order_items UNVERIFIED), rps_tasks, ivr_calls, products, training_videos, agents |
| portal-targets | `portal/targets` | GET kyc; M: GET `/`, tenure, overrides, change-logs, agents; PUT monthly, tenure, overrides; POST change-logs | monthly_targets, tenure_targets, agent_target_overrides, target_change_logs, agents |
Storage buckets (crm): `forum-attachments` (signed upload/read), `test_recordings` (signed upload; bucket missing).

## Key files
`src/modules/portal-data/{portal-data.guard.ts, portal-access.service.ts, hrms-identity.service.ts, portal-data.util.ts,
portal-*.controller.ts, portal-*.service.ts}`; one controller + service per other `src/modules/portal-*/`;
`src/common/supabase/{supabase-rest.service.ts, supabase-filter.ts}`; `portal-retail/crm-agent-scope.service.ts`;
`portal-ideas/caller-name.ts` (reused by portal-misc). Tests: `test/portal-data.e2e-spec.ts` + per-service specs.

## Data
No Mongo writes. Mongo R `agents_v2` only (portal-data test sessions, portal-queries usage log names, scope via AccessService).

## Depends on
common supabase, access (AccessService), raw-db, `utils/in-flight`, `search/retailer-search.util`; HRMS. Each portal-*
module re-provides `PortalDataGuard`, `HrmsIdentityService`, `PortalAccessService` (own instances and HRMS caches).

## Used by
No consumer found in RVP/portal/admin repos on current branches — the RVP and PORTAL branches `origin/migration` /
`origin/query-event-opt` (commits 37d3ab3, 5a8d00b "no Supabase in the browser") would consume them. UNVERIFIED when they ship.

## External services
Supabase crm (`SUPABASE_URL`, `SUPABASE_SERVICE_KEY`), m360 (`MARKETING_SUPABASE_URL`, `MARKETING_SUPABASE_SERVICE_KEY`/`_KEY`);
HRMS `GET {HRMS_BASE_URL}/api/me` with the caller's token (cached 10 min). Kill switch `PORTAL_DATA=off` (503).

## Gotchas
- `PortalDataGuard` runs after SSO; program login (`RETAILER_APP_USER_EMAIL` / `ACCESS_SERVICE_EMAILS`) always 403.
- Manager/own-row rules enforced in services (`assertManager`, `assertReadsAll`, `assertCoversEmail`) per `ACCESS_SCOPE_MODE`;
  `@OpenToAll()` here is documentary. Identity always from the token (`created_by`, `changed_by` no longer from body).
- `limit` above ceiling -> 422; every success is 200 (POST too). Missing Supabase config -> 503, Supabase error -> 502.
- Supabase `agents.id` != `agents_v2.agent_id`; match by e-mail. Supabase `retailers` has ~10 rows (legacy); real base is Mongo.
- Drafts: max per agent, 7-day expiry stored inside `form_data`; list never returns `form_data`.

Last verified: 2026-10-07 @ 278fe58 (kartik)
