# Maintainiac Receipt Flow: Complete Current-State Dossier

Generated: 2026-08-01 07:22 PM EDT

Checkout: `/Users/rbbie/Documents/Maintainiac_5.7_Active`

Branch observed: `feature/receipt-flow-redesign`

## Purpose

This document records the current receipt-photo workflow, long-receipt assembly,
OCR handoff, saved-image handling, QA harnesses, privacy boundaries, confirmed
work, unresolved work, and the order in which remaining work should be completed.

This workflow handles exactly one receipt at a time:

- One selected or captured image means one regular receipt.
- Two or more selected or captured images mean sections of that same long
  receipt.
- Multiple unrelated receipts in one workflow are not supported.
- Repeated text is alignment evidence between neighboring sections. It does not
  mean the app is handling multiple receipts.
- Merchant layouts must never be memorized for image assembly.

## Accuracy Meaning

The target is 90-95 percent reliable behavior for the supported single-receipt
workflow. That target cannot be claimed from source inspection or synthetic tests
alone. It requires all of the following:

1. Green deterministic QA and regression gates.
2. Green synthetic image tests covering realistic damage and transformations.
3. Repeated tests with real receipts on supported physical devices.
4. Verified OCR handoff using the assembled full-quality source.
5. Verified recovery behavior when automatic assembly is unsafe.

At this snapshot, synthetic coverage is broad, but 90-95 percent real-world
accuracy is not yet proven.

## User Workflow Contract

### Entry

The receipt source chooser supports:

- Capture photo.
- Upload one or more photos.
- Upload a PDF or file through its separately owned flow.
- Paste or import text.
- Open receipt settings.
- Open receipt help.

Receipt Assistance remains optional. Manual entry remains available.

### One Photo

One image remains a regular receipt. It must not enter long-receipt assembly.
The person reviews the image, chooses the saved-image size, and continues to
receipt details. Full-quality source data is used for OCR before cleanup when
Receipt Assistance is enabled.

### Two Or More Photos

Two or more images are sections of one long receipt. The expected flow is:

1. Preserve every selected section.
2. Number the sections visibly.
3. Allow section selection, ordering, replacement, retake, and removal.
4. Start automatic assembly after Continue.
5. Use adjacent repeated-content evidence and image geometry.
6. Show the full combined receipt when assembly is safe.
7. Allow pinch zoom, pan while zoomed, double-tap zoom, and visible reset zoom.
8. If automatic assembly is unsafe, identify the failed neighboring pair and
   offer manual alignment or ordered-section fallback.
9. Continue to the saved-image choice.
10. Give OCR the full-quality combined source when a safe combined source exists.

### Long-Receipt Evidence

Automatic assembly uses generic evidence:

- Adjacent repeated text lines when on-device OCR evidence is available.
- Visual overlap between the bottom of one section and top of the next.
- Receipt-like foreground and edge geometry.
- Scale correction.
- Rotation correction.
- Perspective correction.
- Horizontal and vertical placement.
- Continuity across several detailed image bands.
- Header and footer evidence for order correction when text evidence is strong.

The algorithm must fail closed when the evidence is weak. It must preserve the
ordered originals rather than inventing or deleting receipt rows.

## Existing Long-Receipt Engine

The current engine includes:

- Unique and normalized input-path validation.
- Duplicate-path rejection.
- Duplicate-section-image safety.
- Bounded working width to control memory and runtime.
- Device-specific maximum output pixels and height.
- Background-isolate assembly.
- Adjacent-pair overlap matching.
- Scale-tolerant matching.
- Rotation and perspective correction.
- Horizontal offset handling.
- Continuity corroboration.
- Optional OCR-line corroboration.
- Confidence thresholds that reject unsafe joins.
- Manual overlap adjustment.
- Manual zero-overlap joining.
- Manual scale adjustment.
- Manual rotation adjustment.
- Manual horizontal adjustment.
- Pair-specific failure reporting.
- Ordered fallback when assembly is unsafe.
- Temporary combined-preview cleanup.
- Timeout fallback without trapping the user.
- Final OCR-source assembly after full-quality preparation.

The engine processes every adjacent pair. A three-section receipt evaluates
sections 1-2 and 2-3 independently so one transform does not compound across
the full receipt.

## Existing Review And Recovery UI

The current review system includes:

- Visible photo numbering.
- Horizontal section thumbnail strip during ordered-photo review.
- Automatic combined-receipt working state.
- Full combined-receipt preview.
- Aspect-ratio-preserving image display.
- No fixed decode height for tall combined receipts.
- Pinch and double-tap zoom.
- Pan only while zoomed.
- Visible reset-zoom control.
- Bounded pan margin.
- Back navigation from combined review to section review.
- Redo action.
- Cancel action.
- Use combined receipt action.
- Use ordered receipt sections fallback action.
- Failed-pair targeting.
- Previous-bottom and next-top ghost alignment view.
- High-visibility ghost overlay.
- Manual alignment controls for overlap, size, position, and rotation.
- Responsive action layouts for narrow screens and enlarged text.
- Gear icon for settings and accessible help control.
- Scroll-safe first-use Receipt Assistance choice.

## Saved Image And OCR Source

The user-facing saved-image step is called Data Saver. Its visible choices now
include:

- Original photo.
- High-quality saved proof.
- Balanced saved proof.
- Higher-storage-savings proof.

The implementation separates:

- Temporary full-quality source used for OCR.
- User-selected saved proof copy.
- Generated stitch preview.
- Final OCR source.

The original source is not silently retained unless the user chooses the
original-photo option. Generated temporary artifacts have cleanup paths.

### Important Unresolved Storage Contract

The current save path prepares and retains saved proof copies for each original
section while the OCR path may use one combined image. The intended product
contract must be verified and then enforced consistently:

- If the saved proof should be one combined long-receipt image, the current
  result contract requires additional implementation and regression coverage.
- If saved proofs should remain as numbered sections while OCR uses one combined
  source, every later receipt-details and attachment view must present those
  sections as one receipt without confusion.

This is a release-significant item and must not be assumed complete.

## OCR Handoff

The current flow is designed to:

- Prepare OCR sources from the clearest available full-quality input.
- Use the safely combined receipt as the OCR source when assembly succeeds.
- Use ordered individual sections when assembly fails safely.
- Preserve section order in fallback.
- Carry stitch status, confidence, failed-pair, overlap, and source diagnostics.
- Keep OCR results editable and advisory until the user confirms them.
- Avoid treating parser output as authoritative financial data.

Receipt parsing itself is a separate downstream concern. This lane owns the
source images and the handoff contract, not merchant-specific parser accuracy.

## Privacy And Security Boundaries

Receipts can contain names, addresses, account fragments, purchase history, and
financial information. The required boundaries are:

- Processing remains local by default.
- Receipt Assistance is opt-in.
- Raw receipt text, merchant text, prices, card fragments, and images must not
  appear in analytics or routine diagnostics.
- Diagnostics should contain statuses, counts, reason codes, confidence buckets,
  anonymous section indexes, and timing buckets only.
- Temporary full-quality OCR sources must be deleted only after the accepted
  result no longer depends on them.
- Cancellation, timeout, crash recovery, retake, and replacement must clean up
  only app-created temporary artifacts.
- User-owned source files must never be deleted by cleanup code.
- Saved-proof backup is a separate user-controlled decision.
- Any future improvement-data program requires explicit consent, strict
  redaction, bounded retention, and a separate security review before launch.

### Security Work Still Required

- Complete a bounded data-flow audit from picker/camera staging through cleanup.
- Verify no raw OCR text or image bytes enter logs, crash reports, admin metrics,
  filenames, or diagnostic maps.
- Verify cleanup ownership for every success, cancellation, timeout, exception,
  retake, replacement, and process-restart path.
- Verify Android and iOS temporary-file protection and backup-exclusion policy.
- Verify external upload/share paths cannot run without an explicit user action.
- Add regression fixtures containing fake names, fake card fragments, and fake
  addresses to prove diagnostics remain metadata-only.

## Work Completed In The Latest Hardening Session

The following changes were made during the latest bounded hardening work:

1. Added visible reset zoom for a zoomed combined receipt.
2. Added bounded panning margin for zoomed receipt inspection.
3. Fixed the adjacent-pair index clamp after photo removal or replacement.
4. Replaced isolated edge thumbnails with a direct ghost alignment overlay.
5. Made the ghost respond to overlap, scale, rotation, horizontal movement, and
   zero-overlap mode.
6. Added a visible alignment boundary and concise labels.
7. Made long-receipt completion actions responsive on narrow displays and at
   enlarged text sizes.
8. Made order controls responsive on narrow displays and at enlarged text sizes.
9. Replaced confusing order wording with `Arrange Photos` wording.
10. Replaced the settings wrench/text treatment with the expected gear icon.
11. Added accessible tooltips for settings and help.
12. Made the first-use Receipt Assistance choice scroll-safe and inset-aware.
13. Added the previously described but missing Original photo Data Saver choice.
14. Split the oversized Data Saver source into files under the 500-line source
    limit.
15. Updated stale regression contracts to match the current combined-receipt UI.
16. Added regression-ledger entries for every confirmed defect above.
17. Corrected new ledger categories after the ledger gate rejected invalid ones.

## Attribution

The repository contains receipt work from multiple Codex sessions and models.
Git history can identify commits, but it cannot reliably prove which model wrote
every uncommitted line. Therefore:

- The 17-item list above is attributable to the latest hardening session.
- The broader engine, OCR handoff, staging, cleanup, and QA foundation is
  inherited and has been modified across prior sessions.
- No unsupported claim is made that one model authored the whole receipt system.
- Exact line-by-line authorship should not be used as a readiness signal.

## QA And Regression Harnesses

The repository already has receipt-specific automation. The principal harnesses
are:

- `tool/receipt_camera_qa_gate.sh`: phased camera/receipt regression gate with
  quick, stitch, milestone, and full modes.
- `tool/receipt_stitch_contract_health.sh`: focused long-receipt assembly gate.
- `tool/receipt_long_receipt_stitch_health.sh`: fixture-driven long-receipt QA.
- `tool/receipt_camera_changed_gate.sh`: selects checks from changed tracked
  receipt files.
- `tool/receipt_camera_pipeline_gate.sh`: pipeline contract checks.
- `tool/receipt_camera_stitch_gate.sh`: stitch-specific camera gate.
- `tool/receipt_fast_guard_gate.sh`: inexpensive guard checks.
- `tool/receipt_quality_gate.sh`: broader receipt-quality gate.
- `tool/receipt_shared_quality_gate.sh`: shared receipt-quality checks.
- `tool/receipt_ocr_focus_gate.sh`: OCR-focused checks.
- `tool/receipt_ocr_audit.sh`: OCR source and contract audit.
- `tool/receipt_bug_regression_ledger_gate.dart`: validates the bug ledger.
- `tool/receipt_synthetic_stitch_dataset_audit.dart`: validates synthetic stitch
  dataset coverage.
- `tool/receipt_real_device_matrix_gate.dart`: validates device-matrix evidence.
- `tool/receipt_real_device_result_gate.dart`: validates recorded device results.
- `tool/receipt_external_dataset_gate.dart`: guards externally sourced fixture
  use and licensing boundaries.
- `tool/receipt_external_fixture_schema_gate.dart`: validates external fixture
  metadata.
- `tool/receipt_cleanup_log_gate.sh`: checks cleanup-log contracts.
- `tool/receipt_doc_size_gate.sh`: checks bounded documentation surfaces.
- `tool/receipt_quiet_batch_policy_gate.dart`: checks quiet batch-test policy.

The receipt test inventory at this snapshot contains approximately:

- 428 receipt-related test files.
- 63 stitch, order, overlap, or long-receipt test files.
- 61 OCR-related test files.
- 17 privacy or diagnostic test files.
- 19 storage, Data Saver, or proof test files.
- 22 receipt-review UI test files.

Counts overlap by subject and are inventory counts, not proof that every test is
valuable or currently green.

### Stitch Harness Coverage

The stitch health harness has focused modes for:

- Delayed overlap.
- General edge cases.
- Output size caps.
- Phone-window and screenshot inputs.
- Passenger-seat transformations.
- Long stacks.
- Extreme aspect ratios.
- Duplicate sections.
- Ugly, faded, stained, worn, and torn receipts.
- Scale, rotation, perspective, and horizontal drift.
- Uploaded screenshots.
- Section ordering.
- Bad and unreadable inputs.
- Manual overlap.
- OCR handoff.
- Ghost-guide handoff.
- Synthetic dataset auditing.
- Source-file size limits.
- Fast, core, milestone, and full bundles.

### Latest Confirmed QA Evidence

The latest focused evidence includes:

- Long-receipt UI/layout regression bundle: passed.
- Targeted analyzer for changed receipt-review files: passed.
- Stitch source-size gate: passed.
- Core synthetic stitch algorithm bundle: passed.
- Remaining geometry and damaged-receipt bundle: passed.
- Receipt flow lifecycle/save/exit suite: passed after correcting stale test
  expectations.
- Receipt import source tests: passed.
- First-use/camera layout tests: passed.
- Data Saver/help focused tests: passed.
- Receipt regression-ledger gate: passed after category correction.
- `git diff --check` on the latest receipt hardening files: passed.

No physical-device field result is claimed by this evidence.

## Confirmed Defects Fixed In The Latest Session

- No visible reset after zooming a combined receipt.
- Insufficient pan margin at receipt edges.
- Stale pair index could reference a nonexistent final pair.
- Manual alignment lacked a direct ghost comparison.
- Action rows could overflow on narrow screens or enlarged text.
- Order wording was unclear.
- Receipt settings used the wrong visual symbol.
- First-use Receipt Assistance content could overflow vertically.
- Original-photo storage was described but unavailable as a visible choice.
- Data Saver source exceeded the 500-line source limit.
- New ledger rows initially used unsupported categories.

## Known Limitations And Remaining Work

### Release-Blocking

1. Decide and enforce the combined saved-proof contract described above.
2. Run the full receipt-flow harness after the current shared dirty worktree is
   reconciled enough to make failures attributable.
3. Complete the receipt privacy and temporary-artifact ownership audit.
4. Verify every route from capture/upload through review, assembly, Data Saver,
   OCR handoff, manual fallback, and receipt details.
5. Verify back, cancel, process interruption, timeout, and retry behavior at each
   stage.
6. Validate on a physical Galaxy S24 Ultra with representative real receipts.
7. Validate on at least one older Android device with lower memory and camera
   capability.
8. Validate iOS separately before claiming cross-platform readiness.

### Accuracy And Fixture Work

1. Add more independent real receipt specimens. Repeatedly using the same receipt
   cannot establish general accuracy.
2. Cover two through at least six sections from the same receipt.
3. Cover wrong selection order.
4. Cover a missing middle section.
5. Cover duplicate selection.
6. Cover one unreadable section among readable neighbors.
7. Cover zero overlap caused by aggressive user cropping.
8. Cover large and small overlap.
9. Cover folded, wrinkled, curled, torn, stained, faded, glossy, shadowed, and
   unevenly lit receipts.
10. Cover screenshots with phone UI borders.
11. Cover mixed portrait orientation and slight rotation.
12. Cover different camera distances and scales between neighboring sections.
13. Cover English and United States Spanish OCR evidence without making image
    assembly merchant-specific.

### UI And Accessibility

1. Verify the complete flow visually on small and large Android screens.
2. Verify no controls obscure the receipt inspection area.
3. Verify the ghost is visible under bright and dark receipt backgrounds.
4. Verify combined tall receipts remain correctly proportioned.
5. Verify every important action remains reachable at large text sizes.
6. Verify screen-reader names and traversal order.
7. Verify the user can identify and replace a failed section without restarting.
8. Verify the Data Saver rail does not hide too much of the receipt on a narrow
   phone and remains easy to dismiss and reopen.

### Performance And Reliability

1. Measure two-, three-, and six-section assembly time on real devices.
2. Measure peak memory on older Android hardware.
3. Verify isolate timeout cleanup under repeated cancellation.
4. Verify no generated previews remain after completed, canceled, or failed
   reviews.
5. Verify very tall output falls back safely instead of exhausting memory.
6. Verify rapid repeated Continue taps cannot start duplicate work.
7. Verify app background/foreground transitions during OCR and assembly.

## Recommended Completion Order

1. Resolve the combined saved-proof contract.
2. Add regressions for that contract and its cleanup behavior.
3. Complete privacy and artifact-ownership checks.
4. Run focused changed-file and stitch gates.
5. Run the receipt milestone gate.
6. Fix every attributable failure.
7. Run the full receipt gate once at a clean milestone.
8. Perform S24 live testing with several independent receipts.
9. Add every confirmed device defect to the regression ledger.
10. Repeat on older Android hardware.
11. Perform iOS validation.
12. Only then calculate a measured accuracy range.

## Current Repository Risk

At the time of this snapshot, the receipt-scoped worktree contained many existing
changes: 139 modified paths, 28 untracked paths, and 3 deleted paths within the
broad receipt-related path filter. These changes may belong to multiple active
sessions. They must not be mass-staged, mass-reverted, or attributed to one model.

No commit or push was made while creating this dossier.

## Readiness Statement

The receipt flow has a substantial implementation and unusually broad synthetic
QA foundation. It is not empty, and it is not a simple placeholder. However, it
is not yet honest to call it 90-95 percent proven or world-class. The remaining
work is concentrated in the saved-proof contract, end-to-end flow verification,
privacy/cleanup evidence, real-device performance, and representative field
receipts.

The correct standard is measured evidence, not pass counts or the number of lines
changed.



<!-- GENERATED_RECEIPT_INVENTORY_BEGIN -->
# Generated Receipt Capture And Long-Receipt Evidence Appendices

These appendices cover only single-receipt capture, upload, image review, long-receipt assembly, OCR-source handoff, Data Saver, lifecycle, privacy, and directly supporting QA. PDF, maintenance, fuel, inventory, materials, barcode, and merchant-parser lanes are excluded.

## Appendix A: Current In-Scope Git Changes

- ` M docs/receipt_bug_regression_ledger.md`
- ` M lib/shared/widgets/receipt_capture/incoming_receipt_share_media.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_assistance_policy_device_capability_assist.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_attachment_list.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_attachment_ocr_recovery_advice.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_risk_flags.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_attachment_panel_build.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_attachment_publish_helpers.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_attachment_record.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_attachment_status_widgets.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_attachment_storage_models.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_attachment_summary.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_attachment_text_document_actions.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_camera_first_use_intro_sheet.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_capture.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_risks.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_capture_models.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_capture_review_result_handoff.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_capture_review_result_handoff_labels.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_capture_review_storage_settings.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_capture_settings_data_saver.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_capture_stitch_model_helpers.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_capture_stitch_models.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_capture_stitch_pair_models.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_image_processor.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_image_processor_enhancement_helpers.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_image_processor_models.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_image_processor_quality_helpers.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_image_processor_resize_helpers.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_image_processor_scan_helpers.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_api.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_helpers.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_scoring_helpers.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_transform_helpers.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_image_processor_storage_helpers.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_native_camera_service_contract_helpers.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_native_camera_session_ghost_guide.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_native_camera_settings_policy.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_native_camera_settings_session.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_native_camera_shell_ghost_guidance.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_native_capture_staging_recovery_record.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_ocr_diagnostics_coverage.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_ocr_diagnostics_labels.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_ocr_service.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_ocr_source_handoff_long_receipt.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_coverage_decision_from_signals.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_coverage_decision_labels.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_alignment_actions.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_alignment_guide.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_async_work.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_build.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_crop_and_proof_controls.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_exit_actions.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_exit_stitch_actions.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_mode_controls.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_order_actions.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_order_controls.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_photo_surface.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_status.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_tray.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_retake_order.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart`
- ` D lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_chips.dart`
- ` D lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_controls.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_pair_preview.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_preview_async.dart`
- ` D lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_readiness.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_surface.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_surface_controls.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_thumbnail_strip.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_photo_review_ui_config.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_pipeline_trace.dart`
- ` M lib/shared/widgets/receipt_capture/receipt_scanner_service.dart`
- ` M test/expense_receipt_assisted_review_flow_test.dart`
- ` M test/expense_receipt_assisted_review_handoff_native_test.dart`
- ` M test/expense_receipt_assisted_review_save_guardrails_test.dart`
- ` M test/expense_receipt_category_rules_test.dart`
- ` M test/expense_receipt_entry_header_layout_test.dart`
- ` M test/expense_receipt_entry_start_guide_test.dart`
- ` M test/expense_receipt_generic_ocr_handoff_performance_test.dart`
- ` M test/expense_receipt_line_split_entry_contract_test.dart`
- ` M test/expense_receipt_line_total_calculation_contract_test.dart`
- ` M test/expense_receipt_manual_optional_evidence_contract_test.dart`
- ` M test/expense_receipt_manual_screen_rebuild_contract_test.dart`
- ` M test/expense_receipt_review_mode_totals_test.dart`
- ` M test/receipt_attachment_panel_actions_test.dart`
- ` M test/receipt_attachment_panel_recovery_contract_test.dart`
- ` M test/receipt_camera_capture_layout_test.dart`
- ` M test/receipt_camera_help_flow_test.dart`
- ` M test/receipt_camera_long_receipt_guidance_test.dart`
- ` M test/receipt_camera_ocr_source_handoff_test.dart`
- ` M test/receipt_camera_phase3_viewer_contract_test.dart`
- ` M test/receipt_camera_phase4_review_contract_test.dart`
- ` M test/receipt_camera_phase5_long_receipt_contract_test.dart`
- ` M test/receipt_camera_phase6_stitching_handoff_contract_test.dart`
- ` M test/receipt_camera_phase8_storage_proof_timing_contract_test.dart`
- ` M test/receipt_capture_flow_assist_opt_in_contract_test.dart`
- ` M test/receipt_capture_flow_handoff_contract_test.dart`
- ` M test/receipt_capture_flow_handoff_order_test.dart`
- ` M test/receipt_capture_settings_data_saver_test.dart`
- ` M test/receipt_capture_settings_store_test.dart`
- ` M test/receipt_capture_storage_estimate_test.dart`
- ` M test/receipt_continuation_ghost_handoff_contract_test.dart`
- ` M test/receipt_image_data_saver_test.dart`
- ` M test/receipt_import_source_sheet_test.dart`
- ` M test/receipt_native_android_bridge_capture_quality_contract_test.dart`
- ` M test/receipt_native_android_bridge_close_controls_test.dart`
- ` M test/receipt_native_camera_previous_section_channel_test.dart`
- ` M test/receipt_native_camera_session_limits_test.dart`
- ` M test/receipt_native_ghost_orientation_contract_test.dart`
- ` M test/receipt_native_pinch_zoom_contract_test.dart`
- ` M test/receipt_photo_review_async_lifecycle_test.dart`
- ` M test/receipt_photo_review_continuation_copy_test.dart`
- ` M test/receipt_photo_review_continuation_crop_contract_test.dart`
- ` M test/receipt_photo_review_controls_layout_test.dart`
- ` M test/receipt_photo_review_edit_evidence_test.dart`
- ` M test/receipt_photo_review_exit_completion_test.dart`
- ` M test/receipt_photo_review_quality_handoff_test.dart`
- ` M test/receipt_photo_review_retake_order_test.dart`
- ` M test/receipt_photo_review_save_lifecycle_test.dart`
- ` M test/receipt_qa_runner_pack_focus_test.dart`
- ` M test/receipt_stitching_high_overlap_test.dart`
- ` M test/receipt_stitching_horizontal_drift_test.dart`
- ` M test/receipt_stitching_horizontal_placement_test.dart`
- ` M test/receipt_stitching_long_stack_test.dart`
- ` M test/receipt_stitching_manual_overlap_test.dart`
- ` M test/receipt_stitching_real_fixture_probe_test.dart`
- ` M test/receipt_stitching_result_contract_test.dart`
- ` M test/receipt_stitching_test.dart`
- ` M test/receipt_stitching_ugly_long_receipt_test.dart`
- ` M test/receipt_stitching_uploaded_screenshot_test.dart`
- ` M test/receipt_stitching_variants_test.dart`
- ` M test/receipt_stitching_worn_receipt_test.dart`
- ` M tool/receipt_camera_qa_gate.sh`
- ` M tool/receipt_stitch_contract_health.sh`
- `?? docs/receipt_entry_ui_contract.md`
- `?? lib/shared/widgets/receipt_capture/receipt_capture_stitch_result_labels.dart`
- `?? lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_duplicate_helpers.dart`
- `?? lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_sources.dart`
- `?? lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_support.dart`
- `?? lib/shared/widgets/receipt_capture/receipt_ocr_service_stitch_evidence.dart`
- `?? lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_details.dart`
- `?? lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_actions.dart`
- `?? lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_ghost_preview.dart`
- `?? lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_order_evidence.dart`
- `?? lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_pair_navigator.dart`
- `?? lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_photo.dart`
- `?? lib/shared/widgets/receipt_capture/receipt_stitch_text_evidence.dart`
- `?? test/expense_receipt_assistance_setup_flow_test.dart`
- `?? test/expense_receipt_classification_step_contract_test.dart`
- `?? test/expense_receipt_entry_single_page_route_test.dart`
- `?? test/expense_receipt_line_review_layout_test.dart`
- `?? test/expense_receipt_ocr_line_recovery_test.dart`
- `?? test/expense_receipt_recap_mixed_allocation_visibility_test.dart`
- `?? test/receipt_long_capture_guide_layout_test.dart`
- `?? test/receipt_photo_review_back_navigation_contract_test.dart`
- `?? test/receipt_photo_review_long_receipt_runtime_guard_test.dart`
- `?? test/receipt_photo_review_stitch_safety_contract_test.dart`
- `?? test/receipt_proof_target_size_policy_test.dart`
- `?? test/receipt_saved_image_step_contract_test.dart`
- `?? test/receipt_saved_proof_choice_progression_test.dart`
- `?? test/receipt_stitch_final_timeout_recovery_test.dart`
- `?? test/receipt_stitch_real_device_probe_test.dart`
- `?? test/receipt_stitch_text_evidence_test.dart`
- `?? test/receipt_stitch_working_resolution_contract_test.dart`
- `?? test/receipt_stitching_perspective_test.dart`
- `?? tool/receipt_flow_route_audit.dart`
- `?? tool/receipt_flow_route_audit_report.dart`
- `?? tool/receipt_stitch_probe.dart`

## Appendix B: Production Source Inventory

### `lib/shared/receipts/receipt_client_proof_contract.dart`

- Current lines: 338.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_client_proof_contract`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/receipts/receipt_layout_analyzer.dart`

- Current lines: 229.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_layout_analyzer`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/receipts/receipt_layout_intelligence.dart`

- Current lines: 319.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_layout_intelligence`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/receipts/receipt_layout_patterns.dart`

- Current lines: 42.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_layout_patterns`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/receipts/receipt_line_models.dart`

- Current lines: 355.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_line_models`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/receipts/receipt_line_models_serialization.dart`

- Current lines: 129.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_line_models_serialization`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/receipts/receipt_line_selection_contract.dart`

- Current lines: 407.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_line_selection_contract`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/receipts/receipt_ocr_contract.dart`

- Current lines: 37.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_contract`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/receipts/receipt_ocr_handoff.dart`

- Current lines: 93.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_handoff`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/receipts/receipt_processing_contract.dart`

- Current lines: 97.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_processing_contract`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/receipts/receipt_text_quality_contract.dart`

- Current lines: 158.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_text_quality_contract`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/incoming_receipt_share.dart`

- Current lines: 272.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `incoming_receipt_share`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/incoming_receipt_share_media.dart`

- Current lines: 153.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `incoming_receipt_share_media`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_acquired_photo_staging.dart`

- Current lines: 41.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_acquired_photo_staging`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart`

- Current lines: 27.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_brain_footprint.dart`

- Current lines: 88.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_brain_footprint`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_brain_summary_diagnostics.dart`

- Current lines: 251.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_brain_summary_diagnostics`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_brain_summary_privacy_diagnostics.dart`

- Current lines: 88.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_brain_summary_privacy_diagnostics`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_brain_summary_readiness.dart`

- Current lines: 213.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_brain_summary_readiness`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_cloud_plan.dart`

- Current lines: 254.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_cloud_plan`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_decision.dart`

- Current lines: 206.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_decision`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_deployment_recommendation.dart`

- Current lines: 144.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_deployment_recommendation`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_device_capability.dart`

- Current lines: 277.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_device_capability`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_device_capability_assist.dart`

- Current lines: 176.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_device_capability_assist`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_device_capability_camera.dart`

- Current lines: 77.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_device_capability_camera`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_device_profile.dart`

- Current lines: 1.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_device_profile`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_enums.dart`

- Current lines: 66.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_enums`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_feature_footprint.dart`

- Current lines: 208.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_feature_footprint`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_hardware_labels.dart`

- Current lines: 86.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_hardware_labels`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_hardware_profile.dart`

- Current lines: 332.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_hardware_profile`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_install_footprint_strategy.dart`

- Current lines: 220.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_install_footprint_strategy`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_install_strategy.dart`

- Current lines: 1.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_install_strategy`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_local_only_gate.dart`

- Current lines: 188.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_local_only_gate`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_required_base_release.dart`

- Current lines: 125.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_required_base_release`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_assistance_policy_runtime_profile.dart`

- Current lines: 61.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_assistance_policy_runtime_profile`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_button.dart`

- Current lines: 29.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_button`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart`

- Current lines: 291.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_camera_actions`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_camera_fallback_actions.dart`

- Current lines: 235.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_camera_fallback_actions`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_duplicate_detector.dart`

- Current lines: 48.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_duplicate_detector`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart`

- Current lines: 111.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_import_actions`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_initial_state.dart`

- Current lines: 53.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_initial_state`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_list.dart`

- Current lines: 279.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_list`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_native_signal_documents.dart`

- Current lines: 210.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_native_signal_documents`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_native_signal_helpers.dart`

- Current lines: 215.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_native_signal_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart`

- Current lines: 327.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_ocr_actions`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_ocr_recovery_advice.dart`

- Current lines: 145.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_ocr_recovery_advice`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_continuation_signals.dart`

- Current lines: 100.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_ocr_source_continuation_signals`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_risk_flags.dart`

- Current lines: 162.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_ocr_source_risk_flags`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_signals.dart`

- Current lines: 268.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_ocr_source_signals`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart`

- Current lines: 223.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_panel`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_panel_build.dart`

- Current lines: 193.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_panel_build`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_panel_controller.dart`

- Current lines: 51.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_panel_controller`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_publish_helpers.dart`

- Current lines: 205.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_publish_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_publish_signals.dart`

- Current lines: 189.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_publish_signals`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_record.dart`

- Current lines: 296.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_record`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_record_serialization.dart`

- Current lines: 42.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_record_serialization`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_recovery_actions.dart`

- Current lines: 127.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_recovery_actions`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_review_read_actions.dart`

- Current lines: 362.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_review_read_actions`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_status_widgets.dart`

- Current lines: 311.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_status_widgets`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_storage_models.dart`

- Current lines: 320.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_storage_models`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_summary.dart`

- Current lines: 106.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_summary`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_target_guidance.dart`

- Current lines: 65.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_target_guidance`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_attachment_text_document_actions.dart`

- Current lines: 189.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_attachment_text_document_actions`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_camera_first_use_intro_sheet.dart`

- Current lines: 189.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_camera_first_use_intro_sheet`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_camera_fixture_matrix.dart`

- Current lines: 241.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_camera_fixture_matrix`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart`

- Current lines: 94.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_camera_help_sheet`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_camera_permission.dart`

- Current lines: 44.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_camera_permission`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_camera_result_diagnostics.dart`

- Current lines: 193.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_camera_result_diagnostics`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_camera_result_models.dart`

- Current lines: 193.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_camera_result_models`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_camera_storage_policy.dart`

- Current lines: 50.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_camera_storage_policy`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture.dart`

- Current lines: 26.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_diagnostics_policy.dart`

- Current lines: 90.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_diagnostics_policy`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_flow.dart`

- Current lines: 118.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_flow`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_flow_attachment_helpers.dart`

- Current lines: 24.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_flow_attachment_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_flow_capture_and_review.dart`

- Current lines: 314.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_flow_capture_and_review`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_flow_continuation_signals.dart`

- Current lines: 185.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_flow_continuation_signals`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_risks.dart`

- Current lines: 222.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_flow_handoff_risks`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_signals.dart`

- Current lines: 251.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_flow_handoff_signals`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_flow_helpers.dart`

- Current lines: 211.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_flow_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_flow_models.dart`

- Current lines: 283.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_flow_models`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_flow_native_signals.dart`

- Current lines: 205.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_flow_native_signals`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_flow_ocr_helpers.dart`

- Current lines: 33.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_flow_ocr_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_flow_recovery.dart`

- Current lines: 233.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_flow_recovery`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_flow_recovery_results.dart`

- Current lines: 165.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_flow_recovery_results`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_flow_review_result.dart`

- Current lines: 133.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_flow_review_result`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_models.dart`

- Current lines: 257.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_models`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_readiness_decision.dart`

- Current lines: 127.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_readiness_decision`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_brain_install_metadata.dart`

- Current lines: 189.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_brain_install_metadata`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_completion.dart`

- Current lines: 285.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_completion`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_continuation.dart`

- Current lines: 230.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_continuation`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_handoff.dart`

- Current lines: 163.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_handoff`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_handoff_brain_counts.dart`

- Current lines: 189.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_handoff_brain_counts`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_handoff_counts.dart`

- Current lines: 156.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_handoff_counts`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_handoff_labels.dart`

- Current lines: 299.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_handoff_labels`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_handoff_storage.dart`

- Current lines: 177.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_handoff_storage`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_helper_control_health_codes.dart`

- Current lines: 219.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_helper_control_health_codes`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_helper_count_functions.dart`

- Current lines: 98.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_helper_count_functions`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_helper_counts.dart`

- Current lines: 263.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_helper_counts`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_helper_diagnostics.dart`

- Current lines: 115.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_helper_diagnostics`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_helper_health_codes.dart`

- Current lines: 379.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_helper_health_codes`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_helpers.dart`

- Current lines: 24.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_metadata.dart`

- Current lines: 217.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_metadata`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_native_brain_signals.dart`

- Current lines: 260.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_native_brain_signals`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_native_outcomes.dart`

- Current lines: 215.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_native_outcomes`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_native_signals.dart`

- Current lines: 231.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_native_signals`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_next_review.dart`

- Current lines: 133.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_next_review`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_section_order_counts.dart`

- Current lines: 421.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_section_order_counts`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_section_order_helpers.dart`

- Current lines: 453.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_section_order_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_section_order_review.dart`

- Current lines: 180.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_section_order_review`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_settings_health.dart`

- Current lines: 41.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_settings_health`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_result_warnings.dart`

- Current lines: 220.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_result_warnings`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_review_storage_settings.dart`

- Current lines: 168.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_review_storage_settings`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_runtime_settings.dart`

- Current lines: 484.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_runtime_settings`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_settings_data_saver.dart`

- Current lines: 179.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_settings_data_saver`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart`

- Current lines: 330.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_settings_sheet`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart`

- Current lines: 403.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_settings_store`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_stitch_model_helpers.dart`

- Current lines: 89.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_stitch_model_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_stitch_models.dart`

- Current lines: 396.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_stitch_models`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_stitch_pair_models.dart`

- Current lines: 163.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_stitch_pair_models`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_stitch_result_labels.dart`

- Current lines: 114.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_stitch_result_labels`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_storage_estimate.dart`

- Current lines: 96.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_storage_estimate`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_capture_ui_config.dart`

- Current lines: 143.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_capture_ui_config`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_device_capability_service.dart`

- Current lines: 105.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_device_capability_service`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart`

- Current lines: 304.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_edge_cropper`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_edge_cropper_handles.dart`

- Current lines: 153.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_edge_cropper_handles`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_image_picker.dart`

- Current lines: 52.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_image_picker`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_image_processor.dart`

- Current lines: 306.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_image_processor`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_image_processor_enhancement_helpers.dart`

- Current lines: 270.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_image_processor_enhancement_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_image_processor_exposure_helpers.dart`

- Current lines: 70.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_image_processor_exposure_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_image_processor_models.dart`

- Current lines: 208.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_image_processor_models`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_image_processor_quality_helpers.dart`

- Current lines: 312.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_image_processor_quality_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_image_processor_resize_helpers.dart`

- Current lines: 33.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_image_processor_resize_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_image_processor_scan_helpers.dart`

- Current lines: 310.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_image_processor_scan_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_image_processor_source_prep.dart`

- Current lines: 122.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_image_processor_source_prep`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_api.dart`

- Current lines: 474.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_image_processor_stitch_api`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_duplicate_helpers.dart`

- Current lines: 143.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_image_processor_stitch_duplicate_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_helpers.dart`

- Current lines: 487.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_image_processor_stitch_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_scoring_helpers.dart`

- Current lines: 496.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_image_processor_stitch_scoring_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_sources.dart`

- Current lines: 147.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_image_processor_stitch_sources`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_support.dart`

- Current lines: 187.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_image_processor_stitch_support`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_transform_helpers.dart`

- Current lines: 251.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_image_processor_stitch_transform_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_image_processor_storage_helpers.dart`

- Current lines: 208.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_image_processor_storage_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_import_source_help.dart`

- Current lines: 138.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_import_source_help`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart`

- Current lines: 352.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_import_source_sheet`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_import_source_tile.dart`

- Current lines: 77.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_import_source_tile`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_imported_text_sheet.dart`

- Current lines: 158.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_imported_text_sheet`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_interrupted_capture_banner.dart`

- Current lines: 171.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_interrupted_capture_banner`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart`

- Current lines: 241.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_camera_contract`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_camera_preference_mapper.dart`

- Current lines: 39.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_camera_preference_mapper`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart`

- Current lines: 264.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_camera_service`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_camera_service_contract_helpers.dart`

- Current lines: 332.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_camera_service_contract_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_camera_session_config.dart`

- Current lines: 355.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_camera_session_config`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_camera_session_ghost_guide.dart`

- Current lines: 133.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_camera_session_ghost_guide`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_camera_settings.dart`

- Current lines: 156.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_camera_settings`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_camera_settings_descriptors.dart`

- Current lines: 107.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_camera_settings_descriptors`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_camera_settings_policy.dart`

- Current lines: 114.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_camera_settings_policy`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_camera_settings_session.dart`

- Current lines: 263.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_camera_settings_session`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart`

- Current lines: 168.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_camera_shell`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_bar.dart`

- Current lines: 197.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_camera_shell_bottom_bar`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_controls.dart`

- Current lines: 121.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_camera_shell_bottom_controls`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_camera_shell_ghost_guidance.dart`

- Current lines: 92.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_camera_shell_ghost_guidance`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart`

- Current lines: 95.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_camera_shell_guidance`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_camera_shell_top_controls.dart`

- Current lines: 218.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_camera_shell_top_controls`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_camera_ui_config.dart`

- Current lines: 54.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_camera_ui_config`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_capture_diagnostics_sanitizer.dart`

- Current lines: 88.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_capture_diagnostics_sanitizer`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_capture_recovery_store.dart`

- Current lines: 268.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_capture_recovery_store`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart`

- Current lines: 96.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_capture_staging`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_capture_staging_cleanup.dart`

- Current lines: 77.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_capture_staging_cleanup`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_capture_staging_diagnostics.dart`

- Current lines: 167.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_capture_staging_diagnostics`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_capture_staging_manifest_helpers.dart`

- Current lines: 54.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_capture_staging_manifest_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_capture_staging_manifest_writer.dart`

- Current lines: 102.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_capture_staging_manifest_writer`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_capture_staging_recovery_actions.dart`

- Current lines: 129.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_capture_staging_recovery_actions`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_capture_staging_recovery_index.dart`

- Current lines: 89.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_capture_staging_recovery_index`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_capture_staging_recovery_record.dart`

- Current lines: 226.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_capture_staging_recovery_record`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_capture_staging_safe_brain_keys.dart`

- Current lines: 77.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_capture_staging_safe_brain_keys`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_capture_staging_safe_diagnostics.dart`

- Current lines: 60.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_capture_staging_safe_diagnostics`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_capture_staging_safe_keys.dart`

- Current lines: 294.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_capture_staging_safe_keys`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_capture_staging_stage_helpers.dart`

- Current lines: 82.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_capture_staging_stage_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_saved_photo_warning.dart`

- Current lines: 303.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_saved_photo_warning`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_native_saved_photo_warning_details.dart`

- Current lines: 108.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_native_saved_photo_warning_details`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_benchmark_metrics.dart`

- Current lines: 223.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_benchmark_metrics`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_diagnostics.dart`

- Current lines: 176.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_diagnostics`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_diagnostics_coverage.dart`

- Current lines: 249.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_diagnostics_coverage`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_diagnostics_from_result.dart`

- Current lines: 157.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_diagnostics_from_result`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_diagnostics_helpers.dart`

- Current lines: 252.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_diagnostics_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_diagnostics_labels.dart`

- Current lines: 144.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_diagnostics_labels`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_field_candidates.dart`

- Current lines: 251.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_field_candidates`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_layout.dart`

- Current lines: 133.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_layout`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_read_stats.dart`

- Current lines: 51.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_read_stats`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_result.dart`

- Current lines: 154.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_result`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_row_reconstruction.dart`

- Current lines: 352.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_row_reconstruction`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_service.dart`

- Current lines: 433.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_service`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_service_helpers.dart`

- Current lines: 70.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_service_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_service_layout.dart`

- Current lines: 45.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_service_layout`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_service_models.dart`

- Current lines: 56.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_service_models`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_service_stitch_evidence.dart`

- Current lines: 60.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_service_stitch_evidence`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_service_text_combiner.dart`

- Current lines: 114.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_service_text_combiner`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_source_handoff.dart`

- Current lines: 186.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_source_handoff`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_source_handoff_long_receipt.dart`

- Current lines: 200.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_source_handoff_long_receipt`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_source_handoff_review.dart`

- Current lines: 477.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_source_handoff_review`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_warning_classification.dart`

- Current lines: 99.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_warning_classification`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_warning_labels.dart`

- Current lines: 123.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_warning_labels`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_ocr_warnings.dart`

- Current lines: 108.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_ocr_warnings`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_coverage_decision.dart`

- Current lines: 30.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_coverage_decision`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_coverage_decision_from_signals.dart`

- Current lines: 143.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_coverage_decision_from_signals`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_coverage_decision_labels.dart`

- Current lines: 103.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_coverage_decision_labels`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_coverage_evidence_helpers.dart`

- Current lines: 166.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_coverage_evidence_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_path_identity.dart`

- Current lines: 92.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_path_identity`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_quality_models.dart`

- Current lines: 343.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_quality_models`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_alignment_actions.dart`

- Current lines: 170.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_alignment_actions`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_alignment_guide.dart`

- Current lines: 161.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_alignment_guide`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_async_work.dart`

- Current lines: 214.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_async_work`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_build.dart`

- Current lines: 180.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_build`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart`

- Current lines: 455.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_capture_actions`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_capture_feedback.dart`

- Current lines: 72.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_capture_feedback`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart`

- Current lines: 221.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_common_controls`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_completion_actions.dart`

- Current lines: 71.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_completion_actions`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart`

- Current lines: 284.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_context_controls`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart`

- Current lines: 292.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_controls`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_crop_and_proof_controls.dart`

- Current lines: 332.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_crop_and_proof_controls`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_crop_controls.dart`

- Current lines: 184.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_crop_controls`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_details.dart`

- Current lines: 325.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_data_saver_details`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart`

- Current lines: 462.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_data_saver_panel`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_exit_actions.dart`

- Current lines: 323.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_exit_actions`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_exit_stitch_actions.dart`

- Current lines: 155.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_exit_stitch_actions`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart`

- Current lines: 270.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_image_edit_actions`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_mode_controls.dart`

- Current lines: 198.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_mode_controls`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_order_actions.dart`

- Current lines: 173.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_order_actions`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_order_controls.dart`

- Current lines: 194.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_order_controls`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_order_thumbnail.dart`

- Current lines: 124.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_order_thumbnail`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_photo_surface.dart`

- Current lines: 91.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_photo_surface`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_status.dart`

- Current lines: 192.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_preview_action_status`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_tray.dart`

- Current lines: 142.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_preview_action_tray`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart`

- Current lines: 35.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_preview_controls`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart`

- Current lines: 304.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_preview_primary_row`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_quality_recovery.dart`

- Current lines: 166.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_quality_recovery`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_retake_order.dart`

- Current lines: 426.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_retake_order`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart`

- Current lines: 221.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_save_actions`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_save_models.dart`

- Current lines: 194.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_save_models`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart`

- Current lines: 273.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_screen`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart`

- Current lines: 87.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_section_labels`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_settings.dart`

- Current lines: 84.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_settings`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_actions.dart`

- Current lines: 122.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_stitch_actions`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_ghost_preview.dart`

- Current lines: 153.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_stitch_ghost_preview`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_order_evidence.dart`

- Current lines: 111.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_stitch_order_evidence`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_pair_navigator.dart`

- Current lines: 57.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_stitch_pair_navigator`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_pair_preview.dart`

- Current lines: 372.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_stitch_pair_preview`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_photo.dart`

- Current lines: 248.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_stitch_photo`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_preview_async.dart`

- Current lines: 287.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_stitch_preview_async`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_preview_widgets.dart`

- Current lines: 42.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_stitch_preview_widgets`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_surface.dart`

- Current lines: 97.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_stitch_surface`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_surface_controls.dart`

- Current lines: 108.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_surface_controls`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_surfaces.dart`

- Current lines: 110.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_surfaces`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_thumbnail_strip.dart`

- Current lines: 101.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_thumbnail_strip`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart`

- Current lines: 211.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_top_bar`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar_buttons.dart`

- Current lines: 35.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_top_bar_buttons`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_photo_review_ui_config.dart`

- Current lines: 132.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_photo_review_ui_config`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_picker_status.dart`

- Current lines: 31.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_picker_status`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_pipeline_trace.dart`

- Current lines: 43.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_pipeline_trace`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_proof_storage.dart`

- Current lines: 325.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_proof_storage`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_proof_storage_cleanup.dart`

- Current lines: 48.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_proof_storage_cleanup`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_proof_storage_copy.dart`

- Current lines: 41.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_proof_storage_copy`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_proof_storage_exception.dart`

- Current lines: 10.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_proof_storage_exception`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_proof_storage_file_names.dart`

- Current lines: 51.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_proof_storage_file_names`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_proof_storage_helpers.dart`

- Current lines: 164.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_proof_storage_helpers`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_scanner_service.dart`

- Current lines: 153.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_scanner_service`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_stitch_text_evidence.dart`

- Current lines: 324.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_stitch_text_evidence`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.

### `lib/shared/widgets/receipt_capture/receipt_storage_guard.dart`

- Current lines: 137.
- Production scope: single-receipt acquisition, review, long-receipt assembly, OCR source, saved proof, lifecycle, privacy, diagnostics, or supporting contract.
- Name-derived responsibility: `receipt_storage_guard`.
- Line-cap status: within the 500-line production-source limit.
- Verification requirement: source presence alone does not prove runtime correctness.


## Appendix C: QA And Regression Test Inventory

### `test/expense_receipt_assistance_setup_flow_test.dart`

- Current lines: 42.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_assistance_setup_flow_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_assisted_review_flow_test.dart`

- Current lines: 35.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_assisted_review_flow_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_assisted_review_handoff_native_test.dart`

- Current lines: 284.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_assisted_review_handoff_native_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_assisted_review_handoff_test.dart`

- Current lines: 353.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_assisted_review_handoff_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_assisted_review_overlap_native_test.dart`

- Current lines: 251.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `expense_receipt_assisted_review_overlap_native_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_assisted_review_recovery_state_test.dart`

- Current lines: 327.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_assisted_review_recovery_state_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_assisted_review_save_guardrails_test.dart`

- Current lines: 378.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_assisted_review_save_guardrails_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_category_choice_accessibility_contract_test.dart`

- Current lines: 17.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_category_choice_accessibility_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_category_rules_test.dart`

- Current lines: 63.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_category_rules_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_classification_step_contract_test.dart`

- Current lines: 76.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_classification_step_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_classifier_test.dart`

- Current lines: 165.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_classifier_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_context_snapshot_test.dart`

- Current lines: 121.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_context_snapshot_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_custom_category_entry_contract_test.dart`

- Current lines: 21.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_custom_category_entry_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_detail_ocr_review_test.dart`

- Current lines: 359.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `expense_receipt_detail_ocr_review_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_dispose_telemetry_test.dart`

- Current lines: 29.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_dispose_telemetry_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_entry_header_layout_test.dart`

- Current lines: 33.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_entry_header_layout_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_entry_manual_order_test.dart`

- Current lines: 25.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_entry_manual_order_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_entry_single_page_route_test.dart`

- Current lines: 40.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_entry_single_page_route_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_entry_start_guide_test.dart`

- Current lines: 25.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_entry_start_guide_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_explicit_split_allocation_test.dart`

- Current lines: 35.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_explicit_split_allocation_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_generic_ocr_handoff_performance_test.dart`

- Current lines: 58.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `expense_receipt_generic_ocr_handoff_performance_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_item_memory_store_test.dart`

- Current lines: 317.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_item_memory_store_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_line_choice_controls_contract_test.dart`

- Current lines: 17.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_line_choice_controls_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_line_privacy_test.dart`

- Current lines: 155.
- Coverage family: privacy-safe diagnostics or redaction.
- Name-derived scenario: `expense_receipt_line_privacy_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_line_record_test.dart`

- Current lines: 554.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_line_record_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_line_review_layout_test.dart`

- Current lines: 20.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_line_review_layout_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_line_split_entry_contract_test.dart`

- Current lines: 91.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_line_split_entry_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_line_total_calculation_contract_test.dart`

- Current lines: 34.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_line_total_calculation_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_manual_exit_contract_test.dart`

- Current lines: 20.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_manual_exit_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_manual_optional_evidence_contract_test.dart`

- Current lines: 97.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_manual_optional_evidence_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_manual_screen_rebuild_contract_test.dart`

- Current lines: 98.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_manual_screen_rebuild_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_manual_step_indicator_contract_test.dart`

- Current lines: 18.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_manual_step_indicator_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_ocr_handler_integration_test.dart`

- Current lines: 20.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `expense_receipt_ocr_handler_integration_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_ocr_line_recovery_test.dart`

- Current lines: 141.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `expense_receipt_ocr_line_recovery_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_ocr_progress_deadline_test.dart`

- Current lines: 88.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `expense_receipt_ocr_progress_deadline_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_odometer_lifecycle_contract_test.dart`

- Current lines: 30.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_odometer_lifecycle_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_parse_result_copy_test.dart`

- Current lines: 199.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_parse_result_copy_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_proof_availability_test.dart`

- Current lines: 58.
- Coverage family: saved proof, Data Saver, or storage lifecycle.
- Name-derived scenario: `expense_receipt_proof_availability_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_recap_mixed_allocation_visibility_test.dart`

- Current lines: 18.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_recap_mixed_allocation_visibility_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_review_mode_totals_test.dart`

- Current lines: 66.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_review_mode_totals_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_storage_and_duplicate_contract_test.dart`

- Current lines: 42.
- Coverage family: saved proof, Data Saver, or storage lifecycle.
- Name-derived scenario: `expense_receipt_storage_and_duplicate_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/expense_receipt_user_review_merge_test.dart`

- Current lines: 149.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `expense_receipt_user_review_merge_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_acquired_photo_staging_contract_test.dart`

- Current lines: 18.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_acquired_photo_staging_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_active_camera_docs_focus_policy_test.dart`

- Current lines: 92.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_active_camera_docs_focus_policy_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_assistance_footprint_policy_test.dart`

- Current lines: 308.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_assistance_footprint_policy_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_assistance_policy_diagnostics_test.dart`

- Current lines: 177.
- Coverage family: privacy-safe diagnostics or redaction.
- Name-derived scenario: `receipt_assistance_policy_diagnostics_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_assistance_policy_footprint_test.dart`

- Current lines: 253.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_assistance_policy_footprint_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_assistance_policy_install_strategy_test.dart`

- Current lines: 246.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_assistance_policy_install_strategy_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_assistance_policy_test.dart`

- Current lines: 274.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_assistance_policy_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_assisted_accuracy_harness_test.dart`

- Current lines: 188.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_assisted_accuracy_harness_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_attachment_duplicate_detector_test.dart`

- Current lines: 127.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_attachment_duplicate_detector_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_attachment_panel_actions_test.dart`

- Current lines: 281.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_attachment_panel_actions_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_attachment_panel_recovery_contract_test.dart`

- Current lines: 207.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_attachment_panel_recovery_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_attachment_record_metadata_test.dart`

- Current lines: 281.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_attachment_record_metadata_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_automatic_fill_notice_test.dart`

- Current lines: 19.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_automatic_fill_notice_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_bug_regression_ledger_archive_test.dart`

- Current lines: 58.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_bug_regression_ledger_archive_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_active_phase_docs_test.dart`

- Current lines: 61.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_active_phase_docs_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_attachment_helper_parity_test.dart`

- Current lines: 86.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_attachment_helper_parity_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_backup_staging_contract_test.dart`

- Current lines: 44.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_backup_staging_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_capture_busy_handoff_test.dart`

- Current lines: 31.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_capture_busy_handoff_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_capture_layout_test.dart`

- Current lines: 346.
- Coverage family: receipt review UI, entry, layout, or accessibility.
- Name-derived scenario: `receipt_camera_capture_layout_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_capture_loss_contract_test.dart`

- Current lines: 25.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_capture_loss_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_changed_gate_contract_test.dart`

- Current lines: 354.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_changed_gate_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_changed_gate_native_contract_test.dart`

- Current lines: 162.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_changed_gate_native_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_changed_gate_script_contract_test.dart`

- Current lines: 213.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_changed_gate_script_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_changed_route_coverage_gate_test.dart`

- Current lines: 130.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_changed_route_coverage_gate_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_completion_map_test.dart`

- Current lines: 77.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_completion_map_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_coverage_decision_test.dart`

- Current lines: 156.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_coverage_decision_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_dataset_qa_gate_contract_test.dart`

- Current lines: 82.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_dataset_qa_gate_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_fixture_matrix_test.dart`

- Current lines: 106.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_fixture_matrix_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_footprint_audit_test.dart`

- Current lines: 86.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_footprint_audit_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_help_flow_test.dart`

- Current lines: 307.
- Coverage family: receipt review UI, entry, layout, or accessibility.
- Name-derived scenario: `receipt_camera_help_flow_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_import_staging_contract_test.dart`

- Current lines: 34.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_import_staging_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_ios_full_screen_settings_test.dart`

- Current lines: 37.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_ios_full_screen_settings_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_ios_native_asset_preflight_contract_test.dart`

- Current lines: 38.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_ios_native_asset_preflight_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_long_receipt_guidance_test.dart`

- Current lines: 59.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_camera_long_receipt_guidance_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_low_confidence_stack_handoff_test.dart`

- Current lines: 76.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_low_confidence_stack_handoff_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_native_baseline_policy_test.dart`

- Current lines: 41.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_native_baseline_policy_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_native_bridge_layout_test.dart`

- Current lines: 254.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_native_bridge_layout_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_ocr_source_attachment_read_test.dart`

- Current lines: 215.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_camera_ocr_source_attachment_read_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_ocr_source_handoff_test.dart`

- Current lines: 341.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_camera_ocr_source_handoff_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_oversized_stitch_handoff_test.dart`

- Current lines: 81.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_camera_oversized_stitch_handoff_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_permission_contract_test.dart`

- Current lines: 20.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_permission_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_phase3_viewer_contract_test.dart`

- Current lines: 214.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_phase3_viewer_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_phase4_review_contract_test.dart`

- Current lines: 177.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_phase4_review_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_phase5_long_receipt_contract_test.dart`

- Current lines: 239.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_camera_phase5_long_receipt_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_phase6_stitching_handoff_contract_test.dart`

- Current lines: 405.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_camera_phase6_stitching_handoff_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_phase7_ocr_source_handoff_contract_test.dart`

- Current lines: 124.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_camera_phase7_ocr_source_handoff_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_phase8_storage_proof_timing_contract_test.dart`

- Current lines: 117.
- Coverage family: saved proof, Data Saver, or storage lifecycle.
- Name-derived scenario: `receipt_camera_phase8_storage_proof_timing_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_pipeline_handoff_status_test.dart`

- Current lines: 29.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_pipeline_handoff_status_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_preference_mapper_test.dart`

- Current lines: 59.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_preference_mapper_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_qa_gate_contract_test.dart`

- Current lines: 418.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_qa_gate_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_qa_gate_execution_runtime_test.dart`

- Current lines: 285.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_qa_gate_execution_runtime_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_qa_gate_execution_test.dart`

- Current lines: 403.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_qa_gate_execution_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_qa_gate_plan_coverage_test.dart`

- Current lines: 121.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_qa_gate_plan_coverage_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_qa_gate_scope_and_failure_contract_test.dart`

- Current lines: 135.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_qa_gate_scope_and_failure_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_qa_gate_stitch_contract_test.dart`

- Current lines: 135.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_camera_qa_gate_stitch_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_quality_guidance_test.dart`

- Current lines: 475.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_quality_guidance_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_real_device_snapshot_contract_test.dart`

- Current lines: 66.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_real_device_snapshot_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_release_control_priority_test.dart`

- Current lines: 155.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_release_control_priority_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_release_one_blueprint_test.dart`

- Current lines: 41.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_release_one_blueprint_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_reset_opt_in_contract_test.dart`

- Current lines: 24.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_reset_opt_in_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_auto_capture_contract_test.dart`

- Current lines: 250.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_auto_capture_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_best_shot_ocr_test.dart`

- Current lines: 481.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_camera_result_best_shot_ocr_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_completion_coverage_test.dart`

- Current lines: 334.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_completion_coverage_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_continuation_handoff_test.dart`

- Current lines: 361.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_continuation_handoff_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_coverage_totals_test.dart`

- Current lines: 368.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_coverage_totals_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_focus_contract_test.dart`

- Current lines: 214.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_focus_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_frozen_brain_install_test.dart`

- Current lines: 381.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_frozen_brain_install_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_frozen_handoff_counts_test.dart`

- Current lines: 171.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_frozen_handoff_counts_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_frozen_metadata_brain_test.dart`

- Current lines: 222.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_frozen_metadata_brain_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_frozen_metadata_counts_test.dart`

- Current lines: 230.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_frozen_metadata_counts_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_frozen_metadata_routes_test.dart`

- Current lines: 289.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_frozen_metadata_routes_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_frozen_metadata_tail_test.dart`

- Current lines: 128.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_frozen_metadata_tail_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_insert_invalid_context_test.dart`

- Current lines: 162.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_insert_invalid_context_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_manual_reorder_order_test.dart`

- Current lines: 153.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_manual_reorder_order_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_native_close_settings_test.dart`

- Current lines: 452.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_native_close_settings_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_native_quality_test.dart`

- Current lines: 455.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_native_quality_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_native_ui_health_test.dart`

- Current lines: 430.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_native_ui_health_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_native_ui_ready_test.dart`

- Current lines: 265.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_native_ui_ready_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_quality_test.dart`

- Current lines: 368.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_quality_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_recovery_handoff_test.dart`

- Current lines: 242.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_recovery_handoff_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_recovery_metadata_test.dart`

- Current lines: 224.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_recovery_metadata_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_removal_order_test.dart`

- Current lines: 159.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_removal_order_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_retired_control_contract_test.dart`

- Current lines: 264.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_retired_control_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_review_resume_test.dart`

- Current lines: 208.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_review_resume_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_saved_photo_warning_test.dart`

- Current lines: 192.
- Coverage family: saved proof, Data Saver, or storage lifecycle.
- Name-derived scenario: `receipt_camera_result_saved_photo_warning_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_section_order_follow_through_test.dart`

- Current lines: 121.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_camera_result_section_order_follow_through_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_section_order_invalid_context_test.dart`

- Current lines: 454.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_camera_result_section_order_invalid_context_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_section_order_test.dart`

- Current lines: 385.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_camera_result_section_order_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_stitch_handoff_followthrough_test.dart`

- Current lines: 493.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_camera_result_stitch_handoff_followthrough_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_stitch_scanner_test.dart`

- Current lines: 389.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_camera_result_stitch_scanner_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_result_test.dart`

- Current lines: 322.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_result_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_review_actions_contract_test.dart`

- Current lines: 26.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_review_actions_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_saved_photo_warning_diagnostics_test.dart`

- Current lines: 152.
- Coverage family: privacy-safe diagnostics or redaction.
- Name-derived scenario: `receipt_camera_saved_photo_warning_diagnostics_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_settings_handoff_test.dart`

- Current lines: 104.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_settings_handoff_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_single_photo_handoff_contract_test.dart`

- Current lines: 42.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_single_photo_handoff_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_stitch_candidate_metadata_test.dart`

- Current lines: 143.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_camera_stitch_candidate_metadata_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_storage_threshold_policy_test.dart`

- Current lines: 77.
- Coverage family: saved proof, Data Saver, or storage lifecycle.
- Name-derived scenario: `receipt_camera_storage_threshold_policy_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_user_language_contract_test.dart`

- Current lines: 48.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_user_language_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_world_class_readiness_test.dart`

- Current lines: 31.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_world_class_readiness_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_camera_zoom_handoff_contract_test.dart`

- Current lines: 41.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_camera_zoom_handoff_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_capture_diagnostics_policy_test.dart`

- Current lines: 148.
- Coverage family: privacy-safe diagnostics or redaction.
- Name-derived scenario: `receipt_capture_diagnostics_policy_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_capture_flow_assist_opt_in_contract_test.dart`

- Current lines: 284.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_capture_flow_assist_opt_in_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_capture_flow_handoff_contract_test.dart`

- Current lines: 418.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_capture_flow_handoff_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_capture_flow_handoff_order_test.dart`

- Current lines: 225.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_capture_flow_handoff_order_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_capture_flow_native_handoff_health_test.dart`

- Current lines: 99.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_capture_flow_native_handoff_health_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_capture_flow_ocr_source_count_test.dart`

- Current lines: 224.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_capture_flow_ocr_source_count_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_capture_flow_recovery_contract_test.dart`

- Current lines: 363.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_capture_flow_recovery_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_capture_flow_shareability_test.dart`

- Current lines: 476.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_capture_flow_shareability_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_capture_flow_staging_failure_test.dart`

- Current lines: 38.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_capture_flow_staging_failure_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_capture_progress_accessibility_contract_test.dart`

- Current lines: 15.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_capture_progress_accessibility_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_capture_progress_ui_config_test.dart`

- Current lines: 39.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_capture_progress_ui_config_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_capture_settings_actions_contract_test.dart`

- Current lines: 19.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_capture_settings_actions_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_capture_settings_data_saver_test.dart`

- Current lines: 349.
- Coverage family: saved proof, Data Saver, or storage lifecycle.
- Name-derived scenario: `receipt_capture_settings_data_saver_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_capture_settings_store_test.dart`

- Current lines: 434.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_capture_settings_store_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_capture_shared_usage_test.dart`

- Current lines: 26.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_capture_shared_usage_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_capture_status_ui_config_test.dart`

- Current lines: 26.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_capture_status_ui_config_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_capture_storage_estimate_test.dart`

- Current lines: 137.
- Coverage family: saved proof, Data Saver, or storage lifecycle.
- Name-derived scenario: `receipt_capture_storage_estimate_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_capture_ui_config_handoff_test.dart`

- Current lines: 30.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_capture_ui_config_handoff_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_continuation_ghost_handoff_contract_test.dart`

- Current lines: 234.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_continuation_ghost_handoff_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_device_capability_shared_adapter_test.dart`

- Current lines: 99.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_device_capability_shared_adapter_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_device_capability_tiers_test.dart`

- Current lines: 283.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_device_capability_tiers_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_doc_size_gate_contract_test.dart`

- Current lines: 17.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_doc_size_gate_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_drafts_panel_test.dart`

- Current lines: 86.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_drafts_panel_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_end_to_end_regression_matrix_test.dart`

- Current lines: 149.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_end_to_end_regression_matrix_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_external_dataset_gate_test.dart`

- Current lines: 93.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_external_dataset_gate_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_external_dataset_local_audit_test.dart`

- Current lines: 74.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_external_dataset_local_audit_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_external_fixture_schema_gate_test.dart`

- Current lines: 61.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_external_fixture_schema_gate_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_fast_guard_gate_contract_test.dart`

- Current lines: 251.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_fast_guard_gate_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_image_cleanup_settings_test.dart`

- Current lines: 221.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_image_cleanup_settings_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_image_data_saver_test.dart`

- Current lines: 492.
- Coverage family: saved proof, Data Saver, or storage lifecycle.
- Name-derived scenario: `receipt_image_data_saver_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_image_ocr_source_guard_test.dart`

- Current lines: 148.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_image_ocr_source_guard_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_image_rotation_test.dart`

- Current lines: 135.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_image_rotation_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_image_source_prep_test.dart`

- Current lines: 144.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_image_source_prep_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_import_source_sheet_test.dart`

- Current lines: 305.
- Coverage family: receipt review UI, entry, layout, or accessibility.
- Name-derived scenario: `receipt_import_source_sheet_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_line_models_test.dart`

- Current lines: 418.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_line_models_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_long_capture_guide_layout_test.dart`

- Current lines: 62.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_long_capture_guide_layout_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_long_receipt_stitch_health_script_test.dart`

- Current lines: 19.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_long_receipt_stitch_health_script_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_android_analysis_executor_test.dart`

- Current lines: 22.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_android_analysis_executor_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_android_bridge_analysis_exposure_test.dart`

- Current lines: 359.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_android_bridge_analysis_exposure_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_android_bridge_auto_capture_test.dart`

- Current lines: 313.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_android_bridge_auto_capture_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_android_bridge_capture_flow_test.dart`

- Current lines: 72.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_android_bridge_capture_flow_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_android_bridge_capture_quality_contract_test.dart`

- Current lines: 274.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_android_bridge_capture_quality_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_android_bridge_close_controls_test.dart`

- Current lines: 368.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_android_bridge_close_controls_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_android_bridge_diagnostics_storage_test.dart`

- Current lines: 345.
- Coverage family: privacy-safe diagnostics or redaction.
- Name-derived scenario: `receipt_native_android_bridge_diagnostics_storage_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_android_bridge_false_positive_guard_test.dart`

- Current lines: 81.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_android_bridge_false_positive_guard_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_android_bridge_settings_quality_test.dart`

- Current lines: 310.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_android_bridge_settings_quality_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_android_bridge_test.dart`

- Current lines: 38.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_android_bridge_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_android_bridge_ui_contract_test.dart`

- Current lines: 440.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_android_bridge_ui_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_android_camera_startup_resilience_test.dart`

- Current lines: 76.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_native_android_camera_startup_resilience_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_android_capture_watchdog_test.dart`

- Current lines: 33.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_android_capture_watchdog_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_android_diagnostics_payload_test.dart`

- Current lines: 54.
- Coverage family: privacy-safe diagnostics or redaction.
- Name-derived scenario: `receipt_native_android_diagnostics_payload_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_android_guidance_policy_gate_test.dart`

- Current lines: 86.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_android_guidance_policy_gate_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_android_import_hygiene_test.dart`

- Current lines: 146.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_android_import_hygiene_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_android_source_size_test.dart`

- Current lines: 48.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_android_source_size_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_camera_contract_test.dart`

- Current lines: 394.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_native_camera_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_camera_phase8_storage_timing_test.dart`

- Current lines: 40.
- Coverage family: saved proof, Data Saver, or storage lifecycle.
- Name-derived scenario: `receipt_native_camera_phase8_storage_timing_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_camera_previous_section_channel_test.dart`

- Current lines: 236.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_native_camera_previous_section_channel_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_camera_privacy_diagnostics_test.dart`

- Current lines: 293.
- Coverage family: privacy-safe diagnostics or redaction.
- Name-derived scenario: `receipt_native_camera_privacy_diagnostics_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_camera_result_path_validation_test.dart`

- Current lines: 347.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_native_camera_result_path_validation_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_camera_result_rejection_test.dart`

- Current lines: 421.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_native_camera_result_rejection_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_camera_service_basics_test.dart`

- Current lines: 199.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_native_camera_service_basics_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_camera_session_contract_test.dart`

- Current lines: 407.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_native_camera_session_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_camera_session_limits_test.dart`

- Current lines: 499.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_native_camera_session_limits_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_camera_shell_controls_test.dart`

- Current lines: 473.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_native_camera_shell_controls_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_camera_shell_test.dart`

- Current lines: 288.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_native_camera_shell_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_camera_storage_contract_test.dart`

- Current lines: 228.
- Coverage family: saved proof, Data Saver, or storage lifecycle.
- Name-derived scenario: `receipt_native_camera_storage_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_capture_old_cleanup_test.dart`

- Current lines: 176.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_capture_old_cleanup_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_capture_per_photo_zoom_contract_test.dart`

- Current lines: 22.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_capture_per_photo_zoom_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_capture_recovery_index_test.dart`

- Current lines: 410.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_capture_recovery_index_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_capture_recovery_record_test.dart`

- Current lines: 253.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_capture_recovery_record_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_capture_recovery_store_test.dart`

- Current lines: 88.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_capture_recovery_store_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_capture_staging_cleanup_test.dart`

- Current lines: 253.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_capture_staging_cleanup_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_capture_staging_test.dart`

- Current lines: 332.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_capture_staging_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_continuation_guide_layout_test.dart`

- Current lines: 22.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_continuation_guide_layout_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ghost_orientation_contract_test.dart`

- Current lines: 39.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_ghost_orientation_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ghost_warning_contract_test.dart`

- Current lines: 225.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_ghost_warning_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ios_bridge_analysis_exposure_test.dart`

- Current lines: 343.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_ios_bridge_analysis_exposure_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ios_bridge_app_delegate_test.dart`

- Current lines: 67.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_ios_bridge_app_delegate_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ios_bridge_close_capture_test.dart`

- Current lines: 170.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_ios_bridge_close_capture_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ios_bridge_exposure_shutter_contract_test.dart`

- Current lines: 276.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_ios_bridge_exposure_shutter_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ios_bridge_false_positive_guard_test.dart`

- Current lines: 69.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_ios_bridge_false_positive_guard_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ios_bridge_long_receipt_quality_test.dart`

- Current lines: 330.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_native_ios_bridge_long_receipt_quality_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ios_bridge_settings_close_test.dart`

- Current lines: 445.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_ios_bridge_settings_close_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ios_bridge_storage_contract_test.dart`

- Current lines: 248.
- Coverage family: saved proof, Data Saver, or storage lifecycle.
- Name-derived scenario: `receipt_native_ios_bridge_storage_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ios_bridge_test.dart`

- Current lines: 22.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_ios_bridge_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ios_bridge_ui_session_test.dart`

- Current lines: 495.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_ios_bridge_ui_session_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ios_camera_session_capability_test.dart`

- Current lines: 39.
- Coverage family: receipt camera or capture contract.
- Name-derived scenario: `receipt_native_ios_camera_session_capability_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ios_capture_watchdog_test.dart`

- Current lines: 33.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_ios_capture_watchdog_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ios_diagnostics_payload_test.dart`

- Current lines: 51.
- Coverage family: privacy-safe diagnostics or redaction.
- Name-derived scenario: `receipt_native_ios_diagnostics_payload_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ios_guidance_warning_gate_test.dart`

- Current lines: 87.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_ios_guidance_warning_gate_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ios_orientation_contract_test.dart`

- Current lines: 40.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_ios_orientation_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ios_project_membership_test.dart`

- Current lines: 67.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_ios_project_membership_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ios_session_recovery_test.dart`

- Current lines: 42.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_ios_session_recovery_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_ios_settings_guidance_contract_test.dart`

- Current lines: 67.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_ios_settings_guidance_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_pinch_zoom_contract_test.dart`

- Current lines: 66.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_pinch_zoom_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_quality_guidance_contract_test.dart`

- Current lines: 25.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_quality_guidance_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_native_shell_recovery_contract_test.dart`

- Current lines: 283.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_native_shell_recovery_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_benchmark_metrics_test.dart`

- Current lines: 40.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_benchmark_metrics_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_benchmark_runner_test.dart`

- Current lines: 169.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_benchmark_runner_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_combined_text_stress_test.dart`

- Current lines: 315.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_combined_text_stress_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_field_candidates_test.dart`

- Current lines: 531.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_field_candidates_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_handoff_qa_test.dart`

- Current lines: 111.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_handoff_qa_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_handoff_test.dart`

- Current lines: 89.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_handoff_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_layout_contract_test.dart`

- Current lines: 133.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_layout_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_overlap_test.dart`

- Current lines: 303.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_ocr_overlap_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_photo_selection_test.dart`

- Current lines: 57.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_photo_selection_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_bottom_coverage_risk_test.dart`

- Current lines: 309.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_service_bottom_coverage_risk_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_downstream_classification_test.dart`

- Current lines: 160.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_service_downstream_classification_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_footer_amount_test.dart`

- Current lines: 152.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_service_footer_amount_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_hybrid_travel_mart_test.dart`

- Current lines: 125.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_service_hybrid_travel_mart_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_item_family_test.dart`

- Current lines: 275.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_service_item_family_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_line_signals_test.dart`

- Current lines: 258.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_service_line_signals_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_long_receipt_diagnostics_test.dart`

- Current lines: 200.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_ocr_service_long_receipt_diagnostics_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_merchant_structure_test.dart`

- Current lines: 156.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_service_merchant_structure_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_read_warnings_test.dart`

- Current lines: 362.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_service_read_warnings_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_review_contract_test.dart`

- Current lines: 165.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_service_review_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_section_order_failed_pair_test.dart`

- Current lines: 60.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_ocr_service_section_order_failed_pair_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_source_handoff_test.dart`

- Current lines: 241.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_service_source_handoff_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_source_quality_test.dart`

- Current lines: 260.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_service_source_quality_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_test.dart`

- Current lines: 478.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_service_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_totals_coverage_test.dart`

- Current lines: 272.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_service_totals_coverage_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_totals_evidence_test.dart`

- Current lines: 132.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_service_totals_evidence_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_vendor_recovery_test.dart`

- Current lines: 233.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_service_vendor_recovery_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_vendor_review_test.dart`

- Current lines: 185.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_service_vendor_review_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_service_warning_buckets_test.dart`

- Current lines: 128.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_service_warning_buckets_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_source_completion_test.dart`

- Current lines: 158.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_source_completion_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_source_relationship_test.dart`

- Current lines: 382.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_source_relationship_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_source_review_risks_test.dart`

- Current lines: 326.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_source_review_risks_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_source_section_order_handoff_test.dart`

- Current lines: 194.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_ocr_source_section_order_handoff_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_source_text_fidelity_test.dart`

- Current lines: 24.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_source_text_fidelity_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_timeout_recovery_test.dart`

- Current lines: 29.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_timeout_recovery_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_ocr_warning_review_test.dart`

- Current lines: 132.
- Coverage family: OCR source, recognition, or OCR handoff.
- Name-derived scenario: `receipt_ocr_warning_review_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_path_identity_test.dart`

- Current lines: 89.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_photo_path_identity_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_async_lifecycle_test.dart`

- Current lines: 205.
- Coverage family: receipt review UI, entry, layout, or accessibility.
- Name-derived scenario: `receipt_photo_review_async_lifecycle_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_back_navigation_contract_test.dart`

- Current lines: 50.
- Coverage family: receipt review UI, entry, layout, or accessibility.
- Name-derived scenario: `receipt_photo_review_back_navigation_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_continuation_copy_test.dart`

- Current lines: 88.
- Coverage family: receipt review UI, entry, layout, or accessibility.
- Name-derived scenario: `receipt_photo_review_continuation_copy_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_continuation_crop_contract_test.dart`

- Current lines: 150.
- Coverage family: receipt review UI, entry, layout, or accessibility.
- Name-derived scenario: `receipt_photo_review_continuation_crop_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_controls_layout_test.dart`

- Current lines: 459.
- Coverage family: receipt review UI, entry, layout, or accessibility.
- Name-derived scenario: `receipt_photo_review_controls_layout_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_crop_controls_layout_test.dart`

- Current lines: 77.
- Coverage family: receipt review UI, entry, layout, or accessibility.
- Name-derived scenario: `receipt_photo_review_crop_controls_layout_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_edit_evidence_test.dart`

- Current lines: 36.
- Coverage family: receipt review UI, entry, layout, or accessibility.
- Name-derived scenario: `receipt_photo_review_edit_evidence_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_exit_completion_test.dart`

- Current lines: 440.
- Coverage family: receipt review UI, entry, layout, or accessibility.
- Name-derived scenario: `receipt_photo_review_exit_completion_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_exit_contract_test.dart`

- Current lines: 32.
- Coverage family: receipt review UI, entry, layout, or accessibility.
- Name-derived scenario: `receipt_photo_review_exit_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_layout_invariant_test.dart`

- Current lines: 18.
- Coverage family: receipt review UI, entry, layout, or accessibility.
- Name-derived scenario: `receipt_photo_review_layout_invariant_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_long_receipt_runtime_guard_test.dart`

- Current lines: 250.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_photo_review_long_receipt_runtime_guard_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_order_diagnostics_privacy_test.dart`

- Current lines: 159.
- Coverage family: privacy-safe diagnostics or redaction.
- Name-derived scenario: `receipt_photo_review_order_diagnostics_privacy_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_original_retention_test.dart`

- Current lines: 25.
- Coverage family: receipt review UI, entry, layout, or accessibility.
- Name-derived scenario: `receipt_photo_review_original_retention_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_quality_handoff_test.dart`

- Current lines: 330.
- Coverage family: receipt review UI, entry, layout, or accessibility.
- Name-derived scenario: `receipt_photo_review_quality_handoff_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_removal_order_test.dart`

- Current lines: 67.
- Coverage family: receipt review UI, entry, layout, or accessibility.
- Name-derived scenario: `receipt_photo_review_removal_order_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_retake_order_test.dart`

- Current lines: 450.
- Coverage family: receipt review UI, entry, layout, or accessibility.
- Name-derived scenario: `receipt_photo_review_retake_order_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_save_lifecycle_test.dart`

- Current lines: 377.
- Coverage family: receipt review UI, entry, layout, or accessibility.
- Name-derived scenario: `receipt_photo_review_save_lifecycle_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_section_order_ops_test.dart`

- Current lines: 229.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_photo_review_section_order_ops_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_review_stitch_safety_contract_test.dart`

- Current lines: 120.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_photo_review_stitch_safety_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_photo_section_labels_test.dart`

- Current lines: 136.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_photo_section_labels_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_pipeline_failure_to_regression_test.dart`

- Current lines: 101.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_pipeline_failure_to_regression_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_privacy_event_capture_handoff_test.dart`

- Current lines: 120.
- Coverage family: privacy-safe diagnostics or redaction.
- Name-derived scenario: `receipt_privacy_event_capture_handoff_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_privacy_event_store_policy_test.dart`

- Current lines: 336.
- Coverage family: privacy-safe diagnostics or redaction.
- Name-derived scenario: `receipt_privacy_event_store_policy_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_privacy_event_store_test.dart`

- Current lines: 370.
- Coverage family: privacy-safe diagnostics or redaction.
- Name-derived scenario: `receipt_privacy_event_store_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_privacy_event_test.dart`

- Current lines: 301.
- Coverage family: privacy-safe diagnostics or redaction.
- Name-derived scenario: `receipt_privacy_event_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_processing_contract_test.dart`

- Current lines: 468.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_processing_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_proof_storage_hardening_test.dart`

- Current lines: 341.
- Coverage family: saved proof, Data Saver, or storage lifecycle.
- Name-derived scenario: `receipt_proof_storage_hardening_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_proof_storage_lifecycle_test.dart`

- Current lines: 350.
- Coverage family: saved proof, Data Saver, or storage lifecycle.
- Name-derived scenario: `receipt_proof_storage_lifecycle_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_proof_target_size_policy_test.dart`

- Current lines: 31.
- Coverage family: saved proof, Data Saver, or storage lifecycle.
- Name-derived scenario: `receipt_proof_target_size_policy_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_qa_runner_contract_test.dart`

- Current lines: 441.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_qa_runner_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_qa_runner_pack_focus_test.dart`

- Current lines: 217.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_qa_runner_pack_focus_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_quality_gate_contract_test.dart`

- Current lines: 40.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_quality_gate_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_quiet_batch_final_summary_script_test.dart`

- Current lines: 31.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_quiet_batch_final_summary_script_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_quiet_batch_policy_gate_contract_test.dart`

- Current lines: 41.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_quiet_batch_policy_gate_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_real_device_matrix_gate_test.dart`

- Current lines: 55.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_real_device_matrix_gate_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_real_device_result_gate_test.dart`

- Current lines: 263.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_real_device_result_gate_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_real_device_result_start_script_test.dart`

- Current lines: 136.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_real_device_result_start_script_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_real_device_test_script_test.dart`

- Current lines: 37.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_real_device_test_script_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_regression_report_test.dart`

- Current lines: 131.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_regression_report_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_saved_image_step_contract_test.dart`

- Current lines: 36.
- Coverage family: saved proof, Data Saver, or storage lifecycle.
- Name-derived scenario: `receipt_saved_image_step_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_saved_proof_choice_progression_test.dart`

- Current lines: 43.
- Coverage family: saved proof, Data Saver, or storage lifecycle.
- Name-derived scenario: `receipt_saved_proof_choice_progression_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_shared_quality_gate_contract_test.dart`

- Current lines: 35.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_shared_quality_gate_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitch_contract_health_script_test.dart`

- Current lines: 500.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitch_contract_health_script_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitch_fallback_metadata_test.dart`

- Current lines: 223.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitch_fallback_metadata_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitch_final_timeout_recovery_test.dart`

- Current lines: 39.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitch_final_timeout_recovery_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitch_real_device_probe_test.dart`

- Current lines: 108.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitch_real_device_probe_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitch_real_probe_integrity_contract_test.dart`

- Current lines: 62.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitch_real_probe_integrity_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitch_text_evidence_test.dart`

- Current lines: 134.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitch_text_evidence_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitch_working_resolution_contract_test.dart`

- Current lines: 27.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitch_working_resolution_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_artifact_copy_contract_test.dart`

- Current lines: 28.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_artifact_copy_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_bad_input_test.dart`

- Current lines: 136.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_bad_input_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_duplicate_safety_test.dart`

- Current lines: 373.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_duplicate_safety_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_exception_fallback_contract_test.dart`

- Current lines: 27.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_exception_fallback_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_extreme_aspect_ratio_test.dart`

- Current lines: 116.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_extreme_aspect_ratio_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_high_overlap_test.dart`

- Current lines: 40.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_high_overlap_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_horizontal_drift_test.dart`

- Current lines: 184.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_horizontal_drift_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_horizontal_placement_test.dart`

- Current lines: 81.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_horizontal_placement_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_long_stack_test.dart`

- Current lines: 500.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_long_stack_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_manual_overlap_test.dart`

- Current lines: 466.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_manual_overlap_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_mixed_encoding_test.dart`

- Current lines: 69.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_mixed_encoding_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_ocr_source_contract_test.dart`

- Current lines: 403.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_ocr_source_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_orientation_mismatch_test.dart`

- Current lines: 71.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_orientation_mismatch_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_passenger_seat_test.dart`

- Current lines: 95.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_passenger_seat_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_perspective_test.dart`

- Current lines: 62.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_perspective_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_phone_window_edge_crop_test.dart`

- Current lines: 124.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_phone_window_edge_crop_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_phone_window_safety_test.dart`

- Current lines: 467.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_phone_window_safety_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_real_fixture_probe_test.dart`

- Current lines: 245.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_real_fixture_probe_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_result_contract_test.dart`

- Current lines: 478.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_result_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_scale_rotation_test.dart`

- Current lines: 309.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_scale_rotation_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_size_cap_test.dart`

- Current lines: 78.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_size_cap_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_stained_overlap_test.dart`

- Current lines: 92.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_stained_overlap_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_store_receipt_shape_test.dart`

- Current lines: 240.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_store_receipt_shape_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_test.dart`

- Current lines: 278.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_torn_edge_test.dart`

- Current lines: 105.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_torn_edge_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_transformed_phone_window_test.dart`

- Current lines: 129.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_transformed_phone_window_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_ugly_long_receipt_test.dart`

- Current lines: 488.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_ugly_long_receipt_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_uploaded_screenshot_test.dart`

- Current lines: 225.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_uploaded_screenshot_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_variants_test.dart`

- Current lines: 494.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_variants_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_weak_overlap_safety_test.dart`

- Current lines: 286.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_weak_overlap_safety_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_stitching_worn_receipt_test.dart`

- Current lines: 429.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_stitching_worn_receipt_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_store_panel_test.dart`

- Current lines: 96.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_store_panel_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_store_panel_zip_format_test.dart`

- Current lines: 33.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_store_panel_zip_format_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_synthetic_stitch_dataset_audit_test.dart`

- Current lines: 279.
- Coverage family: long-receipt assembly, overlap, or section ordering.
- Name-derived scenario: `receipt_synthetic_stitch_dataset_audit_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_text_quality_contract_test.dart`

- Current lines: 76.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_text_quality_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.

### `test/receipt_warning_profile_parity_contract_test.dart`

- Current lines: 90.
- Coverage family: general receipt-flow regression.
- Name-derived scenario: `receipt_warning_profile_parity_contract_test`.
- Evidence boundary: this test proves only the behavior its assertions execute.
- Runtime boundary: a green test does not replace physical-device evidence.


## Appendix D: QA Tool And Harness Inventory

### `tool/receipt_bug_regression_ledger_archive.dart`

- Current lines: 121.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_bug_regression_ledger_archive`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_bug_regression_ledger_gate.dart`

- Current lines: 122.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_bug_regression_ledger_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_camera_changed_gate.sh`

- Current lines: 385.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_camera_changed_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_camera_changed_route_coverage_gate.dart`

- Current lines: 102.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_camera_changed_route_coverage_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_camera_failure_to_regression.sh`

- Current lines: 49.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_camera_failure_to_regression`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_camera_footprint_audit.dart`

- Current lines: 330.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_camera_footprint_audit`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_camera_io_guard.dart`

- Current lines: 165.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_camera_io_guard`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_camera_ios_native_asset_preflight.sh`

- Current lines: 51.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_camera_ios_native_asset_preflight`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_camera_pipeline_gate.sh`

- Current lines: 4.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_camera_pipeline_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_camera_qa_gate.sh`

- Current lines: 1008.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_camera_qa_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_camera_qa_summary.sh`

- Current lines: 125.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_camera_qa_summary`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_camera_real_device_snapshot.sh`

- Current lines: 64.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_camera_real_device_snapshot`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_camera_scope_gate.sh`

- Current lines: 105.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_camera_scope_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_camera_stitch_gate.sh`

- Current lines: 4.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_camera_stitch_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_cleanup_log_gate.sh`

- Current lines: 49.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_cleanup_log_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_doc_size_gate.sh`

- Current lines: 39.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_doc_size_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_external_dataset_gate.dart`

- Current lines: 201.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_external_dataset_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_external_dataset_local_audit.dart`

- Current lines: 109.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_external_dataset_local_audit`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_external_fixture_schema_gate.dart`

- Current lines: 284.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_external_fixture_schema_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_fast_guard_gate.sh`

- Current lines: 153.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_fast_guard_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_flow_route_audit.dart`

- Current lines: 347.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_flow_route_audit`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_flow_route_audit_report.dart`

- Current lines: 220.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_flow_route_audit_report`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_formatter_projection_gate.sh`

- Current lines: 34.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_formatter_projection_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_long_receipt_stitch_health.sh`

- Current lines: 44.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_long_receipt_stitch_health`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_ocr_audit.sh`

- Current lines: 103.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_ocr_audit`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_ocr_benchmark_runner.dart`

- Current lines: 323.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_ocr_benchmark_runner`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_ocr_focus_gate.sh`

- Current lines: 59.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_ocr_focus_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_ocr_pipeline_run.sh`

- Current lines: 210.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_ocr_pipeline_run`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_pipeline_device_trace.sh`

- Current lines: 15.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_pipeline_device_trace`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_pipeline_failure_to_regression.dart`

- Current lines: 105.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_pipeline_failure_to_regression`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_qa_fixture_manifest.dart`

- Current lines: 210.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_qa_fixture_manifest`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_qa_fixtures.dart`

- Current lines: 12.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_qa_fixtures`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_qa_fixtures_adjustment_retail.dart`

- Current lines: 188.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_qa_fixtures_adjustment_retail`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_qa_fixtures_contractor_supply.dart`

- Current lines: 108.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_qa_fixtures_contractor_supply`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_qa_fixtures_damaged_ocr.dart`

- Current lines: 290.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_qa_fixtures_damaged_ocr`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_qa_fixtures_device_tiers.dart`

- Current lines: 80.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_qa_fixtures_device_tiers`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_qa_fixtures_long_receipt.dart`

- Current lines: 120.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_qa_fixtures_long_receipt`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_qa_fixtures_privacy_admin.dart`

- Current lines: 80.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_qa_fixtures_privacy_admin`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_qa_report_models.dart`

- Current lines: 267.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_qa_report_models`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_qa_runner.dart`

- Current lines: 319.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_qa_runner`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_qa_scoring.dart`

- Current lines: 230.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_qa_scoring`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_qa_scoring_checks.dart`

- Current lines: 461.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_qa_scoring_checks`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_qa_scoring_matchers.dart`

- Current lines: 192.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_qa_scoring_matchers`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_qa_scoring_privacy.dart`

- Current lines: 154.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_qa_scoring_privacy`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_qa_scoring_review.dart`

- Current lines: 137.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_qa_scoring_review`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_quality_gate.sh`

- Current lines: 46.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_quality_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_quiet_batch.sh`

- Current lines: 105.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_quiet_batch`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_quiet_batch_final_summary.sh`

- Current lines: 45.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_quiet_batch_final_summary`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_quiet_batch_policy_gate.dart`

- Current lines: 435.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_quiet_batch_policy_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_quiet_batch_status.sh`

- Current lines: 77.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_quiet_batch_status`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_real_device_matrix_gate.dart`

- Current lines: 84.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_real_device_matrix_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_real_device_result_gate.dart`

- Current lines: 191.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_real_device_result_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_real_device_result_start.sh`

- Current lines: 123.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_real_device_result_start`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_regression_report.sh`

- Current lines: 5.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_regression_report`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_shared_quality_gate.sh`

- Current lines: 82.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_shared_quality_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_start_camera_qa_gate.sh`

- Current lines: 23.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_start_camera_qa_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_start_ocr_pipeline.sh`

- Current lines: 28.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_start_ocr_pipeline`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_start_quiet_quality_gate.sh`

- Current lines: 13.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_start_quiet_quality_gate`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_stitch_contract_health.sh`

- Current lines: 464.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_stitch_contract_health`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_stitch_duplicate_probe.dart`

- Current lines: 132.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_stitch_duplicate_probe`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_stitch_probe.dart`

- Current lines: 45.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_stitch_probe`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_stitch_real_probe.sh`

- Current lines: 42.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_stitch_real_probe`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_stitch_real_window_matrix.sh`

- Current lines: 67.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_stitch_real_window_matrix`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_stitch_real_window_probe.sh`

- Current lines: 49.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_stitch_real_window_probe`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.

### `tool/receipt_synthetic_stitch_dataset_audit.dart`

- Current lines: 465.
- Automation role: capture/review QA, fixture generation, audit, contract validation, reporting, or gate orchestration.
- Name-derived responsibility: `receipt_synthetic_stitch_dataset_audit`.
- Execution policy: use focused modes during development and milestone/full modes only at appropriate checkpoints.
- Output policy: capture logs quietly and inspect only completion status or a targeted failure tail.


## Appendix E: In-Scope Documentation Inventory

### `docs/expense_receipt_storage_and_duplicate_contract.md`

- Current lines: 140.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `expense_receipt_storage_and_duplicate_contract`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/firebase_sync_receipt_expense_schema_spec.md`

- Current lines: 344.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `firebase_sync_receipt_expense_schema_spec`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/long_receipt_stitching_cross_platform_handoff_2026_07_15.md`

- Current lines: 113.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `long_receipt_stitching_cross_platform_handoff_2026_07_15`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/openai_receipt_assist_deployment.md`

- Current lines: 59.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `openai_receipt_assist_deployment`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_bug_regression_ledger.md`

- Current lines: 266.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_bug_regression_ledger`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_bug_regression_ledger_archive_0001.md`

- Current lines: 333.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_bug_regression_ledger_archive_0001`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log.md`

- Current lines: 506.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_014_to_pass_021.md`

- Current lines: 389.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_014_to_pass_021`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_022_to_pass_028.md`

- Current lines: 420.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_022_to_pass_028`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_029_to_pass_034.md`

- Current lines: 415.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_029_to_pass_034`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_035_to_pass_046.md`

- Current lines: 441.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_035_to_pass_046`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_047_to_pass_062.md`

- Current lines: 429.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_047_to_pass_062`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_063_to_pass_074.md`

- Current lines: 429.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_063_to_pass_074`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_073_to_pass_066.md`

- Current lines: 254.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_073_to_pass_066`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_093_to_pass_013.md`

- Current lines: 444.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_093_to_pass_013`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_109_to_pass_094.md`

- Current lines: 439.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_109_to_pass_094`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_122_to_pass_110.md`

- Current lines: 435.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_122_to_pass_110`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_126_to_pass_123.md`

- Current lines: 130.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_126_to_pass_123`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_127_to_pass_127.md`

- Current lines: 32.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_127_to_pass_127`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_130_to_pass_128.md`

- Current lines: 86.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_130_to_pass_128`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_131_to_pass_131.md`

- Current lines: 42.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_131_to_pass_131`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_132_to_pass_132.md`

- Current lines: 32.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_132_to_pass_132`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_133_to_pass_133.md`

- Current lines: 35.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_133_to_pass_133`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_134_to_pass_134.md`

- Current lines: 30.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_134_to_pass_134`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_135_to_pass_135.md`

- Current lines: 51.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_135_to_pass_135`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_136_to_pass_136.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_136_to_pass_136`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_137_to_pass_137.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_137_to_pass_137`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_138_to_pass_138.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_138_to_pass_138`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_139_to_pass_139.md`

- Current lines: 75.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_139_to_pass_139`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_140_to_pass_140.md`

- Current lines: 32.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_140_to_pass_140`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_141_to_pass_141.md`

- Current lines: 36.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_141_to_pass_141`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_142_to_pass_142.md`

- Current lines: 35.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_142_to_pass_142`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_143_to_pass_143.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_143_to_pass_143`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_144_to_pass_144.md`

- Current lines: 31.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_144_to_pass_144`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_145_to_pass_145.md`

- Current lines: 34.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_145_to_pass_145`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_146_to_pass_146.md`

- Current lines: 15.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_146_to_pass_146`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_147_to_pass_147.md`

- Current lines: 30.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_147_to_pass_147`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_148_to_pass_148.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_148_to_pass_148`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_149_to_pass_149.md`

- Current lines: 29.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_149_to_pass_149`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_150_to_pass_150.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_150_to_pass_150`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_151_to_pass_151.md`

- Current lines: 38.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_151_to_pass_151`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_152_to_pass_152.md`

- Current lines: 34.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_152_to_pass_152`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_153_to_pass_153.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_153_to_pass_153`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_154_to_pass_154.md`

- Current lines: 30.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_154_to_pass_154`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_155_to_pass_155.md`

- Current lines: 32.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_155_to_pass_155`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_156_to_pass_156.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_156_to_pass_156`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_157_to_pass_157.md`

- Current lines: 13.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_157_to_pass_157`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_158_to_pass_158.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_158_to_pass_158`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_159_to_pass_159.md`

- Current lines: 32.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_159_to_pass_159`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_160_to_pass_160.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_160_to_pass_160`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_161_to_pass_161.md`

- Current lines: 29.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_161_to_pass_161`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_162_to_pass_162.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_162_to_pass_162`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_163_to_pass_163.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_163_to_pass_163`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_164_to_pass_164.md`

- Current lines: 33.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_164_to_pass_164`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_165_to_pass_165.md`

- Current lines: 35.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_165_to_pass_165`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_166_to_pass_166.md`

- Current lines: 29.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_166_to_pass_166`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_167_to_pass_167.md`

- Current lines: 31.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_167_to_pass_167`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_168_to_pass_168.md`

- Current lines: 32.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_168_to_pass_168`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_169_to_pass_169.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_169_to_pass_169`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_170_to_pass_170.md`

- Current lines: 33.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_170_to_pass_170`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_171_to_pass_171.md`

- Current lines: 32.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_171_to_pass_171`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_172_to_pass_172.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_172_to_pass_172`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_173_to_pass_173.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_173_to_pass_173`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_174_to_pass_174.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_174_to_pass_174`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_175_to_pass_175.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_175_to_pass_175`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_176_to_pass_176.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_176_to_pass_176`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_177_to_pass_177.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_177_to_pass_177`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_178_to_pass_178.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_178_to_pass_178`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_179_to_pass_179.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_179_to_pass_179`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_180_to_pass_180.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_180_to_pass_180`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_181_to_pass_181.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_181_to_pass_181`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_182_to_pass_182.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_182_to_pass_182`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_183_to_pass_183.md`

- Current lines: 29.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_183_to_pass_183`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_184_to_pass_184.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_184_to_pass_184`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_185_to_pass_185.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_185_to_pass_185`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_186_to_pass_186.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_186_to_pass_186`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_187_to_pass_187.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_187_to_pass_187`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_188_to_pass_188.md`

- Current lines: 35.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_188_to_pass_188`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_189_to_pass_189.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_189_to_pass_189`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_190_to_pass_190.md`

- Current lines: 40.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_190_to_pass_190`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_191_to_pass_191.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_191_to_pass_191`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_192_to_pass_192.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_192_to_pass_192`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_193_to_pass_193.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_193_to_pass_193`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_194_to_pass_194.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_194_to_pass_194`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_195_to_pass_195.md`

- Current lines: 29.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_195_to_pass_195`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_196_to_pass_196.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_196_to_pass_196`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_197_to_pass_197.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_197_to_pass_197`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_198_to_pass_198.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_198_to_pass_198`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_199_to_pass_199.md`

- Current lines: 31.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_199_to_pass_199`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_200_to_pass_200.md`

- Current lines: 32.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_200_to_pass_200`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_201_to_pass_201.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_201_to_pass_201`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_202_to_pass_202.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_202_to_pass_202`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_203_to_pass_203.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_203_to_pass_203`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_204_to_pass_204.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_204_to_pass_204`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_205_to_pass_205.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_205_to_pass_205`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_206_to_pass_206.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_206_to_pass_206`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_207_to_pass_207.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_207_to_pass_207`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_208_to_pass_208.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_208_to_pass_208`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_209_to_pass_209.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_209_to_pass_209`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_210_to_pass_210.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_210_to_pass_210`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_211_to_pass_211.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_211_to_pass_211`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_212_to_pass_212.md`

- Current lines: 30.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_212_to_pass_212`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_213_to_pass_213.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_213_to_pass_213`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_214_to_pass_214.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_214_to_pass_214`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_215_to_pass_215.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_215_to_pass_215`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_216_to_pass_216.md`

- Current lines: 32.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_216_to_pass_216`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_217_to_pass_217.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_217_to_pass_217`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_218_to_pass_218.md`

- Current lines: 29.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_218_to_pass_218`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_219_to_pass_219.md`

- Current lines: 17.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_219_to_pass_219`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_220_to_pass_220.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_220_to_pass_220`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_221_to_pass_221.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_221_to_pass_221`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_222_to_pass_222.md`

- Current lines: 29.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_222_to_pass_222`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_223_to_pass_223.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_223_to_pass_223`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_224_to_pass_224.md`

- Current lines: 17.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_224_to_pass_224`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_225_to_pass_225.md`

- Current lines: 34.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_225_to_pass_225`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_226_to_pass_226.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_226_to_pass_226`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_227_to_pass_227.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_227_to_pass_227`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_228_to_pass_228.md`

- Current lines: 33.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_228_to_pass_228`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_229_to_pass_229.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_229_to_pass_229`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_230_to_pass_230.md`

- Current lines: 14.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_230_to_pass_230`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_231_to_pass_231.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_231_to_pass_231`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_232_to_pass_232.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_232_to_pass_232`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_233_to_pass_233.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_233_to_pass_233`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_234_to_pass_234.md`

- Current lines: 29.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_234_to_pass_234`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_235_to_pass_235.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_235_to_pass_235`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_236_to_pass_236.md`

- Current lines: 30.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_236_to_pass_236`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_237_to_pass_237.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_237_to_pass_237`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_238_to_pass_238.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_238_to_pass_238`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_239_to_pass_239.md`

- Current lines: 38.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_239_to_pass_239`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_240_to_pass_240.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_240_to_pass_240`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_241_to_pass_241.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_241_to_pass_241`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_242_to_pass_242.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_242_to_pass_242`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_243_to_pass_243.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_243_to_pass_243`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_244_to_pass_244.md`

- Current lines: 33.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_244_to_pass_244`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_245_to_pass_245.md`

- Current lines: 36.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_245_to_pass_245`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_246_to_pass_246.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_246_to_pass_246`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_247_to_pass_247.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_247_to_pass_247`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_248_to_pass_248.md`

- Current lines: 31.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_248_to_pass_248`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_249_to_pass_249.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_249_to_pass_249`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_250_to_pass_250.md`

- Current lines: 38.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_250_to_pass_250`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_251_to_pass_251.md`

- Current lines: 37.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_251_to_pass_251`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_252_to_pass_252.md`

- Current lines: 29.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_252_to_pass_252`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_253_to_pass_253.md`

- Current lines: 15.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_253_to_pass_253`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_254_to_pass_254.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_254_to_pass_254`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_255_to_pass_255.md`

- Current lines: 15.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_255_to_pass_255`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_256_to_pass_256.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_256_to_pass_256`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_257_to_pass_257.md`

- Current lines: 15.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_257_to_pass_257`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_258_to_pass_258.md`

- Current lines: 15.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_258_to_pass_258`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_259_to_pass_259.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_259_to_pass_259`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_260_to_pass_260.md`

- Current lines: 14.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_260_to_pass_260`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_261_to_pass_261.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_261_to_pass_261`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_262_to_pass_262.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_262_to_pass_262`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_263_to_pass_263.md`

- Current lines: 14.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_263_to_pass_263`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_264_to_pass_264.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_264_to_pass_264`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_265_to_pass_265.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_265_to_pass_265`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_266_to_pass_266.md`

- Current lines: 14.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_266_to_pass_266`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_267_to_pass_267.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_267_to_pass_267`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_268_to_pass_268.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_268_to_pass_268`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_269_to_pass_269.md`

- Current lines: 14.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_269_to_pass_269`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_270_to_pass_270.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_270_to_pass_270`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_271_to_pass_271.md`

- Current lines: 14.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_271_to_pass_271`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_272_to_pass_272.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_272_to_pass_272`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_273_to_pass_273.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_273_to_pass_273`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_274_to_pass_274.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_274_to_pass_274`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_275_to_pass_275.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_275_to_pass_275`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_276_to_pass_276.md`

- Current lines: 30.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_276_to_pass_276`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_277_to_pass_277.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_277_to_pass_277`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_278_to_pass_278.md`

- Current lines: 37.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_278_to_pass_278`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_279_to_pass_279.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_279_to_pass_279`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_280_to_pass_280.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_280_to_pass_280`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_281_to_pass_281.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_281_to_pass_281`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_282_to_pass_282.md`

- Current lines: 30.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_282_to_pass_282`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_283_to_pass_283.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_283_to_pass_283`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_284_to_pass_284.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_284_to_pass_284`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_285_to_pass_285.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_285_to_pass_285`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_286_to_pass_286.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_286_to_pass_286`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_287_to_pass_287.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_287_to_pass_287`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_288_to_pass_288.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_288_to_pass_288`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_289_to_pass_289.md`

- Current lines: 31.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_289_to_pass_289`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_290_to_pass_290.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_290_to_pass_290`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_291_to_pass_291.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_291_to_pass_291`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_292_to_pass_292.md`

- Current lines: 16.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_292_to_pass_292`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_293_to_pass_293.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_293_to_pass_293`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_294_to_pass_294.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_294_to_pass_294`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_295_to_pass_295.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_295_to_pass_295`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_296_to_pass_296.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_296_to_pass_296`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_297_to_pass_297.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_297_to_pass_297`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_298_to_pass_298.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_298_to_pass_298`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_299_to_pass_299.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_299_to_pass_299`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_300_to_pass_300.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_300_to_pass_300`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_301_to_pass_301.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_301_to_pass_301`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_302_to_pass_302.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_302_to_pass_302`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_303_to_pass_303.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_303_to_pass_303`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_304_to_pass_304.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_304_to_pass_304`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_305_to_pass_305.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_305_to_pass_305`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_306_to_pass_306.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_306_to_pass_306`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_307_to_pass_307.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_307_to_pass_307`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_308_to_pass_308.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_308_to_pass_308`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_309_to_pass_309.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_309_to_pass_309`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_310_to_pass_310.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_310_to_pass_310`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_311_to_pass_311.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_311_to_pass_311`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_312_to_pass_312.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_312_to_pass_312`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_313_to_pass_313.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_313_to_pass_313`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_314_to_pass_314.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_314_to_pass_314`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_315_to_pass_315.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_315_to_pass_315`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_316_to_pass_316.md`

- Current lines: 17.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_316_to_pass_316`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_317_to_pass_317.md`

- Current lines: 16.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_317_to_pass_317`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_318_to_pass_318.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_318_to_pass_318`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_319_to_pass_319.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_319_to_pass_319`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_320_to_pass_320.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_320_to_pass_320`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_321_to_pass_321.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_321_to_pass_321`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_322_to_pass_322.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_322_to_pass_322`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_323_to_pass_323.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_323_to_pass_323`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_324_to_pass_324.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_324_to_pass_324`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_325_to_pass_325.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_325_to_pass_325`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_326_to_pass_326.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_326_to_pass_326`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_327_to_pass_327.md`

- Current lines: 17.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_327_to_pass_327`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_328_to_pass_328.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_328_to_pass_328`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_329_to_pass_329.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_329_to_pass_329`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_330_to_pass_330.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_330_to_pass_330`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_331_to_pass_331.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_331_to_pass_331`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_332_to_pass_332.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_332_to_pass_332`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_333_to_pass_333.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_333_to_pass_333`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_334_to_pass_334.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_334_to_pass_334`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_335_to_pass_335.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_335_to_pass_335`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_336_to_pass_336.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_336_to_pass_336`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_337_to_pass_337.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_337_to_pass_337`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_338_to_pass_338.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_338_to_pass_338`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_339_to_pass_339.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_339_to_pass_339`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_340_to_pass_340.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_340_to_pass_340`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_341_to_pass_341.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_341_to_pass_341`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_342_to_pass_342.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_342_to_pass_342`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_343_to_pass_343.md`

- Current lines: 34.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_343_to_pass_343`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_344_to_pass_344.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_344_to_pass_344`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_345_to_pass_345.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_345_to_pass_345`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_346_to_pass_346.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_346_to_pass_346`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_347_to_pass_347.md`

- Current lines: 16.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_347_to_pass_347`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_348_to_pass_348.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_348_to_pass_348`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_349_to_pass_349.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_349_to_pass_349`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_350_to_pass_350.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_350_to_pass_350`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_351_to_pass_351.md`

- Current lines: 13.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_351_to_pass_351`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_352_to_pass_352.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_352_to_pass_352`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_353_to_pass_353.md`

- Current lines: 16.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_353_to_pass_353`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_354_to_pass_354.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_354_to_pass_354`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_355_to_pass_355.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_355_to_pass_355`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_356_to_pass_356.md`

- Current lines: 17.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_356_to_pass_356`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_357_to_pass_357.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_357_to_pass_357`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_358_to_pass_358.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_358_to_pass_358`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_359_to_pass_359.md`

- Current lines: 16.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_359_to_pass_359`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_360_to_pass_360.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_360_to_pass_360`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_361_to_pass_361.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_361_to_pass_361`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_362_to_pass_362.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_362_to_pass_362`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_363_to_pass_363.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_363_to_pass_363`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_364_to_pass_364.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_364_to_pass_364`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_365_to_pass_365.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_365_to_pass_365`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_366_to_pass_366.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_366_to_pass_366`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_367_to_pass_367.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_367_to_pass_367`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_368_to_pass_368.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_368_to_pass_368`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_369_to_pass_369.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_369_to_pass_369`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_370_to_pass_370.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_370_to_pass_370`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_371_to_pass_371.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_371_to_pass_371`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_372_to_pass_372.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_372_to_pass_372`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_373_to_pass_373.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_373_to_pass_373`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_374_to_pass_374.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_374_to_pass_374`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_375_to_pass_375.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_375_to_pass_375`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_376_to_pass_376.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_376_to_pass_376`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_377_to_pass_377.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_377_to_pass_377`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_378_to_pass_378.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_378_to_pass_378`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_379_to_pass_379.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_379_to_pass_379`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_380_to_pass_380.md`

- Current lines: 31.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_380_to_pass_380`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_381_to_pass_381.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_381_to_pass_381`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_382_to_pass_382.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_382_to_pass_382`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_383_to_pass_383.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_383_to_pass_383`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_384_to_pass_384.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_384_to_pass_384`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_385_to_pass_385.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_385_to_pass_385`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_386_to_pass_386.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_386_to_pass_386`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_387_to_pass_387.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_387_to_pass_387`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_388_to_pass_388.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_388_to_pass_388`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_389_to_pass_389.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_389_to_pass_389`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_390_to_pass_390.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_390_to_pass_390`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_391_to_pass_391.md`

- Current lines: 29.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_391_to_pass_391`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_392_to_pass_392.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_392_to_pass_392`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_393_to_pass_393.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_393_to_pass_393`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_394_to_pass_394.md`

- Current lines: 29.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_394_to_pass_394`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_395_to_pass_395.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_395_to_pass_395`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_396_to_pass_396.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_396_to_pass_396`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_397_to_pass_397.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_397_to_pass_397`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_398_to_pass_398.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_398_to_pass_398`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_399_to_pass_399.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_399_to_pass_399`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_400_to_pass_400.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_400_to_pass_400`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_401_to_pass_401.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_401_to_pass_401`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_402_to_pass_402.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_402_to_pass_402`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_403_to_pass_403.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_403_to_pass_403`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_404_to_pass_404.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_404_to_pass_404`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_405_to_pass_405.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_405_to_pass_405`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_406_to_pass_406.md`

- Current lines: 17.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_406_to_pass_406`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_407_to_pass_407.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_407_to_pass_407`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_408_to_pass_408.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_408_to_pass_408`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_409_to_pass_409.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_409_to_pass_409`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_410_to_pass_410.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_410_to_pass_410`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_411_to_pass_411.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_411_to_pass_411`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_412_to_pass_412.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_412_to_pass_412`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_413_to_pass_413.md`

- Current lines: 31.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_413_to_pass_413`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_414_to_pass_414.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_414_to_pass_414`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_415_to_pass_415.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_415_to_pass_415`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_416_to_pass_416.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_416_to_pass_416`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_417_to_pass_417.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_417_to_pass_417`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_418_to_pass_418.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_418_to_pass_418`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_419_to_pass_419.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_419_to_pass_419`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_420_to_pass_420.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_420_to_pass_420`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_421_to_pass_421.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_421_to_pass_421`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_422_to_pass_422.md`

- Current lines: 32.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_422_to_pass_422`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_423_to_pass_423.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_423_to_pass_423`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_424_to_pass_424.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_424_to_pass_424`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_425_to_pass_425.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_425_to_pass_425`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_426_to_pass_426.md`

- Current lines: 32.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_426_to_pass_426`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_427_to_pass_427.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_427_to_pass_427`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_428_to_pass_428.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_428_to_pass_428`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_429_to_pass_429.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_429_to_pass_429`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_430_to_pass_430.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_430_to_pass_430`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_431_to_pass_431.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_431_to_pass_431`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_432_to_pass_432.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_432_to_pass_432`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_433_to_pass_433.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_433_to_pass_433`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_434_to_pass_434.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_434_to_pass_434`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_435_to_pass_435.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_435_to_pass_435`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_436_to_pass_436.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_436_to_pass_436`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_437_to_pass_437.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_437_to_pass_437`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_438_to_pass_438.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_438_to_pass_438`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_439_to_pass_439.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_439_to_pass_439`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_440_to_pass_440.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_440_to_pass_440`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_441_to_pass_441.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_441_to_pass_441`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_442_to_pass_442.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_442_to_pass_442`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_443_to_pass_443.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_443_to_pass_443`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_444_to_pass_444.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_444_to_pass_444`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_445_to_pass_445.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_445_to_pass_445`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_446_to_pass_446.md`

- Current lines: 39.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_446_to_pass_446`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_447_to_pass_447.md`

- Current lines: 36.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_447_to_pass_447`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_448_to_pass_448.md`

- Current lines: 34.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_448_to_pass_448`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_449_to_pass_449.md`

- Current lines: 34.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_449_to_pass_449`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_450_to_pass_450.md`

- Current lines: 34.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_450_to_pass_450`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_451_to_pass_451.md`

- Current lines: 29.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_451_to_pass_451`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_452_to_pass_452.md`

- Current lines: 39.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_452_to_pass_452`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_453_to_pass_453.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_453_to_pass_453`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_454_to_pass_454.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_454_to_pass_454`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_455_to_pass_455.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_455_to_pass_455`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_456_to_pass_456.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_456_to_pass_456`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_457_to_pass_457.md`

- Current lines: 33.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_457_to_pass_457`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_458_to_pass_458.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_458_to_pass_458`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_459_to_pass_459.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_459_to_pass_459`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_460_to_pass_460.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_460_to_pass_460`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_461_to_pass_461.md`

- Current lines: 38.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_461_to_pass_461`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_462_to_pass_462.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_462_to_pass_462`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_463_to_pass_463.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_463_to_pass_463`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_464_to_pass_464.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_464_to_pass_464`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_466_to_pass_466.md`

- Current lines: 41.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_466_to_pass_466`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_467_to_pass_467.md`

- Current lines: 38.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_467_to_pass_467`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_468_to_pass_468.md`

- Current lines: 38.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_468_to_pass_468`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_469_to_pass_469.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_469_to_pass_469`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_470_to_pass_470.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_470_to_pass_470`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_471_to_pass_471.md`

- Current lines: 31.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_471_to_pass_471`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_472_to_pass_472.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_472_to_pass_472`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_473_to_pass_473.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_473_to_pass_473`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_474_to_pass_474.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_474_to_pass_474`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_475_to_pass_475.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_475_to_pass_475`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_476_to_pass_476.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_476_to_pass_476`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_477_to_pass_477.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_477_to_pass_477`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_478_to_pass_478.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_478_to_pass_478`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_479_to_pass_479.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_479_to_pass_479`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_480_to_pass_480.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_480_to_pass_480`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_481_to_pass_481.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_481_to_pass_481`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_482_to_pass_482.md`

- Current lines: 30.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_482_to_pass_482`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_483_to_pass_483.md`

- Current lines: 30.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_483_to_pass_483`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_484_to_pass_484.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_484_to_pass_484`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_485_to_pass_485.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_485_to_pass_485`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_486_to_pass_486.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_486_to_pass_486`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_487_to_pass_487.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_487_to_pass_487`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_488_to_pass_488.md`

- Current lines: 29.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_488_to_pass_488`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_489_to_pass_489.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_489_to_pass_489`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_490_to_pass_490.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_490_to_pass_490`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_491_to_pass_491.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_491_to_pass_491`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_492_to_pass_492.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_492_to_pass_492`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_493_to_pass_493.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_493_to_pass_493`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_494_to_pass_494.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_494_to_pass_494`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_495_to_pass_495.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_495_to_pass_495`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_496_to_pass_496.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_496_to_pass_496`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_497_to_pass_497.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_497_to_pass_497`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_498_to_pass_498.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_498_to_pass_498`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_499_to_pass_499.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_499_to_pass_499`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_500_to_pass_500.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_500_to_pass_500`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_501_to_pass_501.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_501_to_pass_501`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_502_to_pass_502.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_502_to_pass_502`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_503_to_pass_503.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_503_to_pass_503`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_504_to_pass_504.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_504_to_pass_504`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_505_to_pass_505.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_505_to_pass_505`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_506_to_pass_506.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_506_to_pass_506`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_507_to_pass_507.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_507_to_pass_507`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_508_to_pass_508.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_508_to_pass_508`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_509_to_pass_509.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_509_to_pass_509`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_510_to_pass_510.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_510_to_pass_510`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_511_to_pass_511.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_511_to_pass_511`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_512_to_pass_512.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_512_to_pass_512`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_513_to_pass_513.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_513_to_pass_513`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_514_to_pass_514.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_514_to_pass_514`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_515_to_pass_515.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_515_to_pass_515`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_516_to_pass_516.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_516_to_pass_516`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_517_to_pass_517.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_517_to_pass_517`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_518_to_pass_518.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_518_to_pass_518`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_519_to_pass_519.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_519_to_pass_519`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_520_to_pass_520.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_520_to_pass_520`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_521_to_pass_521.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_521_to_pass_521`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_522_to_pass_522.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_522_to_pass_522`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_523_to_pass_523.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_523_to_pass_523`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_524_to_pass_524.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_524_to_pass_524`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_525_to_pass_525.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_525_to_pass_525`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_526_to_pass_526.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_526_to_pass_526`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_527_to_pass_527.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_527_to_pass_527`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_528_to_pass_528.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_528_to_pass_528`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_529_to_pass_529.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_529_to_pass_529`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_530_to_pass_530.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_530_to_pass_530`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_531_to_pass_531.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_531_to_pass_531`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_532_to_pass_532.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_532_to_pass_532`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_533_to_pass_533.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_533_to_pass_533`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_534_to_pass_534.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_534_to_pass_534`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_535_to_pass_535.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_535_to_pass_535`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_536_to_pass_536.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_536_to_pass_536`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_537_to_pass_537.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_537_to_pass_537`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_538_to_pass_538.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_538_to_pass_538`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_539_to_pass_539.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_539_to_pass_539`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_540_to_pass_540.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_540_to_pass_540`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_541_to_pass_541.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_541_to_pass_541`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_542_to_pass_542.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_542_to_pass_542`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_543_to_pass_543.md`

- Current lines: 17.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_543_to_pass_543`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_544_to_pass_544.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_544_to_pass_544`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_545_to_pass_545.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_545_to_pass_545`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_546_to_pass_546.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_546_to_pass_546`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_547_to_pass_547.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_547_to_pass_547`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_548_to_pass_548.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_548_to_pass_548`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_549_to_pass_549.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_549_to_pass_549`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_550_to_pass_550.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_550_to_pass_550`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_551_to_pass_551.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_551_to_pass_551`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_552_to_pass_552.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_552_to_pass_552`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_553_to_pass_553.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_553_to_pass_553`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_554_to_pass_554.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_554_to_pass_554`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_555_to_pass_555.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_555_to_pass_555`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_556_to_pass_556.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_556_to_pass_556`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_557_to_pass_557.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_557_to_pass_557`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_558_to_pass_558.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_558_to_pass_558`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_559_to_pass_559.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_559_to_pass_559`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_560_to_pass_560.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_560_to_pass_560`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_561_to_pass_561.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_561_to_pass_561`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_562_to_pass_562.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_562_to_pass_562`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_564_to_pass_564.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_564_to_pass_564`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_565_to_pass_565.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_565_to_pass_565`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_566_to_pass_566.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_566_to_pass_566`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_567_to_pass_567.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_567_to_pass_567`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_568_to_pass_568.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_568_to_pass_568`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_569_to_pass_569.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_569_to_pass_569`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_570_to_pass_570.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_570_to_pass_570`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_571_to_pass_571.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_571_to_pass_571`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_572_to_pass_572.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_572_to_pass_572`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_573_to_pass_573.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_573_to_pass_573`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_574_to_pass_574.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_574_to_pass_574`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_575_to_pass_575.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_575_to_pass_575`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_576_to_pass_576.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_576_to_pass_576`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_577_to_pass_577.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_577_to_pass_577`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_578_to_pass_578.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_578_to_pass_578`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_579_to_pass_579.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_579_to_pass_579`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_580_to_pass_580.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_580_to_pass_580`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_581_to_pass_581.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_581_to_pass_581`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_582_to_pass_582.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_582_to_pass_582`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_583_to_pass_583.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_583_to_pass_583`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_584_to_pass_584.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_584_to_pass_584`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_585_to_pass_585.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_585_to_pass_585`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_586_to_pass_586.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_586_to_pass_586`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_587_to_pass_587.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_587_to_pass_587`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_588_to_pass_588.md`

- Current lines: 60.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_588_to_pass_588`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_589_to_pass_589.md`

- Current lines: 83.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_589_to_pass_589`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_590_to_pass_590.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_590_to_pass_590`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_591_to_pass_591.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_591_to_pass_591`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_592_to_pass_592.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_592_to_pass_592`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_593_to_pass_593.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_593_to_pass_593`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_594_to_pass_594.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_594_to_pass_594`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_595_to_pass_595.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_595_to_pass_595`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_596_to_pass_596.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_596_to_pass_596`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_597_to_pass_597.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_597_to_pass_597`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_598_to_pass_598.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_598_to_pass_598`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_599_to_pass_599.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_599_to_pass_599`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_600_to_pass_600.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_600_to_pass_600`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_601_to_pass_601.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_601_to_pass_601`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_602_to_pass_602.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_602_to_pass_602`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_603_to_pass_603.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_603_to_pass_603`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_604_to_pass_604.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_604_to_pass_604`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_605_to_pass_605.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_605_to_pass_605`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_606_to_pass_606.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_606_to_pass_606`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_607_to_pass_607.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_607_to_pass_607`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_608_to_pass_608.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_608_to_pass_608`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_609_to_pass_609.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_609_to_pass_609`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_610_to_pass_610.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_610_to_pass_610`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_611_to_pass_611.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_611_to_pass_611`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_612_to_pass_612.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_612_to_pass_612`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_613_to_pass_613.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_613_to_pass_613`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_614_to_pass_614.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_614_to_pass_614`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_619_to_pass_619.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_619_to_pass_619`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_620_to_pass_620.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_620_to_pass_620`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_621_to_pass_621.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_621_to_pass_621`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_622_to_pass_622.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_622_to_pass_622`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_623_to_pass_623.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_623_to_pass_623`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_624_to_pass_624.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_624_to_pass_624`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_625_to_pass_625.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_625_to_pass_625`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_626_to_pass_626.md`

- Current lines: 16.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_626_to_pass_626`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_627_to_pass_627.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_627_to_pass_627`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_634_to_pass_634.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_634_to_pass_634`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_635_to_pass_635.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_635_to_pass_635`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_636_to_pass_636.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_636_to_pass_636`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_637_to_pass_637.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_637_to_pass_637`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_638_to_pass_638.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_638_to_pass_638`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_639_to_pass_639.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_639_to_pass_639`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_640_to_pass_640.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_640_to_pass_640`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_641_to_pass_641.md`

- Current lines: 17.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_641_to_pass_641`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_642_to_pass_642.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_642_to_pass_642`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_643_to_pass_643.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_643_to_pass_643`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_644_to_pass_644.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_644_to_pass_644`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_645_to_pass_645.md`

- Current lines: 17.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_645_to_pass_645`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_646_to_pass_646.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_646_to_pass_646`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_647_to_pass_647.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_647_to_pass_647`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_648_to_pass_648.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_648_to_pass_648`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_649_to_pass_649.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_649_to_pass_649`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_650_to_pass_650.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_650_to_pass_650`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_651_to_pass_651.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_651_to_pass_651`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_652_to_pass_652.md`

- Current lines: 16.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_652_to_pass_652`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_653_to_pass_653.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_653_to_pass_653`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_686_to_pass_686.md`

- Current lines: 29.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_686_to_pass_686`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_687_to_pass_687.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_687_to_pass_687`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_688_to_pass_688.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_688_to_pass_688`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_689_to_pass_689.md`

- Current lines: 29.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_689_to_pass_689`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_690_to_pass_690.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_690_to_pass_690`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_691_to_pass_691.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_691_to_pass_691`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_692_to_pass_692.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_692_to_pass_692`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_693_to_pass_693.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_693_to_pass_693`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_694_to_pass_694.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_694_to_pass_694`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_695_to_pass_695.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_695_to_pass_695`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_696_to_pass_696.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_696_to_pass_696`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_697_to_pass_697.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_697_to_pass_697`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_698_to_pass_698.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_698_to_pass_698`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_699_to_pass_699.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_699_to_pass_699`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_700_to_pass_700.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_700_to_pass_700`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_701_to_pass_701.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_701_to_pass_701`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_702_to_pass_702.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_702_to_pass_702`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_703_to_pass_703.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_703_to_pass_703`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_704_to_pass_704.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_704_to_pass_704`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_705_to_pass_705.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_705_to_pass_705`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_706_to_pass_706.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_706_to_pass_706`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_707_to_pass_707.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_707_to_pass_707`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_708_to_pass_708.md`

- Current lines: 29.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_708_to_pass_708`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_709_to_pass_709.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_709_to_pass_709`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_710_to_pass_710.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_710_to_pass_710`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_711_to_pass_711.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_711_to_pass_711`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_712_to_pass_712.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_712_to_pass_712`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_713_to_pass_713.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_713_to_pass_713`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_714_to_pass_714.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_714_to_pass_714`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_715_to_pass_715.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_715_to_pass_715`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_716_to_pass_716.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_716_to_pass_716`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_717_to_pass_717.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_717_to_pass_717`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_718_to_pass_718.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_718_to_pass_718`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_719_to_pass_719.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_719_to_pass_719`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_720_to_pass_720.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_720_to_pass_720`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_721_to_pass_721.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_721_to_pass_721`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_722_to_pass_722.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_722_to_pass_722`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_723_to_pass_723.md`

- Current lines: 36.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_723_to_pass_723`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_724_to_pass_724.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_724_to_pass_724`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_725_to_pass_725.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_725_to_pass_725`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_726_to_pass_726.md`

- Current lines: 26.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_726_to_pass_726`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_727_to_pass_727.md`

- Current lines: 30.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_727_to_pass_727`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_728_to_pass_728.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_728_to_pass_728`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_729_to_pass_729.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_729_to_pass_729`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_730_to_pass_730.md`

- Current lines: 27.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_730_to_pass_730`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_731_to_pass_731.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_731_to_pass_731`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_732_to_pass_732.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_732_to_pass_732`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_733_to_pass_733.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_733_to_pass_733`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_734_to_pass_734.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_734_to_pass_734`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_735_to_pass_735.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_735_to_pass_735`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_736_to_pass_736.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_736_to_pass_736`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_737_to_pass_737.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_737_to_pass_737`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_738_to_pass_738.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_738_to_pass_738`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_739_to_pass_739.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_739_to_pass_739`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_740_to_pass_740.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_740_to_pass_740`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_741_to_pass_741.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_741_to_pass_741`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_742_to_pass_742.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_742_to_pass_742`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_743_to_pass_743.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_743_to_pass_743`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_744_to_pass_744.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_744_to_pass_744`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_745_to_pass_745.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_745_to_pass_745`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_746_to_pass_746.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_746_to_pass_746`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_747_to_pass_747.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_747_to_pass_747`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_748_to_pass_748.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_748_to_pass_748`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_749_to_pass_749.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_749_to_pass_749`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_750_to_pass_750.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_750_to_pass_750`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_751_to_pass_751.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_751_to_pass_751`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_752_to_pass_752.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_752_to_pass_752`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_753_to_pass_753.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_753_to_pass_753`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_754_to_pass_754.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_754_to_pass_754`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_755_to_pass_755.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_755_to_pass_755`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_756_to_pass_756.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_756_to_pass_756`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_757_to_pass_757.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_757_to_pass_757`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_758_to_pass_758.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_758_to_pass_758`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_759_to_pass_759.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_759_to_pass_759`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_760_to_pass_760.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_760_to_pass_760`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_761_to_pass_761.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_761_to_pass_761`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_762_to_pass_762.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_762_to_pass_762`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_763_to_pass_763.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_763_to_pass_763`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_764_to_pass_764.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_764_to_pass_764`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_765_to_pass_765.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_765_to_pass_765`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_766_to_pass_766.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_766_to_pass_766`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_767_to_pass_767.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_767_to_pass_767`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_768_to_pass_768.md`

- Current lines: 25.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_768_to_pass_768`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_769_to_pass_769.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_769_to_pass_769`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_770_to_pass_770.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_770_to_pass_770`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_771_to_pass_771.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_771_to_pass_771`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_772_to_pass_772.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_772_to_pass_772`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_773_to_pass_773.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_773_to_pass_773`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_774_to_pass_774.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_774_to_pass_774`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_775_to_pass_775.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_775_to_pass_775`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_776_to_pass_776.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_776_to_pass_776`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_777_to_pass_777.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_777_to_pass_777`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_778_to_pass_778.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_778_to_pass_778`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_779_to_pass_779.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_779_to_pass_779`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_780_to_pass_780.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_780_to_pass_780`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_781_to_pass_781.md`

- Current lines: 17.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_781_to_pass_781`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_782_to_pass_782.md`

- Current lines: 17.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_782_to_pass_782`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_783_to_pass_783.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_783_to_pass_783`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_784_to_pass_784.md`

- Current lines: 17.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_784_to_pass_784`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_785_to_pass_785.md`

- Current lines: 17.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_785_to_pass_785`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_786_to_pass_786.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_786_to_pass_786`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_787_to_pass_787.md`

- Current lines: 16.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_787_to_pass_787`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_788_to_pass_788.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_788_to_pass_788`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_789_to_pass_789.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_789_to_pass_789`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_790_to_pass_790.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_790_to_pass_790`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_791_to_pass_791.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_791_to_pass_791`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_792_to_pass_792.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_792_to_pass_792`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_794_to_pass_794.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_794_to_pass_794`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_797_to_pass_797.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_797_to_pass_797`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_798_to_pass_798.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_798_to_pass_798`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_799_to_pass_799.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_799_to_pass_799`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_800_to_pass_800.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_800_to_pass_800`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_801_to_pass_801.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_801_to_pass_801`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_802_to_pass_802.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_802_to_pass_802`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_803_to_pass_803.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_803_to_pass_803`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_804_to_pass_804.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_804_to_pass_804`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_805_to_pass_805.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_805_to_pass_805`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_806_to_pass_806.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_806_to_pass_806`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_807_to_pass_807.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_807_to_pass_807`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_808_to_pass_808.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_808_to_pass_808`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_809_to_pass_809.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_809_to_pass_809`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_810_to_pass_810.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_810_to_pass_810`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_811_to_pass_811.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_811_to_pass_811`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_812_to_pass_812.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_812_to_pass_812`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_813_to_pass_813.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_813_to_pass_813`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_814_to_pass_814.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_814_to_pass_814`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_815_to_pass_815.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_815_to_pass_815`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_816_to_pass_816.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_816_to_pass_816`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_817_to_pass_817.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_817_to_pass_817`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_818_to_pass_818.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_818_to_pass_818`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_819_to_pass_819.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_819_to_pass_819`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_820_to_pass_820.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_820_to_pass_820`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_821_to_pass_821.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_821_to_pass_821`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_822_to_pass_822.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_822_to_pass_822`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_823_to_pass_823.md`

- Current lines: 22.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_823_to_pass_823`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_824_to_pass_824.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_824_to_pass_824`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_825_to_pass_825.md`

- Current lines: 16.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_825_to_pass_825`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_826_to_pass_826.md`

- Current lines: 16.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_826_to_pass_826`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_827_to_pass_827.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_827_to_pass_827`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_834_to_pass_834.md`

- Current lines: 21.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_834_to_pass_834`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_841_to_pass_841.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_841_to_pass_841`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_847_to_pass_847.md`

- Current lines: 17.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_847_to_pass_847`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_855_to_pass_855.md`

- Current lines: 18.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_855_to_pass_855`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_860_to_pass_860.md`

- Current lines: 17.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_860_to_pass_860`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_865_to_pass_865.md`

- Current lines: 19.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_865_to_pass_865`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_868_to_pass_868.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_868_to_pass_868`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_870_to_pass_870.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_870_to_pass_870`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_871_to_pass_871.md`

- Current lines: 23.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_871_to_pass_871`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_cleanup_pass_log_archive_from_pass_872_to_pass_872.md`

- Current lines: 24.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_cleanup_pass_log_archive_from_pass_872_to_pass_872`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_completion_map.md`

- Current lines: 177.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_completion_map`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_double_team_handoff.md`

- Current lines: 361.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_double_team_handoff`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_flutter_reuse_audit.md`

- Current lines: 185.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_flutter_reuse_audit`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_handoff_2026_07_03.md`

- Current lines: 850.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_handoff_2026_07_03`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan.md`

- Current lines: 316.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_current_status.md`

- Current lines: 377.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_current_status`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_005_to_pass_025.md`

- Current lines: 441.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_005_to_pass_025`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_021_to_pass_070.md`

- Current lines: 450.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_021_to_pass_070`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_026_to_pass_046.md`

- Current lines: 431.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_026_to_pass_046`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_047_to_pass_067.md`

- Current lines: 429.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_047_to_pass_067`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_071_to_pass_085.md`

- Current lines: 440.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_071_to_pass_085`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_086_to_pass_102.md`

- Current lines: 429.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_086_to_pass_102`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1014_to_pass_1028.md`

- Current lines: 436.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_1014_to_pass_1028`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1029_to_pass_1044.md`

- Current lines: 444.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_1029_to_pass_1044`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_103_to_pass_122.md`

- Current lines: 433.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_103_to_pass_122`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1045_to_pass_1058.md`

- Current lines: 441.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_1045_to_pass_1058`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1059_to_pass_1074.md`

- Current lines: 448.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_1059_to_pass_1074`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1075_to_pass_1088.md`

- Current lines: 448.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_1075_to_pass_1088`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_107_to_pass_004.md`

- Current lines: 426.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_107_to_pass_004`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1089_to_pass_1102.md`

- Current lines: 449.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_1089_to_pass_1102`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1103_to_pass_1118.md`

- Current lines: 431.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_1103_to_pass_1118`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1119_to_pass_1132.md`

- Current lines: 430.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_1119_to_pass_1132`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1133_to_pass_1146.md`

- Current lines: 425.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_1133_to_pass_1146`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1147_to_pass_1159.md`

- Current lines: 440.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_1147_to_pass_1159`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1160_to_pass_1172.md`

- Current lines: 428.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_1160_to_pass_1172`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1173_to_pass_1184.md`

- Current lines: 456.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_1173_to_pass_1184`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1185_to_pass_1197.md`

- Current lines: 435.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_1185_to_pass_1197`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1198_to_pass_1198.md`

- Current lines: 33.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_1198_to_pass_1198`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_123_to_pass_255.md`

- Current lines: 432.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_123_to_pass_255`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_124_to_pass_108.md`

- Current lines: 448.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_124_to_pass_108`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_141_to_pass_125.md`

- Current lines: 441.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_141_to_pass_125`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_156_to_pass_142.md`

- Current lines: 435.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_156_to_pass_142`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_172_to_pass_157.md`

- Current lines: 438.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_172_to_pass_157`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_189_to_pass_173.md`

- Current lines: 442.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_189_to_pass_173`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_205_to_pass_190.md`

- Current lines: 441.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_205_to_pass_190`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_220_to_pass_206.md`

- Current lines: 449.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_220_to_pass_206`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_225_to_pass_239.md`

- Current lines: 439.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_225_to_pass_239`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_240_to_pass_221.md`

- Current lines: 437.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_240_to_pass_221`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_256_to_pass_271.md`

- Current lines: 442.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_256_to_pass_271`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_272_to_pass_289.md`

- Current lines: 442.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_272_to_pass_289`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_290_to_pass_306.md`

- Current lines: 427.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_290_to_pass_306`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_307_to_pass_321.md`

- Current lines: 425.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_307_to_pass_321`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_322_to_pass_336.md`

- Current lines: 432.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_322_to_pass_336`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_337_to_pass_352.md`

- Current lines: 434.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_337_to_pass_352`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_353_to_pass_871.md`

- Current lines: 449.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_353_to_pass_871`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_367_to_pass_530.md`

- Current lines: 437.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_367_to_pass_530`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_373_to_pass_870.md`

- Current lines: 424.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_373_to_pass_870`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_422_to_pass_414.md`

- Current lines: 447.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_422_to_pass_414`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_483_to_pass_371.md`

- Current lines: 438.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_483_to_pass_371`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_508_to_pass_421.md`

- Current lines: 433.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_508_to_pass_421`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_531_to_pass_887.md`

- Current lines: 424.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_531_to_pass_887`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_546_to_pass_507.md`

- Current lines: 447.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_546_to_pass_507`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_554_to_pass_545.md`

- Current lines: 450.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_554_to_pass_545`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_570_to_pass_564.md`

- Current lines: 450.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_570_to_pass_564`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_587_to_pass_628.md`

- Current lines: 425.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_587_to_pass_628`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_607_to_pass_569.md`

- Current lines: 435.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_607_to_pass_569`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_627_to_pass_608.md`

- Current lines: 436.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_627_to_pass_608`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_639_to_pass_586.md`

- Current lines: 427.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_639_to_pass_586`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_654_to_pass_638.md`

- Current lines: 432.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_654_to_pass_638`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_684_to_pass_653.md`

- Current lines: 437.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_684_to_pass_653`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_693_to_pass_683.md`

- Current lines: 428.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_693_to_pass_683`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_701_to_pass_692.md`

- Current lines: 427.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_701_to_pass_692`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_721_to_pass_700.md`

- Current lines: 432.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_721_to_pass_700`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_738_to_pass_720.md`

- Current lines: 446.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_738_to_pass_720`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_760_to_pass_739.md`

- Current lines: 439.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_760_to_pass_739`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_770_to_pass_759.md`

- Current lines: 427.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_770_to_pass_759`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_788_to_pass_769.md`

- Current lines: 444.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_788_to_pass_769`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_805_to_pass_789.md`

- Current lines: 436.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_805_to_pass_789`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_816_to_pass_804.md`

- Current lines: 433.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_816_to_pass_804`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_834_to_pass_815.md`

- Current lines: 435.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_834_to_pass_815`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_846_to_pass_833.md`

- Current lines: 447.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_846_to_pass_833`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_857_to_pass_853.md`

- Current lines: 438.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_857_to_pass_853`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_872_to_pass_372.md`

- Current lines: 441.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_872_to_pass_372`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_888_to_pass_903.md`

- Current lines: 439.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_888_to_pass_903`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_904_to_pass_918.md`

- Current lines: 439.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_904_to_pass_918`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_919_to_pass_933.md`

- Current lines: 442.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_919_to_pass_933`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_934_to_pass_948.md`

- Current lines: 446.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_934_to_pass_948`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_949_to_pass_964.md`

- Current lines: 435.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_949_to_pass_964`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_965_to_pass_982.md`

- Current lines: 438.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_965_to_pass_982`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_983_to_pass_997.md`

- Current lines: 435.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_983_to_pass_997`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_master_pass_plan_archive_pass_998_to_pass_1013.md`

- Current lines: 434.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_master_pass_plan_archive_pass_998_to_pass_1013`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_pipeline_handoff_report.md`

- Current lines: 489.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_pipeline_handoff_report`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_pipeline_handoff_report_archive_qa_and_remaining_work.md`

- Current lines: 308.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_pipeline_handoff_report_archive_qa_and_remaining_work`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_product_standard.md`

- Current lines: 196.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_product_standard`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_state_of_art_spec.md`

- Current lines: 500.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_state_of_art_spec`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_state_of_art_spec_archive_completion_evidence.md`

- Current lines: 20.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_state_of_art_spec_archive_completion_evidence`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_ocr_state_of_art_spec_archive_final_hardening.md`

- Current lines: 28.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_ocr_state_of_art_spec_archive_final_hardening`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_parallel_work_boundary.md`

- Current lines: 288.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_parallel_work_boundary`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_release_one_blueprint.md`

- Current lines: 365.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_release_one_blueprint`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_roadmap.md`

- Current lines: 256.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_roadmap`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_spark_execution_roadmap.md`

- Current lines: 324.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_spark_execution_roadmap`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_world_class_qa_standard.md`

- Current lines: 178.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_world_class_qa_standard`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_camera_world_class_readiness.md`

- Current lines: 137.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_camera_world_class_readiness`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_cloud_vision_security_plan.md`

- Current lines: 61.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_cloud_vision_security_plan`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_entry_ui_contract.md`

- Current lines: 64.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_entry_ui_contract`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_native_camera_service_spec.md`

- Current lines: 324.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_native_camera_service_spec`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_ocr_build_reading_manifest.md`

- Current lines: 91.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_ocr_build_reading_manifest`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_ocr_competitive_benchmark.md`

- Current lines: 96.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_ocr_competitive_benchmark`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_ocr_ownership_boundary.md`

- Current lines: 46.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_ocr_ownership_boundary`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_ocr_pipeline_blueprint.json`

- Current lines: 69.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_ocr_pipeline_blueprint`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_ocr_real_benchmark_intake.md`

- Current lines: 87.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_ocr_real_benchmark_intake`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_qa_backbone.md`

- Current lines: 38.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_qa_backbone`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_real_device_result_template.md`

- Current lines: 123.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_real_device_result_template`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_real_device_test_script.md`

- Current lines: 332.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_real_device_test_script`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/receipt_stitching_pass_log.md`

- Current lines: 147.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_stitching_pass_log`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.

### `docs/system_handoffs/receipt_capture_ocr_long_receipt.md`

- Current lines: 95.
- Documentation role: receipt-flow requirement, audit, evidence, regression ledger, roadmap, or handoff artifact.
- Name-derived responsibility: `receipt_capture_ocr_long_receipt`.
- Authority warning: current production source and executable tests override stale prose.
- Scope warning: this inventory does not expand the active lane.


## Appendix F: Relevant Git History

- `0f19e9b2` | 2026-07-29 07:55:33 PM EDT | Maintainiac 5.7 integration: calendar, profiles, jobs, and receipt checkpoint [2026-07-29 07:55 PM EDT]
- `c7b89705` | 2026-07-27 10:23:52 PM EDT | Checkpoint current Maintainiac work
- `b66525dd` | 2026-07-27 04:09:06 AM EDT | 2026-07-27  EDT - add ask each time receipt style
- `dfd5f6f4` | 2026-07-27 12:22:39 AM EDT | 2026-07-27  EDT - preserve per-photo capture zoom
- `1984f771` | 2026-07-27 12:05:49 AM EDT | 2026-07-27 02:15 AM EDT - preserve receipt review tooltip semantics
- `7bf28bd4` | 2026-07-27 12:03:11 AM EDT | 2026-07-27 01:15 AM EDT - announce receipt OCR progress
- `e533151e` | 2026-07-26 11:56:39 PM EDT | 2026-07-27 12:30 AM EDT - harden compact receipt review controls
- `156403f7` | 2026-07-26 11:52:24 PM EDT | 2026-07-27 12:15 AM EDT - mark receipt settings reset destructive
- `ebe8b5b7` | 2026-07-26 11:45:13 PM EDT | 2026-07-26 11:45 PM EDT - receipt flow UI and OCR handoff
- `d38333ce` | 2026-07-26 03:14:02 AM EDT | 2026-07-26 03:13 EDT — Receipt Assist and camera UX milestone
- `f07d1a09` | 2026-07-22 04:01:56 PM EDT | [5.7] Complete semantic repository consolidation
- `6bf01ced` | 2026-07-22 12:39:55 PM EDT | [5.7] Reconcile OCR evidence and recovery improvements
- `16ef2f82` | 2026-07-22 12:33:51 PM EDT | [5.7] Enforce receipt recovery cleanup boundaries
- `20a6fc56` | 2026-07-22 11:47:19 AM EDT | [5.7] Remove permanent receipt proof deletion
- `616a6334` | 2026-07-22 10:58:08 AM EDT | Guard explicit managed receipt proof removal
- `35a4cb4b` | 2026-07-22 10:53:51 AM EDT | Expose truthful receipt storage choices
- `ba65c508` | 2026-07-22 10:51:53 AM EDT | Serialize reviewed receipt OCR handoff
- `6367825a` | 2026-07-22 10:48:45 AM EDT | Keep staged Expense proof through checkpoint
- `20eb1528` | 2026-07-22 10:37:38 AM EDT | Port labeled receipt OCR benchmark gate
- `a5e3de9b` | 2026-07-22 04:22:53 AM EDT | Finalize Maintainiac 5.7 consolidation
- `6a6ac0a5` | 2026-07-22 04:08:30 AM EDT | Merge compatible Receipt Camera improvements
- `98ef1d51` | 2026-07-22 04:02:02 AM EDT | Migrate receipt camera preference mapping
- `a0cb57c1` | 2026-07-21 11:18:18 PM EDT | Harden receipt review touch targets and QA contracts
- `e7e6ca58` | 2026-07-21 11:14:20 PM EDT | Merge preserved receipt camera review and OCR handoff work
- `de27c9eb` | 2026-07-21 11:04:37 PM EDT | Preserve receipt camera review and OCR handoff work
- `8a3fa96d` | 2026-07-21 02:59:11 PM EDT | chore: preserve integrated workspace changes
- `6846c5c5` | 2026-07-19 02:55:42 AM EDT | Harden receipt capture quality policies
- `234654ec` | 2026-07-17 06:49:23 PM EDT | Receipt camera: keep capture and review responsive
- `532a8b27` | 2026-07-16 12:18:16 PM EDT | Receipt camera: preserve active capture session
- `c7f94e13` | 2026-07-16 11:58:14 AM EDT | Receipt camera: harden capture review handoff
- `219af94f` | 2026-07-16 11:38:11 AM EDT | Receipt camera: streamline review handoff
- `0c984e74` | 2026-07-16 11:18:06 AM EDT | Receipt camera: harden capture controls
- `7b815e63` | 2026-07-16 10:58:16 AM EDT | Receipt camera: add safe crop suggestions
- `654db0f4` | 2026-07-16 10:38:11 AM EDT | Receipt camera: harden review settings
- `924efbc4` | 2026-07-16 10:18:28 AM EDT | Receipt camera: restore full regression gate
- `c8992e92` | 2026-07-16 10:10:01 AM EDT | Fix receipt review source check
- `f0e1f866` | 2026-07-16 10:08:56 AM EDT | Receipt camera: harden review handoff
- `7f0fe7ca` | 2026-07-16 09:50:48 AM EDT | Receipt camera: honor capture preferences
- `212c79e0` | 2026-07-16 09:33:01 AM EDT | Receipt camera: strengthen review recovery
- `529da0ea` | 2026-07-16 03:56:16 AM EDT | Receipt camera: harden capture handoff failures
- `95cbde99` | 2026-07-16 12:14:41 AM EDT | Pass 519 2026-07-16 harden capture recovery storage
- `9944c6f3` | 2026-07-15 11:35:29 PM EDT | Pass 485 2026-07-15 reject empty receipt proof files
- `98cb796e` | 2026-07-15 10:53:22 PM EDT | Pass 441 2026-07-15 preserve occupied receipt proofs
- `ac53b83f` | 2026-07-15 09:24:55 PM EDT | Receipt camera: preserve acquired photo sources
- `68d1d7d1` | 2026-07-15 09:04:44 PM EDT | Receipt camera: harden live quality guidance
- `bfcac90b` | 2026-07-15 08:52:08 PM EDT | Receipt camera: harden capture handoff
- `89367d80` | 2026-07-15 08:45:49 PM EDT | Receipt camera: clarify review and prevent control clipping
- `dcd0883d` | 2026-07-15 07:28:09 PM EDT | Receipt: preserve user category decisions
- `0b4bf6cf` | 2026-07-15 07:13:07 PM EDT | Receipt: simplify assist settings and labels
- `6ed90aed` | 2026-07-15 07:03:57 PM EDT | Receipt: preserve OCR handoff and simplify review
- `f5cd4797` | 2026-07-15 06:48:38 PM EDT | Pass 176 2026-07-15 21:16 EDT: cover high-overlap receipt stitches
- `6b2b8356` | 2026-07-15 06:45:07 PM EDT | Pass 179 2026-07-15 21:26 EDT: retain const proof storage contract
- `08359a36` | 2026-07-15 06:44:37 PM EDT | Pass 178 2026-07-15 21:20 EDT: serialize receipt proof writes
- `14d4f8c3` | 2026-07-15 06:40:51 PM EDT | Pass 177 2026-07-15 21:12 EDT: retain permanent receipt proof
- `e1dc908c` | 2026-07-15 06:25:12 PM EDT | Pass 163 2026-07-15 19:42 EDT: honor original proof retention
- `d911d50b` | 2026-07-15 06:19:22 PM EDT | Pass 160 2026-07-15 19:05 EDT: preserve proof fingerprints
- `56de344a` | 2026-07-15 06:13:40 PM EDT | Pass 158 2026-07-15 18:36 EDT: require server backup entitlements
- `ed55a5d5` | 2026-07-15 05:26:03 PM EDT | Pass 115 2026-07-15 23:10 EDT: align proof storage previews
- `df0c058c` | 2026-07-15 05:02:48 PM EDT | Pass 101 2026-07-15 19:35 EDT: confine proof rollback restoration
- `62440462` | 2026-07-15 05:02:09 PM EDT | Pass 100 2026-07-15 19:25 EDT: preserve external receipt proof files
- `51b11efc` | 2026-07-15 04:42:27 PM EDT | Pass 086 2026-07-15 16:50 EDT: mark missing receipt proof files
- `44e30d67` | 2026-07-15 03:01:49 PM EDT | Pass 005 2026-07-15 14:30 EDT: add Canadian locale support
- `113c7ea7` | 2026-07-13 10:53:16 PM EDT | Receipt OCR: reconstruct rows and scale device workload
- `e5422997` | 2026-07-13 10:35:22 PM EDT | Receipt OCR: preserve source text and close safely
- `5de71b68` | 2026-07-13 09:24:23 PM EDT | Receipt review: clarify user actions and reading status
- `22caab52` | 2026-07-13 09:04:32 PM EDT | Receipt flow: expose automatic filling opt-in
- `896b1537` | 2026-07-13 07:47:10 PM EDT | Receipt QA: close source audit contract gaps
- `0a147f0e` | 2026-07-13 07:26:45 PM EDT | Receipt review: expand user-facing handoff QA
- `7c3b5078` | 2026-07-13 07:06:32 PM EDT | Receipt workflow: stop spinner and clarify review progress
- `5727f6cc` | 2026-07-13 06:37:44 PM EDT | Receipt review: align basic simple and detailed modes
- `d6c238e6` | 2026-07-13 06:12:20 PM EDT | OCR: expose source-preserving layout evidence
- `0b9444b2` | 2026-07-13 05:55:10 PM EDT | OCR: expose faithful source and display evidence
- `e862db72` | 2026-07-13 05:32:47 PM EDT | Receipt review: add basic receipt mode and build manifest
- `ed005ea4` | 2026-07-13 01:04:18 PM EDT | 2026-07-13 13:04 ET Receipt OCR: protect attachment ingestion integrity
- `2206e585` | 2026-07-13 12:11:33 PM EDT | 2026-07-13 12:18 ET Receipt OCR: expose selected route handoff hooks
- `08fa4466` | 2026-07-13 12:07:53 PM EDT | 2026-07-13 12:07 ET Receipt OCR: normalized handoff and recovery
- `7fe85409` | 2026-07-12 07:32:09 PM EDT | Pass 2799 2026-07-12 19:32 EDT: localize OCR proof preview
- `25f17b51` | 2026-07-12 07:18:51 PM EDT | Pass 2796 2026-07-12 19:18 EDT: repair receipt review QA contracts
- `46fae219` | 2026-07-12 07:02:49 PM EDT | Pass 2795 2026-07-12 EDT: repair camera QA contracts
- `c8f70561` | 2026-07-12 05:49:01 PM EDT | Pass 2794 2026-07-12 EDT: localize receipt review controls
- `539e136a` | 2026-07-12 05:43:37 PM EDT | Pass 2792 2026-07-12 EDT: localize native receipt camera controls
- `5c26457f` | 2026-07-12 05:32:49 PM EDT | Pass 2789 2026-07-12 EDT: refine receipt camera capability profiles
- `99577092` | 2026-07-12 05:30:11 PM EDT | Pass 2788 2026-07-12 EDT: enforce receipt proof compression policy
- `0fbdcd5c` | 2026-07-12 05:24:22 PM EDT | Pass 2787 2026-07-12 EDT: repair receipt settings and pinch zoom
- `fb34ffde` | 2026-07-12 01:33:45 AM EDT | Safety snapshot 2026-07-12 EDT: preserve mixed Maintainiac 5.6 Active work before isolated worktrees
- `7dd46ff0` | 2026-07-10 11:06:33 PM EDT | Pass 2785 2026-07-10 06:05 PM EDT: add manual OCR recovery path
- `fa57cb65` | 2026-07-10 06:26:11 PM EDT | Pass 2784 2026-07-10 06:02 PM EDT: add receipt OCR retry recovery
- `6d96c542` | 2026-07-10 05:48:15 PM EDT | Pass 2783 2026-07-10 05:48 PM EDT harden mixed-source long receipts
- `d3c438e1` | 2026-07-10 05:45:51 PM EDT | Pass 2782 2026-07-10 05:45 PM EDT harden damaged long-receipt overlaps
- `906c6099` | 2026-07-10 05:40:35 PM EDT | Pass 2781 2026-07-10 05:40 PM EDT harden long-receipt orientation review
- `db1755c0` | 2026-07-10 04:51:20 PM EDT | Pass 2682 2026-07-10 04:58 AM EDT: configure receipt OCR status copy
- `9b5f9a4a` | 2026-07-10 03:17:53 AM EDT | Pass 2678 2026-07-10 04:39 AM EDT: enforce unobstructed receipt review
- `80ab96ad` | 2026-07-10 03:09:30 AM EDT | Pass 2676 2026-07-10 04:31 AM EDT: configure receipt settings actions
- `b5024a77` | 2026-07-10 03:05:31 AM EDT | Pass 2675 2026-07-10 04:27 AM EDT: route configurable receipt review UI
- `dca8c2d8` | 2026-07-10 02:59:14 AM EDT | Pass 2674 2026-07-10 04:23 AM EDT: configurable full-screen receipt settings
- `850166f6` | 2026-07-10 02:46:43 AM EDT | Pass 2673 2026-07-10 03:02 AM EDT: stage configurable OCR progress
- `519a9c0a` | 2026-07-10 02:43:05 AM EDT | Pass 2672 2026-07-10 02:46 AM EDT: configure native camera shell controls
- `68ac9121` | 2026-07-10 02:38:29 AM EDT | Pass 2671 2026-07-10 02:34 AM EDT: configure receipt first-use workflow
- `d8c1f7ad` | 2026-07-10 02:32:49 AM EDT | Pass 2670 2026-07-10 02:22 AM EDT: configurable unobstructed receipt review
- `9a4faf9b` | 2026-07-10 01:41:39 AM EDT | Pass 2669 2026-07-10 01:41 AM EDT: open add-photo capture directly
- `88b70319` | 2026-07-10 12:51:17 AM EDT | Pass 2777 2026-07-10 01:02 AM EDT fix proof setting ledger category
- `1e2cdb4e` | 2026-07-10 12:45:46 AM EDT | Pass 2760 2026-07-10 12:49 AM EDT harden stale receipt proof setting
- `36436b33` | 2026-07-10 12:20:31 AM EDT | Pass 2718 2026-07-10 12:34 AM EDT include passenger seat stitch gate
- `172b0ac9` | 2026-07-10 12:19:11 AM EDT | Pass 2714 2026-07-10 12:30 AM EDT add passenger seat stitch regression
- `86964998` | 2026-07-10 12:12:18 AM EDT | Pass 2697 2026-07-10 12:14 AM EDT record stitch timeout regression
- `630e59f4` | 2026-07-10 12:09:55 AM EDT | Pass 2691 2026-07-10 12:30 AM EDT bound stitch comparison cost
- `fac69b56` | 2026-07-09 11:53:06 PM EDT | Pass 2669 2026-07-09 11:56 PM EDT camera quick gate repair
- `6f3cf13f` | 2026-07-09 11:45:37 PM EDT | pass 2668 2026-07-09 11:45 PM EDT normalize retake guide reasons
- `790cd09c` | 2026-07-09 11:43:50 PM EDT | pass 2667 2026-07-09 11:43 PM EDT normalize backup ghost reasons
- `dcba7621` | 2026-07-09 11:41:57 PM EDT | pass 2666 2026-07-09 11:41 PM EDT reject empty ghost reason tokens
- `68cfa632` | 2026-07-09 11:40:25 PM EDT | pass 2665 2026-07-09 11:40 PM EDT normalize continuation ghost reasons
- `febe4e57` | 2026-07-09 11:38:24 PM EDT | pass 2664 2026-07-09 11:38 PM EDT normalize ghost guide reasons
- `669303b4` | 2026-07-09 11:35:09 PM EDT | Pass 2578 12:31 AM receipt storage estimates and split stitch gate
- `5283c537` | 2026-07-09 11:33:26 PM EDT | pass 2663 2026-07-09 11:33 PM EDT preserve stitch exception pair context
- `e9edaf1c` | 2026-07-09 11:29:56 PM EDT | pass 2662 2026-07-09 11:29 PM EDT complete stitching gate coverage
- `6c8dcab6` | 2026-07-09 11:25:32 PM EDT | pass 2661 2026-07-09 11:25 PM EDT cover extreme stitch gates
- `3b07a393` | 2026-07-09 10:59:22 PM EDT | pass 2660 2026-07-09 10:59 PM EDT split section-order QA fixtures
- `7a0eb9c0` | 2026-07-09 10:45:22 PM EDT | pass 2658 2026-07-09 expand ghost handoff QA pack
- `f33e4549` | 2026-07-09 10:43:39 PM EDT | pass 2657 2026-07-09 prune removed receipt diagnostics
- `53f98a86` | 2026-07-09 10:08:14 PM EDT | pass 2654 2026-07-09 include removal order OCR handoff QA
- `b1ed9b7e` | 2026-07-09 10:05:54 PM EDT | pass 2653 2026-07-09 surface removal order in OCR handoff
- `110407fc` | 2026-07-09 10:03:35 PM EDT | pass 2652 2026-07-09 validate removal section set consistency
- `d385acf8` | 2026-07-09 09:54:51 PM EDT | pass 2651 2026-07-09 bound removal section metadata
- `2a0e8075` | 2026-07-09 09:52:30 PM EDT | pass 2650 2026-07-09 validate removal order before OCR handoff
- `ae8b74b0` | 2026-07-09 09:46:15 PM EDT | pass 2649 2026-07-09 09:46 PM EDT preserve removal shifts in long-receipt handoff [checks: Dart regressions, analyzer, stitch handoff health, diff check]
- `abfb217c` | 2026-07-09 09:39:17 PM EDT | pass 2648 2026-07-09 09:39 PM EDT validate and surface final neighbor order metadata [checks: targeted Dart tests, analyzer, stitch handoff health, diff check]
- `95b8fb27` | 2026-07-09 09:34:16 PM EDT | pass 2647 2026-07-09 09:34 PM EDT preserve following section order after photo insertion [checks: Dart regressions, stitch handoff health, diff check]
- `8a15f8e1` | 2026-07-09 09:32:02 PM EDT | pass 2646 2026-07-09 09:32 PM EDT dedupe uploaded receipt sections before stitch review [checks: Dart regressions, stitch handoff health, diff check]
- `37b83817` | 2026-07-09 09:29:11 PM EDT | pass 2645 2026-07-09 09:29 PM EDT preserve final neighbor order after retake insertion [checks: Dart regressions, stitch handoff health, diff check]
- `d7f29d11` | 2026-07-09 09:27:04 PM EDT | pass 2644 2026-07-09 09:30 PM EDT restrict two-sided ghost to middle retakes [checks: Dart regressions, stitch handoff health, diff check]
- `2ae7841e` | 2026-07-09 09:21:43 PM EDT | pass 2643 2026-07-09 09:21 PM EDT two-sided long-receipt retake ghost handoff [checks: Dart tests, stitch handoff gate, Swift parse; Android compile blocked by missing Java]
- `9148785b` | 2026-07-09 09:13:02 PM EDT | pass 2642 2026-07-09 09:12 PM EDT split long-stack stitch QA pack [checks: shell syntax, contract test, 8 long-stack scenarios]
- `bf8f0001` | 2026-07-09 09:02:09 PM EDT | Long receipt stitch pass - 2026-07-09 09:02 PM EDT - extreme aspect ratio fallback [checks: analyzer, contract, extreme stitch pack]
- `6ff7fd49` | 2026-07-09 07:52:44 PM EDT | Long receipt stitch pass - 2026-07-09 07:52 PM EDT - retake guidance hardening [checks: section-order tests, retake-order test, stitch health]
- `cb4e9659` | 2026-07-08 11:46:36 PM EDT | Receipt camera settings polish - 2026-07-08 23:46 EDT
- `5ecbb8fd` | 2026-07-08 11:06:28 PM EDT | Camera receipt settings flow hardening - 2026-07-08 23:06 EDT
- `0ecdda7f` | 2026-07-08 04:02:58 PM EDT | pass 2641 2026-07-08 04:04 PM EDT wire wrinkled long stack gate
- `1f05c659` | 2026-07-08 04:00:53 PM EDT | pass 2639 2026-07-08 04:01 PM EDT wire wrinkled stitch gate
- `1e06ce88` | 2026-07-08 03:57:04 PM EDT | pass 2637 2026-07-08 03:59 PM EDT extend rough rotation stitch tolerance
- `7e6d9696` | 2026-07-08 03:55:58 PM EDT | pass 2636 2026-07-08 03:57 PM EDT wire rough rotation stitch gate
- `27c99757` | 2026-07-08 03:55:10 PM EDT | pass 2635 2026-07-08 03:55 PM EDT harden rough rotation stitching
- `bfafcaed` | 2026-07-08 03:42:33 PM EDT | pass 2633 2026-07-08 03:45 PM EDT add synthetic dataset stitch gate mode
- `80a0dc1b` | 2026-07-08 03:38:01 PM EDT | pass 2630 2026-07-08 03:36 PM EDT add synthetic stitch dataset audit
- `965563b0` | 2026-07-08 03:19:49 PM EDT | pass 2625 2026-07-08 03:17 PM EDT include transformed phone windows in stitch gates
- `819e6d3a` | 2026-07-08 03:18:30 PM EDT | pass 2624 2026-07-08 03:16 PM EDT add transformed phone-window stitch QA
- `6fdd0afe` | 2026-07-08 03:15:36 PM EDT | pass 2623 2026-07-08 03:14 PM EDT add transformed stitch QA mode
- `a02c1b17` | 2026-07-08 03:05:37 PM EDT | pass 2620 2026-07-08 03:04 PM EDT treat section action as handoff risk
- `94f60a4b` | 2026-07-08 02:48:13 PM EDT | pass 2618 2026-07-08 02:46 PM EDT require multi-section fallback review
- `2c0286a9` | 2026-07-08 02:42:51 PM EDT | pass 2616 2026-07-08 02:41 PM EDT add store receipt stitch qa mode
- `21efa5c7` | 2026-07-08 02:38:14 PM EDT | pass 2615 2026-07-08 02:39 PM EDT normalize ghost guide reasons
- `7b61f575` | 2026-07-08 02:36:43 PM EDT | pass 2614 2026-07-08 02:33 PM EDT add store receipt stitch fixture
- `c8485294` | 2026-07-08 02:32:03 PM EDT | pass 2613 2026-07-08 02:30 PM EDT track multi-section fallback handoff
- `0a89a54b` | 2026-07-08 02:26:45 PM EDT | pass 2611 2026-07-08 02:25 PM EDT infer multi-section fallback order
- `e54b01db` | 2026-07-08 02:19:00 PM EDT | pass 2609 2026-07-08 02:18 PM EDT normalize stitch fallback counts
- `4589f83c` | 2026-07-08 02:16:18 PM EDT | pass 2608 2026-07-08 02:16 PM EDT count oversized stitch fallback
- `48273b19` | 2026-07-08 02:11:58 PM EDT | pass 2606 2026-07-08 02:11 PM EDT include mixed transform gate
- `a5c52614` | 2026-07-08 01:56:07 PM EDT | pass 2604 2026-07-08 01:56 PM EDT dedupe stitch milestone gate
- `68530b29` | 2026-07-08 01:55:06 PM EDT | pass 2603 2026-07-08 01:54 PM EDT wire stitch size-cap health
- `2027f818` | 2026-07-08 01:52:40 PM EDT | pass 2602 2026-07-08 01:52 PM EDT split stitch size caps
- `1ef2b699` | 2026-07-08 01:48:16 PM EDT | pass 2601 2026-07-08 01:48 PM EDT tag oversized stitch pair
- `de27f031` | 2026-07-08 01:23:39 PM EDT | pass 2598 2026-07-08 01:23 PM EDT gate ghost retake order
- `ca3cff6e` | 2026-07-08 01:06:59 PM EDT | pass 2596 2026-07-08 01:06 PM EDT harden dark screenshot stitching
- `fb76a698` | 2026-07-08 12:45:51 PM EDT | pass 2594 2026-07-08 12:45 PM EDT tighten core gate proof
- `17a4ed5b` | 2026-07-08 12:19:20 PM EDT | pass 2593 2026-07-08 12:19 PM EDT include section order in core gate
- `2c1d7e7d` | 2026-07-08 12:05:08 PM EDT | pass 2591 2026-07-08 12:05 PM EDT include bad inputs in core gate
- `b91145b4` | 2026-07-08 12:04:26 PM EDT | pass 2590 2026-07-08 12:04 PM EDT include manual overlap in core gate
- `1537fc6a` | 2026-07-08 11:47:51 AM EDT | pass 2588 2026-07-08 11:47 AM EDT classify stitch path aliases
- `26d317a1` | 2026-07-08 11:35:43 AM EDT | pass 2587 2026-07-08 11:35 AM EDT label invalid stitch paths
- `de613391` | 2026-07-08 11:33:45 AM EDT | pass 2586 2026-07-08 11:33 AM EDT preflight invalid stitch paths
- `73eaa19c` | 2026-07-08 11:30:16 AM EDT | pass 2584 2026-07-08 11:30 AM EDT add ghost handoff stitch gate
- `6a9007b7` | 2026-07-08 11:28:37 AM EDT | pass 2583 2026-07-08 11:28 AM EDT add uploaded screenshot stitch gate
- `b2fedbcf` | 2026-07-08 11:26:47 AM EDT | pass 2581 2026-07-08 11:26 AM EDT add uploaded screenshot stitch qa
- `5e734d13` | 2026-07-08 11:08:52 AM EDT | pass 2578 2026-07-08 11:08 AM EDT add core stitch qa gate
- `3a4b93b6` | 2026-07-08 10:54:23 AM EDT | pass 2576 2026-07-08 10:54 AM EDT gate ghost handoff contract
- `c41c955c` | 2026-07-08 10:48:51 AM EDT | pass 2575 2026-07-08 10:48 AM EDT gate stitch artifact handoff
- `35fb9e64` | 2026-07-08 10:44:16 AM EDT | pass 2574 2026-07-08 10:44 AM EDT split stitch artifact contract
- `3679773f` | 2026-07-08 10:42:30 AM EDT | pass 2573 2026-07-08 10:42 AM EDT reject invalid stitch ocr paths
- `03640375` | 2026-07-08 10:39:25 AM EDT | pass 2572 2026-07-08 10:39 AM EDT gate stitch handoff contracts
- `aac568bd` | 2026-07-08 10:37:52 AM EDT | pass 2571 2026-07-08 10:37 AM EDT gate stitch result contract
- `51b4722c` | 2026-07-08 10:36:39 AM EDT | pass 2570 2026-07-08 10:36 AM EDT block aliased stitched ocr source
- `156820e2` | 2026-07-08 10:29:29 AM EDT | pass 2567 2026-07-08 10:29 AM EDT harden stitch drift matcher
- `b75cbc87` | 2026-07-08 10:21:28 AM EDT | pass 2566 2026-07-08 10:21 AM EDT gate cumulative stitch drift
- `1313f796` | 2026-07-08 10:15:13 AM EDT | pass 2556-2565 2026-07-08 10:15 AM EDT preserve cumulative stitch drift
- `839de6bb` | 2026-07-08 10:05:25 AM EDT | pass 2553-2555 2026-07-08 10:05 AM EDT harden tight vertical edge stitching
- `74744852` | 2026-07-08 09:58:36 AM EDT | pass 2529-2550 2026-07-08 09:58 AM EDT fix stitch gate failure reporting
- `05143e12` | 2026-07-08 09:38:31 AM EDT | pass 2522-2523 2026-07-08 09:38 AM EDT add stitch gate watchdog
- `7db35502` | 2026-07-08 09:37:05 AM EDT | pass 2515-2521 2026-07-08 09:36 AM EDT add tight-overlap stitch regression
- `56daa2a8` | 2026-07-08 09:26:39 AM EDT | pass 2513-2514 2026-07-08 09:26 AM EDT add stitch section-order gate
- `b0d0ebb6` | 2026-07-08 09:16:16 AM EDT | pass 2492-2512 2026-07-08 09:54 AM EDT harden long receipt stitch and ghost contracts
- `051def87` | 2026-07-08 09:12:02 AM EDT | pass 2485-2487 2026-07-08 12:59 PM EDT block unreadable fallback OCR handoff
- `699774ad` | 2026-07-08 09:08:59 AM EDT | pass 2479-2484 2026-07-08 09:06 AM EDT add fast stitch health gate
- `74be3021` | 2026-07-08 09:04:31 AM EDT | pass 2456-2475 2026-07-08 08:56 AM EDT add bad-input stitch fallback gate
- `f02964cd` | 2026-07-08 09:01:40 AM EDT | pass 2451-2454 2026-07-08 08:56 AM EDT guard ghost session test line cap
- `fdc631b8` | 2026-07-08 09:00:18 AM EDT | pass 2437 2026-07-08 12:41 PM EDT ledger phone screenshot stitch regression
- `020575e9` | 2026-07-08 09:00:06 AM EDT | pass 2436 2026-07-08 12:40 PM EDT cover phone screenshot receipt stitching
- `a032072a` | 2026-07-08 08:55:37 AM EDT | pass 2428-2434 2026-07-08 08:34 AM EDT include stitch transform in source-size gate
- `170ce1a7` | 2026-07-08 08:53:44 AM EDT | pass 2404-2425 2026-07-08 08:34 AM EDT add weak-overlap fast stitch gate
- `1eb13be2` | 2026-07-08 08:42:58 AM EDT | pass 2372-2403 2026-07-08 08:34 AM EDT harden phone-window stitch health
- `bb2e2e81` | 2026-07-08 08:38:58 AM EDT | pass 2252 2026-07-08 12:02 PM EDT split stitch transform helpers under line cap
- `c0bd8b1e` | 2026-07-08 08:36:34 AM EDT | pass 2251 2026-07-08 11:56 AM EDT add out-of-order stitch gate coverage
- `94a7bf10` | 2026-07-08 08:13:31 AM EDT | pass 2292-2343 2026-07-08 08:30 AM EDT harden delayed overlap and OCR stitch handoff
- `f5c94ed6` | 2026-07-08 08:07:49 AM EDT | pass 2245 2026-07-08 11:20 AM EDT include OCR source contract in stitch handoff gate
- `20d430f2` | 2026-07-08 08:05:04 AM EDT | pass 2258-2275 2026-07-08 08:20 AM EDT harden OCR source fallback stitch contract
- `899f14ff` | 2026-07-08 07:49:37 AM EDT | pass 2203-2243 2026-07-08 08:04 AM EDT strengthen stitch health scripts and long receipt regressions
- `72658d4b` | 2026-07-08 07:44:12 AM EDT | pass 2190-2192 2026-07-08 08:29 AM EDT quiet stitch health script output
- `c49cd8c7` | 2026-07-08 07:41:59 AM EDT | pass 2183-2189 2026-07-08 07:48 AM EDT cover vertical edge crop stitch safety
- `840a4ebc` | 2026-07-08 07:37:31 AM EDT | pass 2163-2166 2026-07-08 07:41 AM EDT add fallback metadata to stitch handoff health
- `75a2c6ab` | 2026-07-08 07:36:35 AM EDT | pass 2117-2160 2026-07-08 07:39 AM EDT harden stitch exposure handoff metadata and search cost
- `9de8e882` | 2026-07-08 07:17:23 AM EDT | pass 2090-2112 2026-07-08 07:25 AM EDT cover stitch handoff metadata exposure shifts and phone windows
- `f5d17ef2` | 2026-07-08 07:16:01 AM EDT | pass 2080-2085 2026-07-08 07:20 AM EDT cover stronger stitch rotation
- `8f975d80` | 2026-07-08 07:13:38 AM EDT | pass 2063-2077 2026-07-08 07:17 AM EDT cover combined stitch transform regression
- `c45122b5` | 2026-07-08 07:07:45 AM EDT | pass 2058-2061 2026-07-08 07:11 AM EDT cover stitch handoff tests in source-size health
- `5c507db4` | 2026-07-08 07:03:56 AM EDT | pass 2043-2047 2026-07-08 07:06 AM EDT include stitch metadata test in full health
- `5f88d9bd` | 2026-07-08 07:02:47 AM EDT | pass 2025-2040 2026-07-08 07:05 AM EDT add manual overlap stitch size-cap health
- `ff805f7f` | 2026-07-08 06:55:04 AM EDT | pass 1988-2024 2026-07-08 07:28 AM EDT cover ragged phone-window stitching
- `775427da` | 2026-07-08 06:49:51 AM EDT | pass 1977-1987 2026-07-08 06:52 AM EDT add ugly phone-window stitch regression
- `c24aed37` | 2026-07-08 06:44:25 AM EDT | pass 1967-1971 2026-07-08 06:44 AM EDT include candidate metadata in stitch handoff health
- `973bccf2` | 2026-07-08 06:41:28 AM EDT | pass 1962-1966 2026-07-08 06:41 AM EDT cover stitched candidate handoff metadata
- `6ee113df` | 2026-07-08 06:37:12 AM EDT | pass 1952-1955 2026-07-08 06:37 AM EDT expose oversized stitch candidate metadata
- `23197b0c` | 2026-07-08 06:36:06 AM EDT | pass 1949-1951 2026-07-08 06:36 AM EDT include eleven-section preflight in stitch health
- `34dda2ab` | 2026-07-08 06:31:57 AM EDT | pass 1941-1944 2026-07-08 06:31 AM EDT guard stitch test file sizes
- `973130e3` | 2026-07-08 06:30:29 AM EDT | pass 1938-1939 2026-07-08 06:31 AM EDT refactor stitch health script modes
- `cb7910da` | 2026-07-08 06:29:56 AM EDT | pass 1934-1937 2026-07-08 06:29 AM EDT wire phone-window safety into camera qa gates
- `2b8ef478` | 2026-07-08 06:28:43 AM EDT | pass 1928-1933 2026-07-08 06:28 AM EDT modularize phone-window stitch safety
- `69ca8c5d` | 2026-07-08 06:24:51 AM EDT | pass 1923-1924 2026-07-08 06:23 AM EDT wire skipped phone-window health check
- `aa9f05ef` | 2026-07-08 06:19:34 AM EDT | pass 1907-1915 2026-07-08 06:19 AM EDT add phone-window stitch health mode
- `b352b76b` | 2026-07-08 06:12:23 AM EDT | pass 1862-1896 2026-07-08 06:16 AM EDT harden stitch qa and long stack
- `de3d2fad` | 2026-07-08 06:03:30 AM EDT | pass 1831-1859 2026-07-08 06:27 AM EDT harden horizontal stitch drift
- `60786657` | 2026-07-08 05:51:41 AM EDT | pass 1821-1827 2026-07-08 05:54 AM EDT harden stitch qa routing
- `e8cab4c9` | 2026-07-08 05:41:30 AM EDT | pass 1857 2026-07-08 06:19 AM EDT cover stitch health script
- `f74acd65` | 2026-07-08 05:39:11 AM EDT | pass 1809-1812 2026-07-08 05:48 AM EDT harden low confidence stack handoff
- `48eacae2` | 2026-07-08 05:28:24 AM EDT | pass 1824 2026-07-08 05:29 AM EDT tune long stitch search
- `39d79db0` | 2026-07-08 05:16:50 AM EDT | pass 1760-1777 2026-07-08 05:16 AM EDT harden oversized stitch handoff
- `fab2c2be` | 2026-07-08 04:58:02 AM EDT | pass 1735-1759 2026-07-08 04:58 AM EDT harden long stitch duplicate safety
- `01177acf` | 2026-07-08 04:39:35 AM EDT | pass 1733-1734 2026-07-08 04:47 AM EDT record bounded stitch preflight regression
- `caf536d8` | 2026-07-08 04:39:19 AM EDT | pass 1729-1732 2026-07-08 04:46 AM EDT guard bounded stitch preflight
- `d2f3e4b4` | 2026-07-08 04:35:13 AM EDT | pass 1683-1720 2026-07-08 04:39 AM EDT harden long stitch preflight
- `6ba91266` | 2026-07-08 04:19:27 AM EDT | pass 1678-1682 2026-07-08 04:24 AM EDT cover cropped stitch continuation
- `3e88c2da` | 2026-07-08 04:18:29 AM EDT | pass 1641-1677 2026-07-08 04:20 AM EDT align long stitch cap regressions
- `e1064589` | 2026-07-08 04:02:59 AM EDT | pass 1629-1640 2026-07-08 06:25 AM EDT optimize long stack stitch fallback
- `47f77013` | 2026-07-08 03:59:30 AM EDT | pass 1573-1628 2026-07-08 06:13 AM EDT harden stitch qa gates
- `1a09f564` | 2026-07-08 03:40:32 AM EDT | pass 1557-1572 2026-07-08 05:15 AM EDT harden stitch fallback handoff
- `3f44a0ee` | 2026-07-08 03:34:55 AM EDT | pass 1527-1556 2026-07-08 04:42 AM EDT harden long receipt stitching drift
- `fee19339` | 2026-07-08 03:07:43 AM EDT | pass 1518-1526 2026-07-08 03:47 AM EDT harden stitch contract gate
- `b13df361` | 2026-07-08 02:48:47 AM EDT | pass 1494-1514 2026-07-08 03:09 EDT harden receipt stitch edge cases and quiet QA summary
- `e2e84160` | 2026-07-08 02:00:16 AM EDT | pass 1493 2026-07-08 02:00 EDT add cheap delayed stitch health gate
- `4fbf96c7` | 2026-07-08 01:55:15 AM EDT | pass 1492 2026-07-08 01:55 EDT commit faded receipt stitch helper
- `5d0ffb18` | 2026-07-08 01:52:32 AM EDT | pass 1491 2026-07-08 01:52 EDT harden delayed receipt overlap confidence
- `41ed8254` | 2026-07-08 01:46:14 AM EDT | pass 1489 2026-07-08 01:46 EDT regress delayed overlap stitch height
- `7433967d` | 2026-07-08 01:43:52 AM EDT | pass 1488 2026-07-08 01:43 EDT harden delayed receipt overlap stitching
- `119c1bb4` | 2026-07-08 01:38:09 AM EDT | pass 1487 2026-07-08 EDT broaden long receipt contract health
- `63c5fb73` | 2026-07-08 01:34:12 AM EDT | pass 1485 2026-07-08 EDT constrain receipt ghost overlap slice
- `e7b6b326` | 2026-07-08 01:32:17 AM EDT | pass 1484 2026-07-08 EDT add receipt stitch contract health script
- `e06c4028` | 2026-07-08 01:22:25 AM EDT | pass 1483 2026-07-08 EDT harden long receipt drift stitching
- `d76851fc` | 2026-07-08 12:54:26 AM EDT | pass 1399 2026-07-08 12:59 AM EDT clear stitch gate analyzer blocker
- `449da298` | 2026-07-08 12:51:05 AM EDT | pass 1463 2026-07-08 09:37 AM EDT harden long receipt duplicate stitching
- `1f85f647` | 2026-07-07 11:49:48 PM EDT | pass 1369 2026-07-08 12:15 AM EDT simplify entry card and fix scope gate
- `9a15e657` | 2026-07-07 11:47:20 PM EDT | pass 1368 2026-07-08 12:08 AM EDT lighten camera viewer chrome
- `dab64ee6` | 2026-07-07 11:44:57 PM EDT | pass 1366 2026-07-07 11:56 PM EDT quiet empty receipt entry panel
- `501ed64c` | 2026-07-07 11:43:34 PM EDT | pass 1365 2026-07-07 11:50 PM EDT roadmap phase lock reset
- `8a86f2e4` | 2026-07-07 11:21:54 PM EDT | pass 1359 2026-07-07 11:21 PM EDT phase9 snapshot audit coverage
- `aed4a620` | 2026-07-07 11:20:25 PM EDT | pass 1358 2026-07-07 11:20 PM EDT phase9 snapshot pack coverage
- `3764303c` | 2026-07-07 11:11:58 PM EDT | pass 1355 2026-07-07 11:11 PM EDT milestone gate regression closeout
- `db138b43` | 2026-07-07 11:06:03 PM EDT | pass 1354 2026-07-07 11:05 PM EDT phase9 roadmap and gate parity closeout
- `a5838837` | 2026-07-07 10:54:30 PM EDT | pass 1351 2026-07-07 10:54 PM EDT stitch handoff section-copy cleanup
- `71bfb9bd` | 2026-07-07 10:51:57 PM EDT | pass 1350 2026-07-07 10:51 PM EDT receipt long-review section numbering copy
- `1957b9b3` | 2026-07-07 10:47:09 PM EDT | pass 1349 2026-07-07 10:47 PM EDT receipt camera review handoff opening language
- `459b5421` | 2026-07-07 10:42:37 PM EDT | pass 1348 2026-07-07 10:42 PM EDT receipt camera viewer guidance stays capture-focused
- `5d314340` | 2026-07-07 10:35:39 PM EDT | pass 1347 2026-07-08 12:33 AM EDT receipt camera roadmap align and phase3 gate
- `ac824dfb` | 2026-07-07 10:30:17 PM EDT | pass 1346 2026-07-08 12:14 AM EDT receipt camera qa harness and device proof
- `d6510946` | 2026-07-07 10:12:21 PM EDT | pass 1345 2026-07-07 11:28PM EDT formalize real-device proof reporting
- `f109b1ed` | 2026-07-07 10:08:23 PM EDT | pass 1344 2026-07-07 11:11PM EDT audit device matrix gate source
- `e772e79d` | 2026-07-07 10:05:34 PM EDT | pass 1343 2026-07-07 10:05PM EDT route matrix gate through phase9 proof
- `f635df37` | 2026-07-07 10:01:55 PM EDT | pass 1341 2026-07-07 10:01PM EDT harden front-door device proof lane
- `06d03e4b` | 2026-07-07 09:52:36 PM EDT | pass 1337 2026-07-07 09:52PM EDT wire pipeline handoff status gate
- `b19c2f29` | 2026-07-07 09:49:02 PM EDT | pass 1336 2026-07-07 09:49PM EDT align active camera phase docs
- `d0036faf` | 2026-07-07 09:46:44 PM EDT | pass 1335 2026-07-07 09:46PM EDT refresh readiness validation coverage
- `704f5ffc` | 2026-07-07 09:36:46 PM EDT | pass 1331 2026-07-07 09:36PM EDT lock attachment helper parity gate
- `661cd52c` | 2026-07-07 09:32:31 PM EDT | pass 1330 2026-07-07 09:39PM EDT carry stitch focus pair through handoff
- `77f4e2ff` | 2026-07-07 09:29:24 PM EDT | pass 1328 2026-07-07 09:32PM EDT refine original proof storage outcome
- `8e62496a` | 2026-07-07 09:27:46 PM EDT | pass 1327 2026-07-07 09:29PM EDT tighten storage cleanup bookkeeping
- `2f4910dd` | 2026-07-07 09:25:08 PM EDT | pass 1326 2026-07-07 09:23PM EDT align recovery handoff parity
- `81ea9fcd` | 2026-07-07 09:21:41 PM EDT | pass 1325 2026-07-08 12:26AM EDT harden OCR source attachment parity
- `ad92c84e` | 2026-07-07 09:15:49 PM EDT | pass 1324 2026-07-07 11:52PM EDT preserve reviewed stitch fallback at final handoff
- `bb8fdd81` | 2026-07-07 08:54:05 PM EDT | pass 1312 2026-07-08 12:18AM EDT align imported receipt OCR source outcome
- `17a49916` | 2026-07-07 08:52:27 PM EDT | pass 1310 2026-07-08 12:08AM EDT track imported receipt OCR source first
- `4814db28` | 2026-07-07 08:46:12 PM EDT | pass 1306 2026-07-07 11:50PM EDT tighten remaining non-ui camera qa lane
- `2317bda0` | 2026-07-07 08:39:21 PM EDT | pass 1299 2026-07-07 11:26PM EDT add explicit uploaded receipt handoff signals
- `e075383c` | 2026-07-07 08:37:10 PM EDT | pass 1291 2026-07-07 11:14PM EDT track uploaded receipt source in handoff metadata
- `86f0bc90` | 2026-07-07 08:34:44 PM EDT | pass 1286 2026-07-07 11:06PM EDT dedupe uploaded receipt photo sets
- `1086ee7e` | 2026-07-07 08:30:54 PM EDT | pass 1280 2026-07-07 10:57PM EDT fix camera milestone gate blockers
- `f806f615` | 2026-07-07 08:18:47 PM EDT | pass 1268 2026-07-07 08:18PM EDT simplify phase4 review wording
- `fde0a7e1` | 2026-07-07 08:08:59 PM EDT | pass 1265 2026-07-07 08:08PM EDT retire storage proof choice from native pre-capture settings
- `7002ef26` | 2026-07-07 08:05:34 PM EDT | pass 1264 2026-07-07 08:05PM EDT retire experimental live-warning toggles from active camera settings
- `aebf9080` | 2026-07-07 07:35:43 PM EDT | pass 1252 2026-07-07 07:35PM EDT harden native tall-screen false positive guard
- `3808f603` | 2026-07-07 07:31:19 PM EDT | pass 1251 2026-07-07 07:31PM EDT relabel manual photo recovery review path
- `b5ba8821` | 2026-07-07 07:26:37 PM EDT | pass 1250 2026-07-07 07:26PM EDT relabel manual phase4 handoff review action
- `1441b6ac` | 2026-07-07 07:24:38 PM EDT | pass 1249 2026-07-07 07:24PM EDT clarify phase4 bottom-section recovery action
- `7e5f9948` | 2026-07-07 07:22:02 PM EDT | pass 1248 2026-07-07 07:21PM EDT gate phase4 handoff review until processing completes
- `3a1939f5` | 2026-07-07 07:17:12 PM EDT | pass 1247 2026-07-07 08:02PM EDT align android back icon with receipt viewer chrome
- `94c640ae` | 2026-07-07 07:16:04 PM EDT | pass 1246 2026-07-07 07:57PM EDT retire stale ios top-done viewer path
- `ab457b88` | 2026-07-07 07:13:51 PM EDT | pass 1245 2026-07-07 07:49PM EDT retire stale android top-done viewer path
- `53a12594` | 2026-07-07 07:12:01 PM EDT | pass 1244 2026-07-07 07:42PM EDT align android shutter icon with receipt viewer chrome
- `4838cf6a` | 2026-07-07 07:09:33 PM EDT | pass 1243 2026-07-07 07:33PM EDT require actionable add-photo diagnostics on android
- `6c933ccf` | 2026-07-07 07:08:07 PM EDT | pass 1242 2026-07-07 07:28PM EDT add roadmap anchor and explicit quality-warning guard
- `37cbad78` | 2026-07-07 07:03:00 PM EDT | pass 1239 2026-07-07 07:06PM EDT align ghost-guide visible control diagnostics
- `3b727ee1` | 2026-07-07 06:59:33 PM EDT | pass 1238 2026-07-07 06:59PM EDT align android viewer settings copy with ios
- `11779211` | 2026-07-07 06:58:00 PM EDT | pass 1237 2026-07-07 06:57PM EDT align viewer diagnostics visible controls
- `2eedcd0d` | 2026-07-07 06:56:09 PM EDT | pass 1236 2026-07-07 06:56PM EDT honor viewer settings strip on first render
- `4e11e046` | 2026-07-07 06:54:44 PM EDT | pass 1235 2026-07-07 06:54PM EDT show viewer settings strip only when meaningful
- `5598a1aa` | 2026-07-07 06:52:40 PM EDT | pass 1234 2026-07-07 06:52PM EDT collapse hidden ios viewer info space
- `50d7fe9a` | 2026-07-07 06:50:54 PM EDT | pass 1233 2026-07-07 06:50PM EDT harden live guidance stability threshold
- `0e11926a` | 2026-07-07 06:48:47 PM EDT | pass 1232 2026-07-07 06:48PM EDT align viewer diagnostics with bottom review handoff
- `2a74d4fa` | 2026-07-07 06:47:08 PM EDT | pass 1231 2026-07-07 06:47PM EDT remove duplicate top done camera control
- `37c662f1` | 2026-07-07 06:41:05 PM EDT | pass 1230 2026-07-07 06:54PM EDT harden native guidance target gate
- `05f8f2b2` | 2026-07-07 06:26:30 PM EDT | pass 1229 2026-07-07 06:26PM EDT add ios native-asset receipt-camera preflight
- `7c6029e1` | 2026-07-07 04:39:07 PM EDT | pass 1223 2026-07-07 05:26PM EDT clear milestone QA split blockers
- `2bdd7536` | 2026-07-07 04:17:53 PM EDT | pass 1220 2026-07-07 04:28PM EDT add phase9 milestone validation QA gate
- `4f0c20b6` | 2026-07-07 04:15:19 PM EDT | pass 1219 2026-07-07 04:20PM EDT add phase8 storage proof QA gate
- `2433f9fc` | 2026-07-07 04:11:02 PM EDT | pass 1218 2026-07-07 04:10PM EDT add phase7 ocr source QA gate
- `528a396e` | 2026-07-07 04:05:59 PM EDT | pass 1217 2026-07-07 04:05PM EDT add phase6 stitching handoff QA gate
- `2084a68f` | 2026-07-07 04:01:42 PM EDT | pass 1216 2026-07-07 04:01PM EDT add phase5 long receipt QA gate
- `cb528ed5` | 2026-07-07 03:57:36 PM EDT | pass 1215 2026-07-07 03:57PM EDT add phase4 review QA gate
- `2e595efc` | 2026-07-07 03:53:06 PM EDT | pass 1214 2026-07-07 03:53PM EDT add phase3 camera viewer QA gate
- `6e383284` | 2026-07-07 03:48:43 PM EDT | pass 1212 2026-07-07 03:48PM EDT add phase2 receipt entry QA gate
- `6c5cff29` | 2026-07-07 03:39:46 PM EDT | pass 1210 2026-07-07 07:11PM EDT clamp review shell selected photo
- `51c3a58a` | 2026-07-07 03:35:50 PM EDT | pass 1209 2026-07-07 07:02PM EDT clamp preview tray selected index
- `abe373ae` | 2026-07-07 03:33:23 PM EDT | pass 1208 2026-07-07 06:54PM EDT gate review remove action to multi-photo
- `6d74f1e5` | 2026-07-07 03:31:37 PM EDT | pass 1207 2026-07-07 06:46PM EDT clamp review action photo index
- `ef31a238` | 2026-07-07 03:28:55 PM EDT | pass 1205 2026-07-07 06:33PM EDT guard review processing on captured photos
- `dd214759` | 2026-07-07 03:27:16 PM EDT | pass 1204 2026-07-07 06:24PM EDT harden phase 4 compact review photo numbering
- `974bff54` | 2026-07-07 03:16:17 PM EDT | pass 1201 2026-07-07 04:48PM EDT gate proof storage settings after capture
- `00345d9a` | 2026-07-07 02:42:03 PM EDT | pass 1195 2026-07-07 02:41PM EDT scope receipt assist first-use choice by receipt area
- `3902894c` | 2026-07-07 02:33:27 PM EDT | pass 1194 2026-07-07 02:33PM EDT guard stitch review setters behind active review controls
- `bf648d41` | 2026-07-07 02:32:25 PM EDT | pass 1193 2026-07-07 02:32PM EDT block leaving receipt review while camera handoff is opening
- `547fa2a9` | 2026-07-07 02:31:35 PM EDT | pass 1192 2026-07-07 02:31PM EDT keep receipt review progress visible during active handoff work
- `02219b85` | 2026-07-07 02:30:39 PM EDT | pass 1191 2026-07-07 02:30PM EDT lock saved proof selection during active receipt review work
- `dbce23eb` | 2026-07-07 02:29:36 PM EDT | pass 1190 2026-07-07 02:29PM EDT lock stitch controls during active receipt review work
- `fdc761e0` | 2026-07-07 02:28:48 PM EDT | pass 1189 2026-07-07 02:28PM EDT lock order and remove actions during active receipt review work
- `cc1c828a` | 2026-07-07 02:27:17 PM EDT | pass 1188 2026-07-07 02:27PM EDT lock review mode strip during active receipt handoff work
- `4746d459` | 2026-07-07 02:26:14 PM EDT | pass 1187 2026-07-07 02:26PM EDT lock post-photo review controls during receipt handoff
- `ff99e561` | 2026-07-07 02:19:13 PM EDT | pass 1186 2026-07-07 02:19PM EDT keep camera guidance above next-step controls on compact phones
- `6a75b5ca` | 2026-07-07 02:17:42 PM EDT | pass 1185 2026-07-07 02:17PM EDT show real camera guidance message when status is absent
- `10d2c1e2` | 2026-07-07 02:15:47 PM EDT | pass 1184 2026-07-07 02:15PM EDT route Paste/Text through paste-or-text-file chooser
- `c5d46089` | 2026-07-07 02:11:58 PM EDT | pass 1183 2026-07-07 02:10PM EDT align top-level OCR handoff policy with actual source decision
- `748351e1` | 2026-07-07 02:10:28 PM EDT | pass 1182 2026-07-07 02:10PM EDT surface OCR source relationship in frozen handoff metadata
- `13416cd3` | 2026-07-07 02:06:41 PM EDT | pass 1181 2026-07-07 02:06pm EDT classify stitched OCR source separately from generic clear-source handoff
- `f7092d6b` | 2026-07-07 02:03:43 PM EDT | pass 1180 2026-07-07 02:03pm EDT clarify ordered-section versus combined-image OCR handoff labels
- `cdf176af` | 2026-07-07 02:01:21 PM EDT | pass 1179 2026-07-07 02:01pm EDT align accepted receipt review handoff wording with Done action
- `c6c8323d` | 2026-07-07 01:58:00 PM EDT | pass 1178 2026-07-07 01:58pm EDT align receipt capture recovery diagnostics with Done handoff wording
- `f279a844` | 2026-07-07 01:54:28 PM EDT | pass 1177 2026-07-07 06:49pm EDT rename capture review handoff action from Next to Done across native camera viewer
- `607ad78b` | 2026-07-07 01:48:40 PM EDT | pass 1176 2026-07-07 06:25pm EDT clarify multi-section retake labels in receipt review
- `5791c3ec` | 2026-07-07 01:41:42 PM EDT | pass 1173 2026-07-07 01:41pm EDT catch repeated receipt sections anywhere in stitch order before OCR handoff
- `877d5025` | 2026-07-07 01:20:36 PM EDT | pass 1167 2026-07-07 01:20pm EDT normalize receipt review handoff labels
- `4b98f85b` | 2026-07-07 01:14:47 PM EDT | pass 1166 2026-07-07 01:14pm EDT align android camera next labels with review handoff
- `4397b3f9` | 2026-07-07 12:58:06 PM EDT | pass 1161 2026-07-07 12:57pm EDT restore chooser after receipt assist back-out
- `aa39c5ea` | 2026-07-07 12:55:26 PM EDT | pass 1160 2026-07-07 12:55pm EDT split missing OCR-source handoff ids
- `6b3716a3` | 2026-07-07 12:52:28 PM EDT | pass 1159 2026-07-07 12:52pm EDT clarify blocked OCR source handoff copy
- `31040221` | 2026-07-07 12:50:01 PM EDT | pass 1158 2026-07-07 12:49pm EDT block missing OCR source handoff honestly
- `428407af` | 2026-07-07 12:46:50 PM EDT | pass 1157 2026-07-07 12:46pm EDT harden stitch preview fallback cleanup
- `016195b8` | 2026-07-07 12:34:52 PM EDT | pass 1153 2026-07-07 07:50am EDT add shell next-step capture controls
- `a257708d` | 2026-07-07 12:30:20 PM EDT | pass 1151 2026-07-07 07:36am EDT focus low-confidence stitched review pair
- `98602338` | 2026-07-07 12:24:43 PM EDT | pass 1150 2026-07-07 12:24pm EDT keep next-section ghost handoff
- `3a6bdb71` | 2026-07-07 12:22:17 PM EDT | pass 1149 2026-07-07 12:22pm EDT preserve top-retake ghost defaults
- `51dde224` | 2026-07-07 12:18:39 PM EDT | pass 1148 2026-07-07 12:18pm EDT preserve backup retake context
- `4b9e9979` | 2026-07-07 12:14:33 PM EDT | pass 1147 2026-07-07 12:14pm EDT keep review preview after photo-set changes
- `cfbbb3db` | 2026-07-07 12:13:26 PM EDT | pass 1146 2026-07-07 12:13pm EDT lock review menu during camera open
- `45d7bf17` | 2026-07-07 12:12:03 PM EDT | pass 1145 2026-07-07 12:11pm EDT disable review menu while saving
- `14c46520` | 2026-07-07 12:11:00 PM EDT | pass 1144 2026-07-07 12:10pm EDT disable review continue while saving
- `9d0d3ec4` | 2026-07-07 12:09:33 PM EDT | pass 1143 2026-07-07 12:09pm EDT open review on captured photo
- `de8c2829` | 2026-07-07 12:07:13 PM EDT | pass 1142 2026-07-07 12:07pm EDT add review quick gate
- `5ae4d6c5` | 2026-07-07 11:50:57 AM EDT | pass 1133 2026-07-07 11:50pm EDT add chooser quick gate
- `0dbf7637` | 2026-07-07 11:42:17 AM EDT | pass 1130 2026-07-07 11:41am EDT harden duplicate stitch sections
- `864d24ec` | 2026-07-07 11:11:55 AM EDT | pass 1128 2026-07-07 11:11am EDT protect receipt assist entry
- `13991e7d` | 2026-07-07 10:58:52 AM EDT | pass 1127 2026-07-07 10:57am EDT promote guidance QA
- `b57d2bb9` | 2026-07-07 10:53:58 AM EDT | pass 1125 2026-07-07 09:28am EDT align warning QA gate
- `19618401` | 2026-07-07 10:49:40 AM EDT | pass 1124 2026-07-07 09:24am EDT guard advisory photo warnings
- `f8ddd6d2` | 2026-07-07 10:39:34 AM EDT | pass 1123 2026-07-07 09:20am EDT widen OCR source QA gate
- `94dceb5a` | 2026-07-07 10:18:13 AM EDT | pass 1120 2026-07-07 08:59am EDT guard low confidence stitches
- `657f9805` | 2026-07-07 10:00:18 AM EDT | pass 1119 2026-07-07 08:51am EDT widen stitch QA gate
- `2da95e62` | 2026-07-07 09:53:20 AM EDT | pass 1118 2026-07-07 08:44am EDT block fallback OCR assist
- `f7c930db` | 2026-07-07 09:34:15 AM EDT | pass 1117 2026-07-07 08:31am EDT harden segment order metadata
- `60625247` | 2026-07-07 09:31:47 AM EDT | pass 1116 2026-07-07 08:25am EDT harden stitch handoff readiness
- `cc8d93f2` | 2026-07-07 07:59:38 AM EDT | pass 1113 2026-07-07 07:59am EDT smoke qa execution route
- `0665415f` | 2026-07-07 07:55:38 AM EDT | pass 1112 2026-07-07 07:55am EDT route fast guard contract
- `1881a562` | 2026-07-07 07:54:36 AM EDT | pass 1111 2026-07-07 07:54am EDT smoke changed gate contract
- `e798b27b` | 2026-07-07 07:53:32 AM EDT | pass 1110 2026-07-07 07:53am EDT split changed gate contract
- `1dfaf382` | 2026-07-07 07:48:40 AM EDT | pass 1109 2026-07-07 07:48am EDT pin route gate contracts
- `dc42ec29` | 2026-07-07 07:46:39 AM EDT | pass 1108 2026-07-07 07:43am EDT route core gate edits
- `84740ff5` | 2026-07-07 07:41:20 AM EDT | pass 1107 2026-07-07 07:41am EDT add route coverage gate
- `13fefba9` | 2026-07-07 07:35:43 AM EDT | pass 1106 2026-07-07 07:35am EDT route fixture test edits
- `35af7898` | 2026-07-07 07:31:07 AM EDT | pass 1105 2026-07-07 07:30am EDT route dataset contract edits
- `674c41a5` | 2026-07-07 07:25:39 AM EDT | pass 1104 2026-07-07 07:45am EDT split dataset QA contract
- `d96f8fc7` | 2026-07-07 07:22:33 AM EDT | pass 1103 2026-07-07 07:42am EDT route dataset gate
- `efde7330` | 2026-07-07 07:17:10 AM EDT | pass 1102 2026-07-07 07:39am EDT route local dataset audit
- `ac60b763` | 2026-07-07 07:15:53 AM EDT | pass 1101 2026-07-07 07:34am EDT audit local datasets
- `321e5175` | 2026-07-07 07:09:52 AM EDT | pass 1100 2026-07-07 07:31am EDT test fixture schema gate
- `c58485c2` | 2026-07-07 07:03:47 AM EDT | pass 1099 2026-07-07 07:23am EDT separate dart schema gate
- `56fd52d3` | 2026-07-07 07:02:08 AM EDT | pass 1098 2026-07-07 07:20am EDT smoke fixture schema route
- `7443f0d0` | 2026-07-07 07:00:25 AM EDT | pass 1097 2026-07-07 07:18am EDT route fixture schema edits
- `3888d803` | 2026-07-07 06:59:07 AM EDT | pass 1096 2026-07-07 07:15am EDT wire fixture schema QA
- `c32c8c02` | 2026-07-07 06:45:39 AM EDT | pass 1095 2026-07-07 07:12am EDT harden dataset fixtures
- `0e66875d` | 2026-07-07 06:44:02 AM EDT | pass 1094 2026-07-07 07:09am EDT smoke quiet batch route
- `ca562abb` | 2026-07-07 06:33:32 AM EDT | pass 1093 2026-07-07 07:07am EDT align quiet batch scope
- `a846b344` | 2026-07-07 06:20:59 AM EDT | pass 1091 2026-07-07 06:43am EDT smoke QA harness route
- `a10d21c7` | 2026-07-07 06:19:48 AM EDT | pass 1090 2026-07-07 06:36am EDT route camera QA harness edits
- `9ae52050` | 2026-07-07 06:16:10 AM EDT | pass 1089 2026-07-07 06:28am EDT harden receipt dataset intake
- `0c6a1960` | 2026-07-07 06:13:59 AM EDT | pass 1087 2026-07-07 06:18am EDT quiet camera QA summaries
- `98993f69` | 2026-07-07 06:12:20 AM EDT | pass 1086 2026-07-07 06:12am EDT pin stitch QA ownership
- `1ae37ea8` | 2026-07-07 06:08:17 AM EDT | pass 1085 2026-07-07 06:08am EDT dedupe stitch QA gate
- `486641f3` | 2026-07-07 06:04:35 AM EDT | pass 1084 2026-07-07 05:58am EDT align stitch QA plans
- `f7a45ee2` | 2026-07-07 05:57:44 AM EDT | pass 1083 2026-07-07 05:57am EDT cover retake order in camera QA
- `87ca5e75` | 2026-07-07 05:55:54 AM EDT | pass 1082 2026-07-07 05:55am EDT camera QA full coverage
- `d8c9c87f` | 2026-07-07 05:31:13 AM EDT | pass 1081 2026-07-07 05:30am edt run device snapshot contract
- `b6e9daea` | 2026-07-07 05:27:00 AM EDT | pass 1080 2026-07-07 05:26am edt run uploaded order in camera qa
- `b5a8b1c5` | 2026-07-07 05:21:30 AM EDT | pass 1079 2026-07-07 05:21am edt add dataset test to camera qa
- `52c5e392` | 2026-07-07 05:10:52 AM EDT | pass 1078 2026-07-07 05:10am edt wire dataset gate into camera qa
- `d43d22c7` | 2026-07-07 05:09:20 AM EDT | pass 1077 2026-07-07 05:09am edt freeze stitch handoff lists
- `b64eaab1` | 2026-07-07 05:02:22 AM EDT | pass 1076 2026-07-07 05:02am edt keep auto stitch for zero overlap
- `4fcf0f0e` | 2026-07-07 04:57:26 AM EDT | pass 1075 2026-07-07 04:57am edt report stale camera qa
- `7f6ae821` | 2026-07-07 04:55:52 AM EDT | pass 1074 2026-07-07 04:53am edt guard receipt datasets
- `45f1cbda` | 2026-07-07 04:48:34 AM EDT | pass 1069-1072 2026-07-07 04:48am edt harden camera qa ordering
- `e26a9327` | 2026-07-07 03:57:14 AM EDT | pass 1067 2026-07-07 03:47am edt execute camera qa summaries
- `9070ec46` | 2026-07-07 03:54:50 AM EDT | pass 1066 2026-07-07 03:44am edt archive receipt bug ledger
- `864341d1` | 2026-07-07 03:42:58 AM EDT | pass 1065 2026-07-07 03:43am edt guard camera qa plan paths
- `aa9a02e3` | 2026-07-07 03:40:35 AM EDT | pass 1064 2026-07-07 03:19am edt clear fast receipt guard
- `e0e37ce1` | 2026-07-07 03:18:30 AM EDT | pass 1063 2026-07-07 03:14am edt split camera qa execution tests
- `129aec92` | 2026-07-07 03:13:09 AM EDT | pass 1062 2026-07-07 03:07am edt correct stitch qa plan
- `109eb6cd` | 2026-07-07 03:06:55 AM EDT | pass 1061 2026-07-07 02:53am edt execute camera failure regression
- `a8adc2dd` | 2026-07-07 02:51:45 AM EDT | pass 1060 2026-07-07 02:47am edt smoke camera qa automation
- `39a1750f` | 2026-07-07 02:46:34 AM EDT | pass 1059 2026-07-07 02:41am edt executable camera qa plans
- `85c6a36b` | 2026-07-07 02:40:01 AM EDT | pass 1058 2026-07-07 02:39am edt executable changed gate routing
- `377e0347` | 2026-07-07 02:26:52 AM EDT | pass 1057 2026-07-07 02:29am edt guard detached qa mode
- `a79c6bd6` | 2026-07-07 02:25:05 AM EDT | pass 1056 2026-07-07 02:26am edt route stitch gate edits
- `9f3e943c` | 2026-07-07 02:23:02 AM EDT | pass 1055 2026-07-07 02:24am edt camera regression scope guard
- `87085984` | 2026-07-07 02:21:52 AM EDT | pass 1054 2026-07-07 02:22am edt full camera qa device snapshot
- `95f4b7ec` | 2026-07-07 02:19:22 AM EDT | pass 1053 2026-07-07 02:18am edt classify stitch qa regressions
- `13fffbbc` | 2026-07-07 02:14:15 AM EDT | pass 1052 2026-07-07 02:15am edt stitch failure regression routing
- `5339e46b` | 2026-07-07 02:12:19 AM EDT | pass 1051 2026-07-07 02:06am edt widen stitch qa coverage
- `42ae09f2` | 2026-07-07 02:01:28 AM EDT | pass 1050 2026-07-07 02:02am edt focused camera qa modes
- `0e2ec874` | 2026-07-07 01:57:39 AM EDT | pass 1049 2026-07-07 stitch fallback review contracts
- `08eb4493` | 2026-07-07 01:43:52 AM EDT | pass 1048 2026-07-07 01:43am edt unreadable stitch contract
- `22b65c23` | 2026-07-07 01:36:12 AM EDT | pass 1047 2026-07-07 01:36am edt duplicate stitch contract
- `2eaa14fa` | 2026-07-07 01:19:34 AM EDT | pass 1044 2026-07-07 01:19am edt camera qa contract guard
- `b73cf5c5` | 2026-07-07 01:13:07 AM EDT | pass 1043 2026-07-07 01:13am edt ocr source gate regression
- `340ae43b` | 2026-07-07 01:03:00 AM EDT | pass 1042 2026-07-07 01:01am edt camera device snapshot qa
- `37363fa1` | 2026-07-07 12:52:09 AM EDT | pass 1041 2026-07-07 12:49am edt camera quick ledger gate
- `03ebb354` | 2026-07-07 12:49:10 AM EDT | pass 1040 2026-07-07 12:43am edt empty stitch fallback regression
- `9ac97739` | 2026-07-07 12:36:49 AM EDT | pass 1038 2026-07-07 12:28am edt camera failure regression wrapper
- `f895ad01` | 2026-07-07 12:28:29 AM EDT | pass 1037 2026-07-07 12:24am edt camera stitch qa gate
- `431d4894` | 2026-07-07 12:24:17 AM EDT | pass 1036 2026-07-07 12:22am edt camera changed qa selector
- `736f4654` | 2026-07-07 12:16:59 AM EDT | pass 1035 2026-07-07 12:00am edt camera scope gate
- `e19f748b` | 2026-07-07 12:04:02 AM EDT | pass 1034 2026-07-06 11:47pm edt long receipt mixed manual auto stitch regression
- `46ac33fc` | 2026-07-06 11:56:43 PM EDT | pass 1033 2026-07-06 11:43pm edt camera qa failure summary helper
- `cebc33b0` | 2026-07-06 11:50:42 PM EDT | pass 1032 2026-07-06 11:41pm edt camera qa gate avoids duplicate packs
- `ed49814c` | 2026-07-06 11:08:59 PM EDT | pass 1029 2026-07-06 11:08pm edt reusable camera qa gate
- `cb102849` | 2026-07-06 10:07:23 PM EDT | pass 1028 2026-07-06 10:04pm edt camera wording scan + live quality guard coverage
- `830e3ae7` | 2026-07-06 09:59:14 PM EDT | pass 1027 2026-07-06 10:12pm edt camera stitch fallback wording cleanup
- `ef27d39b` | 2026-07-06 09:54:27 PM EDT | pass 1026 2026-07-06 10:06pm edt camera contract wording scan + targeted regression cleanup
- `bd6147bb` | 2026-07-06 09:28:09 PM EDT | pass 1025 2026-07-06 09:28pm edt camera guidance copy cleanup + receipt review wording alignment
- `26cba604` | 2026-07-06 09:24:57 PM EDT | pass 1024 2026-07-06 09:24pm edt review-flow wording cleanup + stale contract regression alignment
- `471cd164` | 2026-07-06 09:13:33 PM EDT | pass 1023 2026-07-06 04:18pm edt telemetry blocker + native camera chrome cleanup
- `cb28bdcf` | 2026-07-06 12:57:19 PM EDT | 2026-07-06 12:57 EDT pass 1021 preserve section-order review telemetry through expense handoff
- `bdd85e12` | 2026-07-06 12:46:36 PM EDT | 2026-07-06 12:46 EDT pass 1020 gate experimental live quality warnings behind future opt-in policy
- `98c5b5ef` | 2026-07-06 12:41:46 PM EDT | 2026-07-06 12:41 EDT pass 1019 add ocr handoff section order status fields
- `0c0b0e07` | 2026-07-06 12:39:55 PM EDT | 2026-07-06 12:39 EDT pass 1018 preserve failed stitch pair in ocr handoff
- `a69217cb` | 2026-07-06 12:36:56 PM EDT | 2026-07-06 12:36 EDT pass 1017 align native baseline result telemetry regressions
- `5472c041` | 2026-07-06 12:34:58 PM EDT | 2026-07-06 12:34 EDT pass 1016 align native baseline receipt guidance contract
- `73ba30d0` | 2026-07-06 12:27:29 PM EDT | 2026-07-06 12:27 EDT pass 1015 add failed stitch pair to section-order metadata
- `0706f732` | 2026-07-06 12:24:54 PM EDT | 2026-07-06 12:24 EDT pass 1014 preserve failed stitch pair in section-order review copy
- `58443054` | 2026-07-06 12:23:00 PM EDT | 2026-07-06 12:23 EDT pass 1013 add failed stitch pair label to review metadata
- `83299b75` | 2026-07-06 12:18:05 PM EDT | 2026-07-06 12:18 EDT pass 1012 rename neutral receipt guidance warnings to framing checks
- `a092e2c0` | 2026-07-06 12:07:33 PM EDT | 2026-07-06 12:07 EDT pass 1010 name failed pair in fallback recovery control
- `753a02ac` | 2026-07-06 12:02:55 PM EDT | 2026-07-06 12:02 EDT pass 1009 surface failed stitch pair in fallback review
- `25e2c406` | 2026-07-06 12:00:47 PM EDT | 2026-07-06 12:00 EDT pass 1008 preserve section-order next-step labels
- `dc416884` | 2026-07-06 11:58:42 AM EDT | 2026-07-06 11:58 EDT pass 1007 preserve section-order follow-through labels
- `fdce6243` | 2026-07-06 11:56:27 AM EDT | 2026-07-06 11:56 EDT pass 1006 prioritize retake section order outcome
- `18ae21eb` | 2026-07-06 11:54:14 AM EDT | 2026-07-06 11:54 EDT pass 1005 normalize final stitch order identity
- `931b1692` | 2026-07-06 11:51:31 AM EDT | 2026-07-06 11:51 EDT pass 1004 freeze stitch result handoff lists
- `b8afbf60` | 2026-07-06 11:49:58 AM EDT | 2026-07-06 11:49 EDT pass 1003 freeze attachment signal views
- `6524c137` | 2026-07-06 11:41:17 AM EDT | 2026-07-06 11:41 EDT pass 1002 freeze reader handoff diagnostics
- `1845b77d` | 2026-07-06 11:39:36 AM EDT | 2026-07-06 11:39 EDT pass 1001 freeze direct recovery diagnostics
- `976a2e16` | 2026-07-06 11:32:27 AM EDT | 2026-07-06 11:32 EDT pass 1000 freeze recovery record lists
- `4e65be8f` | 2026-07-06 11:27:23 AM EDT | 2026-07-06 11:27 EDT pass 999 freeze sanitized recovery diagnostics
- `d747a583` | 2026-07-06 11:25:40 AM EDT | 2026-07-06 11:25 EDT pass 998 freeze section order helper codes
- `0ce2dba9` | 2026-07-06 11:23:58 AM EDT | 2026-07-06 11:23 EDT pass 997 retire tap focus diagnostics
- `68ac9045` | 2026-07-06 11:22:26 AM EDT | 2026-07-06 11:22 EDT pass 996 complete experimental warning diagnostics
- `27d54b69` | 2026-07-06 11:19:08 AM EDT | 2026-07-06 11:19 EDT pass 995 expose guidance stability diagnostics
- `6e07d2de` | 2026-07-06 11:17:49 AM EDT | 2026-07-06 11:17 EDT pass 994 freeze native capture result
- `2b607e1e` | 2026-07-06 11:15:40 AM EDT | 2026-07-06 11:15 EDT pass 993 stabilize experimental guidance
- `09bb1619` | 2026-07-06 11:08:33 AM EDT | 2026-07-06 11:08 EDT pass 992 freeze camera flow diagnostics
- `2f8fe2c9` | 2026-07-06 01:40:30 AM EDT | 2026-07-06 01:40 EDT pass 991 freeze picked review diagnostics
- `bf1950eb` | 2026-07-06 01:38:05 AM EDT | 2026-07-06 01:38 EDT pass 990 freeze review order diagnostics
- `a5cf653b` | 2026-07-06 01:33:45 AM EDT | 2026-07-06 01:05 EDT pass 989 freeze camera evidence lists
- `cb3bbea8` | 2026-07-06 01:05:13 AM EDT | 2026-07-06 01:02 EDT pass 988 freeze picked photo handoff
- `e87d2dbb` | 2026-07-06 01:02:01 AM EDT | 2026-07-06 00:59 EDT pass 987 freeze camera result diagnostics
- `e707be05` | 2026-07-06 12:59:36 AM EDT | 2026-07-06 00:58 EDT pass 986 freeze native staging result
- `fa1f2e46` | 2026-07-06 12:57:36 AM EDT | 2026-07-06 00:50 EDT pass 985 camera review stitch immutability
- `74ec5368` | 2026-07-06 12:49:29 AM EDT | 2026-07-06 00:48 EDT pass 983 native capture id contract
- `b87b8f26` | 2026-07-06 12:47:47 AM EDT | 2026-07-06 00:46 EDT pass 982 camera edit source token
- `9929c8c7` | 2026-07-06 12:45:49 AM EDT | 2026-07-06 00:44 EDT pass 981 camera handoff source wording
- `30b079fc` | 2026-07-06 12:44:26 AM EDT | 2026-07-06 00:44 EDT pass 980 camera diagnostics privacy guard
- `781a31fa` | 2026-07-06 12:42:42 AM EDT | 2026-07-06 00:42 EDT pass 979 camera stitch numeric guard
- `3e225847` | 2026-07-06 12:40:57 AM EDT | 2026-07-06 00:40 EDT pass 978 camera neutral guidance docs
- `cba735fc` | 2026-07-06 12:37:53 AM EDT | 2026-07-06 00:37 EDT camera stitched OCR temp cleanup
- `e00968ad` | 2026-07-06 12:36:13 AM EDT | 2026-07-06 00:36 EDT camera neutral default motion diagnostics
- `059a8b44` | 2026-07-06 12:33:31 AM EDT | 2026-07-06 00:33 EDT camera recovery receipt assist preservation
- `13c0cd75` | 2026-07-06 12:31:45 AM EDT | 2026-07-06 00:31 EDT camera receipt assist review propagation
- `5118e91b` | 2026-07-06 12:28:16 AM EDT | 2026-07-06 00:28 EDT camera OCR source sanitized path guard
- `54408d83` | 2026-07-06 12:22:31 AM EDT | 2026-07-06 02:39 EDT camera receipt assist read boundary
- `bfc1e475` | 2026-07-06 12:19:56 AM EDT | 2026-07-06 02:31 EDT camera receipt assist opt-in contract
- `ec5d57e9` | 2026-07-06 12:14:42 AM EDT | 2026-07-06 02:12 EDT camera diagnostics finite scores
- `5bf5241b` | 2026-07-06 12:13:27 AM EDT | 2026-07-06 02:03 EDT camera iOS diagnostics duplicate keys
- `54b75633` | 2026-07-06 12:12:09 AM EDT | 2026-07-06 01:54 EDT camera kept-for-later OCR suppression
- `28db12dc` | 2026-07-06 12:09:30 AM EDT | 2026-07-06 01:43 EDT camera OCR source count contract
- `489029d1` | 2026-07-06 12:06:46 AM EDT | 2026-07-06 01:23 EDT camera neutral default guidance contract
- `81f2573a` | 2026-07-06 12:05:07 AM EDT | 2026-07-06 01:15 EDT camera guidance warning gate parity
- `074afcc6` | 2026-07-06 12:01:03 AM EDT | 2026-07-06 00:52 EDT camera OCR source signal truth
- `171b567a` | 2026-07-05 11:57:15 PM EDT | 2026-07-06 00:22 EDT camera attachment OCR source signal guard
- `f539f194` | 2026-07-05 11:56:24 PM EDT | 2026-07-06 00:15 EDT camera scanner prep review route
- `217231d0` | 2026-07-05 11:55:11 PM EDT | 2026-07-06 00:10 EDT camera block unsafe OCR handoff routes
- `e10a9644` | 2026-07-05 11:50:39 PM EDT | 2026-07-05 23:50 EDT camera ledger source status docs
- `ad116699` | 2026-07-05 11:48:43 PM EDT | 2026-07-05 23:48 EDT camera bug ledger regression entries
- `ceefc7c3` | 2026-07-05 11:47:39 PM EDT | 2026-07-05 23:47 EDT camera stitch risk source status
- `922f95c3` | 2026-07-05 11:45:48 PM EDT | 2026-07-05 23:45 EDT camera stitch mismatch handoff signals
- `c5783f7c` | 2026-07-05 11:43:01 PM EDT | 2026-07-05 23:42 EDT camera quality guidance diagnostics
- `8ad43ce3` | 2026-07-05 11:38:35 PM EDT | 2026-07-05 23:38 EDT camera OCR source contract consistency
- `cdc65bdc` | 2026-07-05 11:36:56 PM EDT | 2026-07-05 23:36 EDT camera pre OCR stitch review risk
- `31ffee5c` | 2026-07-05 11:34:34 PM EDT | 2026-07-05 23:34 EDT camera stitch contract review gate
- `1592b063` | 2026-07-05 11:32:02 PM EDT | 2026-07-05 23:31 EDT camera stitch handoff risk signals
- `f464e6fd` | 2026-07-05 11:30:27 PM EDT | 2026-07-05 23:30 EDT camera diagnostics warning state recovery
- `017db8c7` | 2026-07-05 11:27:39 PM EDT | 2026-07-05 23:27 EDT camera conservative contract names
- `fdbfb777` | 2026-07-05 11:18:19 PM EDT | 2026-07-05 23:20 EDT camera OCR review risk handoff
- `d7885ecd` | 2026-07-05 11:14:48 PM EDT | 2026-07-05 23:16 EDT camera partial recovery review contract
- `90dbdb94` | 2026-07-05 11:12:30 PM EDT | 2026-07-05 23:12 EDT camera OCR fallback review contract
- `d8406de0` | 2026-07-05 11:08:23 PM EDT | 2026-07-05 23:08 EDT camera diagnostics privacy hardening
- `c5264b74` | 2026-07-05 11:06:39 PM EDT | 2026-07-05 23:06 EDT camera stitch contract hardening
- `833c1b83` | 2026-07-05 11:03:53 PM EDT | 2026-07-05 23:03 EDT camera review order hardening
- `f3f33145` | 2026-07-05 10:58:25 PM EDT | 2026-07-05 22:58 EDT camera neutral guidance hardening
- `0c533169` | 2026-07-05 08:43:25 PM EDT | 2026-07-05 20:43 EDT camera UI receipt assist milestone
- `9f554a8c` | 2026-07-05 07:31:18 PM EDT | Pass 925 2026-07-05 19:31 EDT - restore add receipt chooser layout
- `125c2518` | 2026-07-05 07:24:45 PM EDT | Pass 924 2026-07-05 19:24 EDT - harden compact receipt camera shell
- `99d1208a` | 2026-07-05 06:09:06 PM EDT | Pass 923 2026-07-05 18:09 EDT - restore receipt camera shell labels
- `87b9a663` | 2026-07-05 06:02:54 PM EDT | Pass 922 2026-07-05 18:02 EDT - clarify receipt review actions
- `1cb1deaf` | 2026-07-05 03:44:36 PM EDT | Pass 921 2026-07-05 15:44 EDT - make receipt import chooser full screen
- `1a874261` | 2026-07-05 03:28:46 PM EDT | Pass 920 2026-07-05 15:25 EDT - fix receipt camera setup UI
- `39d5bfc7` | 2026-07-05 02:52:57 PM EDT | Pass 919 2026-07-05 14:52 EDT - harden receipt stitch fallback reasons
- `6c7689eb` | 2026-07-05 01:25:41 PM EDT | Pass 918 2026-07-05 13:25 EDT - lock receipt camera control priority
- `cf6f56a6` | 2026-07-05 12:50:02 PM EDT | Pass 916 2026-07-05 12:49 EDT - clarify capture upload receipt entry
- `0a6ba496` | 2026-07-05 12:43:41 PM EDT | Pass 915 2026-07-05 12:43 EDT - lock camera native baseline
- `0cd9a7f5` | 2026-07-05 12:24:50 PM EDT | Pass 914 2026-07-05 12:24 EDT - add camera fixture matrix
- `9293fe24` | 2026-07-05 12:06:17 PM EDT | Pass 912 2026-07-05 09:58 EDT - clarify stitch OCR handoff safety
- `ce12ec9c` | 2026-07-05 12:02:33 PM EDT | Pass 911 2026-07-05 09:45 EDT - align retake guide sheet wording
- `662695b5` | 2026-07-05 11:58:09 AM EDT | Pass 909 2026-07-05 09:29 EDT - preserve retake guide diagnostics
- `c40a8050` | 2026-07-05 11:51:53 AM EDT | Pass 908 2026-07-05 09:22 EDT - harden long receipt retake guide
- `efd6e947` | 2026-07-05 08:07:56 AM EDT | Pass 903 2026-07-05 08:07 EDT - ban preview tap focus
- `105defb0` | 2026-07-05 07:40:14 AM EDT | Pass 901 2026-07-05 07:40 EDT - force continuous camera focus policy
- `094c7405` | 2026-07-05 07:36:26 AM EDT | Pass 900 2026-07-05 07:36 EDT - harden camera diagnostic device privacy
- `30151d45` | 2026-07-05 07:25:23 AM EDT | Pass 899 2026-07-05 07:23 EDT - sanitize native camera diagnostics
- `b9894257` | 2026-07-05 07:20:58 AM EDT | Pass 898 2026-07-05 07:20 EDT - align receipt source retention policy
- `eff29c00` | 2026-07-05 06:58:09 AM EDT | Pass 897 2026-07-05 06:58 EDT - sanitize camera diagnostic payloads
- `f1b80599` | 2026-07-05 06:55:33 AM EDT | Pass 896 2026-07-05 06:55 EDT - add real-device camera privacy checks
- `a209b4e8` | 2026-07-05 06:33:36 AM EDT | Pass 895 2026-07-05 06:33 EDT - test camera diagnostics publish policy
- `83a4e105` | 2026-07-05 06:25:10 AM EDT | Pass 894 2026-07-05 06:24 EDT - gate camera diagnostics opt-in
- `c9014bb2` | 2026-07-05 06:07:19 AM EDT | Pass 893 2026-07-05 06:05 EDT - add camera diagnostics opt-in
- `3d4f993f` | 2026-07-05 05:54:34 AM EDT | Pass 892 2026-07-05 05:54 EDT - enforce machine-only camera diagnostics
- `7f7c832d` | 2026-07-05 05:50:44 AM EDT | Pass 891 2026-07-05 05:50 EDT - expose camera readiness admin telemetry
- `fc6b3e25` | 2026-07-04 05:16:11 PM EDT | Pass 889 2026-07-04 17:16 EDT - gate real-device camera matrix
- `dbf17ba0` | 2026-07-04 05:04:45 PM EDT | Pass 888 2026-07-04 17:04 EDT - rename staged OCR source policy
- `6c9d50e9` | 2026-07-04 05:03:15 PM EDT | Pass 887 2026-07-04 17:03 EDT - pin retired native focus controls
- `7d1ee954` | 2026-07-04 05:00:31 PM EDT | Pass 886 2026-07-04 17:00 EDT - cross-check native focus status
- `a924ab31` | 2026-07-04 04:57:51 PM EDT | Pass 885 2026-07-04 16:56 EDT - require waiting auto capture evidence
- `977bf259` | 2026-07-04 04:54:34 PM EDT | Pass 884 2026-07-04 16:54 EDT - reject stale auto capture waiting
- `df6ebd8a` | 2026-07-04 04:52:53 PM EDT | Pass 883 2026-07-04 16:52 EDT - require auto capture stability evidence
- `96cf648a` | 2026-07-04 04:51:17 PM EDT | Pass 882 2026-07-04 16:51 EDT - require stable auto capture
- `18db32c1` | 2026-07-04 04:49:35 PM EDT | Pass 881 2026-07-04 16:49 EDT - enforce auto capture invariants
- `ee4bdfc7` | 2026-07-04 04:47:45 PM EDT | Pass 880 2026-07-04 16:47 EDT - verify focus contract tags
- `99faa06f` | 2026-07-04 04:45:00 PM EDT | Pass 879 2026-07-04 16:44 EDT - prioritize retired control outcomes
- `842dc247` | 2026-07-04 04:43:31 PM EDT | Pass 878 2026-07-04 16:43 EDT - flag active retired controls
- `e6bc56ab` | 2026-07-04 04:42:01 PM EDT | Pass 877 2026-07-04 16:41 EDT - harden retired control contracts
- `4f9482af` | 2026-07-04 04:38:44 PM EDT | Pass 876 2026-07-04 16:38 EDT - classify section order handoff
- `7d0e736a` | 2026-07-04 04:33:37 PM EDT | Pass 875 2026-07-04 16:32 EDT - expose section order handoff signals
- `f4717293` | 2026-07-04 04:31:28 PM EDT | Pass 874 2026-07-04 16:36 EDT - reject incomplete section metadata
- `5203ca07` | 2026-07-04 04:30:04 PM EDT | Pass 873 2026-07-04 16:31 EDT - gate invalid section order handoff
- `aa997ef8` | 2026-07-04 04:27:50 PM EDT | Pass 872 2026-07-04 16:26 EDT - harden section order diagnostics
- `a58ecc11` | 2026-07-04 04:12:52 PM EDT | Pass 871 2026-07-04 16:12 EDT - prevent top retake ghost mismatch
- `a8d9a04e` | 2026-07-04 04:10:41 PM EDT | Pass 870 2026-07-04 16:10 EDT - forward retake alignment context
- `c39719bf` | 2026-07-04 04:06:48 PM EDT | Pass 869 2026-07-04 16:06 EDT - flag focus status handoff risks
- `9236a9c2` | 2026-07-04 04:05:32 PM EDT | Pass 868 2026-07-04 16:04 EDT - classify native focus status health
- `399b2116` | 2026-07-04 03:48:26 PM EDT | Pass 867 2026-07-04 12:32 EDT - pin iOS focus status fallback
- `7e8cd9b3` | 2026-07-04 03:22:29 PM EDT | Pass 837 2026-07-04 11:46 EDT - pin Android autofocus diagnostics
- `dda573c2` | 2026-07-04 02:32:43 PM EDT | Pass 824 2026-07-04 14:34 EDT - carry review depth telemetry
- `ace9f9b0` | 2026-07-04 01:53:54 PM EDT | Pass 823 2026-07-04 14:00 EDT - expose review depth diagnostics
- `e377513a` | 2026-07-04 01:33:37 PM EDT | Pass 822 2026-07-04 13:18 EDT - expose review depth handoff
- `26493786` | 2026-07-04 12:28:27 PM EDT | Pass 819 2026-07-04 12:06 EDT - guard warning profile parity
- `7c3a0dbc` | 2026-07-04 12:05:46 PM EDT | Pass 818 2026-07-04 11:49 EDT - restore shadow handoff cue
- `6642e685` | 2026-07-04 11:42:45 AM EDT | Pass 817 2026-07-04 11:41 EDT - carry backup capture OCR review
- `ca938745` | 2026-07-04 11:33:51 AM EDT | Pass 816 2026-07-04 11:32 EDT - classify backup capture review risk
- `952b173a` | 2026-07-04 11:23:31 AM EDT | Pass 815 2026-07-04 12:42 EDT - add shadow saved photo review
- `c3b91a6d` | 2026-07-04 11:11:35 AM EDT | Pass 814 2026-07-04 12:34 EDT - surface dirty lens warning handoff
- `59f09fa6` | 2026-07-04 11:05:43 AM EDT | Pass 813 2026-07-04 12:27 EDT - add hazy lens handoff review
- `386f3e39` | 2026-07-04 10:51:43 AM EDT | Pass 812 2026-07-04 12:20 EDT - pin glare blur handoff risks
- `d019c639` | 2026-07-04 10:45:01 AM EDT | Pass 811 2026-07-04 12:14 EDT - summarize photo quality diagnostics
- `4b83500a` | 2026-07-04 10:41:16 AM EDT | Pass 810 2026-07-04 12:08 EDT - classify photo quality handoff risks
- `26e6cae8` | 2026-07-04 10:30:30 AM EDT | Pass 809 2026-07-04 12:01 EDT - pin low light manual review guidance
- `6b86344f` | 2026-07-04 10:20:36 AM EDT | Pass 808 2026-07-04 11:51 EDT - add low light damaged receipt fixture
- `8e26775f` | 2026-07-04 10:10:49 AM EDT | Pass 806 2026-07-04 10:16 EDT - flag focus fallback review risk
- `80733f9d` | 2026-07-04 10:07:28 AM EDT | Pass 805 2026-07-04 10:05 EDT - expose focus readability fallback
- `8968bf81` | 2026-07-04 09:58:58 AM EDT | Pass 804 2026-07-04 09:39 EDT - default manual continuation ghost guide
- `888fdcf6` | 2026-07-04 09:51:48 AM EDT | Pass 803 2026-07-04 09:31 EDT - add draft review mode contract
- `7e40eaf7` | 2026-07-04 09:50:01 AM EDT | Pass 802 2026-07-04 09:22 EDT - add draft line review anchors
- `049056ae` | 2026-07-04 09:35:09 AM EDT | Pass 801 2026-07-04 09:14 EDT - expose receipt section line anchors
- `f2e2d37f` | 2026-07-04 09:27:21 AM EDT | Pass 800 2026-07-04 09:07 EDT - rename unreadable OCR source actions
- `90e596be` | 2026-07-04 09:24:44 AM EDT | Pass 799 2026-07-04 09:03 EDT - rename scanner source guard tokens
- `9d2c67c0` | 2026-07-04 09:08:23 AM EDT | Pass 798 2026-07-04 09:00 EDT - rename OCR source guard policy
- `777d413d` | 2026-07-04 08:49:27 AM EDT | Pass 794 2026-07-04 08:46 EDT - retire tap focus staging fixture activity
- `86764823` | 2026-07-04 08:45:26 AM EDT | Pass 792 2026-07-04 08:12 EDT - finish temporary OCR outcome token
- `6579bdb2` | 2026-07-04 08:39:01 AM EDT | Pass 791 2026-07-04 08:09 EDT - rename temporary OCR handoff token
- `331e0b3d` | 2026-07-04 08:37:16 AM EDT | Pass 790 2026-07-04 08:05 EDT - update OCR storage telemetry fixture
- `1689fe48` | 2026-07-04 08:34:03 AM EDT | Pass 789 2026-07-04 08:01 EDT - rename temporary OCR source memory policy
- `e0659f86` | 2026-07-04 08:32:20 AM EDT | Pass 788 2026-07-04 07:58 EDT - clarify OCR source policy getter
- `4d0787ec` | 2026-07-04 08:23:09 AM EDT | Pass 787 2026-07-04 07:53 EDT - default native staging to balanced proof
- `0e28f721` | 2026-07-04 08:21:35 AM EDT | Pass 786 2026-07-04 07:50 EDT - clarify saved proof source size copy
- `1077b48b` | 2026-07-04 08:07:23 AM EDT | Pass 785 2026-07-04 07:43 EDT - clarify temporary OCR source docs
- `9e4cdd92` | 2026-07-04 07:56:35 AM EDT | Pass 784 2026-07-04 07:40 EDT - update Android OCR copy contract
- `baa2ff79` | 2026-07-04 07:46:27 AM EDT | Pass 783 2026-07-04 07:36 EDT - fix Android OCR source status copy
- `de7a34d3` | 2026-07-04 07:38:23 AM EDT | Pass 782 2026-07-04 07:32 EDT - align manual review quality signal
- `d7f3dbcc` | 2026-07-04 07:30:37 AM EDT | Pass 781 2026-07-04 07:27 EDT - clarify temporary OCR source copy
- `d9f463df` | 2026-07-04 07:26:04 AM EDT | Pass 780 2026-07-04 07:20 EDT - preserve OCR preparation evidence
- `7bb490ab` | 2026-07-04 07:16:59 AM EDT | Pass 779 2026-07-04 07:04 EDT - preserve OCR handoff evidence
- `65ba6ca1` | 2026-07-04 06:32:21 AM EDT | Pass 778 2026-07-04 06:29 EDT - preserve accepted review read states
- `b33057c6` | 2026-07-04 06:29:15 AM EDT | Pass 777 2026-07-04 06:24 EDT - preserve accepted review identity
- `3c07f579` | 2026-07-04 06:14:19 AM EDT | Pass 776 2026-07-04 06:10 EDT - preserve picked review diagnostics
- `71bc79bb` | 2026-07-04 06:02:05 AM EDT | Pass 774 2026-07-04 05:58 EDT - update long receipt guidance regression
- `ab3d1f8a` | 2026-07-04 05:58:01 AM EDT | Pass 773 2026-07-04 05:54 EDT - align recovery review index
- `5e4a9417` | 2026-07-04 05:54:03 AM EDT | Pass 772 2026-07-04 05:51 EDT - align picked photo review index
- `bd753c50` | 2026-07-04 05:46:15 AM EDT | Pass 771 2026-07-04 05:44 EDT - align review index offset
- `86eec8bd` | 2026-07-04 05:44:38 AM EDT | Pass 770 2026-07-04 05:41 EDT - normalize review diagnostics keys
- `776bf694` | 2026-07-04 05:41:01 AM EDT | Pass 769 2026-07-04 05:39 EDT - normalize review quality keys
- `3a6df419` | 2026-07-04 05:39:01 AM EDT | Pass 768 2026-07-04 05:35 EDT - normalize initial review photo paths
- `29aac82e` | 2026-07-04 05:34:44 AM EDT | Pass 767 2026-07-04 05:32 EDT - clamp review opening index
- `ee605c50` | 2026-07-04 05:32:47 AM EDT | Pass 766 2026-07-04 05:21 EDT - bound continuation guide diagnostics
- `7545bf4f` | 2026-07-04 05:20:49 AM EDT | Pass 765 2026-07-04 05:07 EDT - harden continuation guide flow paths
- `030cbc54` | 2026-07-04 05:07:07 AM EDT | Pass 764 2026-07-04 04:52 EDT - validate ghost guide session paths
- `b905bacb` | 2026-07-04 04:59:55 AM EDT | Pass 763 2026-07-04 04:52 EDT - require local image ghost guides
- `99d8b670` | 2026-07-04 04:52:45 AM EDT | Pass 762 2026-07-04 04:41 EDT - bound ghost crop fractions
- `310acfc0` | 2026-07-04 04:41:34 AM EDT | Pass 761 2026-07-04 04:33 EDT - require finite bottom-edge evidence
- `f3a74dc0` | 2026-07-04 04:32:49 AM EDT | Pass 760 2026-07-04 04:26 EDT - reject non-finite vertical quality
- `28403f72` | 2026-07-04 04:26:24 AM EDT | Pass 759 2026-07-04 04:16 EDT - reject non-finite saved quality buckets
- `1f4bc684` | 2026-07-04 04:16:16 AM EDT | Pass 758 2026-07-04 04:08 EDT - require finite pre-capture brightness
- `dcffc1f6` | 2026-07-04 04:08:10 AM EDT | Pass 757 2026-07-04 04:06 EDT - guard iOS exposure bias
- `8f8db6ca` | 2026-07-04 04:06:44 AM EDT | Pass 756 2026-07-04 04:05 EDT - reject invalid pinch zoom scale
- `91118ba8` | 2026-07-04 04:05:28 AM EDT | Pass 755 2026-07-04 04:04 EDT - require finite auto exposure brightness
- `5be95087` | 2026-07-04 04:04:27 AM EDT | Pass 754 2026-07-04 04:03 EDT - reject unknown live readability
- `43569e50` | 2026-07-04 04:03:03 AM EDT | Pass 753 2026-07-04 04:02 EDT - guard auto-capture framing bounds
- `eeef17ae` | 2026-07-04 04:01:57 AM EDT | Pass 752 2026-07-04 03:59 EDT - reject invalid live framing bounds
- `eea740bb` | 2026-07-04 03:59:49 AM EDT | Pass 751 2026-07-04 03:57 EDT - reject non-finite live brightness
- `d9754495` | 2026-07-04 03:57:48 AM EDT | Pass 750 2026-07-04 03:55 EDT - guard live-to-saved parity buckets
- `175bd9f6` | 2026-07-04 03:55:05 AM EDT | Pass 749 2026-07-04 03:52 EDT - guard native luma quality buckets
- `64adecee` | 2026-07-04 03:51:36 AM EDT | Pass 748 2026-07-04 03:50 EDT - harden receipt review style storage
- `dc5762c3` | 2026-07-04 03:50:18 AM EDT | Pass 747 2026-07-04 03:48 EDT - normalize native review-depth arguments
- `39380135` | 2026-07-04 03:48:37 AM EDT | Pass 746 2026-07-04 03:47 EDT - normalize native review depth
- `4b0025fc` | 2026-07-04 03:47:25 AM EDT | Pass 745 2026-07-04 03:46 EDT - normalize receipt review style
- `08222929` | 2026-07-04 03:46:02 AM EDT | Pass 744 2026-07-04 03:42 EDT - gate duplicate receipt line ids
- `8208f6fd` | 2026-07-04 03:42:51 AM EDT | Pass 743 2026-07-04 03:40 EDT - flag duplicate receipt line ids
- `105044d4` | 2026-07-04 03:40:38 AM EDT | Pass 742 2026-07-04 03:39 EDT - block sensitive text QR payloads
- `39a98e3a` | 2026-07-04 03:30:12 AM EDT | Pass 736 2026-07-04 03:28 EDT - remove retired lock fixture state
- `fede0695` | 2026-07-04 03:28:47 AM EDT | Pass 735 2026-07-04 03:27 EDT - pin white balance lock diagnostics false
- `12b207ec` | 2026-07-04 03:27:08 AM EDT | Pass 734 2026-07-04 03:25 EDT - pin native white balance lock false
- `1db51bf8` | 2026-07-04 03:25:46 AM EDT | Pass 733 2026-07-04 03:24 EDT - pin tap focus payload false
- `afa590ac` | 2026-07-04 03:24:43 AM EDT | Pass 732 2026-07-04 03:23 EDT - harden retired lock payloads
- `399e12ca` | 2026-07-04 03:23:44 AM EDT | Pass 731 2026-07-04 03:22 EDT - pin tap focus unexpected at service boundary
- `7caad9fe` | 2026-07-04 03:22:04 AM EDT | Pass 730 2026-07-04 03:17 EDT - remove retired controls from capability policy
- `c90d008e` | 2026-07-04 03:17:39 AM EDT | Pass 729 2026-07-04 03:15 EDT - remove lock tag hooks
- `b4270289` | 2026-07-04 03:15:29 AM EDT | Pass 728 2026-07-04 03:11 EDT - retire Dart lock settings
- `8b80fee6` | 2026-07-04 03:11:06 AM EDT | Pass 727 2026-07-04 03:07 EDT - retire lock expected controls
- `95309485` | 2026-07-04 03:07:04 AM EDT | Pass 726 2026-07-04 03:04 EDT - make readiness core control based
- `daa20dc8` | 2026-07-04 03:03:58 AM EDT | Pass 725 2026-07-04 03:01 EDT - ignore retired controls in readiness
- `08cdabc1` | 2026-07-04 03:01:26 AM EDT | Pass 724 2026-07-04 02:59 EDT - pin tap focus diagnostics retired
- `4003c6e5` | 2026-07-04 02:59:38 AM EDT | Pass 723 2026-07-04 02:54 EDT - retire native tap focus paths
- `dde9dc16` | 2026-07-04 02:53:51 AM EDT | Pass 722 2026-07-04 02:51 EDT - keep overbudget retakes in camera
- `41779f36` | 2026-07-04 02:50:45 AM EDT | Pass 721 2026-07-04 02:47 EDT - reject native overbudget captures
- `45b516da` | 2026-07-04 02:47:15 AM EDT | Pass 720 2026-07-04 02:45 EDT - enforce total native byte budget
- `c657ff73` | 2026-07-04 02:45:26 AM EDT | Pass 719 2026-07-04 02:43 EDT - enforce native photo byte budget
- `1cd0bf19` | 2026-07-04 02:43:13 AM EDT | Pass 718 2026-07-04 02:40 EDT - make native receipt filenames unique
- `96e0d93d` | 2026-07-04 02:40:36 AM EDT | Pass 717 2026-07-04 02:39 EDT - cap native receipt sections
- `afca54ee` | 2026-07-04 02:39:04 AM EDT | Pass 716 2026-07-04 02:37 EDT - cover nul native receipt paths
- `c1de3b15` | 2026-07-04 02:36:23 AM EDT | Pass 715 2026-07-04 02:32 EDT - split native path validation tests
- `4bb8094c` | 2026-07-04 02:32:44 AM EDT | Pass 714 2026-07-04 02:31 EDT - reject nonimage native receipt paths
- `3400bf1f` | 2026-07-04 02:30:44 AM EDT | Pass 713 2026-07-04 02:29 EDT - reject nonlocal native receipt paths
- `68ee2bc7` | 2026-07-04 02:29:11 AM EDT | Pass 712 2026-07-04 02:27 EDT - make native capture ids opaque
- `d83d79cd` | 2026-07-04 02:27:36 AM EDT | Pass 711 2026-07-04 02:25 EDT - sanitize native capture ids
- `5e83e192` | 2026-07-04 02:25:01 AM EDT | Pass 710 2026-07-04 02:23 EDT - align receipt help focus copy
- `50c3cd45` | 2026-07-04 02:22:54 AM EDT | Pass 709 2026-07-04 02:21 EDT - remove Android focus assist copy
- `087674c2` | 2026-07-04 02:21:33 AM EDT | Pass 708 2026-07-04 02:45 EDT - remove iOS focus assist copy
- `4719c73d` | 2026-07-04 02:18:06 AM EDT | Pass 707 2026-07-04 02:38 EDT - trim iOS ghost guide path
- `89ecbfcb` | 2026-07-04 02:16:26 AM EDT | Pass 706 2026-07-04 02:31 EDT - force native tap focus retired
- `e6ab2038` | 2026-07-04 02:14:49 AM EDT | Pass 705 2026-07-04 02:25 EDT - clamp draft receipt line numbers
- `da9c82c9` | 2026-07-04 02:11:26 AM EDT | Pass 703 2026-07-04 02:12 EDT - guard active focus docs
- `73d3e777` | 2026-07-04 02:08:48 AM EDT | Pass 702 2026-07-04 02:06 EDT - sanitize continuation guide inputs
- `c109e061` | 2026-07-04 02:05:09 AM EDT | Pass 701 2026-07-04 01:45 EDT - preserve continuation review depth
- `80238cd1` | 2026-07-04 02:03:35 AM EDT | Pass 700 2026-07-04 01:40 EDT - test review depth contract
- `54b02d21` | 2026-07-04 02:02:24 AM EDT | Pass 699 2026-07-04 01:34 EDT - preserve OCR line detail mode
- `0c675874` | 2026-07-04 02:00:21 AM EDT | Pass 698 2026-07-04 01:29 EDT - default module review depth
- `00a0e103` | 2026-07-04 01:58:52 AM EDT | Pass 697 2026-07-04 01:23 EDT - update handoff focus flow
- `ad67ed79` | 2026-07-04 01:57:59 AM EDT | Pass 696 2026-07-04 01:18 EDT - keep focus docs continuous
- `8c65fc44` | 2026-07-04 01:56:29 AM EDT | Pass 695 2026-07-04 01:10 EDT - roll up layout redaction telemetry
- `de08da7b` | 2026-07-04 01:52:46 AM EDT | Pass 694 2026-07-04 01:05 EDT - aggregate redaction layout telemetry
- `50887cc4` | 2026-07-04 12:57:21 AM EDT | Pass 693 2026-07-04 00:55 EDT - bridge redaction privacy events
- `e9f45144` | 2026-07-04 12:54:56 AM EDT | Pass 692 2026-07-04 00:53 EDT - summarize redaction diagnostics
- `3ff84e9c` | 2026-07-04 12:53:38 AM EDT | Pass 691 2026-07-04 00:52 EDT - ignore phantom redaction lines
- `3deb23e8` | 2026-07-04 12:52:00 AM EDT | Pass 690 2026-07-04 00:50 EDT - clamp selected line allocations
- `52448a85` | 2026-07-04 12:50:42 AM EDT | Pass 689 2026-07-04 00:48 EDT - preserve excluded receipt lines
- `6ebad8d7` | 2026-07-04 12:48:22 AM EDT | Pass 688 2026-07-04 00:46 EDT - allocate split receipt selections
- `7505ab65` | 2026-07-04 12:46:42 AM EDT | Pass 687 2026-07-04 00:45 EDT - remove focus assist guidance
- `f9e7e005` | 2026-07-04 12:45:20 AM EDT | Pass 686 2026-07-04 00:41 EDT - cap OCR receipt line numbers
- `cd916190` | 2026-07-03 11:23:19 PM EDT | 2026-07-03 23:23 EDT - Pass 2 Lane B line use hydration
- `cddd2470` | 2026-07-03 11:17:48 PM EDT | 2026-07-03 23:17 EDT - Lane B OCR source number normalization
- `44f7cbc3` | 2026-07-03 10:50:12 PM EDT | Prefer continuous focus capability evidence
- `6d77db08` | 2026-07-03 10:47:04 PM EDT | Clamp receipt stitch pair review state
- `cb057371` | 2026-07-03 10:45:14 PM EDT | Protect accepted receipt prep artifacts
- `667e5c6b` | 2026-07-03 10:41:05 PM EDT | Expand continuation handoff risks
- `bcaf6d6e` | 2026-07-03 10:39:13 PM EDT | Reject malformed manual reorder summaries
- `f352f88c` | 2026-07-03 10:37:14 PM EDT | Preserve retake context section counts
- `e75195f7` | 2026-07-03 10:31:19 PM EDT | Flag tap focus regressions as camera risks
- `718d2da2` | 2026-07-03 10:29:36 PM EDT | Harden native focus readability health
- `88f82615` | 2026-07-03 10:25:49 PM EDT | Redact client proof line references
- `d6913db4` | 2026-07-03 10:23:39 PM EDT | Redact client proof section labels
- `562406cd` | 2026-07-03 10:21:05 PM EDT | Redact photo edit handoff signals
- `43bacf87` | 2026-07-03 10:18:14 PM EDT | Redact malformed photo edit actions
- `173a7c42` | 2026-07-03 10:16:41 PM EDT | Redact invalid review depth diagnostics
- `a4570399` | 2026-07-03 10:12:39 PM EDT | Harden native ghost guide fallback
- `45a0ee73` | 2026-07-03 10:11:01 PM EDT | Harden ghost slice continuation handoff
- `21c0d0c8` | 2026-07-03 10:07:04 PM EDT | Remove tap focus shell callback hook
- `356a4e07` | 2026-07-03 10:04:33 PM EDT | Mark tap focus enabled telemetry as legacy
- `18fe1c3e` | 2026-07-03 10:02:33 PM EDT | Mark tap focus telemetry as legacy
- `17aa0a31` | 2026-07-03 10:00:40 PM EDT | Remove legacy focus assist health alias
- `2cec976d` | 2026-07-03 09:58:32 PM EDT | Report continuous focus in receipt telemetry
- `fe93c312` | 2026-07-03 09:55:51 PM EDT | Retire tap focus from native helper contracts
- `94ddab4d` | 2026-07-03 09:52:27 PM EDT | Keep receipt camera docs continuous focus first
- `1abc142a` | 2026-07-03 09:51:14 PM EDT | Remove tap focus coordinate diagnostics
- `5af5a9c0` | 2026-07-03 09:49:50 PM EDT | Harden OCR source relationship handoff
- `a586481a` | 2026-07-03 09:46:14 PM EDT | Expose stitch fallback metadata safely
- `5b312ba6` | 2026-07-03 09:43:49 PM EDT | Add retake alignment section diagnostics
- `dc0aa462` | 2026-07-03 09:41:36 PM EDT | Hold native auto capture for quality review
- `e86a65d5` | 2026-07-03 09:39:17 PM EDT | Carry manual quality review readiness
- `2dc650ac` | 2026-07-03 09:36:54 PM EDT | Gate auto capture on review quality
- `67613b84` | 2026-07-03 09:35:29 PM EDT | Keep receipt focus guidance continuous
- `c2740e75` | 2026-07-03 09:32:59 PM EDT | Harden damaged receipt QA guidance
- `f9fb5553` | 2026-07-03 09:27:04 PM EDT | Clamp receipt layout line anchors
- `d679cccd` | 2026-07-03 09:23:01 PM EDT | Normalize receipt line split allocation
- `f244cef9` | 2026-07-03 09:21:28 PM EDT | Flag dim receipt OCR handoff risk
- `e0df2dd4` | 2026-07-03 09:20:18 PM EDT | Align saved photo quality buckets
- `6c1f226e` | 2026-07-03 09:18:23 PM EDT | Retire receipt tap focus path
- `82536cce` | 2026-07-03 09:14:25 PM EDT | Normalize native ghost guide reasons
- `04d2e490` | 2026-07-03 09:12:28 PM EDT | Normalize continuation guide reasons
- `aea09be9` | 2026-07-03 09:10:19 PM EDT | Report iOS continuous focus state
- `f7ffbc05` | 2026-07-03 09:08:41 PM EDT | Request Android continuous autofocus
- `6845be37` | 2026-07-03 09:07:03 PM EDT | Honor continuous focus capability
- `1e2ca024` | 2026-07-03 09:03:49 PM EDT | Expose safe split allocation contracts
- `a35da0a0` | 2026-07-03 09:01:09 PM EDT | normalize native review depth diagnostics
- `ee1fc6b7` | 2026-07-03 08:58:53 PM EDT | distinguish failed section close recovery
- `f7b0d27d` | 2026-07-03 08:56:14 PM EDT | classify native exposure abort outcome
- `d0f97aed` | 2026-07-03 08:54:27 PM EDT | clear ios pre capture abort state
- `1ab1f2c9` | 2026-07-03 08:52:07 PM EDT | honor configured auto capture cooldown
- `395e86d4` | 2026-07-03 08:50:34 PM EDT | make continuous focus primary by default
- `6f2a02b9` | 2026-07-03 08:45:33 PM EDT | harden generated receipt artifact cleanup
- `8e9e6474` | 2026-07-03 08:43:12 PM EDT | preserve blocked auto capture diagnostics
- `3739bed2` | 2026-07-03 08:39:03 PM EDT | remove tap focus first camera copy
- `ddc8c030` | 2026-07-03 08:37:08 PM EDT | make continuous focus primary for receipts
- `3c9d6dab` | 2026-07-03 06:09:18 PM EDT | normalize camera quality diagnostic paths
- `0f8a8dae` | 2026-07-03 06:07:03 PM EDT | carry receipt review depth into camera capture
- `5d98aff5` | 2026-07-03 05:50:11 PM EDT | guard receipt reorder moves to adjacent sections
- `2b030e6c` | 2026-07-03 05:22:24 PM EDT | harden receipt manual reorder diagnostics
- `1b65eeab` | 2026-07-03 04:42:25 PM EDT | checkpoint receipt camera cleanup and ordering hardening
- `accdea48` | 2026-07-03 11:24:17 AM EDT | Bound receipt review diagnostic tokens
- `a619656f` | 2026-07-03 11:16:46 AM EDT | Align privacy-safe receipt line numbers
- `2aebf341` | 2026-07-03 10:56:21 AM EDT | Guard receipt cleanup enhancement score
- `c9779e2b` | 2026-07-03 10:45:26 AM EDT | Use normalized receipt photo membership
- `24b34346` | 2026-07-03 10:42:33 AM EDT | Share receipt photo path identity guard
- `a43fa9b3` | 2026-07-03 10:34:15 AM EDT | Reject receipt retake path aliases
- `946c9831` | 2026-07-03 10:25:21 AM EDT | Reject stringified native nonfinite diagnostics
- `5dcc00d2` | 2026-07-03 10:21:44 AM EDT | Sanitize native diagnostic lists
- `c05efbed` | 2026-07-03 10:08:46 AM EDT | Guard receipt rotation angles
- `e7a01105` | 2026-07-03 09:56:39 AM EDT | Reject unusable receipt crop bounds
- `0a74fd6c` | 2026-07-03 09:38:41 AM EDT | Guard capture evidence numeric flags
- `8b100aab` | 2026-07-03 09:34:18 AM EDT | Guard live brightness diagnostics
- `4dd741ca` | 2026-07-03 09:24:35 AM EDT | Guard native quality diagnostics
- `ecae6f5e` | 2026-07-03 09:22:13 AM EDT | Guard native session double arguments
- `84af3a47` | 2026-07-03 09:13:42 AM EDT | Guard manual stitch overlap input
- `4dafcefc` | 2026-07-03 09:00:08 AM EDT | Ignore non-finite settings open counts
- `75fd17d1` | 2026-07-03 08:43:16 AM EDT | Require finite native recovery counts
- `937efa42` | 2026-07-03 08:31:34 AM EDT | Treat non-finite photo quality as unsafe
- `fb6e9c04` | 2026-07-03 08:21:53 AM EDT | Ignore non-finite native close counts
- `56485243` | 2026-07-03 08:13:35 AM EDT | Normalize native recovery index identity
- `8b24c586` | 2026-07-03 08:08:42 AM EDT | Normalize native recovery photo paths
- `386271e1` | 2026-07-03 08:02:55 AM EDT | Trim restored document receipt kind
- `9f3c75d4` | 2026-07-03 07:54:47 AM EDT | Harden restored receipt proof media
- `ce4fb154` | 2026-07-03 07:45:34 AM EDT | Trim restored receipt duplicate state
- `266f1fd1` | 2026-07-03 07:37:49 AM EDT | Trim restored receipt line use
- `1c8397fb` | 2026-07-03 07:29:41 AM EDT | Report manual stitch usage from pairs
- `81336ef8` | 2026-07-03 07:11:42 AM EDT | Reject duplicate stitch inputs
- `3fdd6e12` | 2026-07-03 07:05:02 AM EDT | Limit retake diagnostics to accepted paths
- `b7da3cbe` | 2026-07-03 07:00:43 AM EDT | Filter recovery stage manifest diagnostics
- `f3a28fc7` | 2026-07-03 06:46:29 AM EDT | Reject duplicate native receipt paths
- `172b4b93` | 2026-07-03 06:44:20 AM EDT | Sanitize native recovery diagnostics
- `d31d95d2` | 2026-07-03 06:34:09 AM EDT | Sanitize native capture diagnostics
- `d46be251` | 2026-07-03 06:24:52 AM EDT | Trim restored receipt attachment identity
- `c98834dc` | 2026-07-03 06:10:40 AM EDT | Guard receipt attachment numeric restore
- `81d4c93c` | 2026-07-03 05:51:49 AM EDT | Normalize initial receipt attachment paths
- `478d8c5a` | 2026-07-03 05:39:35 AM EDT | Guard scanner backup quality paths
- `1f96f301` | 2026-07-03 05:37:45 AM EDT | Guard derived OCR source evidence
- `bb4d5656` | 2026-07-03 05:31:07 AM EDT | Guard picked receipt quality members
- `11932575` | 2026-07-03 05:29:06 AM EDT | Normalize receipt edit source signals
- `d3e03ea2` | 2026-07-03 05:25:31 AM EDT | Separate receipt edit source metadata
- `e18d19a3` | 2026-07-03 05:13:58 AM EDT | Trim receipt performance mode restores
- `cb137f16` | 2026-07-03 05:12:25 AM EDT | Trim native receipt camera engine restores
- `e727b20e` | 2026-07-03 05:04:00 AM EDT | Trim receipt attachment enum restore names
- `01e70ff5` | 2026-07-03 05:00:21 AM EDT | Normalize picked receipt photo paths
- `7f227a8e` | 2026-07-03 04:57:15 AM EDT | Filter receipt review result evidence paths
- `9debd719` | 2026-07-03 04:47:22 AM EDT | Deduplicate native recovery photo paths
- `68ad330b` | 2026-07-03 03:27:10 AM EDT | Reject stale camera diagnostic paths
- `71218990` | 2026-07-03 03:16:01 AM EDT | Preserve stable OCR line evidence
- `5e0551e7` | 2026-07-03 03:01:19 AM EDT | Sanitize receipt line section anchors
- `42a1b4a4` | 2026-07-03 02:57:29 AM EDT | Reject non-finite receipt line numbers
- `baf5b897` | 2026-07-03 02:51:55 AM EDT | Recommend more photos for native coverage risk
- `8bdca973` | 2026-07-03 02:49:08 AM EDT | Normalize attachment coverage risk status
- `282f4cf7` | 2026-07-03 02:42:48 AM EDT | Honor native bottom coverage in completion
- `09a48850` | 2026-07-03 02:38:59 AM EDT | Prioritize OCR source quality guard
- `a04d4523` | 2026-07-03 02:32:05 AM EDT | Guard retake diagnostics against stale paths
- `b9093f1a` | 2026-07-03 02:19:53 AM EDT | Prioritize invalid receipt retake order
- `7d67b537` | 2026-07-03 02:11:31 AM EDT | Deduplicate OCR line action lists
- `e95d23b6` | 2026-07-03 02:00:17 AM EDT | Preserve first OCR line metadata mapping
- `1b563808` | 2026-07-03 01:50:55 AM EDT | Preserve first OCR line id mapping
- `88466576` | 2026-07-03 01:44:12 AM EDT | Normalize native ghost guide reason codes
- `6117f9f5` | 2026-07-03 01:40:40 AM EDT | Recognize native bottom soft coverage status
- `11ba68b7` | 2026-07-03 01:37:21 AM EDT | Reject fractional receipt coverage counts
- `53530db5` | 2026-07-03 01:34:37 AM EDT | Normalize kept for later receipt sources
- `60a1126a` | 2026-07-03 01:29:12 AM EDT | Reject malformed camera result diagnostic paths
- `bc1b0763` | 2026-07-03 01:26:56 AM EDT | Reject ambiguous camera result path diagnostics
- `494a781a` | 2026-07-03 01:22:44 AM EDT | Update receipt review lifecycle ordering guard
- `17c7a18b` | 2026-07-03 01:21:38 AM EDT | Protect long receipt add and remove ordering
- `43628fbc` | 2026-07-03 01:19:15 AM EDT | Reject ambiguous receipt retake paths
- `23aff89e` | 2026-07-03 01:16:40 AM EDT | Protect draft receipt line labels
- `84565ee6` | 2026-07-03 01:14:46 AM EDT | Protect draft receipt line anchors
- `59edc949` | 2026-07-03 01:12:31 AM EDT | Protect manual receipt line anchors
- `1305df47` | 2026-07-03 01:08:31 AM EDT | Guard native staging edge evidence
- `539f154d` | 2026-07-03 01:06:39 AM EDT | Guard receipt coverage diagnostics
- `7b087328` | 2026-07-03 01:04:17 AM EDT | Guard native camera capability numbers
- `b5895f3f` | 2026-07-03 01:03:07 AM EDT | Guard native recovery telemetry counts
- `26a8a5b5` | 2026-07-03 01:02:02 AM EDT | Guard receipt camera diagnostic numbers
- `8f5aa2a2` | 2026-07-03 12:59:42 AM EDT | Normalize custom split percent input
- `e5a835bd` | 2026-07-03 12:57:32 AM EDT | Normalize quick split percent input
- `4295153e` | 2026-07-03 12:56:09 AM EDT | Record selected split line percent
- `8721fe13` | 2026-07-03 12:54:14 AM EDT | Preserve continuation attachment signals
- `18bace01` | 2026-07-03 12:52:39 AM EDT | Preserve backup continuation evidence
- `020a781d` | 2026-07-03 12:48:58 AM EDT | Count invalid native review depth
- `4969c9a3` | 2026-07-03 12:47:17 AM EDT | Redact receipt line privacy ids
- `cd3f4529` | 2026-07-03 12:45:19 AM EDT | Expose privacy-safe stitch source counts
- `9326dcf4` | 2026-07-03 12:43:01 AM EDT | Guard non-finite manual stitch overlap
- `0918d120` | 2026-07-03 12:40:58 AM EDT | Reject unnormalized retake replacement paths
- `37e2bd52` | 2026-07-03 12:39:28 AM EDT | Classify glare receipt source handoff
- `26e67278` | 2026-07-03 12:37:50 AM EDT | Reject non-finite receipt camera diagnostics
- `6afe02fb` | 2026-07-03 12:35:48 AM EDT | Preserve signs in receipt split input
- `fbe015b9` | 2026-07-03 12:24:13 AM EDT | Clamp receipt entry split previews
- `6f03c738` | 2026-07-03 12:22:55 AM EDT | Clamp receipt split allocation math
- `caf80ad6` | 2026-07-03 12:20:20 AM EDT | Preserve detailed receipt review depth
- `72ed4a70` | 2026-07-03 12:18:37 AM EDT | Keep subtotal in receipt redaction totals context
- `95be1328` | 2026-07-03 12:14:35 AM EDT | Share native auto capture readiness thresholds
- `dacb5516` | 2026-07-03 12:10:23 AM EDT | Require categorized receipt regression tasks
- `55ad627c` | 2026-07-03 12:08:07 AM EDT | Deduplicate receipt review source paths
- `dad1d2e2` | 2026-07-03 12:05:29 AM EDT | Bound receipt ghost guide geometry
- `0ac1661f` | 2026-07-03 12:03:13 AM EDT | Flag invalid receipt retake metadata
- `39bc1f92` | 2026-07-03 12:00:24 AM EDT | Harden receipt retake replacement ordering
- `96907728` | 2026-07-02 11:58:40 PM EDT | Assert receipt line review labels in QA fixtures
- `f51f25bc` | 2026-07-02 11:50:06 PM EDT | Add receipt bug regression ledger
- `337d98d4` | 2026-07-02 11:43:07 PM EDT | Show capture readiness in receipt review
- `8c54fa51` | 2026-07-02 10:11:02 PM EDT | Expose capture readiness result counts
- `aac7d400` | 2026-07-02 09:44:52 PM EDT | Add native capture readiness diagnostics
- `c65e96c1` | 2026-07-02 09:36:34 PM EDT | Carry capture readiness into receipt handoff counts
- `44bbf882` | 2026-07-02 09:29:21 PM EDT | Add receipt capture readiness decision
- `3c111696` | 2026-07-02 06:53:12 PM EDT | Add expense system handoff blueprint
- `d623727f` | 2026-06-28 05:29:20 PM EDT | Back up Maintainiac 5.6 work
- `b6fb9437` | 2026-06-27 05:40:45 PM EDT | Sync remaining app work
- `a16fb9a3` | 2026-06-27 05:23:45 PM EDT | Refine receipt photo review copy
- `037360f7` | 2026-06-27 05:22:53 PM EDT | Sync Maintainiac app foundation
- `b120d6b7` | 2026-06-17 11:49:09 PM EDT | Maintainiac 5.6


## Appendix G: Evidence Interpretation Rules

1. A production-file listing is inventory evidence, not proof that its behavior is correct.
2. A test-file listing is coverage evidence, not proof that the test currently passes.
3. A green focused gate proves only its selected scope.
4. A green synthetic gate does not prove physical-device accuracy.
5. Build, installation, launch, and foreground activity are lifecycle evidence, not receipt-quality evidence.
6. One real receipt cannot establish general accuracy.
7. Field accuracy requires independent receipts, supported devices, recorded outcomes, and reproducible fixtures.
8. OCR output remains advisory until the user confirms it.
9. Raw receipt images and text must not become routine telemetry.
10. Shared-worktree changes must not be mass-staged, mass-reverted, or attributed without evidence.

<!-- GENERATED_RECEIPT_INVENTORY_END -->
