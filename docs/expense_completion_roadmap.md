# Maintainiac Independent Expense System Completion Charter

This is the end-to-end completion charter for Maintainiac's Expense
application: everything reached from the bottom Expense navigation button. It
must serve an independent user, a small company, and a commercial fleet from
two employees through materially larger teams without requiring a separate
Expense product. It is not a local-records-only task and it is not complete
until the working Expense experience, its local-first data, receipt/OCR flow,
categories, context, recaps, user-controlled backup/sync, Firebase transport,
Firebase rules, permissions, and release validation work together.

Fuel interpretation, inventory interpretation, long-receipt stitching, taxes,
accounting, and payroll remain separate owned systems. Fleet Expense workflows
are part of this charter: they must use the same dependable local-first and
cloud-backed expense model while enforcing organization and employee
permissions. The Expense system must integrate with other owned systems through
their published contracts without rebuilding or taking ownership of their
internal logic.

## Completion rule

An item is complete only when its local behavior works, its saved data round
trips without loss, its Firebase-backed behavior works where promised, focused
regression tests pass, and its UI does not pretend that a future backend exists.

## System-wide completion gates

The independent Expense system is not complete until every gate below has
working code, durable data, and focused regression coverage.

1. **Expense lifecycle** — create, draft, resume, edit, duplicate prevention,
   delete, restore/recovery where supported, and history/audit timestamps.
2. **Truthful receipt evidence** — preserve source photo/proof, OCR wording,
   source coordinates, confidence, user edits, and the original source after
   edits. OCR must never silently rewrite the printed receipt.
3. **Receipt modes** — Basic, Simple, and Detailed review modes must save the
   appropriate level of user-reviewed structure from the same source evidence.
4. **Receipt form fill** — a readable receipt must populate editable merchant,
   date, subtotal, tax, total, and lines when evidence supports them; an
   unreadable receipt must retain proof and continue manually without loss.
5. **Categories** — every Expense category, including job-related expenses,
   must save to the selected category and appear in that category's recap.
6. **Mixed receipts and allocation** — each receipt line can have its own
   category and Business, Personal, Split, or Unclassified status. Split cents
   must reconcile exactly and cannot silently use an unconfirmed 50% default.
7. **Independent context** — expenses retain the original work-profile,
   vehicle, and optional job context. Later profile/vehicle changes never
   rewrite historic records.
8. **Job linkage** — a confirmed job can show its linked expenses by stable
   job ID. Receipt/OCR never mutates an estimate, job total, inventory, or fuel
   record directly. A real Job store must replace the current demo Jobs UI
   before job selection is exposed to users.
9. **Recap correctness** — every add, edit, delete, restore, or context change
   immediately yields correct total, business, personal, category, profile,
   vehicle, job, calendar-day, Past 7/30/90, year-to-date, custom-range, and
   configured-week recaps. Receipt date is the expense date; created and
   modified timestamps remain separately visible to the data layer.
10. **Calendar and backdating** — entering a receipt from any past date puts it
    on that date and in the correct historical category/context recap.
11. **Local-first storage** — save locally before any queue/upload, preserve
    staged proof until durable checkpoint, never delete gallery photos or
    unrelated user files, and handle low device storage without silent loss.
12. **User-controlled backup** — expose truthful settings for manual sync,
    Wi-Fi-only, Wi-Fi/cellular, receipt-copy retention, quota/entitlement,
    offline queue state, retry, and verified-upload-only cleanup.
13. **Firebase integration** — authenticated account identity, Firestore
    document writes, Storage uploads, idempotent queued sync, conflict/retry
    behavior, quota enforcement, Firebase emulators, and owner-only rules.
    No screen may claim a cloud backup succeeded until the remote write and
    required proof upload have both verified.
14. **Security and privacy** — user/tenant isolation, least-privilege rules,
    opt-in diagnostics, no raw OCR/local paths in telemetry or backup metadata,
    account/export/deletion behavior, and focused security validation.
15. **Optional AI assist** — only after the fully manual and deterministic
    flow works. It must be explicit opt-in, disclose remote processing, retain
    original receipt text/evidence, return suggestions rather than decisions,
    respect budget/rate limits, and never bypass user review or local fallback.
16. **Fleet scale and permissions** — the same Expense app must support an
    owner with multiple employees and vehicles, company-wide plus per-employee,
    per-vehicle, and per-job views, role-based visibility/edit permissions,
    conflict-safe sync, and recap scopes that remain accurate at fleet scale.
17. **Employee payment recording only** — an authorized owner can record an
    employee-payment expense with amount, date, recipient, category, proof,
    and notes. This is record-keeping only: no withholding, tax calculation,
    pay-rate calculation, timesheet-to-payroll conversion, payroll filing, or
    payroll advice belongs in Maintainiac.

## Required delivery order

This order prevents a receipt, recap, or category from attaching to a fake or
unfinished target. Work continues through these packages without treating a
package boundary as the end of the Expense assignment.

1. **Independent profile foundation** — durable default work and vehicle
   context; create, edit, archive, select, and restore profile records; a user
   who never configures profiles continues safely on defaults.
2. **Independent Job expense foundation** — replace the demo Job screen with a
   durable Job record and an Expense-facing job reference/list. Expenses can
   attach to a completed Job record; neither system duplicates the other's
   totals or business logic.
3. **Universal Expense attachment contract** — categories, repairs,
   maintenance, employee payments, jobs, vehicles, and work profiles all use
   the same Expense record and audit/recovery path. Category-specific systems
   may add metadata but do not create shadow expense ledgers.
4. **Receipt/OCR to editable Expense review** — complete camera/import,
   quality/recovery, faithful extraction, form fill, Basic/Simple/Detailed
   modes, category allocation, split validation, and parser handoff.
5. **Accurate recaps and calendar** — category, context, job, Business/
   Personal, date-range, and all-profile recaps recompute after every create,
   edit, delete, restore, or reassignment.
6. **Storage and local-first safety** — immediate durable local checkpoints,
   app-managed proof retention choices, low-storage recovery, and no access to
   unrelated device files.
7. **User-controlled cloud backup/sync** — manual/scheduled preferences,
   free/paid entitlement configuration, offline queue, retry, verified upload,
   and local-copy cleanup only under the user's selected retention policy.
8. **Firebase completion** — authenticated account wiring, Firestore/Storage
   transport, Firebase emulator/rules coverage, tenant isolation, quota and
   cost controls, conflict behavior, and recovery from remote failure.
9. **Fleet extension** — after the independent lane passes its full integrated
   validation, add organization/employee context, permissions, team/vehicle/job
   recap scopes, and fleet-scale sync without changing the core Expense record.
10. **Release gate** — run integrated regression, device validation, emulator
    rules validation, focused security review, and documented recovery tests.

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
