# Account Creation Gate Contract

Maintainiac must stop account farming without exposing raw device or IP details
to the app owner. Enforcement belongs in Firebase Auth blocking functions and
callable Cloud Functions. Client-side code only gathers minimal signals and
explains decisions after the backend responds.

## Client Signal

The app stores a random app installation ID in secure device storage:

```text
maintainiac_app_installation_id_v1
```

The app sends this value only to the hosted account creation function. The
client must not write account-abuse counters directly.

## Server Signal Handling

The backend must:

- Require Google or Apple provider IDs.
- Require Firebase App Check.
- Hash the app installation ID with a server-side secret salt.
- Hash or bucket the IP signal server-side.
- Store only hashed/bucketed signals in Firestore.
- Count accounts per install hash and coarse IP window.
- Allow 2 free hosted accounts per install hash.
- Allow 2 free hosted accounts per coarse IP window.
- Require additional verification after either threshold.
- Block and queue manual review at 6 accounts for either signal.

## Server-Only Collections

```text
accountAbuseInstalls/{installHash}
accountAbuseIpWindows/{ipWindowHash}
accountCreationReviews/{reviewId}
abuseSignals/{signalId}
aiAbuseSecurityEvents/{eventId}
aiEnforcementActions/{actionId}
```

Firestore rules must deny all client reads and writes to these collections.

## Admin App Note

The future admin app should show review status, risk reasons, and support
actions. It should not show raw device IDs or raw IP addresses.

For AI abuse and jailbreak attempts, anonymous-only analytics is not enough.
Command 1 may show account/install enforcement status, rough server-side region,
task type, abuse reason, action taken, attempt count, and risk bucket. It must
not show raw prompts, receipt text, OCR text, customer content, invoice text,
notes, addresses, phone numbers, or emails.
