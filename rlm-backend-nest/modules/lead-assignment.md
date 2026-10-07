# lead-assignment

## Purpose
Lead ownership: initial FO round-robin assignment and FO->RO handoff on first delivered order, single and batch
("cron") runs with live socket progress and CSV report; Slack announcements. Nest modules: lead-assignment, slack.

## Entry points (all `/api/v2/lead-assignment`)
- GET `verification`: SSO; stub
- POST `fo-to-ro`: Scoped (admin/manager); body `order_id`, `skip` (force default owner A0-1126)
- POST `fo-to-ro/cron`: Scoped (admin/manager); returns `{started, runId}`, runs in background
- GET `fo-to-ro/report/:runId`: Scoped (admin/manager)
- POST `assign-fo/by-pii/:pii_id`, POST `assign-default-owner/by-pii/:pii_id`: Scoped pii
- POST `assign-fo/cron`: Scoped (admin/manager)
- Socket `/lead-assignment`: room `foro`; `foro:start|progress|done (CSV)|error`; **no handshake auth**
- No in-process cron; cron routes are called by an external scheduler (UNVERIFIED which).

## Key files
`src/modules/lead-assignment/{lead-assignment.controller.ts, lead-assignment.gateway.ts, fo_assignment.service.ts,
foro_assigment.service.ts (sic), schemas/log-foro.schema.ts, single-flow.mmd + *.png}`; `src/modules/slack/` (SlackPublisher).

## Data
- W: `leads_v2` (lead_owner, agent_category, bucket_id, assigned_*), `lead_owner_history`, `rr_state_pointer`,
  `rr_skip_condition_log`, `fo_assign_skip_log`, `foro_reports`, `log_foro`; indirect legacy `retailers` (LegacyUpdate), `retailers_v2` VIP
- R: `agents_v2`, `buckets_v2`, `orders_v2` + legacy `orders`, `calls_v2` + legacy `calls`, `retailers_v2`, `piis`

## Depends on
slack, ops/netcore (account_manager_assigned on every owner change), retailers-core (LegacyUpdateModule, VipModule,
forwardRef RetailersModule), common orders-v2, raw-db, access.

## Used by
- Modules: retailers-core (FoAssignmentService/ForoAssignmentService during upsert and order-delivered webhook).
- Frontends: no consumer found in RVP/portal/admin repos (ADMIN `BucketMasters.tsx` only mentions it in a comment) —
  likely an external scheduler / ops tooling UNVERIFIED.

## External services
HRMS attendance `${HRMS_BASE_URL}/api/attendance` (`HRMS_SERVICE_KEY`; FO assign only; 6 s, 3 retries then A0-1126);
Slack (`SLACK_RLM_BOT_TOKEN`, `SLACK_RLM_CHANNEL_ID` FO->RO, `SLACK_RLM_FO_CHANNEL_ID` FO; posts + DMs, batches of 15);
Netcore events.

## Gotchas
- FO USR-1029, RO USR-1022, protected USR-1021/1022/1029, passthrough USR-1020; sentinel owner `A0-1126`; delivered status 15.
- `single-flow.mmd`/PNGs are stale: FO->RO has NO HRMS check and NO parking (skips with `no_ro_for_state`), except `skip:true`.
- Header comment says FO->RO writes "no retailers_v2" but it reads it.
- Webhook <-> foro loop prevented via `triggerForo:false`. Slack publisher never throws; without token it only logs.

Last verified: 2026-10-07 @ 278fe58 (kartik)
