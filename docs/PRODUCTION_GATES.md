# MEND UK — Production Gates

## Gate 1 — Source integrity
- [ ] Complete application source tree committed.
- [ ] No secrets or private credentials committed.
- [ ] Package lockfile committed.
- [ ] Environment examples contain placeholders only.

## Gate 2 — Build quality
- [ ] TypeScript passes.
- [ ] Lint passes.
- [ ] Unit/component tests pass.
- [ ] Integration/API tests pass.
- [ ] Expo Android build succeeds.
- [ ] Expo iOS build succeeds.

## Gate 3 — Backend
- [ ] Staging migrations apply cleanly in order.
- [ ] RLS isolation tested for every role.
- [ ] Auth/session recovery tested.
- [ ] Storage policies tested.
- [ ] Edge Functions tested for auth, validation, errors and idempotency.

## Gate 4 — Payments
- [ ] Stripe PaymentSheet tested on Android.
- [ ] Apple Pay tested on iOS where configured.
- [ ] Google Pay tested on Android where configured.
- [ ] 3DS/SCA tested.
- [ ] Signed webhooks verified.
- [ ] Duplicate webhook/payment protection verified.
- [ ] Refund/partial refund/chargeback paths tested.
- [ ] Stripe Connect onboarding and transfer/release tested.

## Gate 5 — Notifications
- [ ] Push provider adapter implemented.
- [ ] Email provider adapter implemented.
- [ ] SMS provider adapter implemented where required.
- [ ] Retry/dead-letter behavior tested.
- [ ] Notification preferences respected.

## Gate 6 — Trust & property data
- [ ] Trade verification is server-backed.
- [ ] Verification expiry/reverification works.
- [ ] Property compliance records are server-backed.
- [ ] Job Passport contains authoritative repair/payment/warranty evidence.

## Gate 7 — Resilience
- [ ] Offline queue survives app restart.
- [ ] Duplicate actions are deduplicated.
- [ ] Financial actions never settle offline.
- [ ] Retry/backoff behavior tested.
- [ ] Interrupted upload recovery tested.

## Gate 8 — Accessibility/performance
- [ ] VoiceOver/TalkBack tested.
- [ ] Dynamic text tested.
- [ ] Touch targets and contrast verified.
- [ ] Startup/rendering performance measured.
- [ ] Large lists/images tested.
- [ ] Low-network behavior tested.

## Gate 9 — Observability/security
- [ ] Crash/error monitoring connected.
- [ ] Structured events have request/trace IDs where applicable.
- [ ] Sensitive values are excluded from logs.
- [ ] Security/RLS/authz audit passed.
- [ ] Dependency audit passed.
- [ ] Backup/restore drill passed.

## Gate 10 — Release
- [ ] TestFlight build accepted internally.
- [ ] Google Play internal test accepted.
- [ ] Store privacy/data declarations reviewed.
- [ ] Privacy/terms/support URLs verified.
- [ ] UK legal/privacy review completed for applicable requirements.
- [ ] Production rollback plan tested.

Production readiness must not be claimed until all applicable gates have evidence.
