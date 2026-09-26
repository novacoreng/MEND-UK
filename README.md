# MEND UK

MEND UK is a mobile-first UK home-repair platform connecting customers, tenants, landlords, property managers and verified tradespeople through repair discovery, quoting, scheduling, Stripe payments, Job Passport records, warranties, disputes and operational tooling.

## Stack
- Expo / React Native for iOS and Android
- Supabase / PostgreSQL / RLS / Edge Functions
- Stripe PaymentSheet + Stripe Connect
- Server-authoritative payment and workflow state

## Production builder workflow
This project follows the updated Full-Stack Production App Builder workflow:

**Build → Test → Verify → Fix → Lock → Move to next phase**

A phase is not considered complete because a screen renders. The corresponding UI, API, database, auth/authz, integration, error/recovery, accessibility, performance, security and verification evidence must pass before the phase is locked.

See:
- `PROJECT_STATE.md`
- `AGENT_HANDOFF.md`
- `DEVICE_TEST_MATRIX.md`
- `docs/PRODUCTION_GATES.md`
- `docs/FINAL_DEBUG_AUDIT_V2.md`

## Core product areas
- Customer repair creation and tracking
- AI-assisted repair triage
- Home Passport and property records
- Trade marketplace and quote requests
- Trade verification
- Booking and scheduling
- Stripe PaymentSheet on iOS/Android
- Stripe Connect trade onboarding and transfers
- Messaging and notifications
- Completion evidence and Job Passport
- Warranty and disputes
- Tenant, landlord and property-manager workspaces
- Trade Pro and staff access
- Marketplace/materials foundation
- Support and trust/safety
- Offline action queue foundation
- Accessibility, performance and observability foundations
- Light/dark/system appearance modes
- UK-focused branding and mobile UX

## Development
Install dependencies in a network-enabled environment, configure the appropriate `.env.*.example` values, then run:

```bash
npm install
npm run typecheck
npm test
npx expo start
```

Apply Supabase migrations in order through the normal Supabase migration workflow. Never commit real secrets.

## Source status
The complete debugged application exists as the prepared local release package used during the source-level audit. The connected GitHub repository currently contains the project configuration, test scaffolding, workflow gates and documentation. The full application source tree still needs to be transferred as a complete repository commit before GitHub Actions can validate the entire mobile/backend tree.

## Production gates
Do not label MEND UK production-ready until applicable gates pass for real staging/production environments: dependency install/lockfile, typecheck/lint/tests, Supabase migrations and RLS, Stripe payments/webhooks/Connect, notification providers, AI provider, physical iOS/Android builds, E2E, accessibility, performance, security, observability, backup/restore, app-store review and UK privacy/legal review.
