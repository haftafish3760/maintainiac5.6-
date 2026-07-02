# Receipt Camera OCR State Of Art Spec Archive - Completion Evidence

Archived from `docs/receipt_camera_ocr_state_of_art_spec.md`.

## Completion Evidence

The receipt system is not complete until evidence proves:

- Camera/photo review does not crash or trap the user.
- Manual capture, tap focus, and pinch zoom work on supported devices.
- Images are not unnecessarily dark compared with native camera behavior.
- Long receipts work through stitch or ordered fallback.
- OCR source image is chosen before backup-size reduction.
- Parser handles common expense, fuel, retail, return, tax, and negative-line cases.
- User can classify whole receipt and mixed line items.
- Split tax math is correct.
- Expense record saves locally and recovers from calendar/day views.
- Diagnostics show exact failure step and cause without private content.
- Android and iOS have acceptable fallback behavior.
- Real-device and synthetic tests cover the known risk areas.
