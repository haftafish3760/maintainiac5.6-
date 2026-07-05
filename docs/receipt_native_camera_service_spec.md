# Maintainiac Native Receipt Camera Service Spec

This is the source-of-truth spec for the rebuilt receipt camera. Maintainiac must own the camera experience. The user should never be dropped into Samsung Camera, Google Camera, Apple Camera, or a generic picker as the normal production path.

Flutter may render Maintainiac screens and call a platform bridge, but Flutter's `camera` plugin is not the heart of this receipt camera.

## Architecture

Maintainiac receipt capture is three layers:

1. **Maintainiac Flutter UI**
   - Owns buttons, copy, settings screens, review screens, long-receipt prompts, crop/review tools, and the app-assisted receipt flow.
   - Can be rearranged freely without rewriting the native engine.

2. **Maintainiac Native Camera Service**
   - Android uses CameraX.
   - iOS uses AVFoundation.
   - Exposes the same receipt-focused settings contract to Flutter on both platforms.
   - Handles device capability detection, focus, exposure, zoom, flash, capture, live guidance signals, and safe temporary capture storage.

3. **Receipt Processing Pipeline**
   - Uses the clearest original/prepared source image for OCR first.
   - Then creates storage-friendly proof copies.
   - Handles enhancement, crop, perspective correction, stitching/fallback, OCR, parser review, business/personal/mixed classification, and diagnostics.

## Hard Rules

- Do not use the phone's stock camera app as the production receipt camera.
- Do not use Flutter `camera` as the production camera engine.
- Do not remove existing useful OCR, stitching, parser, review, or proof-storage logic just because the camera engine changes.
- Do not OCR a compressed proof copy when a clearer OCR source exists.
- Do not hide essential actions behind unlabeled icons.
- Do not silently discard an accepted photo when the user taps Back.
- Do not expose raw phone model/capability details in normal user UI.
- Do not require Google Play Services scanner downloads before receipt capture works.
- Do not start PDF work until the photo receipt flow is stable.
- Preview tap focus is off limits. Do not add screen-tap focus gestures, bridge
  arguments, settings, diagnostics, or user copy; use continuous
  autofocus/readability guidance, with only explicit reversible controls such as
  plus/minus fine-focus buttons or a slider allowed if a future supported-device
  path proves necessary.

## Settings And Controls Contract

Every setting below must live behind a service/controller contract so UI can move without rebuilding the engine.

### Capture Behavior

- Assisted receipt fill on/off.
- Manual receipt entry only.
- Simple price-only review mode.
- Detailed line-item review mode.
- Long receipt mode.
- Add another photo.
- Capture order review.
- Automatic capture, off by default and opt-in only.
- Manual shutter always works.
- Glove-friendly shutter.
- Retake current section.
- Keep reviewing.
- Save and continue.

### Camera Hardware Controls

- Flash/torch off, on, auto where supported.
- Pinch zoom.
- Optional zoom slider.
- Continuous autofocus/readability guidance is the primary focus path.
- Preview tap focus is not a control, fallback, setting, diagnostic
  requirement, or compatibility target for Maintainiac.
- Focus mode: continuous by default with readability guidance.
- Exposure/brightness slider.
- Auto brightness assist.
- Exposure reset.
- Shutter duration where supported.
- ISO/sensor gain where supported.
- White balance auto handling where supported.
- Macro or close-up lens selection where supported.
- Normal lens fallback.
- JPEG capture for normal stills.
- YUV/live frame pipeline for analysis when supported.
- RAW only if a future native path proves it is useful and safe.

### Live Receipt Guidance

- Document/receipt edge detection.
- Live edge/corner overlay.
- Perspective readiness.
- Motion blur warning.
- Glare warning.
- Low light warning.
- Shadow warning.
- Too far warning.
- Too close warning.
- Receipt not fully visible warning.
- Text too small warning.
- Long receipt section overlap guide.
- Previous-section ghost guide for long receipts.
- OCR-readability indicator.
- Guidance must help but never trap manual capture.

### Post Capture

- Save original/clearest source temporarily immediately after acceptance.
- Queue capture safely in local storage.
- Manual crop.
- Automatic crop suggestion.
- Perspective correction.
- Straightening.
- Rotate/orientation correction.
- Grayscale/BW preview.
- Contrast boost.
- Sharpening.
- Shadow reduction.
- Adaptive threshold.
- Save-space proof preview.
- Chosen saved proof size estimate.
- OCR source image path separate from proof image path.

### Long Receipts

- Unlimited receipt sections in principle, bounded by device memory and storage safety.
- User-visible section count.
- Small thumbnails for section order.
- Previous-section ghost/overlap guide.
- Automatic overlap detection.
- Scale correction when the user moves closer/farther between sections.
- Rotation correction when sections are crooked.
- Manual overlap adjustment if automatic matching is weak.
- Stitch only when confidence is safe.
- Fall back to separate ordered OCR when stitching confidence is low.

### Receipt Intelligence

- Merchant/store name.
- Date and time.
- Subtotal.
- Tax.
- Total.
- Payment/returns/discounts where present.
- Line prices.
- Optional line descriptions.
- Business/personal/mixed whole-receipt classification.
- Per-line business/personal/split classification for mixed receipts.
- Split percentage.
- Tax allocation for mixed receipts.
- Vehicle/profile context carried through the receipt flow.

### Privacy And Diagnostics

- Store private images/text only in the user's local/private receipt record.
- Command Center gets health metrics, not private lives.
- Diagnostic events can include step, duration, success/failure, confidence bucket, and confirmed cause.
- Diagnostic events must not include receipt image, raw receipt text, names, addresses, phone numbers, notes, or full item descriptions.

## Device Capability Policy

The service must detect capabilities and choose defaults:

- Low-end/older phone: lighter live analysis, safer preview size, conservative memory use, manual capture first.
- Mid-range phone: standard live guidance, edge overlay, normal enhancement.
- Flagship phone: stronger live analysis, better overlap guidance, heavier enhancement when it stays fast.
- Low storage: smaller saved proof target and stronger cleanup preview, while OCR still uses the clearest source first.

Capabilities must be used internally. Normal users should see helpful language such as "Save more space" or "Sharper receipt reading," not raw model names or sensor trivia.

## Production Flow

1. User taps receipt photo.
2. Maintainiac opens its own receipt camera screen.
3. User can take a photo manually at any time.
4. If long receipt is needed, user adds another section with overlap guidance.
5. User accepts section photos.
6. Maintainiac shows receipt photo review/crop/order/stitch preview.
7. User taps Next.
8. OCR reads the clearest source image or ordered source images.
9. Parser fills receipt review.
10. User classifies business/personal/mixed and confirms.
11. Expense saves locally first with proof image, OCR source metadata, parser review, and privacy-safe diagnostics.

## Parser Lane After Camera

The camera app is only the front door. Once the native receipt camera is stable, the parser lane still needs serious hardening:

- OCR accuracy must be measured against real and synthetic receipts.
- Merchant, date, subtotal, tax, total, line prices, returns, discounts, and payment clues must be parsed with confidence.
- Simple price-only review and detailed line-item review must both work.
- Business, personal, and mixed receipt classification must be accurate and easy to correct.
- Mixed receipts must calculate business amount, personal amount, split amount, and tax allocation.
- Materials/inventory hints should consume the shared receipt result object, not fork the camera/OCR pipeline.
- Vehicle/profile context must travel with the receipt so expenses roll up correctly.
- Parser diagnostics must explain failure stages without storing private receipt content in admin telemetry.

Do not start the full parser rebuild until the native camera/photo review foundation is usable.

## Current Native Rebuild Status

Completed native reset work:

- **Native Pass 01:** Spec reset, Dart service/settings contract, Flutter reuse audit, and initial contract tests.
- **Native Pass 02:** Production receipt entry now tries the Maintainiac native receipt camera service first, with scanner/photo fallback only when the native service is unavailable.
- **Native Pass 03:** Android CameraX method-channel bridge reports native camera capabilities and refuses production capture until the Maintainiac preview UI is wired.
- **Native Pass 04:** iOS AVFoundation method-channel bridge reports native camera capabilities and refuses production capture until the Maintainiac preview UI is wired.
- **Native Pass 05:** Flutter-side Maintainiac native camera shell provides a reusable receipt-first layout for preview, top controls, manual shutter, guidance, save-space summary, and long-receipt ghost overlay.
- **Native Pass 06:** Android `captureReceipt` opens an in-app Maintainiac CameraX activity with manual shutter, torch, receipt guidance, app-cache original capture, and bridge return paths.
- **Native Pass 07:** iOS `captureReceipt` presents an in-app Maintainiac AVFoundation controller with manual shutter, torch, receipt guidance, temporary original capture, and bridge return paths.
- **Native Pass 08:** Android/iOS native camera screens now expose the first hardware controls from the contract: pinch zoom, brightness/exposure adjustment, reset, torch handling, and continuous autofocus/readability as the primary focus path.
- **Native Pass 09:** Android/iOS settings buttons now open real receipt-camera session settings instead of placeholders, covering assisted fill, long receipt mode, automatic capture status, review style, save-space backup, camera controls, and brightness reset.
- **Native Pass 10:** Accepted native capture paths are copied into app-owned receipt staging with verified proof metadata before photo review/OCR prep sees them, so native temp/cache paths are not the fragile handoff point.
- **Native Pass 11:** Abandoned native staged photos now have explicit cleanup hooks: discard removes only app-owned staged photos, and old abandoned staging cleanup can retain active paths while clearing stale files.
- **Native Pass 12:** The photo review handoff now notifies the expense entry screen as soon as the user taps Next, so the screen immediately enters the receipt-reading handoff state before OCR/parser review appears.
- **Native Pass 13:** Long-receipt photo review now presents accepted photos as ordered receipt sections with an explicit section header, Add Section action, larger section thumbnails, and less duplicate bottom-panel clutter.
- **Native Pass 14:** Previous-section ghost guidance now explains the overlap task before and during capture: repeat 3-5 readable lines, keep the prior bottom slice near the top of the next photo, and treat the ghost as a visual guide only.
- **Native Pass 15:** Assisted capture now exposes live edge/corner status in plain language. The overlay still stays nonblocking, but the user can see when edges are found, weak, missing, skewed, or likely cut off instead of guessing why the camera is asking for adjustment.
- **Native Pass 16:** Photo review now makes the OCR-source/saved-proof split visible. The cleanup screen shows that receipt reading uses the clearest source first, then creates a smaller saved proof with plain-language backup choices.
- **Native Pass 17:** Stitch/fallback review now explains whether the app can build one receipt image, needs manual overlap review, or should keep sections separate for OCR.
- **Native Pass 18:** App-assisted review now opens with plain-language OCR/parser review guidance, receipt total context, line counts, and business/personal/mixed classification instructions.

Current verified state:

- Android debug APK builds with CameraX dependencies and the Maintainiac CameraX capture activity.
- iOS simulator build compiles the AVFoundation bridge and Maintainiac AVFoundation capture controller.
- Focused native contract, Android bridge, iOS bridge, and routing tests pass.
- The native service can report capability profiles, the Flutter shell can render a receipt-first camera surface, and Android/iOS can open an in-app Maintainiac native camera, guide continuous focus/readability, adjust zoom/exposure/torch, show receipt settings, return a manual receipt photo path, stage that accepted photo into app-owned receipt storage before review, and clean abandoned staged photos without touching external files.
- After photo review accepts the receipt, the expense receipt entry screen gets an immediate handoff signal, shows that the app is reading the receipt, and then scrolls to the filled receipt review area when OCR/parser data lands.
- Long receipts are presented as top-to-bottom receipt sections, not mystery photos: the preview strip names the selected section, explains overlap/order, and keeps the Add Section action visible without stacking a second action rail.
- The next-section capture guide now labels the ghost slice as the previous section bottom and gives a concrete overlap target instead of vague "line it up" copy.
- Native capture results now carry camera evidence instead of a placeholder: engine, capture surface, receipt modes, torch, brightness/exposure, zoom, temporary source byte size, and the fact that OCR uses the temporary full-quality source first.
- Android receipt capture now favors `CAPTURE_MODE_MAXIMIZE_QUALITY`, JPEG 98, and target rotation instead of latency-first capture. iOS requests high-resolution, quality-prioritized still capture where AVFoundation supports it.
- The default post-capture review tray now has a dedicated primary row: receipt section count, photo health, and a clear `Next` button that opens the filled receipt review. Secondary tools use plain receipt language such as `Add Receipt Section`, `Retake`, `Adjust`, and `Proof Size`.
- Leaving post-capture review is guarded with section-aware copy: one photo says photo, long receipts say photos/sections, and the safe path is `Next` into receipt review instead of silently throwing work away.
- Native camera staging now writes a non-private recovery manifest outside the staged-photo folder. It records staged app-owned paths, attachment metadata, engine, capture time, data-saver level, and capture diagnostics without storing receipt text or customer/private content.
- Native capture recovery can now read those manifests back, skip corrupt records, skip records whose staged photos are gone, and sort interrupted captures newest first.
- The receipt attachment panel now surfaces recoverable interrupted native captures with a plain `Resume Interrupted Receipt Photos` banner. Resume sends the staged photos back through the normal review/OCR path; successful review clears the recovery manifest.

## Current Native Rebuild Pass Map

These passes replace the old "open phone camera" decision.

- **Native Pass 05:** Build the Maintainiac capture UI shell against the native contract. **Complete.**
- **Native Pass 06:** Add Android CameraX live preview and manual still capture. **Complete.**
- **Native Pass 07:** Add iOS AVFoundation live preview and manual still capture. **Complete.**
- **Native Pass 08:** Add pinch zoom, torch, exposure slider, and reset controls, with continuous autofocus/readability primary. **Complete.**
- **Native Pass 09:** Add visible camera settings screen driven by the contract. **Complete.**
- **Native Pass 10:** Add accepted-photo safe local queue before review navigation. **Complete.**
- **Native Pass 11:** Add abandoned staged native photo cleanup and recovery. **Complete.**
- **Native Pass 12:** Rebuild post-capture review so Next goes to OCR/parser review, not the attachment start. **Complete.**
- **Native Pass 13:** Add long receipt section thumbnails and add-another-photo flow. **Complete.**
- **Native Pass 14:** Add previous-section ghost/overlap guidance. **Complete.**
- **Native Pass 15:** Add native edge/corner signals and receipt overlay. **Complete.**
- **Native Pass 16:** Add image cleanup preview controls and OCR-source/proof-source separation. **Complete.**
- **Native Pass 17:** Add stitch/fallback UI polish and manual overlap adjustment. **Complete.**
- **Native Pass 18:** Add OCR/parser/classification review polish. **Complete.**
- **Native Pass 19:** Add real-device QA and crash/lifecycle hardening.
- **Native Pass 20:** Add native capture diagnostics for exposure, zoom, torch, source size, review mode, and OCR-source proof. **Complete.**
- **Native Pass 21:** Make native still capture quality-first for receipt text: Android CameraX maximize-quality/JPEG 98/rotation, iOS high-resolution quality prioritization. **Complete.**
- **Native Pass 22:** Clean up the first post-capture receipt review tray so the receipt stays dominant, `Next` is obvious, and add-section/retake/adjust/proof actions are plainly labeled. **Complete.**
- **Native Pass 23:** Harden post-capture exit/back copy so captured receipt work is not silently discarded and multi-section receipts are described correctly. **Complete.**
- **Native Pass 24:** Add native capture recovery manifests for interrupted receipt review, with cleanup/discard protection and no private receipt content. **Complete.**
- **Native Pass 25:** Add recoverable native capture listing so interrupted app-owned receipt photos can be found again without private receipt text. **Complete.**
- **Native Pass 26:** Surface interrupted native receipt captures in the receipt attachment panel with Resume/Dismiss actions wired to the normal review flow. **Complete.**
- **Native Pass 27:** Add a Hive-backed native receipt recovery index that mirrors non-private recovery manifests, so interrupted capture work can be found without storing receipt text or customer content. **Complete.**
- **Native Pass 28:** Tighten the accepted-photo handoff language so `Next` clearly moves from photo review into the filled receipt review instead of sounding like the flow returned to the attachment panel. **Complete.**
- **Native Pass 29:** Remove the unused Flutter-camera prototype and its package dependency so the production receipt camera path is unambiguously the native CameraX/AVFoundation bridge, with image picker kept only as a backup fallback. **Complete.**
- **Native Pass 30:** Pass previous receipt-section guide context into the native CameraX/AVFoundation camera so long-receipt add-next-section capture can show a native overlap guide instead of relying only on the pre-camera prompt. **Complete.**
- **Native Pass 52:** Add stable content-free stitching fallback reason codes and carry them into receipt handoff telemetry, so long-receipt failures can be categorized without private receipt content. **Complete.**
- **Native Pass 53:** Show user-safe stitching fallback reasons in the long-receipt review card, so fallback explains the exact safe category without exposing receipt content. **Complete.**
- **Native Pass 54:** Add privacy-safe brightness bucket and exposure-assist status diagnostics to the native CameraX/AVFoundation capture result, so dark/overbright capture problems can be explained without receipt content. **Complete.**
- **Native Pass 55:** Preserve brightness bucket and exposure-assist status through native capture staging/recovery manifests while continuing to drop private receipt text/content. **Complete.**
- **Native Pass 56:** Tighten post-capture receipt review tray height caps so the receipt image remains dominant, with tests enforcing the 75-80% preview target. **Complete.**
- **Native Pass 57:** Carry privacy-safe native camera diagnostics from staged photos into the review result and expense telemetry, so accepted receipt photos report camera health without receipt content. **Complete.**
- **Native Pass 58:** Add native live framing confidence and edge-coverage diagnostics on CameraX/AVFoundation, preserving only bucketed document-scanner evidence through staging and expense telemetry. **Complete.**
- **Native Pass 59:** Show native edge/framing confidence as plain, nonblocking capture guidance on CameraX/AVFoundation, including found/usable/weak/missing edge messages while keeping manual shutter available. **Complete.**
- **Native Pass 60:** Wire native edge settings through CameraX/AVFoundation so `Find receipt edges` controls live edge analysis, overlay visibility, user guidance, and safe diagnostics instead of being a fake settings label. **Complete.**
- **Native Pass 61:** Wire native camera-control settings through CameraX/AVFoundation so pinch zoom, brightness slider, brightness reset, and continuous-focus policy are honored by native UI, controls, diagnostics, and the method-channel session. **Complete.**
- **Native Pass 62:** Add privacy-safe native camera-control usage diagnostics for legacy focus taps, zoom, manual brightness changes, and focus status, then preserve those counters through staging and expense telemetry without receipt content. **Complete.**
- **Native Pass 63:** Preserve edge/control setting state through native staging and expense telemetry, so future Command Center health can distinguish disabled camera aids from failed camera aids without receipt content. **Complete.**
- **Native Pass 64:** Make optional automatic capture real but conservative on CameraX/AVFoundation: it only fires after repeated stable/readable frames with usable edges and good light, preserves manual shutter, cools down between sections, and records safe status/trigger diagnostics. **Complete.**
- **Native Pass 65:** Harden native close/back lifecycle around manual and automatic capture so CameraX/AVFoundation refuses new captures while closing, returns existing sections safely, and records a safe closing status. **Complete.**
- **Native Pass 66:** Clarify automatic-capture settings copy across the Dart contract and native Android/iOS settings so users know it is off by default, waits for several steady readable frames, and never removes the manual shutter. **Complete.**
- **Native Pass 67:** Wire shadow and tiny-text warning settings into CameraX/AVFoundation live analysis, add a content-free shadow-risk heuristic, and preserve the safe warning state/signals through staging and expense telemetry. **Complete.**
- **Native Pass 68:** Preserve image-cleanup setting state from the native CameraX/AVFoundation session, including crop suggestions, grayscale, contrast, sharpening, shadow cleanup, adaptive threshold, and orientation correction, so downstream review/telemetry can explain the intended cleanup path without receipt content. **Complete.**
- **Native Pass 69:** Make native image-cleanup settings actionable in Dart OCR preparation and saved-proof preview. The capture diagnostics now choose whether OCR prep may crop, straighten, grayscale, boost contrast, sharpen, balance shadows, and run adaptive exposure, while diagnostics remain content-free and OCR still prepares from the clearest accepted receipt source before storage downsizing. **Complete.**
- **Native Pass 70:** Add conservative OCR-source orientation cleanup for obvious sideways receipt captures. When orientation cleanup is enabled, the image prep pipeline can rotate a landscape receipt into portrait only when text/focus quality remains safe, records `auto_orient`, and leaves normal portrait receipts alone. **Complete.**
- **Native Pass 71:** Preserve native camera diagnostics across user crop/rotate edits and add content-free edit-action telemetry. Expense OCR-start metadata now records safe camera health buckets, scanner cleanup actions, and user edit counts through an explicit telemetry allowlist while still rejecting private receipt text, store names, notes, and unsupported values. **Complete.**
- **Native Pass 72:** Treat native CameraX/AVFoundation Back/cancel as a clean user cancellation. Android and iOS already return `native_camera_cancelled`; Dart now maps that to a dedicated cancel exception, and both first-photo and add-section/retake flows quietly return without opening fallback camera UI or showing false failure copy. **Complete.**
- **Native Pass 73:** Add regression guards proving both receipt entry points catch native camera cancel before unavailable/fallback handling, so Back/cancel cannot regress into a false failure message or backup camera launch. **Complete.**
- **Native Pass 74:** Carry safe native capture diagnostics into the first photo review route for both first capture and interrupted-capture resume, so OCR prep, saved-proof preview, cleanup settings, and telemetry honor the native camera settings from the first review screen instead of only later add-section flows. **Complete.**
- **Native Pass 75:** Freeze accepted receipt photo review results with immutable photo lists and nested diagnostics maps, so camera health evidence, OCR-source preparation evidence, and saved-proof references cannot be accidentally mutated after the review screen hands them to expense entry or future Command Center telemetry. **Complete.**
- **Native Pass 76:** Add migration-boundary guards proving the production receipt path does not reintroduce Flutter `camera` package wiring or the old Flutter receipt camera screen, while preserving `image_picker` only as a backup photo fallback behind the native CameraX/AVFoundation service. **Complete.**
- **Native Pass 77:** Harden post-capture review lifecycle cleanup. Late async proof-size previews now no-op safely after disposal, delete their own temporary saved-proof preview if the review closed or the source photo was replaced, and route review state updates through a mounted/disposed guard to reduce disposed-widget crashes. **Complete.**
- **Native Pass 78:** Harden the receipt attachment panel's interrupted-capture recovery lifecycle. Recovery load/resume/dismiss state now uses a mounted/disposed guard, so async Hive/staging recovery work cannot call `setState` after the receipt form panel has been removed while still preserving resume into the normal review/OCR path. **Complete.**
- **Native Pass 79:** Make native receipt camera sessions storage-aware without weakening OCR capture quality. CameraX/AVFoundation now receive the selected proof-storage level, the stronger device-recommended storage safety level, a content-free storage reason code, and a capped long-receipt section count for tight-storage modes while OCR still uses the original accepted source first. **Complete.**
- **Native Pass 80:** Consume storage-safety session fields inside the native CameraX/AVFoundation camera screens. The camera bottom label now reflects the effective storage safety mode, tight-storage sessions explain that long receipts are kept lighter, and native diagnostics report the storage safety level/reason without receipt content. **Complete.**
- **Native Pass 81:** Preserve storage-safety camera diagnostics through native capture staging and interrupted-capture recovery. The safe allowlist now carries storage safety level, constrained status, and reason code into staged handoff, recovery manifests, and Hive recovery index entries while still dropping receipt text/customer content. **Complete.**
- **Native Pass 82:** Carry storage-safety camera evidence into expense OCR-start telemetry as privacy-safe buckets. Accepted receipt photo handoff now records storage safety level counts, storage reason counts, and constrained-session counts for future Command Center health without private receipt text, store names, addresses, or line items. **Complete.**
- **Native Pass 83:** Separate automatic-capture eligibility from automatic-capture enabled state. Dart now sends `autoCaptureAllowed`, CameraX/AVFoundation settings refuse to re-enable automatic capture when device/storage safety holds it back, and staging/telemetry preserve the safe allowed-count so Command Center can distinguish disabled-by-user from held-back-for-safety. **Complete.**
- **Native Pass 84:** Harden automatic capture against disabled receipt edge guidance. CameraX/AVFoundation now treat automatic capture as currently allowed only when session safety allows it and live edge guidance is on; turning edge guidance off disables automatic capture, explains that manual shutter is safest, and records the effective eligibility in safe diagnostics/telemetry. **Complete.**
- **Native Pass 85:** Add native close/back outcome diagnostics. CameraX/AVFoundation now distinguish back-without-photo cancel, Done-without-photo cancel, Back returning captured receipt sections, and Done returning captured receipt sections; the safe `closeAction` bucket flows through staging and expense telemetry without receipt content. **Complete.**
- **Native Pass 86:** Guard native close/result delivery against repeated Back/Done taps. CameraX/AVFoundation now no-op after the first close/capture result is delivered, preventing duplicate callbacks or duplicate section handoffs during physical-device button spam while recording a safe `closeResultDelivered` diagnostic. **Complete.**
- **Native Pass 87:** Improve interrupted-capture resume context. Recovery records now derive safe section-count and close-action labels so the attachment panel can explain whether Back/Done returned one receipt photo or ordered long-receipt sections, without exposing receipt text or customer content. **Complete.**
- **Native Pass 31:** Add native long-receipt batch capture to CameraX/AVFoundation so long receipt mode keeps the camera open after each section, shows a section-count Done action, returns all ordered native receipt photo paths through the bridge for OCR/prep, and reports photo count/max section diagnostics. **Complete.**
- **Native Pass 32:** Guard Android native camera Back/close behavior after sections are captured and make CameraX unbind defensive, so captured receipt sections are not silently discarded by the top Back button or system Back while the native camera is closing. **Complete.**
- **Native Pass 33:** Update the native previous-section guide during the same long-receipt camera session after each saved section, so CameraX/AVFoundation users can line up the next receipt section without reopening the camera through Flutter. **Complete.**
- **Native Pass 34:** Report real native still-photo dimensions through Camera2/CameraX and AVFoundation capability reads, carry them into the private device hardware profile for safe defaults, and keep raw sensor details out of normal user-facing labels. **Complete.**
- **Native Pass 35:** Add a shared camera-permission preflight before native receipt capture from both first-photo and add-section flows, with plain permission-needed/blocked messages before falling back to backup photo options. **Complete.**
- **Native Pass 36:** Add throttled native live brightness/readability analysis to CameraX and AVFoundation preview frames, warning about dark receipts or glare/over-bright scenes without blocking manual capture or storing image content. **Complete.**
- **Native Pass 37:** Rework post-capture quality guidance so the review tray leads with the user action, explains the confirmed photo issue in plain language, and keeps the percent score as secondary evidence instead of the main decision. **Complete.**
- **Native Pass 38:** Add conservative native auto-brightness assist for CameraX and AVFoundation. When live analysis sees clearly dark or over-bright receipt frames, the camera makes small exposure-bias nudges until the user manually touches brightness, and diagnostics record the adjustment count without storing image content. **Complete.**
- **Native Pass 39:** Surface auto-brightness assist in Android/iOS receipt camera settings so users can see and disable the automatic exposure help without losing manual Brightness control. **Complete.**
- **Native Pass 40:** Add a native receipt frame guide and live framing signal on CameraX/AVFoundation. Preview analysis now gives nonblocking move-closer/cut-off/framing-ok guidance and records the framing signal in diagnostics without saving preview frames. **Complete.**
- **Native Pass 41:** Add nonblocking live steadiness/motion detection on CameraX/AVFoundation. Preview luma samples are compared against the prior sampled frame to warn `Hold steady so the receipt text stays sharp`, with only motion signal/score stored in diagnostics. **Complete.**
- **Native Pass 42:** Expose receipt guidance warnings in native Android/iOS settings, letting users turn off shake/light/glare/framing warnings without disabling manual shutter, focus, zoom, brightness, or app-assisted receipt review. **Complete.**
- **Native Pass 43:** Harden native live-analysis binding so CameraX/AVFoundation keeps preview analysis attached whenever framing warnings or auto-brightness assist need it, even if low-light/glare/motion warnings are disabled. **Complete.**
- **Native Pass 44:** Strengthen interrupted-capture recovery so the Hive recovery index stores enough non-private attachment metadata to restore a staged native receipt capture even when the JSON recovery manifest is missing, while still avoiding receipt text/customer content. **Complete.**
- **Native Pass 45:** Add an explicit safe-diagnostic allowlist for native recovery manifests and Hive recovery index entries, so accidental receipt text/customer names/addresses or other unknown private keys are dropped before local recovery metadata is written. **Complete.**
- **Native Pass 46:** Make interrupted-capture discard explicit and clean: the banner now says `Discard`, explains it removes staged receipt copies, and the staging service deletes app-owned staged native receipt photos plus the recovery manifest/Hive index without touching the original native source file. **Complete.**
- **Native Pass 47:** Harden receipt review async lifecycle guards around native camera launch/review messaging. The add-section camera path re-checks `mounted` after native capability reads, and receipt camera snackbar helpers now no-op after disposal so stale async camera work cannot touch a dead review screen. **Complete.**
- **Native Pass 48:** Broaden native auto-brightness assist so CameraX/AVFoundation gently correct receipt preview exposure before the image is extremely dark or blown out. Warning copy still stays nonblocking and user-controlled, but the camera now tries to protect OCR readability earlier unless the user manually changes Brightness. **Complete.**
- **Native Pass 49:** Fix native camera Back behavior after receipt sections are captured. Back/no-photo still cancels, but Back/with-photos now returns captured sections to receipt review like Done instead of trapping the user in camera with only guidance text. **Complete.**
- **Native Pass 50:** Add non-private image-preparation evidence for the scanner cleanup pipeline. OCR source prep now returns before/after quality scores, cleanup actions, and whether the source was enhanced, and the accepted photo review result carries those diagnostics forward without receipt text, merchant, address, or line-item content. **Complete.**
- **Native Pass 51:** Carry safe camera cleanup evidence into the expense receipt handoff. When accepted receipt photos begin app-assisted reading, the expense screen records content-free OCR-start metadata for saved proof count, OCR source count, scanner cleanup usage, cleanup action names, stitch status, and stitch confidence bucket. **Complete.**

This list is tentative. Stop only when the receipt camera flow is proven, not when the pass count looks tidy.
