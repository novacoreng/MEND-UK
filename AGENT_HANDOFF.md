# MEND UK — Agent Handoff

## Mission
Finish MEND UK as one connected production system. Do not treat UI completion as feature completion.

## Required implementation loop
1. Build approved requirements.
2. Test unit/component/API/database/E2E/device/accessibility/performance checks as applicable.
3. Verify against process-flow coverage, API contracts, database contracts and runtime behavior.
4. Fix every discovered issue and repeat testing.
5. Lock the phase with evidence, limitations and checkpoint SHA.
6. Automatically continue to the next approved phase unless genuinely blocked.

## Change-impact checklist
For every material change inspect:
- PRD / product contract
- process flows
- UX/UI
- API
- database / migration / RLS
- frontend
- backend / Edge Functions
- authentication / authorization
- Stripe/payment state machine
- notifications
- offline synchronization
- accessibility
- performance
- observability
- security
- tests
- documentation
- deployment configuration

## Critical product rules
- No fake production functionality.
- Mock data may only be used for explicit development/demo mode; production must fail gracefully when required backend data is unavailable.
- Never expose service-role, Stripe secret, webhook secret or other private credentials in the mobile bundle.
- Payment state is confirmed server-side through Stripe and signed webhooks.
- Financial actions must be idempotent and recoverable after interruption.
- Trade verification and property compliance must be backed by server-side state, not visual badges alone.
- Offline queues must never independently authorize or settle financial transactions.
- Accessibility and adaptive layout are part of the feature definition of done.

## Current blockers
See `PROJECT_STATE.md` and `docs/PRODUCTION_GATES.md` for the current external-environment gates.
