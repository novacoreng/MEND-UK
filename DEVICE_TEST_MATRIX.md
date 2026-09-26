# MEND UK — Device & Adaptive Test Matrix

MEND UK is mobile-first but must adapt to available window size and platform constraints rather than hard-coded device names.

| Profile | Orientation | Required checks |
|---|---|---|
| Compact phone | Portrait | navigation, keyboard, safe areas, forms, 44px+ targets |
| Compact phone | Landscape | layout does not clip or hide primary actions |
| Standard phone | Portrait | full core journey |
| Standard phone | Landscape | adaptive navigation and sheets |
| Large/tall phone | Portrait | content hierarchy and scrolling |
| Large/tall phone | Landscape | split content and keyboard handling |
| Foldable cover | Portrait | navigation and safe-area behavior |
| Foldable inner | Portrait | expanded composition |
| Foldable | Half-open/tabletop | hinge-safe critical controls |
| Tablet | Portrait | expanded list/detail layouts |
| Tablet | Landscape | rail/sidebar and multi-column behavior |
| Resizable window | Any | no fixed-width assumptions |

## Core journey on every applicable profile
Open → onboarding → signup/login → permissions → home → create repair → AI triage → evidence → discover trade → request quote → accept quote → Stripe PaymentSheet → booking → trade arrival → completion → customer confirmation → payout/release → warranty → review → reopen and state restore.

## Failure-state checks
- Offline before submit
- Offline during upload
- Offline during status update
- App killed and reopened
- Session expiry
- API timeout
- Backend 4xx/5xx
- Duplicate submit
- Interrupted payment
- Payment webhook delayed
- Notification provider failure
- Rotation/resize/fold during a form

## Accessibility checks
- VoiceOver
- TalkBack
- Dynamic text / font scaling
- Focus order
- Labels and hints
- Contrast
- Reduced motion
- Touch targets
- Error announcements
