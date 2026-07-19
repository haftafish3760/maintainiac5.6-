# Receipt AI Assist deployment

Receipt AI Assist is an optional feature adapter of Maintainiac's shared AI
gateway. It never owns an API key or the application-wide AI architecture. It
only suggests candidate receipt fields and never replaces OCR text, chooses
business or personal use, routes a receipt, or writes expense, fuel, inventory,
or accounting records. See `maintainiac_ai_gateway_contract.md` before adding
another AI feature.

## Secret setup

The OpenAI API key must exist only in Firebase Functions secret storage. Do not
place it in Flutter, Firebase client configuration, `.env` files committed to
the repository, screenshots, or support messages.

1. Revoke any key that was pasted into a chat, source file, terminal history,
   or other non-secret location.
2. Create a replacement OpenAI key in the OpenAI dashboard.
3. From this repository, run the following command. Firebase will request the
   value interactively without printing it:

   ```sh
   firebase functions:secrets:set OPENAI_API_KEY
   ```

4. Deploy only the callable after the secret exists:

   ```sh
   firebase deploy --only functions:requestReceiptAiAssist
   ```

The callable uses the `gpt-4o-mini` model and Firebase App Check. Rotating the
secret uses the same command; no mobile release is needed.

## Request contract

`requestReceiptAiAssist` requires an authenticated active organization member,
Firebase App Check, explicit per-request confirmation, a receipt mode, and
bounded OCR line evidence. It accepts text and coordinates-derived line
evidence only; it does not upload a receipt image to OpenAI.

The output contains candidate merchant, date, subtotal, tax, and total fields,
each with source line indexes, confidence, and a reason. The client must show
these as suggestions for review and must retain the existing OCR `sourceText`
and `displayText` separately.

## Server controls

Before production deployment, set the following Firebase Functions parameters
for the appropriate environment. They are intentionally server-side and may be
changed without releasing the mobile application:

- `RECEIPT_AI_MAX_INPUT_CHARACTERS`
- `RECEIPT_AI_MAX_REQUESTS_PER_DAY`
- `RECEIPT_AI_MAX_OUTPUT_TOKENS`

The defaults are conservative safety values, not subscription or billing
policy. Product-specific allowance, entitlement, and migration rules belong in
the central cloud policy once that contract is approved.
