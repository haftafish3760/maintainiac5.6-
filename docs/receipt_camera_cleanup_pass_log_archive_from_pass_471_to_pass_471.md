# Receipt Camera Cleanup Pass Log Archive - Pass 471

Archived out of `docs/receipt_camera_cleanup_pass_log.md` during Pass 507 to
keep the active cleanup log under the project line-count cap.

## Pass 471 - 18:14:30 EDT to 18:41:59 EDT

Scope:
- Propagated stitch overlap and source-preservation codes into OCR-source
  attachment document signals and OCR handoff stitch-signal counts.
- Added `docs/maintainiac_production_operating_directive.md` as the repo-level
  production trust, QA discipline, and bug-to-regression directive.
- Linked the directive from `README.md`, `PROJECT_RULES.md`, and the focused
  fast receipt guard.
- Added the production directive guard test so critical rules remain present in
  the repo.

Failures fixed during this pass:
- The directive guard initially failed because protected phrases wrapped across
  Markdown lines; made those policy phrases contiguous and reran the focused
  tests.

Verification:
- Passed targeted analyzer and focused Flutter tests for the directive and
  fast-guard contract files.
- Passed targeted analyzer and focused Flutter tests for stitch-signal handoff
  files and camera/OCR handoff regressions.
- Passed `bash -n tool/receipt_fast_guard_gate.sh`,
  `bash tool/receipt_doc_size_gate.sh`, receipt source audit with
  `--max-line-length=220`, and targeted `git diff --check`.

