# Changelog

## 2026-09-26 — Production Builder Workflow Update

### Added
- Explicit Build → Test → Verify → Fix → Lock phase discipline.
- Project state and agent handoff records.
- Adaptive device test matrix for phones, foldables, tablets, landscape and resizable windows.
- Production release gates covering source integrity, builds, backend, Stripe, notifications, trust, resilience, accessibility, performance, observability, security and store release.
- Clear separation between source-level verification and external environment validation.

### Rules reinforced
- No UI-only functionality counted as complete.
- No fake production integrations.
- No secrets committed.
- Mock data restricted to explicit development/demo use.
- Financial actions remain server-authoritative and idempotent.
