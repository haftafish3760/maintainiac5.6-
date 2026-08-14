# Receipt Flow — Production Blueprint

**Status:** Product contract for the finished receipt experience.
**Scope:** Expense receipts only: capture/import, photo review, regular and long-receipt preparation, OCR-assisted review, manual entry, allocation, proof storage, and saved-record review.
**Non-goal:** This document does not authorize implementation changes by itself. It is the source of truth to design and implement against.

## 1. Product promise

Maintainiac records a purchase in a form a person can understand, verify, edit, and later export. A receipt is never silently accepted as correct. The user always sees the receipt image and can edit every saved value before saving.

The experience must be understandable without explaining OCR, image matching, confidence percentages, or internal analysis. The application may do that work in the background; the user sees plain language and clear choices.

## 2. Shared rules that apply to every receipt

1. A receipt is one **receipt session**. A session can hold one image, several images for one long or wide receipt, or a PDF.
2. The first receipt step is shared by Manual and App-assisted paths: choose how the receipt counts and make one category decision. The approved first screen remains the source-of-truth layout.
3. A user must make a category decision before Continue: select one receipt category, **Mixed items**, or **Not sure yet**. Category is optional as data, but deciding to leave it open is explicit.
4. A chosen Business or Personal classification is shown later as plain context, not repeatedly asked. A Split receipt exposes per-line Business/Personal/Split allocation where it is needed.
5. Android Back returns to the immediately previous receipt step and preserves the in-progress receipt session. Leaving the receipt flow deliberately returns to Expenses, never to a random internal step.
6. No screen advances without an explicit user action, except short progress states that immediately continue after their task finishes.
7. The original capture/import is retained only inside the active session while preparation, OCR, review, and editing are underway. It is not the default permanently saved proof image. The user picks a readable compressed proof before final save.
8. Every user-facing statement uses everyday language. Do not show confidence grades, parsing percentages, pixel terminology, OCR terminology, or developer diagnostics.
9. Phone layout baseline is 360dp wide. Controls remain usable at 320dp, scale cleanly through large phones, and use a centered max-width content column on tablets. Touch targets are at least 48dp high.

## 3. Design language and layout foundation

### 3.1 Visual language

- **Theme:** dark, high-contrast, calm, and compact—not a collection of oversized cards.
- **Font:** Roboto, matching the Flutter application.
- **Page background:** near-black.
- **Surfaces:** charcoal with a visible but restrained border; no pale-gray input surfaces.
- **Text:** white primary, muted-gray helper text.
- **Primary action:** green full-width action at the bottom of the safe area.
- **Money / selected state:** orange. Blue is reserved for links, selected supporting controls, and editable context where it is not an error.
- **Destructive action:** red, used only for discard/delete.
- **Spacing:** 16dp page margin; 12dp between tightly related rows; 20–24dp between sections; 8–12dp internal control padding.
- **Navigation:** compact 56dp top bar: Back on left, centered title, optional three-dot menu on right. No duplicated subtitles that crowd the photo viewport.

### 3.2 Screen anatomy

Each standard screen has four zones:

1. compact top bar;
2. scrollable content;
3. persistent bottom action area when there is a primary action; and
4. temporary feedback only when an operation is genuinely running.

Photo screens favor the image viewport. Forms favor a readable field order and avoid wrapping a field in multiple nested containers.

### 3.3 Responsive measurement contract

The finished design is specified against a **360dp-wide phone content area**.
Measurements are dp unless noted otherwise. They define hierarchy and density;
they are not a reason to crop content or force a fixed physical-pixel size.

| Element | Phone rule | Large phone / tablet rule |
| --- | --- | --- |
| Page gutter | 16 on each side; never below 12 at 320dp | Center content at 600 max width, retaining 16–24 outer gutter |
| Top bar | 56 high plus system inset; title is 22sp medium | Same height; do not create a taller tablet-only header |
| Screen heading | 28sp bold, 32–36 line height | May remain 28sp; hierarchy comes from space, not oversized type |
| Section title | 20sp medium, 28 above / 8 below | Same |
| Field label | 12sp medium, all caps only for brief labels | Same |
| Primary field | 56 high; 16 horizontal padding; 16sp entered text | Same; fields fill the content column |
| Selectable classification card | Three equal columns; 112 minimum high; 12 gap | Keep equal columns up to 600dp, then max each at 184 |
| Action row | 64 minimum high; icon 24; title 16sp; helper 14sp | Same |
| Compact context row | 52–56 high; one label/value hierarchy, not nested cards | Same |
| Divider | 1 high, low-contrast, with 12 vertical breathing room | Same |
| Bottom action area | 80 minimum including bottom safe inset; primary button 56 high | Same; fixed to content column, never over a photo |
| Primary button | 56 high, 12 radius, full column width | Same |
| Secondary/tertiary button | 48 high minimum; never reduce the touch target for density | Same |

**Photo-screen rules.** Between the 56dp top bar and the bottom action area,
the receipt viewport receives all remaining height. It may not be displaced by
a large title, stacked explanatory cards, or a permanent drawer. The selected
photo thumbnail rail is 64dp high, with 48dp thumbnails and 8dp gaps. A
single-photo viewport has a 220dp minimum height; a multi-photo review
viewport has a 260dp minimum height. On short phones, helper text yields space
before the viewport or bottom actions do.

**Form-screen rules.** A form field appears once: a label above it, one
input/select surface, and relevant helper/error text beneath it. Do not nest a
field inside a parent card merely to create a second border. Use 12dp between
related fields and 20dp before a new task or section. The keyboard must scroll
the focused field above the persistent action area; it must never cover the
typed description, price, or printed line total.

**Receipt-review rules.** A saved/review receipt is a flat document surface,
not a card per line item. The header uses 20sp store name, 14sp address/date,
and a compact classification/category context line. Each item row has an
ordinal in a 32dp leading column, description/value aligned in the remaining
space, and a divider after it. The monetary summary belongs at the bottom in
this order: subtotal, tax, business/personal allocation when applicable, then
the visually strongest receipt total. Long receipts scroll vertically; no
single item or informational panel may consume the entire screen.

**Dark-theme token intent.** Use near-black page background, charcoal surface,
white primary text, muted-gray supporting text, orange for money/selected
emphasis, green for the one primary completion action, and blue only for
supporting editable/link affordances. A border must remain visible at normal
brightness, but color alone must not convey selection, validity, or error.

## 4. Screen contract

### S0 — Receipt assistance preference (Expenses settings/onboarding)

**Purpose:** Let a user choose the default help level, accurately described.

**Contains:**

- `Manual receipts` — the app starts with a blank receipt form after image preparation.
- `App-assisted receipt extraction` — the app reads the receipt and proposes a form; the user reviews it before save.
- Short helper text that neither option promises artificial intelligence. The second option says the app reads receipt text locally/on device when available.

**Actions:** Save preference. This setting changes the downstream form path, never the first classification/category screen.

### S1 — Classify this receipt (approved first Add Receipt screen)

**Purpose:** Tell the app how the receipt should be recorded before capture/import.

**Contains:**

- compact header `Add Receipt`;
- mode subtitle that is conditional and truthful: `Manual` or `App-assisted`;
- heading `Please classify this receipt`;
- brief promise: `You can review and change every detail before saving.`;
- three equal controls: Business, Personal, Split;
- category section headed `Choose a category for this receipt` with `Optional` helper text;
- one closed category selector;
- separate radio-style choices: `Mixed items` and `Not sure yet`;
- full-width green `Continue`.

**Rules:**

- Continue is disabled until the user selects Business, Personal, Split, or an explicit `Not sure yet` classification, and selects a category, Mixed items, or Not sure yet category decision.
- A specific category becomes the receipt default. `Mixed items` permits each item to have its own category. `Not sure yet` leaves categories unassigned.
- Business or Personal will not be repeatedly requested later. Split enables item-level choices later.

**Navigation:** Continue → S2. Back → Expenses home.

### S2 — Add receipt image

**Purpose:** Select the source without mixing it with form entry.

**Contains:** three clear source actions: `Take a photo`, `Upload photos`, `Upload PDF`; ordinary helper copy. Existing approved source-choice layout is retained.

**Rules:** Selected classification and category are carried in the receipt session. A user can return to S1 to change them.

**Navigation:** source selection → device camera, file picker, or PDF picker. Picker completion → S4. Back → S1.

### S3 — Capture receipt

**Purpose:** Let the phone camera capture receipt images using native camera capabilities rather than pretending to replace the device camera app.

**Contains:**

- nearly full-screen live camera view;
- visible receipt-edge guide;
- compact Back and three-dot menu;
- shutter, gallery, and current-photo thumbnail;
- menu actions only for relevant camera features such as flash and capture mode.

**Rules:**

- Device autofocus, exposure, brightness, and stabilization remain device-camera responsibilities when platform APIs allow them.
- No tap-to-focus behavior. If manual focus is supported, use a deliberate focus control/slider rather than an accidental tap target.
- Capturing an image adds it to the same receipt session and opens S4.

### S4 — Review selected photos

**Purpose:** Let the user verify source images before preparation. This is not a stitch result screen.

**Contains:**

- compact header `Review photos` and `1 of 1` / `1 of 2` context;
- a large, uncluttered image viewport; pinch zoom is available inside the image;
- thumbnail strip below the viewport; swiping changes the displayed photo, it does not drag the photo around the screen;
- compact `Add photo`, `Retake`, and `Crop & adjust` controls;
- a full-width `Continue`.

**Rules:**

- Retake replaces the selected source image only after confirmation.
- Add photo appends to the session in the user-selected order. Reordering is explicit, never inferred by a casual swipe.
- Continue is the only control that begins preparation. There is no “keep photos?” dialog after Continue.
- Exiting without saving leaves the receipt flow and returns to Expenses home after an explicit discard choice. Back returns to S2 and preserves session state.

### S5 — Crop and adjust photo

**Purpose:** Correct a source image without losing its original session copy.

**Contains:**

- full-screen editing canvas;
- edge-adjust/perspective control that moves receipt corners inside the image frame;
- crop control;
- rotate left and rotate right controls;
- reset and `Apply changes` actions.

**Rules:**

- `Straighten` is not a mislabeled rotation button. It aligns the receipt/perspective within the frame; rotation remains explicit and reversible in both directions.
- Applying changes produces a derived working image. The original is retained until final save or discard.
- Apply → S4 with the corrected image visibly shown. Back → S4 without applying.

### S6 — Preparing receipt

**Purpose:** A short, honest transition while the app prepares a derived image.

**Contains:** only a dark screen, progress indicator, and one plain phrase:

- `Preparing receipt`.

**Rules:**

- No underlying source screen flashes during the transition.
- This screen contains no user decision and automatically moves only after processing completes.
- One image skips stitching. Multiple images are prepared for long/wide receipt assembly.

### S7a — Finished receipt image (single image)

**Purpose:** Confirm the prepared single receipt image before the app reads it or stores a smaller proof.

**Contains:**

- `Receipt image` header;
- large scrollable/zoomable full image, without a drawer covering it;
- `Edit photo`, `Retake`, and `Continue`.

**Navigation:** Continue → S9 for App-assisted or S10 for Manual. Back → S4.

### S7b — Finished receipt image (long or wide receipt)

**Purpose:** Show the actual assembled receipt, in full, before any OCR result is trusted.

**Contains:**

- `Full receipt image` header;
- vertically scrollable, pinch-zoomable assembled image;
- `Retake images`, `Align photos yourself`, and `Continue`;
- no raw diagnostic score, seam percentage, or technical explanation.

**Rules:**

- The displayed result must be the assembled image, never only the first selected image.
- A user can visually inspect the entire long/wide document before proceeding.
- Continue → S8 (data saver) then S9 or S10. Back → S4.

### S7c — Could not put photos together

**Purpose:** Fail safely when an assembled result cannot be supported well enough.

**Contains:** simple copy: `These photos did not line up well enough to make one receipt image.`

- `Retake images`;
- `Align photos yourself`.

**Rules:** Never invent or silently save a merged document. There is no developer error text. The fallback offers these two recovery choices; it does not silently route the user into an unrelated form.

### S8 — Align photos yourself

**Purpose:** Offer manual alignment only when automatic assembly is not acceptable.

**Contains:**

- a full-canvas overlap workspace with no card blocking the images;
- selected source order (`Photo 1`, `Photo 2`, etc.);
- zoom, pan, scale, rotate, and vertical/horizontal adjustment tools;
- clearly marked seam/overlap region;
- `Use this alignment`.

**Rules:**

- The user can inspect shared content at full size and adjust the second image against the first.
- Adding a photo returns to S4 so order and individual edits stay understandable.
- Use this alignment creates the visible S7b result, then the user confirms it there.

### S9 — Save space on your phone

**Purpose:** Choose the stored proof-image size after the final image is visible.

**Contains:**

- full receipt preview with a hideable/showable side panel;
- panel title `Save space on your phone`;
- choices `Best detail`, `Balanced`, `Smaller file` with ordinary-language descriptions and estimated final size;
- panel handle/button `Hide panel` / `Show saving options` so the full image is never obscured;
- `Continue`.

**Rules:** The original session image remains available for OCR and review. The selected compressed proof is written only after final receipt save.

### S10 — Read receipt (App-assisted only)

**Purpose:** Communicate that the app is filling in the form, without exposing internal analytics.

**Contains:** `Reading your receipt` and the plain promise `You will review every detail before saving.`

**Rules:** Automatically moves to S11 on success. If text cannot be read, offer `Enter details yourself` → S12 while attaching the prepared image.

### S11 — Review receipt details (App-assisted)

**Purpose:** Show the proposed record in a clean, normal-receipt-like review before final save.

**Contains:**

- store name, optional store number, address, receipt date/time, and selected Business/Personal/Split plus category context;
- compact summary: line count and total only;
- numbered line-item list with divider between rows, not a huge analytics card per item;
- each line shows item number, description, quantity/unit, unit price when known, line total, optional category, and `Edit`;
- receipt subtotal, sales tax, and final total at the bottom;
- `Add item`, `Preview receipt`, and `Continue`.

**Rules:**

- Every displayed value is editable.
- No confidence percentage, failure-grade, or OCR jargon is shown to the user.
- Repeated identical printed items remain individual ordered occurrences until the user deliberately changes them. The app must not collapse them merely because the text matches.
- Total checks may warn in plain language that the visible items do not match the receipt total; this is a review prompt, not a silent alteration of money.

### S12 — Add receipt details (Manual)

**Purpose:** Enter the record by hand while retaining the prepared receipt photo as proof.

**Contains:**

- receipt header context (classification/category/date/time);
- store-information action that opens an editable form and returns a readable store summary;
- `Add item` action;
- numbered compact line list after items are added;
- subtotal, sales tax, total fields;
- `Preview receipt` and `Continue`.

**Rules:** The user can type a line total directly when that is all they know, or add full description/price/quantity/unit details. No separate receipt type is required.

### S13 — Add or edit item

**Purpose:** Edit one line item in a focused, readable form.

**Contains, in this order:**

1. `Item total` row at top with an optional direct total entry and short helper text;
2. item description;
3. price per unit;
4. quantity stepper with visible minus and plus controls;
5. unit of measure selector;
6. category selector when the receipt category is Mixed items or Not sure yet;
7. Business/Personal/Split control only when the parent receipt is Split;
8. `Save item`.

**Rules:**

- Inputs use dark, high-contrast fields; typed text remains visible above the keyboard.
- Unit options include each, piece, box, case, pound, ounce, gallon, quart, liter, kilowatt-hour, mile, hour, and a custom unit. Category/receipt content can suggest a unit but never prevents correction.
- Fuel/charging categories suggest appropriate energy units; they do not assume gasoline-only vehicles.
- Selecting Split opens S14 rather than exposing a cramped inline gray field.
- Save returns to S11 or S12 with the item’s number preserved.

### S14 — Split item / Split receipt allocation

**Purpose:** Divide a receipt or line between Business and Personal in one focused calculation screen.

**Contains:**

- line/receipt total at top;
- toggle: `Percentage` or `Dollar amount`;
- Business and Personal inputs;
- live calculated counterpart amounts;
- plain validation statement;
- visible allocation preview; and
- full-width green `Apply split`.

**Rules:**

- Percentage must equal exactly 100%; dollar mode must equal the relevant total, accounting for rounding to cents.
- The user can return and correct it without losing other item details.
- Vehicle-mileage allocation is a future, user-opt-in source for suggested split values; it never silently overrides a user’s selection.

### S15 — Receipt preview before save

**Purpose:** Present the actual finished record like a familiar store receipt before it enters the ledger.

**Contains:**

- store name/store number at top when known;
- store address;
- receipt date/time and entry timestamp context;
- classification and category;
- numbered line items with quantities/unit prices/totals;
- subtotal, tax, business/personal split totals if applicable, and receipt total at bottom;
- attached-photo indicator;
- `Cancel`, `Edit`, and green `Save receipt`.

**Rules:**

- This is a review page, not an analytics page.
- `Edit` returns to the appropriate review/form screen; `Cancel` leaves the draft; Save is the only action that commits a receipt record and compressed proof.

### S16 — Saved receipt details

**Purpose:** Let the user later view, edit, export, or correct a saved record.

**Contains:** stored receipt record and image proof; same normal-receipt hierarchy; Edit and export actions.

**Rules:** Receipt date remains the ledger date. Entry timestamp is preserved separately for audit/history. Edit preserves revision history rather than overwriting the prior state without trace.

## 5. End-to-end user flows

### 5.1 App-assisted, regular receipt

`S1 → S2 → capture/import → S4 → S6 → S7a → S9 → S10 → S11 → S13/S14 as needed → S15 → S16`

### 5.2 App-assisted, long or wide receipt

`S1 → S2 → capture/import multiple images → S4 → S6 → S7b`.

If automatic assembly is not acceptable: `S7c → Retake → S4` or `S7c → S8 → S7b`.

Then: `S9 → S10 → S11 → S13/S14 as needed → S15 → S16`.

### 5.3 Manual receipt, regular or long receipt

`S1 → S2 → capture/import → S4 → S6 → S7a/S7b → S9 → S12 → S13/S14 as needed → S15 → S16`.

The image path is shared. Manual changes only the form-filling step; it does not create a second incompatible receipt system.

## 6. Processing contract — the receipt engine behind the screens

### 6.1 Intake and session ownership

1. Create one durable in-progress receipt session before the picker/camera opens.
2. Record source order, source type, orientation metadata, non-destructive edits, classification/category decisions, and draft form values.
3. Keep the original imports only in the active session. All crop/straighten/compression output is derived and linked to its source.
4. The session survives normal navigation and Android Back. It is cleared only when the user discards it or saves it.

### 6.2 One image versus several images

- **One image:** normalize orientation, apply approved crop/perspective adjustments, make a display preview, then continue. No stitch task is run.
- **Several images for one receipt:** retain user order as the initial order, normalize each image, analyze candidates, and present an assembled result or a safe fallback.
- **Several separate receipts in one future upload:** do not guess and merge them into one. The future multi-receipt queue must create separate receipt sessions after explicit user confirmation. That is outside this single-receipt design but is a hard boundary, not a reason to hardcode a one-image limit.

### 6.3 Long/wide receipt assembly

The app must use several complementary signals. It must not rely on brightness alone, one raw pixel score, or text alone.

1. **Prepare each source:** correct EXIF orientation; generate a bounded working copy appropriate to device capability; retain original dimensions; detect document edges/perspective when possible.
2. **Determine candidate relationship:** top-to-bottom, left-to-right, or no reliable relationship. User order is respected as a strong prior but remains reversible in manual alignment.
3. **Find likely overlap:** compare receipt geometry, structural line patterns, feature correspondences, and readable text blocks/line baselines in the lower edge of one image and upper edge of the next. OCR contributes matching words/numbers/layout as corroboration; it does not invent a seam.
4. **Reject weak candidates safely:** a candidate must satisfy a coherent geometric transform and enough corroborating evidence. Brightness correlation alone cannot pass it.
5. **Compose:** warp/perspective-correct the working images into one canvas, crop duplicate overlap conservatively, blend only where the geometry agrees, and encode a derived assembled image.
6. **Validate:** confirm resulting document bounds, readable transition, ordered text continuity when text exists, and basic header/body/footer plausibility. Receipt total/subtotal reconciliation is a useful soft check—not a hard blocker because receipts can contain discounts, taxes, returns, or unreadable print.
7. **Show the user the exact output:** S7b always displays the produced canvas. If validation is inadequate, show S7c rather than a first photo or a fake completed preview.

### 6.4 Difficult and edge cases

| Situation | Required handling |
| --- | --- |
| Repeated identical line items across the overlap | Preserve individual line occurrence/order and use image geometry plus surrounding layout; never deduplicate because text matches. |
| Clean, repetitive receipt with little visual variation | Do not claim a confident merge from text repetition alone; present manual alignment or separate-photo fallback. |
| Bent, dirty, folded, greasy, faint, or shadowed receipt | Attempt edge/perspective normalization and readable working copies; do not reject merely because the image is imperfect. If it cannot be assembled, offer Retake or manual alignment. |
| No printed subtotal/tax | OCR leaves fields blank/unknown; user can enter them. The absence is not a failed receipt. |
| Line-item sum differs from printed total | Preserve printed total, flag plain-language review, and let the user correct missing/incorrect items. Do not change amounts automatically. |
| No readable text | Keep the image proof; Manual path remains available. |
| Wrong photo order | Offer explicit reorder in S4 and manual alignment in S8. |
| User exits during processing | Cancel/discard the derived task result; preserve sources and return only to a valid previous receipt step. |
| Low-memory/low-performance device | Limit working-image size and parallel tasks based on device capability; degrade to manual alignment/separate photos rather than freezing or crashing. |
| Wide 8.5 × 11 or handwritten receipt | Treat it as a document canvas, not a narrow thermal strip. Determine horizontal/vertical relation from geometry and allow manual alignment. Handwritten text can remain a photo-backed manual record if it cannot be read. |

### 6.5 OCR and record creation

1. OCR reads the prepared single or assembled receipt image first; it never uses the final compressed proof as its only source.
2. Parser output is a draft: merchant/store number/address, receipt date/time, line occurrences, quantity/unit/unit price/line total, subtotal/tax/total, and plausible category suggestions.
3. The app preserves raw source-to-line mapping internally so an edited line can refer back to its visual source, but it does not expose parser analytics to the user.
4. The user reviews every field in S11/S12 and can add, remove, reorder, or edit any item.
5. On final Save, persist the reviewed record, audit/revision data, original session metadata needed for recovery, and the user-selected compressed proof. Release temporary originals only after save/discard rules complete.

## 7. Performance and reliability requirements

- Image assembly and OCR must run off the main interaction path; the interface remains responsive and cancellable.
- Device capability data drives working resolution, concurrency, output limits, and timeout/fallback strategy; no arbitrary fixed behavior for every phone.
- Performance targets require measured device tests, not claims from a desktop harness. Initial target budgets: high-end device 5–7 seconds for assembly, older flagship 8–10 seconds, and lower-end device 10–12 seconds, with a clear fallback rather than a blocked screen.
- Every stage exposes one state owner: the receipt session owns source paths, derived images, current operation generation, parsed draft, and selected proof option. Stale asynchronous results cannot overwrite a newer crop/reorder/retake.
- A screen only renders an image/result that belongs to its current session and generation.

## 8. Figma deliverable requirements

The finished Figma work lives on the new **Receipt Flow · Final Product Design** page in the existing Maintainiac Figma file. The current rejected pages remain untouched.

The file must include finished phone-sized screens—not a wireframe—and clickable flows for:

1. App-assisted regular receipt;
2. App-assisted long receipt, including automatic success, safe failure, and manual alignment;
3. Manual receipt using the shared image path;
4. Item edit and Split allocation;
5. Final receipt preview/save.

Use the user-provided receipt photos for the selected-photo thumbnails and prepared receipt previews when the files are available. Every visible button has a destination or an intentionally documented disabled state. The interactive design must let the user click through the flow without a dead end.

### 8.1 Current Figma traceability

The following on-canvas work is a finished visual direction for the named screen, not a claim that the Flutter implementation is complete. Contract IDs above remain authoritative; the temporary canvas labels below are retained only to locate the design nodes.

| Contract screen | Figma canvas screen | Node ID | Current state |
| --- | --- | --- | --- |
| S1 Classify this receipt | `S1 · Classify this receipt` | `24:2` | Built; Continue leads to S2. |
| S2 Add receipt image | `S2 · Choose receipt source` | `28:3` | Built; source actions lead to capture design. |
| S3 Capture receipt | `S3 · Capture receipt` | `31:3` | Built; shutter leads to the preparation design. |
| S6 Preparing receipt | `S6 · Preparing receipt` | `32:3` | Built; progress-only screen. |
| S7c Safe assembly fallback | `S7c · Assembly fallback` | `40:3` | Built; shows Retake images and Align photos yourself only. |
| S12 Manual Add receipt details | `S12 · Add receipt details (Manual)` | `39:3` | Built; Add items, Preview, and Continue are wired. |
| S13 Add or edit item | `S13 · Add item · Split mixed` | `36:3` | Built; Split and category actions are wired. |
| S13 category picker | `S13a · Choose item category` | `41:3` | Built; Cancel and Use category are pinned and wired. |
| S14 Split allocation | `S14 · Split allocation` | `35:3` | Built; Apply returns to item editing. |
| S15 Receipt preview before save | `S15 · Receipt review` | `37:3` | Built; Edit returns to Add receipt details. |

Still required before the interactive design is approved: S4 review selected photos, S5 crop and adjust, S7a single-image preview, S7b assembled-image preview, S8 manual alignment, S9 data saver, S10 app-assisted read transition, S11 app-assisted detail review, the associated click paths, and placement of the actual receipt photos. Those screens must use real receipt images rather than invented stand-ins.

## 9. Acceptance checklist

- [ ] The approved S1 classification/category layout is retained, not redesigned.
- [ ] Capture/import screens are retained unless a later explicit amendment changes them.
- [ ] No transition flashes an unrelated Add Receipt or upload screen.
- [ ] Review Photos is user-controlled; it does not auto-advance.
- [ ] One image shows a single prepared result; multi-image shows a real full assembly or safe fallback.
- [ ] Manual alignment is usable full canvas, not a card-covered placeholder.
- [ ] Data saver occurs after the correct prepared result and never hides most of the image.
- [ ] No user-facing OCR/stitch analytics percentages.
- [ ] All OCR/manual fields are editable and every line item is numbered.
- [ ] Split has a dedicated percentage/dollar allocation screen.
- [ ] Final preview looks like a familiar receipt, with totals at the bottom.
- [ ] Back navigation preserves the receipt session and returns one valid step at a time.
- [ ] Each Figma click path reaches a valid next screen or a deliberate recovery choice.

## 10. Implementation repair roadmap

This roadmap is based on a read-only source audit of the current Expenses
receipt code. It prevents another visual rewrite from silently replacing the
durable photo, OCR, or proof behavior that already exists.

### 10.1 Preserve, do not rewrite

The repair must retain these established contracts and adapt them behind one
receipt-session owner:

1. native camera/import staging and its permission/recovery handling;
2. non-destructive image crop/rotate output and temporary-artifact cleanup;
3. receipt proof promotion after a successful local ledger save;
4. local OCR service, line parsing, editable parsed-line merge, and manual
   fallback;
5. draft persistence, saved receipt records, and revision/readiness checks;
6. device-capability limits used for image preparation and receipt assembly.

No repair pass may delete, replace, or change those contracts merely to make a
screen appear simpler. Each existing contract is retained unless a focused
source-level defect proves it unsafe.

### 10.2 Current source-level defects to repair

The audit found these separate state owners and route decisions in the current
flow. They are evidence of the problem, not finished behavior:

1. The visible Expense receipt form owns classification, category, manual step,
   form fields, lines, and attachments. A hidden/offstage attachment panel owns
   a second copy of photo import/review state and opens routes independently.
2. The S1 Continue handler validates only Business/Personal/Split. It does not
   require the explicit category, Mixed items, or Not sure yet decision required
   by this contract.
3. That same handler opens the source chooser but does not move the visible
   form from the classification step to the next session step. Later parsing
   can independently set the form directly to Review. This permits skipped
   details screens and inconsistent Back behavior.
4. The source chooser, device picker, photo review route, and visible receipt
   form each control closing/return behavior. Their nested pushes and delayed
   pops can expose an underlying Add Receipt screen between transitions.
5. Multi-photo assembly occurs inside the photo-review widget. The current
   long-receipt result may be used as a temporary OCR source, but the durable
   saved proof is the individual compressed sections rather than a confirmed
   assembled receipt artifact. The final record cannot rely on a permanent
   full stitched proof today.
6. The attachment panel and the Expense form disagree on the default meaning
   of an unset assistance preference. A new session must receive one immutable
   mode decision at S1 and every downstream operation must read that decision.

### 10.3 One authoritative receipt session

Before repairing individual screens, define one persisted in-progress session
record and one coordinator. The coordinator may adapt the existing draft and
attachment contracts; it must not create a parallel second draft store.

The session owns:

- a stable session ID and source mode;
- chosen receipt-wide classification and explicit category decision;
- ordered original source references and their derived edits;
- one current visual step from S1 through S16;
- one operation generation/cancellation token for image preparation, assembly,
  OCR, and compression;
- assembled-image outcome or explicit fallback outcome;
- selected saved-proof option and temporary artifact ownership; and
- parsed-but-editable record values and final-save readiness.

Every route receives that session ID and returns an explicit result. No widget
may infer a next screen by looking only at a local photo list, an assistance
setting, or whether a parser happened to finish first.

### 10.4 Repair passes and completion evidence

A pass means one bounded component: inspect its owners, make its scoped
changes, run only its relevant checks after design is complete, record the
result, and then close that component before starting the next. The expected
repair sequence is:

1. **Session and navigation pass:** make S1 decisions explicit; introduce the
   single session route sequence; remove competing automatic route ownership;
   prove Back preserves the current session and exits only deliberately.
2. **Selected-photo review pass:** implement S4/S5 around the session; verify
   paging versus image pan, Add/Retake, crop/perspective, and reversible
   rotate-left/rotate-right behavior.
3. **Preparation and assembly pass:** implement S6 then S7a/S7b/S7c/S8;
   preserve originals; show only an actual assembled image or the two approved
   recovery choices; persist the approved full-receipt proof when appropriate.
4. **Saved-image and OCR handoff pass:** implement S9/S10/S11 with the exact
   prepared source; keep all user-facing copy free of internal scores and keep
   every OCR value editable.
5. **Manual forms and allocation pass:** implement S12/S13/S14/S15 against the
   same session, including ordered line occurrences, units, split validation,
   and plain receipt context.
6. **Durability and recovery pass:** verify save, draft recovery, discard,
   temporary-source cleanup, permanent proof promotion, and saved-record
   editing without changing unrelated modules.
7. **Evidence pass:** use real short, long, wide, and difficult receipt images;
   validate the completed interaction on explicitly authorized devices and
   record actual timing/fallback outcomes by device tier.

No pass is considered complete merely because source-text tests pass. Screen
design, unit/contract checks, real-image outputs, and explicitly authorized
device interaction prove different parts of the result and must remain labeled
accordingly.
