# whatsapp

**Purpose:** WhatsApp messaging: full inbox (Saathi/CropTalk), global launcher + floating chat, lead-level chat panel (ko-sales /messages),
manager analysis/messaging/template screens.

**Entry points:** `/whatsapp` -> `src/pages/agent/WhatsAppInbox.tsx`; global `WhatsAppLauncher` (all pages except /whatsapp);
lead-level `WhatsAppChatPanel`; manager `/manager/whatsapp-analysis`, `/manager/messaging` (MessagingModule), `/manager/template-master` (mock).

**Key files:** `src/services/saathiApi.ts`, `src/hooks/useSaathiSocket.ts`, `src/components/lead/` (WhatsAppLauncher, WhatsAppFloatChat,
WhatsAppChatPanel ...), `src/lib/waTemplateMessage.ts`, `src/lib/whatsappTarget.ts`, `src/hooks/useMessages.ts`, `src/hooks/useMessageRealtime.ts`,
`src/hooks/useWhatsAppTemplates.ts`, `src/integrations/supabase/messages.ts`.

**Data:** Supabase `messages` (+ realtime channels `conversation:*`, `conversations:all`); `whatsapp_conversations` read by manager AgentDetail.

**Depends on:** auth-session.
**Used by:** layout-shell, my-leads, profiled, lead-detail-legacy.

**External services / endpoints:**
- Saathi (VITE_SAATHI_URL, VITE_SAATHI_WS_URL; fallback croptalk.ko-tech.in; header `X-Channel-Id`): `/auth/login`, `/channels/available`,
  `/recent-messages`, `/get-conversation`, `/conversations/mode`, `/conversations/summary`, `/conversations/resolve`, `/send-message`,
  `/send-template`, `/send-media-upload`, `/templates`, `/templates/preview/:name`, `/media/:id`, `/debug/lookup-pii`; WS `/ws` (text ping).
- ko-sales: `GET /messages/conversation/:piiId`, `GET /messages/by-entity/:type/:id`, `POST /messages/send-whatsapp`, `POST /messages/send-text`,
  `POST /messages/send-media`, `POST /messages/upload`, `GET /templates`, `GET /messages?…limit=1` (count, manager Dashboard).

**Gotchas:**
- TWO WhatsApp stacks coexist (Saathi inbox vs ko-sales /messages). Know which one a screen uses before changing it.
- Saathi env vars are not in tracked .env (code fallback used).
- `hooks/useMessageSSE.ts` (ko-sales `/messages/events/:piiId` SSE) is unused.
- Repo docs: DEPLOYMENT-NEW-FEATURES.md (WhatsApp inbox release).

Last verified: 2026-10-07 @ 6e2113d (kartik)
