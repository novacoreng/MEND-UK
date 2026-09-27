# MEND UK — Final Feature Pack

This build adds the fifteen remaining product/launch workstreams identified during the production audit.

1. Customer experience: saved trades, maintenance entry points, support, privacy controls and operational UX foundations.
2. Trade experience: Stripe Connect earnings/payout centre and production operations entry points.
3. Stripe: native Android/iOS PaymentSheet architecture remains server-authoritative with Connect transfers.
4. Notifications: existing notification infrastructure remains the delivery layer; production provider credentials are still environment-specific.
5. MEND AI: existing advisory intelligence remains server-side; safety-critical categories must escalate.
6. Marketplace: existing materials/services marketplace remains linked to repairs and properties.
7. Property management: recurring maintenance plans/tasks are now persisted and property-scoped.
8. Admin: production operations control centre added for release testing.
9. Support: customer support tickets and ticket messages foundation added.
10. Security: privacy/data-export/deletion request controls and explicit RLS added.
11. UK compliance: consent/version records added; legal review remains external.
12. Mobile polish: theme-safe UI, safe-area-aware screens and production test checklist added.
13. Offline/resilience: local offline action queue foundation added; network-aware replay should be completed with live device testing.
14. App-store readiness: EAS production profiles and release documentation retained; Apple/Google developer setup remains external.
15. Final testing: release_test_runs schema and admin checklist added for staging/device/E2E verification.

## Remaining external gates

- Live Supabase project migration and advisor/security audit.
- Stripe live account, Connect, Apple Pay and Google Pay merchant configuration.
- Push/email/SMS provider credentials and delivery tests.
- AI provider credentials and safety evaluation.
- Android physical-device test and Play Console setup.
- iOS physical-device/TestFlight test and Apple Developer setup.
- Penetration testing, accessibility audit and performance testing.
- UK GDPR/legal review and final policies.
- Backup/restore and incident/rollback drill.
