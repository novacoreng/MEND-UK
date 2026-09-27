# MEND UK

MEND UK is a mobile-first home repairs and property maintenance platform for customers, tenants, landlords, property managers and trusted tradespeople.

## Application
- Expo / React Native SDK 57
- Expo Router
- Supabase backend and Edge Functions
- Stripe PaymentSheet / Connect architecture
- Job Passport and property compliance
- Trade verification
- Offline action queue
- Accessibility and observability foundations

## Development
```bash
npm install
npx expo start
```

## Validation
```bash
npx expo-doctor
npm run typecheck
npm run lint
npm test
```

## EAS
Link the repository to the real Expo project before production builds:
```bash
eas init --account novacoreng
```
Never commit real secrets or service-role keys.

## Source import
The application source is being imported into GitHub in verified batches. Existing repository configuration and documentation are retained while missing application source is added incrementally.
