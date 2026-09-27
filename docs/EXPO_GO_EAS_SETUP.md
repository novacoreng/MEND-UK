# MEND UK — Expo Go / EAS setup

## Why the previous build failed

The failure was not caused by the Expo app configuration itself. EAS stopped because the project is not linked to an Expo EAS project:

`The "extra.eas.projectId" field is missing from your app config.`

The `EAS_BUILD_NO_EXPO_GO_WARNING` message is only a warning. It does not cause the build to fail.

## One-time setup

From the repository root, authenticate with the Expo account that owns the project and create/link the EAS project:

```bash
eas login
eas init --account novacoreng --non-interactive
```

If an EAS project already exists, use its real project ID:

```bash
eas init --id <REAL_EAS_PROJECT_ID> --non-interactive
```

`eas init` will write the real `extra.eas.projectId` into the Expo app configuration. Do not use a placeholder project ID.

## Build profiles

- `development`: internal development build. Use this for Stripe/native modules and device development.
- `preview`: internal distribution build.
- `production`: store-ready build with remote version management.

The Expo Go warning is suppressed for EAS builds. This does not make Expo Go capable of running native-only modules.

## Stripe and Expo Go

MEND UK includes `@stripe/stripe-react-native`. Stripe's native PaymentSheet/Apple Pay/Google Pay flows require a development/preview/production native build. Expo Go is suitable for UI/navigation work but is not the target runtime for the native Stripe payment path.

Use:

```bash
eas build --profile development --platform android
eas build --profile development --platform ios
```

for real Stripe/native testing.

## Validation

After EAS is linked:

```bash
npx expo config --type public
eas build --profile development --platform android
eas build --profile development --platform ios
```

The public config should contain a real `extra.eas.projectId`.
