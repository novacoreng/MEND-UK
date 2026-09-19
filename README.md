# MEND UK — Phase 7

Booking & Scheduling layer built on Phase 6.

Includes appointment request/confirmation/cancellation, availability validation, double-booking protection, customer booking UI, and repair scheduling integration.

Run `npm install` then `npx expo start` after configuring Supabase. Apply migrations in order through the Supabase migration workflow.


## Phase 8 — Messaging & Notifications
Repair conversations, realtime message updates, read receipts, notification inbox, preferences, device registry, and server-created notification events are implemented. See `docs/PHASE_8.md`.

## Phase 9 — Payments
Provider-backed GBP repair payments now use the accepted quote as the server-authoritative amount. Stripe PaymentIntent creation, signed webhook verification, payment audit transactions, idempotency and protected/failed states are implemented. Native payment collection remains a provider UI integration boundary and is not represented as successful by a client button.


## Phase 10 — Repair Completion & Job Passport
- Completion evidence and server-side completion workflow
- Customer confirmation and warranty creation
- Consolidated Job Passport retrieval
- Immutable completion evidence

## Phase 11 — Warranty & Disputes
Warranty claims, repair disputes, evidence protection, and authorised resolution workflows are included. See `docs/PHASE_11.md`.

## Phase 12 — Tenant Experience
Tenant property access, access requests, tenant dashboard, tenant repair visibility and tenant repair creation permissions are included. Responsibility language remains informational rather than a legal liability determination.


## Phase 13 — Landlord Experience

Added a mobile-first landlord workspace with property portfolio oversight, tenant/access-request review, property-scoped repair oversight, landlord repair authorisation, quote/appointment/payment visibility, and warranty/dispute visibility. Server-side RLS/RPC controls remain authoritative; payment execution is not performed by the landlord UI.

Migration: `014_phase13_landlord_experience.sql`.


## Phase 14 — Property Manager / MEND Pro
Added property-scoped manager assignments, secure email-bound invites, MEND Pro portfolio dashboard, managed property/repair views, and RLS-backed operational visibility.


## Phase 15 — Tradesperson Pro
Added trade job inbox, team/staff invites, staff-scoped access and Job Passport operational views.

## Phase 17 — Fraud, Trust & Safety
Safety Centre, safety reports, risk signals, admin triage, auditable enforcement actions and account restriction controls are included in `docs/PHASE_17.md` and migration `017_phase17_fraud_trust_safety.sql`.

## Phase 18 — Notifications & Communications Infrastructure
Adds preference-aware communications, durable delivery records, device registration, reminder generation, retry/dead-letter foundations, communication audit events and a provider-neutral server delivery boundary. See `docs/PHASE_18.md`.


## Phase 19 — Analytics
Privacy-conscious operational analytics, admin KPI reporting, and daily aggregate snapshots are included in `docs/PHASE_19.md`.

## Consolidated Release Candidate — Phases 20–24
The release candidate adds MEND Intelligence, marketplace foundations, production hardening, beta feedback/feature flags, and production launch controls. See `docs/DEBUG_AUDIT.md` and `docs/PRODUCTION_STATUS.md` for the latest audit and remaining launch gates.

## Stripe payments

The mobile app uses Stripe PaymentSheet on iOS and Android. Customer repair payments are created server-side from the accepted quote; Stripe Connect Express is used for trade payout onboarding, and MEND uses Separate Charges and Transfers so customer confirmation remains the release boundary. See `docs/STRIPE_PAYMENTS.md` for setup and launch requirements.

## Final Feature Pack

The current release includes the final in-app feature pack: saved trades, recurring maintenance, customer support tickets, privacy/data controls, trade earnings/payout centre, production operations checklist, offline action queue foundation and compliance consent records. See `docs/FINAL_FEATURE_PACK.md`.

### Production validation still required

Live Supabase/RLS validation, Stripe live configuration (including Apple Pay/Google Pay and Connect), notification providers, AI provider, physical Android/iOS testing, E2E/regression/security/accessibility testing, app-store submission and UK legal/GDPR review remain release gates.

## Final Production Hardening
See `docs/FINAL_PRODUCTION_HARDENING.md` and `docs/REAL_ENVIRONMENT_SETUP.md` for the final environment, verification, compliance, Job Passport, offline, accessibility, performance and observability work.
