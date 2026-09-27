# Expo Go / EAS configuration fix

The error `Failed to read "/eas.json". Run eas build:configure to create the file.` is a project-directory/configuration error, not an Expo Router runtime error.

The repository now contains a valid root `eas.json` with development, preview, and production profiles.

## Correct commands

Run these from the repository root:

```bash
npx expo start
```

For EAS builds:

```bash
npx eas-cli@latest build:configure
```

Then:

```bash
npx eas-cli@latest build --profile preview --platform ios
```

Production:

```bash
npx eas-cli@latest build --profile production --platform ios
```

The command must be executed from the directory containing both `package.json` and `eas.json`.

Do not create a second `eas.json` inside `app/` or another subdirectory.
