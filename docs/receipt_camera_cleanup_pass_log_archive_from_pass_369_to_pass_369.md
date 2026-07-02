# Receipt Camera Cleanup Pass Log Archive - Pass 369

Archived from the active cleanup log to keep the active file under the
500-line limit.

## Pass 369 - 12:00:32 EDT to 12:01:58 EDT

Scope:
- Split receipt parser date/time extraction out of
  `expense_receipt_parser_merchant_totals_logic.dart` into
  `expense_receipt_parser_date_time_logic.dart`.
- Kept OCR row normalization, merchant-header ranking, and subtotal/tax/total
  extraction in the original merchant/totals parser part.
- Reduced `expense_receipt_parser_merchant_totals_logic.dart` from 342 lines to
  248 lines; the new date/time helper is 95 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused receipt parser,
  fuel-format, merchant-ranking, and vendor-recovery tests, source audit, `bash
  tool/receipt_fast_guard_gate.sh`, and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
