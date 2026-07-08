# Receipt Real-Device Result Template

Use this template for each real-device receipt-camera session.

Purpose:
- capture camera-lane evidence in one repeatable format
- keep personal receipt information out of the notes
- make Phase 9 real-device proof review faster and less guess-heavy

Rules:
- Do not paste full receipt text.
- Do not paste receipt images into this note.
- Use merchant class only when needed, for example `fuel`, `hardware`, or
  `grocery`.
- If a field was unreadable, say that directly instead of guessing.
- If a flow was not run, mark it `NOT RUN`.

Suggested file path:
- `docs/receipt_real_device_runs/YYYY-MM-DD-device-batch.md`

## Session Metadata

- Date:
- Branch:
- Commit:
- Build type:
- Tester:
- Devices:
- Receipt set:

## Environment And Device Matrix

List the device classes covered in this session:

- Metadata snapshot summary:
- Flutter devices snapshot log:
- ADB devices snapshot log:
- Xcode devices snapshot log:

- Older Android:
- Current Android:
- Additional Android:
- iPhone:

List the lighting or interruption conditions covered:

- Bright indoor light:
- Dim room:
- Direct glare:
- Shadow across the receipt:
- Vehicle interior:
- App switch:
- Lock screen:
- Back/close during capture:
- Low-storage or smallest saved-proof setting:

## Flow Results

### Flow 1: Single Photo Receipt

- Status:
- Device coverage:
- Notes:

### Flow 2: Long Receipt Multi-Photo

- Status:
- Device coverage:
- Notes:

### Flow 3: Save-Space Preview

- Status:
- Device coverage:
- Notes:

### Flow 4: App-Assisted Filled Receipt Review

- Status:
- Device coverage:
- Notes:

### Flow 5: Manual Or No-Assist Receipt

- Status:
- Device coverage:
- Notes:

### Flow 6: Interruption And Recovery

- Status:
- Device coverage:
- Notes:

## Failure Reports

Repeat this block for each real failure:

- Device:
- Flow number:
- Step number:
- What you expected:
- What happened:
- Was the receipt proof still visible:
- Did the app show an error:
- Did the app crash:

## Privacy And Diagnostics Check

- Help Improve Receipt Camera defaulted off:
- Owner-visible diagnostics stayed metadata-only:
- No receipt images were owner-visible:
- No receipt text was owner-visible:

## Exit Summary

- Single-photo flow ready:
- Long-receipt flow ready:
- Save-space review ready:
- Manual/no-assist ready:
- Recovery ready:
- Remaining risks:
- Recommended next camera pass:
