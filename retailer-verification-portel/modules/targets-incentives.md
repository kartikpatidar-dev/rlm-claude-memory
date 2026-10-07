# targets-incentives (incl. call-audit)

**Purpose:** Monthly/tenure targets and per-agent overrides, target achievement, incentive levels, agent wallet; plus call audit
(audit list/detail from ko-sales and mock audit tooling).

**Entry points:** `/manager/targets` (TargetSettings), `/manager/target-achievement` (TargetAchievement), `/manager/incentive-wallet`
(IncentiveWallet), `/manager/rewards` (RewardsManagement, mock), agent `/wallet` (Wallet), `/wallet/transaction/:id` (mock).
Call audit: `/manager/call-audit` (CallAudit), `/manager/call-audit/:auditId` (CallAuditDetail), `/manager/call-audit-master`,
`/manager/audit-analysis`, `/manager/dip-checker`, `/manager/dip-questions` (mock / local state).

**Key files:** `src/pages/manager/{TargetSettings,TargetAchievement,IncentiveWallet,CallAudit,CallAuditDetail}.tsx`, `src/pages/agent/Wallet.tsx`,
`src/services/backendApi.ts`.

**Data:** main Supabase `monthly_targets`, `agent_target_overrides`, `tenure_targets`, `target_change_logs`, `kpi_data_view` (TargetSettings,
TargetAchievement), `agents` (TargetSettings); `incentive_levels_config` exists in migrations but is not queried by src. HRMS Supabase `employees` via `integrations/supabase/attendance.ts`.

**Depends on:** auth-session.
**Used by:** — (agent-performance and manager-reporting read `monthly_targets` too).

**External services / endpoints:**
- ko-sales: `GET /level-config`, `PUT /level-config/:level` (IncentiveWallet, TargetSettings), `POST /wallet`, `GET /wallet/transactions`,
  `GET /schemes/active` (Wallet), `GET /cs/audits`, `GET /cs/audits/stats`, `GET /cs/audits/:id`, `PATCH /cs/audits/:id`.

**Gotchas:**
- Two incentive sources: ko-sales `/level-config` vs Supabase target tables. `kpi_data_view` has no migration and is untyped (`as any`).
- CallAuditMaster, AuditAnalysis, DIPChecker, DIPQuestionMaster, RewardsManagement are mock/local-state.

Last verified: 2026-10-07 @ 6e2113d (kartik)
