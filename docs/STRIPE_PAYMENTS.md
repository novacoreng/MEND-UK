# MEND UK — Stripe Payments Architecture

## Mobile platforms

MEND UK is a native React Native/Expo mobile application for **iOS and Android**. Customer repair payments use Stripe's native React Native SDK and PaymentSheet.

- iOS: Stripe PaymentSheet + Apple Pay when the device/account and Apple Pay merchant configuration support it.
- Android: Stripe PaymentSheet + Google Pay when the device/account and Google Pay configuration support it.
- Card details never pass through MEND's React Native JavaScript or Supabase database.
- The Stripe publishable key is safe for the client; the Stripe secret key exists only in Supabase Edge Functions.
- Apple Pay requires the configured Apple merchant identifier and Stripe Apple Pay setup/certificate.
- Google Pay requires a development/production native build; Expo Go is not sufficient for wallet testing.

## Money flow

```text
Customer mobile app
      |
      | Stripe PaymentSheet
      v
MEND Stripe platform account
      |
      | PaymentIntent (full repair amount)
      v
Stripe payment processing
      |
      | signed webhook: payment_intent.succeeded
      v
MEND payment ledger -> protected
      |
      | customer confirms completed repair
      v
MEND server checks repair + payment + trade
      |
      | Stripe Transfer
      v
Verified trade Stripe Connect Express account
      |
      v
Trade bank payout managed by Stripe
```

MEND uses **Stripe Connect** because MEND is a two-sided marketplace: customers pay through MEND and tradespeople receive their proceeds through MEND. The implementation uses **Separate Charges and Transfers** because MEND needs the application-level release boundary after customer confirmation. A destination charge would transfer the connected-account amount automatically and therefore is not the chosen architecture for the Job Passport release step.

## Payment states

- `pending` — PaymentIntent created, customer checkout not yet confirmed.
- `protected` — Stripe webhook confirmed successful payment; funds remain under the platform's payment/release workflow.
- `release_requested` — MEND has authorised the release operation server-side.
- `released` — Stripe transfer created and recorded against the payment.
- `partially_refunded` / `refunded` — Stripe refund state reconciled into MEND's ledger.
- `failed` — Stripe reported payment failure.

## Platform fee

The server calculates the MEND fee from `MEND_PLATFORM_FEE_BPS`. The customer amount is never accepted from the mobile client. The accepted quote is the source of truth.

Example:

- Quote: £500
- `MEND_PLATFORM_FEE_BPS=1000`
- Platform fee: £50
- Trade transfer: £450

The Stripe processing fee is a platform-level Stripe cost under this marketplace architecture and is not silently added to the customer's quote.

## Trade onboarding

Each trade has a Stripe Connect Express account. MEND creates the account server-side and generates a Stripe-hosted onboarding link. The trade must have a payout-enabled account before MEND creates a repair payment.

The mobile app exposes **MEND Pro → Stripe payouts** for onboarding.

## Security requirements

- Never expose `STRIPE_SECRET_KEY` in Expo public variables.
- Never trust an amount supplied by the mobile app.
- Verify every Stripe webhook signature using the raw request body.
- Process webhook events idempotently.
- Use Stripe idempotency keys for PaymentIntent, Transfer and Refund creation.
- Keep Stripe IDs in the server database, not in client-controlled metadata only.
- Treat Stripe webhook confirmation as the payment truth; the mobile success screen is not payment confirmation.
- Customer confirmation can request release, but only the server creates the Stripe transfer.
- Refunds are server/admin operations.
- Reconcile Stripe payment/transfer/refund events against MEND's payment ledger.

## Required production configuration

### Expo / EAS public values

```text
EXPO_PUBLIC_SUPABASE_URL=
EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY=
EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_...
EXPO_PUBLIC_STRIPE_MERCHANT_IDENTIFIER=merchant.uk.mend.app
EXPO_PUBLIC_STRIPE_TEST_MODE=false
```

### Supabase Edge Function secrets

```text
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_CONNECT_RETURN_URL=https://<verified-domain>/stripe/connect/return
STRIPE_CONNECT_REFRESH_URL=https://<verified-domain>/stripe/connect/refresh
MEND_PLATFORM_FEE_BPS=1000
```

Do not copy secret values into the repository or `.env` files committed to Git.

## Stripe Dashboard setup still required

1. Enable the appropriate payment methods for GBP/UK customers.
2. Configure and verify Apple Pay for the MEND Apple merchant identifier.
3. Configure Google Pay for the MEND Android application.
4. Enable/configure Stripe Connect Express for UK trades.
5. Configure the platform's branding and statement descriptor.
6. Configure Radar and review marketplace fraud rules.
7. Create the production webhook endpoint pointing to the Supabase `payment-webhook` function.
8. Subscribe to the payment, refund, transfer and connected-account events used by the application.
9. Test refunds and failed transfers before live launch.
10. Verify platform fee/tax/accounting treatment with the business/accounting team.

## Native build requirement

Apple Pay and Google Pay are native capabilities. They require a development/preview/production build containing the Stripe native module; Expo Go is not a valid final wallet-testing environment. Rebuild after changing the Stripe config plugin or Apple merchant configuration.

## Launch acceptance tests

- Successful UK card payment.
- 3DS/SCA authentication.
- Apple Pay on a supported physical iPhone.
- Google Pay on a supported physical Android device.
- Payment cancellation.
- Payment failure.
- Duplicate payment button taps.
- Duplicate webhook delivery.
- Customer confirmation → release.
- Trade onboarding incomplete → payment blocked.
- Transfer failure → payment remains protected/retryable.
- Full refund before release.
- Partial refund after release, subject to the platform's dispute/refund policy.
- Stripe Dashboard and MEND Job Passport amounts reconcile exactly.
