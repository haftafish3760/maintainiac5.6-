import 'dart:convert';
import 'dart:io';

import 'reusable_parsing_qa_handoff_parity.dart';

const _usage =
    'dart run tool/reusable_parsing_qa_handoff_status.dart '
    '[--root .]';

Future<void> main(List<String> args) async {
  final exit = runReusableParsingQaHandoffStatus(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runReusableParsingQaHandoffStatus(
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
  final indexFile = File.fromUri(
    docsDir.resolve('reusable_parsing_qa_handoff_index.md'),
  );
  final markerFile = File.fromUri(
    docsDir.resolve('reusable_parsing_qa_handoff_marker.md'),
  );
  final runbookFile = File.fromUri(
    docsDir.resolve('reusable_parsing_qa_mac_runbook.md'),
  );
  final boundaryFile = File.fromUri(
    docsDir.resolve('reusable_parsing_qa_scope_boundary.md'),
  );
  final checkpointFile = File.fromUri(
    docsDir.resolve('reusable_parsing_qa_checkpoint.md'),
  );
  final packetFile = File.fromUri(
    docsDir.resolve('reusable_parsing_qa_mac_handoff_packet.json'),
  );
  final pehPacketFile = File(
    _join(root, 'build/parser_qa_pipeline/peh_core_mac_handoff_packet.json'),
  );
  final pehScriptFile = File(
    _join(root, 'build/parser_qa_pipeline/peh_core_mac_handoff.sh'),
  );

  final missing = <String>[
    if (!indexFile.existsSync()) indexFile.path,
    if (!markerFile.existsSync()) markerFile.path,
    if (!runbookFile.existsSync()) runbookFile.path,
    if (!boundaryFile.existsSync()) boundaryFile.path,
    if (!checkpointFile.existsSync()) checkpointFile.path,
    if (!packetFile.existsSync()) packetFile.path,
    if (!pehPacketFile.existsSync()) pehPacketFile.path,
    if (!pehScriptFile.existsSync()) pehScriptFile.path,
  ];
  if (missing.isNotEmpty) {
    stderr.writeln('Missing handoff files: ${missing.join(', ')}');
    return 66;
  }

  final index = indexFile.readAsStringSync();
  final marker = markerFile.readAsStringSync();
  final runbook = runbookFile.readAsStringSync();
  final boundary = boundaryFile.readAsStringSync();
  final checkpoint = checkpointFile.readAsStringSync();
  final packet =
      jsonDecode(packetFile.readAsStringSync()) as Map<String, Object?>;
  final pehPacket =
      jsonDecode(pehPacketFile.readAsStringSync()) as Map<String, Object?>;
  final pehScript = pehScriptFile.readAsStringSync();
  final checkpointJson = _readCheckpointJson(root);

  final branch = packet['primaryBranch']?.toString() ?? 'unknown-branch';
  final validatedFloor = packet['baselineCommit']?.toString() ?? 'unknown';
  final validatedFloorLabel =
      packet['baselineCommitLabel']?.toString() ?? 'unknown';
  final headShort =
      _gitValue(['rev-parse', '--short', 'HEAD'], root) ?? 'unknown-head';
  final headFull = _gitValue(['rev-parse', 'HEAD'], root) ?? headShort;
  final currentBranch =
      _gitValue(['rev-parse', '--abbrev-ref', 'HEAD'], root) ?? 'unknown-branch';
  final localModifiedFiles = _gitModifiedFiles(root);
  final expectedLocalRefreshFiles = {
    'docs/reusable_parsing_qa_checkpoint.json',
    'docs/reusable_parsing_qa_checkpoint.md',
    'docs/reusable_parsing_qa_handoff_index.md',
    'docs/reusable_parsing_qa_handoff_marker.md',
    'docs/reusable_parsing_qa_mac_handoff_packet.json',
    'docs/reusable_parsing_qa_mac_runbook.md',
    'docs/reusable_parsing_qa_scope_boundary.md',
  };
  final hasLocalModifiedFiles = localModifiedFiles.isNotEmpty;
  final windowsWorkingBranch =
      checkpointJson['windowsWorkingBranch']?.toString() ??
      'codex/inventory-parser-backup-20260702-2056';
  final expectedLocalDocsRefreshDirty =
      hasLocalModifiedFiles &&
      currentBranch == windowsWorkingBranch &&
      localModifiedFiles.every(expectedLocalRefreshFiles.contains);
  final checkpointTotalRemainingChecked =
      (checkpointJson['totalRemainingChecked'] as num?)?.toInt() ?? 0;
  final checkpointNextTradesByRemainingGap = _stringList(
    checkpointJson['nextTradesByRemainingGap'],
  );
  final packetCurrentMeasurementState =
      (packet['currentMeasurementState'] as Map?)?.cast<String, Object?>() ??
      const {};
  final packetTotalRemainingChecked =
      (packetCurrentMeasurementState['totalRemainingChecked'] as num?)?.toInt() ??
      0;
  final packetNextTradesByRemainingGap = _stringList(
    packetCurrentMeasurementState['nextTradesByRemainingGap'],
  );
  final claimBlockingFindings = _stringList(packet['claimBlockingFindings']);
  final claimNextActions = _stringList(packet['claimNextActions']);
  final packetExecutionCommit =
      pehPacket['inventoryExecutionCommit']?.toString() ??
      pehPacket['commit']?.toString() ??
      'unknown-execution-commit';
  final packetExecutionBranch =
      pehPacket['inventoryExecutionBranch']?.toString() ??
      pehPacket['branch']?.toString() ??
      'unknown-execution-branch';
  final scriptExecutionCommit =
      _extractScriptCommentValue(pehScript, '# Commit: ') ??
      'unknown-script-commit';
  final scriptExecutionBranch =
      _extractScriptCommentValue(pehScript, '# Branch: ') ??
      'unknown-script-branch';
  final docsOnlyExecutionDrift =
      currentBranch == windowsWorkingBranch &&
      _isDocsOnlyHandoffDrift(
        root,
        baseCommit: packetExecutionCommit,
        headCommit: headFull,
      );
  final executionPacketAlignedToHead =
      currentBranch != windowsWorkingBranch ||
      (packetExecutionBranch == currentBranch &&
          (packetExecutionCommit == headShort || docsOnlyExecutionDrift));
  final executionScriptAlignedToHead =
      currentBranch != windowsWorkingBranch ||
      (scriptExecutionBranch == currentBranch &&
          (scriptExecutionCommit == headShort || docsOnlyExecutionDrift));

  final agrees =
      _extractSingleLineValue(
            marker,
            '- Primary reusable branch: `',
          ) ==
          branch &&
      _extractSingleLineValue(
            index,
            '- Branch: `',
          ) ==
          branch &&
      index.contains('docs/reusable_parsing_qa_scope_boundary.md') &&
      _extractSingleLineValue(
            marker,
            '- Validated floor commit: `',
          ) ==
          validatedFloor &&
      _extractSingleLineValue(
            index,
            '- Validated floor commit: `',
          ) ==
          validatedFloor &&
      _extractSingleLineValue(
            runbook,
            '2. Confirm the branch is at or after validated floor commit `',
          ) ==
          validatedFloor &&
      checkpoint.contains('## Windows Next') &&
      checkpoint.contains('## Mac Mini Next') &&
      boundary.contains('Validated floor commit: `$validatedFloor`') &&
      packet['scopeBoundaryPath']?.toString() ==
          'docs/reusable_parsing_qa_scope_boundary.md' &&
      packet['checkpointJsonPath']?.toString() ==
          'docs/reusable_parsing_qa_checkpoint.json' &&
      packet['windowsCheckpointSyncCommand']?.toString().contains(
            'reusable_parsing_qa_handoff_sync.dart',
          ) ==
          true &&
      packet['artifactInputs'] is Map &&
      ((packet['artifactInputs'] as Map)['claimReadiness']?.toString() ==
          'build/parser_qa_pipeline/peh_core_claim_readiness.json') &&
      packetCurrentMeasurementState['nextTradeByGap']?.toString().isNotEmpty ==
          true &&
      packetTotalRemainingChecked == checkpointTotalRemainingChecked &&
      _sameStrings(
        packetNextTradesByRemainingGap,
        checkpointNextTradesByRemainingGap,
      ) &&
      claimBlockingFindings.isNotEmpty &&
      claimNextActions.isNotEmpty &&
      packet['checkpointMarkdownPath']?.toString() ==
          'docs/reusable_parsing_qa_checkpoint.md';

  final branchTipAheadOfFloor = headShort != validatedFloor;
  final refreshCommand = 'dart run tool/reusable_parsing_qa_handoff_refresh.dart';
  final parityApplicable = currentBranch == windowsWorkingBranch;
  Map<String, Object?>? paritySummary;
  var parityExit = 0;
  if (parityApplicable) {
    final parityBuffer = _MemorySink();
    parityExit = runReusableParsingQaHandoffParity(
      ['--root', root],
      stdout: parityBuffer,
      stderr: stderr,
    );
    paritySummary = _extractParitySummary(parityBuffer.content);
  }

  final summary = {
    'schemaVersion': 1,
    'report': 'reusable_parsing_qa_handoff_status',
    'primaryBranch': branch,
    'currentBranch': currentBranch,
    'currentBranchHeadCommit': headShort,
    'currentBranchHeadCommitFull': headFull,
    'validatedFloorCommit': validatedFloor,
    'validatedFloorLabel': validatedFloorLabel,
    'headCommit': headShort,
    'headCommitFull': headFull,
    'checkpointTotalRemainingChecked': checkpointTotalRemainingChecked,
    'checkpointNextTradesByRemainingGap': checkpointNextTradesByRemainingGap,
    'packetTotalRemainingChecked': packetTotalRemainingChecked,
    'packetNextTradesByRemainingGap': packetNextTradesByRemainingGap,
    'docsAligned': agrees,
    'parityApplicable': parityApplicable,
    'parityOk': parityApplicable ? (paritySummary?['parityOk'] == true) : null,
    'parityExit': parityExit,
    'parityFindingCount':
        parityApplicable ? (paritySummary?['findingCount'] ?? 0) : 0,
    'parityFindings':
        parityApplicable
            ? (paritySummary?['findings'] ?? const <Object>[])
            : const <Object>[],
    'packetExecutionBranch': packetExecutionBranch,
    'packetExecutionCommit': packetExecutionCommit,
    'packetExecutionHeadAligned': executionPacketAlignedToHead,
    'scriptExecutionBranch': scriptExecutionBranch,
    'scriptExecutionCommit': scriptExecutionCommit,
    'scriptExecutionHeadAligned': executionScriptAlignedToHead,
    'docsOnlyExecutionDriftAccepted': docsOnlyExecutionDrift,
    'hasLocalModifiedFiles': hasLocalModifiedFiles,
    'localModifiedFiles': localModifiedFiles,
    'expectedLocalDocsRefreshDirty': expectedLocalDocsRefreshDirty,
    'branchTipAheadOfValidatedFloor': branchTipAheadOfFloor,
    'refreshCommand': refreshCommand,
    'indexPath': indexFile.path,
    'markerPath': markerFile.path,
    'boundaryPath': boundaryFile.path,
    'checkpointPath': checkpointFile.path,
    'runbookPath': runbookFile.path,
    'packetPath': packetFile.path,
  };

  stdout.writeln(
    'QA_REUSABLE_PARSING_HANDOFF_STATUS '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  return agrees &&
          (!parityApplicable || parityExit == 0) &&
          executionPacketAlignedToHead &&
          executionScriptAlignedToHead
      ? 0
      : 1;
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}

Map<String, Object?> _readCheckpointJson(String root) {
  final file = File(_join(root, 'docs/reusable_parsing_qa_checkpoint.json'));
  if (!file.existsSync()) return const {};
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is Map<String, Object?>) return decoded;
  if (decoded is Map) return decoded.cast<String, Object?>();
  return const {};
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value
        .map((entry) => entry?.toString() ?? '')
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _isDocsOnlyHandoffDrift(
  String root, {
  required String baseCommit,
  required String headCommit,
}) {
  if (baseCommit.isEmpty || headCommit.isEmpty || baseCommit == 'unknown-execution-commit') {
    return false;
  }
  final result = Process.runSync(
    'git',
    ['diff', '--name-only', '$baseCommit..$headCommit'],
    workingDirectory: root,
  );
  if (result.exitCode != 0) return false;
  final files = result.stdout
      .toString()
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim().replaceAll('\\', '/'))
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  if (files.isEmpty) return false;
  final tradeHandoffPattern = RegExp(
    r'^docs/inventory_parser_(plumbing|electrical|hvac)_core_mac_handoff\.md$',
  );
  const reusableHandoffDocs = {
    'docs/reusable_parsing_qa_checkpoint.json',
    'docs/reusable_parsing_qa_checkpoint.md',
    'docs/reusable_parsing_qa_handoff_index.md',
    'docs/reusable_parsing_qa_handoff_marker.md',
    'docs/reusable_parsing_qa_mac_handoff_packet.json',
    'docs/reusable_parsing_qa_mac_runbook.md',
    'docs/reusable_parsing_qa_scope_boundary.md',
  };
  return files.every(
    (file) => tradeHandoffPattern.hasMatch(file) || reusableHandoffDocs.contains(file),
  );
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

List<String> _gitModifiedFiles(String root) {
  final result = Process.runSync(
    'git',
    ['status', '--short'],
    workingDirectory: root,
  );
  if (result.exitCode != 0) return const [];
  return result.stdout
      .toString()
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trimRight())
      .where((line) => line.isNotEmpty)
      .map((line) {
        if (line.length <= 3) return '';
        return line.substring(3).trim().replaceAll('\\', '/');
      })
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

String _extractSingleLineValue(String source, String prefix) {
  final start = source.indexOf(prefix);
  if (start < 0) return '';
  final valueStart = start + prefix.length;
  final valueEnd = source.indexOf('`', valueStart);
  if (valueEnd < 0) return '';
  return source.substring(valueStart, valueEnd);
}

Map<String, Object?>? _extractParitySummary(String stdout) {
  const prefix = 'QA_REUSABLE_PARSING_HANDOFF_PARITY ';
  final start = stdout.indexOf(prefix);
  if (start < 0) return null;
  final jsonText = stdout.substring(start + prefix.length).trim();
  final decoded = jsonDecode(jsonText);
  if (decoded is Map<String, Object?>) {
    return decoded;
  }
  if (decoded is Map) {
    return decoded.cast<String, Object?>();
  }
  return null;
}

String _join(String root, String path) {
  final normalizedRoot = root.replaceAll('/', Platform.pathSeparator);
  final normalizedPath = path.replaceAll('/', Platform.pathSeparator);
  if (normalizedRoot.endsWith(Platform.pathSeparator)) {
    return '$normalizedRoot$normalizedPath';
  }
  return '$normalizedRoot${Platform.pathSeparator}$normalizedPath';
}

String? _extractScriptCommentValue(String source, String prefix) {
  final start = source.indexOf(prefix);
  if (start < 0) return null;
  final valueStart = start + prefix.length;
  final valueEnd = source.indexOf('\n', valueStart);
  if (valueEnd < 0) {
    return source.substring(valueStart).trim();
  }
  return source.substring(valueStart, valueEnd).trim();
}

class _MemorySink implements IOSink {
  final _buffer = StringBuffer();

  String get content => _buffer.toString();

  @override
  void write(Object? object) => _buffer.write(object);

  @override
  void writeln([Object? object = '']) => _buffer.writeln(object);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
