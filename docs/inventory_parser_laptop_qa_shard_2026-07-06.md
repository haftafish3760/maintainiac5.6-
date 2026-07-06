# Inventory Parser Laptop QA Shard - 2026-07-06

Issued: 2026-07-06 14:06 EDT

This handoff is for a second Windows machine to run Maintainiac inventory/parser
QA without editing source code or touching unrelated app areas.

## Scope

- Repo: `C:\Users\rjenk\Documents\Mainteniac 5.6`
- Branch: `codex/inventory-parser-backup-20260702-2056`
- Area: inventory/parser QA only
- Do not touch: OCR, camera, expenses, UI, PDF, sync, invoices, estimates, jobs,
  maintenance, or unrelated modules
- Do not edit source unless a real parser/QA failure is confirmed and the main
  thread tells you to fix it
- Do not use live Firebase, Cloud Storage, production catalog writes, or network
  services

## Authority And Guardrails

The human owner chooses what this laptop machine does. The laptop Codex model
does not choose its own next shard, roadmap item, cleanup task, refactor, or
feature work.

Hard rules:

- Run only the shard named in this document.
- Treat app source as read-only unless the human owner explicitly approves a
  specific fix after a real failure is reported.
- Do not start Core, Professional, Complete, Expenses, OCR, Camera, UI, PDF,
  sync, Firebase, or any unrelated QA.
- Do not run a second shard after this one finishes.
- Do not broaden the command to more tiers, more trades, more locales, or a
  higher fixture count.
- Do not change parser thresholds, confidence caps, catalog data, aliases,
  fixtures, tests, or harness code just to make a run pass.
- Do not delete build artifacts from the desktop or laptop unless the human
  owner says to do it.
- Do not commit or push unrelated files.
- Do not use `git reset --hard`, `git checkout --`, destructive cleanup, or
  force-push.
- If another machine is already running the same wave id or same
  trade/scope/tier/locale cells, stop and report possible duplicate work.

Allowed actions:

- Pull/fetch the branch.
- Run the exact command in this document.
- Inspect the final status, summary, generated fixture reports, and transcripts.
- Run the evidence gate command in this document.
- Commit and push only the small evidence artifacts and progress note if the
  shard passes.
- Report failures with exact paths and case ids if the shard fails.

Stop immediately and report back if:

- Any cell fails.
- Any cell is unsafe.
- Any report shows live services, production catalog writes, Firebase writes,
  OCR/camera/expenses touched, missing safety fields, timed-out chunks, or
  non-zero chunk exits.
- The command path does not exist.
- The branch is not `codex/inventory-parser-backup-20260702-2056`.
- The repo has unexpected source changes before starting.
- The laptop model is tempted to do anything outside this document.

## Machine Assignment

Use the laptop for one Standard residential PEH shard while the desktop
continues Core escalation. This is intentionally a limited assignment, not the
whole remaining QA roadmap.

The laptop shard is:

- Trades: Plumbing, Electrical, HVAC
- Scope: Residential
- Tier: Standard
- Locales: `en-US`, `es-US`
- Fixture limit: 5 cases per cell first
- Expected cells: 6
- Expected parser calls if complete: 30

This intentionally does not overlap the desktop Core wave.

## First Command

Run from the repo root:

```powershell
cd "C:\Users\rjenk\Documents\Mainteniac 5.6"
New-Item -ItemType Directory -Force -Path build\parser_qa_batch_waves | Out-Null
dart run tool\work_supply_parser_qa_batch_wave.dart `
  --execute `
  --wave-id laptop-2026-07-06-peh-standard-baby-5 `
  --qa-layer laptop-generated-fixture-standard-baby-5 `
  --trades plumbing,electrical,hvac `
  --tiers standard `
  --locales en-US,es-US `
  --limit 60 `
  --fixture-run-limit 5 `
  --fixture-run-timeout-ms 900000 `
  --fixture-run-stale-report-timeout-ms 300000 `
  --output-root build\parser_qa_batch_waves *> build\parser_qa_batch_waves\laptop_2026-07-06_standard_baby_5_transcript.txt
```

Do not watch the transcript continuously. Let it finish, then inspect summaries.

## Status Check

```powershell
$status = "build\parser_qa_batch_waves\laptop-2026-07-06-peh-standard-baby-5\queue\latest_status.json"
if (Test-Path $status) {
  $s = Get-Content $status -Raw | ConvertFrom-Json
  "STATE=$($s.state) CELLS=$($s.cellCount) COMPLETED=$($s.completedCellCount) FAILED=$($s.failedCellCount) ACTIVE=$($s.activeCellId) UPDATED=$($s.updatedAtIso)"
}
```

## Evidence Gate

After the wave finishes, run:

```powershell
dart run tool\work_supply_parser_qa_generated_run_status.dart `
  --report-root build\parser_qa_batch_waves\laptop-2026-07-06-peh-standard-baby-5\queue\laptop_2026_07_06_peh_standard_baby_5_laptop_generated_fixture_standard_baby_5\cells `
  --trades plumbing,electrical,hvac `
  --scopes residential `
  --tiers standard `
  --locales en-US,es-US `
  --require-complete `
  --min-checked-per-cell 5 `
  --output build\parser_qa_batch_waves\laptop-2026-07-06-peh-standard-baby-5\generated_run_status.json
```

Passing evidence must show:

- `expectedCells: 6`
- `presentCells: 6`
- `missingCells: 0`
- `failedCells: 0`
- `unsafeCells: 0`
- `underMinCheckedCells: 0`
- `checkedTotal: 30`
- `parserCalls: 30`
- all local-only safety flags false

## If It Passes

Commit only the small evidence artifacts and progress note. Do not commit noisy
transcripts unless specifically asked.

Recommended commit label format:

```text
QA testing 2026-07-06 HHMM EDT: laptop PEH Standard baby-5 evidence
```

Then stop and report the evidence back to the main inventory/parser QA thread.
Do not automatically continue into larger shards.

## If It Fails

Stop the shard and report:

- failed cell id
- fixture line/case id
- expected item/category/review status
- actual parser output
- report path
- transcript path

Do not start another heavy run until the failure is understood.

## Do Not Continue Past This Shard

After baby-5 passes or fails, stop. The next shard will be assigned separately
after the main thread reviews the evidence.
