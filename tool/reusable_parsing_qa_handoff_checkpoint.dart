import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/reusable_parsing_qa_handoff_checkpoint.dart '
    '[--root .]';

Future<void> main(List<String> args) async {
  final exit = runReusableParsingQaHandoffCheckpoint(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runReusableParsingQaHandoffCheckpoint(
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
  final buildDir = Directory(root).uri.resolve('build/parser_qa_pipeline/');

  final packetFile = File.fromUri(
    docsDir.resolve('reusable_parsing_qa_mac_handoff_packet.json'),
  );
  final readinessFile = File.fromUri(
    buildDir.resolve('peh_core_handoff_readiness.json'),
  );
  final gapFile = File.fromUri(
    buildDir.resolve('peh_core_measurement_gap.json'),
  );
  final rollupFile = File.fromUri(
    buildDir.resolve('peh_core_windows_status_rollup.json'),
  );

  final missing = <String>[
    if (!packetFile.existsSync()) packetFile.path,
    if (!readinessFile.existsSync()) readinessFile.path,
    if (!gapFile.existsSync()) gapFile.path,
    if (!rollupFile.existsSync()) rollupFile.path,
  ];
  if (missing.isNotEmpty) {
    stderr.writeln('Missing checkpoint inputs: ${missing.join(', ')}');
    return 66;
  }

  final packet =
      jsonDecode(packetFile.readAsStringSync()) as Map<String, Object?>;
  final readiness =
      jsonDecode(readinessFile.readAsStringSync()) as Map<String, Object?>;
  final gap = jsonDecode(gapFile.readAsStringSync()) as Map<String, Object?>;
  final rollup =
      jsonDecode(rollupFile.readAsStringSync()) as Map<String, Object?>;
  final liveExecutionPacket = _readOptionalJson(
    '$root${Platform.pathSeparator}build${Platform.pathSeparator}parser_qa_pipeline${Platform.pathSeparator}peh_core_mac_handoff_packet.json',
  );

  final nextTrades = _stringList(gap['nextTradesByRemainingGap']);
  final readinessActions = _stringList(readiness['nextActions']);
  final macMiniNextCommands = _commandLists(packet['macMiniNextCommands']);
  final hasPostMacRefresh = macMiniNextCommands.any(
    (command) => command.contains('tool/work_supply_parser_qa_peh_core_post_mac_refresh.dart'),
  );
  final macNextActions = <String>[
    'Run the Mac PEH measurement wave commands from the packet on branch '
        '${packet['primaryBranch']}.',
    if (nextTrades.isNotEmpty)
      'Prioritize ${nextTrades.join(', ')} because they still have measured '
          'coverage gaps.',
    if (hasPostMacRefresh)
      'After the heavier run finishes, execute '
          '`dart run tool/work_supply_parser_qa_peh_core_post_mac_refresh.dart --root .` '
          'to rebuild the PEH and reusable handoff artifacts together.'
    else
      'Refresh Mac wave status, merged rollup, and PEH claim readiness artifacts '
          'after the heavier run finishes.',
  ];
  final windowsNextActions = <String>[
    'Keep Windows ownership on inventory-specific Work Supplies parser/code '
        'hardening.',
    'Do not claim 90-95 percent PEH readiness until the Mac wave closes the '
        'remaining measured gaps.',
    if (readinessActions.isNotEmpty) ...readinessActions,
  ];

  final checkpoint = <String, Object?>{
    'schemaVersion': 1,
    'report': 'reusable_parsing_qa_handoff_checkpoint',
    'primaryBranch': packet['primaryBranch'],
    'windowsWorkingBranch': packet['windowsWorkingBranch'],
    'windowsExecutionCommit':
        packet['currentExecutionCommit'] ??
        packet['inventoryExecutionCommit'] ??
        liveExecutionPacket['inventoryExecutionCommit'] ??
        liveExecutionPacket['commit'] ??
        'unknown',
    'validatedFloorCommit': packet['baselineCommit'],
    'validatedFloorLabel': packet['baselineCommitLabel'],
    'readyForMacMeasurementWave': readiness['readyForMacMeasurementWave'] ?? false,
    'readyToClaimNinetyPlus': readiness['readyToClaimNinetyPlus'] ?? false,
    'nextTradesByRemainingGap': nextTrades,
    'totalRemainingChecked': gap['totalRemainingChecked'] ?? 0,
    'sampleSizedTradeCount': rollup['sampleSizedTradeCount'] ?? 0,
    'underTargetTradeCount': rollup['underTargetTradeCount'] ?? 0,
    'expectedLocalDocsRefreshFiles': const [
      'docs/reusable_parsing_qa_checkpoint.json',
      'docs/reusable_parsing_qa_checkpoint.md',
      'docs/reusable_parsing_qa_mac_handoff_packet.json',
    ],
    'windowsNextActions': windowsNextActions,
    'macMiniNextActions': macNextActions,
    'generatedAtEdt': packet['generatedAtEdt'] ?? 'unknown',
  };

  final jsonFile = File.fromUri(
    docsDir.resolve('reusable_parsing_qa_checkpoint.json'),
  );
  jsonFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(checkpoint),
    flush: true,
  );

  final mdFile = File.fromUri(
    docsDir.resolve('reusable_parsing_qa_checkpoint.md'),
  );
  mdFile.writeAsStringSync(
    _markdownCheckpoint(checkpoint),
    flush: true,
  );

  stdout.writeln(
    'QA_REUSABLE_PARSING_HANDOFF_CHECKPOINT '
    '${const JsonEncoder.withIndent('  ').convert(checkpoint)}',
  );
  return 0;
}

String _markdownCheckpoint(Map<String, Object?> checkpoint) {
  final windowsNext = _stringList(checkpoint['windowsNextActions']);
  final macNext = _stringList(checkpoint['macMiniNextActions']);
  final nextTrades = _stringList(checkpoint['nextTradesByRemainingGap']);
  final expectedLocalDocs =
      _stringList(checkpoint['expectedLocalDocsRefreshFiles']);
  return '''# Reusable Parsing QA Checkpoint

Last updated: ${checkpoint['generatedAtEdt']}

- Primary reusable branch: `${checkpoint['primaryBranch']}`
- Windows working branch: `${checkpoint['windowsWorkingBranch']}`
- Windows execution commit: `${checkpoint['windowsExecutionCommit']}`
- Validated floor commit: `${checkpoint['validatedFloorCommit']}`
- Ready for Mac measurement wave: `${checkpoint['readyForMacMeasurementWave']}`
- Ready to claim 90-95 percent: `${checkpoint['readyToClaimNinetyPlus']}`
- Remaining measured gap count: `${checkpoint['totalRemainingChecked']}`
- Next trades by remaining gap: `${nextTrades.join(', ')}`

## Windows Next

${windowsNext.map((item) => '- $item').join('\n')}

## Mac Mini Next

${macNext.map((item) => '- $item').join('\n')}

## Expected Local Windows Refresh State

Immediately after a Windows-side handoff sync or PEH restamp, it is normal for
these local docs to be modified until the next artifact-sync commit:

${expectedLocalDocs.map((item) => '- `$item`').join('\n')}

If the live handoff is healthy, `dart run tool/reusable_parsing_qa_handoff_summary.dart --root .`
will report `expectedLocalDocsRefreshDirty: true` for this state.
''';
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return [for (final item in value) '$item'];
}

Map<String, Object?> _readOptionalJson(String path) {
  final file = File(path);
  if (!file.existsSync()) return const {};
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is Map<String, Object?>) return decoded;
  if (decoded is Map) return decoded.cast<String, Object?>();
  return const {};
}

List<List<String>> _commandLists(Object? value) {
  if (value is! List) return const [];
  return [
    for (final entry in value)
      if (entry is List) [for (final part in entry) '$part'],
  ];
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
