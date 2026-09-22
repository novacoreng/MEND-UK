# MEND UK — Source Import

The complete debugged application source is prepared locally as `mend-uk-final-debugged.zip`.

This repository currently contains the project shell. The GitHub connection available to the build agent can create individual repository files, but does not expose a binary/archive upload or local-directory push operation. Therefore the complete 234-file source tree cannot be safely reconstructed through this connection without risking a partial application commit.

## Intended source
- Expo / React Native application
- Supabase Edge Functions
- 28 consolidated migrations
- Stripe Connect/payment flows
- Trade verification
- Property compliance
- Job Passport
- Offline resilience
- Accessibility
- Performance and observability
- Production configuration

## Local import
From the extracted project directory:

    git init
    git remote add origin https://github.com/novacoreng/MEND-UK.git
    git add .
    git commit -m "feat: add complete MEND UK application source"
    git branch -M main
    git push -u origin main

Do not commit real environment secrets. Use the provided `.env.*.example` files and configure production secrets in the deployment environment.
