# Receipt Camera Cleanup Pass Log Archive - Pass 372

Archived from the active cleanup log to keep the active file under the
500-line limit.

## Pass 372 - 12:04:00 EDT to 12:05:51 EDT

Scope:
- Hardened remaining retail QA fixtures with exact merchant-name,
  line-description, line-category, line-family, and business-use expectations.
- Pinned Walmart mixed retail and Target tender-row receipts so unknown lines,
  safety gear, vehicle supplies, and grocery water rows cannot silently drift.
- Fixed parser family mapping so `Uncategorized` lines report the
  `uncategorized` parser family instead of falling into generic expense.

Failures fixed during this pass:
- First retail QA run failed the 100.0% threshold because `Uncategorized` rows
  still carried `general_expense`, and bottled water parsed as `Groceries`
  instead of the fixture's initial `Meals` expectation. Fixed the family mapping
  and corrected the grocery expectation, then reran green.

Verification:
- Passed `dart format`, retail QA pack at 100.0%, focused mixed-category and
  business/personal Flutter tests, full receipt QA at 100.0% across 16
  fixtures, `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
