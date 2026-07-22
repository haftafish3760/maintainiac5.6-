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
| `Maintainiac_5.6_Long_Receipt` | Added the unique cross-platform long-receipt handoff document. A 62-commit batch and four isolated old tests were rejected after compatibility validation. |
| `Maintainiac_5.6_PDF_Engine` | Source history is already an ancestor of 5.7; 3,773 exact duplicates and 133 older same-path differences recorded. |
| `Maintainiac_5.6_ReceiptCamera` | Added the native-camera preference mapper and its focused test, then merged 82 compatible camera files. Full changed-file analysis and the 87-test batch passed. |
| `Maintainiac_5.6_Receipt_OCR` | Eight isolated candidates and the 33-commit batch were rejected after 49 and 262 analyzer issues respectively. Unique work remains preserved on GitHub and indexed for feature-level review. |
| `Maintainiac_5.6_Trip_Tracking` | Two isolated candidates were incompatible or semantically superseded. The 24-commit batch was rejected after 731 analyzer issues. Unique work remains preserved on GitHub and indexed for feature-level review. |
| PDF chat export | Added six compatible PDF utilities, three QA fixture/helper artifacts, three documents, and four tools. Eight focused decoder/formatter tests passed. Older typography and invoice code were rejected. |
| PDF two-folder export | Root-aware scan proved its compatible absent files duplicate the prior PDF export batch; no additional code was added. |
| `Comand 1` | Content inspection proved it is the separate `command_one` admin product. Its code was excluded from the customer app and remains in its own GitHub repository. |

## Duplicate and conflict policy

- Exact file hashes, normalized token hashes, block fingerprints, symbols, imports, Git history, protected-feature signals, and prior-source matches were indexed in SQLite.
- Exact duplicates were skipped regardless of path.
- Target-absent files were accepted only after compatibility checks.
- Existing target files were never blindly overwritten. Uncertain same-path or semantic conflicts remain in compressed decision logs and reports.
- Work Supplies/Materials signals were scanned in every source; folder names were not used as feature boundaries.

## Validation boundary

- Repository-engine unit tests passed.
- Accepted source batches received formatter/static checks and focused tests as recorded in their individual reports.
- Final full-project `flutter analyze` passed with no issues after reconciling the Receipt Camera top-bar/crop contracts.
- This was consolidation validation, not exhaustive feature QA or real-device validation.

## Evidence locations

- Human-readable reports: `docs/consolidation_reports/*.md`
- Machine summaries: `docs/consolidation_reports/*.json`
- Compressed decisions and candidate patches: `docs/consolidation_reports/*.jsonl.gz` and `*.patch.gz`
- Disk-backed comparison index: `.dart_tool/repository_consolidation/index.sqlite3` (local generated evidence)

