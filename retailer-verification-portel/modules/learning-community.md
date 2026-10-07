# learning-community (training/knowledge, onboarding, forum/ideas/grievances/sahiyog, attendance/roster)

**Purpose:** Everything people-side: training, skills, courses, SOPs, crops & agronomy tests, onboarding batches; discussion forum,
ideas, grievances, HRMS tickets, Sahiyog (customer-success tickets); attendance and roster.

**Entry points:** agent `/skills-training`, `/training`, `/skill-library`, `/company-courses`, `/sop`, `/product-knowledge`, `/success-stories`,
`/crops`, `/crops/:cropId`, `/agronomy/tests`, `/agronomy/tests/:testId/result`, `/discussions` (Forum), `/forum` (AskKatyaniAI, mock),
`/ideas`, `/grievances`, `/my-tickets`, `/sahiyog`. Manager `/manager/training`, `/manager/sop`, `/manager/course-tracker`,
`/manager/skill-matrix`, `/manager/agronomy/monitor-test`, `/manager/onboarding`, `/manager/onboarding/batch/:batchId`,
`/manager/forum-answers`, `/manager/ideas`, `/manager/grievances`, `/manager/sahiyog`, `/manager/attendance`, `/manager/roster`.

**Key files:** `src/components/training/`, `src/components/onboarding/`, `src/integrations/supabase/{trainingsService,categoriesService,trainers,
certificatesService,processesService,sopCategoriesService,onboarding,attendance,sopDataClient}.ts`, `src/services/hrmsSkillMatrix.ts`,
`src/services/companyCourses.ts`, `src/redux/api/{agronomyTestsSlice,cropsApi,salesOperationSlice}.ts`, `src/lib/certificate*.ts`,
`src/hooks/supabase/{useForumQuestions,useIdeas,useTrainingVideos,useVideoFeedback,useMyOnboardingSessions}.ts`.

**Data:** main Supabase: training_videos, video_* (6), agent_test_sessions (+ storage `test_recordings`), company_courses* (5), certificate_templates,
issued_certificates, ideas/idea_votes/idea_comments/idea_notifications, grievances/grievance_timeline, onboarding_* (5).
sopSupabase (same project): sops, sop_categories, processes, motivational_quotes, forum_questions, forum_question_comments,
forum_question_attachments (+ storage `forum-attachments`), agents. HRMS Supabase: employees, attendance, attendance_rosters,
attendance_roster_entries, tickets, trainings, training_categories, profiles. Realtime: onboarding-*, video-*, ideas/grievances channels.

**Depends on:** auth-session.
**Used by:** — (navigation only).

**External services / endpoints:**
- ko-sales: `GET /agronomy/tests`, `GET /agronomy/tests/:id`, `GET/POST /agronomy/answer-sheets`, `GET /crops`, `POST /slack/send-dm`
  (BatchSessions; VITE_SLACK_DM_URL, VITE_SLACK_SESSION_MSG_TEMPLATE), `GET /statistics/attendance`.
- sales-operation: `POST /agronomy/agent-tests/:test_id/submit`, `GET /agronomy/answer-sheets/:test_id/:katyayani_id`.
- HRMS REST: `/api/skill-gap-analysis`, `/api/employees`, `/api/employee-skills`, `/api/trainings/by-skill`, `/api/courses/recommended`,
  `GET/POST /api/grievances`, `/api/departments/hr/employees`, `/api/course-tracker/enroll`, attendance clock endpoints.
- iframes: Sahiyog -> VITE_TICKETING_EMBED_URL (SSO token in query); CropDetail -> b2bsales.ko-tech.in/crops/:id (token). Wikipedia REST (crop images).

**Gotchas:**
- Forum uses `sopSupabase`; repo guides DATA_FLOW_GUIDE.md / FORUM_STRUCTURE.md / ATTACHMENTS_GUIDE.md / SUPABASE_STORAGE_SETUP.md cover it.
- `attendanceSupabase` prefers the service_role key (in browser) — rotate; branch `origin/migration` replaces it with HRMS REST.
- `/company-courses` and AskKatyaniAI are mock. `services/forumApi.ts`, `hooks/useRoster.ts` are dead.
- Several onboarding/certificate tables are untyped (`as any`, not in types.ts).

Last verified: 2026-10-07 @ 6e2113d (kartik)
