# notes

## Purpose
Append-only retailer notes per PII; pinning is the only mutation. Latest note text/date denormalised to the retailer.

## Entry points (all `/api/v2/notes`, ScopedGuard)
- POST `/` (Scoped pii), GET `by-pii/:pii_id`, PATCH `:id/pin`, GET `:id` (record)

## Key files
`src/modules/notes/{notes.controller.ts, notes.service.ts, schemas/note.schema.ts, dto/}`

## Data
- R/W `notes_v2`; R/W `app_counters` (`_id:'notes'`, ids `NT-n`)
- R `piis` (exists), `agents_v2` (author email -> agent)
- W `retailers_v2.remarks` (latest text + date only)

## Depends on
Pii, Retailer schemas; common raw-db, access.

## Used by
- Modules: verification-kyc (VerificationService writes audit notes).
- RVP: `/notes`, `/notes/by-pii/:pii_id`, `/notes/:id/pin` (`src/redux/api/kycModuleApi.ts`).
- PORTAL: `/notes`, `/:id`, `/:id/pin`, `/by-pii/:pii_id` (`redux_v2/apis/notes_api.service.ts`).
- ADMIN: `/notes/by-pii/:pii_id` (`src/redux/buketMaster.v2.api.ts`).

## External services
None.

## Gotchas
- A doc comment says note_id is pushed into `remarks[]`; the code stores only latest text/date (code wins).
- Indexes: pii_id+pinned+created_at, type+pii_id+created_at, task_id, signal_id (`scripts/perf` has a note-id-index task).

Last verified: 2026-10-07 @ 278fe58 (kartik)
