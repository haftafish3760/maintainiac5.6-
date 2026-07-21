# Receipt Real-Device Test Script

This script is for controlled phone testing after a meaningful receipt-camera build. It is not a random tap-around checklist. The goal is to prove that a normal user can capture receipt proof, review and correct it, and hand it off without fighting the camera or losing the proof.

## Test Rules

- Test the receipt flow from the expense app first.
- Avoid maintenance-specific receipt paths during this test batch.
- Use the same receipt on every device when possible so differences are device-related, not receipt-related.
- Test at least one short receipt and one multi-photo capture set when the long-receipt subsystem is available.
- Do not judge text extraction from the smaller saved proof. Extraction must happen from the best prepared image first.
- A failed handoff is acceptable only if the app explains what happened and lets the user continue manually with the proof saved.
- Copy `docs/receipt_real_device_result_template.md` into
  `docs/receipt_real_device_runs/YYYY-MM-DD-device-batch.md` before a serious
  test session so the proof note stays structured and privacy-safe.
- Or run `tool/receipt_real_device_result_start.sh [slug]` to generate that
  note with branch, commit, workspace, and metadata-only device snapshots
  already filled in.
- The starter script also runs
  `tool/receipt_camera_real_device_snapshot.sh` so the session note points to
  the exact non-UI device-state logs captured at the start of manual testing.

## Device Targets

- Galaxy S9 Plus class device: proves older-phone limits, memory safety, and simpler camera behavior.
- Galaxy S24/S25 class device: proves flagship capture, image cleanup, and receipt-review handoff.
- Second available Android device: proves the flow is not tuned only to Samsung flagship behavior.
- iPhone SE class device: proves iOS capture, photo proof, PDF/import behavior, and route parity.

## Required Test Matrix

Run the same short receipt and the same long receipt across the device targets
whenever possible. The goal is to separate camera behavior from receipt content.

Device tiers:
- Older Android: Galaxy S9 Plus class or similar low-memory Android.
- Current Android: Galaxy S24/S25 class or similar flagship Android.
- Additional Android: any available non-primary Android device, especially if
  it differs in camera hardware or OS version.
- Current iPhone: iPhone SE/current iPhone class device.

Lighting conditions:
- Bright indoor light.
- Dim room.
- Direct glare across the receipt.
- Shadow across the receipt.
- Truck cab or vehicle interior.

Receipt conditions:
- Short receipt that fits in one photo.
- Multi-photo receipt set when the separate long-receipt subsystem is enabled.
- Wrinkled or folded receipt.
- Faded thermal receipt.
- Mixed business/personal receipt.

Interruption conditions:
- App switch after capture before save.
- Lock screen after capture before save.
- Back/close during an in-flight capture.
- Low-storage mode or smallest saved-proof setting.
- Save-space proof size preview before accepting the receipt.

Privacy diagnostics conditions:
- Help Improve Receipt Camera must be default off.
- When Help Improve Receipt Camera is off, owner-visible diagnostics stay
  metadata-only and no camera diagnostic event is published from the receipt
  capture callback.
- When Help Improve Receipt Camera is on, receipt images and receipt text are
  not owner-visible; only machine-quality review flags and privacy-safe camera
  failure counts may be used.
- Privacy checkpoint: owner-visible diagnostics stay metadata-only.
- Privacy checkpoint: receipt images and receipt text are not owner-visible.

## Build Cadence

- Do not reinstall after every small change.
- Push a phone build only after a meaningful camera or receipt review batch.
- After install, start with a clean new expense receipt entry so stale draft state does not hide flow bugs.

### iPhone Native-Asset Preflight

Before physical iPhone receipt-camera QA after a repo move, clone, or long gap:

1. Run `flutter clean`.
2. Run `flutter pub get`.
3. Run `flutter build ios --debug --no-codesign` or the signed device build you
   actually plan to install.
4. Run `bash tool/receipt_camera_ios_native_asset_preflight.sh`.

Expected:
- The preflight reports `status=ok`.
- `NativeAssetsManifest.json` advertises `ios_arm64`.
- `objective_c.framework/objective_c` contains `arm64`.

If the preflight fails and the framework is `x86_64` only, treat that as stale
generated build contamination first, not as a receipt-camera feature failure.

If `flutter run` installs the app and then fails with
`Target native_assets required define SdkRoot but it was not provided`, treat
that as a separate Flutter debug/native-assets tooling blocker after install,
not as proof that the receipt-camera app bundle is still wrong.

## Flow 1: Single Photo Receipt

Purpose:
- Prove a normal short receipt can go from photo to app-assisted review.
- Prove the Phase 2 receipt entry flow and Phase 3 camera viewer feel clean on
  a real phone, not just in source contracts.

Front-door proof before capture:
- `Add Receipt` opens a simple chooser.
- The chooser exposes `Capture Photo`, `Upload Photos`, `Upload PDF/File`, and
  `Paste/Text`.
- Choosing `Capture Photo` asks only the quick Receipt Assist question when it
  is needed.
- Manual entry remains available.
- No compression, storage, or save-space setup wall appears before the first
  photo.
- The camera opens immediately after the choice.

Live viewer proof:
- The preview reads as full-screen on the device.
- Back, settings gear, and torch stay on the screen edges.
- The shutter is round and centered near the bottom.
- No large black bars or oversized control sheets block the receipt preview.
- `Done` or `Next` does not appear until there is at least one captured photo.
- Preview tap focus stays off limits. The flow uses native autofocus plus the
  explicit controls only.
- The viewer does not hide the receipt behind a large control sheet.

Steps:
1. Open Expenses.
2. Start a new receipt expense.
3. Attach a receipt photo using the camera.
4. Wait for continuous focus/readability guidance to settle.
5. Pinch to zoom and back out.
6. Toggle flash once, then return it to the desired setting.
7. Take one photo manually.
8. Review the photo.
9. Confirm the receipt image is not hidden by a large panel.
10. Use the photo and continue.

Expected:
- Camera controls stay on the screen edges.
- Manual capture works even if guidance is uncertain.
- The review screen shows a clear primary `Next` action to fill the receipt review.
- The next app-assisted screen shows what Maintainiac read from the receipt.
- The user is not dumped back into a plain attachment list.

Must Never Happen:
- No large control sheet hides the receipt.
- No missing continue action.
- No developer labels such as parser line counts on the user-facing receipt screen.
- No compressed saved copy is used as the OCR source.

Report Back:
- Did the preview feel blocked?
- Did continuous autofocus settle on readable receipt text without extra user
  work?
- Confirm preview tap focus is off limits: no screen-tap focus prompt, preview
  focus setting, or preview tap focus diagnostic should appear during receipt
  capture.
- Did brightness, glare, and sharpness guidance match the real photo?
- Did the app move to receipt review after using the photo?
- Did the handoff retain the original photo and the correction history?

## Flow 2: Multi-Photo Capture Handoff

Purpose:
- Prove capture preserves ordered source segments for the separate long-receipt subsystem.

Steps:
1. Start a new receipt expense.
2. Take the top section of a long receipt.
3. Add another photo.
4. Use the ghost/overlap guide and repeat 3-5 readable lines while capturing
   the next section for later reconstruction.
6. Add a third section if needed.
7. Review photo order.
8. Move one photo out of order, then put it back.
9. Continue to the receipt-review handoff.
10. Confirm that the ordered photo set remains available to the next subsystem.

Expected:
- The app makes photo order clear.
- Every accepted source image remains available with its capture order.
- The camera lane does not attempt to stitch, deduplicate, or reorder the receipt itself.
- The user can still continue manually with proof attached.

Must Never Happen:
- No silent loss of a receipt section.
- No memory crash on an older phone.

Report Back:
- Did the app make it obvious which section was first, second, and third?
- Did it warn if a middle section might be missing?
- Did every accepted photo remain available in the correct order?
- Did the camera handoff avoid presenting a false stitched receipt?

## Flow 3: Save-Space Preview

Purpose:
- Prove the user can understand saved proof size without harming OCR.

Steps:
1. Capture or import a receipt photo.
2. Open the save-space controls.
3. Preview the default saved copy.
4. Preview the smallest saved copy.
5. Preview the highest quality saved copy.
6. Return to receipt review and continue.

Expected:
- User-facing language says save space or backup size, not compression.
- The preview shows what the saved proof will look like.
- OCR still uses the best prepared source before the saved proof is reduced.
- The user can leave save-space controls without losing the receipt.

Must Never Happen:
- No OCR from the smallest backup copy.
- No unclear "saved copy" wording without explaining what is saved.
- No settings panel hiding the receipt while the user is trying to inspect quality.

Report Back:
- Which saved-copy level still looked readable?
- Did the language make sense?
- Did returning from save-space controls keep the receipt state?

## Flow 4: Receipt-Review Handoff

Purpose:
- Prove the camera lane hands off usable, editable receipt evidence without deciding business meaning.

Steps:
1. Capture or import a receipt.
2. Continue with app assistance enabled.
3. Wait for the receipt-review handoff.
4. Confirm the original proof remains visible and editable.
5. Confirm any quality warning is understandable and does not block a usable image.
6. Continue to the receipt form, or continue manually if the handoff is unavailable.

Expected:
- The handoff identifies the accepted source and any quality warning.
- The original proof remains traceable after any crop, rotation, or correction.
- The camera lane does not classify the receipt as business, personal, inventory, fuel, or any other business meaning.

Must Never Happen:
- No crash when saving draft or backing out.

Report Back:
- Did the review handoff preserve the exact proof and any correction details?
- Did manual continuation remain available if the handoff could not complete?

## Flow 5: Manual Or No-Assist Photo Handoff

Purpose:
- Prove users can keep receipt proof without automatic text extraction.

Steps:
1. Open receipt photo settings.
2. Turn off app assistance for expense receipts.
3. Capture or import a receipt.
4. Continue.
5. Confirm the manual handoff is available.
6. Back out without discarding the captured proof.
7. Reopen the photo review and view the receipt proof.

Expected:
- The app does not force OCR.
- The proof remains attached.
- Returning to the review shows the proof.

Must Never Happen:
- No forced OCR when assistance is off.
- No loss of the receipt photo.
- No app-assisted receipt details required before manual continuation.

Report Back:
- Did manual handoff stay available?
- Could you still view the proof after leaving and returning?

## Flow 6: Interruption And Recovery

Purpose:
- Prove drafts and proof files survive normal phone behavior.

Steps:
1. Start a receipt expense.
2. Attach a receipt photo.
3. Leave the app before saving.
4. Return to Maintainiac.
5. Confirm the draft still has the proof.
6. Reopen the in-progress receipt flow.
7. Confirm the staged proof remains available.
8. Retake or add a photo and confirm the ordered proof set remains intact.

Expected:
- Draft proof is recoverable.
- Staged proof remains available until the receiving receipt flow accepts it.
- Adding or retaking a photo does not drop another accepted proof image.

Must Never Happen:
- No orphan proof loss.
- No duplicate attachment confusion.

Report Back:
- Did the draft survive leaving the app?
- Did the in-progress receipt flow retain every accepted photo?

## Failure Report Format

When something fails, report it this way:

- Device:
- Flow number:
- Step number:
- What you expected:
- What happened:
- Was the receipt proof still visible:
- Did the app show an error:
- Did the app crash:

## Ready For Wider Testing

The receipt camera flow is ready for broader real receipt testing only when:

- Single-photo receipt flow passes on S24/S25 and iPhone.
- Manual capture works on every tested phone.
- Multi-photo capture preserves ordered source segments for the long-receipt subsystem.
- Receipt-review handoff opens after photo acceptance.
- Save-space preview is understandable and does not affect text-extraction source quality.
- Draft recovery survives app interruption.
