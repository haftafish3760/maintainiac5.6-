import 'dart:convert';
import 'dart:io';

import 'reusable_parsing_qa_handoff_status.dart';

const _usage =
    'dart run tool/reusable_parsing_qa_mac_handoff_brief.dart [--root .]';

Future<void> main(List<String> args) async {
  final exit = runReusableParsingQaMacHandoffBrief(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runReusableParsingQaMacHandoffBrief(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }

  final root = _value(args, 'root', '.');
  final packetFile = File(
    _join(root, 'docs/reusable_parsing_qa_mac_handoff_packet.json'),
  );
  final checkpointFile = File(
    _join(root, 'docs/reusable_parsing_qa_checkpoint.json'),
  );

  final missing = <String>[
    if (!packetFile.existsSync()) packetFile.path,
    if (!checkpointFile.existsSync()) checkpointFile.path,
  ];
  if (missing.isNotEmpty) {
    stderr.writeln('Missing Mac handoff brief inputs: ${missing.join(', ')}');
    return 66;
  }

  final packet =
      jsonDecode(packetFile.readAsStringSync()) as Map<String, Object?>;
  final checkpoint =
      jsonDecode(checkpointFile.readAsStringSync()) as Map<String, Object?>;
  final statusBuffer = _MemorySink();
  final statusExit = runReusableParsingQaHandoffStatus(
    ['--root', root],
    stdout: statusBuffer,
    stderr: stderr,
  );
  final statusSummary = _extractStatusSummary(statusBuffer.content) ?? const {};
  final measurementState =
      (packet['currentMeasurementState'] as Map?)?.cast<String, Object?>() ??
      const {};
  final macCommands = _commandLists(packet['macMiniNextCommands']);
  final expectedOutputs = _stringList(packet['macMiniExpectedOutputs']);
  final readFirst = const [
    'docs/reusable_parsing_qa_handoff_marker.md',
    'docs/reusable_parsing_qa_scope_boundary.md',
    'docs/reusable_parsing_qa_checkpoint.md',
    'docs/reusable_parsing_qa_mac_runbook.md',
    'docs/reusable_parsing_qa_mac_handoff_packet.json',
  ];

  final payload = <String, Object?>{
    'schemaVersion': 1,
    'report': 'reusable_parsing_qa_mac_handoff_brief',
    'primaryBranch': packet['primaryBranch'],
    'validatedFloorCommit': packet['baselineCommit'],
    'validatedFloorLabel': packet['baselineCommitLabel'],
    'windowsWorkingBranch': checkpoint['windowsWorkingBranch'],
    'windowsExecutionCommit': checkpoint['windowsExecutionCommit'],
    'currentBranchHeadCommit': statusSummary['currentBranchHeadCommit'],
    'currentBranchHeadCommitFull': statusSummary['currentBranchHeadCommitFull'],
    'docsOnlyExecutionDriftAccepted':
        statusSummary['docsOnlyExecutionDriftAccepted'],
    'statusExit': statusExit,
    'readyForMacMeasurementWave':
        checkpoint['readyForMacMeasurementWave'] == true,
    'readyToClaimNinetyPlus': checkpoint['readyToClaimNinetyPlus'] == true,
    'nextTradesByRemainingGap':
        _stringList(checkpoint['nextTradesByRemainingGap']),
    'totalRemainingChecked':
        (checkpoint['totalRemainingChecked'] as num?)?.toInt() ?? 0,
    'claimBlockingFindings': _stringList(packet['claimBlockingFindings']),
    'claimNextActions': _stringList(packet['claimNextActions']),
    'measurementCommandCount':
        (packet['measurementCommandCount'] as num?)?.toInt() ?? 0,
    'rollupCommandCount':
        (packet['rollupCommandCount'] as num?)?.toInt() ?? 0,
    'macMiniExpectedOutputs': expectedOutputs,
    'readFirst': readFirst,
    'firstMeasurementCommand':
        macCommands.isEmpty ? const <String>[] : macCommands.first,
    'macMiniNextCommands': macCommands,
    'currentMeasurementState': {
      'nextTradeByGap': measurementState['nextTradeByGap'],
      'remainingCheckedForTopGap': measurementState['remainingCheckedForTopGap'],
      'totalRemainingChecked': measurementState['totalRemainingChecked'],
    },
    'expectedLocalDocsRefreshFiles':
        _stringList(checkpoint['expectedLocalDocsRefreshFiles']),
    'generatedAtEdt': packet['generatedAtEdt'] ?? checkpoint['generatedAtEdt'],
  };

  stdout.writeln(
    'QA_REUSABLE_PARSING_MAC_HANDOFF_BRIEF '
    '${const JsonEncoder.withIndent('  ').convert(payload)}',
  );
  return statusExit == 0 ? 0 : 1;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return [for (final item in value) '$item'];
}

List<List<String>> _commandLists(Object? value) {
  if (value is! List) return const [];
  return [
    for (final entry in value)
      if (entry is List) [for (final item in entry) '$item'],
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

Map<String, Object?>? _extractStatusSummary(String output) {
  const prefix = 'QA_REUSABLE_PARSING_HANDOFF_STATUS ';
  final start = output.indexOf(prefix);
  if (start < 0) return null;
  final jsonText = output.substring(start + prefix.length).trim();
  final decoded = jsonDecode(jsonText);
  if (decoded is Map<String, Object?>) return decoded;
  if (decoded is Map) return decoded.cast<String, Object?>();
  return null;
}

String _join(String root, String relative) {
  final normalizedRoot = root.replaceAll('/', Platform.pathSeparator);
  final normalizedRelative = relative.replaceAll('/', Platform.pathSeparator);
  if (normalizedRoot.endsWith(Platform.pathSeparator)) {
    return '$normalizedRoot$normalizedRelative';
  }
  return '$normalizedRoot${Platform.pathSeparator}$normalizedRelative';
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
