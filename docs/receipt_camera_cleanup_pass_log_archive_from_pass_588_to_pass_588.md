# Receipt Camera Cleanup Pass Log Archive - Pass 588

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line-count cap.

## Pass 588 - 11:55:00 EDT to active cleanup

Scope:
- Hardened Android and iOS native camera session argument readers so receipt
  review depth is normalized before UI labels and diagnostics can use it.
- Added native bridge source regressions requiring safe review-depth readers on
  both platforms.
- Recorded `BUG-RECEIPT-0104` under `receipt_line_review_mode`.
- Ran a broad professional QA gate and stopped on real failures instead of
  bypassing them.
- Hardened derived OCR-source attachment diagnostics so OCR-ready artifacts can
  still inherit aligned original proof-photo continuation and ghost-guide
  evidence.
- Recorded `BUG-RECEIPT-0105` under `ocr_handoff_contract`.
- Fixed app-wide regressions exposed by the broad suite: invoice PDF archive
  hashes, invoice calendar filter focus, dashboard duplicate labels, iOS-native
  navigation route guards, and archived OCR contract documentation checks.
- Fixed low-voltage receipt parser precedence for LV bracket/mud-ring and
  thermostat C-wire adapter receipt lines.
- Split tools/safety parser scoring into its own part file after the source
  audit caught an oversized parser scoring file.
- Reused generated trade-pack payloads for export manifest and chunk writing so
  the catalog pack QA does not build the same payload twice.
- Split oversized receipt parser alias, fallback, and trade-scoring god-files
  into focused part files for terms, trade families, HVAC sections, tile
  waterproofing, and tile tools while preserving behavior.
- Tightened the source audit to ignore third-party iOS plugin symlinks so the
  500-line rule reports app-owned files.
- Archived Pass 561 and Pass 562 out of the live cleanup log to keep the active
  log under the project line-count cap.

Verification:
- Fixed a stale iOS source assertion so it matches the current safer
  `doubleArgument` zoom parsing contract.
- Passed targeted Dart format/analyzer for Android and iOS native bridge source
  coverage.
- Passed focused Flutter Android and iOS native bridge regressions.
- Passed targeted receipt-camera OCR-source/continuation regressions and source
  audit contract for split receipt OCR warning coverage.
- Passed targeted app-wide regression batch:
  `test/widget_test.dart`, `test/invoices_home_screen_test.dart`,
  `test/invoice_pdf_preview_action_tracking_test.dart`,
  `test/ios_navigation_gesture_routes_test.dart`, and
  `test/expense_command_center_ocr_contract_doc_test.dart`.
- Passed work-supply parser/export regressions:
  `test/work_supply_low_voltage_tools_receipt_parser_test.dart` and
  `test/work_supply_catalog_pack_payload_test.dart`.
- Passed focused parser cleanup regressions for work-supply catalog aliases,
  electrical/HVAC/low-voltage, large trade matrix, and tile parser coverage.
- Passed
  `dart analyze lib/screens/work_supplies/data/work_supply_receipt_parser.dart`.
- Passed `git diff --check`.
- Focused work-supply data source audit showed no hand-written receipt parser
  scoring files over the 500-line cap; remaining failures were generated
  catalog data files that need a separate generated-data strategy.
