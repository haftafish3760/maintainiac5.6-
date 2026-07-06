# Receipt Camera Completion Map

This file is the estimating source of truth for Maintainiac receipt workflow
capture work. Do not answer "how many passes are left" from a hunch. Use this
map, update the evidence, then answer from the current completion state.

## Estimating Rules

- A pass count is a planning forecast, not proof of quality.
- Do not give a precise-looking number unless it is tied to the milestones
  below.
- For quick answers, state that the number is a quick estimate.
- For verified answers, inspect current source, tests, docs, native contracts,
  and device evidence before answering.
- The release target is 90-93% reliability for core receipt workflow paths, not
  99% scanner-app or pro-camera perfection.
- Passes are app-work passes only. Clarifying questions, git status, or
  push-only activity are not passes.
- Real receipt/device testing can move the estimate up or down.

## Current Scope

Receipt workflow scope includes:

- launch shared receipt capture
- take or import a normal receipt photo
- use the platform-native camera stack as the baseline instead of building a
  pro camera replacement
- guide the user through receipt capture without pretending unproven live
  quality heuristics are truth
- provide the release-one receipt controls: manual shutter, torch when
  supported, phone-native autofocus, basic brightness control, receipt framing
  guidance, and settings
- review, retake, add photo, or use receipt
- capture long receipts in ordered segments
- preserve segment order during retakes
- show ghost/overlap guidance for continuation capture
- stitch when evidence is strong
- fall back to ordered segments when stitching is risky
- hand OCR the best available camera evidence
- keep source and derived image responsibilities explicit

Receipt workflow scope excludes:

- replacing Samsung, Google, Apple, or other device camera software
- building a generic camera application
- trying to outbuild Google ML Kit OCR
- ISO, RAW, white-balance lock, exposure lock, screen-tap focus, focus lock, or
  manual lens-distance controls without explicit approval
- treating a focus slider as required release-one work. A focus slider is not a
  release blocker; any manual focus adjustment is optional, device-supported,
  and future-facing unless real-device proof shows it is needed
- full receipt parser perfection
- inventory parser work
- PDF generation or import polish
- maintenance automation
- invoices, maps, cloud sync, or admin dashboards

## Completion Evidence Table

| Work package | Target proof | Current evidence | Status |
| --- | --- | --- | --- |
| Native camera baseline | CameraX/AVFoundation use device defaults for core camera behavior while Maintainiac owns receipt UI/review/stitching only. | Contract docs/tests exist; production code now has a native-baseline policy. | Strong |
| Receipt control priority | Manual shutter, torch, brightness guidance, settings, and receipt review are prioritized over pro-camera controls. | Native Android/iOS torch exists; contract now states torch and optional focus policy. | Strong |
| Shared entry and permissions | User can start receipt capture from shared flow with safe fallback. | Source and tests exist for camera actions, permission, and fallback contracts. | Partial |
| Native camera contract | Android CameraX and iOS AVFoundation expose matching high-level settings and capture metadata. | Flutter contract and native bridge tests exist; real-device proof still required. | Partial |
| No preview tap focus | Preview/screen tap focus is banned; phone-native continuous autofocus is primary. Any manual focus control must be explicit, reversible, device-supported, and separately approved. | Active docs and regression tests exist. | Strong |
| Single photo capture | Manual capture works, review opens, retake/use actions are stable. | Capture/review source and tests exist; real-device proof still required. | Partial |
| Quality guidance | Release-one live guidance stays conservative: receipt framing, small-text/distance, and edge visibility can guide capture; blur, glare, shadow, dirty-lens, and low-light claims stay disabled by default unless separately proven. Post-capture review may surface saved-photo quality risks as advisory review prompts. | Quality model/tests exist; unproven live quality claims are default-off and need real receipt calibration before promotion. | Partial |
| Long receipt ordering | Add Photo creates ordered segments; retake preserves index and context. | Continuation/order tests exist; more UI and interruption evidence needed. | Partial |
| Ghost/overlap guidance | Previous segment bottom 15-20% guides the next capture; middle retake can use previous/next context. | Ghost guide contract/source exists; real-device visual proof is missing. | Partial |
| Stitch/fallback | Strong overlap stitches; weak overlap falls back to ordered OCR handoff without corrupting sources. | Stitch source/tests exist; synthetic and real receipt fixtures need expansion. | Partial |
| OCR source handoff | OCR gets temporary full-quality source or ordered segments; saved compressed proof is separate. | Handoff tests exist; final app-flow proof still required. | Partial |
| Review mode handoff | Camera output carries price-only versus detailed-line review intent; parser owns final line extraction/numbering. | Review-depth contracts and expense line numbering already exist; needs app-flow proof. | Partial |
| Barcode/QR handoff | Receipt capture can hand barcode/QR evidence forward without owning inventory work. | Service files and camera summary tests exist; flow proof can wait behind capture/stitch. | Partial |
| Device/storage safety | Older devices reduce heavy work; low storage avoids unsafe processing. | Capability/storage contracts exist; real-device proof missing. | Partial |
| Fixture QA | Synthetic and real receipt fixtures cover camera failure families. | Many camera tests exist; release-one camera fixture matrix exists and needs real receipt additions. | Partial |
| Milestone quality gate | Targeted camera tests, source audit, doc gate, analyzer, and real-device notes pass together. | Targeted checks have passed in recent passes; final milestone gate is not proven. | Missing |

## Forecast Method

Use this formula for pass forecasts:

1. Count only remaining receipt workflow packages, not generic camera-app work.
2. Weight each package:
   - `Strong`: 0-15 passes for regression maintenance.
   - `Partial`: 20-70 passes depending on UI/native/test depth.
   - `Missing`: 70-140 passes because implementation and proof are absent.
3. Add 15-25% contingency for real-device camera behavior and stitching.
4. Do not count unrelated PDF, inventory, maintenance, maps, invoices, or parser
   work against this estimate.
5. Do not count normal user context as parser work. If the user starts from
   Fuel, Maintenance, Materials, or another category, that selected context is
   already parser evidence.

## Current Forecast

From the current evidence table, the strongest single-number planning forecast
is:

**400 to 550 focused receipt workflow passes from this remap.**

That range comes from:

- the existing native camera/review foundation already being substantial
- remaining single-photo app-flow proof
- long-receipt order/retake polish
- stitching/fallback hardening as the main technical risk
- real-device proof on the available phones

If a single planning anchor is required, use:

**450 focused receipt workflow passes.**

Do not treat `450` as a promise. Treat it as the working anchor until the
evidence table is updated.

## Four-Phone Real-Device Proof

The real-device path should use the user's available phones as the proof set:

- Galaxy S9 Plus: older Android baseline, memory pressure, lower-camera margin.
- Galaxy S24 Ultra: current Android flagship baseline.
- Additional Android phone: brand/device variation when available.
- iPhone: iOS AVFoundation route parity when available.

If fewer than four phones are connected during a QA window, test the available
phones and record the missing device class as a remaining risk instead of
inflating pass estimates.

## Reliability Target

The expected quality target after this map is completed and verified:

- normal single receipts: 93-96% usable capture/review success
- long receipt capture: 88-93% usable capture/review/stitch-or-fallback success
- OCR-ready handoff for good photos: 90-95% useful ML Kit input
- difficult real-world captures before user retake: 65-80%
- difficult captures after guidance and retake: 80-90%

The final 7-10% must come from real receipt/device regressions, not pass count.

## Update Rule

Whenever a camera milestone changes materially:

1. Update the evidence table.
2. Update the forecast only from changed evidence.
3. Add or update tests for any bug family fixed.
4. Run targeted checks.
5. Commit with pass number, date/time, and milestone label.
