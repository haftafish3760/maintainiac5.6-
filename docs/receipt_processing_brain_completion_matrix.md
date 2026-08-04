# Receipt Processing Brain Completion Matrix

This matrix is the completion authority for the current receipt-brain goal.
Green source contracts, host tests, a successful build, installed-device
behavior, and physical-receipt accuracy are separate evidence levels. A row is
complete only when its named proof exists; a related passing test is not a
substitute for the missing proof.

## Evidence Labels

- `verified-host`: current source and focused executable tests prove the brain
  contract without a physical device.
- `partial`: useful implementation exists, but a named source, fixture,
  integration, performance, or recovery gap remains.
- `device-required`: host work is closed and the remaining claim requires a
  supported physical device and receipt.

## Capture, Intake, And Source Ownership

| Requirement | Current evidence | Status / required closure |
| --- | --- | --- |
| Camera capture uses high-resolution stills, not saved video | CameraX/AVFoundation native contracts and bridge tests | `verified-host`; S24 capture parity remains device-required |
| Photo import preserves the selected source and order | import staging and handoff contracts | `verified-host` |
| PDF intake produces safe OCR pages or an explicit rejection | PDF OCR service, safety warnings, and size/read-failure contracts | `partial`; add end-to-end representative PDF fixtures |
| Full-quality originals remain temporary OCR/review sources | durable-save lifecycle, staging recovery, and cleanup tests | `verified-host` |
| Saved images are generated separately at the chosen compression level | data-saver preview/final parity and storage tests | `verified-host`; visual readability remains device-required |
| Originals are deleted only after durable receipt and image save | durable acknowledgement and app-owned cleanup contracts | `verified-host`; process/device interruption proof remains |
| User-owned gallery originals are never deleted | artifact ownership checks | `verified-host` |

## Document Preparation And Quality

| Requirement | Current evidence | Status / required closure |
| --- | --- | --- |
| Orientation is normalized before OCR/stitching | EXIF/orientation preparation and native bridge contracts | `verified-host` |
| Edge detection supplies safe crop guidance | native framing analysis and crop suggestion contracts | `verified-host`; camera calibration remains device-required |
| Auto crop never removes off-center receipt content | unsafe/off-center crop rejection tests | `verified-host` |
| Deskew/straighten changes document angle rather than translating it | horizontal-edge alignment scoring and skewed-receipt output regression | `verified-host`; physical camera calibration remains device-required |
| Perspective correction is bounded by detected receipt geometry | independent four-corner detection, distortion/readability guards, and rectified-corner regression | `verified-host`; real warped-receipt output remains device-required |
| Cleanup can prepare OCR copies without changing saved originals | source-preparation and cleanup-setting tests | `verified-host` |
| Quality decisions are advisory and do not block manual shutter | native capture and guidance contracts | `verified-host`; threshold calibration remains device-required |
| Diagnostics contain buckets/reason codes, not private receipt content | privacy diagnostics and QA checks | `verified-host` |

## Multi-Photo And Long-Receipt Processing

| Requirement | Current evidence | Status / required closure |
| --- | --- | --- |
| Capture/review retains ordered sections and retake indexes | section-order and retake contracts | `verified-host`; interruption flow remains device-required |
| Neighbor-aware ghost guidance supplies previous and next context | native continuation-guide contracts | `verified-host`; legibility remains device-required |
| OCR evidence is actually passed into ordering and geometry | live call path through `recognizeStitchTextEvidence` and `textEvidence` | `verified-host` |
| OCR ordering does not stall lower-capability devices | fixed 28-second pre-stitch OCR timeout found in live path | `partial`; replace with capability-derived bounded work |
| Automatic ordering supports every allowed 2-8 photo stack | exact permutation search is bounded to six; 7-8 preserves selected order | `partial`; implement scalable confidence-safe ordering |
| Visual matching uses geometry/detail, not brightness alone | multiscale overlap, continuity bands, transform and receipt-shape guards | `verified-host` |
| Visual coordinates remain valid on full proof images | coordinate-space and placement regressions | `verified-host` |
| OCR acceleration requires two distinct shared lines | direct text-evidence safety tests | `verified-host` |
| Identical repeated purchases never prove a seam or disappear | repeated-line ambiguity and OCR reconstruction tests | `verified-host` |
| Header/body/footer evidence influences order/completeness | OCR header/footer hints and continuation decisions | `partial`; add explicit topology fixtures for 3-8 sections |
| Two-photo composition preserves all receipt regions | synthetic suite plus Walmart A/B reproduction | `partial`; A safely falls back, B stitches, seam width still needs polish |
| Three-to-eight-photo composition is bounded and recoverable | long-stack tests and output caps | `partial`; 7-8 automatic order and physical stacks remain |
| Weak/unrelated photos cannot create a false combined receipt | screenshot, duplicate, weak-overlap, and acceptance tests | `verified-host` |
| Manual alignment changes scale, angle, X, and overlap with safe bounds | manual-overlap and transform contracts | `verified-host`; touch usability remains device-required |
| Failed pairs offer targeted retake or ordered-source fallback | failed-pair metadata and review handoff | `verified-host`; rendered flow remains device-required |
| Seam selection avoids duplicated or missing rows | seam crop and repeated-overlap tests | `partial`; add image-difference/seam continuity acceptance metrics |

## OCR, Parsing, Review, And Save

| Requirement | Current evidence | Status / required closure |
| --- | --- | --- |
| ML Kit reads full-quality/prepared sources before compression | OCR source selection and lifecycle contracts | `verified-host`; physical ML Kit accuracy remains device-required |
| Section text is reconstructed by ordered positional overlap | OCR combiner and source-location tests | `verified-host` |
| Repeated identical items remain separate when overlap is ambiguous | repeated-item tests and arithmetic review behavior | `verified-host` |
| Merchant, date, items, subtotal, tax, total, tender are represented | parser handoff models and QA runner fields | `partial`; real external fixtures are absent |
| Missing subtotal/total does not invent receipt evidence | arithmetic and missing-total review contracts | `verified-host` |
| Line sums/tax/total disagreements create review tasks | reconciliation tests | `verified-host` |
| Every extracted field remains editable before save | parser draft and expense-model handoff contracts | `partial`; end-to-end rendered edit/save proof remains |
| Parser confidence is user-facing review guidance, not hidden analytics | review reason/task models | `partial`; verify final app screen does not expose internal percentages |
| Receipt save persists the chosen image, fields, classification, and category | expense save and durable cleanup contracts | `partial`; physical save/reopen/recovery remains |
| OCR/parser works locally without cloud or AI authority | ML Kit/local parser ownership | `verified-host` |

## Reliability, Performance, And Recovery

| Requirement | Current evidence | Status / required closure |
| --- | --- | --- |
| Device capability controls stitch resolution, comparison work, output size, and deadline | low/medium/high policy tests and live call wiring | `verified-host` |
| Timed-out stitch work is cancelled, partial output removed, sources preserved | managed-isolate timeout tests | `verified-host` |
| Stale asynchronous preview results cannot replace current photos/order | generation/key cancellation contracts | `verified-host` |
| Process interruption preserves recoverable native captures | staging records and recovery tests | `verified-host`; kill/relaunch remains device-required |
| Low-end work has measured latency/RSS/thermal budgets | host bounds exist, no low-end physical measurements | `device-required` |
| S24 regular and long receipt flow passes capture through reopen | no connected S24 in current ADB state | `device-required` |
| Parser QA uses representative real/redacted fixtures | runner: 956/956 synthetic checks; external fixtures not ready, no real samples | `partial`; create redacted image/text fixtures and expected outputs |
| Current debug build matches verified source | APK hash is recorded in the numbered pass log | `verified-host`; install/run evidence remains device-required |

## Pass 1 Findings That Must Drive Implementation

1. Replace the fixed 28-second stitch-evidence wait with capability-derived,
   cancellable work that cannot make Add Photo feel frozen.
2. Replace factorial-only automatic ordering with a bounded graph/path strategy
   that supports all allowed 2-8 section stacks and preserves selected order
   whenever confidence is ambiguous.
3. Add explicit document-angle/perspective output tests rather than relying on
   bridge setting names.
4. Add header/body/footer topology fixtures, seam acceptance metrics, and 7-8
   section ordering/composition regressions.
5. Add representative redacted external fixtures. The current 956/956 result
   proves its synthetic expectations, not 90-95% physical receipt accuracy.
6. Close rendered editable-handoff/save/reopen proof and physical device
   performance before claiming the brain is 100% finished.
