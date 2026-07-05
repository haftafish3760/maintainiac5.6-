# Receipt Camera Completion Map

This file is the estimating source of truth for Maintainiac receipt-camera work.
Do not answer "how many passes are left" from a hunch. Use this map, update the
evidence, then answer from the current completion state.

## Estimating Rules

- A pass count is a planning forecast, not proof of quality.
- Do not give a precise-looking number unless it is tied to the milestones
  below.
- For quick answers, state that the number is a quick estimate.
- For verified answers, inspect current source, tests, docs, native contracts,
  and device evidence before answering.
- The release target is 90-93% reliability for core receipt-camera workflows,
  not 99% scanner-app perfection.
- Real receipt/device testing can move the estimate up or down.

## Current Scope

Camera scope includes:

- launch shared receipt capture
- take or import a normal receipt photo
- use the platform-native camera stack as the baseline instead of building a
  pro camera replacement
- guide the user toward a clear image
- review, retake, add photo, or use receipt
- capture long receipts in ordered segments
- preserve segment order during retakes
- show ghost/overlap guidance for continuation capture
- stitch when evidence is strong
- fall back to ordered segments when stitching is risky
- hand OCR the best available camera evidence
- keep source and derived image responsibilities explicit

Camera scope excludes:

- replacing Samsung, Google, Apple, or other device camera software
- trying to outbuild Google ML Kit OCR
- ISO, RAW, white-balance lock, exposure lock, screen-tap focus, focus lock, or
  manual lens-distance controls without explicit approval
- full receipt parser perfection
- inventory parser work
- PDF generation or import polish
- maintenance automation
- invoices, maps, cloud sync, or admin dashboards

## Completion Evidence Table

| Work package | Target proof | Current evidence | Status |
| --- | --- | --- | --- |
| Native camera baseline | CameraX/AVFoundation use device defaults for core camera behavior while Maintainiac owns receipt UI/review/stitching only. | Contract docs/tests exist; production code now has a native-baseline policy. | Strong |
| Shared entry and permissions | User can start receipt capture from shared flow with safe fallback. | Source and tests exist for camera actions, permission, and fallback contracts. | Partial |
| Native camera contract | Android CameraX and iOS AVFoundation expose matching high-level settings and capture metadata. | Flutter contract and native bridge tests exist; real-device proof still required. | Partial |
| No preview tap focus | Preview/screen tap focus is banned; continuous focus/readability guidance is primary. | Active docs and regression tests exist. | Strong |
| Single photo capture | Manual capture works, review opens, retake/use actions are stable. | Capture/review source and tests exist; real-device proof still required. | Partial |
| Quality guidance | Blur, glare, low-light, edge/crop, bottom, and readability warnings are advisory and do not block manual capture. | Quality model/tests exist; thresholds need real receipt calibration. | Partial |
| Long receipt ordering | Add Photo creates ordered segments; retake preserves index and context. | Continuation/order tests exist; more UI and interruption evidence needed. | Partial |
| Ghost/overlap guidance | Previous segment bottom 15-20% guides the next capture; middle retake can use previous/next context. | Ghost guide contract/source exists; real-device visual proof is missing. | Partial |
| Stitch/fallback | Strong overlap stitches; weak overlap falls back to ordered OCR handoff without corrupting sources. | Stitch source/tests exist; synthetic and real receipt fixtures need expansion. | Partial |
| OCR source handoff | OCR gets temporary full-quality source or ordered segments; saved compressed proof is separate. | Handoff tests exist; final app-flow proof still required. | Partial |
| Review mode line handoff | Camera output can carry numbered line/segment evidence for price-only or detailed review later. | Some handoff/line signal source exists; end-to-end review proof incomplete. | Early |
| Barcode/QR handoff | Receipt capture can hand barcode/QR evidence forward without owning inventory work. | Service files exist; camera-flow integration proof incomplete. | Early |
| Device/storage safety | Older devices reduce heavy work; low storage avoids unsafe processing. | Capability/storage contracts exist; real-device proof missing. | Partial |
| Fixture QA | Synthetic and real receipt fixtures cover camera failure families. | Many camera tests exist; fixture matrix is not yet release-grade. | Partial |
| Milestone quality gate | Targeted camera tests, source audit, doc gate, analyzer, and real-device notes pass together. | Targeted checks have passed in recent passes; final milestone gate is not proven. | Missing |

## Forecast Method

Use this formula for pass forecasts:

1. Count the remaining work packages that are `Missing`, `Early`, or `Partial`.
2. Weight each package:
   - `Strong`: 0-50 passes for regression maintenance.
   - `Partial`: 120-260 passes depending on UI/native/test depth.
   - `Early`: 220-420 passes because contracts and tests both need work.
   - `Missing`: 300-600 passes because implementation and proof are absent.
3. Add 20-30% contingency for real-device camera behavior.
4. Do not count unrelated PDF, inventory, maintenance, maps, invoices, or parser
   work against this estimate.

## Current Forecast

From the current evidence table, the strongest single-number planning forecast
is:

**2,400 to 3,100 focused camera passes from this map's creation.**

That range is not a guess from the air. It comes from:

- ten `Partial` packages
- two `Early` packages
- one `Missing` package
- one `Strong` package needing only regression maintenance
- real-device and real-receipt contingency

If a single planning anchor is required, use:

**2,750 focused camera passes.**

Do not treat `2,750` as a promise. Treat it as the working anchor until the
evidence table is updated.

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
