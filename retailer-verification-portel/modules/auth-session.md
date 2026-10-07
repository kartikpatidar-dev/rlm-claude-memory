# auth-session

**Purpose:** Login (ko-sales), MFA/OTP via SSO, role gate (agent / manager / admin), role switch, auto-logout, HRMS clock-in/out.

**Entry points:** route `/login` -> `src/pages/auth/LoginNew.tsx` (redirects to `/` when authenticated); `ProtectedRoutes` in `src/App.tsx`
(auth check, `useAutoLogout`, fires `useGetRlmAgentsQuery`, picks manager vs agent route tree).

**Key files:** `src/contexts/AuthContext.tsx` (login, MFA, `isManager`, `switchRole`, role codes, email allow-list, localStorage keys),
`src/services/ssoAuth.ts`, `src/services/crmAuth.ts` (only init/getStoredUserData/logout used), `src/lib/auth.ts` (+ `auth.test.ts`),
`src/hooks/use-auto-logout.ts`, `src/lib/soonModules.ts`, `src/services/hrmsAttendance.ts`.

**Data:** no tables. localStorage session keys (`ssoAccessToken`, `sso_token`, `crm*`, `isVoip`, `voipExtension`, `crmRoleView` ...; see database.md).

**Depends on:** — (root of the graph)
**Used by:** every module (tokens, `isManager`, agent id/email/category, `isVoip`).

**External services / endpoints:**
- ko-sales (VITE_BACKEND_URL): `POST /auth/login` ({email,password} or {email,temp_code}) — returns agent payload incl. `is_voip`, `extension`.
- SSO (VITE_SSO_URL): `POST /verify-otp` (MFA), `POST /refresh` (auto-logout refresh). `POST /login`, `POST /generate-tokens` exist in ssoAuth.ts but are not in the active path.
- HRMS (VITE_HRMS_BASE_URL || VITE_HRMS_API_URL): `POST /api/attendance/clock-in`, `/clock-out`, `/break-in`, `/break-out`, `GET /api/employees/kpi-targets`.
- utils (VITE_BASE_URL): `GET /kyc/agent_v2` on every protected render (cached in localStorage `rlm_agents`).
- CRM (VITE_CRM_BASE_URL): `POST /agent/login`, `GET /userRoles/all` — code present, NOT called by current login.

**Gotchas:**
- Role codes: ADMIN USR-1000; MANAGER USR-1021/1002/1019; ALLOWED adds 1001/1012/1020/1030 + 2 hard-coded emails. USR-1030 forces `agent_category=retailer_kyc`.
- Two tokens: `ssoAccessToken` (ko-sales JWT) and `sso_token` (SSO JWT); clients prefer them inconsistently (`fetchBackend` uses only `ssoAccessToken`).
- 401s dispatch window event `auth:unauthorized`.
- `VITE_TEST_MODE` bypasses OTP/MFA — must never be on in prod.
- RTK `authApi` (src/redux/api/authApi.ts) is unused; `pages/auth/Login.tsx` and `components/MFAVerification.tsx` are dead.

Last verified: 2026-10-07 @ 6e2113d (kartik)
