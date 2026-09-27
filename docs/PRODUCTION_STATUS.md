# MEND UK — Production Status

## Current state
Release candidate covering the planned Phase 1–24 architecture. The local audit pass has fixed several concrete client/API/UI contract issues found in the consolidated archive.

## Confirmed by local audit
- App route and relative/alias imports resolve to existing project files.
- Client imports from `lib/api.ts` resolve, including conversation methods added during the audit.
- Client-referenced Supabase tables exist in the migration set.
- Phase 20 intelligence generation now has a server-side, deterministic advisory RPC rather than a UI-only placeholder.
- UI primitives accept the props used throughout the application.
- Production EAS build profiles and app runtime/bundle configuration foundations are present.
- Archive contents are internally consistent and the release ZIP can be extracted.

## Not yet verified against a live environment
- `npm install` / Expo dependency resolution and full TypeScript compile with installed dependencies.
- Supabase migration execution and `supabase db lint` / security advisors on the target project.
- RLS behavior under every role and cross-tenant/property access scenario.
- Real Stripe PaymentSheet/native payment collection and signed webhook delivery.
- Push, email and SMS provider delivery, retries and provider credentials.
- AI provider configuration, model selection, safety evaluation and cost controls.
- iOS and Android production builds on real devices.
- End-to-end tests and automated regression suite.
- Penetration testing, dependency vulnerability remediation and mobile security review.
- Accessibility audit and production UX review.
- Backup/restore drill, incident response and rollback rehearsal.
- App Store / Google Play submission and review.
- UK GDPR, terms, privacy, consumer/rental, verification, insurance and payment legal review.

## Required before public launch
1. Connect a dedicated staging Supabase project and apply migrations in order.
2. Run RLS/security advisors and role-based integration tests.
3. Install/pin dependencies and pass Expo/TypeScript/lint checks.
4. Configure real payment, messaging, notification and AI providers in server-side secrets.
5. Implement and verify native payment collection; never mark payment successful from the client.
6. Run customer → quote → booking → payment → completion → warranty/dispute end-to-end tests.
7. Test tenant/landlord/property-manager permissions and isolation.
8. Complete fraud/trust/safety abuse cases and admin escalation testing.
9. Run device, accessibility, performance and security testing.
10. Complete store metadata, privacy/legal review, release signing and staged rollout.

## Stripe mobile payments update

MEND UK now uses a Stripe-first architecture for the Android/iOS application: native PaymentSheet for customer checkout, Apple Pay/Google Pay support, Stripe Connect Express for trade onboarding/payouts, Separate Charges and Transfers for post-confirmation release, signed/idempotent webhooks, and server-side refund handling. See `docs/STRIPE_PAYMENTS.md`.

The remaining payment launch gates are external configuration and validation: live Stripe keys, Apple Pay merchant/certificate configuration, Google Pay configuration, Connect onboarding, production webhook registration, physical-device wallet tests, refund/transfer-failure tests, and reconciliation.
