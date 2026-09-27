# MEND UK Debug Audit — Release Candidate

## Fixed in this pass
- Added missing conversation API methods: listMyConversations, listConversationMessages, markConversationRead.
- Added marketplace API methods for products and maintenance plans.
- Added server-side deterministic MEND Intelligence generation RPC and client APIs.
- Fixed UI component prop contracts: Screen title, Status label/value compatibility, and Input native TextInput props.
- Exported requireSupabase for the existing warranty screen.
- Removed an unsupported DateTimeFormat `dateStyle` option from a landlord repair screen.
- Added EAS build profiles and production bundle/runtime configuration foundations.
- Added production configuration validation helper.
- Improved marketplace and beta error/loading states.

## Verification performed
- All relative/@ imports resolve to files in the release candidate.
- All imported lib/api symbols now exist.
- All referenced Supabase tables in the client have schema definitions in migrations.
- Migration 020 intelligence function was added with authenticated execution and property authorization.
- ZIP archive and file tree were inspected.

## Environment limitation
A full Expo/React Native typecheck cannot be truthfully reported from the extracted archive alone because dependencies are not installed in the archive and network installation timed out in this environment. The global TypeScript compiler therefore reports missing Expo/React Native/Deno modules; those are environment/dependency errors rather than proof of application syntax failure.

## Remaining production gates
See `docs/PRODUCTION_STATUS.md` for the launch checklist. In particular, live Supabase migration/RLS testing, provider credentials/webhooks, real payment UI, push/email/SMS delivery, iOS/Android release builds, device testing, E2E tests, security testing, backup/restore testing, accessibility, observability, and UK legal/privacy review remain required before production launch.
