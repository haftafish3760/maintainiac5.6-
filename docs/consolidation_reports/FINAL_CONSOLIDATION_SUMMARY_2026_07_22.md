# Maintainiac 5.7 consolidation summary — 2026-07-22

## Preservation baseline

- Canonical target: `/Users/rbbie/Documents/Maintainiac_5.7_Active`
- Target branch: `codex/maintainiac-5.7-consolidation-20260722`
- The target began as a checksum-verified copy of `Maintainiac_5.6_Active`: 112,480 entries and 8,952,358,260 bytes matched before consolidation.
- All legitimate local Maintainiac Git commits, branches, and stashes were published to GitHub before consolidation. Verification found zero local-only commits and zero local branch tips lacking remote reachability.
- Source repositories were treated as content-read-only. No source folder was deleted.

## Source-by-source result

| Source | Final result |
| --- | --- |
| `Maintainiac_5.6` | No unique compatible project content; duplicate/generated evidence recorded. |
| `Maintainiac_5.6_Fuel_System` | Source history is already an ancestor of 5.7; 3,151 exact duplicates and 358 older same-path differences recorded, with no overwrite. |
| `Maintainiac_5.6_Long_Receipt` | The rejected 62-commit batch was reopened and compared semantically. Current 5.7 already owned the application flow; unique native ghost-image orientation normalization and real-probe source-integrity safeguards were integrated. Analyzer, Swift parse, Android compile, and focused tests passed; physical-device and real-fixture proof remain pending. |
| `Maintainiac_5.6_PDF_Engine` | Source history is already an ancestor of 5.7; 3,773 exact duplicates and 133 older same-path differences recorded. |
| `Maintainiac_5.6_ReceiptCamera` | Added the native-camera preference mapper and its focused test, then merged 82 compatible camera files. Full changed-file analysis and the 87-test batch passed. |
| `Maintainiac_5.6_Receipt_OCR` | The rejected bulk trial was reopened. All 33 source-only commits were evaluated semantically. OCR evidence, recovery, editable candidates, review totals, explicit split ownership, and the durable Jobs/context capability were integrated; newer 5.7 owners were retained; automatic OCR-owned Fuel/Inventory routing was rejected. Jobs use one shared durable owner with non-destructive legacy migration. |
| `Maintainiac_5.6_Trip_Tracking` | The rejected bulk trial was reopened. All 24 July 20 source-only commits were semantically merged or superseded, while the July 21 head was already an ancestor of 5.7. Source/build/targeted gates passed; field-route, replay, battery, lifecycle, and commercial-accuracy proof remain pending. |
| PDF branches and exports | Added the compatible utility/QA/document batch, then reopened all 101 commits unique to `origin/codex/pdf-system-resume-20260708`. Integrated the target-absent verified ZIP export/import package, invoice export preflight, canonical Document Engine facade, source-module registry, and privacy-safe health diagnostics. Restored compatible version, appended-revision, encryption, and filename-spoofing safeguards into the newer 5.7 model. The newer July 9 removal of the parallel permanent PDF archive and the newer unified report/receipt renderer remain authoritative. Focused analysis and 99 tests passed. |
| PDF two-folder export | Root-aware scan proved its compatible absent files duplicate the prior PDF export batch; no additional code was added. |
| `Comand 1` | Content inspection proved it is the separate `command_one` admin product. Its code was excluded from the customer app and remains in its own GitHub repository. |

## Duplicate and conflict policy

- Exact file hashes, normalized token hashes, block fingerprints, symbols, imports, Git history, protected-feature signals, and prior-source matches were indexed in SQLite.
- Exact duplicates were skipped regardless of path.
- Target-absent files were accepted only after compatibility checks.
- Existing target files were never blindly overwritten. Uncertain same-path or semantic conflicts remain in compressed decision logs and reports.
- Work Supplies/Materials signals were scanned in every source; folder names were not used as feature boundaries.
- The final production duplicate scan found zero exact duplicate files and no
  increase over the untouched 5.6 baseline's 220 repeated-block groups. One
  updated paired Android/iOS camera-settings fingerprint replaces an older
  paired baseline fingerprint. Imported duplicate PDF gate/verifier blocks
  were consolidated; see `DUPLICATE_CODE_AUDIT_2026_07_22.md`.

## Git-history closure

A final fetch exposed preservation refs that were absent from the first clone's
remote-tip inventory. The refreshed 60 refs collapse to 19 independent tips.
Every tip now has a semantic integration, already-present, superseded, or
intentionally excluded outcome recorded in
`GIT_HISTORY_RECONCILIATION_2026_07_22.md` and
`REMOTE_REF_GAP_RECONCILIATION_2026_07_22.md`. The refs remain non-ancestors by
design because source histories were not merged wholesale.

## Validation boundary

- Repository-engine unit tests passed.
- Accepted source batches received formatter/static checks and focused tests as recorded in their individual reports.
- Final full-project `flutter analyze` passed with no issues after the PDF,
  receipt-barcode QA, storage-boundary, and Receipt Camera reconciliations.
- `flutter build apk --debug` produced the Android debug APK, and
  `flutter build ios --debug --no-codesign` produced the iOS device
  `Runner.app`. Neither build was installed on a physical device.
- This was consolidation validation, not exhaustive feature QA or real-device validation.

## Transfer self-containment follow-up

A fresh GitHub clone at commit `739907fd` passed full analysis, 24 bounded
transfer contracts, an Android debug build, and an unsigned iOS device build
without any ignored Firebase credentials. Existing Mac-local Android/iOS
Firebase configuration paths were separately preserved and compile-verified.
See `TRANSFER_SELF_CONTAINMENT_VERIFICATION_2026_07_22.md`.

## Evidence locations

- Human-readable reports: `docs/consolidation_reports/*.md`
- Machine summaries: `docs/consolidation_reports/*.json`
- Compressed decisions and candidate patches: `docs/consolidation_reports/*.jsonl.gz` and `*.patch.gz`
- Disk-backed comparison index: `.dart_tool/repository_consolidation/index.sqlite3` (local generated evidence)
