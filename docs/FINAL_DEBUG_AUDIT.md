# MEND UK — Final Source Debug Audit

## Scope
This audit covers the current release candidate source tree, mobile app routes/components, client API layer, Supabase Edge Function wiring, Supabase migration ordering, runtime configuration, Stripe client wiring, and local JavaScript syntax.

## Checks completed
- All local `@/` imports resolve to files in the source tree.
- Every `supabase.functions.invoke()` target has an Edge Function directory.
- Every invoked Edge Function is declared in `supabase/config.toml`.
- All Supabase migrations now have unique 14-digit versions and preserve the original migration order.
- No Stripe secret key/service-role secret was found in app/components/lib client code.
- JavaScript/MJS files pass `node --check`.
- Stripe Android/iOS PaymentSheet remains server-intent driven.
- Booking API paths now use one canonical `book-appointment` workflow; the legacy `createAppointment()` API delegates to it instead of creating a second booking path.
- Trade availability/services functions use the same standard Supabase client pattern as the rest of the Edge Functions.
- Job Passport TypeScript shape includes the additional passport event/access/verification sections returned by the RPC.
- Category trade discovery no longer silently returns all trades when a category has no matching service.
- Refund webhook lookup handles Stripe refund objects that identify the payment through `payment_intent` or `charge`.
- Package dependency ranges have been converted to exact versions.

## Verification limitation
A complete Expo/React Native TypeScript build could not be executed in this environment because `node_modules` could not be installed: the package registry request timed out and offline npm cache did not contain the required packages. Supabase SQL was also not executed against a live staging project in this audit. Those two checks must be run in the real development/staging environment.

## Production gates still required
1. `npm install`/lockfile generation in the project environment.
2. `npm run typecheck` and `npm run lint`.
3. Supabase migration application and test queries.
4. Supabase security advisors/RLS regression tests.
5. Physical Android and iPhone builds.
6. Stripe test-mode PaymentSheet + webhook + Connect transfer tests.
7. End-to-end role isolation tests.
8. Accessibility and performance testing on representative devices.
9. Crash/observability verification.
10. App Store/Google Play release validation.
