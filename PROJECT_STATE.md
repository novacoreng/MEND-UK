# MEND UK — Project State

## Current phase
**Production Hardening / Verification — Phase Lock Preparation**

## Product
MEND UK — mobile-first UK home repairs, trusted trades, property records, payments, warranties and Job Passport.

## Platforms
- iOS / iPhone
- Android
- Expo / React Native
- Supabase / PostgreSQL
- Stripe + Stripe Connect

## Builder workflow
Every implementation phase follows:

**Build → Test → Verify → Fix → Lock → Move to next phase**

A phase is not locked until acceptance criteria, integration checks, security checks, runtime verification and documentation are complete or an external blocker is explicitly recorded.

## Current source status
The prepared debugged build exists as a local release package. The GitHub repository currently contains the project shell and production workflow documentation. The full application tree must be transferred as a complete source commit before repository-level CI can validate the whole app.

## Known external gates
- Install dependencies and generate/commit the package lockfile.
- Run TypeScript, lint and Jest checks in a network-enabled environment.
- Execute Supabase migrations and RLS tests against staging.
- Configure and test Stripe test mode, Connect onboarding and signed webhooks.
- Configure real push/email/SMS providers.
- Run physical-device iOS and Android tests.
- Complete accessibility, performance and security validation.

## Do not claim
Do not claim production readiness until the above applicable gates have evidence attached to a locked phase record.
