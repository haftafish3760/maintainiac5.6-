# Independent Expense Completion Roadmap

This roadmap covers the independent-user Expense lane only. It intentionally
does not implement fuel interpretation, inventory interpretation, long-receipt
stitching, taxes, accounting, payroll, or fleet workflows.

## Completion rule

An item is complete only when its local behavior works, its saved data round
trips without loss, focused regression tests pass, and its UI does not pretend
that a future backend exists.

## 1. Durable local expense records

Status: in progress, final validation pending.

- Save every receipt locally before any optional backup.
- Preserve expense date, created time, last-modified time, proof attachment,
  original OCR text, editable display text, and source evidence.
- Store money as whole cents in persisted records and recap aggregation.
- Keep staged proof files until the saved draft points to the permanent copy.
- Prevent duplicate save and duplicate receipt-photo read work.

Acceptance: killing the app during receipt save leaves a recoverable draft;
saved cents reconcile exactly in day, range, and category totals.

## 2. Receipt capture to editable receipt form

Status: in progress.

- Accept camera, gallery, file, and supported text imports.
- Preserve the accepted photo and open the receipt-details state immediately.
- Show plain-language numbered progress while the app prepares and reads text.
- Use OCR coordinates and confidence to fill merchant, date, totals, and
  editable receipt lines without replacing printed wording.
- Keep manual entry available after unreadable, empty, or timed-out OCR.
- Route structured evidence to the fuel or inventory parser only; do not
  interpret their business meaning here.

Acceptance: a readable short receipt produces editable fields and line evidence;
a bad image leaves the proof intact and gives a usable manual recovery path.

## 3. Classification, categories, and allocations

Status: existing line controls need end-to-end validation.

- Receipt mode: Basic (receipt total), Simple (one selected category), or
  Detailed (printed lines).
- Each saved line owns its category and business/personal/split state.
- The initially selected category is a starting value, never a hidden override.
- Mixed receipts allow a category and allocation for each line.
- Block saving unresolved splits or allocations that do not reconcile to cents.
- Category recaps use the saved line category, including receipts entered for
  an earlier date.

Acceptance: selecting a category records money in that exact category; a mixed
receipt can allocate different lines without changing their printed text.

## 4. Independent work, vehicle, and job context

Status: not started; Jobs UI is currently demo-only and must not be falsely wired.

- Add real local stores for work profiles and vehicle profiles.
- Keep a default profile for people who never want to manage profiles.
- Save an explicit context snapshot on each expense: work profile, vehicle, and
  optional job reference.
- Support historical entry: choose the correct context when a past-date receipt
  cannot be inferred from a saved default.
- Implement a real Job record source before exposing Job selection in Expenses.
- Link a confirmed job expense by stable ID; do not mutate an estimate,
  inventory, fuel record, or job total directly from OCR.

Acceptance: switching vehicle/profile changes only future defaults; old entries
remain attached to their original context; a real job can show linked expense
evidence without double counting it.

## 5. Recaps and calendar behavior

Status: base ledger summaries exist; profile/job scopes and user date settings remain.

- Base every recap on `receiptDate`, not date entered or date synced.
- Provide Past 7 days, Past 30 days, Past 90 days, year-to-date, custom range,
  and a user-configured current-week start day.
- Show category, work-profile, vehicle, job, and all-profiles scopes clearly.
- Keep business/personal allocations separate from total spend.
- Make active scope visible in every category and recap screen.

Acceptance: a three-year-old receipt appears on its historical calendar date and
only in the selected profile/vehicle/job recap scope.

## 6. Receipt storage controls

Status: local device storage facts and local saved-copy choices exist; sync policy remains.

- Never delete user gallery photos or unrelated device files.
- Retain original proof until a derived copy and any chosen cloud upload verify.
- Offer retained local copy choices: original, readable, balanced, compact, or
  minimal, with a clear explanation of what each does.
- Warn from actual device free space and reserve enough temporary space for OCR.
- Show cloud storage only from real account entitlement data, never placeholders.

Acceptance: full or low-storage devices fail safely, retain user data, and offer
manual recovery rather than silently losing a receipt.

## 7. Optional Firebase backup and sync

Status: not started; requires a configured Firebase project and user-account contract.

- Local save is always first and succeeds offline.
- User chooses manual sync, automatic sync, Wi-Fi only, or Wi-Fi plus cellular.
- Queue changes locally with idempotent IDs, retry/backoff, conflict metadata,
  and verified upload before any optional local-copy cleanup.
- Display real sync state, cloud quota, and entitlement from the account; keep
  limits configurable server-side rather than hardcoding a launch promotion.
- Do not ship cloud OCR until explicit consent, provider credentials, budget
  controls, and retention rules exist.

Acceptance: an offline expense survives restart, syncs exactly once when allowed,
and one user cannot observe or overwrite another user's records.

## 8. Firebase rules, release validation, and security review

Status: deferred until the prior packages are implemented.

- Test Firebase rules in emulators using authenticated owner and non-owner cases.
- Validate local migration, sync retry, quota denial, attachment upload failure,
  and account deletion/export paths.
- Run focused security review for Expenses and Firebase after the implementation
  surface is stable; do not burn a repository-wide scan while the feature is
  still changing.
- Run focused widget/unit/regression tests and one device build at a time.

Acceptance: no Expense or receipt path depends on fake cloud state, and release
checks demonstrate local recovery, scope isolation, exact money totals, and
user-visible failure handling.
