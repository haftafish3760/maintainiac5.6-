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
- Reliability is proven per workflow and target; a forecast percentage never
  substitutes for measured fixture and physical-device evidence.
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
| Shared entry and permissions | User can start receipt capture from shared flow with safe fallback. | Chooser, assistance opt-in/manual path, permission, camera-launch, import, and recovery contracts are included in the Pass 26 host milestone. Real-device launch proof is still required. | Partial |
| Native camera contract | Android CameraX and iOS AVFoundation expose matching high-level settings and capture metadata. | Flutter/native bridge contracts are green. Android packaging and iOS simulator compilation pass; first-party iOS warnings are gate failures after Pass 30. Real-device proof is still required. | Partial |
| No preview tap focus | Preview/screen tap focus is banned; phone-native continuous autofocus is primary. Any manual focus control must be explicit, reversible, device-supported, and separately approved. | Active docs and regression tests exist. | Strong |
| Single photo capture | Manual capture works, review opens, retake/use actions are stable. | Capture, review, retake, use, staging, recovery, and OCR-source contracts are green in the current host milestone. Real-device proof is still required. | Partial |
| Quality guidance | Release-one live guidance stays conservative: neutral receipt framing/readability guidance, small-text/distance, and edge visibility can guide capture; blur, glare, shadow, dirty-lens, low-light, and steadiness claims stay disabled by default unless separately proven. Post-capture review may surface saved-photo quality risks as advisory review prompts. | Quality model/tests exist; unproven live quality claims are default-off and need real receipt calibration before promotion. Experimental live warnings now also wait for a reliable framed receipt target instead of any vague bounds hit. Optional experimental blur/focus scoring stays out of the default flow. | Partial |
| Long receipt ordering | Add Photo creates ordered segments; retake preserves index and context. | Phase 5 contracts are green for numbering, continuation ordering, retake slot preservation, and section-order regressions. Real-device UI/interruption proof is still required. | Partial |
| Ghost/overlap guidance | Previous segment bottom 15-20% guides the next capture; middle retake can use previous/next context. | Ghost-guide contracts are green through Phase 5 and the milestone gate. Real-device visual proof is still missing. | Partial |
| Stitch/fallback | Strong overlap stitches; weak overlap falls back to ordered OCR handoff without corrupting sources. | Registration, coordinate-space, positional OCR, native proposal, seam, transformed-stack, fallback, cancellation, and source-preservation host regressions are green through Pass 31. Physical saved-composite proof remains required. | Partial |
| OCR source handoff | OCR gets temporary full-quality source or ordered segments; saved compressed proof is separate. | Handoff, privacy, source-count, stitch-followthrough, durable-save, and artifact-cleanup contracts are green through Pass 26. Final app-flow and real-device proof are still required. | Partial |
| Review mode handoff | Camera output carries price-only versus detailed-line review intent; parser owns final line extraction/numbering. | Review-depth contracts and expense line numbering already exist; needs app-flow proof. | Partial |
| Barcode/QR handoff | Receipt capture can hand barcode/QR evidence forward without owning inventory work. | Service files and camera summary tests exist; flow proof can wait behind capture/stitch. | Partial |
| Device/storage safety | Older devices reduce heavy work; low storage avoids unsafe processing. | Capability-derived registration/search limits, storage-proof timing, cancellation, and representative S24/S9 Plus/iPhone SE/budget profiles are green through Pass 27. Runtime memory, latency, and thermal proof are still missing. | Partial |
| Fixture QA | External versioned receipt fixtures cover parser, damage, long-receipt, device-tier, privacy, maintenance, fuel, retail, contractor-supply, and adjustment families. | All ten packs load through the external JSON contract: 34 fixtures and 993/993 deterministic checks passed in Pass 25. Real redacted physical captures remain a separate evidence tier. | Strong (host) |
| Milestone quality gate | Targeted camera tests, source audit, doc gate, analyzer, compile gates, and real-device notes pass together. | Pass 26 closed 374/374 deterministic milestone tests with analyzer/schema/source gates green. Passes 29-31 removed first-party iOS compile warnings and added warning enforcement to the authoritative QA plan. The shared wrapper still honors its unrelated-dirty-work ownership fence. Physical target rows remain `NOT RUN`. | Partial |

## Forecast Method

Use this evidence-based method:

1. Count only unsatisfied receipt requirements, not generic camera-app work.
2. Identify the exact proof target for each requirement: source contract,
   deterministic fixture, compile/package gate, virtual-device measurement, or
   named physical-device run.
3. Add a repair pass only for a reproduced defect or a directly missing proof
   mechanism; add a regression before closing that pass.
4. Re-run the affected deterministic bundle after every repair and the full
   milestone at defined handoffs.
5. Keep unavailable physical rows as `NOT RUN`; never turn a device-class guess
   into a pass estimate or copied result.

## Current Forecast

The deterministic engine is ready for controlled target evidence, but the
remaining repair count cannot be known before those measurements exist. The
minimum is one independently recorded execution for each available required
target, followed by a bounded repair-and-regression pass for every reproduced
defect. Do not manufacture a fixed pass count or copy evidence between targets.

## Current Non-UI Punch List

Use this punch list before any new camera UI polish:

1. Keep Phase 6 stitch/fallback regressions green as real receipt fixtures are
   added.
2. Keep Phase 7 OCR-source handoff follow-through green as app-flow and
   device-proof work lands.
3. Keep Phase 8 storage-proof timing verification green while device/UI proof
   is added.
4. Deterministic host work is green through Pass 31. Keep it green while exact
   physical and constrained-runtime evidence is collected.

## Exact Physical and Virtual Target Proof

The target rows are non-substitutable:

- Galaxy S24 Ultra: current Android flagship baseline.
- Galaxy S25 Ultra: additional flagship evidence only; it does not satisfy the
  S24 row.
- Galaxy S9 Plus: former flagship and older Android baseline; do not label it a
  budget or low-tier phone.
- Constrained Android emulator: deterministic low-resource virtual evidence.
- iPhone SE third generation: exact iOS AVFoundation target; another iPhone or
  simulator does not satisfy it.
- Future budget Android: physical budget-device evidence when available.

Record unavailable rows as `NOT RUN`. Never copy timing, memory, camera, OCR,
or stitching results from another row.

`tool/receipt_camera_real_device_snapshot.sh` is metadata-only environment
evidence. Do not treat that snapshot as receipt capture proof. Real-device proof
still requires manual receipt flows on the connected phones.

`tool/receipt_real_device_result_gate.dart` and
`docs/receipt_real_device_result_template.md` define the expected structure for
those manual phone notes. A green template gate is not proof that the manual
flows passed; it only proves the reporting lane is ready.

`tool/receipt_real_device_result_start.sh` can prefill a new run note with
branch, commit, workspace, and metadata-only device snapshots before the manual
test session starts.

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
