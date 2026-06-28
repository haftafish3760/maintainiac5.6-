# Receipt Camera Flutter Reuse Audit

This audit exists so the native CameraX/AVFoundation rebuild does not throw away useful receipt work.

The rule is simple: keep Flutter-side workflow and receipt intelligence; replace camera hardware control.

## Keep And Reuse

### Capture Workflow UI

Reusable files:

- `receipt_camera_bars.dart`
- `receipt_camera_buttons.dart`
- `receipt_camera_assist.dart`
- `receipt_camera_feedback.dart`
- `receipt_camera_help_sheet.dart`
- `receipt_camera_setup.dart`

Why keep:

- Top bar, settings button, torch button, shutter button, compact guidance, first-use help, and user-facing camera copy are UI concepts, not camera-engine concepts.
- These widgets can be adapted to a native preview view once CameraX/AVFoundation owns the hardware.

Migration rule:

- Remove direct dependency on `ReceiptCameraScreen` state where practical.
- Move user-facing assist states and guidance models into public/native-safe classes as needed.
- Keep manual shutter always available.
- Keep auto capture opt-in only.

### Photo Review And Edit Flow

Reusable files:

- `receipt_photo_review_screen.dart`
- `receipt_photo_review_controls.dart`
- `receipt_photo_review_data_saver_panel.dart`
- `receipt_photo_review_image_edit_actions.dart`
- `receipt_photo_review_save_actions.dart`
- `receipt_photo_review_section_labels.dart`
- `receipt_photo_review_top_bar.dart`
- `receipt_edge_cropper.dart`

Why keep:

- The review screen already owns crop, rotate, stitch preview, data-saver preview, section order, add/retake/remove, and Next/save behavior.
- This is independent of whether photos came from Flutter camera, CameraX, AVFoundation, document scanner, or image import.

Migration rule:

- New native camera results must enter this review flow through `ReceiptCameraResult` or a compatible native result adapter.
- Existing photo review must continue to produce `ReceiptPhotoReviewResult` with separate `photoPaths` and `ocrSourcePhotoPaths`.

### Image Processing

Reusable files:

- `receipt_image_processor.dart`
- `receipt_capture_models.dart` image, quality, and stitch models.

Why keep:

- Current processing already separates OCR source from saved proof.
- It includes crop, rotate, straightening, storage preview, compression tiers, quality scoring, enhancement candidates, overlap matching, stitching, and fallback.

Migration rule:

- Native camera must feed original/clearest accepted paths into this processor.
- OCR must use prepared source images before proof compression.
- Saved proof size controls remain user-facing save-space controls, not developer "compression" language.

### OCR And Parser Handoff

Reusable files:

- `receipt_ocr_service.dart`
- `receipt_attachment_ocr_actions.dart`
- `receipt_attachment_import_actions.dart` handoff after it is rerouted to the native camera service.
- Expense receipt review/parser files that consume OCR output.

Why keep:

- OCR/parser logic should not care what camera engine produced the image.
- Existing text-block, confidence, error-state, and receipt-review handoff work should survive unless tied directly to `package:camera`.

Migration rule:

- Keep OCR input as image paths and metadata.
- Add native capture diagnostics as metadata only.
- Do not put private receipt text in Command Center telemetry.

### Storage And Local-First Protection

Reusable files:

- `receipt_proof_storage.dart`
- `receipt_proof_storage_copy.dart`
- `receipt_proof_storage_exception.dart`
- `receipt_proof_storage_file_names.dart`
- `receipt_storage_guard.dart`
- Hive/local-first expense storage and dirty sync queue code.

Why keep:

- The user must not lose an accepted receipt because of a call, app switch, crash, low memory, or accidental Back.
- Local-first remains the record of truth.

Migration rule:

- Native capture must save accepted originals to app-controlled temporary storage immediately.
- Photo review then creates proof copies and OCR source paths.
- Sync stays later and separate.

### Tests And Docs

Reusable:

- Behavior tests around OCR source separation, proof storage, review flow, parser diagnostics, and privacy.
- Specs in `docs/` after stale phone-camera language is corrected.

Migration rule:

- Tests that assert "phone camera opens" are stale and must be updated to "Maintainiac native camera opens; phone camera fallback only if native service unavailable."
- Tests that guard review, OCR, storage, and privacy should stay.

## Replace Or Wrap

### Camera Backend

Replace:

- `package:camera` imports.
- `CameraController`.
- `CameraPreview`.
- `CameraImage`.
- `availableCameras`.
- Direct Flutter-camera `setFocusPoint`, `setExposurePoint`, `setZoomLevel`, `setFlashMode`, `takePicture`, and `startImageStream`.

Replacement:

- Android CameraX bridge.
- iOS AVFoundation bridge.
- Shared Dart contract in `receipt_native_camera_contract.dart`.
- Shared service in `receipt_native_camera_service.dart`.

### Live Preview Pipeline

Replace:

- Any preview surface that depends on Flutter `CameraPreview`.
- Any live frame analysis that depends directly on Flutter `CameraImage`.

Reuse:

- The math and thresholds from `_ReceiptLiveFrameQuality`.
- The guidance labels from `_ReceiptCameraAssistState`.
- Candidate ranking from `_compareReceiptCameraCandidates`.

Migration rule:

- Native engine should send platform-neutral frame signals to Flutter, such as brightness, contrast, focus score, edge confidence, text-band score, skew score, and bottom-content risk.
- Flutter should render guidance from those signals.

## Current Spaghetti Risk

The old custom camera is tangled through `part of 'receipt_camera_screen.dart'`, which makes direct reuse harder than it should be. Do not build more production behavior into that tangle.

Instead:

1. Extract reusable models/copy/policies into native-safe files.
2. Keep the old Flutter camera files as reference/test surfaces until the native camera screen replaces them.
3. Route production capture through `ReceiptNativeCameraService`.
4. Delete or quarantine the old Flutter camera engine only after the native camera passes real-device QA.

## Acceptance For Migration

- Maintainiac camera opens inside Maintainiac, not Samsung Camera.
- Android capture path uses CameraX.
- iOS capture path uses AVFoundation.
- Flutter renders UI and review, but does not own camera hardware.
- Manual capture works even when guidance is uncertain.
- Accepted originals are protected locally immediately.
- Post-capture review gets the photo and can crop, retake, add another section, preview saved proof size, and tap Next.
- Next leads to OCR/parser/classification review when app-assisted receipt fill is on.
