# pipeline

## Purpose
Workflow-driven retailer pipeline (FO -> RO -> AR -> LR stages): forward-only stage transitions with stage history
and evidence checks before a move.

## Entry points (all `/api/v2/pipeline`)
- POST `transition`: Scoped retailer_id
- GET `workflows`: SSO only; `?pipeline_type` default `retailer`
- GET `cycles/retailer/:retailer_id` (Scoped retailer), GET `cycles/pii/:pii_id` (Scoped pii)
- No sockets/crons here (sweep cron and reconcile live in retailers-core).

## Key files
`src/modules/pipeline/{pipeline.service.ts, pipeline-evidence.service.ts, utils/stage-evidence.rules.ts,
schemas/retailer-pipeline.schema.ts, schemas/pipeline-workflow.schema.ts}`; rules shared from
`src/modules/retailers/utils/pipeline-rules.ts`. Seeds: `scripts/seed-{fo,ro,ar,lr}-pipeline-workflow.ts`.

## Data
- W: `retailer_pipelines` (create, history), `retailers_v2` (mirror `pipeline_info`)
- R: `pipelines_workflow`, `retailer_pipelines`, `calls_v2`, `retailevents`, `status`, `orders_v2` + legacy `orders`, `retailers_v2`

## Depends on
common orders-v2 (OrdersV2SourceService), access (ScopedGuard). No module imports.

## Used by
- Modules: retailers-core (imports PipelineModule; exports PipelineService + models).
- PORTAL: `/pipeline/workflows` (`src/redux_v2/apis/pipeline_api.service.ts`). RVP, ADMIN: none found.

## External services
None.

## Gotchas
- `PIPELINE_EVIDENCE_MODE` off | **warn (default)** | enforce. ~79% of `calls_v2` rows lack a usable `pii_id`, so call
  evidence is mostly unfindable; enforce only after a backfill.
- `retailer_pipelines` is the source of truth; `retailers_v2.pipeline_info` is only a mirror.
- Comments reference `STAGE-TRANSITION-CONDITIONS.md`, not present in `docs/` (UNVERIFIED location).

Last verified: 2026-10-07 @ 278fe58 (kartik)
