# EAS iOS Build 7da06030 Fix

## Diagnosis

Build `7da06030-3101-4ff1-81d0-faba39aacce5` was created from commit `56719e5babb3ef19484bc73bc3f76b0bb520993b`.

The EAS profile itself is structurally valid, but the commit used for the build does not contain the complete Expo application source tree or the referenced binary assets. `app.json` references `./assets/mend-uk-icon.png` and `./assets/mend-uk-logo.png`, while the Git tree used by the build does not contain the complete application directories/assets required by Expo Router.

## Required rebuild gate

1. Commit the complete MEND UK application source and assets to `main`.
2. Link `main` to the real Expo EAS project ID; never invent an ID.
3. Run `npx expo-doctor`.
4. Run `npx expo config --type public` and verify the resolved config.
5. Install dependencies and run `npm run typecheck`, `npm run lint`, and `npm test`.
6. Run an iOS development/preview build before Store distribution.
7. Run the production Store build only after the above gates pass.

## Configuration notes

- `eas.json` uses remote app versioning and production auto-increment.
- The Expo Go warning is non-fatal and is suppressed in EAS profiles.
- Stripe PaymentSheet/Apple Pay require a native development or production build; Expo Go is not the validation target for those paths.
- The `extra.eas.projectId` value must be the actual project ID returned by `eas init` for the `novacoreng` account.

## Do not do

Do not add a fake `extra.eas.projectId`, do not suppress native build errors, and do not declare the Store build fixed until the complete source/assets are present and an actual iOS build passes.
