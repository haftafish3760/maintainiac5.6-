# Receipt Real-Device Test Script

This script is for controlled phone testing after a meaningful receipt-camera build. It is not a random tap-around checklist. The goal is to prove that a normal user can capture receipt proof, let Maintainiac fill the receipt review, classify the result, and save it without fighting the camera or losing the proof.

## Test Rules

- Test the receipt flow from the expense app first.
- Avoid maintenance-specific receipt paths during this test batch.
- Use the same receipt on every device when possible so differences are device-related, not receipt-related.
- Test at least one short receipt and one long receipt that needs more than one photo.
- Do not judge OCR from the smaller saved proof. OCR must happen from the best prepared image first.
- A failed read is acceptable only if the app explains what happened and lets the user continue manually with the proof saved.

## Device Targets

- Galaxy S9 Plus class device: proves older-phone limits, memory safety, and simpler camera behavior.
- Galaxy S24/S25 class device: proves flagship capture, stitching, image cleanup, and app-assisted review.
- iPhone SE class device: proves iOS capture, photo proof, PDF/import behavior, and route parity.

## Build Cadence

- Do not reinstall after every small change.
- Push a phone build only after a meaningful camera or receipt review batch.
- After install, start with a clean new expense receipt entry so stale draft state does not hide flow bugs.

## Flow 1: Single Photo Receipt

Purpose:
- Prove a normal short receipt can go from photo to app-assisted review.

Steps:
1. Open Expenses.
2. Start a new receipt expense.
3. Attach a receipt photo using the camera.
4. Tap the receipt text once to focus.
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
- Did tap-to-focus visibly help?
- Did the app move to receipt review after using the photo?
- What merchant, total, tax, and date did it detect?

## Flow 2: Long Receipt Multi-Photo

Purpose:
- Prove long receipts are treated as a first-class workflow.

Steps:
1. Start a new receipt expense.
2. Take the top section of a long receipt.
3. Add another photo.
4. Use the ghost/overlap guide if shown.
5. Capture the next section with some repeated lines from the first photo.
6. Add a third section if needed.
7. Review photo order.
8. Move one photo out of order, then put it back.
9. Continue to stitch/review.
10. Accept the stitched image if readable, or use top-to-bottom photo review if stitching is not confident.

Expected:
- The app makes photo order clear.
- The app can handle overlap without duplicating every repeated line.
- If the stitch is unsafe, the app falls back to reviewing ordered photos separately.
- The user can still continue manually with proof attached.

Must Never Happen:
- No forced bad stitch.
- No silent loss of a receipt section.
- No duplicate overlap lines trusted as separate purchases without review.
- No memory crash on an older phone.

Report Back:
- Did the app make it obvious which section was first, second, and third?
- Did it warn if a middle section might be missing?
- Did the stitched image remain readable?
- Did line items duplicate or disappear?

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

## Flow 4: App-Assisted Filled Receipt Review

Purpose:
- Prove app-assisted receipt fill leads to business/personal/mixed classification.

Steps:
1. Capture or import a receipt.
2. Continue with app assistance enabled.
3. Wait for the filled receipt review.
4. Review merchant, date, subtotal, tax, total, and line amounts.
5. Mark the whole receipt as business.
6. Change it to personal.
7. Change it to mixed.
8. For mixed, classify at least one line as business and one as personal.
9. If available, mark one line as split and set a percentage.
10. Save or keep as draft.

Expected:
- Whole receipt choices are clear: business, personal, mixed.
- Mixed receipts expose per-line classification.
- Split lines calculate business and personal amounts.
- Tax allocation is visible or explainable where relevant.
- Low-confidence fields are shown as needing review, not as trusted facts.

Must Never Happen:
- No automatic inventory update from an expense receipt.
- No hidden tax math for mixed receipts.
- No unexplained totals that do not match the receipt.
- No crash when saving draft or backing out.

Report Back:
- Did the app make mixed receipt classification obvious?
- Were totals and tax believable?
- Did it save the reviewed proof and classifications?

## Flow 5: Manual Or No-Assist Receipt

Purpose:
- Prove users can attach proof without app-assisted receipt fill.

Steps:
1. Open receipt photo settings.
2. Turn off app assistance for expense receipts.
3. Capture or import a receipt.
4. Continue.
5. Manually enter expense amount and category.
6. Save.
7. Reopen the saved expense and view the receipt proof.

Expected:
- The app does not force OCR.
- The proof remains attached.
- Manual expense save still works.
- Reopening the expense shows the proof.

Must Never Happen:
- No forced OCR when assistance is off.
- No loss of the receipt photo.
- No app-assisted review screen required before manual save.

Report Back:
- Did manual mode feel simpler?
- Could you still view the proof later?

## Flow 6: PDF Receipt Import

Purpose:
- Prove PDF receipts are handled safely.

Steps:
1. Start a receipt expense.
2. Import a normal PDF receipt.
3. Import or test a PDF that has little or no readable text.
4. Import a long PDF if available.
5. Continue through receipt review or proof-only handling.

Expected:
- Readable PDFs can fill the receipt review.
- Unreadable PDFs stay attached as read-only proof.
- Long PDFs are bounded by device-safe page limits.
- The user is told when only part of a PDF is read.

Must Never Happen:
- No crash on unreadable PDFs.
- No blocking a save just because PDF text cannot be read.
- No treating a suspicious PDF as editable content.

Report Back:
- Did the PDF read into the form?
- Did proof-only language make sense?
- Did the full PDF remain viewable as proof?

## Flow 7: Interruption And Recovery

Purpose:
- Prove drafts and proof files survive normal phone behavior.

Steps:
1. Start a receipt expense.
2. Attach a receipt photo.
3. Leave the app before saving.
4. Return to Maintainiac.
5. Confirm the draft still has the proof.
6. Save the expense.
7. Reopen from the calendar/day view.
8. Edit the expense and confirm proof remains attached.

Expected:
- Draft proof is recoverable.
- Save promotes staged proof into permanent proof storage.
- Calendar recovery opens the correct saved receipt.
- Editing does not drop the proof.

Must Never Happen:
- No orphan proof loss.
- No duplicate attachment confusion.
- No wrong-day calendar save when the receipt date is edited.

Report Back:
- Did the draft survive leaving the app?
- Did calendar/day recovery open the correct expense?

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
- Long receipt multi-photo flow either stitches correctly or falls back safely.
- App-assisted review opens after photo acceptance.
- Business/personal/mixed classification works.
- Save-space preview is understandable and does not affect OCR source quality.
- PDF import is bounded and proof-safe.
- Draft recovery survives app interruption.
