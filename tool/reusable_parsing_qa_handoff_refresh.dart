import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/reusable_parsing_qa_handoff_refresh.dart '
    '[--root .] '
    '[--branch <auto-from-git>] '
    '[--commit <auto-from-git>] '
    '[--commit-full <auto-from-git>] '
    '[--label <commit label>] '
    '[--updated-at "YYYY-MM-DD HH:MM EDT"]';

Future<void> main(List<String> args) async {
  final exit = runReusableParsingQaHandoffRefresh(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runReusableParsingQaHandoffRefresh(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }

  final root = _value(args, 'root', '.');
  final docsDir = Directory(root).uri.resolve('docs/');
  final packetFile = File.fromUri(
    docsDir.resolve('reusable_parsing_qa_mac_handoff_packet.json'),
  );
  if (!packetFile.existsSync()) {
    stderr.writeln(
      'Expected packet file at ${packetFile.path} before refreshing handoff docs.',
    );
    return 66;
  }

  final branch =
      _optionalValue(args, 'branch') ??
      _gitValue(['rev-parse', '--abbrev-ref', 'HEAD'], root) ??
      'unknown-branch';
  final commit =
      _optionalValue(args, 'commit') ??
      _gitValue(['rev-parse', '--short', 'HEAD'], root) ??
      'unknown-commit';
  final commitFull =
      _optionalValue(args, 'commit-full') ??
      _gitValue(['rev-parse', 'HEAD'], root) ??
      commit;
  final updatedAt = _optionalValue(args, 'updated-at') ?? _nowEdtLabel();
  final label =
      _optionalValue(args, 'label') ??
      'Reusable parsing QA $updatedAt: refresh handoff artifacts';

  final packet =
      jsonDecode(packetFile.readAsStringSync()) as Map<String, Object?>;
  packet['primaryBranch'] = branch;
  packet['baselineCommit'] = commit;
  packet['baselineCommitFull'] = commitFull;
  packet['baselineCommitLabel'] = label;
  packet['generatedAtEdt'] = updatedAt;

  packetFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(packet),
    flush: true,
  );

  final markerFile = File.fromUri(
    docsDir.resolve('reusable_parsing_qa_handoff_marker.md'),
  );
  markerFile.writeAsStringSync(
    _markerContents(
      updatedAt: updatedAt,
      branch: branch,
      commit: commit,
      label: label,
    ),
    flush: true,
  );

  final boundaryFile = File.fromUri(
    docsDir.resolve('reusable_parsing_qa_scope_boundary.md'),
  );
  boundaryFile.writeAsStringSync(
    _boundaryContents(
      updatedAt: updatedAt,
      branch: branch,
      commit: commit,
    ),
    flush: true,
  );

  final runbookFile = File.fromUri(
    docsDir.resolve('reusable_parsing_qa_mac_runbook.md'),
  );
  runbookFile.writeAsStringSync(
    _runbookContents(
      updatedAt: updatedAt,
      branch: branch,
      commit: commit,
      boundaryPath: 'docs/reusable_parsing_qa_scope_boundary.md',
    ),
    flush: true,
  );

  final indexFile = File.fromUri(
    docsDir.resolve('reusable_parsing_qa_handoff_index.md'),
  );
  indexFile.writeAsStringSync(
    _indexContents(
      updatedAt: updatedAt,
      branch: branch,
      commit: commit,
      label: label,
      boundaryPath: 'docs/reusable_parsing_qa_scope_boundary.md',
    ),
    flush: true,
  );

  packet['scopeBoundaryPath'] = 'docs/reusable_parsing_qa_scope_boundary.md';
  packet['checkpointJsonPath'] = 'docs/reusable_parsing_qa_checkpoint.json';
  packet['checkpointMarkdownPath'] = 'docs/reusable_parsing_qa_checkpoint.md';
  packet['windowsCheckpointSyncCommand'] =
      'dart run tool/reusable_parsing_qa_handoff_sync.dart '
      '--root . '
      '--branch $branch '
      '--commit $commit '
      '--commit-full $commitFull '
      '--label "$label" '
      '--updated-at "$updatedAt"';
  packet['reusableFoundationPaths'] = [
    'test/support/parser_qa_platform/',
    'test/support/qa_harness/',
    'tool/reusable_parsing_qa_handoff_refresh.dart',
    'tool/reusable_parsing_qa_handoff_sync.dart',
    'tool/reusable_parsing_qa_handoff_status.dart',
    'docs/reusable_parsing_qa_handoff_index.md',
    'docs/reusable_parsing_qa_handoff_marker.md',
    'docs/reusable_parsing_qa_scope_boundary.md',
    'docs/reusable_parsing_qa_mac_runbook.md',
    'docs/reusable_parsing_qa_mac_handoff_packet.json',
  ];
  packet['inventorySpecificWindowsPaths'] = [
    'lib/screens/work_supplies/data/work_supply_receipt_parser.dart',
    'test/support/work_supply_parser_qa/',
    'docs/inventory_parser_peh_core_roadmap.md',
    'build/parser_qa_pipeline/peh_core_windows_status_rollup.json',
    'build/parser_qa_pipeline/peh_core_measurement_gap.json',
    'build/parser_qa_pipeline/peh_core_handoff_readiness.json',
  ];
  packet['macMiniExpectedOutputs'] = [
    'build/parser_qa_pipeline/mac_electrical_core_generated_run_status_25.json',
    'build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json',
    'build/parser_qa_pipeline/peh_core_mac_wave_status.json',
    'build/parser_qa_pipeline/peh_core_merged_status_rollup.json',
    'build/parser_qa_pipeline/peh_core_claim_readiness.json',
  ];

  packetFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(packet),
    flush: true,
  );

  stdout.writeln(
    'QA_REUSABLE_PARSING_HANDOFF_REFRESH '
    '${jsonEncode({
      'branch': branch,
      'commit': commit,
      'commitFull': commitFull,
      'label': label,
      'updatedAt': updatedAt,
      'markerPath': markerFile.path,
      'boundaryPath': boundaryFile.path,
      'packetPath': packetFile.path,
      'runbookPath': runbookFile.path,
      'indexPath': indexFile.path,
    })}',
  );
  return 0;
}

String _markerContents({
  required String updatedAt,
  required String branch,
  required String commit,
  required String label,
}) {
  return '''# Reusable Parsing QA Handoff Marker

Last updated: $updatedAt

Purpose: prevent duplicate work between the Windows parser/QA lane and the Mac
Mini lane.

## Git Marker

- Primary reusable branch: `$branch`
- Current Windows working branch: `codex/inventory-parser-backup-20260702-2056`
- Validated floor commit: `$commit`
- Commit label:
  `$label`

The Mac Mini side should start from branch `$branch`.
Treat the branch tip as authoritative.
Treat commit `$commit` as the last Windows-validated floor, not as a promise
that the handoff docs already describe their own just-created commit.

Companion machine-readable packet:
`docs/reusable_parsing_qa_mac_handoff_packet.json`

Companion scope boundary map:
`docs/reusable_parsing_qa_scope_boundary.md`

Companion next-action checkpoint:
`docs/reusable_parsing_qa_checkpoint.md`

Companion plain-English runbook:
`docs/reusable_parsing_qa_mac_runbook.md`

## Handoff Rule

When the Mac Mini lane starts, this file is the first thing it should read.
If chat instructions and this file disagree, this file wins until a newer
committed handoff marker replaces it.

The explicit reusable-versus-inventory ownership split lives in
`docs/reusable_parsing_qa_scope_boundary.md`.
The current Windows-next versus Mac-next checkpoint lives in
`docs/reusable_parsing_qa_checkpoint.md`.
Windows should refresh the full handoff stack with
`dart run tool/reusable_parsing_qa_handoff_sync.dart ...` instead of running
separate refresh and checkpoint commands by hand.

## Completed On Windows

These pieces are already done enough that the Mac Mini side should treat them
as the current baseline, not rebuild them from scratch:

- Shared parser QA platform backbone already exists in
  `test/support/parser_qa_platform/`.
- Reusable reporting/gating artifacts already exist for parser QA platform
  status, duration, failure digest, watchdog, release readiness, and exports.
- Inventory parser adapter already proves reusable parser-platform behavior is
  not strictly inventory-locked.
- Mixed-trade PEH ambiguity hardening has already been added for overlapping
  PVC and copper receipt language.
- Estimate-section and invoice-section routing rules already exist as
  review-only ranking boosts, not silent confirmation.
- HVAC-specific fixes already landed for thermostat wire vs thermostat and
  humidifier water-panel wording.

## Files Touched In The Current Reusable Baseline

- `docs/inventory_parser_peh_core_roadmap.md`
- `docs/materials_catalog_intelligence_contract.md`
- `lib/screens/work_supplies/data/work_supply_receipt_parser.dart`
- `test/support/work_supply_parser_qa/work_supply_parser_context_qa.dart`
- `test/support/work_supply_parser_qa/work_supply_parser_estimate_section_qa.dart`
- `test/work_supply_hvac_receipt_parser_test.dart`
- `test/work_supply_parser_regression_lock_behavior_test.dart`

## Mac Mini Should Pick Up Here

The Mac Mini lane should continue from the reusable baseline above and focus on
work that benefits from heavier validation or broader parser-domain reuse:

1. Run heavier generated-fixture and mixed-trade measurement waves from the
   reusable baseline instead of rebuilding the same Windows-side ambiguity work.
2. Continue extracting receipt-interpretation behavior that is truly generic to
   parsing in general, not only Work Supplies inventory.
3. Reuse shared parser-platform pieces for future parser domains such as fuel,
   maintenance, invoice/estimate import, and other text-to-structured-data
   flows.
4. Use the machine-readable packet for the exact current Mac-side command order
   instead of copying commands out of old chat or stale artifacts.

## Do Not Duplicate On Mac Mini

Do not spend Mac Mini passes redoing these Windows-complete tasks unless a new
regression proves they are wrong:

- Re-adding the same mixed-trade PVC/copper ambiguity regressions.
- Re-documenting estimate/invoice section routing as review-only.
- Re-fixing thermostat-wire and water-panel HVAC cases.
- Re-creating the reusable parser QA branch label.

## Windows Still Owns

Until a later handoff says otherwise, the Windows lane still owns:

- Ongoing Work Supplies parser/code edits in this thread.
- Inventory-specific PEH parser hardening before broader parser-domain
  extraction is declared complete.
- The current local progress memory and Windows-side roadmap updates.

## Mac Mini Safe Starting Instruction

Start from branch `$branch`, confirm it is at or after validated floor commit
`$commit`, read this marker first, then continue only with heavier validation,
broader reusable parsing-core extraction, or new parser-domain consumers that
are not already listed as Windows-complete above.
''';
}

String _runbookContents({
  required String updatedAt,
  required String branch,
  required String commit,
  required String boundaryPath,
}) {
  return '''# Reusable Parsing QA Mac Mini Runbook

Last updated: $updatedAt

This runbook is the plain-English companion to:

- `docs/reusable_parsing_qa_handoff_marker.md`
- `$boundaryPath`
- `docs/reusable_parsing_qa_checkpoint.md`
- `docs/reusable_parsing_qa_mac_handoff_packet.json`

## Start Here

1. Check out branch `$branch`.
2. Confirm the branch is at or after validated floor commit `$commit`.
3. Read `docs/reusable_parsing_qa_handoff_marker.md` before running anything.
4. Read `$boundaryPath` to separate reusable parser QA work from
   inventory-specific Windows ownership.
5. Read `docs/reusable_parsing_qa_checkpoint.md` to see the current
   Windows-next versus Mac-next checkpoint from live PEH evidence.
6. Use `docs/reusable_parsing_qa_mac_handoff_packet.json` as the exact command
   source of truth.

## What Windows Already Finished

Do not rebuild these unless a new regression proves they are wrong:

- Shared parser QA platform backbone in `test/support/parser_qa_platform/`
- Reusable parser QA reporting and gating artifacts
- Mixed-trade PEH ambiguity hardening for overlapping PVC and copper wording
- Review-only estimate/invoice section routing boosts
- HVAC thermostat-wire versus thermostat hardening
- HVAC humidifier water-panel wording hardening

## What The Mac Mini Should Do Next

1. Run the heavier PEH generated-fixture measurement wave from the reusable
   parsing baseline.
2. Roll up the Electrical and HVAC Mac wave results.
3. Refresh the PEH status stack after the Mac wave outputs exist.
4. Continue broader reusable receipt/parsing-core extraction only after the
   current PEH measurement lane is advanced from this checkpoint.

## Current Measurement Reality

- Plumbing already has the stronger Windows-side generated evidence.
- Electrical already has the current Windows-side sample-sized proof.
- HVAC is the remaining top measured gap from the current PEH artifacts.
- The branch is ready for a Mac measurement wave.
- The branch is not yet ready for a `90-95%` claim across PEH.

## Do Not Duplicate

- Do not re-add the same mixed-trade PEH ambiguity regressions.
- Do not re-document review-only estimate/invoice routing.
- Do not re-fix thermostat wire versus thermostat behavior.
- Do not re-fix humidifier water-panel wording.
- Do not recreate branch labeling or older handoff artifacts.

## Expected Mac Outputs

The current packet expects these outputs to exist after the Mac wave:

- `build/parser_qa_pipeline/mac_electrical_core_generated_run_status_25.json`
- `build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json`
- `build/parser_qa_pipeline/peh_core_mac_wave_status.json`
- `build/parser_qa_pipeline/peh_core_merged_status_rollup.json`
- `build/parser_qa_pipeline/peh_core_claim_readiness.json`

## Ownership Boundary

The Windows lane still owns:

- Ongoing Work Supplies parser/code edits in this thread
- Inventory-specific PEH hardening before broader parser-domain extraction is
  declared complete
- Windows-side roadmap and progress-memory maintenance

The Mac Mini lane should focus on:

- Heavier generated-fixture measurement work
- Mac-side rollups and refresh
- Broader reusable parser-domain follow-through after the current PEH handoff
  step
''';
}

String _indexContents({
  required String updatedAt,
  required String branch,
  required String commit,
  required String label,
  required String boundaryPath,
}) {
  return '''# Reusable Parsing QA Handoff Index

Last updated: $updatedAt

This is the single first file the Mac Mini side should open.

Current baseline:

- Branch: `$branch`
- Validated floor commit: `$commit`
- Commit label:
  `$label`

Open these in order:

1. `docs/reusable_parsing_qa_handoff_marker.md`
2. `$boundaryPath`
3. `docs/reusable_parsing_qa_checkpoint.md`
4. `docs/reusable_parsing_qa_mac_runbook.md`
5. `docs/reusable_parsing_qa_mac_handoff_packet.json`

What this means:

- The marker is the top human-readable boundary and ownership file.
- The scope boundary file is the explicit reusable-versus-inventory split.
- The checkpoint file is the current Windows-next versus Mac-next state.
- The runbook is the plain-English execution sequence.
- The packet is the machine-readable source of exact Mac-side commands.
- The branch tip is authoritative; the listed commit is the last Windows-validated floor.

Do not trust older chat instructions over these committed files.
''';
}

String _boundaryContents({
  required String updatedAt,
  required String branch,
  required String commit,
}) {
  return '''# Reusable Parsing QA Scope Boundary

Last updated: $updatedAt

This file is the explicit boundary between reusable parser QA foundation work
and inventory-specific Windows work.

Validated floor:

- Branch: `$branch`
- Validated floor commit: `$commit`

## Reusable Parser QA Foundation

These artifacts are intended to stay reusable across parser domains and can be
consumed by the Mac Mini lane without rebuilding them from scratch:

- `test/support/parser_qa_platform/`
- `test/support/qa_harness/`
- `tool/reusable_parsing_qa_handoff_refresh.dart`
- `tool/reusable_parsing_qa_handoff_status.dart`
- `docs/reusable_parsing_qa_handoff_index.md`
- `docs/reusable_parsing_qa_handoff_marker.md`
- `docs/reusable_parsing_qa_scope_boundary.md`
- `docs/reusable_parsing_qa_mac_runbook.md`
- `docs/reusable_parsing_qa_mac_handoff_packet.json`

## Inventory-Specific Windows Ownership

These artifacts are still owned by the current Windows-side Work Supplies
inventory/parser lane and should not be re-authored on the Mac Mini unless a
new regression or handoff explicitly says otherwise:

- `lib/screens/work_supplies/data/work_supply_receipt_parser.dart`
- `test/support/work_supply_parser_qa/`
- `docs/inventory_parser_peh_core_roadmap.md`
- `build/parser_qa_pipeline/peh_core_windows_status_rollup.json`
- `build/parser_qa_pipeline/peh_core_measurement_gap.json`
- `build/parser_qa_pipeline/peh_core_handoff_readiness.json`

## Mac Mini Measurement Outputs

The Mac Mini lane is expected to produce or refresh these heavier validation
artifacts from the reusable baseline:

- `build/parser_qa_pipeline/mac_electrical_core_generated_run_status_25.json`
- `build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json`
- `build/parser_qa_pipeline/peh_core_mac_wave_status.json`
- `build/parser_qa_pipeline/peh_core_merged_status_rollup.json`
- `build/parser_qa_pipeline/peh_core_claim_readiness.json`

## Rule

If a task changes reusable parser QA infrastructure, handoff boundary files, or
shared parser-platform behavior, it belongs in the reusable lane.

If a task changes Work Supplies parser behavior, PEH inventory-specific hardening,
or Windows-owned roadmap/progress state, it stays in the Windows lane until a
new committed handoff explicitly promotes it.
''';
}

String _value(List<String> args, String key, String fallback) {
  return _optionalValue(args, key) ?? fallback;
}

String? _optionalValue(List<String> args, String key) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return null;
}

String? _gitValue(List<String> command, String root) {
  final result = Process.runSync(
    'git',
    command,
    workingDirectory: root,
  );
  if (result.exitCode != 0) return null;
  return result.stdout.toString().trim();
}

String _nowEdtLabel() {
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)} '
      '${two(now.hour)}:${two(now.minute)} EDT';
}
