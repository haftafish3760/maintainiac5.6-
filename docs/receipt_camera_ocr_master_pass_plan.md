# Receipt Camera OCR Master Pass Plan

This is the working execution plan for making Maintainiac's receipt capture, OCR, parsing, review, and expense intelligence state-of-the-art.

The plan is intentionally numbered. Every receipt-hardening pass should be reported as `Pass NN` after the state-of-art spec reset, so progress is easy to track and the work does not drift.

## Native Camera Architecture Reset

The old phone-camera production path is no longer the target. Maintainiac must
own the receipt camera UI and talk to native camera frameworks underneath:

- Android: CameraX.
- iOS: AVFoundation.
- Flutter: bridge/UI/review layer only, not the production camera engine.
- Samsung/Apple camera apps: fallback/import path only.

The active native rebuild spec is `docs/receipt_native_camera_service_spec.md`.

## Progress Rule

- Always name the current pass as `Pass NN` after this update. Existing original pass headings may still say `of 40`, `of 55`, or `of 150` until they are touched, but new progress reporting should use the 300-pass cap.
- Keep each pass shippable: format, analyze, and run focused tests before calling it done.
- Bundle related changes inside each pass, but do not mix unrelated domains.
- UI passes come first so the product flow can be judged on the S24 Ultra before deeper parser work.
- Do not push a phone build after every tiny tweak.
- For UI work, push to the S24 Ultra after a meaningful batch of roughly 3-4 UI passes, or sooner only when the user asks for device review.
- Backend/parser-only passes do not require a phone install unless the change affects visible workflow.
- Continue through receipt passes automatically until the receipt camera/OCR/parser flow is complete or a real product/blocking decision is required.
- Do not take phone screenshots, inspect the device UI, or push device builds unless the user explicitly asks for that action.

## Benchmark Responsibilities

- **Adobe Scan lane:** image enhancement, cleanup, crop, perspective, shadow reduction.
- **Microsoft Lens lane:** camera experience, fast capture, edge controls, no clutter.
- **Expensify lane:** OCR/parser intelligence for merchant, date, tax, total, lines, expense creation.
- **Scanner Pro lane:** polish, animation, consistency, premium feel.
- **Genius Scan lane:** long receipts, multi-photo capture, batch order, stitching/fallback.
- **Google Drive Scanner lane:** simplicity, no fifty-button clutter, obvious path.
- **CamScanner lane:** document scanning engine ideas, filters, batch scanning, automatic document help.
- **Maintainiac lane:** business/personal/mixed, simple/detailed modes, split tax, local-first storage, profiles, vehicles, inventory, diagnostics, privacy.

## Future Maintenance Receipt Parser Note

- Do not start maintenance-category implementation until the receipt camera,
  OCR source selection, image cleanup, stitching/fallback, and expense receipt
  parsing flow are stable.
- When the camera/OCR receipt foundation is ready, add a maintenance receipt
  parser lane that uses the same receipt capture flow to extract privacy-safe
  maintenance setup hints from oil-change and repair receipts.
- Maintenance receipt parsing should look for service type, vehicle mileage,
  service date, next due mileage/date, engine oil type, oil weight, filter
  details, transmission fluid, coolant, tire rotation, brake work, and other
  maintenance interval evidence when present on the receipt.
- If a user uploads a maintenance-related receipt from expenses, ask whether
  Maintainiac should use it to help set up or update that vehicle's maintenance
  schedule. Include a "do not show again" choice for that prompt.
- The maintenance parser must be rule/parser based first, without requiring AI,
  and must never depend on storing private receipt images or raw receipt text in
  admin-visible telemetry.

## Future Expense Vehicle/Fleet Attribution Note

- Every saved expense must be attributable to the selected active vehicle when
  the expense belongs to a vehicle cost. The active vehicle row is the user's
  current working context, and the expense flow must preserve that context when
  adding, editing, reviewing, and saving receipts.
- The expense flow must still let the user choose a different vehicle for the
  expense before saving when the active vehicle row is not the right one. The
  saved expense should record the final selected vehicle context, not merely
  whatever happened to be active when the receipt camera opened.
- Single-person mode and multi-employee/fleet mode both need vehicle-aware
  expense records so fuel, repairs, supplies, materials, insurance, and other
  costs can roll up correctly by vehicle.
- Fleet mode will also need employee/profile attribution so account owners can
  review which employee recorded an expense, which vehicle it was tied to, and
  whether permissions allowed that action, without exposing private receipt
  content in admin telemetry.
- Inventory/materials work can proceed in parallel with another model as long
  as shared receipt capture, camera, OCR source selection, and app-assisted
  receipt parsing contracts are treated as shared infrastructure and not forked
  or rewritten independently.
- The inventory/materials parser may define material-specific parsing needs,
  aliases, SKU matching, and catalog handoff fields, but it should consume the
  shared receipt result object instead of creating a separate photo capture,
  stitching, OCR, or saved-proof pipeline.

## Current Status

- **Pass 01 of 40: App-Assisted Handoff** is complete.
- **Pass 02 of 40: Camera Shell Layout** is complete.
- **Pass 03 of 40: Camera Interaction Basics** is complete.
- **Pass 04 of 40: First-Use Camera Setup** is complete.
- **Pass 05 of 40: Photo Review Default Surface** is complete.
- **Pass 06 of 40: Photo Review Tool Modes** is complete.
- **Pass 07 of 40: S24 UI Review Batch 1** is complete.
- **Pass 08 of 150: Live Guidance Copy And States** is complete.
- **Pass 09 of 150: Auto Capture Confidence** is complete.
- **Pass 10 of 150: Camera Capability Defaults** is complete.
- **Pass 11 of 150: Capture Diagnostics** is complete.
- **Pass 12 of 150: OCR Source Pipeline Audit** is complete.
- **Pass 13 of 150: Adobe-Style Enhancement Pass 1** is complete.
- **Pass 14 of 150: Adobe-Style Enhancement Pass 2** is complete.
- **Pass 15 of 150: Crop And Perspective Foundation** is complete.
- **Pass 16 of 150: Image Save-Space Preview** is complete.
- **Pass 17 of estimated 55: Long Receipt Capture Flow** is complete.
- **Pass 18 of estimated 55: Capability-Gated Edge Detection Overlay** is complete.
- **Pass 19 of estimated 55: Multi-Photo Review And Ordering** is complete.
- **Pass 20 of estimated 55: Automatic Stitching Core** is complete.
- **Pass 21 of estimated 55: Manual Stitch Adjustment** is complete.
- **Pass 22 of estimated 55: Receipt Reading Handoff After Stitch Review** is complete.
- **Pass 23 of estimated 55: Receipt Review Classification Landing** is complete.
- **Pass 24 of estimated 55: Receipt Tax And Split Allocation Review** is complete.
- **Pass 25 of estimated 55: Receipt Camera Device-Safe Limits** is complete.
- **Pass 26 of estimated 55: Receipt Photo Quality And Auto-Capture Tuning** is complete.
- **Pass 27 of estimated 55: Receipt Review Action Surface** is complete.
- **Pass 28 of estimated 55: Receipt Review Flow Routing** is complete.
- **Pass 29 of estimated 55: Long Receipt Section Guardrails** is complete.
- Next pass is **Pass 30 of estimated 55: Receipt Review Device UI Batch**.
- **Pass 30 of estimated 55: Receipt Review Device UI Batch** is deferred until the user explicitly asks for an S24 install.
- **Pass 31 of estimated 55: Separate OCR Fallback Guardrails** is complete.
- **Pass 32 of estimated 55: OCR Diagnostics Hardening** is complete.
- **Pass 33 of estimated 55: Parser Field Confidence Hardening** is complete.
- **Pass 34 of estimated 55: Parser Review Failure Reasons** is complete.
- **Pass 35 of estimated 55: Parser Review UI Guidance** is complete.
- **Pass 36 of estimated 55: Privacy-Safe Parser Health Metrics** is complete.
- **Pass 37 of estimated 55: Receipt Backup Image Pipeline Audit** is complete.
- **Pass 38 of estimated 55: Receipt Proof Storage And Backup Metadata** is complete.
- **Pass 39 of estimated 55: Receipt PDF OCR Safety Review** is complete.
- **Pass 40 of estimated 55: Receipt Import Failure Recovery** is complete.
- **Pass 41 of estimated 55: Receipt Review Classification Completion** is complete.
- **Pass 42 of estimated 55: Receipt Data Saver Preview Completion** is complete.
- **Pass 43 of estimated 55: Receipt Save Readiness Guardrails** is complete.
- **Pass 44 of estimated 55: Saved Receipt Detail And Calendar Recovery** is complete.
- **Pass 45 of estimated 55: Receipt Calendar Add/Edit/Delete Diagnostics** is complete.
- **Pass 46 of estimated 55: Receipt Export Proof Bundle Readiness** is complete.
- **Pass 47 of estimated 55: Synthetic End-To-End Receipt Regression Matrix** is complete.
- **Pass 48 of estimated 55: Receipt Stitching And OCR Handoff Stress Matrix** is complete.
- **Pass 49 of estimated 55: Receipt Camera Capability And Low-End Device Stress Review** is complete.
- **Pass 50 of estimated 55: Receipt Review Route And Classification Contract** is complete.
- **Pass 51 of estimated 55: Receipt Data Saver Preview And OCR Source Contract** is complete.
- **Pass 52 of estimated 55: Receipt Saved Proof Lifecycle And Cleanup Audit** is complete.
- **Pass 53 of estimated 55: Receipt Final Synthetic Stress And Coverage Review** is complete.
- **Pass 54 of estimated 55: Receipt Real-Device Readiness Checklist And Manual Test Script** is complete.
- **Pass 55 of estimated 55: Receipt Remaining Gaps And PDF/Invoice Bridge Decision** is complete.
- Next receipt step is controlled real-device validation using `docs/receipt_real_device_test_script.md`.
- **PDF Pass 56 of up to 200: Generated PDF Boundary Validation** is complete.
- **PDF Pass 57 of up to 200: Invoice PDF Send/Archive Lifecycle Audit** is complete.
- **PDF Pass 58 of up to 200: Incoming Invoice/Document PDF Routing** is complete.
- **PDF Pass 59 of up to 200: Generated PDF Preview And Share Failure Recovery** is complete.
- **PDF Pass 60 of up to 200: Invoice PDF Delivery Metadata And Audit Trail** is complete.
- **PDF Pass 61 of up to 200: Invoice PDF Firestore/Backup Shape Audit** is complete.
- **PDF Pass 62 of up to 200: Invoice PDF Form Action Wiring** is complete.
- **PDF Pass 63 of up to 200: Invoice PDF Preview Action Callback Seam** is complete.
- **PDF Pass 64 of up to 200: Invoice PDF Preview Surface Decision And Wiring** is complete.
- **PDF Pass 65 of up to 200: PDF Preparation Failure And Retry Audit** is complete.
- **PDF Pass 66 of up to 200: PDF Delivery Event Semantics Cleanup** is complete.
- Real-device receipt testing exposed receipt-flow blockers, so PDF work is paused until the camera/photo review path is stable again.
- **Receipt Camera Reopen Pass 89 of 150: Native Capture Boundary And Maintenance-Safe Entry Point** is complete.
- **Receipt Camera Reopen Pass 90 of 150: Review Surface Back/Next Behavior** is complete.
- **Receipt Camera Reopen Pass 91 of 150: Review Surface Control Density** is complete.
- **Receipt Camera Reopen Pass 92 of 150: Photo Quality Framing Tolerance** is complete.
- **Receipt Camera Reopen Pass 93 of 150: Attached Proof Clarity And Metadata Cleanup** is complete.
- **Receipt Camera Reopen Pass 94 of 150: Long-Receipt Photo Removal Safety** is complete.
- **Receipt Camera Reopen Pass 95 of 150: Photo Review Remove Confirmation** is complete.
- **Receipt Camera Reopen Pass 96 of 150: Edited Photo Preview Cleanup** is complete.
- **Receipt Camera Reopen Pass 97 of 150: Retake/Remove Preview Cache Cleanup** is complete.
- **Receipt Camera Reopen Pass 98 of 150: Production Native Camera Routing Guard** is complete.
- **Receipt Camera Reopen Pass 99 of 150: Newly Added Receipt Section Focus** is complete.
- **Receipt Camera Reopen Pass 100 of 150: App-Assisted Re-Read Line Replacement** is complete.
- **Receipt Camera Reopen Pass 101 of 150: Reviewed Photo Proof Read State** is complete.
- **Receipt Camera Reopen Pass 102 of 150: Stable Photo Proof IDs** is complete.
- **Receipt Camera Reopen Pass 103 of 150: Review Back Action And Next-Step Copy** is complete.
- **Receipt Camera Reopen Pass 104 of 150: Native Capture Regression Guard** is complete.
- **Receipt Camera Reopen Pass 105 of 150: Filled Review Handoff Copy** is complete.
- **Receipt Camera Reopen Pass 106 of 150: Empty Photo Review Recovery** is complete.
- **Receipt Camera Reopen Pass 107 of 150: Long Receipt Review Language Alignment** is complete.
- **Receipt Camera Reopen Pass 108 of 150: Stitch Result Review Metadata Alignment** is complete.
- **Receipt Camera Reopen Pass 109 of 150: Real-Device QA Contract Alignment** is complete.
- **Receipt Camera Reopen Pass 110 of 150: Photo Review Control Height Caps** is complete.
- **Receipt Camera Reopen Pass 111 of 150: Camera Exit Lifecycle Guard** is complete.
- **Receipt Camera Reopen Pass 112: Master Receipt System Spec Reset** is complete.
- **Receipt Camera Reopen Pass 113: Expense Receipt Review Detail Settings Contract** is complete.
- **Receipt Camera Reopen Pass 114: Native Capture And Long Receipt Overlay Decision** is complete.
- **Receipt Camera Reopen Pass 115: Camera Permission And Fallback UX** is complete.
- **Receipt Camera Reopen Pass 116: Capture Surface Edge Layout** is complete.
- **Receipt Camera Reopen Pass 117: Pinch Zoom And Tap Focus Contract** is complete.
- **Receipt Camera Reopen Pass 118: Brightness And Exposure Baseline** is complete.
- **Receipt Camera Reopen Pass 119: Manual Shutter Always Works** is complete.
- **Receipt Camera Reopen Pass 120: Live Guidance Tone And Timing** is complete.
- **Receipt Camera Reopen Pass 121: Capability-Based Camera Settings** is complete.
- **Receipt Camera Reopen Pass 122: First-Use Camera Setup** is complete.
- **Receipt Camera Reopen Pass 123: Camera UI Device Batch** is complete.
- **Receipt Camera Reopen Pass 124: Review Surface Real-Device Polish Batch** is complete.
- **Receipt Camera Reopen Pass 125: Review Surface Tool Affordance Batch** is complete.
- **Receipt Camera Reopen Pass 126: Review Tool Mode Height And Scroll Batch** is complete.
- **Receipt Camera Reopen Pass 127: Review Continue Button Persistence Batch** is complete.
- **Receipt Camera Reopen Pass 128: Receipt Review Mode Transition Polish Batch** is complete.
- **Receipt Camera Reopen Pass 129: Crop Mode Readability And Edge Controls Batch** is complete.
- **Receipt Camera Reopen Pass 130: Crop Apply And Preview Recovery Batch** is complete.
- **Receipt Camera Reopen Pass 131: Crop Failure And Storage Recovery Copy Batch** is complete.
- **Receipt Camera Reopen Pass 132: Review Image Brightness And Native Capture Evidence Batch** is complete.
- **Receipt Camera Reopen Pass 133: Brightness-Aware Capture Candidate Selection Batch** is complete.
- **Receipt Camera Reopen Pass 134: Brightness Review Feedback And Retake Guidance Batch** is complete.
- **Receipt Camera Reopen Pass 135: Review Continue Safety For Critical Photos Batch** is complete.
- **Receipt Camera Reopen Pass 136: Capture Exposure Retry Strategy Batch** is complete.
- **Receipt Camera Reopen Pass 137: Exposure Retry Failure Recovery Batch** is complete.
- **Receipt Camera Reopen Pass 138: Camera Capture Flow Real-Device Polish Batch** is complete.
- **Receipt Camera Reopen Pass 139: Review-To-App-Filled Receipt Handoff Batch** is complete.
- **Receipt Camera Reopen Pass 140: Receipt Review Failure Detail Batch** is complete.
- **Receipt Camera Reopen Pass 141: Real Receipt Line Review Entry Batch** is complete.
- **Receipt Camera Reopen Pass 142: Receipt Line Review Save-Gate Polish Batch** is complete.
- **Receipt Camera Reopen Pass 143: Receipt Mixed Allocation And Tax Review Batch** is complete.
- **Receipt Camera Reopen Pass 144: Receipt Review Line Editing Flow Batch** is complete.
- **Receipt Camera Reopen Pass 145: Receipt Review Correction Telemetry Batch** is complete.
- **Receipt Camera Reopen Pass 146: Camera Review Navigation Safety Batch** is complete.
- **Receipt Camera Reopen Pass 147: Review Add/Retake State Recovery Batch** is complete.
- **Receipt Camera Reopen Pass 148: Review Save/Continue State Audit Batch** is complete.
- **Receipt Camera Reopen Pass 149: Review Continuation Copy And Action Clarity Batch** is complete.
- **Receipt Camera Reopen Pass 150: Review Stitch Fallback Copy And Evidence Batch** is complete.
- **Receipt Camera Reopen Pass 151: Receipt Review Result Handoff Evidence Batch** is complete.
- **Receipt Camera Reopen Pass 152: OCR Source Count And Proof Handoff Guard Batch** is complete.
- **Receipt Camera Reopen Pass 153: OCR Read Status Source Detail Batch** is complete.
- **Receipt Camera Reopen Pass 154: OCR Failure Source-Aware Recovery Batch** is complete.
- **Receipt Camera Reopen Pass 155: OCR Warning Source-Aware Review Batch** is complete.
- **Receipt Camera Reopen Pass 156: Receipt Review Warning Visibility Batch** is complete.
- **Receipt Camera Reopen Pass 157: Receipt Review Line Warning Targeting Batch** is complete.
- **Receipt Camera Reopen Pass 158: OCR Warning Priority Stack Batch** is complete.
- **Receipt Camera Reopen Pass 159: Review Warning Save-Gate Alignment Batch** is complete.
- **Receipt Camera Reopen Pass 160: OCR Warning Diagnostics Alignment Batch** is complete.
- **Receipt Camera Reopen Pass 161: OCR Primary Warning Command Summary Batch** is complete.
- **Receipt Camera Reopen Pass 162: OCR Warning Export Summary Batch** is complete.
- **Receipt Camera Reopen Pass 163: Receipt Export Manifest OCR Health Batch** is complete.
- **Receipt Camera Reopen Pass 164: Receipt OCR Health Summary Tests Batch** is complete.
- **Receipt Camera Reopen Pass 165: Receipt OCR Failure Diagnostics Regression Batch** is complete.
- **Receipt Camera Reopen Pass 166: OCR Failure Telemetry Command Summary Batch** is complete.
- **Receipt Camera Reopen Pass 167: OCR Failure Cause Action Coverage Batch** is complete.
- **Receipt Camera Reopen Pass 168: OCR Failure Source Metadata Coverage Batch** is complete.
- **Receipt Camera Reopen Pass 169: OCR Failure Source Action Drilldown Batch** is complete.
- **Receipt Camera Reopen Pass 170: OCR Failure Stage Summary Batch** is complete.
- **Receipt Camera Reopen Pass 171: OCR Failure Summary Export Alignment Batch** is complete.
- **Receipt Camera Reopen Pass 172: OCR Summary Firestore Alignment Batch** is complete.
- **Receipt Camera Reopen Pass 173: OCR Summary Recovery Contract Batch** is complete.
- **Receipt Camera Reopen Pass 174: OCR Summary Privacy Regression Batch** is complete.
- **Receipt Camera Reopen Pass 175: Capture Brightness And Exit Regression Batch** is complete.
- **Receipt Camera Reopen Pass 176: Receipt Review Long-Receipt Control Layout Batch** is complete.
- **Receipt Camera Reopen Pass 177: Receipt Review Preview Footprint Batch** is complete.
- **Receipt Camera Reopen Pass 178: Receipt Review Single-Photo Action Density Batch** is complete.
- **Receipt Camera Reopen Pass 179: Receipt Review Quality Warning Action Batch** is complete.
- **Receipt Camera Reopen Pass 180: Receipt Review Bottom Sheet Overflow Guard Batch** is complete.
- **Receipt Camera Reopen Pass 181: Receipt Review Multi-Photo Density Guard Batch** is complete.
- **Receipt Camera Reopen Pass 182: Receipt Review Action Label Polish Batch** is complete.
- **Receipt Camera Reopen Pass 183: Camera And Review Exit Hardening Batch** is complete.
- **Receipt Camera Reopen Pass 184: Camera Capture Brightness Comparison Batch** is complete.
- **Receipt Camera Reopen Pass 185: Camera Brightness Recovery Copy Batch** is complete.
- **Receipt Camera Reopen Pass 186: Camera Exposure Evidence Summary Batch** is complete.
- **Receipt Camera Reopen Pass 187: OCR Source Readability Handoff Batch** is complete.
- **Receipt Camera Reopen Pass 188: OCR Source Failure Specificity Batch** is complete.
- **Receipt Camera Reopen Pass 189: OCR Source Recovery Action Drilldown Batch** is complete.
- **Receipt Camera Reopen Pass 190: OCR Recovery Telemetry Shape Batch** is complete.
- **Receipt Camera Reopen Pass 191: OCR Recovery Summary Surface Batch** is complete.
- **Receipt Camera Reopen Pass 192: OCR Recovery Detail Persistence Batch** is complete.
- **Receipt Camera Reopen Pass 193: OCR Recovery Export Summary Batch** is complete.
- **Receipt Camera Reopen Pass 194: OCR Recovery Detail Screen Batch** is complete.
- **Receipt Camera Reopen Pass 195: OCR Recovery Saved Receipt Regression Batch** is complete.
- **Receipt Camera Reopen Pass 196: OCR Recovery Calendar Summary Batch** is complete.
- **Receipt Camera Reopen Pass 197: OCR Recovery Day Recap Batch** is complete.
- **Receipt Camera Reopen Pass 198: OCR Recovery Range Recap Batch** is complete.
- **Receipt Camera Reopen Pass 199: OCR Recovery Recap Export Handoff Batch** is complete.
- **Receipt Camera Reopen Pass 200: OCR Recovery Command Center Contract Batch** is complete.
- **Receipt Camera Reopen Pass 201: OCR Recovery Command Center Privacy Regression Batch** is complete.
- **Receipt Camera Reopen Pass 202: OCR Recovery Command Center Handoff Documentation Batch** is complete.
- **Receipt Camera Reopen Pass 203: OCR Recovery Firestore Summary Bridge Batch** is complete.
- **Receipt Camera Reopen Pass 204: OCR Recovery Firestore Contract Documentation Batch** is complete.
- **Receipt Camera Reopen Pass 205: OCR Recovery Firestore Contract Guard Batch** is complete.
- **Receipt Camera Reopen Pass 206: OCR Recovery Summary Scheduler Bridge Batch** is complete.
- **Receipt Camera Reopen Pass 207: OCR Recovery Scheduled Upload Documentation Batch** is complete.
- **Receipt Camera Reopen Pass 208: OCR Recovery Scheduler Failure Safety Batch** is complete.
- **Receipt Camera Reopen Pass 209: OCR Recovery Scheduler Recorder Trace Batch** is complete.
- **Receipt Camera Reopen Pass 210: OCR Recovery Scheduler Trace Documentation Batch** is complete.
- **Receipt Camera Reopen Pass 211: OCR Recovery Telemetry Summary Trace Metrics Batch** is complete.
- **Receipt Camera Reopen Pass 212: OCR Recovery Firestore Summary Trace Metrics Batch** is complete.
- **Receipt Camera Reopen Pass 213: OCR Recovery Firestore Trace Metrics Documentation Batch** is complete.
- **Receipt Camera Reopen Pass 214: OCR Recovery Parser Metrics Firestore Allowlist Audit Batch** is complete.
- **Receipt Camera Reopen Pass 215: OCR Recovery Firestore Allowlist Guard Batch** is complete.
- **Receipt Camera Reopen Pass 216: OCR Recovery Firestore Allowlist Documentation Batch** is complete.
- **Receipt Camera Reopen Pass 217: OCR Recovery Firestore Allowlist Drift Stress Batch** is complete.
- **Receipt Camera Reopen Pass 218: OCR Recovery Summary Schema Snapshot Batch** is complete.
- **Receipt Camera Reopen Pass 219: OCR Recovery Command Center Schema Documentation Batch** is complete.
- **Receipt Camera Reopen Pass 220: OCR Recovery Telemetry Schema Change Checklist Batch** is complete.
- **Receipt Camera Reopen Pass 221: OCR Recovery Telemetry Sanitizer Type Guard Batch** is complete.
- **Receipt Camera Reopen Pass 222: OCR Recovery Telemetry Sanitizer Documentation Batch** is complete.
- **Receipt Camera Reopen Pass 223: OCR Recovery Telemetry Sanitizer Schema Helper Guard Batch** is complete.
- **Receipt Camera Reopen Pass 224: OCR Recovery Telemetry Firestore Metadata Boundary Batch** is complete.
- **Receipt Camera Reopen Pass 225: OCR Recovery Telemetry Failure Detail Cap Guard Batch** is complete.
- **Receipt Camera Reopen Pass 226: OCR Recovery Telemetry Failure Detail Schema Guard Batch** is complete.
- **Receipt Camera Reopen Pass 227: OCR Recovery Telemetry Failure Detail Privacy Guard Batch** is complete.
- **Receipt Camera Reopen Pass 228: OCR Recovery Telemetry Failure Detail Redaction Stress Batch** is complete.
- **Receipt Camera Reopen Pass 229: OCR Recovery Telemetry Failure Detail Redaction Helper Boundary Batch** is complete.
- **Receipt Camera Reopen Pass 230: OCR Recovery Telemetry Redaction Contract Drift Guard Batch** is complete.
- **Receipt Camera Reopen Pass 231: OCR Recovery Telemetry Redaction Vendor Expansion Batch** is complete.
- **Receipt Camera Reopen Pass 232: OCR Recovery Telemetry Redaction Source Isolation Batch** is complete.
- **Receipt Camera Reopen Pass 233: OCR Recovery Telemetry Source Action Coverage Batch** is complete.
- **Receipt Camera Reopen Pass 234: OCR Recovery Telemetry Source Action Firestore Guard Batch** is complete.
- **Receipt Camera Reopen Pass 235: OCR Recovery Telemetry Failure Detail Source Action Drilldown Batch** is complete.
- **Receipt Camera Reopen Pass 236: OCR Recovery Telemetry Drilldown Source Privacy Stress Batch** is complete.
- **Receipt Camera Reopen Pass 237: OCR Recovery Telemetry Drilldown Non-OCR Source Semantics Batch** is complete.
- **Receipt Camera Reopen Pass 238: OCR Recovery Telemetry Drilldown Source Schema Drift Guard Batch** is complete.
- **Receipt Camera Reopen Pass 239: OCR Recovery Telemetry Source Action Redaction Edge Matrix Batch** is complete.
- **Receipt Camera Reopen Pass 240: OCR Recovery Telemetry Drilldown Action Explainability Batch** is complete.
- **Receipt Camera Reopen Pass 241: OCR Recovery Telemetry Drilldown Explainability Firestore Drift Guard Batch** is complete.
- **Receipt Camera Reopen Pass 242: OCR Recovery Telemetry Drilldown Explainability Cause Matrix Batch** is complete.
- **Receipt Camera Reopen Pass 243 / Total Pass 323: OCR Recovery Telemetry Drilldown Explainability Firestore Cause Matrix Batch** is complete.
- **Receipt Camera Reopen Pass 244 / Total Pass 324: OCR Recovery Telemetry Drilldown Explainability Privacy Fixture Batch** is complete.
- **Receipt Camera Reopen Pass 245 / Total Pass 325: OCR Recovery Telemetry Drilldown Explainability Length Budget Batch** is complete.
- **Receipt Camera Reopen Pass 246 / Total Pass 326: OCR Recovery Telemetry Drilldown Evidence Label Privacy Budget Batch** is complete.
- **Receipt Camera Reopen Pass 247 / Total Pass 327: OCR Recovery Telemetry Drilldown Confirmed Cause Label Privacy Batch** is complete.
- **Receipt Camera Reopen Pass 248 / Total Pass 328: OCR Recovery Telemetry Drilldown Raw Token Boundary Batch** is complete.
- **Receipt Camera Reopen Pass 249 / Total Pass 329: OCR Recovery Telemetry Drift Guard Documentation Batch** is complete.
- **Receipt Camera Reopen Pass 250 / Total Pass 330: OCR Recovery Telemetry Write Budget Contract Batch** is complete.
- **Receipt Camera Reopen Pass 251 / Total Pass 331: Camera Health Command 1 Visibility Batch** is complete.
- **Receipt Camera Reopen Pass 252 / Total Pass 332: Accepted Photo Handoff And Admin Health Continuity Batch** is complete.
- Next receipt step is **Receipt Camera Reopen Pass 253 / Total Pass 333: Native Camera UI Settings And Review Continuity Batch**.

### Receipt Camera Reopen Pass 225: OCR Recovery Telemetry Failure Detail Cap Guard Batch

Status: completed.

Goal:
- Keep Command 1 OCR/parser failure drill-downs useful but bounded inside the
  single Firestore summary document so failure diagnostics do not become raw
  event history or an unbounded upload.

Completed:
- Added `maxRecentFailureDetails` to
  `MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument`.
- Capped `failureBreakdowns` at the existing default of 20 with a hard clamp of
  50.
- Capped `recentFailureDetails` at a default of 50 with a hard clamp of 100.
- Preserved caller control so either cap can be set to `0` for ultra-lean
  summaries.
- Added `caps expense telemetry failure drill-downs for Firestore` to prove the
  default cap, hard clamp, zero cap, and privacy-safe output behavior.
- Documented the failure drill-down caps in
  `docs/expense_command_center_ocr_contract.md` and
  `docs/firebase_sync_schema_spec.md`.
- Extended doc guards so the cap limits remain documented.

Verification:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart`
- `dart format test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 226: OCR Recovery Telemetry Failure Detail Schema Guard Batch

Status: completed.

Goal:
- Keep the nested Command 1 failure drill-down objects stable so an OCR/parser
  failure card can always show exactly what failed, where it failed, why it
  failed, and what action to take without exposing private receipt content.

Completed:
- Added shared expected key sets for `failureBreakdowns` and
  `recentFailureDetails`.
- Made `missingEvidence` always present as `none` when no evidence is missing,
  preventing Command 1 from having to guess whether a missing field means
  "healthy" or "not uploaded."
- Added a Firestore regression that checks nested failure object schemas and
  blocks private keys such as `payload`, `metadata`, `receiptText`,
  `rawOcrText`, `merchantName`, `itemDescription`, `proofPath`, `orgId`, and
  `userId`.
- Documented both nested object schemas in the OCR Command Center contract.
- Extended doc guards so the nested failure schemas, `missingEvidence` rule, and
  raw-private-content boundary remain documented.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 227: OCR Recovery Telemetry Failure Detail Privacy Guard Batch

Status: completed.

Goal:
- Add deeper privacy regression coverage around nested failure drill-down text so
  safe labels stay useful while raw OCR text, raw receipt values, and private
  user-entered strings remain blocked from Command 1 summaries.

Completed:
- Added Firestore-side redaction for private receipt hints inside failure
  diagnostic token fields such as `failedAt`, `confirmedCause`, `evidence`,
  `missingEvidence`, `topOcrFailureCause`, and `topOcrFailureStage`.
- Redacted known merchant names to `merchant`, money-like values to `amount`,
  and receipt/auth/transaction-length numbers to `number` before Command 1
  summary upload.
- Added `scrubs private receipt hints from failure drill-down text` to prove
  nested failure summaries do not upload Lowe's/amount/receipt/auth details.
- Documented the nested failure redaction rule in
  `docs/expense_command_center_ocr_contract.md` and
  `docs/firebase_sync_schema_spec.md`.
- Extended doc guards so the merchant/amount/number privacy placeholders remain
  part of the Firestore mirror contract.

Verification:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 228: OCR Recovery Telemetry Failure Detail Redaction Stress Batch

Status: completed.

Goal:
- Stress the failure-detail redaction boundary with multiple vendor, fuel,
  automotive, receipt-number, barcode-like, and currency-like diagnostic inputs
  so Command 1 gets useful categories while private receipt references stay out
  of the Firestore summary.

Completed:
- Added `stress scrubs fuel auto barcode and currency failure hints`.
- Covered tokenized Shell, Walmart, Home Depot, Jiffy Lube, totals, UPC/barcode
  values, auth codes, terminal numbers, transaction numbers, invoice numbers,
  and receipt/order-like numbers.
- Confirmed the local telemetry policy blocks raw currency symbols before
  summary generation, while Firestore redaction protects tokenized receipt-like
  values that can pass local telemetry.
- Documented the stress coverage in both OCR Command Center and Firebase sync
  specs.
- Extended doc guards so fuel, retail, auto-service, barcode-like, and
  underscore-separated total redaction examples remain part of the contract.

Verification:
- `dart format test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 229: OCR Recovery Telemetry Failure Detail Redaction Helper Boundary Batch

Status: completed.

Goal:
- Pull the Firestore failure-detail redaction rules behind a clearer helper
  boundary with focused coverage so future camera/OCR passes can reuse or extend
  redaction without scattering privacy logic across the document builder.

Completed:
- Moved Command 1 / Firestore receipt-hint redaction behind
  `_ExpenseTelemetryFirestoreRedactor`.
- Split redaction responsibility into readable text cleanup, failure token field
  cleanup, and failure count-map key cleanup.
- Reused the helper for safe OCR contract readable text and expense telemetry
  failure drill-downs.
- Added `keeps redaction scoped to failure detail fields` to prove failure
  details redact merchant/amount/number hints while normal operational tokens
  such as platform, device tier, app version, OCR source, and app-version counts
  remain useful.
- Documented the helper boundary in OCR Command Center and Firebase sync specs.
- Extended doc guards so the helper boundary and no-over-redaction rule stay in
  the contract.

Verification:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 230: OCR Recovery Telemetry Redaction Contract Drift Guard Batch

Status: completed.

Goal:
- Add contract-drift coverage that compares the documented Firestore redaction
  boundary with the active helper fields so future OCR/camera telemetry fields
  cannot be added without either redaction or explicit documentation.

Completed:
- Added shared expected redaction token/map field sets to
  `test/helpers/expense_telemetry_schema_expectations.dart`.
- Added `keeps Firestore redaction helper fields aligned with contract` to guard
  `_ExpenseTelemetryFirestoreRedactor` against silent field-list drift.
- Added isolated `test/expense_telemetry_redaction_contract_guard_test.dart`
  so the redaction contract can still be verified when unrelated module imports
  are temporarily broken.
- Extended the OCR Command Center doc test so every redacted token and map field
  must be named in the contract.
- Documented the active redacted token fields and redacted count-map fields in
  both the OCR Command Center contract and Firebase sync spec.
- Extended Firestore schema guards so the sync spec must keep the redaction
  helper boundary and active field lists documented.

Verification:
- `dart format test/helpers/expense_telemetry_schema_expectations.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/expense_telemetry_redaction_contract_guard_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/expense_telemetry_redaction_contract_guard_test.dart`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

Note:
- `flutter test test/maintainiac_firestore_documents_test.dart ...` is currently
  blocked by an unrelated compile error in
  `lib/screens/work_supplies/data/work_supply_receipt_parser_terms.dart`, where
  the const map key `taping knife` is duplicated.

### Receipt Camera Reopen Pass 231: OCR Recovery Telemetry Redaction Vendor Expansion Batch

Status: completed.

Goal:
- Expand the known merchant redaction list and regression coverage for more
  regional fuel, retail, and auto-service vendors likely to appear in receipt
  OCR/parser diagnostics.

Completed:
- Expanded the Firestore failure-diagnostic merchant redaction pattern to cover
  more regional fuel, truck stop, contractor retail, and auto-service names
  while avoiding broad numeric-only or two-letter matches that could erase useful
  operational tokens.
- Added isolated runtime coverage that builds a real expense telemetry summary
  document and proves regional vendor hints, totals, receipt numbers, barcodes,
  auth codes, transaction ids, and invoice numbers do not survive in Command
  1-visible failure drill-downs.
- Updated the OCR Command Center and Firebase sync specs so the expanded
  redaction guard stays part of the contract.
- Extended doc guards so Pilot/Flying J, Love's, Casey's, Kwik Trip, Tractor
  Supply, Harbor Freight, Valvoline, Take 5, and Firestone remain documented
  examples.

Verification:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 232: OCR Recovery Telemetry Redaction Source Isolation Batch

Status: completed.

Goal:
- Continue hardening receipt/OCR diagnostic privacy by isolating source labels
  that can safely explain OCR failure origin from labels that might contain
  receipt text, vendor names, file paths, or user-entered content.

Completed:
- Changed OCR failure source extraction so evidence can only produce allowlisted
  source buckets: `photo`, `pdf`, `importedtext`, `mixed`, `none`, or
  `unknown`.
- Made unrecognized `source_*` labels fall back to `unknown`, preventing
  merchant names, user notes, file labels, receipt text, and other private
  evidence labels from becoming `ocrFailureSourceCounts` or
  `topOcrFailureSource`.
- Added local telemetry coverage proving known source synonyms are preserved
  while private-looking source labels become `unknown`.
- Added Firestore summary coverage proving poisoned source labels do not reach
  Command 1 and failure-detail evidence is still redacted.
- Documented the OCR source-isolation rule in the Command Center OCR contract
  and Firebase sync schema.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 233: OCR Recovery Telemetry Source Action Coverage Batch

Status: completed.

Goal:
- Ensure every allowed OCR source bucket has a clear Command 1 recovery action
  so the admin dashboard can explain what to fix without guessing or exposing
  private receipt content.

Completed:
- Added dedicated Command 1 recovery actions for `mixed` and `unknown` OCR
  source buckets instead of letting them fall through to generic guidance.
- Kept existing source-specific actions for `photo`, `pdf`, `importedtext`, and
  `none`.
- Added regression coverage proving all allowed source buckets produce a clear
  `topOcrFailureSourceAction` and that private source labels do not appear in
  the action text.
- Documented the source-action contract in the Command Center OCR contract and
  Firebase sync schema.
- Extended doc guards so the action coverage requirement stays tied to the safe
  source buckets.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 234: OCR Recovery Telemetry Source Action Firestore Guard Batch

Status: completed.

Goal:
- Prove the source-action guidance survives the final Firestore summary
  sanitizer for each allowed OCR source bucket without leaking private receipt
  evidence.

Completed:
- Added isolated Firestore-builder coverage for every allowed OCR source bucket:
  `photo`, `pdf`, `importedtext`, `mixed`, `none`, and `unknown`.
- Proved `topOcrFailureSource` survives the final Firestore summary document.
- Proved `topOcrFailureSourceAction` remains bounded, sanitizer-safe, and still
  useful enough for Command 1 to route the owner to the right investigation
  path.
- Proved source-action Firestore summaries do not preserve private vendor names
  or exact receipt totals from the source evidence.
- Documented the final Firestore sanitizer actionability requirement in the OCR
  Command Center contract and Firebase sync schema.

Verification:
- `dart format test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 235: OCR Recovery Telemetry Failure Detail Source Action Drilldown Batch

Status: completed.

Goal:
- Make failure drill-down samples carry enough source-action context for Command
  1 to explain the next repair path on a specific OCR failure group without
  exposing private receipt content.

Completed:
- Added `ocrFailureSource` and `ocrFailureSourceAction` to grouped
  `failureBreakdowns`.
- Added the same fields to recent `recentFailureDetails` samples.
- Kept the values derived from safe OCR source buckets instead of raw evidence.
- Initially kept non-OCR failures on `ocrFailureSource: none`; Pass 237 later
  split those rows into `not_ocr` so `none` can stay reserved for OCR failures
  that started without a usable source.
- Updated Firestore nested-map allowlists and shared schema expectations so the
  new fields survive the one-summary-document Command 1 path.
- Documented the new drill-down source/action fields in the OCR Command Center
  contract and Firebase sync schema.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 236: OCR Recovery Telemetry Drilldown Source Privacy Stress Batch

Status: completed.

Goal:
- Stress drill-down source/action fields with mixed OCR and non-OCR failures,
  poisoned source labels, totals, auth codes, and store names to prove Command 1
  gets repair context without private receipt content.

Completed:
- Added a mixed Firestore stress test that combines photo OCR, PDF OCR,
  poisoned OCR source labels, user-note source labels, parser failures, and save
  failures in one summary document.
- Proved both grouped `failureBreakdowns` and recent `recentFailureDetails`
  keep safe `ocrFailureSource` / `ocrFailureSourceAction` context.
- Proved non-OCR parser/save failures stay out of raw OCR source labels; Pass
  237 later tightened their explicit bucket to `not_ocr`.
- Proved store names, exact totals, auth codes, terminal ids, invoice numbers,
  transaction numbers, and barcode-like values do not survive in the final
  Command 1-visible payload.
- Documented the mixed OCR/non-OCR drill-down stress requirement in the OCR
  Command Center contract and Firebase sync schema.

Verification:
- `dart format test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 237: OCR Recovery Telemetry Drilldown Non-OCR Source Semantics Batch

Status: completed.

Goal:
- Give non-OCR failure drill-down rows a clearer non-OCR-safe source/action label
  for parser/save/sync failures without confusing Command 1 or exposing private
  receipt content.

Completed:
- Changed non-OCR drill-down rows from `ocrFailureSource: none` to
  `ocrFailureSource: not_ocr`.
- Kept `none` reserved for actual OCR-step failures where OCR started without a
  usable photo, PDF, or imported text source.
- Added a `not_ocr` source action that points Command 1 to workflow, confirmed
  cause, evidence summary, and recommended action instead of camera/PDF OCR
  repair paths.
- Updated local telemetry and Firestore redaction guard coverage so grouped and
  recent failure rows preserve the clearer non-OCR semantics.
- Updated the OCR Command Center contract and Firebase sync schema with the
  `not_ocr` boundary.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 238: OCR Recovery Telemetry Drilldown Source Schema Drift Guard Batch

Status: completed.

Goal:
- Add explicit drift guards so future changes to OCR source buckets, source
  actions, docs, Firestore sanitizer allowlists, and Command 1 drill-down fields
  have to move together.

Completed:
- Centralized expected OCR source buckets in the telemetry schema expectation
  helper.
- Split the six top-level OCR source buckets from the seven drill-down buckets
  that also include `not_ocr`.
- Added a Firestore drift guard that builds every safe OCR source bucket plus a
  non-OCR failure and proves local telemetry, Firestore summary maps, grouped
  failure drill-downs, and recent failure drill-downs stay aligned.
- Updated the OCR Command Center contract and Firebase sync schema to document
  that nested drill-down source fields may use `not_ocr` while top-level OCR
  source counts may not.

Verification:
- `dart format test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 239: OCR Recovery Telemetry Source Action Redaction Edge Matrix Batch

Status: completed.

Goal:
- Stress source-action redaction against edge labels, mixed source hints,
  malformed source tokens, and long action strings so Command 1 keeps useful
  guidance without leaking private receipt clues.

Completed:
- Added a Firestore-facing source-action edge matrix covering `source_camera`,
  `source_image`, `source_document`, `source_pasted_text`, `source_combined`,
  `source_missing`, malformed private source labels, and non-OCR drill-down
  rows.
- Proved each source bucket keeps a useful bounded action after Firestore
  tokenization.
- Proved source actions and drill-down rows do not leak store names, exact
  totals, auth numbers, receipt numbers, barcode-like numbers, or user-note
  source labels.
- Updated the OCR Command Center contract and Firebase sync schema to require
  source-action edge coverage.
- Extended doc guards so those edge aliases remain documented.

Verification:
- `dart format test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 240: OCR Recovery Telemetry Drilldown Action Explainability Batch

Status: completed.

Goal:
- Make failure drill-down action fields easier for Command 1 to explain in
  plain language without needing private evidence, while keeping every action
  bounded, source-safe, and tied to the failed workflow.

Completed:
- Added `actionSummary` to grouped `failureBreakdowns` and recent
  `recentFailureDetails`.
- Built action summaries from safe workflow labels, confirmed cause status,
  missing evidence labels, source bucket context, and the existing recommended
  action.
- Preserved unconfirmed-cause behavior by asking for missing evidence before
  claiming the app knows the fix.
- Kept `actionSummary` readable through the Firestore sanitizer while bounded
  and private-content safe.
- Updated schema helpers, OCR Command Center docs, and Firebase sync schema so
  Command 1 can rely on the new field.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 241: OCR Recovery Telemetry Drilldown Explainability Firestore Drift Guard Batch

Status: completed.

Goal:
- Add Firestore drift guards around `actionSummary` so future schema,
  allowlist, sanitizer, docs, and tests cannot diverge or accidentally tokenize
  the plain-language explanation.

Completed:
- Added a Firestore-facing drift guard proving `actionSummary` remains readable
  after summary sanitization instead of becoming a lowercase token.
- Proved `actionSummary` still scrubs store names, exact totals, auth numbers,
  receipt numbers, and source tokens.
- Proved confirmed OCR failures keep a useful next-check summary and
  unconfirmed failures ask for missing evidence before claiming the app knows
  the fix.
- Extended redaction helper contract tests so `actionSummary` must stay in the
  readable text sanitizer path.
- Updated OCR Command Center and Firebase sync docs to spell out the readable
  text boundary.

Verification:
- `dart format test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 242: OCR Recovery Telemetry Drilldown Explainability Cause Matrix Batch

Status: completed.

Goal:
- Build matrix coverage for `actionSummary` across confirmed OCR, parser,
  attachment, save, sync, export, and unconfirmed failure causes so every major
  receipt/expense workflow gets a useful Command 1 explanation.

Completed:
- Added local telemetry matrix coverage for `actionSummary` across OCR,
  parser, receipt attachment, save, sync, cloud backup, export, line review, and
  unconfirmed failure rows.
- Proved each summary names the failed workflow, gives the safe context to
  check next, and includes the expected next-step hint.
- Proved unconfirmed failures ask for missing evidence instead of pretending the
  app knows the fix.
- Proved local summaries stay display-friendly and do not expose raw token
  underscores.

Verification:
- `dart format test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 243: OCR Recovery Telemetry Drilldown Explainability Firestore Cause Matrix Batch

Status: completed.

Goal:
- Mirror the `actionSummary` cause matrix through the Firestore summary builder
  so Command 1 receives the same useful explanations after sanitizer and upload
  boundaries.

Completed:
- Added Firestore-facing matrix coverage for `actionSummary` across OCR,
  parser, receipt attachment, save, sync, cloud backup, export, line review, and
  unconfirmed failure rows.
- Proved grouped `failureBreakdowns` and recent `recentFailureDetails` both
  preserve the safe workflow, context, and next-step hints that Command 1 needs
  after upload.
- Proved uploaded summaries stay readable, bounded to the Firestore readable
  text limit, and avoid raw snake-case diagnostic internals.
- Proved private merchant, exact amount, auth, barcode, receipt, and poisoned
  cause hints do not survive into the Firestore summary document.

Verification:
- `dart format test/expense_telemetry_redaction_contract_guard_test.dart`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart --plain-name "keeps action summaries useful across Firestore failure cause matrix" -r expanded`

### Receipt Camera Reopen Pass 244: OCR Recovery Telemetry Drilldown Explainability Privacy Fixture Batch

Status: completed.

Goal:
- Stress `actionSummary` with private merchant, receipt, auth, barcode, amount,
  and user-note evidence across mixed workflows so no private clue survives
  local or Firestore drill-down summaries.

Completed:
- Added a local privacy-safe failure phrase helper for `actionSummary` and
  unconfirmed `recommendedAction` text so private diagnostic values are scrubbed
  before Firestore upload.
- Redacted known merchants, exact amounts, long receipt/auth/barcode numbers,
  emails, phone numbers, and user-note/name style private references from
  summary text.
- Added a privacy fixture test proving local and Firestore grouped/recent
  summaries stay readable while hiding merchant, customer/name, auth, receipt,
  barcode, phone, amount, and raw source tokens.
- Kept safe generic language such as `merchant`, `amount`, and
  `private reference` so Command 1 remains useful without exposing private
  receipt content.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_telemetry_redaction_contract_guard_test.dart`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart --plain-name "protects action summaries from private fixture hints locally and in Firestore" -r expanded`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 245: OCR Recovery Telemetry Drilldown Explainability Length Budget Batch

Status: completed.

Goal:
- Keep `actionSummary` useful under Firestore readable-text limits by proving
  the failed workflow, safe context, and next action survive truncation for
  long receipt, OCR, parser, and sync diagnostic inputs.

Completed:
- Compact `actionSummary` cause, missing-evidence, and next-action phrases at
  the source so local summaries are born inside the Firestore readable text
  budget instead of depending on upload-time truncation.
- Shortened the non-OCR source context while preserving the plain-language
  phrase Command 1 needs: `the failed workflow`.
- Tightened the local action summary matrix from a 260-character ceiling to the
  180-character Firestore readable-text budget.
- Verified Firestore grouped and recent failure rows still preserve workflow,
  safe context, and next-step hints after the compact wording.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart --plain-name "covers action summaries across major failure workflows" -r expanded`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart --plain-name "keeps action summaries useful across Firestore failure cause matrix" -r expanded`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart --plain-name "protects action summaries from private fixture hints locally and in Firestore" -r expanded`

### Receipt Camera Reopen Pass 246: OCR Recovery Telemetry Drilldown Evidence Label Privacy Budget Batch

Status: completed.

Goal:
- Apply the same privacy and length discipline to visible evidence labels so
  Command 1 can explain what proof is missing without exposing receipt content
  or oversized diagnostic text.

Completed:
- Routed local `evidenceLabel` and `missingEvidenceLabel` through the same
  privacy-safe compact phrase builder used by `actionSummary`.
- Hardened local redaction for note/name/call phrases, known merchant names,
  receipt-number references, auth/barcode/order style identifiers, emails,
  phone numbers, exact amounts, and long numeric receipt hints.
- Expanded the local-plus-Firestore privacy fixture so summaries,
  recommended actions, evidence labels, and missing-evidence labels are all
  checked together.
- Proved visible labels stay non-empty, avoid raw snake-case tokens, and remain
  bounded while still using safe generic words such as `merchant`, `amount`,
  and `private reference`.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_telemetry_redaction_contract_guard_test.dart`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart --plain-name "protects action summaries from private fixture hints locally and in Firestore" -r expanded`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 247: OCR Recovery Telemetry Drilldown Confirmed Cause Label Privacy Batch

Status: completed.

Goal:
- Apply privacy-safe readable labels to confirmed cause and failure-stage labels
  so Command 1 drill-down rows never expose private receipt hints through label
  fields while still showing a useful cause category.

Completed:
- Routed local `failedAtLabel`, `causeLabel`, and
  `topOcrFailureStageLabel` through a privacy-safe diagnostic label helper.
- Kept the stored machine tokens unchanged for grouping and counts while
  making the visible labels safe for Command 1 drill-down surfaces.
- Preserved display acronyms such as `OCR`, `PDF`, and `Hive` after privacy
  cleanup so labels stay readable.
- Extended the local-plus-Firestore privacy fixture so cause labels, failure
  stage labels, and the top OCR stage label are checked alongside summaries,
  recommended actions, evidence labels, and missing-evidence labels.
- Added common receipt location redaction so city/address hints in diagnostic
  labels become generic `location` text.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_telemetry_redaction_contract_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart --plain-name "builds confirmed cause failure breakdowns for Command 1" -r expanded`
- `flutter test test/expense_screen_telemetry_test.dart --plain-name "tracks export completion, blocked exports, and export failure causes" -r expanded`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart --plain-name "protects action summaries from private fixture hints locally and in Firestore" -r expanded`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 248: OCR Recovery Telemetry Drilldown Raw Token Boundary Batch

Status: completed.

Goal:
- Verify which raw diagnostic token fields are intentionally stored for machine
  grouping and which visible fields must remain readable, so future Command 1
  work does not accidentally show raw receipt-derived tokens to the user.

Completed:
- Added a Firestore drill-down boundary test that separates machine-token
  fields from human-visible fields.
- Proved `failedAt`, `confirmedCause`, `evidence`, `missingEvidence`, and
  `ocrFailureSourceAction` remain machine-safe tokens for grouping, filtering,
  and action routing.
- Proved visible fields such as `failedAtLabel`, `causeLabel`,
  `evidenceLabel`, `missingEvidenceLabel`, `recommendedAction`, and
  `actionSummary` do not expose raw token underscores.
- Aligned the Firestore telemetry redactor with the local privacy helper for
  known locations, note/name references, receipt-number phrases, and
  private-reference tokens.
- Fixed over-redaction so normal workflow labels such as `Receipt OCR` and
  `Receipt parser` remain readable instead of becoming private-reference text.

Verification:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart test/expense_telemetry_redaction_contract_guard_test.dart`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart --plain-name "keeps machine tokens out of visible Firestore drill-down text" -r expanded`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart --plain-name "isolates OCR source labels from private evidence strings" -r expanded`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart --plain-name "keeps action summaries useful across Firestore failure cause matrix" -r expanded`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 249: OCR Recovery Telemetry Drift Guard Documentation Batch

Status: completed.

Goal:
- Update Command 1 OCR telemetry docs and schema guards so the machine-token
  versus visible-text boundary is explicit, testable, and hard to accidentally
  undo during future receipt-camera work.

Completed:
- Updated `docs/expense_command_center_ocr_contract.md` so Command 1 OCR and
  expense telemetry docs explicitly separate machine-token fields from visible
  drill-down text.
- Updated `docs/firebase_sync_schema_spec.md` so Firestore redaction rules
  describe merchant, location, amount, number, and private-reference
  placeholders before a summary can be queued.
- Extended documentation guard tests so both the OCR Command 1 contract and the
  Firebase sync schema keep the machine-token, visible-label, redaction, and
  private-content boundaries documented together.
- Preserved the single summary document direction for Command 1 telemetry so
  camera/OCR health stays visible without uploading raw receipt content.

Verification:
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 250: OCR Recovery Telemetry Write Budget Contract Batch

Status: completed.

Goal:
- Lock the Firebase/Firestore write-budget boundary for receipt camera, OCR,
  parser, and expense diagnostics so raw local events are summarized before
  cloud upload and Command 1 can read camera health without creating one
  Firestore write per capture, failure, retry, receipt, or OCR event.

Completed:
- Added `ExpenseTelemetryFirestoreWriteBudget` with the 20,000-write safety
  target, single-summary upload shape, zero raw-event upload count, and a helper
  that estimates scheduled summary writes per day from the scheduler interval.
- Added a high-volume bridge regression proving 240 local receipt/camera events
  still queue one replacement Firestore summary document for the same
  `expenseTelemetrySummaries/latest` path.
- Proved the queued summary keeps `rawEventUploadCount` at `0`, preserves
  camera/OCR failure counts, caps recent failure samples at 50, and replaces the
  pending draft on repeated queue attempts.
- Documented the write-budget contract in the Command 1 OCR handoff doc and the
  Firebase sync schema so diagnostics stay local-first and summarized before
  Firestore upload.
- Extended doc guards to require the 15-minute / 96 scheduled writes per org per
  day / 20,000 writes per day safety language and the no per-capture,
  per-failure, per-retry, per-line, or per-receipt write rule.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry_firestore_bridge.dart test/expense_screen_telemetry_firestore_bridge_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_firestore_bridge_test.dart`
- `flutter test test/expense_screen_telemetry_firestore_bridge_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/data/expense_screen_telemetry_firestore_bridge.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 251: Camera Health Command 1 Visibility Batch

Status: planned.

Goal:
- Make the next Command 1-facing camera health layer explicit: capture success
  rate, capture failure rate, back/exit failures, focus/exposure warnings,
  long-receipt section issues, stitching fallback rate, OCR handoff success,
  and safe drill-down paths, all without private receipt content.

### Receipt Camera Reopen Pass 224: OCR Recovery Telemetry Firestore Metadata Boundary Batch

Status: completed.

Goal:
- Lock the boundary between the local Command Center expense telemetry schema
  and the Firestore document wrapper metadata so receipt health fields, upload
  shape fields, and the optional OCR contract do not blur together.

Completed:
- Added `Firestore summary metadata stays outside local telemetry schema`.
- Proved `summaryId`, `summaryScope`, `uploadShape`, `rawEventUploadCount`,
  and `commandCenterOcrContract` are absent from
  `ExpenseTelemetryHealthSnapshot.toCommandCenterMap()`.
- Proved those same Firestore wrapper fields are present in the generated
  expense telemetry summary document.
- Proved `summaryId` is path-token sanitized before storage and that the raw
  unsanitized summary id does not survive in document data.
- Added a `Firestore Metadata Boundary` section to
  `docs/expense_command_center_ocr_contract.md`.
- Updated `docs/firebase_sync_schema_spec.md` and doc guard tests so Firestore
  wrapper metadata stays out of the local Command Center telemetry schema
  helper.

Verification:
- `dart format test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 223: OCR Recovery Telemetry Sanitizer Schema Helper Guard Batch

Status: completed.

Goal:
- Protect the shared expected expense telemetry schema helper from drifting into
  Firestore-only document metadata or losing critical Command 1 receipt health
  keys.

Completed:
- Added `expense telemetry schema helper stays scoped to Command Center map`.
- Proved `expectedExpenseTelemetryCommandCenterKeys` has no duplicate entries.
- Proved Firestore document metadata keys such as `summaryId`,
  `summaryScope`, `uploadShape`, `rawEventUploadCount`, and
  `commandCenterOcrContract` are not part of the local Command Center telemetry
  schema helper.
- Proved the helper still contains critical receipt/OCR health keys such as
  `ocrSuccessRate`, `parserFailureRate`, `topOcrFailureSourceAction`,
  `failureBreakdowns`, and `recentFailureDetails`.

Verification:
- `dart format test/maintainiac_firestore_documents_test.dart`
- `flutter analyze test/maintainiac_firestore_documents_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 222: OCR Recovery Telemetry Sanitizer Documentation Batch

Status: completed.

Goal:
- Document the expense telemetry sanitizer value rules so future Command 1,
  Firestore, OCR, parser, and receipt telemetry changes know which value shapes
  are allowed in the one-document summary.

Completed:
- Added an `Expense Telemetry Sanitizer Rules` section to
  `docs/expense_command_center_ocr_contract.md`.
- Documented that nonnegative counts, finite nonnegative rates, safe timestamp
  strings, safe tokens, readable labels, nonnegative count maps, and sanitized
  nested failure maps are the allowed Firestore summary value shapes.
- Documented that unsupported scalar values, negative scalar counts, negative
  rates, `NaN`, and infinite rates must throw before the Firestore summary is
  queued.
- Updated `docs/firebase_sync_schema_spec.md` with the same sanitizer boundary.
- Extended OCR contract and Firestore data model doc guards so the sanitizer
  rules remain documented.

Verification:
- `dart format test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/maintainiac_firestore_documents_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/maintainiac_firestore_documents_test.dart`

### Receipt Camera Reopen Pass 221: OCR Recovery Telemetry Sanitizer Type Guard Batch

Status: completed.

Goal:
- Add direct Firestore document-builder coverage for the expense telemetry
  sanitizer so invalid scalar values are rejected and map/label values are
  safely normalized before Command 1 can read them.

Completed:
- Added `rejects invalid expense telemetry scalar values before Firestore`.
- Proved negative scalar counts fail before an expense telemetry summary can be
  queued to Firestore.
- Proved negative derived rates fail before an expense telemetry summary can be
  queued to Firestore.
- Added `sanitizes expense telemetry maps and drill-down labels`.
- Proved count-map keys are tokenized, negative map counts are removed, OCR
  source drill-down keys are tokenized, readable stage labels are normalized,
  and private-looking free text/amounts do not survive as plain receipt text.
- Added a test-only `_expenseTelemetrySnapshotForSanitizer` fixture so sanitizer
  edge cases can be exercised through the public Firestore summary builder
  instead of exposing private sanitizer helpers.

Verification:
- `dart format test/maintainiac_firestore_documents_test.dart`
- `flutter analyze test/maintainiac_firestore_documents_test.dart lib/shared/firebase/maintainiac_firestore_documents.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 220: OCR Recovery Telemetry Schema Change Checklist Batch

Status: completed.

Goal:
- Add a practical change checklist for future Command 1-visible expense
  telemetry fields so OCR, parser, sync, scheduler, export, Firestore, docs,
  and privacy guards move together.

Completed:
- Added an `Expense Telemetry Schema Change Checklist` section to
  `docs/expense_command_center_ocr_contract.md`.
- Documented the required update path for new telemetry fields:
  `ExpenseTelemetryHealthSnapshot.toCommandCenterMap`,
  `MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument`,
  `_sanitizeExpenseTelemetryMap`,
  `test/helpers/expense_telemetry_schema_expectations.dart`, the Firestore
  parity regression, the OCR contract doc, the Firebase sync schema spec, and
  doc guard tests.
- Added the rule that new Command 1 telemetry fields must not create
  per-event, per-receipt, per-failure, or separate admin collections just to be
  visible.
- Updated `docs/firebase_sync_schema_spec.md` to point schema changes back to
  the checklist while preserving the one-summary-document Firestore shape.
- Extended the OCR contract doc guard and Firebase data model guard to require
  the checklist, schema helper, sanitizer, and no-extra-collection rule.

Verification:
- `dart format test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/maintainiac_firestore_documents_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/maintainiac_firestore_documents_test.dart`

### Receipt Camera Reopen Pass 219: OCR Recovery Command Center Schema Documentation Batch

Status: completed.

Goal:
- Document the Command 1-visible expense telemetry summary schema from the
  guarded key snapshot so the Firestore summary contract is readable, tested,
  and kept in sync with code.

Completed:
- Added an `Expense Telemetry Summary Fields` section to
  `docs/expense_command_center_ocr_contract.md`.
- Documented the one-summary-document telemetry groups for envelope/context,
  expense screen flow health, image/OCR/parser/app-filled review health,
  cloud/sync/scheduler/export health, and OCR failure drill-down health.
- Moved the expected Command Center expense telemetry key set into
  `test/helpers/expense_telemetry_schema_expectations.dart` so schema snapshot
  checks and documentation guards share one source of truth.
- Updated `test/maintainiac_firestore_documents_test.dart` to use the shared
  schema expectation helper.
- Extended `test/expense_command_center_ocr_contract_doc_test.dart` so every
  expected expense telemetry key must be documented in the OCR/Command Center
  handoff contract.

Verification:
- `dart format test/helpers/expense_telemetry_schema_expectations.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart`
- `flutter analyze test/helpers/expense_telemetry_schema_expectations.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/maintainiac_firestore_documents_test.dart`

### Receipt Camera Reopen Pass 218: OCR Recovery Summary Schema Snapshot Batch

Status: completed.

Goal:
- Add a schema snapshot for the expense Command Center telemetry map so field
  removals, renames, and undocumented additions are caught alongside Firestore
  sanitizer drift.

Completed:
- Added `_expectedExpenseTelemetryCommandCenterKeys` to the Firestore document
  test suite.
- Extended `keeps every Command Center telemetry field in Firestore summary`
  so the rich `ExpenseTelemetryHealthSnapshot.toCommandCenterMap()` output must
  match the expected schema key set.
- Kept the existing Firestore parity check, conditional-key stress check, and
  privacy checks in the same regression so Command 1-visible expense receipt
  health changes must update code, docs, and tests together.

Verification:
- `dart format test/maintainiac_firestore_documents_test.dart`
- `flutter analyze test/maintainiac_firestore_documents_test.dart lib/shared/firebase/maintainiac_firestore_documents.dart lib/screens/expenses/data/expense_screen_telemetry.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 217: OCR Recovery Firestore Allowlist Drift Stress Batch

Status: completed.

Goal:
- Make the Firestore summary parity regression harder to accidentally weaken by
  proving the rich fixture exercises the conditional OCR, parser, and scheduler
  telemetry keys that only appear when real failure/recovery evidence exists.

Completed:
- Strengthened `keeps every Command Center telemetry field in Firestore summary`
  with an explicit conditional-key fixture check.
- Required the parity fixture to produce and preserve
  `topExpenseSummaryOcrContractSource`,
  `topExpenseSummaryOcrContractSkippedReason`, `topOcrFailureCause`,
  `topOcrFailureSource`, `topOcrFailureSourceAction`, `topOcrFailureStage`,
  and `topOcrFailureStageLabel`.
- Added value checks for those top conditional fields so source, skipped
  reason, OCR failure cause, OCR source, recommended action, and OCR stage
  labels stay deterministic across the Firestore summary boundary.
- Preserved the single-document summary shape and privacy checks from the
  previous parity guard.

Verification:
- `dart format test/maintainiac_firestore_documents_test.dart`
- `flutter analyze test/maintainiac_firestore_documents_test.dart lib/shared/firebase/maintainiac_firestore_documents.dart lib/screens/expenses/data/expense_screen_telemetry.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 216: OCR Recovery Firestore Allowlist Documentation Batch

Status: completed.

Goal:
- Document the Firestore allowlist parity rule so future OCR, parser, sync,
  export, and Command 1 telemetry metrics cannot be added locally while
  silently disappearing from the one-document Firestore summary.

Completed:
- Updated `docs/expense_command_center_ocr_contract.md` to state that every
  new top-level field from
  `ExpenseTelemetryHealthSnapshot.toCommandCenterMap()` must either survive
  into `expenseTelemetrySummaries/{summaryId}` or be intentionally excluded
  with a documented reason.
- Documented the parity regression
  `keeps every Command Center telemetry field in Firestore summary` as the
  guard that compares local Command Center telemetry keys with the final
  Firestore summary document.
- Updated `docs/firebase_sync_schema_spec.md` so the Firebase cost model keeps
  those fields in the existing one-summary-document path and forbids moving
  them into per-event, per-receipt, or separate admin collections just to make
  them visible.
- Extended the OCR contract doc guard and Firestore data model guard so the
  allowlist parity rule remains documented.

Verification:
- `dart format test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/maintainiac_firestore_documents_test.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/maintainiac_firestore_documents_test.dart`

### Receipt Camera Reopen Pass 215: OCR Recovery Firestore Allowlist Guard Batch

Status: completed.

Goal:
- Prevent future expense telemetry fields from being computed for Command 1
  locally and then silently dropped by the Firestore summary sanitizer.

Completed:
- Added a broad Firestore parity regression that builds a rich
  `ExpenseTelemetryHealthSnapshot` covering screen usage, add/abandon,
  validation, image attach, OCR, parser, app-filled line review, user
  correction, cloud backup, scheduled OCR contract queue traces, sync, export,
  and failure drill-down metrics.
- Compared every top-level key emitted by
  `ExpenseTelemetryHealthSnapshot.toCommandCenterMap()` against the generated
  `expenseTelemetrySummaries/{summaryId}` document.
- Kept the assertion key-based instead of value-based where the Firestore
  builder intentionally overrides summary document metadata such as `schema`.
- Preserved the privacy guard expectation that summary output does not expose
  raw receipt text or the org id inside the summary data.

Verification:
- `dart format test/maintainiac_firestore_documents_test.dart`
- `flutter analyze test/maintainiac_firestore_documents_test.dart lib/shared/firebase/maintainiac_firestore_documents.dart lib/screens/expenses/data/expense_screen_telemetry.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_test.dart`

### Receipt Camera Reopen Pass 214: OCR Recovery Parser Metrics Firestore Allowlist Audit Batch

Status: completed.

Goal:
- Audit the expense telemetry Command Center map against the Firestore summary
  sanitizer so parser/OCR recovery metrics are not computed locally and then
  silently dropped before Command 1 can read them.

Completed:
- Compared `ExpenseTelemetryHealthSnapshot.toCommandCenterMap` fields against
  `_sanitizeExpenseTelemetryMap`.
- Added missing parser fields to the Firestore summary allowlist:
  `parserStartedCount`, `parserCompletedCount`, `parserNeedsReviewCount`,
  `parserFailedCount`, `parserSuccessRate`, `parserReviewRate`, and
  `parserFailureRate`.
- Added missing app-filled receipt review fields:
  `appFilledReceiptLineConfirmedCount`,
  `appFilledReceiptLineCorrectedCount`, and
  `appFilledReceiptLineCorrectionRate`.
- Added missing OCR failure drill-down fields:
  `ocrFailureCauseCounts`, `topOcrFailureCause`, `ocrFailureSourceCounts`,
  `topOcrFailureSource`, `topOcrFailureSourceAction`,
  `ocrFailureStageCounts`, `topOcrFailureStage`, and
  `topOcrFailureStageLabel`.
- Added a Firestore document regression proving parser metrics, app-filled
  correction metrics, OCR failure buckets, OCR source buckets, and OCR stage
  buckets survive sanitization.

Verification:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart lib/screens/expenses/data/expense_screen_telemetry.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 213: OCR Recovery Firestore Trace Metrics Documentation Batch

Status: completed.

Goal:
- Document the Firestore-visible scheduled OCR summary trace metrics so future
  Command 1 and sync work knows those fields belong in the existing
  `expenseTelemetrySummaries/{summaryId}` document and must not become a
  separate read-heavy trace collection.

Completed:
- Updated `docs/expense_command_center_ocr_contract.md` with the Firestore
  aggregate scheduler trace metric field list.
- Documented `expenseSummaryQueuedCount`,
  `expenseSummaryOcrContractQueuedCount`,
  `expenseSummaryOcrContractSkippedCount`,
  `expenseSummaryOcrContractSourceCounts`,
  `topExpenseSummaryOcrContractSource`,
  `expenseSummaryOcrContractSkippedReasonCounts`, and
  `topExpenseSummaryOcrContractSkippedReason`.
- Documented that these are safe counts/tokens only and must remain in the
  existing summary document.
- Updated `docs/firebase_sync_schema_spec.md` with the same Firestore metric
  contract and the no-separate-scheduler-trace rule.
- Extended doc guard tests so the Firestore scheduler trace metric contract
  remains documented.

Verification:
- `dart format test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 212: OCR Recovery Firestore Summary Trace Metrics Batch

Status: completed.

Goal:
- Carry the scheduled OCR summary trace metrics added in Pass 211 through the
  Firestore expense telemetry summary document so Command 1 can read them from
  the existing one-document summary path.

Completed:
- Added the scheduled OCR summary trace metric fields to the Firestore expense
  telemetry summary sanitizer allowlist.
- Preserved the one-summary-document upload shape and `rawEventUploadCount: 0`.
- Added Firestore document builder coverage proving
  `expenseSummaryQueuedCount`, OCR contract queued/skipped counts, source
  buckets, top source, skipped-reason buckets, and top skipped reason survive
  sanitization.
- Added bridge queue coverage proving the real pending Firestore summary
  document includes scheduled OCR summary trace metrics.
- Confirmed the queued document still avoids receipt text and private org/path
  leakage in the new scheduler trace metric path.

Verification:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart lib/screens/expenses/data/expense_screen_telemetry.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart test/expense_screen_telemetry_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 211: OCR Recovery Telemetry Summary Trace Metrics Batch

Status: completed.

Goal:
- Promote the scheduled OCR summary queue trace from raw telemetry into
  Command 1-ready aggregate metrics so the admin side can see whether expense
  OCR health summaries are being queued and whether the OCR contract was
  attached or skipped.

Completed:
- Added `expenseSummaryQueuedCount` to the expense telemetry health snapshot.
- Added `expenseSummaryOcrContractQueuedCount` and
  `expenseSummaryOcrContractSkippedCount`.
- Added source buckets through `expenseSummaryOcrContractSourceCounts` and
  `topExpenseSummaryOcrContractSource`.
- Added skipped-reason buckets through
  `expenseSummaryOcrContractSkippedReasonCounts` and
  `topExpenseSummaryOcrContractSkippedReason`.
- Exposed all new scheduler trace metrics through `toCommandCenterMap`.
- Added a regression test proving unrelated sync-pending events are not counted
  as expense OCR summary queue traces and private receipt content is not
  surfaced.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart lib/screens/expenses/data/expense_screen_telemetry_recorder.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 210: OCR Recovery Scheduler Trace Documentation Batch

Status: completed.

Goal:
- Document the privacy-safe local recorder trace created after scheduled OCR
  health summary queueing so future sync, Command 1, and diagnostics work knows
  exactly what can and cannot be recorded.

Completed:
- Updated `docs/expense_command_center_ocr_contract.md` with the scheduler
  recorder trace contract.
- Documented the safe trace metadata fields: `syncState`,
  `expense_summary_queued`, `summaryStatus`, `ocrContractQueued`,
  `ocrContractSource`, and optional `ocrContractSkippedReason`.
- Documented that the trace must not store Firestore path, org id, receipt
  image, raw OCR text, merchant/store names, item descriptions, proof paths, or
  private receipt values.
- Documented that throttled scheduler checks should not create trace events.
- Updated `docs/firebase_sync_schema_spec.md` with the same scheduled trace
  rule.
- Extended doc guard tests so the scheduler trace contract stays documented.

Verification:
- `dart format test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 209: OCR Recovery Scheduler Recorder Trace Batch

Status: completed.

Goal:
- Record a privacy-safe local telemetry trace when the expense summary
  scheduler queues a Command 1 OCR health summary, so later diagnostics can
  tell whether the OCR contract was attached without exposing receipt content
  or spamming throttled scheduler checks.

Completed:
- Added safe telemetry metadata keys for scheduled summary status and OCR
  contract queue status.
- Updated `ExpenseScreenTelemetryRecorder` so successful scheduled summary
  queueing records a local `syncPending` trace.
- The recorder trace stores only safe tokens: `expense_summary_queued`,
  `summaryStatus`, `ocrContractQueued`, `ocrContractSource`, and optional
  `ocrContractSkippedReason`.
- The recorder deliberately does not store the Firestore path or org id in the
  trace event.
- The recorder ignores throttled scheduler checks so ordinary expense events do
  not create noisy trace records during the throttle window.
- Added regression tests proving the recorder stores the queued OCR summary
  trace without receipt content and stores nothing for throttled checks.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/data/expense_screen_telemetry_recorder.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/data/expense_screen_telemetry_recorder.dart lib/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 208: OCR Recovery Scheduler Failure Safety Batch

Status: completed.

Goal:
- Make scheduled expense OCR health uploads observable enough that the app can
  tell whether the scheduler attached the OCR contract, where the contract came
  from, or why it was intentionally skipped.

Completed:
- Extended `ExpenseTelemetrySummaryScheduleResult` with
  `ocrContractQueued`, `ocrContractSource`, and
  `ocrContractSkippedReason`.
- Added an internal scheduled OCR contract resolver that distinguishes explicit
  contracts, rolling local-ledger contracts, deliberate disabled state, and
  unavailable ledger state.
- Preserved the existing throttling behavior and single-summary-document queue
  behavior.
- Extended scheduler tests so rolling local-ledger OCR uploads report
  `ocrContractQueued: true` and `ocrContractSource: rolling_local_ledger`.
- Extended scheduler tests so disabled OCR contract uploads report
  `ocrContractQueued: false`, `ocrContractSource: none`, and
  `ocrContractSkippedReason: ledger_ocr_contract_disabled`.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `flutter test test/expense_screen_telemetry_firestore_bridge_test.dart test/maintainiac_firestore_documents_test.dart test/expense_export_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 207: OCR Recovery Scheduled Upload Documentation Batch

Status: completed.

Goal:
- Document the scheduled OCR health upload path so future Command 1, sync, and
  telemetry work keeps OCR health in the one cost-safe expense summary document
  and understands that the scheduler builds the OCR contract from the rolling
  local ledger.

Completed:
- Updated `docs/expense_command_center_ocr_contract.md` with a scheduled
  summary upload section.
- Documented `ExpenseTelemetrySummaryScheduler.queueIfDue`, the rolling 90-day
  local receipt window, and the `includeLedgerOcrContract` switch.
- Updated `docs/firebase_sync_schema_spec.md` so the Firestore data model
  records the scheduled OCR contract behavior.
- Extended the Command Center OCR contract doc guard to require scheduler,
  rolling-window, and `includeLedgerOcrContract` language.
- Extended the Firestore data model guard so Firebase docs cannot forget the
  scheduler path.

Verification:
- `dart format test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart lib/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 206: OCR Recovery Summary Scheduler Bridge Batch

Status: completed.

Goal:
- Carry the expense OCR Command Center contract through the scheduled telemetry
  summary path so routine background health uploads can include OCR recovery
  health from saved receipts without creating per-receipt admin documents or
  exposing private receipt content.

Completed:
- Extended `ExpenseTelemetrySummaryScheduler.queueIfDue` with an optional
  `commandCenterOcrContract` override for future callers and tests.
- Added automatic rolling ledger OCR contract generation from the local expense
  ledger for scheduled summary uploads.
- Kept the contract inside the existing single
  `expenseTelemetrySummaries/{summaryId}` upload document.
- Added an `includeLedgerOcrContract` switch so non-OCR summary runs can
  deliberately skip the ledger contract.
- Added scheduler regression coverage proving the queued scheduled document
  contains OCR health counts, passes the Firestore OCR contract guard, and does
  not upload private line descriptions.
- Added regression coverage proving the scheduler can skip the OCR contract
  when requested.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart test/expense_screen_telemetry_firestore_bridge_test.dart lib/screens/expenses/data/expense_screen_telemetry_firestore_bridge.dart lib/shared/firebase/maintainiac_firestore_documents.dart`
- `flutter test test/expense_screen_telemetry_firestore_bridge_test.dart test/maintainiac_firestore_documents_test.dart test/expense_export_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 205: OCR Recovery Firestore Contract Guard Batch

Status: completed.

Goal:
- Add a reusable Firestore summary document audit for the expense OCR Command
  Center contract so the actual queued document cannot drift into unsafe paths,
  per-receipt upload shapes, raw event uploads, forbidden private fields, or an
  unsafe nested OCR contract.

Completed:
- Added `expenseTelemetrySummaryOcrContractFindingsFor` to
  `MaintainiacFirestoreDocumentBuilder`.
- The new guard validates the final Firestore draft path, upload shape,
  `rawEventUploadCount`, forbidden private top-level keys, nested OCR contract
  safety, and forbidden OCR-contract upload-shape/raw-event fields.
- Extended Firestore document tests to prove a clean summary has no findings.
- Added a crafted unsafe draft regression that flags a receipt-diagnostics path,
  per-receipt upload shape, raw event upload count, raw OCR text, merchant name,
  and private issue text.
- Extended the expense telemetry bridge queue test so the actual pending upload
  document also passes the Firestore OCR contract guard.

Verification:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart test/expense_export_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 204: OCR Recovery Firestore Contract Documentation Batch

Status: completed.

Goal:
- Document the Firestore handoff shape for the expense OCR Command Center
  contract so future dashboard/sync work keeps OCR health in one privacy-safe
  summary document instead of drifting into per-receipt admin reads/writes.

Completed:
- Expanded `docs/expense_command_center_ocr_contract.md` with the Firestore
  summary bridge path, nested field name, cost-safe upload shape, privacy guard,
  bridge API, and document-builder API.
- Updated `docs/expense_screen_full_design.md` to state that expense OCR
  Command Center health belongs in
  `orgs/{orgId}/expenseTelemetrySummaries/{summaryId}` as
  `commandCenterOcrContract`.
- Updated `docs/firebase_sync_schema_spec.md` to forbid a per-receipt admin OCR
  health collection and require `commandCenterOcrContractFindingsFor` before
  queueing.
- Extended doc guard tests so the OCR contract doc and Firebase specs must keep
  the one-summary-document path, `single_summary_document`, and privacy audit
  language.

Verification:
- `dart format test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 203: OCR Recovery Firestore Summary Bridge Batch

Status: completed.

Goal:
- Carry the privacy-safe OCR recovery contract into the existing expense
  telemetry Firestore summary path without creating per-receipt admin uploads,
  leaking receipt content, or increasing Firestore reads/writes beyond the
  single summary document pattern.

Completed:
- Extended `ExpenseTelemetryFirestoreBridge.queueHealthSummary` with an
  optional `commandCenterOcrContract` argument.
- Extended `MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument`
  to embed a sanitized OCR contract inside the same
  `expenseTelemetrySummaries/{summaryId}` document when provided.
- Reused `ExpenseExportSnapshot.commandCenterOcrContractFindingsFor` before
  Firestore queueing so unsafe contracts are rejected instead of uploaded.
- Preserved the existing `uploadShape: single_summary_document` and
  `rawEventUploadCount: 0` behavior.
- Added regression coverage for the document builder, unsafe contract rejection,
  and the actual upload queue bridge.

Verification:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart lib/screens/expenses/data/expense_screen_telemetry_firestore_bridge.dart test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart lib/screens/expenses/data/expense_screen_telemetry_firestore_bridge.dart test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart test/expense_export_test.dart test/expense_command_center_ocr_contract_doc_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 202: OCR Recovery Command Center Handoff Documentation Batch

Status: completed.

Goal:
- Document the Command 1/admin OCR recovery contract so future dashboard work
  can consume receipt OCR health without guessing, drifting, or exposing private
  receipt content.

Completed:
- Added `docs/expense_command_center_ocr_contract.md` as the handoff source for
  the expense OCR Command Center contract.
- Documented the current schema, privacy scope, content policy, allowed fields,
  field meanings, forbidden content, required privacy guard, rejected examples,
  Command 1 UI guidance, and update checklist.
- Added a documentation guard test proving the handoff doc names the active
  Dart schema/privacy constants, every allowed contract field, and the forbidden
  content categories that must remain out of Command 1.

Verification:
- `dart format test/expense_command_center_ocr_contract_doc_test.dart test/expense_export_test.dart lib/screens/expenses/data/expense_export_models.dart`
- `flutter analyze lib/screens/expenses/data/expense_export_models.dart test/expense_command_center_ocr_contract_doc_test.dart test/expense_export_test.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/expense_export_test.dart test/expense_ledger_store_test.dart test/expense_draft_store_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 201: OCR Recovery Command Center Privacy Regression Batch

Status: completed.

Goal:
- Add a defensive privacy audit around the Command Center OCR contract so future
  export/admin changes cannot quietly add receipt images, raw OCR text, item
  descriptions, merchant details, proof paths, phone numbers, emails, or private
  receipt values to the admin-facing OCR health payload.

Completed:
- Added an explicit allowlist of Command Center OCR contract keys.
- Added a privacy-finding audit for the OCR contract that flags unexpected keys,
  missing required keys, private-looking string values, unsafe map keys,
  negative/invalid numbers, lists, and unsupported values.
- Exposed the audit through `commandCenterOcrContractPrivacyFindings` and a
  static `commandCenterOcrContractFindingsFor` helper so tests and future
  Command 1 wiring can verify payloads before upload/display.
- Added regression coverage proving the current contract is clean and a crafted
  unsafe payload containing merchant/private-store text, line-item-like text,
  local proof paths, and private recovery tokens is rejected.

Verification:
- `dart format lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart`
- `flutter test test/expense_export_test.dart test/expense_ledger_store_test.dart test/expense_draft_store_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 200: OCR Recovery Command Center Contract Batch

Status: completed.

Goal:
- Formalize the privacy-safe OCR recovery payload that Command 1/admin
  surfaces can consume without needing receipt images, raw OCR text, item
  descriptions, merchant details, notes, or private receipt content.

Completed:
- Added a named `commandCenterOcrContract` export payload with explicit schema,
  privacy scope, and content policy markers.
- Included the operational OCR fields Command 1 needs for expense health:
  saved reads, clean reads, review counts, warning counts, source counts,
  recovery action counts, recovery target counts, top check, and top safe
  issue/action.
- Embedded the contract into the expense export manifest while keeping the
  existing manifest OCR fields for compatibility.
- Added regression coverage proving the contract exposes OCR health aggregates
  and does not leak private store tokens, line-item descriptions, or false
  recovery action tokens from healthy reads.

Verification:
- `dart format lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart`
- `flutter test test/expense_export_test.dart test/expense_ledger_store_test.dart test/expense_draft_store_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 199: OCR Recovery Recap Export Handoff Batch

Status: completed.

Goal:
- Carry the same privacy-safe OCR read recap concepts into expense export
  manifests so exported records keep operational OCR health context without
  embedding raw receipt content.

Completed:
- Added manifest fields for `ocrReadStatus`, `ocrReadSummary`,
  `ocrReadsSaved`, `ocrCleanReadCount`, and `ocrTopCheck`.
- Built export recap summaries from existing sanitized OCR review issue/action
  surfaces, not raw OCR text, receipt images, item descriptions, or private
  merchant details.
- Expanded export coverage with both a receipt needing review and a clean OCR
  read so the manifest proves saved reads, clean reads, review count, and top
  check.
- Fixed healthy saved OCR reads so they no longer backfill false recovery
  actions such as retaking a photo just because the OCR source was `photo`.
- Added regression coverage proving clean OCR reads do not add recovery action
  tokens to manifest aggregates.

Verification:
- `dart format lib/screens/expenses/data/expense_receipt_ocr_review.dart lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_ocr_review.dart lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart`
- `flutter test test/expense_export_test.dart test/expense_ledger_store_test.dart test/expense_receipt_detail_ocr_review_test.dart test/expense_draft_store_test.dart`

### Receipt Camera Reopen Pass 198: OCR Recovery Range Recap Batch

Status: completed.

Goal:
- Extend receipt OCR recovery recap from the selected day to the active expense
  recap range so the user can see receipt read health across week, month,
  90-day, and year-to-date views.

Completed:
- Added range-based OCR recap construction from the ledger and selected
  `ExpenseDateRange`.
- Reused the same privacy-safe read status and recovery hint rules for day and
  range summaries.
- Added `Receipt Reads` rows to the expense recap panel: status, reads saved,
  needs review, read summary, and top check.
- Hardened recap row layout so long read-summary text cannot overflow the
  screen.
- Expanded widget coverage to switch from Daily to Weekly and verify the range
  recap includes receipts outside the selected day while staying privacy-safe.

Verification:
- `dart format lib/screens/expenses/calendar/expense_calendar_models.dart lib/screens/expenses/calendar/expense_day_screen.dart lib/screens/expenses/calendar/expense_day_summary_sections.dart test/expense_receipt_detail_ocr_review_test.dart`
- `flutter analyze lib/screens/expenses/calendar/expense_calendar_models.dart lib/screens/expenses/calendar/expense_day_screen.dart lib/screens/expenses/calendar/expense_day_summary_sections.dart test/expense_receipt_detail_ocr_review_test.dart`
- `flutter test test/expense_receipt_detail_ocr_review_test.dart test/expense_ledger_store_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 197: OCR Recovery Day Recap Batch

Status: completed.

Goal:
- Add a day-level receipt read health recap to the expense calendar so OCR
  review problems are visible before the user opens individual saved receipts.

Completed:
- Added `_CalendarOcrDayRecap` to summarize selected-day receipt OCR health
  from existing calendar receipt entries.
- Counted total receipts, saved receipt reads, reads needing review, clean
  reads, and the top safe recovery hint for the day.
- Added a compact `Receipt read health` panel under the calendar day controls.
- Kept the recap privacy-safe by using already-sanitized calendar OCR status
  and recovery hint labels instead of raw OCR text, receipt images, merchant
  OCR content, totals, or internal recovery tokens.
- Expanded widget/static coverage for the day recap and calendar OCR summary
  path.

Verification:
- `dart format lib/screens/expenses/calendar/expense_calendar_models.dart lib/screens/expenses/calendar/expense_day_screen.dart lib/screens/expenses/calendar/expense_day_summary_sections.dart test/expense_receipt_detail_ocr_review_test.dart`
- `flutter analyze lib/screens/expenses/calendar/expense_calendar_models.dart lib/screens/expenses/calendar/expense_day_screen.dart lib/screens/expenses/calendar/expense_day_summary_sections.dart test/expense_receipt_detail_ocr_review_test.dart`
- `flutter test test/expense_receipt_detail_ocr_review_test.dart test/expense_ledger_store_test.dart`

### Receipt Camera Reopen Pass 196: OCR Recovery Calendar Summary Batch

Status: completed.

Goal:
- Surface saved receipt OCR health from the expense calendar day entries so the
  user can spot receipts needing read review without opening each saved receipt.

Completed:
- Added privacy-safe OCR status and recovery hint fields to the calendar
  receipt data model.
- Added a compact one-line OCR summary to calendar day receipt cards when OCR
  metadata exists, such as `Read needs review: Check long receipt overlap`.
- Derived the recovery hint from the same safe Command Center issue text used
  elsewhere, avoiding raw OCR text, receipt images, private values, and internal
  recovery tokens.
- Added widget coverage proving the calendar day entry shows the safe summary
  and does not leak recovery tokens or receipt content.

Verification:
- `dart format lib/screens/expenses/calendar/expense_calendar_models.dart lib/screens/expenses/calendar/expense_day_entries.dart test/expense_receipt_detail_ocr_review_test.dart`
- `flutter analyze lib/screens/expenses/calendar/expense_calendar_models.dart lib/screens/expenses/calendar/expense_day_entries.dart test/expense_receipt_detail_ocr_review_test.dart`
- `flutter analyze lib/screens/expenses/calendar/expense_calendar_models.dart lib/screens/expenses/calendar/expense_day_entries.dart test/expense_receipt_detail_ocr_review_test.dart lib/screens/expenses/data/expense_ledger_store.dart test/expense_ledger_store_test.dart`
- `flutter test test/expense_receipt_detail_ocr_review_test.dart test/expense_ledger_store_test.dart`

### Receipt Camera Reopen Pass 195: OCR Recovery Saved Receipt Regression Batch

Status: completed.

Goal:
- Prove saved expense receipts keep OCR recovery detail after local persistence
  and expose privacy-safe aggregate recovery counts for future health surfaces.

Completed:
- Added saved receipt OCR review helpers on `ExpenseLedgerController` for
  receipts needing OCR review, recovery action counts, recovery target counts,
  top recovery action, and top recovery target.
- Built those aggregate counts from the sanitized `commandCenterSummary` so
  raw receipt content and unsafe recovery tokens cannot leak into app health
  surfaces.
- Expanded the saved receipt OCR metadata regression to verify recovery action,
  recovery target, recovery summary, Command Center summary fields, and ledger
  aggregate counts.
- Added a privacy regression where an unsafe recovery action is stored locally
  but does not appear in aggregate recovery counts.

Verification:
- `dart format lib/screens/expenses/data/expense_ledger_store.dart test/expense_ledger_store_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_ledger_store.dart test/expense_ledger_store_test.dart lib/screens/expenses/data/expense_receipt_ocr_review.dart`
- `flutter test test/expense_ledger_store_test.dart test/expense_draft_store_test.dart test/expense_export_test.dart test/expense_receipt_detail_ocr_review_test.dart`

### Receipt Camera Reopen Pass 194: OCR Recovery Detail Screen Batch

Status: completed.

Goal:
- Show saved receipt OCR recovery context on the receipt detail screen in plain
  language, without exposing raw OCR text, receipt images, or developer tokens.

Completed:
- Added a compact OCR recovery detail block to the saved receipt OCR review
  panel.
- Converted persisted recovery action and target tokens into user-facing labels
  such as `Check overlap` and `Long receipt overlap`.
- Kept the existing warning, issue, action, and chip summary intact so saved
  receipt details still explain what happened and what to check.
- Updated saved receipt detail widget coverage to verify the recovery labels
  appear and raw recovery tokens do not leak into the UI.

Verification:
- `dart format lib/screens/expenses/calendar/expense_receipt_detail_info.dart test/expense_receipt_detail_ocr_review_test.dart`
- `flutter analyze lib/screens/expenses/calendar/expense_receipt_detail_info.dart test/expense_receipt_detail_ocr_review_test.dart`
- `flutter test test/expense_receipt_detail_ocr_review_test.dart test/expense_draft_store_test.dart test/expense_export_test.dart`

### Receipt Camera Reopen Pass 193: OCR Recovery Export Summary Batch

Status: completed.

Goal:
- Carry privacy-safe OCR recovery action/target data into expense exports so
  exported receipt records and manifests keep operational recovery context
  without embedding receipt images or raw OCR text.

Completed:
- Added `ocr_recovery_action` and `ocr_recovery_target` columns to the receipt
  export CSV.
- Populated those columns from the sanitized `ExpenseReceiptOcrReview`
  Command Center summary fields.
- Added `ocrRecoveryActionCounts`, `ocrRecoveryTargetCounts`,
  `ocrTopRecoveryAction`, and `ocrTopRecoveryTarget` to the export manifest.
- Kept export recovery data token-based and privacy-safe.
- Updated export regression coverage for CSV headers, CSV values, manifest
  counts, and top recovery action/target fields.

Verification:
- `dart format lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart lib/screens/expenses/data/expense_receipt_ocr_review.dart`
- `flutter test test/expense_export_test.dart test/expense_draft_store_test.dart test/expense_ocr_failure_diagnostics_test.dart`

### Receipt Camera Reopen Pass 192: OCR Recovery Detail Persistence Batch

Status: completed.

Goal:
- Persist privacy-safe OCR recovery details with receipt OCR review snapshots so
  drafts, saved receipts, backups, exports, and future Command Center views can
  keep the user's next-step context without storing private receipt content.

Completed:
- Added `recoveryAction`, `recoveryTarget`, and `recoverySummary` to
  `ExpenseReceiptOcrReview`.
- `fromDiagnostics` now derives recovery details from the primary OCR warning
  kind and source.
- `fromMap` now backfills recovery details for older saved drafts/receipts that
  do not yet have the new fields.
- Command Center summaries now include sanitized recovery action/target tokens.
- Added a whitelist-based recovery token guard so arbitrary snake_case strings
  cannot leak into Command Center summary fields.
- Firestore receipt backups now include recovery action, recovery target, and a
  safe recovery summary using the sanitized Command Center action text.
- Updated draft and Firestore backup tests for recovery persistence, backfill,
  sanitizing, and privacy-safe summaries.

Verification:
- `dart format lib/screens/expenses/data/expense_receipt_ocr_review.dart lib/screens/expenses/data/expense_firestore_documents.dart test/expense_draft_store_test.dart test/expense_firestore_documents_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_ocr_review.dart lib/screens/expenses/data/expense_firestore_documents.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_draft_store_test.dart test/expense_firestore_documents_test.dart`
- `flutter test test/expense_draft_store_test.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_ocr_failure_diagnostics_test.dart`

Note:
- `flutter test test/expense_firestore_documents_test.dart` is currently blocked
  by unrelated work-supplies catalog compile errors involving duplicate
  `_variants` declarations and invalid spreads in fencing/masonry catalog files.
  The focused analyzer covering the Firestore document builder passed.

### Receipt Camera Reopen Pass 191: OCR Recovery Summary Surface Batch

Status: completed.

Goal:
- Surface a plain next-step recovery summary in the OCR review area so users can
  tell what to do after OCR trouble without reading developer-style diagnostics.

Completed:
- Added a `Next step:` sentence to the OCR review detail area.
- The next-step summary changes by OCR warning kind and receipt source:
  missing proof, no readable text, skipped sources, duplicate/overlap,
  missing sections, PDF safety/size/readability, plugin unavailable, photo
  quality, photo read failure, PDF read failure, and unknown OCR warnings.
- Generic no-warning/no-readable-text failures now fall back to the source type:
  photo, PDF, saved text, mixed sources, or no proof.
- Kept the recovery text privacy-safe and action-oriented: retake, add a
  missing section, scan with photos, paste cleaner text, attach safe proof, or
  continue by hand.
- Updated the assisted receipt review guard to preserve the recovery helper and
  representative recovery copy.

Verification:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 190: OCR Recovery Telemetry Shape Batch

Status: completed.

Goal:
- Give the expense OCR failure diagnostics privacy-safe recovery labels that can
  later power Command Center counts without exposing receipt text, images,
  vendor names, totals, addresses, or customer content.

Completed:
- Extended OCR failure diagnostic evidence with `recovery_*` and `target_*`
  tokens.
- Added source-specific fallback recovery actions for generic/no-warning OCR
  failures: photo, PDF, saved text, mixed sources, and missing proof.
- Added warning-specific recovery actions for missing sections, overlap,
  unsafe/large/unreadable PDFs, photo quality, photo read failures, PDF read
  failures, plugin unavailable, and unknown OCR warnings.
- Kept the evidence shape compact and non-content: warning kind, severity,
  source, read/skipped counts, recovery action, and recovery target only.
- Added focused diagnostic tests for photo quality, PDF safety, generic
  no-readable-text, missing sections, prioritized PDF/photo read failures, and
  source-specific fallback recovery.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/screens/expenses/data/expense_ocr_failure_diagnostics.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart test/expense_ocr_failure_diagnostics_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/screens/expenses/data/expense_ocr_failure_diagnostics.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart test/expense_ocr_failure_diagnostics_test.dart`
- `flutter test test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`

### Receipt Camera Reopen Pass 189: OCR Source Recovery Action Drilldown Batch

Status: completed.

Goal:
- Make app-assisted OCR recovery guidance more specific for the receipt source
  type without collecting or exposing private receipt content.

Completed:
- Replaced the loose failure/recovery strings with `_ReceiptReadRecoveryAdvice`
  so each OCR failure has a source-specific lead, a full on-screen recovery
  action, and a shorter returned warning.
- Added separate recovery guidance for single receipt photos, multi-photo/long
  receipts, PDF-only proofs, saved receipt text, mixed proof sources, and
  unknown proof states.
- Multi-photo failures now tell the user to check photo order and add a clearer
  missing section instead of giving the same generic retake advice as a single
  photo.
- Single-photo failures now mention brighter light, full receipt framing, and
  adding another photo for long receipts.
- PDF/text/mixed-source failures now steer users toward the best next proof
  source while still allowing manual continuation.
- Updated receipt-flow regression guards for the recovery-advice object,
  source-specific action copy, and short-action handoff.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`

### Receipt Camera Reopen Pass 188: OCR Source Failure Specificity Batch

Status: completed.

Goal:
- Make OCR read failures explain which kind of receipt source failed and what
  broad recovery path applies, without exposing private receipt content.

Completed:
- Added `_receiptReadFailureLead` for photo-only, PDF-only, saved-text-only,
  mixed-source, and unknown-source read failures.
- Prefixed OCR exceptions and no-text OCR failures with source-specific plain
  language before the recovery action.
- Kept recovery actions source-specific and privacy-safe: keep proof attached,
  add a clearer receipt photo, retake, paste cleaner text, or enter manually.
- Updated focused regression guards so the receipt flow no longer protects the
  older vague failure wording.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`

### Receipt Camera Reopen Pass 187: OCR Source Readability Handoff Batch

Status: completed.

Goal:
- Carry photo quality/readability evidence into the OCR handoff status so the
  user understands what the app is reading without exposing private receipt
  content.

Completed:
- Added a privacy-safe OCR source quality summary to the post-review read
  status message.
- The status now distinguishes unmeasured photo quality, readable OCR source
  quality, and OCR sources that may need review.
- For stitched long receipts that become one OCR image, the quality summary uses
  the weakest source-section quality as the handoff warning.
- Kept the handoff message limited to proof count, OCR source count, quality
  score/issue, and stitch decision; no receipt text, vendor, address, total, or
  image content is surfaced.
- Added focused regression coverage for the new quality handoff helper and
  status message shape.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Note:
- A broader `test/receipt_ocr_service_test.dart` run still has an unrelated PDF
  expectation failure around PDF overflow wording. Pass 187 did not modify PDF
  OCR service behavior.

### Receipt Camera Reopen Pass 186: Camera Exposure Evidence Summary Batch

Status: completed.

Goal:
- Make camera capture diagnostics explain brightness/exposure behavior without
  storing private receipt content.

Completed:
- Added `hasUnderexposedLiveFrame` to capture evidence so diagnostics can
  distinguish truly dark previews from previews that are merely darker than
  ideal.
- Added `Live preview was darker than ideal` to the brightness summary.
- Added `exposureSummaryLabel` so evidence can say whether the selected shot
  used native auto-exposure baseline or a bracketed exposure candidate.
- Added model tests for dark, underexposed, native-baseline, and bracketed
  exposure summaries.
- Added string contract coverage so the camera evidence surface keeps these
  privacy-safe diagnostics.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 185: Camera Brightness Recovery Copy Batch

Status: completed.

Goal:
- Align live camera guidance, assisted capture feedback, and review guidance so
  dim-but-usable receipt photos are handled differently from truly too-dark
  photos.

Completed:
- Added a live camera status label for underexposed receipt frames:
  `Brighter helps`.
- Added live feedback that says the receipt is readable but brighter light will
  help bottom text.
- Added assisted-capture feedback titled `Could Be Brighter` for photos that
  may work but need better light for lower receipt lines.
- Kept hard `Too Dark` guidance separate for genuinely dark photos.
- Added focused regression coverage for the new live, assisted, and review copy.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart lib/shared/widgets/receipt_capture/receipt_camera_feedback.dart lib/shared/widgets/receipt_capture/receipt_camera_assist.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart lib/shared/widgets/receipt_capture/receipt_camera_feedback.dart lib/shared/widgets/receipt_capture/receipt_camera_assist.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 184: Camera Capture Brightness Comparison Batch

Status: completed.

Goal:
- Make the receipt camera detect and prefer against app-captured photos that are
  darker than ideal, even when they are not dark enough to be a hard blocker.

Completed:
- Added an `isUnderexposedForReceipt` quality band below the existing hard
  `isTooDark` blocker.
- Added review guidance that tells the user a receipt is readable but darker
  than ideal and calls out dim bottom text.
- Kept blur/sharpness priority above the new underexposed warning so a blurry
  photo is not mislabeled as only a brightness issue.
- Added the same underexposed signal to live camera analysis.
- Updated best-shot candidate ordering so an underexposed receipt candidate
  loses to a similarly readable, better-lit candidate before pixel count can
  decide.
- Updated exposure bracketing so slightly underexposed live frames can trigger
  a bounded positive exposure candidate.
- Added focused regression coverage for the threshold, ranking signal,
  guidance, and exposure-bracket trigger.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart lib/shared/widgets/receipt_capture/receipt_camera_capture.dart lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart lib/shared/widgets/receipt_capture/receipt_camera_capture.dart lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 183: Camera And Review Exit Hardening Batch

Status: completed.

Goal:
- Make the receipt review back/exit path behave like a normal professional app
  instead of trapping the user while receipt photos are being prepared.

Completed:
- Changed photo review exit so it no longer blocks Back/Close with a
  "leave after this finishes" message while `_savingPhotos` is true.
- Stopped the review save state before closing when the user backs out during
  receipt photo preparation.
- Preserved the crop safety guard so the user must finish or cancel crop before
  leaving an active crop operation.
- Kept the existing async save safety model: save work already checks
  `_closingReview` and returns without handing off stale results.
- Updated regression coverage to prove the old blocking message is gone and
  save state is stopped before review close.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 182: Receipt Review Action Label Polish Batch

Status: completed.

Goal:
- Keep compact receipt-review actions short enough for phone screens while
  avoiding vague/developer-style labels.

Completed:
- Changed compact long-receipt `Add Next` to `Add Section` so the action maps
  to the next receipt section.
- Changed compact long-receipt `Arrange` to `Order` so the user knows it opens
  photo ordering.
- Changed compact proof-size actions from `Save Size` / `Save Space` to
  `Proof Size`, matching the saved proof image concept used elsewhere.
- Kept the full long-receipt rail labels unchanged where there is room:
  `Add Next Photo`, `Photo Order`, `Match Photos`, and `Saved Proof Size`.
- Updated focused label contract coverage.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 181: Receipt Review Multi-Photo Density Guard Batch

Status: completed.

Goal:
- Keep long-receipt/multi-photo review usable on tight screens without stacking
  thumbnails and the full action rail into a cramped control panel.

Completed:
- Added a compact multi-photo action row for tight bottom-control constraints.
- Kept the compact row focused on the essential multi-photo actions:
  `Add Next`, `Arrange`, `Match`, and `Save Size`.
- Kept the full multi-photo action rail available when there is enough room.
- Preserved the thumbnail strip, with compact height already guarded by Pass 180.
- Added focused regression coverage proving compact and full multi-photo action
  paths are separate.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 180: Receipt Review Bottom Sheet Overflow Guard Batch

Status: completed.

Goal:
- Keep the post-capture review controls from becoming an overflowing mini-screen
  on shorter phones while preserving the recovery actions users need.

Completed:
- Added a `LayoutBuilder`-based compact-control guard for the preview tray.
- Limited the preview status text to one line when the bottom-control height is
  tight.
- Collapsed the quality-warning strip by hiding its detail text in compact
  mode, while keeping `Retake`, `Adjust`, and `Add Photo` visible.
- Reduced multi-photo thumbnail strip height under compact constraints.
- Added focused regression checks for the compact threshold, compact status
  text, thumbnail height guard, and compact warning-strip behavior.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 179: Receipt Review Quality Warning Action Batch

Status: completed.

Goal:
- Make questionable one-photo review states actionable without forcing the user
  to hunt through menus or accept a weak photo.

Completed:
- Added `Add Photo` directly to the photo-quality recovery strip so the user can
  add another receipt section when a photo is blurry, dark, glary, or incomplete.
- Renamed the quality recovery crop action to `Adjust` so it covers crop,
  straighten, and rotation more plainly.
- Kept `Retake`, `Adjust`, and `Add Photo` available inside the warning state
  without showing the full long-receipt action rail.
- Disabled the new add-photo recovery action while the camera is already
  opening, matching the existing retake guard.
- Added focused regression coverage that proves warning recovery exposes the
  add-photo action and does not fall back to ambiguous conditional labels.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 178: Receipt Review Single-Photo Action Density Batch

Status: completed.

Goal:
- Make one-photo receipt review feel like a focused camera workflow instead of
  a long-receipt batch manager.

Completed:
- Split single-photo preview actions away from the long-receipt action rail.
- Added a dedicated single-photo action row with compact labeled actions:
  `Add Photo`, `Retake`, `Adjust`, and `Save Space`.
- Kept long-receipt photo order, matching, and add-next-photo controls scoped to
  multi-photo review only.
- Kept quality-warning recovery focused on retake/crop help instead of stacking
  the full action rail underneath it.
- Reduced the single-photo preview control cap from 112 pixels to 108 pixels so
  the receipt image stays more visible.
- Added focused regression coverage for the single-photo action row and the
  long-receipt-only action rail split.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 177: Receipt Review Preview Footprint Batch

Status: completed.

Goal:
- Keep the receipt photo dominant after capture by reducing the bottom-control
  footprint and removing fake chooser UI when there is only one receipt photo.

Completed:
- Reduced the review bottom-control cap from 20% to 18% of screen height.
- Lowered absolute control-height caps for preview, crop, photo order,
  stitching, and data-saver modes.
- Reduced receipt-image bottom padding from controls plus 8 pixels to controls
  plus 4 pixels.
- Reused the calculated image padding for stitch pair previews instead of a
  hard-coded 154-pixel inset.
- Removed the one-photo thumbnail strip from preview mode because one photo has
  nothing to choose.
- Kept thumbnails available for multi-photo long receipts, where they actually
  help the user understand order and sections.
- Removed the unused compact thumbnail branch so the review controls have one
  simpler multi-photo layout path.

Verification:
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 176: Receipt Review Long-Receipt Control Layout Batch

Status: completed.

Goal:
- Make multi-photo/long-receipt review controls read like a professional
  receipt flow instead of generic tooling, while keeping the bottom controls
  compact.

Completed:
- Updated multi-photo preview copy so it reminds the user that Photo 1 should
  be the top of the receipt and the next photo should be the next section.
- Changed ambiguous `Order` and `Match` labels to `Photo Order` and
  `Match Photos`.
- Changed tool-mode add-photo copy to `Add Next Section` for long receipts.
- Made stitch pair navigation say `Previous Pair` / `Next Pair` and show the
  actual photo pair being matched.
- Changed stitch success/fallback labels to `Combined Receipt Ready` and
  `Safe Fallback Ready`.
- Added order-mode copy that says Next reads photos in the displayed order.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 175: Capture Brightness And Exit Regression Batch

Status: completed.

Goal:
- Reduce camera preview/capture lifecycle races by making async capture work
  stop when the route is closing or when the active camera controller has been
  cleared/swapped.

Completed:
- Added an active-controller guard that requires the widget to still be
  mounted, the camera not to be closing, the same controller instance to still
  be active, and the controller to still be initialized.
- Guarded manual and assisted capture loops before/after focus, exposure,
  shot gaps, and result handoff.
- Prevented `_takeReceiptPhoto` from running when the camera is already
  closing.
- Kept exposure restoration best-effort only while the same controller is
  active.
- Added a focused regression guard proving the capture pipeline checks the
  active controller identity before continuing.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 174: OCR Summary Privacy Regression Batch

Status: completed.

Goal:
- Prove Command 1-safe OCR summaries cannot leak raw receipt content, vendor
  text, customer text, phone numbers, addresses, totals, invoice numbers, or
  local proof paths even if OCR warning copy is constructed incorrectly.

Completed:
- Hardened `ExpenseReceiptOcrReview.commandCenterSummary` so the admin-facing
  summary uses safe issue/action text when warning labels or instructions look
  private.
- Added safe fallback labels and actions for known OCR warning kinds so Command
  1 still gets useful failure direction without exposing receipt content.
- Added a `privacyScope` marker to the OCR summary payload.
- Added a regression test that injects private store/address/phone/path/amount
  text into OCR warning fields and proves the Command 1 summary does not echo it.

Verification:
- `dart format lib/screens/expenses/data/expense_receipt_ocr_review.dart test/expense_draft_store_test.dart`

### Receipt Camera Reopen Pass 173: OCR Summary Recovery Contract Batch

Status: completed.

Goal:
- Make sure OCR Command 1 summary metadata survives interruption/recovery
  paths, not just the first happy-path receipt scan.

Completed:
- Added draft recovery coverage proving OCR source survives save/load and is
  present in the Command 1 summary.
- Added saved ledger coverage proving source-skipped OCR review data keeps the
  source and action after receipt save/load.
- Updated the Command 1 summary contract test to include the safe OCR source.

Verification:
- `flutter test test/expense_draft_store_test.dart test/expense_ledger_store_test.dart test/expense_screen_telemetry_test.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_ocr_review.dart test/expense_draft_store_test.dart test/expense_ledger_store_test.dart`
- `git diff --check`

Known external blocker:
- The full broad receipt/expense sweep remains blocked by unrelated missing
  work-supplies generated catalog files.

Next camera-only focus:
- Add privacy regression checks across OCR summaries to prove raw OCR, receipt
  totals/text, vendor/customer text, and local proof paths do not leak into
  Command 1-safe summary payloads.

### Receipt Camera Reopen Pass 172: OCR Summary Firestore Alignment Batch

Status: completed.

Goal:
- Keep Firestore receipt backup OCR summaries aligned with the local
  telemetry/export health shape while preserving privacy boundaries.

Completed:
- Added the safe OCR `source` token to nested Firestore
  `commandCenterSummary` payloads.
- Kept raw OCR text, local proof paths, imported text, and raw line text out of
  backup documents.
- Added Firestore document regression coverage proving the nested Command 1
  OCR summary includes source plus primary issue/action.

Verification:
- `flutter analyze lib/screens/expenses/data/expense_firestore_documents.dart test/expense_firestore_documents_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_result_test.dart`
- `git diff --check`

Known external blocker:
- Firestore/export tests that import the broader expense ledger still cannot
  load while unrelated work-supplies generated catalog files are missing.

Next camera-only focus:
- Add a recovery contract around saved OCR summaries so draft resume, saved
  receipt detail, export, and Firestore backup stay consistent.

### Receipt Camera Reopen Pass 171: OCR Failure Summary Export Alignment Batch

Status: completed.

Goal:
- Keep local export manifests aligned with the OCR health data Command 1 will
  need, without embedding raw OCR text or receipt images.

Completed:
- Added `ocrSourceCounts` and `ocrTopSource` to expense export manifests.
- Added `ocrTopPrimaryAction` so exported OCR health summaries include both
  the top issue and the next action.
- Reused saved per-receipt OCR review metadata instead of adding private
  receipt content to exports.
- Added export manifest regression coverage for OCR source and action fields.

Verification:
- `flutter test test/expense_export_test.dart test/expense_screen_telemetry_test.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart`

Known external blocker:
- The wider receipt/expense sweep is still blocked by unrelated work-supplies
  catalog compile errors in `lib/screens/work_supplies/data`.

Next camera-only focus:
- Align Firestore OCR command summaries with the export/telemetry summary
  shape so backup mirrors and Command 1 dashboards read the same health facts.

### Receipt Camera Reopen Pass 170: OCR Failure Stage Summary Batch

Status: completed.

Goal:
- Let Command 1 separate OCR failures by pipeline stage so app health can show
  whether problems happen before OCR starts, during photo OCR, during PDF OCR,
  or after attachment read before parser handoff.

Completed:
- Added `ocrFailureStageCounts` to expense telemetry health snapshots.
- Added `topOcrFailureStage` and `topOcrFailureStageLabel` to the Command 1
  expense telemetry map.
- Extended OCR summary coverage to prove photo/PDF stage counts are separated
  and unrelated save failures do not pollute OCR stage health.

Verification:
- `flutter test test/expense_screen_telemetry_test.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`

Known external blocker:
- The broader receipt/expense sweep currently fails in the unrelated
  work-supplies/inventory catalog area because
  `lib/screens/work_supplies/data/work_supply_catalog_sizes.dart` is missing
  and search helpers are duplicated. This pass does not modify that area.

Next camera-only focus:
- Align OCR failure summary fields with export/backup payloads so local-first
  diagnostics and Command 1 data remain consistent.

### Receipt Camera Reopen Pass 169: OCR Failure Source Action Drilldown Batch

Status: completed.

Goal:
- Make the OCR source summary actionable so Command 1 can show different
  investigation paths for photo, PDF, imported text, missing source, and
  unknown-source OCR failures.

Completed:
- Added `topOcrFailureSourceAction` to the Command 1 expense telemetry map.
- Added photo-source guidance that points to receipt camera focus, exposure,
  crop coverage, long-receipt section order, and decode failures.
- Added PDF-source guidance for safety checks, file size, rendering, page
  extraction, and PDF-to-image conversion.
- Kept the source action derived from aggregate safe source tokens only.

Verification:
- `flutter test test/expense_screen_telemetry_test.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Add OCR failure stage summaries so Command 1 can separate before-read,
  photo-read, PDF-read, and post-read/parser-handoff failure clusters.

### Receipt Camera Reopen Pass 168: OCR Failure Source Metadata Coverage Batch

Status: completed.

Goal:
- Let Command 1 separate receipt OCR failure patterns by safe OCR source
  without storing receipt images, receipt text, customer data, or vendor names.

Completed:
- Added `ocrFailureSourceCounts` to expense telemetry health snapshots.
- Added `topOcrFailureSource` for the dominant source behind OCR failures.
- Derived source counts from privacy-safe diagnostic evidence such as
  `source_photo` and `source_pdf`.
- Added regression coverage proving OCR source counts include photo/PDF OCR
  failures and ignore unrelated save failures.

Verification:
- `flutter test test/expense_screen_telemetry_test.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Add source-aware Command 1 drilldown actions so photo OCR failures, PDF OCR
  failures, and unknown-source failures point to different investigation paths.

### Receipt Camera Reopen Pass 167: OCR Failure Cause Action Coverage Batch

Status: completed.

Goal:
- Make every receipt OCR failure cause that reaches Command 1 produce a
  specific, plain next action instead of vague generic OCR guidance.

Completed:
- Added explicit Command 1 actions for possible missing receipt sections,
  receipt photo overlap, duplicate receipt text, and unknown OCR failures.
- Split overlap guidance from duplicate-text guidance so long-receipt stitch
  problems and duplicate suppression problems are easier to distinguish.
- Added regression coverage for every OCR failure cause emitted by
  `ExpenseOcrFailureDiagnostics`.
- Verified OCR action guidance remains privacy-safe and does not require raw
  receipt text, images, vendor names, or customer content.

Verification:
- `flutter test test/expense_screen_telemetry_test.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Carry OCR source metadata into failure telemetry summaries so Command 1 can
  separate photo/PDF/pasted-text failure patterns without private content.

### Receipt Camera Reopen Pass 166: OCR Failure Telemetry Command Summary Batch

Status: completed.

Goal:
- Give Command 1 a direct OCR failure cause summary instead of forcing it to
  infer OCR health from the full expense failure list.

Completed:
- Added `ocrFailureCauseCounts` to expense telemetry health snapshots.
- Added `topOcrFailureCause` for the leading OCR problem on the current
  telemetry window.
- Exposed both fields in the Command 1 map while keeping the payload
  privacy-safe and receipt-content-free.
- Added regression coverage proving OCR cause counts include receipt OCR
  failures and ignore unrelated save/parser failures.

Verification:
- `flutter test test/expense_screen_telemetry_test.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Make sure every OCR failure cause that can reach Command 1 has a plain,
  specific, non-vague recommended action.

### Receipt Camera Reopen Pass 165: Receipt OCR Failure Diagnostics Regression Batch

Status: completed.

Goal:
- Lock OCR failure diagnostics to the shared warning-priority stack so the
  app records the exact failed stage even when raw warning text arrives in a
  less useful order.

Completed:
- Added regression coverage proving PDF read failures outrank duplicate-text
  review warnings for confirmed OCR failure diagnostics.
- Added regression coverage proving photo read failures outrank review-only
  photo quality and duplicate-text warnings.
- Verified diagnostics evidence keeps privacy-safe command-center facts:
  warning kind, OCR source, severity, read count, and skipped count only.
- Kept the app on the existing ML Kit OCR plus Maintainiac parser architecture;
  this pass does not build OCR from scratch or add maintenance parsing.

Verification:
- `flutter test test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_ocr_failure_diagnostics.dart test/expense_ocr_failure_diagnostics_test.dart`

Next camera-only focus:
- Carry the exact OCR failure cause into telemetry/Command 1 summaries so
  abandoned or failed receipt sessions can show the actual failed stage.

### Receipt Camera Reopen Pass 164: Receipt OCR Health Summary Tests Batch

Status: completed.

Goal:
- Add direct coverage for compact OCR health summary helpers so local saved
  records, exports, Firestore summaries, and Command 1-ready data stay aligned.

Completed:
- Added a focused privacy-safe Command 1 OCR summary test.
- Added healthy OCR summary default coverage.
- Added empty OCR review summary default coverage.
- Verified the compact summary does not expose raw receipt text.
- Re-ran export and Firestore summary tests to keep the summary contract
  aligned across local-first and backup surfaces.

Verification:
- `flutter test test/expense_draft_store_test.dart test/expense_export_test.dart test/expense_firestore_documents_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_ocr_review.dart lib/screens/expenses/data/expense_export_models.dart lib/screens/expenses/data/expense_firestore_documents.dart test/expense_draft_store_test.dart test/expense_export_test.dart test/expense_firestore_documents_test.dart`

Next camera-only focus:
- Add regression coverage proving OCR failure diagnostics use the same
  prioritized warning stack as review, save, export, and Command 1 summaries.

### Receipt Camera Reopen Pass 163: Receipt Export Manifest OCR Health Batch

Status: completed.

Goal:
- Add aggregate OCR health data to expense export manifests so export packages
  summarize receipt OCR review burden without exposing receipt contents.

Completed:
- Added total OCR warning counts to export manifests.
- Added blocking, partial, and review warning bucket counts to export manifests.
- Added primary OCR warning kind counts to export manifests.
- Added top primary OCR issue to export manifests.
- Added export and end-to-end regression tests proving OCR health aggregates and
  new CSV columns are present without raw OCR text.

Verification:
- `flutter test test/expense_export_test.dart test/receipt_end_to_end_regression_matrix_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart test/receipt_end_to_end_regression_matrix_test.dart`

Next camera-only focus:
- Add focused tests around the compact OCR health summary helpers so local
  saved records, exports, Firestore summaries, and Command 1-ready telemetry
  stay aligned as the receipt system grows.

### Receipt Camera Reopen Pass 162: OCR Warning Export Summary Batch

Status: completed.

Goal:
- Add privacy-safe primary OCR issue/action fields to receipt export rows so
  user exports and admin-safe summaries agree on OCR health without embedding
  raw receipt text.

Completed:
- Added `ocr_primary_warning_kind`, `ocr_primary_issue`, and
  `ocr_primary_action` columns to receipt export CSV rows.
- Wired those columns to the same compact OCR summary helpers used by saved
  receipt detail and Firestore backup summaries.
- Added export tests proving primary warning kind, issue, and action appear in
  receipt exports while existing OCR count/status fields remain intact.

Verification:
- `flutter test test/expense_export_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_export_models.dart lib/screens/expenses/data/expense_receipt_ocr_review.dart test/expense_export_test.dart`

Next camera-only focus:
- Add aggregate OCR health data to the export manifest so export packages show
  how many receipts need OCR review and which primary warning kinds are most
  common without exposing receipt content.

### Receipt Camera Reopen Pass 161: OCR Primary Warning Command Summary Batch

Status: completed.

Goal:
- Add a compact privacy-safe OCR warning summary for Command 1/admin health
  views and saved receipt detail views.

Completed:
- Added `commandCenterPrimaryIssue`, `commandCenterPrimaryAction`, and
  `commandCenterSummary` to saved expense OCR review records.
- Added OCR command center summary data to Firestore receipt backup summaries.
- Kept summary data free of raw receipt text, item descriptions, customer names,
  addresses, or other private content.
- Updated saved receipt detail UI to show the primary issue/action from the
  compact summary.
- Added tests proving saved detail, local draft/ledger persistence, and
  Firestore backup summaries carry the privacy-safe primary OCR issue/action.

Verification:
- `flutter test test/expense_receipt_detail_ocr_review_test.dart test/expense_firestore_documents_test.dart test/expense_draft_store_test.dart test/expense_ledger_store_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_ocr_review.dart lib/screens/expenses/data/expense_firestore_documents.dart lib/screens/expenses/calendar/expense_receipt_detail_info.dart test/expense_receipt_detail_ocr_review_test.dart test/expense_firestore_documents_test.dart test/expense_draft_store_test.dart test/expense_ledger_store_test.dart`

Next camera-only focus:
- Add the same primary OCR issue/action to export summary rows so user exports
  and admin-safe summaries agree on OCR health without including private text.

### Receipt Camera Reopen Pass 160: OCR Warning Diagnostics Alignment Batch

Status: completed.

Goal:
- Carry the prioritized primary OCR warning through diagnostics, saved expense
  OCR review records, and Firestore backup summaries.

Completed:
- Added primary warning kind, label, target label, and target instruction to
  `ReceiptOcrDiagnostics`.
- Added the same primary warning fields to `ExpenseReceiptOcrReview` with
  backward-compatible map loading.
- Preserved old warning kind/label lists while making `primaryWarningLabel`
  prefer the prioritized primary warning when available.
- Updated OCR failure diagnostics to use `ReceiptOcrResult.prioritizedWarnings`
  instead of a separate priority list.
- Added primary warning fields to Firestore expense receipt backup summaries.
- Preserved machine-readable warning kind casing while storing human-readable
  primary warning labels/instructions for Command 1.
- Added tests proving draft, ledger, OCR diagnostics, and Firestore backup
  summaries retain the prioritized primary warning data.

Verification:
- `flutter test test/receipt_camera_result_test.dart test/expense_draft_store_test.dart test/expense_ledger_store_test.dart test/expense_firestore_documents_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_ocr_review.dart lib/screens/expenses/data/expense_ocr_failure_diagnostics.dart lib/screens/expenses/data/expense_firestore_documents.dart test/receipt_camera_result_test.dart test/expense_draft_store_test.dart test/expense_ledger_store_test.dart test/expense_firestore_documents_test.dart`

Next camera-only focus:
- Add a compact primary OCR warning summary helper for Command 1/admin health
  views so the app can expose success/failure/primary-warning data without
  private receipt content.

### Receipt Camera Reopen Pass 159: Review Warning Save-Gate Alignment Batch

Status: completed.

Goal:
- Make the save readiness dialog use the same prioritized OCR warning logic and
  plain-language review guidance as the visible filled receipt review.

Completed:
- Replaced the old manual blocking/partial/review warning loop in
  `_primaryOcrWarningMessage` with `ReceiptOcrWarning.compareByPriority`.
- Added warning review instructions to save-gate detail copy.
- Added warning target labels and target instructions to save-gate detail copy.
- Added a count for remaining OCR warnings so the save dialog does not hide the
  rest of the warning stack.
- Added source guards proving the save gate uses warning priority and target
  guidance instead of the old manual loop.

Verification:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_save_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_result_test.dart`

Next camera-only focus:
- Align diagnostics and Command 1 summary data with the prioritized warning
  stack so admin health views can show the most important OCR issue first.

### Receipt Camera Reopen Pass 158: OCR Warning Priority Stack Batch

Status: completed.

Goal:
- Prioritize multiple OCR warnings so the most important blocker or review item
  is shown first without losing the remaining warning stack.

Completed:
- Added `prioritizedWarnings` to OCR results while preserving original
  `structuredWarnings` ordering for diagnostics compatibility.
- Added warning priority ranks based on severity and warning kind.
- Updated `primaryWarning` to use the prioritized stack.
- Updated the visible OCR review row to sort warnings by priority before
  selecting the lead warning.
- Added visible secondary review targets with `Next checks` copy for the next
  two warnings.
- Added behavior tests proving blockers outrank ordinary review warnings while
  raw structured warning order stays intact.
- Added source guards proving the review UI consumes the priority stack.

Verification:
- `flutter test test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Align save-gate checks with the prioritized warning stack so blocking and
  partial OCR issues produce the same plain-language guidance in the save path.

### Receipt Camera Reopen Pass 157: Receipt Review Line Warning Targeting Batch

Status: completed.

Goal:
- Map OCR warning kinds to the exact receipt area the user should check first
  so the filled receipt review is not vague.

Completed:
- Added `reviewTargetLabel` to OCR warnings for attachment, photo clarity,
  saved proof, long receipt overlap, missing section, PDF safety, PDF size,
  PDF readability, manual entry, photo proof, photo read, PDF read, and unknown
  warning areas.
- Added `reviewTargetInstruction` with plain-language next checks for each OCR
  warning kind.
- Surfaced the target label and instruction in the visible filled receipt review
  OCR row.
- Broadened photo-quality warning classification so alternate warning wording
  still routes to photo-proof review.
- Added behavior tests for overlap, missing-section, and photo-quality warning
  targeting.
- Added source guards proving the visible review consumes warning target labels
  and instructions.

Verification:
- `flutter test test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Prioritize multiple OCR warnings into a review stack so the user sees the
  most important blocker/check first without losing the rest.

### Receipt Camera Reopen Pass 156: Receipt Review Warning Visibility Batch

Status: completed.

Goal:
- Make the visible filled receipt review screen show OCR warning burden clearly
  instead of burying it behind one generic read label.

Completed:
- Reworked the OCR review row title to include the warning count when warnings
  exist.
- Added the warning review instruction directly to the visible receipt review
  detail.
- Added a count for additional OCR warnings so multiple warnings are not hidden
  behind the first warning.
- Added guards proving the review row uses warning instructions, warning count
  wording, and warning pluralization.

Verification:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Map warning kinds to the specific review areas the user should check first:
  receipt photos, overlap/stitch sections, totals, or app-filled line items.

### Receipt Camera Reopen Pass 155: OCR Warning Source-Aware Review Batch

Status: completed.

Goal:
- Make successful OCR reads with warnings tell the user exactly what review
  burden remains before saving.

Completed:
- Added `ReceiptOcrWarning.reviewInstruction` so blocked, partial, and review
  warnings each carry plain-language save guidance.
- Added warning review instructions to `ReceiptOcrResult.reviewMessage`.
- Changed receipt read status so any OCR warning marks the panel as needing
  review, not only blocking or partial warnings.
- Added a behavior test proving duplicate/overlap OCR warnings tell the user to
  compare the filled form with the receipt proof before saving.
- Added a source guard proving review-level warnings affect receipt read status.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_result_test.dart`

Next camera-only focus:
- Make the visible receipt review screen surface OCR warning details clearly
  enough that the user knows which lines or receipt sections need checking.

### Receipt Camera Reopen Pass 154: OCR Failure Source-Aware Recovery Batch

Status: completed.

Goal:
- Make app-assisted receipt reading failures explain what source failed and
  what the user should do next instead of giving one generic retry message.

Completed:
- Added `_receiptReadRecoveryAction` for photos, PDFs, saved receipt text, and
  mixed readable source sets.
- Reworded OCR exception failures to name the source summary before explaining
  the next action.
- Reworded no-text/unreadable states to pair the OCR warning with source-aware
  recovery instructions.
- Added source guards for photo, PDF, saved-text, mixed-source recovery copy,
  and source-aware reading failure copy.
- Added expense coordination note: expenses must stay active-vehicle aware so a
  single owner, employee, or fleet account can assign each expense to the right
  vehicle/profile for cost tracking.
- Added inventory/materials coordination note: inventory parsing can advance in
  another workstream, but it should consume the shared receipt capture/OCR
  output instead of forking the camera flow.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Continue with OCR warning review copy so partial/low-confidence read states
  make the exact review burden clear before the user saves.

### Receipt Camera Reopen Pass 153: OCR Read Status Source Detail Batch

Status: completed.

Goal:
- Make generic app-assisted receipt reading status explain what kind and count
  of source files are being read instead of saying every source is a single
  clear receipt image.

Completed:
- Added `_receiptReadSourceSummary` for readable attachment sets.
- The source summary distinguishes clear receipt photos, receipt PDFs, and saved
  receipt text.
- Reworded generic OCR read-start status to use the source summary.
- Kept the filled receipt review destination explicit in the status copy.
- Added source guards for single/multiple photos, PDFs, saved receipt text, and
  the new source-summary read message.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Continue with OCR failure recovery copy so unreadable/no-text states explain
  which source type failed and what the user should do next.

### Receipt Camera Reopen Pass 152: OCR Source Count And Proof Handoff Guard Batch

Status: completed.

Goal:
- Make the receipt handoff explain the difference between saved proof photos and
  clear OCR source images, especially for long receipts.

Completed:
- Added `savedProofCountLabel` to receipt review results.
- Added `ocrSourceCountLabel` to receipt review results, including combined OCR
  image wording when stitching succeeds.
- Reworded the app-assisted read-start message to say how many saved proof
  photos were kept and how many clear OCR sources are being read.
- Reworded the missing-OCR-source warning to include the saved proof count.
- Added source guards for proof count, OCR source count, combined OCR image
  wording, and missing clear OCR source messaging.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with OCR read-status source detail so generic attachment OCR status
  can also explain what type and count of source files are being read.

### Receipt Camera Reopen Pass 151: Receipt Review Result Handoff Evidence Batch

Status: completed.

Goal:
- Make the post-review OCR handoff agree with the long-receipt decision so the
  app explains whether it is reading one combined image or multiple receipt
  photos in order.

Completed:
- Reused the stitch review decision label when receipt photos are saved and the
  app-assisted read begins.
- Reworded the read-start status to say the app is reading into the filled
  receipt review form.
- Reworded matched-image success copy from a vague matched photo to `One
  combined receipt image was read`.
- Kept fallback success copy explicit: receipt photos are read from top to
  bottom.
- Added source guards for the review-decision handoff and combined-image
  success message.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with OCR source count and proof handoff guards so the app can explain
  when the saved proof is separate from the clear OCR source images.

### Receipt Camera Reopen Pass 150: Review Stitch Fallback Copy And Evidence Batch

Status: completed.

Goal:
- Make long-receipt stitch decisions visible in plain language so the user can
  tell whether Maintainiac made one combined receipt image or is safely reviewing
  the photos from top to bottom.

Completed:
- Added plain stitch-result decision labels for match confidence, review path,
  and final review decision.
- Shows a compact `Decision:` line on the long-receipt match card.
- The decision line distinguishes `1 combined receipt image` from
  `photos top to bottom`.
- Keeps fallback behavior honest: if the stitch is unsafe, `Next` still works
  by reviewing the photos in order.
- Added source guards for stitch decision labels and the review-card decision
  evidence.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with receipt review result handoff evidence so the import/OCR side
  can explain whether it is reading one combined image or multiple top-to-bottom
  receipt photos.

### Receipt Camera Reopen Pass 149: Review Continuation Copy And Action Clarity Batch

Status: completed.

Goal:
- Make receipt review continuation wording explain the user's next screen
  instead of exposing internal OCR/read/save pipeline wording.

Completed:
- Reworded save-prep status copy to say the app is preparing the filled receipt
  review form.
- Changed critical-quality continue copy from `Review Anyway` to
  `Use Photo Anyway`.
- Reworded multi-photo pre-stitch continue copy to `Check Long Receipt`.
- Reworded stitch mode title to `Long Receipt Match` and clarified that unsafe
  matches still let `Next` review photos in order.
- Reworded preview status and tool-mode copy so `Next` means opening the filled
  receipt review form.
- Added source guards so future receipt UI changes keep the clearer
  continuation language and do not reintroduce vague match/review labels.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with stitch fallback copy and evidence so long receipts clearly show
  when the app made one combined receipt image versus when it safely reviews
  photos top to bottom.

### Receipt Camera Reopen Pass 148: Review Save/Continue State Audit Batch

Status: completed.

Goal:
- Harden the `Next` path so preparing saved proof images, OCR source images, and
  stitch output cannot leave the review screen in a stale "preparing" state.

Completed:
- Added an empty-photo guard before receipt review save preparation begins.
- Snapshots the current photo paths before storage checks and image prep so the
  async save path does not use a mutable `_photoPaths` list directly.
- Added `_stopReceiptReviewSave` as a shared cleanup point for interrupted save
  preparation.
- Clears `_savingPhotos` when a closing review interrupts image prep before
  stitch, after stitch, or after generated-file cleanup.
- Added guard coverage proving the save path snapshots photo paths and clears
  interrupted saving state.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue with review continuation copy and action clarity so every save,
  stitch, and fallback state tells the user exactly what `Next` will do.

### Receipt Camera Reopen Pass 147: Review Add/Retake State Recovery Batch

Status: completed.

Goal:
- Keep add-photo, retake, remove, and reorder actions from leaving stale crop,
  stitch-preview, saved-proof, or saving state behind in the receipt photo
  review screen.

Completed:
- Added a shared `_recoverReviewAfterPhotoSetChanged` recovery path for review
  photo-set changes.
- Routed add-photo, retake, remove, and reorder through the recovery path after
  the photo list changes.
- Clamp the selected photo index and stitch-pair index after photo changes so
  the review cannot point at a missing receipt photo or missing stitch pair.
- Return multi-photo receipts to order review and single-photo receipts to
  preview review with controls visible.
- Clear stale crop source bytes, crop rectangles, crop display state, saving
  flags, and crop-processing flags after photo-set changes.
- Reset the tool controls scroll position so the next action stays reachable.
- Updated receipt camera layout guards so future changes keep this recovery
  behavior.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue with review save/continue state auditing so `Next` never leaves the
  user in a hidden or stale receipt-review state after image prep, stitching, or
  storage warnings.

### Receipt Camera Reopen Pass 146: Camera Review Navigation Safety Batch

Status: completed.

Goal:
- Prevent camera/review navigation from interrupting native capture or image
  preparation in ways that can leave the user stuck or the review flow in a
  dead-end state.

Completed:
- Added a close/back guard to the live receipt camera when a manual or assisted
  capture is already in progress.
- Shows a short user hint instead of tearing down the camera while a receipt
  photo is being captured.
- Added a close/back guard to receipt photo review while saved proof and OCR
  source photos are being prepared.
- Added a close/back guard while crop processing is active, directing the user
  to finish or cancel crop before leaving the review.
- Added guard tests proving camera close protection happens before teardown and
  review close protection happens before `_closingReview` is set.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Continue with review add/retake state recovery so newly added, retaken, or
  removed receipt photos keep the user in the right review mode with obvious
  next actions.

### Receipt Camera Reopen Pass 145: Receipt Review Correction Telemetry Batch

Status: completed.

Goal:
- Track whether app-filled receipt lines are confirmed or corrected after the
  user reviews them, without collecting private receipt text or item details.

Completed:
- Added privacy-safe telemetry event types for app-filled receipt line
  confirmations and corrections.
- Recorded the event after an app-filled receipt line is saved from the review
  editor.
- Kept telemetry metadata limited to source area, line use, review-needed flag,
  parser-review presence, category group, and parser confidence bucket.
- Added Command One summary counts for confirmed app-filled receipt lines,
  corrected app-filled receipt lines, and app-filled receipt line correction
  rate.
- Counted corrected app-filled receipt lines as user corrections while keeping
  confirmed lines separate.
- Added source guards and snapshot tests proving the new metrics exist and do
  not include private receipt content.

Verification:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Continue with camera/review navigation safety: back/close behavior, staged
  photo escape paths, and making sure every photo review state has an obvious
  next action.

### Receipt Camera Reopen Pass 144: Receipt Review Line Editing Flow Batch

Status: completed.

Goal:
- Make editing an app-filled receipt line resolve its review state cleanly so
  corrected or confirmed OCR/parser lines do not keep warning the user after the
  line has been reviewed.

Completed:
- Changed the receipt line editor save path to mark app-filled lines reviewed
  when the user saves the line.
- Added `Corrected` parser review labeling when the user changes line details
  before saving.
- Added `Confirmed` parser review labeling when the user saves an app-filled
  line without changing it.
- Added review reasons for corrected and confirmed app-filled lines.
- Preserved parser confidence and receipt evidence while clearing
  `parserNeedsReview`.
- Added line-editor copy explaining that saving an app-filled line marks it
  reviewed.
- Added source guards for corrected/confirmed review labels, cleared review
  state, and the editor guidance copy.

Verification:
- `dart format lib/screens/expenses/entry/expense_receipt_line_editor_actions.dart lib/screens/expenses/entry/expense_receipt_line_fields.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_line_editor_actions.dart lib/screens/expenses/entry/expense_receipt_line_fields.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 143: Receipt Mixed Allocation And Tax Review Batch

Status: completed.

Goal:
- Make mixed business/personal receipt allocation visible before save so users
  can understand how line subtotals, tax, fees, discounts, and receipt
  adjustments are split.

Completed:
- Added a `MIXED ALLOCATION REVIEW` block to the receipt-paper recap when line
  use controls are active.
- Shows business line count, personal line count, and split line count.
- Shows business subtotal, business tax/adjustment, and business final total.
- Shows personal subtotal, personal tax/adjustment, and personal final total.
- Updated mixed-total explanatory copy to explicitly mention sales tax, fees,
  discounts, and receipt adjustments.
- Kept return handling conservative by using nonnegative business/personal bases
  for the visible allocation breakdown.
- Added source guards for the mixed allocation review UI and allocation math.

Verification:
- `dart format lib/screens/expenses/entry/expense_receipt_recap.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_recap.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 142: Receipt Line Review Save-Gate Polish Batch

Status: completed.

Goal:
- Make receipt save readiness behave like a real review checklist: it should
  identify what still needs attention, send the user back to the filled receipt
  review, and use strongest OCR warning logic before committing records.

Completed:
- Added a save-readiness issue for mixed receipt lines that do not have a usable
  business percent.
- Updated the Save Receipt panel to show mixed-line split-percent warnings
  before the user taps Save.
- Changed OCR save-readiness warning selection to prioritize blocking warnings,
  then partial warnings, then review warnings.
- Changed the `Review Receipt` path to scroll back to the app-filled receipt
  review and show clear next-step copy instead of silently closing the dialog.
- Added source guards for split-percent readiness, strongest OCR save warnings,
  and visible Save panel split warnings.

Verification:
- `dart format lib/screens/expenses/entry/expense_receipt_save_actions.dart lib/screens/expenses/entry/expense_receipt_totals.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_save_actions.dart lib/screens/expenses/entry/expense_receipt_totals.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 141: Real Receipt Line Review Entry Batch

Status: completed.

Goal:
- Make the app-filled receipt review guide the user clearly into Business /
  Personal / Mixed classification and surface the strongest privacy-safe warning
  when OCR or parsing needs attention.

Completed:
- Changed attached receipt OCR no-text handling to show the OCR result's
  strongest action message instead of whichever warning happened to come first.
- Added primary parsed-warning selection that prioritizes missing, could-not,
  failed, low-confidence, and mismatch warnings.
- Updated successful parse handoff copy to explicitly tell the user to classify
  the receipt as Business, Personal, or Mixed and review the lines before
  saving.
- Updated parse-warning handoff copy to keep the warning but still direct the
  user into classification and line review.
- Added assisted-review source guards for the stronger warning selection and
  classification handoff copy.

Verification:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture lib/screens/expenses/entry`
- `git diff --check`

### Receipt Camera Reopen Pass 140: Receipt Review Failure Detail Batch

Status: completed.

Goal:
- Make app-assisted receipt-read failures explain the strongest confirmed issue
  and a concrete next action instead of flattening every failure into vague
  retry copy.

Completed:
- Added `primaryWarning` to OCR results so blocking warnings outrank partial
  and review warnings.
- Added `strongestActionMessage` to OCR results for privacy-safe user guidance.
- Updated OCR review messages to use the strongest structured warning instead
  of the first raw warning string.
- Updated no-text receipt-photo failure copy to keep the proof attached and
  give concrete options: add another receipt photo, retake, or enter manually.
- Added tests proving no-readable-text outranks duplicate/overlap warnings in
  user-facing action copy.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_result_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 139: Review-To-App-Filled Receipt Handoff Batch

Status: completed.

Goal:
- Make the transition from approved receipt photos into app-assisted receipt
  filling visible, deterministic, and lifecycle-safe.

Completed:
- Added a reviewed-photo handoff status before OCR begins so the user sees that
  receipt photos were saved and are being read into the receipt form.
- Tailored the handoff copy for single photos, multi-section receipts, and
  stitched receipt images.
- Reused the existing app-assisted settings gate so proof-only mode stays
  proof-only.
- Added mounted checks after reviewed-photo OCR before updating photo read
  states.
- Added a mounted guard after the receipt text is handed to the form and before
  the attachment panel updates its own state.
- Added source guards proving the review-to-form handoff is announced before
  OCR and that the async form-fill callback is lifecycle-safe.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 138: Camera Capture Flow Real-Device Polish Batch

Status: completed.

Goal:
- Make the first photo review surface clearer and more professional on real
  phones without hiding critical receipt actions in a tiny horizontal drawer.

Completed:
- Added a compact `current/total` receipt photo badge to the preview tray.
- Changed single-photo and multi-photo copy to explain that `Next` opens the
  filled receipt review, while additional photos are for continuing long
  receipts.
- Reworded the add-photo actions to `Add Another Receipt Photo` and `Add Next
  Receipt Photo`.
- Reworded crop and data-saver actions to `Crop / Straighten` and `Save Space
  Preview`.
- Replaced the preview action rail's horizontal scroller with a wrapped action
  layout so key controls stay visible without a hidden control drawer.
- Raised preview-mode bottom control caps enough to fit the wrapped scanner
  controls while keeping the receipt image dominant.
- Added source guards proving the preview tray uses explicit receipt language
  and a wrapped action panel.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 137: Exposure Retry Failure Recovery Batch

Status: completed.

Goal:
- Keep the camera lifecycle safe when exposure retries cross async gaps or when
  capture exits early.

Completed:
- Added mounted/closing guards immediately after async exposure adjustment in
  manual capture before widget state is touched.
- Added mounted/closing guards immediately after async exposure adjustment in
  assisted capture before widget state is touched.
- Moved manual capture exposure restoration into a `finally` block so native
  baseline recovery still runs after early returns or capture errors.
- Moved assisted capture exposure restoration into a `finally` block so guided
  capture cannot leave the camera in a nudged exposure state.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_camera_screen.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_capture.dart lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 136: Capture Exposure Retry Strategy Batch

Status: completed.

Goal:
- Give dark/glare capture sessions a bounded second chance without abandoning
  native auto exposure as the default camera behavior.

Completed:
- Added per-candidate exposure offset tracking to camera candidates.
- Added selected/candidate exposure offsets to privacy-safe camera capture
  evidence.
- Kept the first receipt photo at the native auto-exposure baseline.
- Added a bounded exposure nudge only for later candidates when live guidance
  says the frame is too dark or too bright.
- Clamped every exposure retry to the camera-reported min/max exposure range.
- Restored the native exposure baseline after the candidate burst.
- Added model and source guards proving exposure retries are bounded,
  evidence-backed, and not a blind always-on exposure change.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_capture.dart lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_capture.dart lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 135: Review Continue Safety For Critical Photos Batch

Status: completed.

Goal:
- Keep users from mistaking a critical dark/glare/blurry photo for a normal
  review-ready receipt while still allowing them to continue when they decide
  the receipt is readable.

Completed:
- Changed the preview-mode continue label to `Review Anyway` when the selected
  photo has a critical quality issue.
- Kept normal `Next` behavior for readable or non-critical photos.
- Added a source guard proving critical photo quality changes the preview
  continue copy before the normal `Next` branch.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 134: Brightness Review Feedback And Retake Guidance Batch

Status: completed.

Goal:
- Make dark/glare receipt photo problems obvious in the photo review surface so
  users know whether to retake, add light, turn on the torch, or reduce glare.

Completed:
- Added quality-aware status icons in the photo review tray.
- Added warning color treatment for critical photo quality issues.
- Changed critical-quality review copy to include `Retake Recommended` and the
  concrete dark/glare guidance from the photo quality model.
- Made `Retake Now` the emphasized preview action for critical photo issues.
- Kept normal/add-photo emphasis when the selected photo does not have a
  critical quality issue.
- Added source and model guards for dark/glare guidance and critical retake
  emphasis.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 133: Brightness-Aware Capture Candidate Selection Batch

Status: completed.

Goal:
- Make best-shot selection explicitly prefer readable, properly lit receipt
  images before falling back to generic score or pixel count.

Completed:
- Added `brightnessDistanceFromReceiptIdeal` to receipt photo quality checks.
- Updated best-shot candidate ranking to reject critical quality issues before
  normal readability scoring.
- Added explicit dark/glare ordering so a large but poorly lit photo does not
  beat a cleaner receipt image.
- Added brightness-distance, contrast, and text-band tie breakers before final
  pixel-count tie breaking.
- Added tests/source guards proving brightness-aware ranking happens before
  resolution tie breaking.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_capture.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_capture.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 132: Review Image Brightness And Native Capture Evidence Batch

Status: completed.

Goal:
- Add privacy-safe evidence for dark/bright receipt captures so the app can
  tell whether capture quality problems came from native camera state, lighting,
  preview analysis, or later image processing.

Completed:
- Added `ReceiptCameraCaptureEvidence` to `ReceiptCameraResult`.
- Tracked capture surface, capture flow, resolution tier, actual resolution
  preset, flash mode, exposure mode, focus mode, focus/exposure point support,
  applied exposure offset, exposure range, zoom range, preview size, live
  brightness, live contrast, live focus score, readiness, and stream state.
- Populated capture evidence for both manual and assisted custom-camera
  captures.
- Recorded the actual resolution preset that initialized successfully after
  fallback.
- Stored the actual exposure offset returned by the native camera plugin when
  the app resets exposure to the native auto-exposure baseline.
- Added model and source guards proving brightness/exposure evidence stays
  attached to camera results without collecting receipt content.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_screen.dart lib/shared/widgets/receipt_capture/receipt_camera_setup.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_screen.dart lib/shared/widgets/receipt_capture/receipt_camera_setup.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 131: Crop Failure And Storage Recovery Copy Batch

Status: completed.

Goal:
- Prevent crop mode from leaving the review screen in a stuck processing state
  when async storage validation returns after crop mode has already been exited.

Completed:
- Split the crop apply post-storage guard into explicit mounted and mode checks.
- Cleared `_cropProcessing` before returning when the crop session is no longer
  active.
- Added a source guard proving the interrupted crop path clears processing
  before any storage failure handling continues.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 130: Crop Apply And Preview Recovery Batch

Status: completed.

Goal:
- Make crop apply/cancel behavior recover predictably, avoid stale crop state,
  and keep async crop work tied to the crop that the user actually accepted.

Completed:
- Added a dedicated crop cancel path that clears crop processing, source bytes,
  decoded image size, crop rectangle, and display rectangle.
- Routed both the crop top-bar close action and bottom `Cancel` action through
  that shared cleanup path.
- Made `Apply Crop` snapshot the current crop bytes, display rectangle, and crop
  rectangle before async storage/image work starts.
- Added a user-facing recovery message when Apply Crop is tapped before crop
  data is ready.
- Routed successful crop completion through the shared review-mode transition so
  preview controls reset cleanly.
- Added source guards proving crop apply/cancel cannot leave stale crop state.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 129: Crop Mode Readability And Edge Controls Batch

Status: completed.

Goal:
- Make receipt crop mode easier to understand and easier to operate on a phone
  without covering the receipt image.

Completed:
- Increased crop handle hit targets and visible edge/corner sizes so users can
  grab receipt edges more reliably.
- Added high-contrast corner handle centers and stronger handle outlines.
- Added accessibility labels for each crop edge and corner.
- Replaced the icon-only crop cancel affordance with a labeled `Cancel` action.
- Renamed the crop confirmation action to `Apply Crop`.
- Added compact crop instructions inside the bottom tool controls instead of
  over the receipt image.
- Added source guards proving crop handles stay touchable and crop controls
  remain plainly labeled.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 128: Receipt Review Mode Transition Polish Batch

Status: completed.

Goal:
- Keep receipt-review mode switches predictable by preventing stale scroll
  positions from carrying between Review, Crop, Order, Match, and Save Space.

Completed:
- Added a mode-transition scroll reset so each tool mode starts at the top of
  its controls.
- Guarded the scroll reset so it only touches the controller when attached.
- Routed crop top-bar close through the shared review-mode switch.
- Routed crop cancel through the shared review-mode switch.
- Added source guards proving mode changes reset the tool scroll position and
  crop exits use the shared transition path.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 127: Review Continue Button Persistence Batch

Status: completed.

Goal:
- Keep the `Next` / receipt-review handoff action visible in tool modes even
  when the crop/order/match/save-space details need to scroll.

Completed:
- Passed the receipt-review tool scroll controller into the bottom-controls
  widget instead of wrapping the whole tray from the screen.
- Moved the visible scrollbar and scroll view inside the non-preview tool
  content area only.
- Added a persistent continue button below the scrollable tool details so the
  user does not have to hunt for `Next`.
- Preserved the waiting-for-stitch disable behavior and the saving spinner/copy
  on the persistent action.
- Added source guards proving the scrollbar appears before the persistent
  continue button and that the screen wires the scroll controller into the
  controls.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 126: Review Tool Mode Height And Scroll Batch

Status: completed.

Goal:
- Make capped tool trays usable on phone screens when crop/order/match/save-space
  controls are taller than the available review tray height.

Completed:
- Added a dedicated scroll controller for receipt-review tool controls.
- Wrapped non-preview review tool trays in a visible `Scrollbar` so scrollable
  controls are discoverable instead of silently clipped.
- Kept preview mode unwrapped so the primary review tray remains direct and
  compact.
- Disposed the tool-control scroll controller with the review screen lifecycle.
- Added source guards for the controller, disposal, and visible scrollbar
  contract.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 125: Review Surface Tool Affordance Batch

Status: completed.

Goal:
- Make secondary receipt-review tools understandable on a phone without relying
  on tooltip-only icon buttons.

Completed:
- Reworked the non-preview tool context row into a compact labeled action card.
- Replaced the icon-only Add/Retake/Remove controls in tool modes with labeled
  mini action buttons.
- The Add action now says Add Next Photo when multiple receipt sections exist
  and Add Another Photo for a single receipt section.
- Kept the action strip horizontally scrollable and compact so crop/order/match
  tools remain usable without taking over the receipt preview.
- Added guards that the tool-mode action row uses visible labels instead of
  tooltip-only icons.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 124: Review Surface Real-Device Polish Batch

Status: completed.

Goal:
- Keep the receipt photo itself dominant and fully reviewable on real phone
  screens by preventing the bottom control tray from covering the bottom of the
  receipt image.

Completed:
- Replaced the separate hard-coded review-image bottom padding values with a
  single padding calculation tied to the actual capped bottom controls height.
- The photo preview surface now reserves the same height as the visible controls
  plus a small gutter.
- The crop surface now uses the same controls-aware bottom padding, so crop
  handles and receipt edges are less likely to be hidden behind the tray.
- Added source guards proving the review surface padding is derived from
  `_reviewBottomControlsMaxHeight(context)` instead of a stale fixed value.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 123: Camera UI Device Batch

Status: completed.

Goal:
- Tighten the first photo-review decision surface so the next step is obvious
  on a phone-sized screen without relying on tiny icons or vague scan wording.

Completed:
- Changed the single-photo review prompt to explicitly say to tap Add Another
  Photo when the receipt continues, otherwise tap Next.
- Changed the multi-photo prompt to explicitly say Add Next Photo for long
  receipts, otherwise Next moves into the filled receipt review.
- Changed the multi-photo add action label from Add Photo to Add Next Photo so
  it matches the long-receipt workflow instead of sounding like a generic
  gallery action.
- Changed the retake action to Retake Clearer Photo when the selected quality
  check indicates the photo needs review.
- Added source guards to keep the explicit Add Another Photo/Add Next Photo
  language from regressing back to vague review wording.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`

### Receipt Camera Reopen Pass 122: First-Use Camera Setup

Status: completed.

Goal:
- Give users a short first-use explanation of receipt photo capture without
  turning the camera flow into a long setup wizard.

Completed:
- Replaced the silent `cameraSetupComplete` flip with a compact first-use
  receipt camera intro.
- The intro appears only before the first receipt photo capture.
- The user can continue directly to the camera or open Receipt Settings first.
- The intro covers clear photo first, long receipt sections, app-assisted
  review, saved proof size, and privacy/storage behavior.
- The intro shows the effective camera runtime summary without raw device model,
  RAM, CPU, or SDK details.
- Added source guards for first-use gating, settings handoff, intro actions,
  and privacy-safe copy.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_settings_store_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 121: Capability-Based Camera Settings

Status: completed.

Goal:
- Make receipt camera settings resolve to safe runtime behavior based on device
  capability, not raw phone model names or user toggles alone.

Completed:
- Added `ReceiptCameraRuntimeProfile` as the effective camera behavior contract.
- Added `ReceiptDeviceCapability.cameraRuntimeProfileFor(...)` so guidance,
  assisted start, auto capture, long receipt tips, resolution tier, shot count,
  timing, and saved-proof size are derived from capability.
- Older/light devices keep live guidance but are forced manual-first for camera
  responsiveness, even if a heavier setting was requested.
- Medium devices can use guided manual capture but hold back auto capture.
- Heavyweight devices can use guided auto capture when requested.
- Added `effectiveCameraRuntimeProfile` to receipt capture settings.
- Added a plain receipt scanner settings summary that explains effective camera
  behavior without showing raw model, RAM, CPU, or Android SDK details.
- Added tests for older-phone gating, heavyweight auto capture, settings store
  exposure, and privacy-safe settings copy.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 120: Live Guidance Tone And Timing

Status: completed.

Goal:
- Make live receipt guidance short, plain, and useful without developer-status
  wording or messages that imply capture is blocked.

Completed:
- Replaced auto-capture status labels like `Waiting:` and `Check:` with direct
  action labels.
- Kept guidance focused on what the user should do next: add light, reduce
  glare, tap receipt text, show the full receipt, move closer, or hold steady.
- Changed capture guidance copy to say capture still works instead of sounding
  like the app is blocking the shutter.
- Tightened assisted-capture labels such as `Receipt Assist`, `Check Focus`,
  and `Final Shot`.
- Added tests that reject `Waiting:`/`Check:` auto-capture labels and guard the
  plain-language replacements.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart lib/shared/widgets/receipt_capture/receipt_camera_assist.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart lib/shared/widgets/receipt_capture/receipt_camera_assist.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 119: Manual Shutter Always Works

Status: completed.

Goal:
- Make manual shutter taps feel immediate and independent from auto-capture
  guidance.

Completed:
- Audited the manual and assisted capture paths.
- Kept manual shutter free from mode/guidance gating.
- Split camera settle timing into a short manual delay and a longer assisted
  delay.
- Manual shutter now primes focus/exposure briefly, then starts capture without
  waiting on the full guided steadying delay.
- Assisted capture keeps the longer settle delay because that mode is explicitly
  trying to choose the best frame.
- Added source guards proving manual and assisted capture use separate settle
  delays and that manual capture still calls `_capturePhoto()` directly.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_camera_screen.dart lib/shared/widgets/receipt_capture/receipt_camera_capture.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart lib/shared/widgets/receipt_capture/receipt_camera_capture.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 118: Brightness And Exposure Baseline

Status: completed.

Goal:
- Stop the in-app receipt camera from making hidden exposure assumptions that
  can diverge from the phone's native camera behavior.

Completed:
- Audited the in-app camera exposure setup.
- Kept focus mode and exposure mode on native auto behavior.
- Removed the forced positive exposure-compensation tier defaults.
- Kept tap-to-exposure best effort, so the user can still tap receipt text to
  guide the camera when the device supports it.
- Added source guards proving exposure compensation stays neutral and does not
  reintroduce S9/S24/S25-style tier offsets.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 117: Pinch Zoom And Tap Focus Contract

Status: completed.

Goal:
- Make the in-app receipt camera's pinch zoom and tap focus/exposure behavior
  match what the user sees on the cover-cropped camera preview.

Completed:
- Audited the live camera gesture layer.
- Kept pinch-to-zoom on the full preview tap layer with queued zoom updates.
- Kept tap-to-focus/tap-to-exposure best effort and nonblocking.
- Corrected tap-focus coordinate mapping so focus/exposure points account for
  the same cover-cropped preview size used by the visible camera image.
- Added source guards proving tap focus uses `controller.value.previewSize`,
  rendered preview scale, and crop offset instead of raw screen-only
  coordinates.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 116: Capture Surface Edge Layout

Status: completed.

Goal:
- Keep visible capture/review controls anchored to expected screen edges and
  avoid a floating cluster over the receipt image.

Completed:
- Audited the active camera and post-capture review surfaces.
- Kept the live camera top bar edge anchored with back on the left and settings
  plus torch on the right.
- Reworked the photo review top bar so the back action stays left, the title is
  a constrained left-aligned chip, and hide/menu actions stay right.
- Removed spacer-centered review-title behavior that could make controls feel
  like they were sitting in the middle of the receipt.
- Added a source guard that proves the review top controls stay ordered
  left-title-right and do not reintroduce `Spacer` centering.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 115: Camera Permission And Fallback UX

Status: completed.

Goal:
- Make camera permission, scanner fallback, canceled camera, and unavailable
  camera/plugin states understandable and recoverable without developer jargon.

Completed:
- Improved scanner fallback messaging so users know the phone camera opens next
  and receipt capture can continue.
- Added plain camera permission handling for both first receipt photo and
  add-another-photo flows.
- Added canceled-camera messaging that confirms no receipt photo was added.
- Added practical recovery copy: try the camera again or choose an existing
  receipt image.
- Added tests that guard the permission, cancel, scanner fallback, and recovery
  wording.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 114: Native Capture And Long Receipt Overlay Decision

Status: completed.

Goal:
- Resolve the conflict between native phone-camera image quality and
  Maintainiac's desire for a long-receipt ghost alignment overlay.

Completed:
- Kept production add-photo capture on the native phone camera path for image
  quality and exposure trust.
- Added a pre-camera long receipt alignment guide that shows the bottom of the
  previous receipt section before opening the external camera.
- Explained to the user that Maintainiac cannot draw over the phone camera
  screen, so the preview is the alignment reference.
- Kept post-capture order review, stitching, manual overlap, and ordered OCR
  fallback as the Maintainiac-controlled part of the long receipt workflow.
- Added tests proving the alignment guide, native-camera note, and `Open
  Camera` action exist.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 113: Expense Receipt Review Detail Settings Contract

Status: completed.

Goal:
- Put the expense receipt simple-vs-detailed review choice where users expect it
  during receipt photo setup, while reusing the existing expense setting that
  already drives the receipt review screen.

Completed:
- Added optional `ExpenseSettingsScope.maybeOf` access so shared receipt widgets
  can use expense settings without crashing outside the expense area.
- Added `Expense Receipt Review Detail` to Expense Receipt Settings.
- Added plain choices for `Show Prices Only` and `Show Full Item Details`.
- Kept the setting backed by `ExpenseReceiptReviewStyle` so the receipt entry
  screen and receipt photo settings share one source of truth.
- Added tests for the settings wording and persisted review-style default.

Verification:
- `dart format lib/shared/state/expense_settings_store.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_help_flow_test.dart test/expense_settings_store_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/expense_settings_store_test.dart`
- `flutter analyze lib/shared/state/expense_settings_store.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_help_flow_test.dart test/expense_settings_store_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 112: Master Receipt System Spec Reset

Status: completed.

Goal:
- Create a single state-of-art receipt system spec that maps the remaining work
  against Adobe Scan, Microsoft Lens, Expensify, Genius Scan, Scanner Pro,
  CamScanner, and Maintainiac-specific requirements.

Completed:
- Added `docs/receipt_camera_ocr_state_of_art_spec.md`.
- Raised new receipt work tracking to a 300-pass cap while reporting passes as Pass NN.
- Mapped remaining work across camera, image cleanup, long receipts, OCR,
  parsing, classification, PDF/text extraction, diagnostics, storage, and QA.

Verification:
- Spec file exists and is linked from this master plan.

### Receipt Camera Reopen Pass 111 of 150: Camera Exit Lifecycle Guard

Status: completed.

Goal:
- Reduce the risk of the legacy camera surface throwing a disposed-preview
  crash when the user backs out or finishes capture.

Completed:
- Changed the camera close path so the route is popped before the detached
  camera controller is disposed.
- Changed the camera result path so successful capture also pops before
  disposing the detached controller.
- Added source guards proving both close and result paths pop before controller
  disposal.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 110 of 150: Photo Review Control Height Caps

Status: completed.

Goal:
- Keep the post-capture receipt preview dominant on tall phones by capping the
  bottom control tray height by mode.

Completed:
- Replaced the purely proportional bottom-control max height with mode-specific
  caps.
- Kept single-photo preview smallest, gave multi-photo preview room for
  thumbnails, and bounded crop, order, stitch, and data-saver modes.
- Added source guards proving the preview, crop, order, stitch, and data-saver
  caps stay in place.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 109 of 150: Real-Device QA Contract Alignment

Status: completed.

Goal:
- Make the real-device checklist and product standard match the current
  app-assisted camera workflow so S24/S9/iPhone testing judges the right
  behavior.

Completed:
- Updated the real-device script goal from `let Maintainiac read it` to
  filling a receipt review the user classifies and saves.
- Updated single-photo expected behavior so the primary action is `Next` to
  fill the receipt review.
- Updated long-receipt fallback wording to top-to-bottom photo review instead
  of separate-photo reading.
- Renamed the app-assisted manual test flow to `App-Assisted Filled Receipt
  Review`.
- Updated the product standard so the default user-facing next step is filling
  the receipt review.
- Added test guards that read both the product standard and real-device script
  so stale `read receipt` wording does not drift back into QA instructions.

Verification:
- `dart format test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for remaining camera/review gaps, then keep
  hardening the receipt review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 108 of 150: Stitch Result Review Metadata Alignment

Status: completed.

Goal:
- Make the underlying stitch result labels and fallback warnings match the
  visible long-receipt review workflow, while proving fallback preserves ordered
  OCR source paths.

Completed:
- Updated `ReceiptStitchResult.summaryLabel` to use receipt review language
  instead of app-assisted reading language.
- Updated `ReceiptStitchResult.detailLabel` to describe photos prepared for
  receipt review.
- Updated oversized/exception stitch fallback warnings so they say `Next` will
  review photos separately.
- Added a stitching test assertion proving fallback OCR source paths stay in
  top-to-bottom input order.
- Kept PDF-specific app-assisted reading copy untouched because PDF work is
  paused until camera/photo review is stable.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_image_processor.dart test/receipt_stitching_test.dart`
- `flutter test test/receipt_stitching_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_image_processor.dart test/receipt_stitching_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for remaining camera/review gaps, then keep
  hardening the receipt review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 107 of 150: Long Receipt Review Language Alignment

Status: completed.

Goal:
- Make long-receipt stitch/fallback UI match the current app-assisted receipt
  workflow: `Next` leads to filled receipt review, not a vague hidden read step.

Completed:
- Reworded successful stitch preview copy so it says `Next` reviews one
  combined receipt image.
- Reworded fallback stitch copy so unsafe matches tell the user the app will
  review photos top to bottom.
- Renamed long-receipt fallback labels from `Read Photos In Order` to
  `Review Photos Top To Bottom`.
- Renamed the fallback action pill from `Next Reads Top To Bottom` to
  `Next Reviews Top To Bottom`.
- Reworded stitch-mode helper copy so it describes filling/reviewing the
  receipt review instead of reading the receipt.
- Updated the match-wait warning to say the receipt review fill is waiting on
  the photo match check.
- Updated source guards to protect the new long-receipt review language.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_stitching_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for remaining camera/review gaps, then keep
  hardening the receipt review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 106 of 150: Empty Photo Review Recovery

Status: completed.

Goal:
- Prevent the receipt photo review route from throwing if a picker/scanner edge
  case opens review without a usable photo path.

Completed:
- Added an empty-review recovery surface before the review screen indexes into
  the selected photo path.
- Added a clear back action to return to the receipt form.
- Added plain recovery copy explaining that the photo was not available and no
  receipt fields were changed.
- Added source guards so this recovery path remains in the receipt review
  screen.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for remaining camera/review gaps, then keep
  hardening the receipt review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 105 of 150: Filled Review Handoff Copy

Status: completed.

Goal:
- Make the handoff from captured receipt photo to expense receipt review clear:
  `Next` prepares the app-assisted filled review section, not a mystery read
  or a return to the attachment button.

Completed:
- Updated the expense receipt reading status to say the app is preparing the
  filled review section below.
- Reworded the app-assisted receipt review panel to say it is the filled review
  from the photo.
- Called out the exact fields the user must check: store, date, totals, and
  lines.
- Updated OCR/parser success snackbars to say receipt fields were filled and
  must be reviewed before saving.
- Updated assisted-flow source guards so the camera `Next` copy and expense
  review handoff copy stay aligned.

Verification:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for remaining camera/review gaps, then keep
  hardening the receipt review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 104 of 150: Native Capture Regression Guard

Status: completed.

Goal:
- Keep production receipt capture on native phone camera/scanner surfaces and
  prevent the legacy custom Flutter camera screen from returning to the expense
  receipt flow by accident.

Completed:
- Strengthened receipt capture source guards so production review/import actions
  must not launch `ReceiptCameraScreen`.
- Guarded against production receipt action files depending on `CameraController`
  or `CameraPreview`.
- Kept Android document scanning unavailable until an offline/non-Play-Services
  scanner path is available.
- Guarded the scanner service against Android-specific document scanner routing
  that could make a user wait for Google Play Services updates before taking a
  receipt photo.

Verification:
- `dart format test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for remaining camera/review gaps, then keep
  hardening the receipt review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 103 of 150: Review Back Action And Next-Step Copy

Status: completed.

Goal:
- Make the post-capture receipt photo review screen feel like a normal camera
  review step instead of a trapped modal, and make the `Next` action describe
  the actual app-assisted receipt review handoff.

Completed:
- Changed the post-capture review top-left control from a close/X action to a
  plain back arrow labeled `Back to receipt form`.
- Kept crop mode as a cancel-crop action because that stays inside the editor
  instead of leaving the review flow.
- Reworded single-photo and long-receipt preview guidance so `Next` means
  reviewing the filled receipt, not a vague receipt read.
- Updated source guards so the back action and clearer `Next` copy stay in
  place during future receipt-camera passes.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_help_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for the remaining camera gaps and keep hardening
  only the camera/review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 102 of 150: Stable Photo Proof IDs

Status: completed.

Goal:
- Keep saved receipt photo proof identity stable when the attachment panel
  republishes, removes, reorders, or re-reviews photos.

Completed:
- Added path-based receipt photo ID tracking in the shared attachment panel.
- Initial photo proof attachments now seed stable IDs from existing records.
- Removing or clearing photo proof now clears the matching stable ID entries.
- Publishing attachment changes now reuses the same photo ID for the same saved
  proof path instead of regenerating a timestamp ID every time.
- Re-reviewing existing receipt photos preserves IDs for unchanged proof paths.
- Adding new receipt photos preserves IDs for already attached proof paths while
  assigning new stable IDs to new saved proof paths.
- Added tests/guards proving photo IDs stay stable after removing a long-receipt
  section and that the stable-ID helpers remain wired.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_attachment_panel_actions_test.dart test/receipt_camera_help_flow_test.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for the remaining camera gaps and keep hardening
  only the camera/review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 97 of 150: Retake/Remove Preview Cache Cleanup

Status: completed.

Goal:
- Prevent stale saved-proof previews, quality badges, and in-flight preview work
  from surviving after a receipt photo is retaken or removed.

Completed:
- Centralized per-photo review cache cleanup so crop, rotate, retake, and remove
  all clear the same quality, storage-preview, saved-proof-preview, and
  in-flight preview state.
- Made retake reuse the same path-replacement cleanup that edited photos use.
- Made remove clear stale saved-proof preview files for the removed photo.
- Kept long-receipt review state safe by invalidating stitch preview after
  retake/remove.
- Added source guards proving retake/remove use the shared cleanup path and
  clear in-flight preview keys.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_image_data_saver_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for the remaining camera gaps and keep hardening
  only the camera/review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 101 of 150: Reviewed Photo Proof Read State

Status: completed.

Goal:
- Make saved receipt photo proof record whether it was actually read into the
  app-assisted receipt form.

Completed:
- Added per-photo read-state tracking in the shared receipt attachment panel.
- Reviewed photos now publish `readIntoForm` after OCR successfully fills the
  receipt form.
- Reviewed photos now publish `unreadable` when OCR attempts fail to find
  usable text.
- Replacing or newly adding receipt photos resets those photos to `notRead`
  until they are actually read.
- Photo-quality warnings no longer downgrade a proof that OCR already read into
  the form.
- Added tests/guards for read-state preservation and reviewed-photo read-state
  handoff.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_ocr_service_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_ocr_service_test.dart test/receipt_camera_help_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_ocr_service_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for the remaining camera gaps and keep hardening
  only the camera/review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 100 of 150: App-Assisted Re-Read Line Replacement

Status: completed.

Goal:
- Prevent duplicated or stale parsed receipt lines when the user retakes,
  replaces, or re-reads receipt proof during app-assisted expense entry.

Completed:
- Added a line-origin helper that identifies lines created by app-assisted
  receipt reading.
- Successful app-assisted parses now remove previous app-filled lines before
  adding the newly parsed lines.
- Unusable app-assisted reads now remove stale app-filled lines too, so old OCR
  results do not remain attached to a new failed read.
- Manual lines remain in place because they do not carry receipt OCR/parser
  evidence.
- Added assisted-flow guards proving the old app-filled lines are removed
  before new parsed lines are added.

Verification:
- `dart format lib/screens/expenses/entry/expense_receipt_line_models.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/expense_receipt_parser_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_line_models.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for the remaining camera gaps and keep hardening
  only the camera/review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 99 of 150: Newly Added Receipt Section Focus

Status: completed.

Goal:
- Keep long-receipt users oriented when they add another receipt photo after
  proof already exists.

Completed:
- Added an initial selected-photo index to `ReceiptPhotoReviewScreen`.
- When the user adds new receipt photos to an existing proof set, review now
  opens on the first newly added photo instead of jumping back to photo 1.
- Clamped the initial selected index so stale or invalid indexes cannot crash
  the review screen.
- Added source guards proving the import path passes the first-new-photo index
  and the review screen clamps it safely.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for the remaining camera gaps and keep hardening
  only the camera/review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 98 of 150: Production Native Camera Routing Guard

Status: completed.

Goal:
- Keep production receipt capture routed through the phone camera/gallery
  surfaces and prevent future code from falling back into one-photo-only or
  custom-camera entry points.

Completed:
- Removed unused single-photo helper methods from `ReceiptImagePicker` so
  receipt callers use the set-based camera/gallery APIs that support long
  receipts.
- Added source guards proving receipt review add-photo and receipt import both
  use `ReceiptImagePicker.takeReceiptPhotoSet()` and do not instantiate the
  legacy `ReceiptCameraScreen`.
- Kept Android receipt capture away from Google Play Services document-scanner
  waits; Android uses the phone camera fallback, while iOS can still use the
  native document scanner.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_image_picker.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_image_picker.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for the remaining camera gaps and keep hardening
  only the camera/review path before moving to PDF or maintenance parsing.

## UI Foundation Track

### Pass 01 of 40: App-Assisted Handoff

Status: complete.

Goal:
- After receipt photo review, app-assisted reading must lead into receipt review/classification instead of feeling like a plain attachment picker.

Scope:
- Show reading status during OCR.
- Show success status telling the user to review parsed receipt lines below.
- Make OCR failure reset the reading state.
- Guard that parsed receipts scroll into review/classification.

Done:
- User sees that the app is reading the receipt.
- User sees where to review after reading.
- Parser application scrolls into review.
- Focused tests cover the handoff.

### Pass 02 of 40: Camera Shell Layout

Status: complete.

Goal:
- Make the live camera screen feel like Microsoft Lens plus Google Drive Scanner: fast, obvious, edge-controlled, and uncluttered.

Scope:
- Top bar: back, flash, settings, help if needed, all edge-aligned.
- Bottom bar: shutter, add/import option if appropriate, assisted/manual mode indicator.
- Remove any center-screen buttons that compete with the preview.
- Keep the preview dominant.
- Make settings a full screen or clean route, not a blocking bottom sheet over the camera.
- Keep manual shutter always available.

Done:
- User can open camera and immediately understand how to take a receipt photo.
- Preview is not covered by controls.
- No device capability details are visible to the normal user.
- S24 UI review is appropriate after this pass or after Pass 04 depending on batch size.

### Pass 03 of 40: Camera Interaction Basics

Status: complete.

Goal:
- Make the live camera behave like a normal high-quality camera app.

Scope:
- Pinch to zoom.
- Tap receipt text to focus.
- Flash modes are understandable.
- Manual shutter works even when automatic guidance is unsure.
- Capture button gives immediate feedback.
- Camera errors are plain-language and recoverable.

Done:
- User can zoom, focus, flash, and capture without fighting the app.
- Auto mode cannot prevent manual capture.
- Focus/capture wording matches real behavior.
- Tap focus now attempts focus and exposure independently so partial camera support still helps the user.
- Zoom and torch failures now use compact camera-surface feedback instead of disruptive UI.

### Pass 04 of 40: First-Use Camera Setup

Status: complete.

Goal:
- Explain advanced receipt capture without dumping settings into the capture surface.

Scope:
- First-use setup explains app-assisted receipt fill.
- Explain long receipt sections.
- Explain save-space copies in plain language.
- Explain automatic capture as optional.
- Add reset defaults.
- Keep setup short enough that a user can get to the camera quickly.

Done:
- First-time user understands the workflow.
- Returning user is not forced through setup again.
- UI build should be pushed to S24 after Pass 02-04 batch.
- Auto capture now turns on assisted camera mode because auto capture depends on assisted guidance.
- First-use setup now summarizes assisted fill, manual/auto capture, and saved-copy behavior in plain language.

### Pass 05 of 40: Photo Review Default Surface

Status: complete.

Goal:
- Make post-capture review look like a professional document/photo review surface.

Scope:
- Receipt image gets 75-80 percent of the screen when possible.
- Controls are compact and edge/bottom anchored.
- Primary action is obvious: `Read Receipt`.
- Secondary tools: crop, stitch, save space, retake, remove, add photo.
- No scroll-trap control panel.

Done:
- User can see the full receipt and continue without hunting for a button.
- Single photo does not use multi-photo wording.
- Default review now uses a compact action rail with `Read Receipt` as the primary action.
- Default preview reserves more room for the receipt image and removes the old two-row status pill/tool-chip layout.

### Pass 06 of 40: Photo Review Tool Modes

Status: complete.

Goal:
- Keep advanced tools available without cluttering default review.

Scope:
- Crop mode.
- Stitch mode.
- Save-space preview mode.
- Photo order mode for multi-photo receipts.
- Clear exit/back behavior between modes.

Done:
- Each tool has one job.
- User can return to preview without losing work.
- Tool mode controls never hide the area they are supposed to edit.
- Multi-photo receipts now have an explicit Order mode with thumbnails and Move Up / Move Down controls.
- Tool modes now have clear headers and a direct Preview return action.
- Single-photo receipts are guarded from entering Order or Stitch modes.

### Pass 07 of 40: S24 UI Review Batch 1

Status: complete.

Goal:
- Install the UI batch to the S24 Ultra for real visual inspection.

Scope:
- Build debug app.
- Install to S24 only unless user asks otherwise.
- User reviews live camera, first-use setup, and photo review.

Done:
- User has a real-device build for the first UI batch.
- Any obvious UI regressions are listed before moving deeper.
- S24 Ultra target `192.168.1.117:38847` resolved `com.maintainiac/.MainActivity`.
- Installed app package shows `lastUpdateTime=2026-06-26 17:19:11`, `versionName=1.0.0`, `versionCode=1`.
- App was brought to foreground and confirmed focused as `com.maintainiac/.MainActivity`.
- Crash log buffer was empty after launch.
- Real-device screenshot captured at `/tmp/maintainiac_s24_pass07_second.png`.
- First automated screenshot was black because the device was on the lock/notification surface and focused on ChatGPT; this was not treated as an app UI pass.
- Remaining review note: user still needs to visually walk through live camera, first-use setup, and photo review on the S24 before the camera UI is considered accepted.

## Camera Guidance And Image Capture Track

### Pass 08 of 150: Live Guidance Copy And States

Status: complete.

Goal:
- Make live guidance useful, short, and not annoying.

Scope:
- Guidance for move closer/farther.
- Guidance for glare/shadow.
- Guidance for long receipts.
- Guidance for unreadable/small text.
- No fake promise if the app is not actually detecting something.

Done:
- Guidance explains what the user should do next.
- Guidance never blocks manual capture.
- Live guidance now uses plain action wording for light, glare, focus, framing, small text, long receipts, and possible cut-off sections.
- Guidance no longer claims the app can see receipt edges when the current signal is only a best-effort framing/readability estimate.
- Manual shutter copy stays explicit: capture is allowed even when guidance is unsure.

### Pass 09 of 150: Auto Capture Confidence

Status: complete.

Goal:
- Make auto capture excellent enough to trust, but never overconfident.

Scope:
- Stability threshold.
- Focus/readability threshold.
- Brightness/contrast threshold.
- Minimum hold time before capture.
- Manual shutter remains available.

Done:
- Auto capture does not fire while user is still aligning.
- Auto capture can be turned off.
- Auto capture now uses a stricter policy than manual capture, including minimum focus, contrast, text-band, framing, hold-time, and stable-frame thresholds.
- Auto capture readiness badge now uses the same stricter gate as the actual auto-capture trigger.
- Manual shutter remains available even when the strict auto-capture gate is not ready.

### Pass 10 of 150: Camera Capability Defaults

Status: complete.

Goal:
- Use device capability in the background to choose sensible defaults.

Scope:
- Device tier.
- Camera capability.
- Low-storage state.
- OCR/parser workload limits.
- Keep device details out of normal UI.

Done:
- S9-class phones get safer defaults.
- S24/S25-class phones can do more local work.
- User sees simple modes, not creepy hardware details.
- Camera controller resolution fallbacks are driven by the background capability tier.
- Capability tests cover light, medium, and heavyweight capture defaults.
- Settings tests guard against exposing raw model/RAM/CPU/SDK details in normal receipt camera UI.

### Pass 11 of 150: Capture Diagnostics

Status: complete.

Goal:
- Record privacy-safe camera/capture health.

Scope:
- Capture started/completed/abandoned.
- Manual vs auto capture.
- Focus/readability score buckets.
- Retake count.
- Camera errors.
- No private image content.

Done:
- Command One can eventually show capture failure rates without seeing receipts.
- Privacy-safe receipt events now include capture started/completed/abandoned/failed event types.
- Capture diagnostics store only mode/outcome, capability tier, focus/readability buckets, section count, retake count, duration, and safe error kind.
- Receipt privacy health snapshots now expose capture success/failure/abandonment rates and bucket counts for Command One.

## Image Cleanup Track

### Pass 12 of 150: OCR Source Pipeline Audit

Status: complete.

Goal:
- Guarantee OCR reads the best prepared image before save-space copies.

Scope:
- Original capture.
- Prepared OCR source.
- Enhanced grayscale/contrast source.
- Saved backup proof.
- Cleanup of temporary files.

Done:
- Tests prove OCR source comes before backup optimization.
- Photo review prepares OCR source images before save-space copies.
- Saved backup copies are optimized from prepared images, but OCR still receives the prepared/stitch source paths.
- Cleanup now explicitly preserves every final OCR source path until the caller reads it and performs temporary OCR cleanup.

### Pass 13 of 150: Adobe-Style Enhancement Pass 1

Status: complete.

Goal:
- Improve receipt readability before OCR.

Scope:
- Grayscale.
- Contrast normalization.
- Brightness correction.
- Basic shadow handling.
- Paper tint reduction.

Done:
- Good receipt photos become cleaner without destroying text.
- OCR prep now evaluates multiple enhancement candidates and keeps the best readability score instead of applying one blunt filter.
- Baseline enhancement performs grayscale, brightness correction, normalization, and measured contrast strengthening.

### Pass 14 of 150: Adobe-Style Enhancement Pass 2

Status: complete.

Goal:
- Improve hard photos.

Scope:
- Wrinkled/faded receipts.
- Low contrast receipts.
- Thermal paper.
- Mild blur handling.
- Overexposed/underexposed areas.

Done:
- Enhancement helps OCR without making normal images worse.
- Added faded, thermal, shadow-balanced, and mild text-sharpen enhancement candidates.
- Synthetic faded/thermal/shadowed receipt tests guard that hard-photo prep does not lower review score or text-band detection.

### Pass 15 of 150: Crop And Perspective Foundation

Status: complete.

Goal:
- Improve automatic crop and perspective correction without relying on a required Google Play add-on.

Scope:
- Existing crop helpers audit.
- Safe automatic crop.
- Manual crop polish.
- Perspective correction when confidence is acceptable.
- Never block saving if crop confidence is low.

Done:
- Crop helps when safe and gets out of the way when unsure.
- Auto-crop now rejects tiny, off-center, or extreme-aspect candidate bounds before cropping.
- Crop guard tests prove suspicious off-center receipt-like patches do not get blindly cropped.

### Pass 16 of 150: Image Save-Space Preview

Status: complete.

Goal:
- Let the user understand backup size choices by seeing the result.

Scope:
- Save-space preview.
- Plain-language labels.
- Black-and-white default where appropriate.
- Keep OCR source separate from saved proof.

Done:
- User can choose storage tradeoff without developer terms.
- Saved-copy preview quality is now measured from the actual optimized saved-copy image, not the original full-quality source.
- Preview tests prove estimated saved copy quality matches the optimized image that would be kept.

## Long Receipt And Stitching Track

### Pass 17 of estimated 55: Long Receipt Capture Flow

Status: complete.

Goal:
- Make long receipt capture first-class.

Scope:
- Prompt user to add another photo.
- Explain not to squeeze tiny text into one photo.
- Keep photos ordered.
- Make top/middle/bottom sections obvious.

Done:
- A long Walmart/CVS-style receipt can be captured section by section.
- When adding the next receipt section, the camera shows a translucent bottom slice from the previous section as a nonblocking alignment guide.
- Additional-section capture keeps long-receipt guidance enabled instead of dropping to an unguided plain camera.
- Prepared OCR images now preserve original-quality source bytes when cleanup decides the original is safest, while still bounding oversized sources.
- Stitching and image-prep regression tests cover ghost guide wiring, manual overlap, scale differences, unsafe overlap fallback, hard-photo enhancement, crop safety, and OCR-before-save-copy behavior.

### Pass 18 of estimated 55: Capability-Gated Edge Detection Overlay

Status: complete.

Goal:
- Show a real receipt-edge frame only when the app has enough local signal to draw it honestly and safely.

Scope:
- Device/capability gating.
- Live edge estimate from camera frame analysis.
- Nonblocking overlay frame.
- No required Google Play add-on.
- Fallback to guidance-only mode on low tier/low confidence.

Done:
- Live camera analysis now estimates a normalized receipt/document frame from local image signal.
- The camera only draws the live edge frame when the device capability policy allows it and confidence is usable.
- Light-tier devices skip the live edge overlay and stay on guidance-only mode to avoid overloading older phones.
- The overlay is nonblocking, so tap focus and pinch zoom still work.
- Tests prove the overlay is capability-gated, signal-based, and not a fake always-on rectangle.

### Pass 19 of estimated 55: Multi-Photo Review And Ordering

Status: complete.

Goal:
- Make photo order obvious and correctable.

Scope:
- Ordered photo list.
- Move up/down.
- Retake one section.
- Remove one section.
- Add missing section.

Done:
- User can fix a bad middle photo without restarting.
- Multi-photo review now labels receipt sections as Top Photo, Middle Photo, and Bottom Photo.
- Order controls use plain receipt wording like Move Toward Top and Move Toward Bottom instead of vague page/order terms.
- The selected-photo status explains what that photo should contain, so a user can catch out-of-order sections before OCR.
- Focused analyzer and receipt review/stitching tests pass.

### Pass 20 of estimated 55: Automatic Stitching Core

Status: complete.

Goal:
- Stitch receipt sections when overlap confidence is safe.

Scope:
- Overlap detection.
- Duplicate line avoidance.
- Scale differences between photos.
- Slight rotation differences.
- Memory limits for older devices.

Done:
- Safe overlaps produce one stitched OCR source.
- Stitch matching now tolerates scale differences and slight handheld rotation between receipt sections.
- Candidate overlap matching now runs on bounded comparison images and only applies the winning correction to the full OCR image.
- Fallback results include the failed pair confidence metadata so Command Center/future diagnostics can show what failed.
- Oversized stitched receipts still fall back to separate OCR photos instead of risking memory pressure on older phones.
- Focused analyzer and stitching tests pass.

### Pass 21 of estimated 55: Manual Stitch Adjustment

Status: complete.

Goal:
- Let user correct stitching when automatic overlap is unsure.

Scope:
- Manual overlap slider.
- Pair-by-pair preview.
- Fallback warning.
- Preserve readability.

Done:
- User can rescue a stitch instead of being stuck.
- Stitch results now use receipt-photo language instead of generic page language.
- Manual overlap controls explain that the user is lining up repeated receipt text between photos.
- Fallback wording tells the user that separate OCR reading is safe when stitching confidence is too low.
- Focused analyzer, stitching tests, and camera help-flow guards pass.

### Pass 22 of estimated 55: Receipt Reading Handoff After Stitch Review

Status: complete.

Goal:
- After photo review, app-assisted receipt capture should move directly into OCR reading and receipt classification/review.

Scope:
- Verify `Read Receipt` / `Read Stitched Receipt` routes through OCR.
- Avoid returning the user to the receipt attachment area as a dead end.
- Preserve manual receipt flow when app assistance is off.
- Show clear reading/failure/success status.
- Keep OCR using source-quality photos before saved-copy compression.

Done:
- User accepts receipt photos and lands in a real review/classification workflow.
- Shared receipt photo handoff now reports whether OCR read a stitched receipt image, separate long-receipt photos, or one receipt photo.
- App-assisted disabled mode still skips OCR and leaves the user in manual/proof-only flow.
- OCR source photos are still read before temporary OCR artifacts are deleted.
- Focused analyzer, camera help-flow, and expense assisted-review tests pass.

### Pass 23 of estimated 55: Receipt Review Classification Landing

Status: complete.

Goal:
- Make the post-OCR receipt review feel like the actual next screen of the flow: classify the whole receipt, then only classify lines when mixed.

Scope:
- Whole receipt business/personal/mixed decision.
- Simple mode remains amount/classification focused.
- Detailed mode remains available.
- Mixed receipt line controls are clear.
- Totals/tax allocation stay visible.

Done:
- User can understand what to do immediately after OCR fills the receipt review.
- Receipt recap now keeps line-level Business/Personal/Split controls hidden until the receipt is mixed or split.
- Whole-receipt classification stays the primary action before line-by-line review.
- Mixed receipt totals explain that business/personal totals include line shares plus allocated tax or adjustment.
- Focused analyzer and assisted receipt review tests pass.

### Pass 24 of estimated 55: Receipt Tax And Split Allocation Review

Status: complete.

Goal:
- Make subtotal, tax, receipt total, business total, and personal total trustworthy for mixed receipts.

Scope:
- Show tax/adjustment allocation clearly.
- Guard negative lines/returns.
- Avoid double counting receipt totals.
- Make split percentages plain.
- Keep simple receipt mode fast.

Done:
- Mixed receipts make financial sense before save/export.
- Business/personal tax and receipt adjustment allocation now uses positive purchase shares instead of raw net subtotal.
- Negative lines/returns still reduce the side they belong to but do not receive extra tax allocation.
- Mixed receipt recap explains the allocation behavior in plain language.
- Focused analyzer and assisted receipt review tests pass.

### Pass 25 of estimated 55: Receipt Camera Device-Safe Limits

Status: complete.

Goal:
- Keep camera, stitching, OCR prep, and storage behavior safe across S9-class, mid-tier, and flagship devices.

Scope:
- Capability tier gates.
- Stitch/image max dimensions by tier.
- OCR source limits by tier.
- Auto-capture and live-edge limits by tier.
- Low-storage behavior.

Done:
- Older phones get safe defaults without blocking flagship-quality capture.
- Receipt stitch preview and final OCR stitching now use capability-tier max pixels and height.
- Light devices use smaller stitch bounds, medium devices use balanced bounds, and heavyweight devices can keep larger stitched OCR sources.
- Capability and camera help-flow tests guard the tiered behavior.

### Pass 26 of estimated 55: Receipt Photo Quality And Auto-Capture Tuning

Status: complete.

Goal:
- Make automatic capture helpful without trapping the user or refusing good photos.

Scope:
- Manual shutter always works.
- Auto capture needs stable readable frames.
- Quality score copy is plain-language.
- Tap-to-focus copy matches real behavior.
- Best-photo candidate selection does not confuse single-photo flow.

Done:
- Camera helps the user get a clear photo but does not fight them.
- Tapping the shutter now always uses the manual capture path, even when assisted or auto capture is active.
- Auto capture remains available only after stable readable frames meet the stricter auto policy.
- Focused analyzer and camera layout/quality tests guard the behavior.

### Pass 27 of estimated 55: Receipt Review Action Surface

Status: complete.

Goal:
- Make the after-photo review screen feel like a professional receipt scanner, not a hidden scroll panel.

Scope:
- Single-photo review should say `Review Receipt Photo`, not `Choose the best receipt photo`.
- The primary action should be visible as `Read Receipt` or `Use Photo`.
- Compact controls should not bury the continue action.
- Multi-photo controls should explain adding another photo and reading the full receipt.
- Saved-copy wording should be plain-language and not sound like a final save.

Done:
- User can take one photo and immediately see how to continue.
- User can add another receipt section for a long receipt without confusing it with saving the expense.
- Focused review tests cover the single-photo and multi-photo wording.
- Single-photo review now says `Review receipt photo` and `Review receipt photo, then read it.`
- Multi-photo review now says `receipt sections` and makes order/read intent clearer.
- `Saved copy` / `Save Space` UI copy is replaced with `Backup image` / `Backup Size`.
- Focused analyzer and review/help/assisted-flow tests pass.

### Pass 28 of estimated 55: Receipt Review Flow Routing

Status: complete.

Goal:
- After photo review, app-assisted receipts should continue into parsed receipt review instead of dumping the user back into an attachment-only state.

Scope:
- Confirm photo-review result returns OCR source paths, saved proof paths, stitch metadata, and quality metadata.
- Confirm expense receipt import reads reviewed photos immediately when app-assisted fill is on.
- Confirm success copy tells the user to review parsed lines, not simply that a photo attached.
- Confirm manual/no-assist mode can still attach proof photos without forcing OCR.
- Keep the route scoped to expenses and shared receipt capture, avoiding maintenance-specific flows.

Done:
- Assisted expense receipt photo flow reads the receipt and lands the user in review/classification.
- Manual proof-only flow still works.
- Focused tests cover both routes.
- Reviewed photos now report that parsed lines should be reviewed below after OCR finishes.
- Tests guard app-assisted opt-out, missing imported-text callback, empty OCR sources, and OCR-before-cleanup ordering.

### Pass 29 of estimated 55: Long Receipt Section Guardrails

Status: complete.

Goal:
- Help users capture long receipts in readable top-to-bottom sections without mixing up order or squeezing tiny text into one blurry photo.

Scope:
- Keep previous-section ghost guide when adding/retaking later sections.
- Make single-photo and multi-photo review copy explain sections plainly.
- Keep ordering controls available only when needed.
- Keep stitching optional with safe fallback to reading ordered photos separately.
- Avoid blocking receipt save when stitch confidence is low.

Done:
- Long receipt users can add sections, check order, review stitch, and still continue if stitching is not confident.
- Focused tests guard the section flow and fallback wording.
- Adding or retaking into multiple receipt sections now opens the photo-order review step automatically.
- Previous-section guide handoff remains wired into add/retake camera launches.
- Focused analyzer and camera/stitching tests pass.

### Pass 30 of estimated 55: Receipt Review Device UI Batch

Status: deferred until user asks for device install.

Goal:
- Put the current camera/review UI batch on the S24 Ultra only after the bundled review changes are worth inspecting.

Scope:
- Build/install debug app only if the S24 is available and user wants the UI batch.
- Do not uninstall unrelated Maintainiac builds.
- Verify the app launches.
- Let user inspect live camera, after-photo review, add-section order flow, and read-receipt handoff.

Done:
- S24 Ultra has the latest meaningful UI batch for review.
- Any device-only defects are listed as the next UI pass.

### Pass 31 of estimated 55: Separate OCR Fallback Guardrails

Status: complete.

Goal:
- Make ordered separate-photo OCR safer for long receipts when stitching is unavailable, low-confidence, or intentionally skipped.

Scope:
- Suppress true section-boundary overlap.
- Do not remove legitimate duplicate item lines inside the same section.
- Do not remove legitimate duplicate item lines that appear later in a different section when they are not overlap.
- Warn when neighboring receipt sections have no repeated text and may be missing a middle section.
- Keep raw text intact for proof/review while parser text is cleaned for app-assisted fill.

Done:
- OCR overlap suppression is boundary-aware instead of global.
- Missing section gaps now create a review warning without changing text.
- Legitimate duplicate item lines are preserved.
- Focused analyzer and OCR long-receipt tests pass.

### Pass 32 of estimated 55: OCR Diagnostics Hardening

Status: complete.

Goal:
- Make OCR outcomes explainable without exposing private receipt content.

Scope:
- Confirmed warning kinds for duplicate overlap, possible section gap, photo quality, skipped proof-only sources, PDF safety, PDF too large, unreadable files, plugin unavailable, and no readable text.
- Diagnostics should summarize severity, counts, source type, and review needs without storing receipt text.
- Command One-safe health data should remain content-free.

Done:
- OCR diagnostics clearly say what failed or needs review and why.
- Focused diagnostics tests cover warning kinds and severity.
- OCR diagnostics now expose privacy-safe warning-kind counts.
- Expense OCR review records persist warning-kind counts through draft, ledger, and Firestore-shaped receipt backups.
- Section-gap OCR warnings map to `possible_missing_receipt_section` instead of a vague or duplicate-text cause.
- Focused analyzer and OCR diagnostics/storage tests pass.

### Pass 33 of estimated 55: Parser Field Confidence Hardening

Status: complete.

Goal:
- Improve receipt parser confidence for merchant, date, subtotal, tax, total, payment, and receipt identifiers without trusting bad OCR too quickly.

Scope:
- Merchant/date/total confidence labels.
- Explicit subtotal/tax/total reconciliation.
- Fuel, retail, and trade-supply receipt field patterns.
- Negative/return lines should be understood as adjustments, not confidence penalties by themselves.
- Parser warnings should remain content-safe for diagnostics.

Done:
- Parser field extraction has clearer confidence and review reasons.
- Focused parser tests cover core field extraction and suspicious math.
- Parse results and diagnostics now expose field confidence for merchant, date, time, subtotal, tax, total, line items, and receipt math.
- Known merchant profiles, OCR dates, explicit totals, inferred totals, fallback dates, and line/math reconciliation now get distinct review reasons.
- Focused analyzer and parser torture tests pass.

### Pass 34 of estimated 55: Parser Review Failure Reasons

Status: complete.

Goal:
- Make parser failures and review states explain exact root causes in plain language for receipt review and future Command One metrics.

Scope:
- Normalize parser warning kinds without storing receipt content.
- Distinguish missing fields, inferred fields, line mismatch, subtotal/tax/total mismatch, too many low-confidence lines, and catalog/material review.
- Keep negative coupon/discount/return lines from lowering confidence when they reconcile.
- Make tests prove the failure reason points at the exact failing parser stage.

Done:
- Receipt parser review reasons are specific enough to route UI help and diagnostics.
- Focused parser tests cover missing, mismatched, inferred, and low-confidence receipt states.
- Parser diagnostics now distinguish inferred subtotal/tax/total and fallback receipt dates from generic low confidence.
- Parser failure evidence includes content-free field review labels for Command One summaries.
- Focused analyzer, parser diagnostics, parser, and expense telemetry tests pass.

### Pass 35 of estimated 55: Parser Review UI Guidance

Status: complete.

Goal:
- Surface parser field confidence and exact review causes in the assisted receipt review UI using plain language.

Scope:
- Show user-facing parser guidance without raw diagnostic jargon.
- Prioritize merchant/date/total/math/line review warnings.
- Keep private receipt content out of telemetry and diagnostics.
- Avoid changing maintenance-specific receipt behavior.

Done:
- Assisted receipt review explains what needs checking and why.
- Focused UI or widget tests cover the guidance surface.
- Receipt entry now stores the latest parser field confidences and clears stale confidence state when loading drafts or saved receipts.
- Receipt Fill Review now shows a compact `Fields to check` summary with plain-language merchant/date/total/math/line guidance.
- Focused analyzer and assisted review/parser tests pass.

### Pass 36 of estimated 55: Privacy-Safe Parser Health Metrics

Status: complete.

Goal:
- Feed parser field confidence and review causes into local telemetry summaries without storing receipt text or private item details.

Scope:
- Add content-free parser field review counts where telemetry already tracks parser outcomes.
- Include exact parser cause buckets for inferred totals, fallback dates, receipt math, line mismatch, and line review.
- Keep raw receipt text, merchant names, addresses, notes, and item descriptions out of telemetry.

Done:
- Expense telemetry can summarize parser health by field/cause.
- Focused privacy tests prove no private receipt content is stored.
- Privacy-safe receipt parse events now include parser review cause and field review keys.
- Command Center health snapshots now count parser review causes and field review keys without merchant names, receipt text, item names, or amounts.
- Existing app-assisted parse flow already queues these privacy-safe parse events.
- Focused analyzer, receipt privacy, parser diagnostics, and expense telemetry tests pass.

### Pass 37 of estimated 55: Receipt Backup Image Pipeline Audit

Status: complete.

Goal:
- Confirm the receipt image pipeline reads OCR from the best available image first, then creates space-saving backup copies without making OCR worse.

Scope:
- Audit original/captured image, enhanced image, stitched image, backup-size preview, and saved proof path.
- Ensure OCR is not forced to read only from heavily compressed backup copies.
- Keep backup/storage wording user-friendly: save space, backup image, phone/cloud storage.
- Add tests around OCR-before-backup-copy behavior where practical.

Done:
- Receipt photo proof storage remains lean without sacrificing OCR input quality.
- Focused tests document the order of operations.
- `ReceiptImageProcessor.prepareForOcrAndBackup` now makes the clean OCR source and smaller backup copy explicit outputs.
- Photo review save uses the clean OCR source for reading and the backup copy for stored proof.
- Focused analyzer and image/camera review tests pass.

### Pass 38 of estimated 55: Receipt Proof Storage And Backup Metadata

Status: complete.

Goal:
- Make saved receipt proof metadata clear enough for local storage, export, cloud backup, and Command One cost/health reporting.

Scope:
- Audit saved proof records for data saver level, byte size, source type, staged/permanent path handling, and cloud-safe fields.
- Confirm optimized receipt proof paths are kept out of Firestore backup documents.
- Confirm local proof files remain recoverable for drafts and saved receipts.
- Avoid changing maintenance-specific receipt behavior.

Done:
- Receipt proof records preserve storage-size metadata without syncing private local paths.
- Focused storage and Firestore document tests pass.
- Firestore receipt proof pointers now include backup byte size and a safe backup size bucket for cost/storage health reporting.
- Local proof paths, raw OCR, imported proof text, and raw line OCR remain excluded from backup documents.
- Focused analyzer, Firestore backup, and proof storage lifecycle tests pass.

### Pass 39 of estimated 55: Receipt PDF OCR Safety Review

Status: complete.

Goal:
- Harden receipt PDF input so readable PDFs work, unsafe PDFs stay proof-only, and older phones avoid expensive PDF work.

Scope:
- Audit PDF inspection, page limits, timeout behavior, and OCR warning mapping.
- Confirm PDF proof storage remains read-only and cloud backup metadata stays lean.
- Confirm unreadable or unsafe PDFs never block saving the receipt proof.
- Keep invoice PDF generation separate from receipt PDF import unless a shared utility is clearly appropriate.

Done:
- PDF receipt import behavior is predictable, bounded, and explainable.
- Focused PDF OCR/proof tests pass.
- OCR service now tracks planned PDF page work before reading instead of assuming every PDF read used the maximum page cap.
- Device-specific PDF page-limit warnings explain when only the front pages will be read while the full PDF remains saved as read-only proof.
- Focused analyzer plus OCR/PDF/share/proof torture tests pass.

### Pass 40 of estimated 55: Receipt Import Failure Recovery

Status: complete.

Goal:
- Make failed receipt import/reading states recoverable without losing proof attachments or trapping the user in the wrong screen.

Scope:
- Audit photo/PDF/imported-text failure branches after app-assisted reading.
- Confirm failed OCR does not discard attachments, staged proof records, or user-entered receipt info.
- Confirm retry/manual-entry messaging uses plain receipt language and avoids developer terms.
- Keep maintenance-specific receipt flows untouched.

Done:
- Failed receipt reading leaves the user with proof saved, clear recovery choices, and no duplicate staged attachments.
- The attachment panel now has separate reading, success, warning, and failed visual states.
- Receipt-reading failures now keep clear plain-language recovery copy: keep proof, try another photo, retake, or continue manually.
- The add-more action after proof exists now says `Add More Proof` instead of implying a new receipt.
- Focused analyzer plus attachment/OCR/PDF import tests pass.

### Pass 41 of estimated 55: Receipt Review Classification Completion

Status: complete.

Goal:
- Finish the app-assisted receipt review handoff so a read receipt naturally lands on business/personal/mixed classification with line-level review instead of feeling like a plain attachment return.

Scope:
- Audit the expense receipt review panel for whole-receipt classification, mixed receipt line controls, and split tax/total recap.
- Make sure simple mode and detailed mode wording is plain and receipt-specific.
- Confirm OCR success routes to review and failure routes to recover/manual entry.
- Keep the separate detailed item editor route; do not rebuild it inline.

Done:
- After receipt reading succeeds, the user can classify the receipt and its lines without guessing what screen they are on.
- Assisted review order now starts with `What Maintainiac Found`, then whole-receipt classification, then parser line evidence, then the totals recap.
- The review copy now tells the user to check store, date, totals, and line confidence before saving.
- Focused analyzer, assisted review, parser, and parser diagnostic tests pass.

### Pass 42 of estimated 55: Receipt Data Saver Preview Completion

Status: complete.

Goal:
- Make receipt save-space choices understandable and previewable without making users learn image-compression terms.

Scope:
- Audit data saver wording, preview sizes, backup image labels, and review controls.
- Confirm OCR uses the best available source before backup-size reduction.
- Confirm users can understand what is stored locally/cloud-backed versus what is used temporarily for reading.
- Keep the data saver settings out of the way of receipt crop/review.

Done:
- Users can pick a storage-saving receipt proof level with clear language and without hurting OCR accuracy.
- Data saver copy now uses `saved proof` language instead of making users think about compression.
- Photo review and settings now explain that OCR uses the clear photo first, then the smaller proof copy is kept.
- The saved-proof preview panel now labels the actual kept image and storage details clearly.
- Focused analyzer plus camera help, data-saver image, and camera layout tests pass.

### Pass 43 of estimated 55: Receipt Save Readiness Guardrails

Status: complete.

Goal:
- Prevent users from saving confusing assisted receipts without clear line, classification, proof, and review state.

Scope:
- Audit save validation for parsed lines, missing proof, unreviewed parser lines, mixed receipt allocations, and subtotal/tax/total math.
- Keep warnings plain-language and actionable.
- Confirm save guardrails do not block simple manual expense entry unnecessarily.
- Keep maintenance-specific save behavior untouched.

Done:
- Expense receipt save gives clear reasons when the receipt needs another review step before saving.
- Save readiness now runs before duplicate detection, proof persistence, and ledger save.
- The readiness dialog explains unreviewed app-filled lines, OCR no-text/blocking/partial/review warnings, and receipt subtotal versus line subtotal mismatches.
- The user can review the receipt or save anyway after verification; simple manual entry is still only hard-blocked when no lines exist.
- Abandoned readiness review records privacy-safe telemetry with confirmed issue kinds, not receipt content.
- Focused analyzer plus assisted review, telemetry, and duplicate-save tests pass.

### Pass 44 of estimated 55: Saved Receipt Detail And Calendar Recovery

Status: complete.

Goal:
- Make saved receipt review from calendar/detail screens preserve the same proof, OCR review, classification, totals, and edit context the user just created.

Scope:
- Audit saved expense receipt detail and calendar entry routes.
- Confirm proof thumbnails/PDF pointers open without losing receipt context.
- Confirm business/personal/split totals and receipt OCR review metadata are visible in plain language.
- Confirm edit routes reuse the receipt flow instead of creating a disconnected duplicate path.
- Keep maintenance-specific receipt handling untouched.

Done:
- A saved receipt can be found later, reviewed, understood, and edited without losing app-assisted receipt context.
- Calendar day entries and home ledger rows now open saved receipt detail first instead of immediately dropping into edit mode.
- Saved receipt detail now shows a receipt breakdown with business total, personal total, split-line count, proof count, and OCR/read status.
- Saved receipt line totals use the receipt's allocated total so tax/adjustment context is preserved during later review.
- Saved receipt photos are tappable and open a pinch-zoom proof viewer; saved PDFs still open the PDF proof viewer.
- Focused analyzer plus saved receipt detail, assisted review, and telemetry tests pass.

### Pass 45 of estimated 55: Receipt Calendar Add/Edit/Delete Diagnostics

Status: complete.

Goal:
- Make calendar-side receipt actions explain exactly what failed and keep Command One-ready diagnostics privacy-safe.

Scope:
- Audit add-line, edit-line, copy-line, delete-line, full-receipt edit, and delete-receipt paths from saved receipt detail/calendar.
- Confirm each action records success/failure where appropriate without private receipt content.
- Confirm failures show plain recovery messages instead of silent no-ops.
- Confirm calendar entries stay chronological by receipt date/time after edits.
- Keep maintenance-specific receipt behavior untouched.

Done:
- Calendar-side receipt edits are observable, recoverable, and do not silently fail.
- Calendar receipt delete, line edit, line copy, and line delete failures have distinct confirmed-cause diagnostics for future Command One health views.
- Calendar-side recovery copy is source-guarded so failures remain plain-language instead of silent.
- The telemetry aggregation test now covers all four calendar receipt action failure causes.
- Focused analyzer plus saved receipt detail, assisted review, and telemetry tests pass.

### Pass 46 of estimated 55: Receipt Export Proof Bundle Readiness

Status: complete.

Goal:
- Make exported receipt records preserve proof status, OCR review status, business/personal totals, and line details without bloating user data.

Scope:
- Audit expense export models and file writer for receipt proof metadata.
- Confirm exports can include proof references/counts without embedding giant private images by default.
- Confirm business, personal, split, tax, and total fields match saved receipt detail.
- Confirm export events distinguish completed, blocked, and failed outcomes.
- Keep invoice/maintenance PDF export behavior untouched.

Done:
- Expense receipt export data is complete enough for recordkeeping while staying storage-conscious.
- Receipt CSV now includes proof count, proof types, saved proof byte total, OCR review status, OCR warning count, parser line count, and requested PDF pages.
- Export manifests now summarize proof count, proof bytes, missing-proof receipts, OCR-reviewed receipts, and receipts needing OCR review.
- Export privacy notes state that raw OCR text and receipt images are not embedded by default.
- Existing line export keeps tax-adjusted totals, business amounts, personal amounts, and split percentages.
- Focused analyzer plus export and telemetry tests pass.

### Pass 47 of estimated 55: Synthetic End-To-End Receipt Regression Matrix

Status: complete.

Goal:
- Prove the receipt pipeline against repeatable synthetic receipt cases before relying on real-world phone testing.

Scope:
- Audit existing synthetic Lowe's, Home Depot, Walmart, CVS, fuel, return, wrinkled/noisy, and long receipt tests.
- Add missing end-to-end expectations for OCR text normalization, parser results, review flags, business/personal/mixed classification, proof metadata, and export readiness.
- Keep synthetic images/text privacy-safe and deterministic.
- Keep maintenance-specific receipt setup untouched.

Done:
- The receipt system has a repeatable regression matrix showing what is covered and what still requires real-device testing.
- Added an end-to-end synthetic matrix that parses all fixture packs into real `ExpenseReceiptRecord` objects, checks saved proof/OCR metadata, verifies business plus personal totals reconcile, and exports the records.
- The matrix proves export readiness includes proof metadata and OCR review metadata while keeping raw OCR text out of the receipt CSV.
- Existing regression report still covers 14 fixtures across core, materials, noisy OCR, damaged, and trade supply packs with 14/14 ready fixtures.
- Focused analyzer plus end-to-end matrix, regression report, long retail torture, and export tests pass.

### Pass 48 of estimated 55: Receipt Stitching And OCR Handoff Stress Matrix

Status: complete.

Goal:
- Prove stitched, multi-photo, duplicate-overlap, and missing-section receipt inputs hand off safely to OCR/parser review.

Scope:
- Audit existing receipt stitching and combined OCR text stress tests.
- Add matrix expectations for overlap suppression, section ordering, missing middle section warnings, and fallback-to-separate OCR behavior.
- Confirm long receipt handoff does not trust low-confidence or incomplete stitched output.
- Confirm older-device limits remain bounded and do not require all images in memory forever.

Done:
- Multi-photo receipt capture has repeatable stress coverage before real-device long-receipt testing.
- Added a section handoff matrix that drives multi-section receipt text through OCR app-fill and the expense parser.
- The matrix covers ordered overlap suppression, missing middle sections, out-of-order sections, and similar-but-different overlap lines that must not be deleted.
- Missing and out-of-order sections now have regression coverage proving they stay reviewable and are not treated as trusted math.
- Focused analyzer plus stitching, combined OCR, and long-retail torture tests pass.

### Pass 49 of estimated 55: Receipt Camera Capability And Low-End Device Stress Review

Status: complete.

Goal:
- Prove receipt capture, stitching, OCR limits, and saved proof behavior stay bounded on older and lower-capability devices.

Scope:
- Audit receipt device capability detection, camera capture policy, PDF/OCR limits, stitching output limits, data saver defaults, and low-storage behavior.
- Add or tighten tests for light, medium, and heavyweight capability tiers.
- Confirm manual capture always works even when automatic capture is not confident.
- Confirm long-receipt stitching falls back cleanly when output size exceeds a device tier.
- Confirm user-facing labels do not expose creepy device details, while diagnostics keep privacy-safe capability context.

Done:
- Low-end device behavior is covered before broader camera UI/device testing resumes.
- Stitch output limits now live in the shared receipt capability policy instead of private review-screen UI code.
- Photo review uses `ReceiptDeviceCapability.stitchLimits`, so older, medium, and heavyweight devices share the same tested limits everywhere.
- Capability tests now cover stitch output ceilings, low-end camera defaults, large-photo review on older phones, and no raw hardware detail leakage in setup/settings surfaces.
- Focused analyzer plus assistance policy, OCR service, stitching, and combined OCR handoff tests pass.

### Pass 50 of estimated 55: Receipt Review Route And Classification Contract

Status: complete.

Goal:
- Prove the app-assisted receipt flow routes to receipt review/classification after photo OCR instead of dropping the user back into a plain attachment screen.

Scope:
- Audit receipt attachment import actions, expense receipt entry routing, app-assisted mode handling, and classification landing tests.
- Add or tighten source/behavior tests proving `Read Receipt` leads to parsed review rows.
- Confirm business, personal, and mixed classification choices remain available after OCR.
- Confirm quick classify and detailed item modes are user-facing choices with plain wording, not developer jargon.
- Keep maintenance-specific receipt setup out of scope.

Done:
- App-assisted receipt capture has a tested route contract from accepted photos to review/classification.
- The assisted receipt review source-contract test now covers the reviewed-photo import path.
- The test proves attachment state is published, reviewed OCR photos are read for app-assisted review, and temporary OCR copies are cleaned up after handoff.
- The test covers stitched, separate-photo fallback, multi-photo, and single-photo success messages that direct the user to parsed receipt lines below.
- Focused analyzer plus assisted review, saved receipt detail, and expense telemetry tests pass.

### Pass 51 of estimated 55: Receipt Data Saver Preview And OCR Source Contract

Status: complete.

Goal:
- Prove OCR reads the best prepared receipt source before saved-copy shrinking, while the user can still choose a smaller cloud/local proof copy after review.

Scope:
- Audit image preparation, OCR source photo paths, data saver preview, saved proof copies, and attachment metadata.
- Add or tighten tests proving OCR source paths are separate from saved proof copies when needed.
- Confirm data saver language remains user-friendly and not developer/compression jargon.
- Confirm grayscale/space-saving copies are for saved proof/storage, not the first OCR read.
- Confirm selected saved-copy level persists without changing raw OCR diagnostic text.

Done:
- Receipt photo reading and receipt proof storage are contractually separated.
- Added prepared saved-proof preview helpers so the preview estimates and preview image use the same OCR-prepared source as the final saved proof copy.
- Photo review now uses `previewPreparedBackupFile` and `optimizePreparedBackupFile`, preventing the UI from previewing an unprepared camera image while saving a prepared receipt proof.
- Data saver tests now prove OCR source and saved proof are separate, prove final backup quality/size matches the prepared preview pipeline, and tolerate only tiny JPEG score variance.
- Source-contract tests now cover prepared preview helpers, OCR-before-backup order, and reviewed-photo handoff cleanup.
- Focused analyzer plus data saver, camera help, assisted review, and OCR service tests pass.

### Pass 52 of estimated 55: Receipt Saved Proof Lifecycle And Cleanup Audit

Status: complete.

Goal:
- Prove temporary receipt OCR artifacts, data-saver previews, stitch previews, best-shot extras, and saved proof files are kept or deleted at the right time.

Scope:
- Audit generated file cleanup in camera review, attachment import, proof storage, drafts, and saved expense records.
- Add or tighten tests proving saved proof files are preserved while temporary OCR/stitch/preview artifacts are cleaned after handoff.
- Confirm cleanup never deletes the saved receipt proof path or user-selected source still needed by the receipt.
- Confirm cleanup is best-effort and cannot crash the receipt workflow.

Done:
- Receipt file lifecycle has explicit regression coverage before real-device long receipt testing.
- Prepared backup preview helpers now await cleanup of temporary OCR-prepared source files instead of leaving cleanup fire-and-forget.
- Added a direct cleanup test proving prepared backup preview/optimization leaves the saved optimized proof and does not leak temporary enhanced OCR artifacts.
- Source-contract coverage now checks review-screen cleanup hooks, best-shot cleanup, stitch/data-saver preview cleanup, and imported OCR source cleanup that skips saved receipt photo paths.
- Existing proof storage lifecycle tests still prove staged proof promotion, rollback, orphan cleanup, draft retention, and staged-copy deletion behavior.
- Focused analyzer plus data saver, camera help, proof storage lifecycle, and draft storage lifecycle tests pass.

### Pass 53 of estimated 55: Receipt Final Synthetic Stress And Coverage Review

Status: complete.

Goal:
- Run the broadest practical synthetic receipt/camera/OCR/parser/export regression set and identify any remaining hardening passes before moving to real-device receipt tests or PDF/invoice hardening.

Scope:
- Run focused receipt camera/OCR/parser/export/telemetry tests together.
- Review the pass plan for remaining gaps versus the receipt camera/OCR/product standard.
- Fix small discovered gaps where safe; otherwise add explicit next-pass items.
- Do not push a device build unless the user asks.

Done:
- The receipt capture/OCR/parser foundation has a current synthetic QA snapshot and a short remaining-work list.
- Focused analyzer passed for shared receipt capture, expense entry, export models, and the receipt/camera/OCR/export/telemetry/storage tests used in this pass.
- Camera/settings tests passed: data saver, camera help, quality guidance, capture layout, assistance policy, and settings store.
- OCR/stitch/parser tests passed: stitching, combined OCR handoff, OCR service, end-to-end regression matrix, regression report, and long retail torture.
- Expense/export/storage tests passed: assisted receipt review, saved receipt OCR detail, export, telemetry, proof lifecycle, and draft lifecycle.
- Synthetic regression report stayed at 14/14 ready fixtures, 100.0% pass, 95.6% quality, 98.8% readiness, and 0 issue buckets.

### Pass 54 of estimated 55: Receipt Real-Device Readiness Checklist And Manual Test Script

Status: complete.

Goal:
- Convert the synthetic receipt evidence into a practical S24/S9/iPhone manual test checklist so real-device testing is deliberate instead of random.

Scope:
- Define exact phone test flows for single-photo receipts, long multi-photo receipts, add-photo order changes, manual capture, auto guidance, save-space preview, app-assisted review, manual/no-assist mode, PDF import, and proof recovery.
- Keep the checklist privacy-safe and written in plain language.
- Identify the small number of device builds worth pushing instead of reinstalling after every tweak.
- List remaining pass candidates before moving into heavier PDF/invoice hardening.

Done:
- User has a concise receipt-device test script that says what to tap, what should happen, what must never happen, and what evidence to report back.
- Added `docs/receipt_real_device_test_script.md` covering single-photo receipts, long multi-photo receipts, save-space preview, app-assisted review, manual/no-assist mode, PDF receipt import, interruption recovery, and failure reporting.
- The script names the expected behavior and "must never happen" checks for each flow so S24/S9/iPhone testing is useful instead of vague.

### Pass 55 of estimated 55: Receipt Remaining Gaps And PDF/Invoice Bridge Decision

Status: complete.

Goal:
- Decide whether the receipt camera/OCR foundation is ready for real-device validation, or whether one more code-hardening pass is needed before moving into PDF/invoice hardening.

Scope:
- Review remaining product-standard gaps against the synthetic evidence and real-device script.
- Identify the smallest safe next code pass if there is a known gap.
- Separate receipt-camera/OCR work from invoice PDF generation/send/receive hardening.
- Do not touch maintenance-specific receipt paths.

Done:
- The next work lane is explicit: either device validation, a named receipt gap fix, or the next PDF/invoice hardening pass.
- Decision: receipt camera/OCR foundation is ready for controlled real-device validation, not random stress testing.
- Fixed a remaining user-facing wording gap: saved receipt detail and OCR summaries now say receipt lines are ready for review instead of showing developer-facing parser/raw-line language.
- Kept raw/parser line counts in storage, exports, privacy-safe diagnostics, and Command One-ready telemetry where they are useful for debugging and health reporting.
- Focused analyzer and OCR/detail tests pass after the wording fix.

## PDF And Invoice Hardening Track

### PDF Pass 56 of up to 200: Generated PDF Boundary Validation

Status: complete.

Goal:
- Make every app-generated PDF prove it is a safe, complete PDF before Maintainiac writes, previews, archives, prints, shares, or stores it as invoice/document proof.

Scope:
- Add shared generated-PDF validation for empty bytes, missing PDF header, missing EOF marker, over-large files, and unsupported active PDF features.
- Sanitize generated PDF filenames through one shared helper.
- Apply validation to temporary generated PDF writes, printing, sharing, and permanent generated-document archive.
- Share the already prepared preview file instead of silently generating another temporary PDF from the share button.
- Keep invoice PDF bytes generated from structured invoice data; do not store invoice PDFs inside invoice ledger records.

Done:
- `AppGeneratedPdfDocument` exposes validation and sendable status.
- `AppGeneratedPdfService` refuses invalid generated PDFs before temporary write, print, or share.
- `AppGeneratedPdfArchiveService` refuses invalid generated PDFs before permanent document archive.
- `AppGeneratedPdfPreviewScreen` shares the already prepared preview file.
- Focused analyzer passed for generated PDF services, invoice renderer/factory, and related tests.
- Focused tests passed for generated PDF service and invoice template PDF factory.

### PDF Pass 57 of up to 200: Invoice PDF Send/Archive Lifecycle Audit

Status: complete.

Goal:
- Prove invoice and estimate PDFs can be generated, previewed, shared/sent, printed, archived, and later recovered without duplicate temp buildup, incomplete files, or private-data backup mistakes.

Scope:
- Audit invoice PDF preview entry points and record-specific PDF generation.
- Confirm permanent archive links generated invoice PDFs to invoice records without storing PDF bytes in the invoice ledger.
- Add lifecycle tests for record-specific invoice/estimate PDFs, archive duplicate handling, and file hash/byte-size metadata.
- Keep customer contact/payment data as structured invoice data; generated PDFs remain derived artifacts.
- Do not touch maintenance-specific PDF flows unless a shared generated-PDF utility requires it.

Done:
- Invoice PDF send/archive lifecycle has focused regression coverage and a short remaining gap list before incoming invoice/document PDF work.
- Record-specific invoice PDFs are now tested as sendable, safe-named, archived permanent document proof linked to the invoice record, and excluded from invoice ledger maps.
- Record-specific estimate PDFs are tested as generated estimate documents archived as invoice document proof.
- Focused analyzer passed for invoice PDF factory/renderer, generated PDF services, archive service, and tests.
- Focused tests passed for generated PDF service, invoice template PDF factory, and invoice ledger store.

### PDF Pass 58 of up to 200: Incoming Invoice/Document PDF Routing

Status: complete.

Goal:
- Make incoming/shared invoice, estimate, proposal, job, and contractor PDFs route to document/invoice proof handling instead of being mistaken for ordinary expense receipts.

Scope:
- Audit incoming shared PDF classification and destination UI.
- Strengthen invoice/estimate/job-document keyword handling without reading or storing private content in diagnostics.
- Add tests for incoming invoice PDFs, estimate PDFs, manual PDFs, and regular receipts.
- Keep maintenance receipt routing untouched.

Done:
- Shared invoice/estimate PDFs are suggested as job/invoice documents and can be saved as read-only proof without forcing the expense receipt flow.
- Invoice, estimate, proposal, work order, scope of work, bill-to, amount-due, balance-due, and payment-terms signals now weigh strongly toward job/contractor document routing.
- The job/contractor document suggestion copy now uses user-facing language and explains read-only proof instead of saying an internal feature is not wired.
- Incoming invoice and estimate PDF widget tests prove those PDFs are not mistaken for ordinary expense receipts.
- Existing generic receipt PDF, other document PDF, and PDF torture routing tests still pass.

### PDF Pass 59 of up to 200: Generated PDF Preview And Share Failure Recovery

Status: complete.

Goal:
- Make generated invoice/estimate PDF preview, share, print, and failure states clear and recoverable before deeper invoice-delivery work.

Scope:
- Audit `AppGeneratedPdfPreviewScreen` for validation errors, missing temp files, incomplete prepared files, and share/print dismissals.
- Add tests for preview error wording and share-file failure handling without needing a real platform share sheet.
- Confirm the user sees plain language and can regenerate instead of being stuck.
- Keep this pass focused on generated invoice/estimate PDFs, not maintenance PDFs.

Done:
- Generated PDF UI and service failure states are covered by tests and use user-safe recovery copy.
- Preview generation failures now show a plain-language error plus a `Try Again` action.
- Share and print platform failures now show friendly recovery messages instead of only handling generated-PDF validation errors.
- Preview sharing continues to use the already prepared generated file.
- Widget tests cover retry after preparation failure, friendly share failure, and friendly print failure.
- Focused analyzer and generated PDF preview/service tests pass.

### PDF Pass 60 of up to 200: Invoice PDF Delivery Metadata And Audit Trail

Status: complete.

Goal:
- Track invoice/estimate PDF generation and delivery attempts as structured, privacy-safe invoice events without storing PDF bytes or private document text in the invoice ledger.

Scope:
- Audit invoice audit events and delivery-related status transitions.
- Add structured helpers for PDF generated, previewed, shared/sent, printed, archived, and failed delivery attempts where feasible.
- Preserve local-first invoice records and keep generated PDFs as derived artifacts.
- Add tests proving delivery metadata is useful without embedding PDF bytes or customer/private document text.

Done:
- Added structured `InvoicePdfDeliveryEvent` records for generated, previewed, archived, shared, sent, printed, and failed PDF actions.
- `InvoiceRecord` now preserves `pdfEvents` through copy, map serialization, and reload.
- Added record helpers for generated, previewed, archived, shared, printed, and failed PDF delivery events.
- PDF event metadata stores action type, timestamp, safe filename, byte size, hash, source id, and reason code without storing PDF bytes, PDF paths, customer names, addresses, emails, notes, share text, or document body text.
- Focused analyzer and invoice/PDF ledger tests pass.

### PDF Pass 61 of up to 200: Invoice PDF Firestore/Backup Shape Audit

Status: complete.

Goal:
- Make sure invoice PDF metadata and delivery events have a cost-safe, privacy-safe backup shape for future Firestore mirroring.

Scope:
- Audit invoice daily backup batches and generated PDF document attachment metadata.
- Ensure invoice PDF events stay small enough to live in structured ledger records without storing PDF bytes or local-only paths.
- Add tests for Firestore-like map payload shape, event count bounds, and privacy-safe document metadata.

Done:
- Added a bounded invoice PDF delivery history limit so one invoice cannot grow an unlimited delivery log.
- Invoice record PDF event helpers keep only the newest bounded delivery events.
- Added tests proving invoice daily backup batches include PDF metadata, exclude PDF bytes and local paths, and keep event history bounded.
- Documented invoice/estimate Firestore backup scope, derived PDF artifact handling, and forbidden PDF event content.
- Focused analyzer and invoice/PDF ledger tests pass.

### PDF Pass 62 of up to 200: Invoice PDF Form Action Wiring

Status: complete.

Goal:
- Make invoice form preview/share/print/save actions update the invoice record PDF delivery trail where feasible.

Scope:
- Audit current invoice form PDF preview, archive, share, and error paths.
- Wire generated, archived, shared/printed/failed metadata into saved invoice records without changing user-facing workflow unless necessary.
- Keep generated PDFs as derived artifacts and avoid storing file paths or PDF bytes in invoice records.
- Add focused tests around record updates if the existing UI/service seams allow it safely.

Done:
- Invoice final save now records generated and archived PDF delivery events before saving the permanent proof hash.
- Invoice preview now records generated and previewed PDF events after the temporary PDF is prepared.
- Invoice preview/archive failures now record structured failure reason codes where the invoice form owns the failing action.
- The visible invoice workflow stays unchanged.
- Focused analyzer and invoice/PDF ledger tests pass.

### PDF Pass 63 of up to 200: Invoice PDF Preview Action Callback Seam

Status: complete.

Goal:
- Let preview/share/print surfaces report PDF actions back to the owning record without coupling generic PDF widgets directly to invoice storage.

Scope:
- Audit current generated PDF preview and receipt PDF viewer seams.
- Add an optional callback/action-result object where generic preview widgets can report share/print/open failures.
- Keep callbacks privacy-safe: event type and reason code only, no PDF text or local paths.
- Add focused widget/service tests if the preview seams support it safely.

Done:
- Added `AppGeneratedPdfPreviewAction` and `AppGeneratedPdfPreviewActionEvent`.
- `AppGeneratedPdfPreviewScreen` now has an optional `onAction` callback for preview opened, share completed/dismissed/failed, and print opened/dismissed/failed.
- Failure callbacks use reason codes only and do not expose PDF text, share text, file paths, or customer content.
- Added widget tests for share failure callback, print failure callback, and successful share/print action reporting.
- Focused analyzer and generated PDF preview/service tests pass.

### PDF Pass 64 of up to 200: Invoice PDF Preview Surface Decision And Wiring

Status: complete.

Goal:
- Decide and implement the clean invoice preview surface so invoice-generated PDFs can report share/print/open activity without duplicate PDF writes or confusing navigation.

Scope:
- Compare the current invoice form preview path against `AppGeneratedPdfPreviewScreen`.
- Avoid duplicate temporary writes where possible.
- If the shared generated-PDF preview becomes the invoice surface, wire action callbacks into `InvoiceRecord` PDF delivery events.
- If invoice stays on the lightweight PDF viewer, document why and keep share/print tracking limited to the generated-PDF preview surface.

Done:
- Invoice form preview now uses `AppGeneratedPdfPreviewScreen` instead of separately writing a temporary PDF and pushing the plain PDF viewer.
- The shared generated-PDF preview reports prepared and preparation-failed events in addition to preview/share/print results.
- Invoice preview actions translate generic preview callbacks into invoice PDF delivery events for generated, shared, printed, and failed actions.
- Added a narrow invoice form testing seam for PDF preview factory/service injection without changing production defaults.
- Fixed invoice form draft creation so ledger notifications do not fire during dependency building.
- Added widget coverage proving invoice preview records generated, shared, and printed PDF events with only one temporary PDF preparation.
- Focused analyzer and generated PDF/invoice ledger tests pass.

### PDF Pass 65 of up to 200: PDF Preparation Failure And Retry Audit

Status: complete.

Goal:
- Make retry behavior and preparation failures produce useful, bounded, privacy-safe diagnostics without duplicate or misleading invoice history.

Scope:
- Verify generated-PDF preview retry behavior after preparation failure.
- Ensure invoice records can distinguish preparation failure from share/print failure.
- Keep repeated retries bounded by the existing PDF event history cap.
- Add tests for preparation failure followed by successful retry where feasible.

Done:
- Generated-PDF preview retry tests now assert preparation failure and later prepared events.
- Invoice preview widget coverage proves a preparation failure records a failed invoice PDF event and successful retry records a generated PDF event.
- Repeated retry history remains bounded by the existing invoice PDF event cap.
- Focused analyzer and generated PDF/invoice ledger tests pass.

### PDF Pass 66 of up to 200: PDF Delivery Event Semantics Cleanup

Status: complete.

Goal:
- Make PDF delivery event names and semantics precise enough for future Command One/support views.

Scope:
- Review whether dismissed share/print flows should be tracked as completed actions, cancelled actions, or no-ops.
- Add event types if needed so histories do not confuse a closed share sheet with a successful send.
- Preserve privacy-safe event maps and backward compatibility for existing events.
- Add focused tests for dismissed share/print behavior.

Done:
- Added `InvoicePdfDeliveryEventType.cancelled`.
- Added `InvoicePdfDeliveryEvent.cancelled` and `InvoiceRecord.recordPdfDeliveryCancelled`.
- Invoice preview now maps dismissed share sheets to `cancelled/share_sheet_dismissed` and closed print flows to `cancelled/print_flow_dismissed`.
- Added generated-PDF preview tests for dismissed share/print action callbacks.
- Added invoice preview tests proving dismissed share/print actions are not stored as successful shared/printed events.
- Focused analyzer and generated PDF/invoice ledger tests pass.

### PDF Pass 67 of up to 200: Invoice PDF Final Save Event Completeness

Status: pending.

Goal:
- Make final save/archive history as complete and truthful as preview history.

Scope:
- Verify final save records generated, archived, hash, and failure reason codes.
- Add focused tests around successful permanent PDF proof save and archive failures if feasible.
- Keep final save from storing PDF bytes, local paths, or private rendered PDF text.

Done:
- Saving an invoice or estimate with permanent PDF proof leaves the same quality of structured history as preview/share/print paths.

### Pass 21 of 40: Separate OCR Fallback

Status: pending.

Goal:
- Make fallback to separate photos reliable.

Scope:
- Ordered OCR per photo.
- Duplicate overlap text suppression.
- Missing middle section detection where possible.
- User-safe warnings.

Done:
- Bad stitching does not ruin the receipt read.

### Pass 22 of 40: S24 UI Review Batch 2

Status: pending.

Goal:
- Install UI/image/long-receipt batch to S24 Ultra.

Scope:
- Live capture.
- Photo review.
- Long receipt section capture.
- Stitch/fallback review.

Done:
- User can test real long receipt behavior on S24.

## OCR And Parser Intelligence Track

### Pass 23 of 40: OCR Reliability Audit

Status: pending.

Goal:
- Audit shared OCR service for photo, PDF, imported text, and stitched sources.

Scope:
- Timeouts.
- Page limits.
- Duplicate/overlap handling.
- Warnings.
- Older-phone workload limits.

Done:
- OCR service has clear behavior for every receipt source.

### Pass 24 of 40: OCR Diagnostics Hardening

Status: pending.

Goal:
- Make OCR failures explainable without exposing receipt content.

Scope:
- No text found.
- Blurry/unreadable.
- Too long/too large.
- Plugin unavailable.
- Timeout.
- Duplicate/overlap suppressed.

Done:
- Each OCR failure has confirmed cause or clear missing evidence.

### Pass 25 of 40: Expensify-Style Parser Fields

Status: pending.

Goal:
- Improve extraction for merchant, date, subtotal, tax, total, payment, receipt number.

Scope:
- Lowe's/Home Depot.
- Walmart/Target/general retail.
- Fuel receipts.
- Returns/negative lines.
- Regional convenience stores.

Done:
- Core receipt fields are extracted and confidence-scored.

### Pass 26 of 40: Parser Line Items

Status: pending.

Goal:
- Improve line item extraction.

Scope:
- Item description.
- Amount.
- Quantity.
- Unit/pack where available.
- Returns/discounts/negative lines.
- Taxable vs non-taxable signals where possible.

Done:
- Parsed lines match the receipt better and mark uncertainty clearly.

### Pass 27 of 40: Vendor Profiles

Status: pending.

Goal:
- Add maintainable vendor parsing profiles.

Scope:
- Vendor aliases.
- Receipt layout hints.
- Total/tax/date patterns.
- Fuel-specific profiles.
- Regional store hooks.

Done:
- Vendor matching is explainable and updateable.

### Pass 28 of 40: Correction Learning

Status: pending.

Goal:
- Use local corrections to improve future receipt parsing.

Scope:
- Original OCR text.
- Corrected field.
- Corrected category/item.
- Merchant context.
- Local-first storage.
- Future Firebase contribution remains opt-in.

Done:
- User corrections make future parsing better locally.

## Expense Review And Maintainiac Intelligence Track

### Pass 29 of 40: Receipt Review Screen Polish

Status: pending.

Goal:
- Make the parsed receipt review screen professional and fast.

Scope:
- Merchant/date/total summary.
- Line list.
- Confidence and review reasons.
- Edit/confirm/remove actions.
- No developer jargon.

Done:
- User knows what the app found and what needs review.

### Pass 30 of 40: Business Personal Mixed Whole Receipt

Status: pending.

Goal:
- Make whole-receipt classification fast.

Scope:
- All business.
- All personal.
- Mixed receipt.
- Keep selected state unmistakable.
- Update totals immediately.

Done:
- User can classify a simple receipt in seconds.

### Pass 31 of 40: Mixed Receipt Line Classification

Status: pending.

Goal:
- Make mixed receipt line-by-line classification fast.

Scope:
- Business/personal/split per line.
- Bulk actions.
- Keyboard/accessibility friendly.
- Clear line totals.

Done:
- Mixed receipts are manageable without frustration.

### Pass 32 of 40: Split Percent And Tax Allocation

Status: pending.

Goal:
- Make split math correct.

Scope:
- Business percentage.
- Personal percentage.
- Tax allocation.
- Receipt total reconciliation.
- Rounding rules.

Done:
- Business/personal totals are defensible and understandable.

### Pass 33 of 40: Simple Mode Detailed Mode

Status: pending.

Goal:
- Make simple and detailed receipt modes clear.

Scope:
- Simple mode: amounts and classification.
- Detailed mode: descriptions, quantity, unit, category, inventory fields.
- First-use explanation.
- Per-area settings.

Done:
- User understands the difference and can switch without confusion.

### Pass 34 of 40: Vehicle And Mixed-Use Expense Intelligence

Status: pending.

Goal:
- Use vehicle/profile context in receipt expenses.

Scope:
- Vehicle selected.
- Business/personal mileage share.
- Fuel/maintenance/repair/insurance/registration allocation.
- Odometer edge-case coordination.

Done:
- Shared-use vehicle expenses allocate correctly.

### Pass 35 of 40: Materials Inventory Bridge

Status: pending.

Goal:
- Keep expense receipts and inventory updates correctly separated.

Scope:
- Expense-origin materials stay expense-first.
- Ask whether to prepare inventory.
- Stage inventory changes.
- Confirm before inventory update.

Done:
- Inventory never changes behind the user's back.

## Storage, Sync, Privacy, Diagnostics, And QA Track

### Pass 36 of 40: Storage And Backup Policy

Status: pending.

Goal:
- Make receipt proof storage lean and understandable.

Scope:
- Local original temporary handling.
- Saved proof size.
- Cloud backup size.
- Low-storage behavior.
- Export implications.

Done:
- User storage and Firebase costs stay controlled.

### Pass 37 of 40: Firestore Sync Shape For Receipts

Status: pending.

Goal:
- Ensure receipt backup does not explode reads/writes/cost.

Scope:
- Local-first Hive source of truth.
- Firestore mirror documents.
- Bundled/summarized sync where feasible.
- Receipt image storage references.
- No private raw OCR text in telemetry.

Done:
- Receipt data can sync without runaway Firebase cost.

### Pass 38 of 40: Command One Diagnostics Feed

Status: pending.

Goal:
- Feed Command One with privacy-safe receipt health.

Scope:
- Capture success/failure.
- OCR success/failure.
- Parser success/failure.
- Review correction rate.
- Abandonment rate.
- Device tier and app version context.

Done:
- Command One can show what failed, where it failed, and why without private receipt content.

### Pass 39 of 40: Synthetic Torture Test Suite

Status: pending.

Goal:
- Build repeatable receipt tests before relying only on real receipts.

Scope:
- Lowe's/Home Depot.
- Walmart/Target.
- Fuel.
- Returns.
- Long receipts.
- Faded/wrinkled/noisy.
- Multi-photo overlap.

Done:
- Parser and OCR changes are regression-tested.

### Pass 40 of 40: Real Device And Real Receipt QA

Status: pending.

Goal:
- Prove the receipt flow on actual devices and actual ugly receipts.

Scope:
- S9 Plus class.
- S24/S25 class.
- iPhone class.
- Photo capture.
- Multi-photo stitching.
- OCR/parser review.
- Save and later calendar/detail review.

Done:
- The receipt system can be called ready for broader app testing.

## Camera-Only Continuation After PDF Freeze

The user paused PDF work until the receipt camera/capture/review flow is
professional and complete. The active lane resumes camera, OCR handoff,
stitching, and expense receipt review only.

### Camera/Receipt Pass 68 of up to 150: Review Tray And OCR Handoff Cleanup

Status: completed.

Goal:
- Make the receipt photo review path feel like a professional camera workflow,
  especially for one-photo receipts and long receipts.

Completed:
- Reserved more vertical room for the receipt image in preview, order, stitch,
  and saved-proof preview modes so the bottom controls do not cover the
  receipt being reviewed or cropped.
- Reworked the single-photo review tray so the primary action is clearly
  "Read Receipt" and the tool actions are secondary.
- Changed multi-photo wording from vague "sections" to plain "receipt photos,"
  with clear top-to-bottom ordering guidance.
- Renamed the review tool action to "Saved Proof Size" where the user previews
  the smaller backup image, while preserving that OCR reads the clear source
  first.
- Stopped the expense receipt screen from immediately kicking off a duplicate
  OCR scan after the shared receipt panel already reads the reviewed photo.
- Added visible parsing state and confirmed failure telemetry for the imported
  OCR text handoff into the expense parser.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_photo_section_labels_test.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Continue receipt photo review polish around crop ergonomics, stitch preview
  confidence, and the direct OCR-to-business/personal/mixed review landing.

### Camera/Receipt Pass 69 of up to 150: Crop Preview Crash And Crop Ergonomics

Status: completed.

Goal:
- Fix the receipt preview failure reported during camera/photo review and make
  receipt cropping behave more like a professional document/photo editor.

Completed:
- Moved cropper display-rect and initial-crop callbacks out of layout/build and
  into safe post-frame callbacks.
- Added mounted/context guards so crop callbacks do not update the review screen
  after the cropper has been disposed or after the user leaves crop mode.
- Added corner crop handles in addition to edge handles, so users can adjust a
  receipt crop from the corners instead of fighting one edge at a time.
- Wired the saved-proof preview card into the active Saved Proof Size mode so
  the user sees a plain-language storage preview instead of a dead/unused
  widget.
- Removed the unused photo-strip part and stale review-control widgets that
  were guarded by `unused_element` ignores.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_photo_section_labels_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_help_flow_test.dart test/receipt_photo_section_labels_test.dart`
- `rg -n "unused_element|_ReceiptPhotoOrderCheckPanel|_ReceiptPreviewActions|_BestPhotoReviewNotice|_CompactPhotoActionButton|receipt_photo_review_strip|build preview|disposed" lib/shared/widgets/receipt_capture test/receipt_camera_help_flow_test.dart test/receipt_photo_section_labels_test.dart -S`

Next camera-only focus:
- Continue camera flow polish around the direct post-photo review landing,
  multi-photo stitch confidence, and making crop/stitch/data-saver modes feel
  like one coherent receipt-scanner workflow.

### Camera/Receipt Pass 70 of up to 150: Post-Photo Review Landing

Status: completed.

Goal:
- Make the app land on visible receipt review after the user accepts and reads a
  receipt photo, even when OCR/parser finds only header/totals and not line
  items.

Completed:
- Moved the receipt-review scroll target so it wraps the full parsed review
  block instead of only the line-item review panel.
- Kept whole-receipt business/personal/mixed controls and line review inside
  that same landing area when line items are available.
- Preserved the classification, OCR diagnostics, field confidence, and
  maintenance hint display as the first review surface after app-assisted photo
  reading.
- Verified the deleted legacy photo strip and stale review widgets are no
  longer referenced.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_photo_section_labels_test.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart test/receipt_photo_section_labels_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart lib/shared/widgets/receipt_capture/receipt_photo_review_strip.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart test/receipt_photo_section_labels_test.dart docs/receipt_camera_ocr_master_pass_plan.md`
- `rg -n "unused_element|_ReceiptPhotoOrderCheckPanel|_ReceiptPreviewActions|_BestPhotoReviewNotice|_CompactPhotoActionButton|receipt_photo_review_strip|build preview|disposed" lib/shared/widgets/receipt_capture test/receipt_camera_help_flow_test.dart test/receipt_photo_section_labels_test.dart -S`

Next camera-only focus:
- Continue with camera/stitch polish only: stitch confidence language, review
  action flow, and safer multi-photo long-receipt handling.

### Camera/Receipt Pass 71 of up to 150: Long-Receipt Review Language Cleanup

Status: completed.

Goal:
- Make the long-receipt photo review and stitch controls read like a
  professional receipt-scanner workflow instead of internal scanner terms.

Completed:
- Replaced visible "section" wording in the camera, help, settings, import,
  attachment summary, and stitch review paths with clearer "photo" language.
- Renamed stitch adjustment controls from overlap navigation to plain
  photo-pair navigation: "Previous Photos" and "Next Photos."
- Changed manual stitch guidance from "Manual overlap" to "Manual match" while
  preserving the actual overlap-based stitching behavior underneath.
- Clarified stitch status copy so the app explains when photos are safely
  stitched into one readable image versus when OCR will read the photos
  separately.
- Updated capability and attachment tests so future changes do not reintroduce
  confusing "photo sections" wording in the camera-facing flow.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_assistance_policy_test.dart test/receipt_stitching_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_image_processor.dart lib/shared/widgets/receipt_capture/receipt_attachment_list.dart lib/shared/widgets/receipt_capture/receipt_camera_feedback.dart lib/shared/widgets/receipt_capture/receipt_camera_bars.dart lib/shared/widgets/receipt_capture/receipt_camera_assist.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_camera_preview.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_assistance_policy_test.dart`
- `rg -n "photo sections|receipt photo sections|Receipt sections|receipt sections|Use sections|Capture readable sections|Previous Overlap|Next Overlap|Add Receipt Section|Add Section|sections in order|read the sections|captured in sections" lib/shared/widgets/receipt_capture test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_assistance_policy_test.dart -S`

Next camera-only focus:
- Continue with camera review polish around stitched-image preview, safe
  fallback messaging, and direct app-assisted handoff into the receipt review
  screen.

### Camera/Receipt Pass 72 of up to 150: Stitch Preview Decision Polish

Status: completed.

Goal:
- Make the stitch preview screen explain the decision clearly: one readable
  receipt image when safe, or separate photo reading when not safe.

Completed:
- Added a clear stitched-preview success title: "Ready To Read One Receipt
  Image."
- Reworded stitch pair summaries from technical overlap/scale details to
  plain match language, including "manual match" and "repeated text found."
- Changed the stitched receipt detail from "OCR image" to "receipt image" so
  users are not exposed to internal OCR terminology during review.
- Clarified fallback guidance: if the repeated lines match, slide the match
  control; otherwise continue and the app reads each photo in order.
- Updated the long-receipt preview guide copy to use "match repeated receipt
  text" instead of overlap-centric wording.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_stitching_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_assistance_policy_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_stitching_test.dart test/receipt_camera_help_flow_test.dart`

Next camera-only focus:
- Continue camera review polish around direct app-assisted handoff, action
  labels during save/read, and ensuring the review surface never feels like it
  dropped the user back to the previous form.

### Camera/Receipt Pass 73 of up to 150: Awaited App-Assisted Handoff

Status: completed.

Goal:
- Make the camera/photo review handoff wait for expense receipt parsing before
  the shared receipt panel reports that parsed lines are ready below.

Completed:
- Changed the shared receipt attachment `onImportedText` callback to support
  `FutureOr<void>` so the parent receipt screen can finish parsing before the
  shared panel clears its reading state.
- Updated OCR/photo import paths to `await` the app-assisted receipt callback
  before showing "review parsed lines below" status.
- Changed the expense receipt parser entrypoint from fire-and-forget to an
  awaited `Future<void>` flow.
- Preserved the existing nonblocking startup parse by explicitly wrapping that
  one call in `unawaited(...)`.
- Added/updated guard tests proving the app-assisted handoff is awaited before
  the "Receipt read" status copy is set.

Verification:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_stitching_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Continue camera review polish around the final read/save button states,
  failed-read recovery, and making the post-photo receipt review impossible to
  miss.

### Camera/Receipt Pass 74 of up to 150: Failed-Read Recovery Panel

Status: completed.

Goal:
- Make failed receipt reading recoverable and understandable after a camera or
  photo review attempt.

Completed:
- Reworked the shared receipt read status panel from a single status sentence
  into a title, detail, and next-step hint.
- Added explicit failed-read guidance: review the photo, add another photo, or
  keep the proof and fill the receipt by hand.
- Added success/warning/reading titles so the panel communicates state at a
  glance.
- Preserved existing attachment actions while making the status panel more
  useful when OCR cannot read a photo.
- Added guard tests for the failed-read recovery copy.

Verification:
- `flutter test test/receipt_attachment_panel_actions_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_attachment_panel_actions_test.dart`

Next camera-only focus:
- Continue with camera action polish around final read/save labels, no-text OCR
  recovery, and receipt review visibility after app-assisted reading.

### Camera/Receipt Pass 75 of up to 150: App-Assisted Read Action Clarity

Status: completed.

Goal:
- Make the photo review handoff clearly say that the app is reading the receipt
  into the expense form, using the clear prepared OCR image before the saved
  proof copy is reduced for backup/storage.

Completed:
- Reworded final camera review actions from generic scanner language to direct
  expense-flow language such as "Read Into Expense Form," "Check Stitch First,"
  "Read One Receipt Image," and "Read Photos In Order."
- Replaced the stitch wait warning with a plain instruction to wait for the
  photo match check before choosing how the receipt should be read.
- Clarified the reading status so it states that OCR uses the clear receipt
  image before the saved proof copy is made smaller.
- Changed successful photo-read messages to point the user to the parsed
  expense fields instead of vague parsed-line language.
- Strengthened failed-read recovery copy for blurry/no-text photos and long
  receipts.
- Updated receipt-camera guard tests for the new action labels and recovery
  wording.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`

Next camera-only focus:
- Continue camera review polish around the bottom tray footprint, clearer
  primary/secondary action hierarchy, and long-receipt photo order/stitch
  guidance.

### Camera/Receipt Pass 76 of up to 150: Compact Review Tray Footprint

Status: completed.

Goal:
- Make the receipt photo remain the dominant surface after capture by reducing
  the bottom review tray footprint and making the primary read action clearer
  than the secondary tools.

Completed:
- Reduced the reserved preview bottom space from 124px to 98px so more of the
  receipt image remains visible during normal review.
- Trimmed the order, stitch, and saved-proof preview bottom reservations while
  still leaving room for their tools.
- Reduced compact tray padding and primary button height.
- Reduced mini tool button size from 39px to 35px.
- Removed the extra trailing helper text in the compact preview tray so the
  tray behaves like a control bar instead of a large instruction panel.
- Kept the top status sentence and primary "Read Into Expense Form" action
  visible so the user still knows the next step.
- Added/updated guard tests for the compact layout constants and button sizes.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera review polish around long-receipt ordering/stitch guidance,
  including clearer handling when multiple photos are taken and one needs to be
  retaken or moved.

### Camera/Receipt Pass 77 of up to 150: Long-Receipt Order And Retake Clarity

Status: completed.

Goal:
- Make multi-photo receipt review safer when a user retakes a blurry top,
  middle, or bottom photo, without adding another large instruction panel.

Completed:
- Clarified order hints so the selected long-receipt photo explains whether it
  should show the top, bottom, or the next downward section.
- Added plain labels for adding the next photo versus filling a missing photo
  slot.
- Added plain retake labels for top, middle, and bottom photos so retake
  clearly preserves the selected receipt position.
- Reused the existing count label helper in the order header instead of leaving
  unused label code behind.
- Added guard tests for the new order/retake label helpers.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera-side hardening around live capture controls and automatic
  capture behavior so manual shutter always works and auto capture never blocks
  a clear user-taken photo.

### Camera/Receipt Pass 78 of up to 150: Manual Shutter Overrides Auto Capture

Status: completed.

Goal:
- Ensure assisted/auto capture helps the user without blocking or overriding a
  manual shutter tap.

Completed:
- Made the manual shutter clear any queued auto-capture before taking the
  photo.
- Made the delayed auto-capture callback verify that it is still queued before
  it fires.
- Cleared the queue immediately before launching assisted capture so stale
  capture requests cannot stack.
- Changed the assisted camera badge from "Auto ready" to "Tap anytime" so users
  know they can take the photo themselves.
- Added guard tests proving questionable manual photos are not blocked and
  queued auto-capture is cancelable.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart lib/shared/widgets/receipt_capture/receipt_camera_bars.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue live camera polish around visible guidance, edge overlay behavior,
  and keeping help unobtrusive while preserving tap focus and pinch zoom.

### Camera/Receipt Pass 79 of up to 150: Confident Edge Overlay Only

Status: completed.

Goal:
- Keep the live camera clean unless the app has a confident receipt frame to
  show, so the edge overlay does not feel like decoration or clutter.

Completed:
- Added a device-tier-aware live edge confidence threshold to the camera capture
  policy.
- Kept live edge overlay disabled for light-tier devices.
- Added a single `_liveFrameForOverlay()` gate so the overlay only appears in
  assisted mode, only when the frame is usable, and only when confidence meets
  the device policy threshold.
- Preserved tap focus, pinch zoom, camera top controls, and nonblocking long
  receipt hints.
- Added guard tests for assisted-mode overlay gating and edge confidence policy.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_capture.dart lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera capture polish around post-capture review routing and the
  bridge from live capture into photo review so one-photo and multi-photo
  receipts land in the expected review state.

### Camera/Receipt Pass 80 of up to 150: Multi-Photo Review Starts In Order Mode

Status: completed.

Goal:
- Make the post-capture/photo-review handoff land in the right state for
  one-photo versus multi-photo receipts.

Completed:
- Added an initial review-mode selector for the receipt photo review screen.
- Kept single-photo and best-shot candidate flows in the normal review mode.
- Started ordinary multi-photo receipt review in the order-check mode so users
  immediately verify top-to-bottom photo order before stitching or reading.
- Added guard tests so multi-photo review does not silently regress to the
  single-photo preview state.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera flow polish around photo review completion, especially how
  the app communicates that the next step is receipt parsing/review and not a
  return to a generic attachment screen.

### Camera/Receipt Pass 81 of up to 150: Receipt Proof Summary Explains App Assistance

Status: completed.

Goal:
- Make the attachment summary after photo review feel like a receipt-processing
  checkpoint instead of a generic file attachment list.

Completed:
- Passed the app-assisted receipt setting into the receipt proof summary.
- Reworded photo proof summary details to say "Saved proof" instead of only
  "Data saver."
- Added clear summary copy that app assistance reads the clear photo first when
  assisted receipt filling is enabled.
- Preserved proof-only wording when app assistance is disabled.
- Kept multi-photo summaries explicit that photos are kept in receipt order.
- Updated widget tests for the new long-receipt summary copy.

Verification:
- `flutter test test/receipt_attachment_panel_actions_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_list.dart test/receipt_attachment_panel_actions_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera/review polishing around completing photo review and ensuring
  the parsed receipt review remains the clear destination after OCR finishes.

### Camera/Receipt Pass 82 of up to 150: Parsed Expense Review Destination Copy

Status: completed.

Goal:
- Align the expense receipt OCR success message with the camera handoff so the
  user knows the next destination is parsed expense review, not a generic
  attachment area.

Completed:
- Updated the expense-side OCR success copy to say the receipt was read and the
  parsed expense fields below should be reviewed before saving.
- Kept the existing parsed receipt scroll behavior intact.
- Added a guard test so the expense OCR path keeps pointing users to the parsed
  expense review destination.

Verification:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera hardening around quality review thresholds and the language
  shown for questionable photos so clear manual captures are accepted but weak
  photos still receive useful next-step guidance.

### Camera/Receipt Pass 83 of up to 150: Quality Review Warnings Without False Blocking

Status: completed.

Goal:
- Make photo-quality feedback help the user inspect or retake a photo without
  treating every imperfect manual capture like a failed scan.

Completed:
- Split receipt photo quality into critical retake issues versus review-level
  warnings.
- Added plain-language quality titles and guidance for dark, glare-heavy,
  blurry, soft, low-resolution, low-contrast, poorly framed, and weak-text
  photos.
- Reworded post-capture warnings so soft photos can continue with review while
  critical issues still recommend retaking the image.
- Updated the receipt review tray to show specific next-step guidance instead
  of vague "check readability" text.
- Updated the saved-proof preview to explain that OCR uses the clear photo
  first and the data-saving setting only controls the smaller proof copy.
- Added tests proving soft photos warn without becoming retake blockers.

Verification:
- `flutter test test/receipt_camera_result_test.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_result_test.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue camera/review polishing around the single-photo review screen layout
  and the post-photo continuation path so the user always has an obvious next
  action after choosing a receipt photo.

### Camera/Receipt Pass 84 of up to 150: Single-Photo Review Handoff Clarity

Status: completed.

Goal:
- Make the one-photo review screen and OCR handoff tell the user exactly what
  happens next after accepting a receipt photo.

Completed:
- Reworded the one-photo review tray to explain that users should add another
  photo if the receipt continues, otherwise read the current photo into the
  expense form.
- Allowed the preview tray status to use two short lines so the instruction is
  not hidden behind ellipses.
- Preserved the same long-receipt instruction in the regular preview status
  path and the compact preview tray.
- Changed the OCR handoff status to keep the actual per-source success message
  instead of replacing it with generic wording.
- Updated assisted receipt tests so the persistent OCR status remains tied to
  the actual source that was read.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera review hardening around long-receipt ordering and the
  stitch/read decision so multi-photo receipts cannot accidentally feel like a
  single generic attachment.

### Camera/Receipt Pass 85 of up to 150: Multi-Photo Stitch Decision Clarity

Status: completed.

Goal:
- Make the long-receipt stitching controls explain photo pairs and fallback
  behavior without confusing the user about what will be read.

Completed:
- Fixed stitch pair navigation copy from a confusing photo-count phrase to
  "Pair X of Y."
- Added explicit readiness labels for safe stitched reads versus top-to-bottom
  separate-photo reads.
- Reworded stitch readiness detail so a failed/unsafe stitch tells the user the
  app will read each receipt photo in order instead of hiding that fallback
  behind technical language.
- Added source guards for the pair-count wording and safe-stitch label.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera review polish around saved-proof/data-saving preview and
  making sure saved proof choices remain visible without blocking the receipt.

### Camera/Receipt Pass 86 of up to 150: Saved Proof Size Language Cleanup

Status: completed.

Goal:
- Keep storage-saving choices understandable to non-technical users and avoid
  leaking "data saver" or compression-style wording into the receipt UI.

Completed:
- Renamed the photo review top-bar title from backup-size language to "Saved
  proof size."
- Reworded saved-proof preview loading and error text.
- Replaced settings-page "saved-copy" wording with "saved proof" wording.
- Kept the important product rule clear: OCR reads the clear receipt image
  first, while the saved proof size only affects the smaller retained image.
- Updated camera help-flow guards for the new saved-proof title.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_image_data_saver_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera capture/review hardening around first-run settings and making
  sure settings actions have clear apply/reset/default behavior.

### Camera/Receipt Pass 87 of up to 150: Receipt Camera Settings Apply/Reset Clarity

Status: completed.

Goal:
- Make receipt camera settings honest and clear: switch/size choices save
  immediately, while the Apply button closes the settings screen.

Completed:
- Added a plain settings note explaining that changes save as soon as the user
  taps a switch or saved-proof size choice.
- Clarified that "Apply Settings" closes the screen instead of pretending it is
  the only save action.
- Reworded first-use summary text from backup-copy language to saved-proof
  image language.
- Kept reset defaults visible and tied to recommended receipt camera plus saved
  proof settings.
- Updated camera help-flow guards for the new settings copy.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera hardening around capture/review navigation safety, especially
  accidental exits while a receipt photo is staged.

### Camera/Receipt Pass 88 of up to 150: Staged Photo Exit Dialog Clarity

Status: completed.

Goal:
- Make accidental-exit protection explain what the user is choosing before
  leaving staged receipt photos.

Completed:
- Reworded the close/exit dialog to explain that photos are in progress and
  can be prepared for receipt review, kept for editing, or abandoned.
- Replaced vague "Leave" with "Leave Without Saving."
- Replaced misleading "Save Progress" with "Prepare Receipt Review," matching
  the actual flow for both one-photo and multi-photo receipts.
- Added guard coverage for the updated exit-dialog actions.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera capture/review hardening around photo retake/add-photo
  behavior and making sure inserted photos keep the user in the right review
  state.

### Camera/Receipt Pass 89 of up to 150: Accepted Photo To Filled Review Routing

Status: completed.

Goal:
- Make the accepted receipt photo flow land on the app-filled receipt review
  destination instead of leaving the user at the attachment area.

Completed:
- Added an explicit `_hasAppAssistedReceiptReview` destination guard so the
  filled review section appears after OCR produces receipt text, parser quality,
  field confidence, OCR diagnostics, warnings, classification, or line items.
- Fixed the zero-line receipt path so a readable receipt with no safe parsed
  line items still shows the "No Line Items Found" recovery review instead of
  looking like the photo flow ended early.
- Made `_scrollToReceiptReview` retry briefly when the review section has not
  mounted yet, instead of silently giving up after one frame.
- Changed successful receipt-read completion to clear the reading state and
  focus the filled receipt review again after the awaited OCR/parser handoff.
- Added guard coverage so future camera/receipt changes cannot remove the
  app-assisted review destination, raw OCR fallback destination, retry-safe
  review focus, or successful read focus behavior.

Verification:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera capture/review hardening around photo retake/add-photo
  behavior, back navigation, and preventing staged photos from leaving the user
  in a dead-end review state.

### Camera/Receipt Pass 90: Professional Photo Review Tray Tightening

Status: completed.

Goal:
- Make the first screen after taking a receipt photo feel like a professional
  scanner review instead of a cramped control panel.

Completed:
- Reduced the review tray height budget to 20% of the screen so the receipt
  preview keeps roughly the top 80% of the screen.
- Shortened the preview action labels to plain user language: Add Another
  Photo, Add Next Photo, Retake, Crop / Straighten, Saved Proof Size, and Next.
- Changed the primary preview action to a forward Next button instead of a
  scanner/read-style action.
- Added a compact thumbnail strip even for a single captured photo so the user
  can see what photo is selected without needing hidden scrolling.
- Kept multi-photo thumbnails visible for long receipts while preserving the
  larger receipt preview area.
- Updated guard coverage so future receipt-camera passes cannot quietly expand
  the preview controls or restore the confusing long add-photo labels.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera capture/review hardening around Android back behavior, native
  camera brightness/exposure parity, and avoiding disposed-camera preview
  crashes.

### Camera/Receipt Pass 91: Camera Close And Preview Disposal Safety

Status: completed.

Goal:
- Make camera back/close behavior reliable on Android and reduce the native
  preview race that can show a disposed-camera red screen.

Completed:
- Changed close/back during active capture from a blocked wait state into a
  real close request so the user is not trapped on the camera screen.
- Reworded the close hint to explain that an unfinished photo will be ignored.
- Added a delayed native camera disposal helper used after route pop for both
  cancel/back and successful camera result returns.
- Kept immediate disposal for non-mounted teardown, but avoided disposing the
  active native controller in the same frame that the camera route begins
  popping.
- Updated camera layout guards so future camera passes preserve the route-pop
  before controller-dispose order.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera hardening around Android brightness/exposure parity and
  native-camera result quality compared with the stock camera app.

### Camera/Receipt Pass 92: Native Exposure Baseline And Bracket Guardrails

Status: completed.

Goal:
- Keep receipt capture closer to the phone camera's native auto-exposure result
  while still allowing bounded rescue attempts when the live receipt signal says
  the image is too dark or too bright.

Completed:
- Stopped candidate capture retries from repeatedly forcing the native baseline
  exposure offset when no exposure correction is needed.
- Kept the first receipt photo candidate on the native auto-exposure baseline.
- Added an explicit bracketing gate so exposure nudges only happen on later
  candidates when live quality detects darkness or glare.
- Preserved bounded exposure nudges and post-capture baseline restoration for
  the rare cases where bracketing is justified.
- Updated camera guard tests so future passes cannot reintroduce always-on
  exposure fiddling during normal receipt capture.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera hardening around native capture quality, preview brightness,
  pinch-to-zoom, and the image-review-to-filled-receipt handoff.

### Camera/Receipt Pass 93: Pinch Zoom Queue Reliability

Status: completed.

Goal:
- Make receipt-camera pinch zoom behave like a normal phone camera control even
  while native `setZoomLevel` calls are still settling.

Completed:
- Split zoom gesture updates from native zoom pumping so pinch gestures can keep
  queuing the latest requested zoom level without awaiting the camera.
- Added a stale-controller guard so delayed zoom work cannot update a disposed
  or replaced camera controller.
- Added a final queued-update pump so a pinch update that lands at the end of an
  in-flight zoom call does not get stranded.
- Kept zoom finger-driven on the full preview instead of bringing back a visible
  zoom button.
- Updated camera layout guard coverage for the queued zoom pump and stale
  controller protection.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera hardening around live preview brightness, back navigation on
  physical devices, and the image-review-to-filled-receipt handoff.

### Camera/Receipt Pass 94: Filled Receipt Review Handoff Anchor

Status: completed.

Goal:
- Make the moment after accepting receipt photos feel like a clear next step:
  the app is reading the receipt, then opening the filled receipt review.

Completed:
- Added a receipt-read handoff anchor around the attachment/read-status area.
- When OCR starts after photo review, the expense form now scrolls to the
  receipt-read status instead of leaving the user at an unclear attachment area.
- When OCR/parser succeeds, the existing filled-review scroll remains the final
  destination.
- When OCR/parser fails or is skipped, the form scrolls back to the receipt
  handoff area so the failure/recovery message is visible.
- Reworded the reading status in plain user language: the app is reading the
  receipt now and the filled review opens below when readable.
- Updated assisted receipt flow guards for the new handoff anchor and scroll
  behavior.

Verification:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera hardening around native preview brightness, physical-device
  back behavior, and receipt photo review layout density.

### Camera/Receipt Pass 95: Photo Quality Recovery Strip

Status: completed.

Goal:
- Make questionable receipt photos easier to understand after capture without
  blocking a user who can still read the receipt and wants to continue.

Completed:
- Added a compact single-photo quality recovery strip for photos that need
  review.
- The strip uses plain labels: Photo Needs Attention for critical issues and
  Check Photo Before Next for lighter warnings.
- The strip surfaces the quality guidance directly instead of burying the issue
  inside the main status sentence.
- Added direct Retake and Crop actions in the warning strip while keeping Next
  available for user judgment.
- Kept the strip out of normal good-photo review and multi-photo long-receipt
  mode so the main flow stays fast.
- Updated camera layout guards for the recovery strip, guidance source, and
  direct crop/retake actions.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera/photo review hardening around long-receipt multi-photo review
  clarity, saved proof size preview, and physical-device back behavior.

### Camera/Receipt Pass 96: Saved Proof Storage Clarity

Status: completed.

Goal:
- Make saved proof size settings understandable without making users think the
  app is reading OCR from the smaller backup image.

Completed:
- Renamed the details dialog from Photo Storage Details to Receipt Proof
  Storage.
- Added an explicit Receipt reading row that says OCR uses the clear photo
  first.
- Added an explicit Cloud backup copy row that identifies the saved proof tier.
- Kept the saved proof size language focused on storage and backup instead of
  developer compression jargon.
- Updated camera layout guards so future changes preserve the OCR-first and
  saved-proof-second wording.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue hardening around long-receipt multi-photo ordering/stitching clarity
  and physical-device back behavior.

### Camera/Receipt Pass 97: Filled Review Handoff Copy Cleanup

Status: complete.

What changed:
- Reworded post-capture and attachment status copy so `Next` clearly opens the
  filled receipt review instead of sounding like a hidden "read receipt" step.
- Kept OCR/readability language where it describes image quality, but removed
  vague camera-review handoff copy from the review tray, attachment list, exit
  dialog, and app-assisted receipt status.
- Updated long-receipt order/stitch fallback copy so the safe fallback says
  `Next reviews` or opens the filled review top to bottom.

Validation:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_attachment_panel_actions_test.dart`

Next camera-only focus:
- Continue with native review/back behavior and camera handoff checks, then
  rerun the broader receipt-camera suite.

### Camera/Receipt Pass 98: Native Close Outcome Diagnostics

Status: complete.

What changed:
- Added a safe native `closeAction` diagnostic so QA and future Command Center
  health can distinguish Back/Done with no photos from Back/Done returning
  captured receipt sections.
- Preserved the current safety behavior: Back with captured sections returns
  them to review instead of silently discarding work.
- Carried the close-action bucket through staging and expense telemetry without
  receipt image/text/customer content.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Continue hardening physical-device close/reopen behavior and long-receipt
  review recovery, then rerun the broader receipt-camera suite.

### Camera/Receipt Pass 99: Native Close Result Double-Tap Guard

Status: complete.

What changed:
- Added a native close-result delivery guard so repeated Back/Done taps cannot
  fire duplicate cancel/capture callbacks from CameraX or AVFoundation.
- Kept the existing Back behavior: no photos cancels, captured sections return
  to review.
- Preserved safe diagnostics through staging and telemetry with
  `closeResultDeliveredCount`, still without receipt content.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Continue hardening interrupted/reopened native camera recovery and long-receipt
  photo review behavior.

### Camera/Receipt Pass 100: Interrupted Resume Context

Status: complete.

What changed:
- Added safe recovery-record labels for interrupted native captures:
  one-photo versus ordered long-receipt sections, plus the Back/Done close
  outcome.
- Updated the interrupted-capture banner so resuming explains that top-to-bottom
  section order is preserved.
- Kept the labels derived from diagnostics only; no receipt text, image content,
  customer names, addresses, or item details are exposed.

Validation:
- `flutter test test/receipt_native_capture_staging_test.dart test/receipt_attachment_panel_actions_test.dart`

Next camera-only focus:
- Continue hardening long-receipt review recovery and native camera reopen flows.

### Native Scanner Pass 101: Long-Receipt Stitch Diagnostics

Status: complete.

What changed:
- Added content-free long-receipt stitch diagnostics for manual overlap,
  repeated-text matching, zoom correction, straightening correction, and
  combined zoom/straighten correction.
- Exposed pair and diagnostic labels so review/Command Center can explain why a
  stitch succeeded or fell back without showing receipt text.

Validation:
- `flutter test test/receipt_stitching_test.dart`

### Native Scanner Pass 102: Android CameraX Brightness Assist

Status: complete.

What changed:
- Strengthened Android CameraX auto-exposure assistance for dark/glary receipt
  preview frames while keeping user manual brightness changes respected.
- Added safe diagnostics for brightness bucket, exposure decision, exposure
  index, and adjustment timing.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart`

### Native Scanner Pass 103: iOS AVFoundation Brightness Assist

Status: complete.

What changed:
- Added AVFoundation parity for the receipt brightness assist path.
- Preserved safe diagnostics for brightness bucket, exposure decision, exposure
  bias, and adjustment timing without storing preview frames.

Validation:
- `flutter test test/receipt_native_ios_bridge_test.dart`

### Native Scanner Pass 104: Focus And Exposure Lock

Status: complete.

What changed:
- Wired focus/exposure mode settings through CameraX and AVFoundation.
- Added diagnostics for focus lock attempts, focus lock success, exposure lock
  success, and last focus status so capture health can be explained without
  receipt content.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

### Native Scanner Pass 105: White-Balance Lock

Status: complete.

What changed:
- Wired white-balance mode through the native camera bridge.
- Android records CameraX support limits as safe diagnostics; iOS locks white
  balance on supported devices and reports attempts/success/status.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

### Native Scanner Pass 106: OCR Prep Scanner Decision Codes

Status: complete.

What changed:
- Added exact, content-free scanner decision codes to OCR source preparation.
- Crop, orientation, straighten, cleanup, and OCR-source selection now report
  why they applied or skipped work, such as bounds too small, quality guard,
  no straighten benefit, cleanup applied for dark/glare/faded/soft text, or
  original source preserved for quality.
- Kept OCR prep privacy-safe: diagnostics do not include receipt text, merchant,
  address, line items, notes, source file path, or customer content.

Validation:
- `flutter test test/receipt_image_data_saver_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_camera_result_test.dart test/receipt_image_data_saver_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_contract_test.dart test/receipt_native_capture_staging_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_stitching_test.dart`

### Native Scanner Pass 107: Review Result Scanner Summary

Status: complete.

What changed:
- Added receipt review result helpers that summarize scanner decision codes and
  counts from the accepted OCR-prep diagnostics.
- Added safe flags for enhanced OCR source use, original-source quality guard,
  and operator-review-needed scanner concerns.
- This gives future UI/Command Center work a direct summary API instead of
  forcing every caller to parse raw diagnostic maps.

Validation:
- `flutter test test/receipt_camera_result_test.dart`
- `flutter test test/receipt_image_data_saver_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze` now reports only the unrelated generated inventory warning
  at `lib/screens/work_supplies/data/catalog/fencing/generated_fencing_detail_catalog.dart:66`.

### Native Scanner Pass 108: Exact Crop Safety Buckets

Status: complete.

What changed:
- Replaced the generic crop safety rejection with exact, content-free reason
  codes for bounds too narrow, too short, aspect too wide/tall, off-center X,
  and off-center Y.
- Kept the original safe behavior: unsafe crop suggestions still preserve the
  original OCR source instead of cutting off receipt information.
- Updated review-result scanner concern detection so meaningful crop-skip
  reasons are flagged for operator review, while user-disabled crop cleanup is
  not treated as a camera problem.

Validation:
- `flutter test test/receipt_image_data_saver_test.dart`
- `flutter test test/receipt_camera_result_test.dart`
- `flutter test --concurrency=1 test/expense_screen_telemetry_test.dart test/receipt_camera_result_test.dart test/receipt_image_data_saver_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_contract_test.dart test/receipt_native_capture_staging_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_stitching_test.dart`
- `flutter analyze` still reports only the unrelated generated inventory warning
  at `lib/screens/work_supplies/data/catalog/fencing/generated_fencing_detail_catalog.dart:66`.

### Native Scanner Pass 109: Perspective Readiness Diagnostics

Status: complete.

What changed:
- Added a separate content-free perspective-readiness check during OCR source
  preparation instead of treating perspective correction as a vague straighten
  setting.
- The scanner now reports whether perspective work was ready, disabled, missing
  bounds, too small, off-center, aspect-unsafe, or too weak to trust.
- Review-result scanner concern detection now flags meaningful perspective-skip
  reasons for review while ignoring the normal user-disabled setting state.
- This does not store receipt text, merchant, address, customer content, line
  items, notes, or source file paths.

Validation:
- `flutter test test/receipt_image_data_saver_test.dart test/receipt_camera_result_test.dart`
- `flutter test --concurrency=1 test/expense_screen_telemetry_test.dart test/receipt_camera_result_test.dart test/receipt_image_data_saver_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_contract_test.dart test/receipt_native_capture_staging_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_stitching_test.dart`
- `flutter analyze` still reports only the unrelated generated inventory warning
  at `lib/screens/work_supplies/data/catalog/fencing/generated_fencing_detail_catalog.dart:66`.

Next camera-only focus:
- Continue with scanner-quality hardening around crop/perspective confidence,
  image clarity parity with native camera behavior, and physical-device review
  flow checks before parser/PDF/Firebase work resumes.

### Native Scanner Pass 110: Native Perspective Telemetry Handoff

Status: complete.

What changed:
- Carried `latestPerspectiveReadiness` from the Android CameraX and iOS
  AVFoundation camera bridges through native capture staging, recovery
  manifests, and the Hive recovery index.
- Aggregated perspective readiness into expense receipt telemetry as
  `perspectiveReadinessBuckets` so Command 1 can later show why scanner cleanup
  was ready, skipped, or blocked without exposing receipt content.
- Kept the telemetry path privacy-safe: the allowlist accepts only reason-code
  buckets, not receipt text, merchant names, addresses, line items, notes,
  image content, or file paths.

Validation:
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_native_capture_staging_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera-only focus:
- Continue with native review/back behavior, preview brightness parity, and
  physical-device capture quality checks before parser/PDF/Firebase work
  resumes.

### Native Scanner Pass 111: Back During Save Guard

Status: complete.

What changed:
- Hardened Android CameraX and iOS AVFoundation close behavior when Back is
  pressed while a receipt photo is still saving.
- The camera now marks a pending close, disables repeat capture/finish actions,
  shows "Finishing this receipt photo before closing.", waits for the save
  callback, then returns the captured section instead of silently cancelling or
  throwing away the photo.
- Added a privacy-safe `pendingCloseAfterCapture` diagnostic through native
  staging, recovery manifests, Hive recovery index, and expense telemetry as
  `pendingCloseAfterCaptureCount`.

Validation:
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_native_capture_staging_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera-only focus:
- Continue with preview/capture brightness parity and captured-image quality
  diagnostics before parser/PDF/Firebase work resumes.

### Native Scanner Pass 112: Receipt-Targeted Exposure Assist

Status: complete.

What changed:
- Prevented Android CameraX and iOS AVFoundation auto-brightness assist from
  adjusting exposure against the entire camera frame before a receipt-like
  target is found.
- Auto exposure now waits for receipt framing and records
  `waiting_for_receipt_target` instead of darkening or brightening random
  background frames while the user is lining up the receipt.
- Added privacy-safe auto-exposure decision buckets through staging and expense
  telemetry so Command 1 can later distinguish brightness decisions such as
  waiting for target, brightening, dimming, manual override, or unsupported
  device behavior.

Validation:
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_native_capture_staging_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera-only focus:
- Continue with captured-image quality parity, review-screen clarity, and
  physical-device handoff behavior before parser/PDF/Firebase work resumes.

### Native Scanner Pass 113: Exposure Stability Gate

Status: complete.

What changed:
- Added a two-frame stability gate before CameraX or AVFoundation auto exposure
  assist brightens or dims a receipt.
- The app now records `stabilizing_brighten` or `stabilizing_dim` while it waits
  for repeated receipt-target evidence, reducing one-frame exposure jumps that
  can make the preview look darker or stranger than the stock camera.
- Added privacy-safe diagnostics for `lastAutoExposureCandidate` and
  `autoExposureCandidateFrameCount`, then summarized them into expense
  telemetry as `autoExposureCandidateBuckets` and
  `autoExposureCandidateFrameTotal`.

Validation:
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_native_capture_staging_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera-only focus:
- Continue with captured-image quality parity, review-screen clarity, and
  physical-device handoff behavior before parser/PDF/Firebase work resumes.

### Native Scanner Pass 114: Captured Image Quality Buckets

Status: complete.

What changed:
- Added native captured-photo quality diagnostics after each saved receipt photo
  on Android CameraX and iOS AVFoundation.
- Android now reads JPEG bounds with `BitmapFactory` and iOS reads image
  dimensions with `UIImage(data:)` after capture.
- Recorded content-free quality fields:
  `latestCapturedPhotoWidth`, `latestCapturedPhotoHeight`,
  `latestCapturedMegapixelBucket`, `latestCapturedByteBucket`, and
  `photoByteSizeBucket`.
- Threaded those diagnostics through native staging, recovery manifests, Hive
  recovery index, and expense telemetry as aggregate buckets/max dimensions.

Validation:
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_native_capture_staging_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera-only focus:
- Continue with review-screen clarity and physical-device handoff behavior
  before parser/PDF/Firebase work resumes.

### Native Scanner Pass 115: Review Screen Clarity And Next Action Copy

Status: complete.

What changed:
- Tightened the post-capture receipt review tray so the primary action now says
  `Next: Review Details` instead of a vague or internal-sounding receipt action.
- Reworded single-photo and long-receipt review guidance so users understand
  that they can add another photo for a long receipt or tap Next to review what
  Maintainiac read.
- Renamed unclear review copy such as `Add Receipt Section` and saved-proof
  language to plain receipt-user language: `Add Another Photo`, backup image
  size, and receipt details.
- Updated the unsaved-photo exit dialog to explain that Next reviews what
  Maintainiac read instead of sending the user back to the generic expense form.

Validation:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Continue with physical-device review behavior, capture quality parity, and
  next-screen handoff hardening before parser/PDF/Firebase work resumes.

### Native Scanner Pass 116: Receipt Details Handoff Copy And Backup Image Language

Status: complete.

What changed:
- Hardened the accepted-photo handoff language after `Next` so the app says it
  is preparing receipt details and reviewing what Maintainiac read, instead of
  sounding like it is returning to a generic expense screen.
- Replaced remaining `saved proof copy`/`receipt proof saved` wording in the
  active receipt capture/review path with plain `backup image` language.
- Clarified the app-assisted read status for combined, top-to-bottom, and
  single receipt photos so the user sees that Maintainiac read the receipt and
  that the next work is checking what was filled in.
- Kept OCR source behavior unchanged: receipt reading still uses the clearest
  source before the smaller backup image is used for storage.

Validation:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_image_data_saver_test.dart`
- `flutter analyze` still reports only the unrelated generated fencing warning:
  `lib/screens/work_supplies/data/catalog/fencing/generated_fencing_detail_catalog.dart:66:26 unused_local_variable`

Next camera-only focus:
- Continue with physical-device capture quality parity and native camera review
  behavior before parser/PDF/Firebase work resumes.

### Native Scanner Pass 117: Captured Photo Brightness And Sharpness Diagnostics

Status: complete.

What changed:
- Added native, content-free diagnostics for the actual saved receipt photo on
  Android CameraX and iOS AVFoundation, instead of judging only the live camera
  preview.
- Android and iOS now sample the accepted image after capture and bucket its
  brightness, sharpness, overall quality signal, and preview-versus-capture
  exposure mismatch.
- Threaded the new safe diagnostic fields through receipt capture staging,
  recovery metadata, and expense telemetry so Command 1 can later show whether
  receipt failures are tied to dark captures, soft captures, glare risk, or
  live/captured exposure mismatch without storing receipt content.
- Kept OCR and parser behavior unchanged in this pass; this pass only adds the
  measurement layer needed to prove why a captured photo looks worse than the
  stock camera image.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart test/expense_screen_telemetry_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :app:compileDebugKotlin --quiet`

Next camera-only focus:
- Continue with physical-device review behavior, back-navigation hardening, and
  capture-quality parity before parser/PDF/Firebase work resumes.

### Native Scanner Pass 118: Android System Back Hardening

Status: complete.

What changed:
- Added Android 13+ `OnBackInvokedCallback` handling to the native CameraX
  receipt camera so system back, gesture back, and the on-screen back button all
  use the same `requestCloseCamera()` path.
- Kept the older `onBackPressed()` fallback for older Android versions.
- Registered the system-back handler when the native receipt camera opens and
  unregisters it during destroy so the callback cannot leak after the camera is
  closed.
- Preserved the existing captured-photo safety behavior: if a receipt photo is
  already saved, back returns the captured sections; if capture is in flight,
  back waits for the in-flight photo to finish; if no photo exists, back cancels.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart`
- `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :app:compileDebugKotlin --quiet`

Next camera-only focus:
- Continue with physical-device review behavior, capture-quality parity, and
  accepted-photo handoff into receipt detail review before parser/PDF/Firebase
  work resumes.

### Native Scanner Pass 119: Failed Read Still Opens Receipt Review

Status: complete.

What changed:
- Added an explicit `_receiptReadAttemptedWithoutText` state so accepting a
  receipt photo can still open a receipt-review recovery area even when OCR
  cannot produce usable text.
- Changed the no-text read handoff to scroll into the receipt review/recovery
  area instead of returning the user to the attachment area and making it feel
  like nothing happened.
- Updated the no-line recovery copy so it says Maintainiac could not read
  usable receipt text from that photo when no text came through, instead of
  claiming receipt text was read.
- Confirmed the photo-quality helper and receipt privacy feature getter are
  syntactically clean while tracing this path.

Validation:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_native_android_bridge_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_native_android_bridge_test.dart`

Next camera-only focus:
- Continue with iOS native compile sanity, capture-quality parity, and review
  screen layout polish before parser/PDF/Firebase work resumes.

### Native Scanner Pass 120: Single Photo Review Action Clarity

Status: complete.

What changed:
- Renamed the primary single-photo review action from `Next: Review Details` to
  `Next: Review Receipt` so the user understands the next screen is the
  app-filled receipt review, not a vague detail page.
- Renamed the single-photo backup-size tool from `Proof Size` to `Backup Size`
  in the active review tray.
- Kept the receipt image dominant in the post-capture review screen while
  leaving the compact bottom tray available for add another photo, retake,
  adjust, backup size, and Next.
- Rechecked the review controls file after noisy terminal output made it look
  duplicated; the active file analyzes cleanly.

Validation:
- `flutter test test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Continue with broader analyzer cleanup, iOS native compile sanity, and
  capture-quality parity before parser/PDF/Firebase work resumes.

### Native Scanner Pass 121: iOS Native Camera Build Sanity

Status: complete.

What changed:
- Verified the iOS AVFoundation receipt camera changes compile inside the full
  iOS Runner workspace.
- Confirmed the captured-photo brightness/sharpness diagnostics and native
  receipt camera bridge do not break the simulator build.
- No camera behavior changed in this pass; this was a native build gate after
  Android CameraX had already compiled.

Validation:
- `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -sdk iphonesimulator -configuration Debug COMPILER_INDEX_STORE_ENABLE=NO build`
- Result: `BUILD SUCCEEDED`.
- Notes: Xcode emitted stale-file warnings under `build/ios/Debug-iphonesimulator`,
  but no Swift/AVFoundation compile failure.

Next camera-only focus:
- Continue with physical-device capture-quality parity, review-screen polish,
  and native camera interaction hardening before parser/PDF/Firebase work
  resumes.

### Native Scanner Pass 122: Saved Photo Quality Warning In Review

Status: complete.

What changed:
- Threaded the selected photo's native CameraX/AVFoundation capture diagnostics
  into the post-capture receipt review tray.
- Added plain-language review warnings for saved photos that came out darker
  than the live camera preview, dimmer than expected, soft/blurry, or at glare
  risk.
- Kept the warning content privacy-safe by using only bucketed native diagnostic
  keys such as captured brightness, captured sharpness, quality signal, and
  preview-versus-capture exposure mismatch.
- Preserved the existing flow: users can retake, add another photo, crop, or tap
  Next to review what Maintainiac read.

Validation:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with physical-device capture-quality parity, especially native
  preview/capture brightness behavior and post-capture review clarity before
  parser/PDF/Firebase work resumes.

### Native Scanner Pass 123: Live-Capture Brightness Mismatch Fix

Status: complete.

What changed:
- Fixed the Android CameraX saved-photo exposure mismatch detector so it uses
  the real live brightness bucket names emitted by the camera analyzer:
  `lighting_ok`, `too_dark_warning`, `dark_assisted`, `glare_warning`, and
  `bright_assisted`.
- Fixed the same AVFoundation mismatch detector on iOS.
- This makes the captured-photo diagnostics correctly identify cases where the
  live preview looked acceptable but the saved receipt photo came out too dark
  or dim, so the review warning added in Pass 122 can actually fire.
- Added Android and iOS bridge regression checks so the old dead comparisons to
  `normal`, `dark`, and `bright` cannot sneak back in.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :app:compileDebugKotlin --quiet`
- `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -sdk iphonesimulator -configuration Debug COMPILER_INDEX_STORE_ENABLE=NO build`

Next camera-only focus:
- Continue with native preview/capture brightness parity, especially whether the
  live analyzer is sampling the same region the user cares about and whether
  the review surface should offer clearer retake/edit guidance for dim captures.

### Native Scanner Pass 124: Conservative Exposure Assist Before Edges

Status: complete.

What changed:
- Added a conservative pre-edge exposure fallback to Android CameraX and iOS
  AVFoundation receipt capture.
- Before receipt edges are found, auto brightness assist can now make a small
  native exposure correction only after four sustained very-dark or glare-heavy
  analysis frames.
- Kept normal receipt-target exposure behavior faster: once receipt framing is
  found, the existing two-frame brightness candidate gate still applies.
- Preserved user control: manual brightness still overrides auto assist, manual
  shutter still works, and automatic capture is not made more aggressive.
- Added Android and iOS bridge regression checks for the four-frame fallback
  candidates so this cannot turn into twitchy instant exposure changes.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :app:compileDebugKotlin --quiet`
- `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -sdk iphonesimulator -configuration Debug COMPILER_INDEX_STORE_ENABLE=NO build`

Next camera-only focus:
- Continue with physical-device camera review around focus/zoom responsiveness,
  crop/edit clarity, and receipt-section handoff into the app-filled review.

### Native Scanner Pass 125: Pinch Zoom Tap-Focus Guard

Status: complete.

What changed:
- Hardened Android CameraX pinch zoom so the finger lift at the end of a pinch
  cannot accidentally fire tap-to-focus.
- Hardened iOS AVFoundation the same way with a short post-zoom tap-focus
  suppression window.
- Added privacy-safe diagnostics for the suppression count so Command One can
  eventually show camera interaction health without receipt images, receipt
  text, names, addresses, or other private user content.
- Preserved normal tap-to-focus behavior outside the short post-zoom guard.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart`
- `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :app:compileDebugKotlin --quiet`
- `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -sdk iphonesimulator -configuration Debug COMPILER_INDEX_STORE_ENABLE=NO build`

Command One telemetry requirement:
- Command One must expose receipt/expense health from privacy-safe summarized
  diagnostics, including OCR success/failure, parser success/failure,
  save/abandonment/retry rates, camera capture problems, crop/stitch problems,
  and parser accuracy by expense category such as fuel, materials, groceries,
  maintenance, basic expense, and unknown.
- Command One must show what failed and where it failed, using diagnostic
  reason codes and trace IDs instead of private receipt content.
- Bundle related camera/receipt work whenever safe so passes move the system
  forward in meaningful chunks instead of tiny isolated edits.

Next camera-only focus:
- Continue with camera lifecycle/back behavior, post-capture review layout, and
  the Next handoff into app-filled receipt review before parser/PDF/Firebase
  work resumes.

### Native Scanner Pass 126: Retry-Safe Back/Close

Status: complete.

What changed:
- Hardened Android CameraX back/close so a second back tap is not ignored if
  the native camera screen is still visible after a close result was already
  marked delivered.
- Hardened iOS AVFoundation the same way: if the controller is still presented
  after a delivered close result, another back action attempts dismissal again.
- Added `closeRetryCount` as a privacy-safe diagnostic so Command One can later
  show whether camera close/back behavior is getting sticky on real devices.
- Preserved captured-photo safety: back with saved receipt sections returns
  those photos, while back with no photo still cancels.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart`
- `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :app:compileDebugKotlin --quiet`
- `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -sdk iphonesimulator -configuration Debug COMPILER_INDEX_STORE_ENABLE=NO build`

Next camera-only focus:
- Continue with the post-capture review layout and the Next handoff into the
  app-filled receipt review, then return to physical-device brightness/quality
  tuning.

### Native Scanner Pass 127: Command One Camera Health Signals

Status: complete.

What changed:
- Added the new native camera interaction diagnostics into the expense receipt
  photo telemetry summary that Command One will consume later.
- `tapFocusSuppressedAfterZoomTotal` lets the admin app show whether pinch zoom
  is being protected from accidental tap-focus conflicts on real devices.
- `closeRetryTotal` lets the admin app show whether camera back/close is sticky
  or requiring repeated attempts.
- Kept the telemetry privacy-safe: no receipt image, receipt text, customer
  names, addresses, phone numbers, notes, or item descriptions are included.
- Preserved the visible handoff language: after photo review, the user is told
  to tap Next to review what Maintainiac read.

Validation:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Continue with the photo-review layout and the app-filled review handoff,
  especially making the “Next” path feel like a guided receipt flow instead of
  a return to the starting form.

### Native Scanner Pass 128: Receipt-First Review Height Cap

Status: complete.

What changed:
- Tightened the post-capture receipt review bottom-control height limits so the
  receipt image keeps more of the screen.
- Reduced preview, stitch, and backup-size panel caps while preserving access
  to Add Another Photo, Retake, Adjust, Backup Size, and Next.
- Kept crop mode especially low so receipt edges remain reachable.
- Updated layout tests to guard the tighter cap.

Validation:
- `flutter test test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with post-capture review clarity: make Add Another Photo, Next, crop,
  and long-receipt stitching feel like one professional receipt workflow.

### Native Scanner Pass 129: Plain Receipt Quality Wording

Status: complete.

What changed:
- Replaced vague photo-score evidence such as `Photo check 78%` with
  action-oriented receipt language such as `Readable receipt photo (78%)`,
  `Check before Next (...)`, or `Retake recommended (...)`.
- Kept the numeric score as supporting evidence for diagnostics and Command One
  trends, but stopped leading the user with an unexplained percentage.
- Preserved the same quality model, warnings, and review decisions.

Validation:
- `flutter test test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue tightening the post-capture review flow: clear Add Another Photo,
  crop, backup size, and Next behavior before deeper OCR/parser polish.

### Native Scanner Pass 130: Direct Next Review Language

Status: complete.

What changed:
- Replaced long post-photo continuation labels with plain `Next` or
  `Next Anyway` so the review screen behaves like a normal camera workflow.
- Moved the explanation into the compact status copy: after a photo is accepted,
  Next leads to reviewing the store, date, total, and item prices.
- Renamed vague review tools from `Adjust` to `Crop` and `Backup Size` to
  `Save Space`.
- Kept long-receipt language explicit: add the next receipt section if the
  receipt continues, check the match when multiple photos are present, then tap
  Next.

Validation:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Tighten the photo-review action tray further, then continue with the
  brightness/focus and native camera quality passes.

### Native Scanner Pass 131: Android Bright Receipt And Back Guard

Status: complete.

What changed:
- Raised the Android CameraX glare/dim thresholds so normal bright white receipt
  paper is treated as readable instead of being dimmed like glare.
- Added a `bright_receipt_ok` diagnostics bucket so Command One can separate
  healthy bright receipt paper from true glare.
- Kept strong dimming only for real over-bright frames, reducing the chance that
  the Maintainiac camera view looks darker than the phone's stock camera.
- Made the Android receipt edge guide follow the detected receipt bounds instead
  of staying as a fixed decorative rectangle.
- Enabled Android's modern back callback on `ReceiptCameraActivity` so system
  back and the in-app back path both route through the receipt-camera close
  logic.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart`
- Native Kotlin compile was attempted with `./gradlew :app:compileDebugKotlin`
  but this Mac session could not locate a Java runtime.

Next camera-only focus:
- Continue Android/iOS native camera hardening: prove back behavior on-device,
  keep tightening pinch zoom/focus behavior, then continue into post-capture
  review and stitched receipt handoff.

### Native Scanner Pass 132: iOS Bright Receipt Parity

Status: complete.

What changed:
- Mirrored the Android bright-paper threshold fix into the iOS AVFoundation
  receipt camera.
- Normal bright white receipt paper now reports `bright_receipt_ok` instead of
  being treated as a dimming target.
- Kept true glare detection at the higher over-bright threshold so both native
  camera backends share the same receipt-first exposure behavior.
- Updated bridge guard tests so Android CameraX and iOS AVFoundation stay in
  sync on brightness buckets.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera-only focus:
- Continue with on-device behavior risks: pinch zoom/focus, sticky back exits,
  capture-result recovery, and the post-capture review path into parsed receipt
  lines.

### Native Scanner Pass 133: Hive-Only Recovery Cleanup

Status: complete.

What changed:
- Hardened the receipt-native recovery index so stale Hive entries are removed
  when both the recovery manifest and staged receipt photos are gone.
- Wired stale-index cleanup into abandoned native staging cleanup.
- Preserved retained staged photos, so an in-progress receipt review is not
  deleted just because cleanup runs.
- Added a regression test for the edge case where a receipt capture manifest is
  missing, Hive still has the recovery entry, and the old staged photo has been
  cleaned up.

Validation:
- `flutter test test/receipt_native_capture_staging_test.dart`

Next camera-only focus:
- Continue interruption safety from the UI side: resume banners/actions for
  interrupted captures, then return to post-photo review layout and the Next
  handoff into parsed receipt lines.

### Native Scanner Pass 134: Attachment-Backed Resume Paths

Status: complete.

What changed:
- Added `recoverablePhotoPaths` to interrupted native capture records so resume
  can recover from either staged path lists or attachment-backed Hive records.
- Updated the receipt attachment panel resume path to use the safer recovered
  path list instead of raw `stagedPhotoPaths`.
- Preserved capture diagnostics for every recovered photo path when review is
  resumed.
- Added regression coverage for attachment-only recovery records and guarded
  the UI source against reverting to the old raw path loop.

Validation:
- `flutter test test/receipt_native_capture_staging_test.dart test/receipt_attachment_panel_actions_test.dart`

Next camera-only focus:
- Continue with the post-capture review flow: clearer resume/Next language,
  then enforce that accepted assisted receipt photos move into the parsed line
  review instead of feeling like a return to the starting form.

### Receipt Camera Reopen Pass 140: Command One Parser Category Telemetry Batch

Status: complete.

What changed:
- Added privacy-safe parser category health buckets for Command One so the admin
  app can separate receipt/parser performance by `fuel`, `groceries`,
  `materials`, `maintenance`, and other safe category tokens.
- Added parser needs-review and parser-failed category buckets so failure-rate
  drill-downs can answer which expense categories are struggling without
  storing receipt text, store names, addresses, item descriptions, or private
  notes.
- Added parser field confidence buckets such as safe field/status tokens, so
  Command One can distinguish weak totals, tax, date, or merchant parsing.
- Wired the expense receipt parser event path to emit safe category,
  confidence, subtotal reconciliation, tax math, and review-count telemetry.
- Updated telemetry schema guard coverage so these admin-facing fields cannot
  quietly disappear in a later pass.

Validation:
- `flutter test test/expense_screen_telemetry_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart`

Next camera-only focus:
- Continue with the accepted-photo handoff and receipt review surface: make the
  post-capture Next path visibly and reliably land on the filled receipt review,
  then continue hardening native capture brightness/back/zoom behavior.

### Receipt Camera Reopen Pass 252 / Total Pass 332: Accepted Photo Handoff And Admin Health Continuity Batch

Status: complete.

What changed:
- Finished the accepted-photo handoff panel in the expense receipt flow so an
  accepted receipt photo shows `Reading Receipt Details`, saved proof count,
  OCR source count, stitch/review decision, and clear copy that the next step is
  the filled receipt details review.
- Kept the handoff privacy-safe and workflow-specific; it does not show receipt
  text, store names, addresses, item descriptions, or user content.
- Added Command 1 expense health models that consume the sanitized Maintainiac
  expense telemetry summary keys, including parser category counts, parser
  needs-review category counts, parser failed category counts, top parser
  category, top needs-review category, and top failed category.
- Added a Command 1 expense telemetry health panel with OCR readable rate,
  parser success rate, save success, time on screen, abandonment, and category
  breakdowns for fuel, groceries, materials, and maintenance.
- Wired the Command 1 Expenses screen to show the new telemetry panel before the
  broader owner stats, so category health and failure causes are visible without
  exposing private receipt content.

Validation:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart`
- Command 1: `flutter test test/expense_health_panel_test.dart test/widget_test.dart`
- Command 1: `flutter analyze lib/features/admin_screens/admin_detail_screen.dart lib/features/expense_health/expense_health_models.dart lib/features/expense_health/expense_health_panel.dart test/expense_health_panel_test.dart`

Next camera-only focus:
- Continue with native camera UI settings and review continuity: camera settings
  must be visible inside Maintainiac, accepted photos must not be easy to lose,
  and the flow must keep moving from capture to image review to filled receipt
  review.
