# Maintainiac 5.7 remote-ref gap reconciliation — 2026-07-22

## Why this follow-up exists

A final `git fetch --prune origin` exposed preservation refs that were not
present in the 5.7 clone during the first remote-tip inventory. The first
history report therefore covered nine independent source tips but did not name
the nine additional independent source tips below. No source checkout was
modified.

The refreshed remote contains 60 branch refs and collapses to 19 independent
tips. The original nine retain their recorded outcomes. This report closes the
remaining nine by comparing commit deltas, trees, current owners, later history,
and focused contract evidence.

## Newly surfaced independent tips

| Tip | Ref | Reconciliation |
| --- | --- | --- |
| `13df8b2d` | `backup/active-remaining-dirty-state-20260713` | The one backup commit's durable odometer-ID migration, global-odometer maintenance ownership, receipt read-count assertion, configurable review controls, and removed duplicate daily navigator are present or superseded in 5.7. Its remaining differences are test formatting and ignored `build/` evidence. |
| `46611e84` | `main`, `codex/dashboard-command-center` | Disconnected initial history. Tree comparison found zero source-tip-only paths; current 5.7 contains the maintained descendants. |
| `469d9ae1` | `codex/recover-pre-control-dashboard` | Older pre-control dashboard and legacy monolithic Expense/Materials screens. Current 5.7 owns newer modular dashboard, Expense, Work Supplies, calendar, odometer, and generated trade-icon implementations. Importing these paths would recreate parallel screens and asset owners. |
| `7a79acfc` | `codex/inventory-parser-backup-20260702-2056` | The branch's 175 commits culminate in mixed-trade ambiguity safeguards across 15 changed paths. The July 12 Active safety snapshot and subsequent PEH parser-indexing, semantic-curation, mixed-receipt, confidence, and analyzer passes replace those monolithic owners with the current indexed parser architecture. The 3,647-line historical ambiguity suite remains preserved on this GitHub ref; it is not copied as a second executable suite. A bounded attempt was stopped during its first case when catalog initialization reached about 1 GB, honoring the owner's prohibition on broad Work Supplies catalog QA. |
| `86cf5321` | `codex/restore-original-dashboard` | Older restored dashboard history. Its legacy screen paths are superseded by the current modular owners; no parallel dashboard was imported. |
| `8e9771d9` | `codex/reusable-parsing-qa-foundation` | Five of ten commits have exact patch identities in 5.7. Current parity, validated-floor, stale-packet, refresh, summary, checkpoint, and Mac handoff owners contain and extend the other five documentation/status updates. |
| `94e91e1d` | `archive/stash/pdf-system-20260704-162359` | UTF-16 PDF hex decoding and binary-payload rejection moved into the shared `AppPdfTextDecoder`; the fixture inventory records covered UTF-16 and binary-hex cases. This newer shared owner supersedes the stashed inspector-local helper. |
| `b7049e96` | `codex/expense-camera` | The device-tier OCR timeout, timeout recovery, manual continuation, and focused timeout test are present in 5.7. |
| `eb4e51ee` | `archive/stash/pdf-system-20260704-162351` | The stash removed the duplicate daily Expense navigator from the home screen. Current 5.7 already has that removal and the consolidated period-navigation owner. |

## Inventory/Work Supplies boundary

The Inventory backup is preservation evidence, not a newer whole-tree owner.
Its tip predates the July 12 Active parser overhaul, which introduced the
current specialized PEH parsers, cached indexes, trade-pack loading, precedence
owners, semantic curation, mixed-receipt hardening, and scale proofs. Copying
the old monolithic parser and 3,647-line suite into 5.7 would duplicate parser
authority and reintroduce the expensive catalog-wide test behavior the owner
explicitly prohibited.

This is a semantic supersession decision, not a claim that the historical
3,647-line suite was exhaustively rerun. The source ref remains published on
GitHub so every historical case is preserved for later targeted parser work.

## Closure

- All 19 independent remote tips now have a recorded outcome across this report
  and `GIT_HISTORY_RECONCILIATION_2026_07_22.md`.
- No source branch, source checkout, stash, or source file was deleted.
- No legacy parallel screen, parser, PDF decoder, or navigation owner was
  copied into production merely to make the histories literal ancestors.
- Transfer closure remains separate from exhaustive feature QA, physical-device
  proof, and Work Supplies catalog-wide accuracy measurement.

## Focused validation

- The refreshed fixture inventory exposed a missing
  `test/pdf_text_decoder_contract_test.dart` owner. A focused shared-decoder
  contract was restored for UTF-16 big-endian, UTF-16 little-endian, and binary
  hex rejection.
- Stale Receipt Photo Review source-contract assertions were updated to follow
  the current 48-pixel primary action, 144-pixel single-photo control area,
  context-copy owner, and surface coverage-decision owner. No production camera
  behavior was changed.
- Focused remote-gap batch: 27 tests passed across OCR timeout, PDF decoding,
  reusable parser handoff parity/status, duplicate receipt attachments, receipt
  capture handoff, and real-device evidence contracts.
- Focused global-odometer maintenance save regression: 1 test passed.
- Full `flutter analyze`: no issues.
- Final duplicate scan: 1,610 production files, zero exact duplicate groups,
  220 repeated-block groups. This exactly matches the prior final scan, so the
  gap reconciliation introduced no new production duplicate group.
