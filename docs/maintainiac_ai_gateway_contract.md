# Maintainiac AI gateway contract

Maintainiac uses one server-side `OPENAI_API_KEY` secret for the entire
application. No Flutter screen, parser, feature module, or future ChatGPT
integration may store or call that key directly.

## Architecture

```text
Maintainiac feature -> authenticated Firebase callable -> feature policy ->
shared AI gateway -> OpenAI
```

The gateway is shared infrastructure. Receipt assistance is one feature adapter;
it does not own the key, model account, billing, or the application-wide AI
architecture.

## Rules for feature owners

When adding an AI capability, do not create another API key or direct mobile
client call. Add a narrowly named, authenticated callable that uses
`functions/maintainiac_ai_gateway.js` and declares its own:

- explicit user opt-in and review behavior;
- input minimization and redaction policy;
- authorization and App Check requirements;
- server-side rate and entitlement policy;
- fixed model, prompt, output schema, and output-token ceiling;
- audit-safe usage telemetry without raw user content;
- validation that prevents the feature from writing records automatically.

Clients must not choose arbitrary models, prompts, tools, or token limits. A
generic client-to-model proxy would make cost control, authorization, privacy,
and prompt-injection protection impossible to enforce consistently.

## Feature boundaries

Receipt assistance may suggest evidence-backed candidate fields only. It cannot
change OCR source text, decide business or personal use, choose accounting
categories, or write a record. Expense summaries, record lookup, and future
account-linked ChatGPT experiences require separate feature contracts and
explicit authorization scopes before implementation.

## ChatGPT account linking

ChatGPT account linking is not the same as an OpenAI API key. It must be
designed as a separate authenticated integration with its own consent,
permissions, data-sharing disclosure, revocation, and rate policy. Do not
attempt to implement it by sharing the Maintainiac server secret with a client
or plugin.
