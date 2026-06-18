# Receipt Cloud Reading Security Plan

Maintaniac is local-first. Cloud receipt reading is optional and must never make
the mobile app responsible for protecting paid API credentials or enforcing paid
usage limits.

## Non-Negotiable Rules

- The app must not call Google Vision directly.
- The app must not contain a Google Vision API key, service-account JSON, Stripe
  secret key, Firebase admin credential, or webhook secret.
- The 30 free cloud receipt reads per month must be enforced on the backend, not
  in Hive, SharedPreferences, or any other client-side storage.
- Firebase App Check must protect the cloud receipt endpoint before production.
- Firebase Auth must identify the user before any cloud receipt read.
- The backend must check quota and increment usage in one server-side transaction
  before calling Google Vision.
- A failed Vision call must be recorded separately from a successful charged read
  so users are not unfairly charged for backend failures.
- Cloud receipt reading must preserve the user's local-first choice. Users who
  leave it off continue using local/manual receipt entry.

## Recommended Flow

1. User opts into cloud receipt reading.
2. App uploads the selected receipt image to a private temporary storage path or
   sends it to a callable backend endpoint, depending on final architecture.
3. Backend verifies Firebase Auth and App Check.
4. Backend reads the user's current monthly cloud receipt usage.
5. Backend rejects the request if the free allowance is exhausted and no paid
   entitlement exists.
6. Backend reserves one usage slot in a transaction.
7. Backend calls Google Vision using server-held credentials.
8. Backend returns extracted text and confidence metadata to the app.
9. App shows parsed receipt fields for user review before saving.

## Firestore Shape To Plan For

```text
users/{uid}/usage/cloudReceiptReads/{yyyyMM}
  freeLimit: 30
  used: number
  paidCreditsUsed: number
  updatedAt: server timestamp

users/{uid}/entitlements/cloudReceiptReading
  status: free | paid | disabled
  paidCreditsRemaining: number
  stripeCustomerId: string
```

## Security Notes

- Do not trust a receipt count sent by the app.
- Do not trust a plan name sent by the app.
- Do not trust a price sent by the app.
- Do not expose other users' receipt text, receipt photos, usage records, or
  entitlement records through Firestore rules.
- Stripe checkout and webhooks must be server-side. The app may launch checkout
  or show entitlement status, but webhook verification and credit updates happen
  on the backend.
