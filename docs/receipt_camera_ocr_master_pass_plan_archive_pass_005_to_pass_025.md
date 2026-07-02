# Receipt Camera OCR Master Pass Plan Archive - Pass 05 of 40: Photo Review Default Surface

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

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
