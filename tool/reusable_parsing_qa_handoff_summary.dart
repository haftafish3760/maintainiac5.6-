import 'dart:convert';
import 'dart:io';

import 'reusable_parsing_qa_handoff_status.dart';

const _usage =
    'dart run tool/reusable_parsing_qa_handoff_summary.dart '
    '[--root .]';

Future<void> main(List<String> args) async {
  final exit = runReusableParsingQaHandoffSummary(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runReusableParsingQaHandoffSummary(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }

  final root = _value(args, 'root', '.');
  final docsPacketFile = File(
    _join(root, 'docs/reusable_parsing_qa_mac_handoff_packet.json'),
  );
  final pehPacketFile = File(
    _join(root, 'build/parser_qa_pipeline/peh_core_mac_handoff_packet.json'),
  );

  final missing = <String>[
    if (!docsPacketFile.existsSync()) docsPacketFile.path,
    if (!pehPacketFile.existsSync()) pehPacketFile.path,
  ];
  if (missing.isNotEmpty) {
    stderr.writeln('Missing handoff summary inputs: ${missing.join(', ')}');
    return 66;
  }

  final statusBuffer = _MemorySink();
  final statusExit = runReusableParsingQaHandoffStatus(
    ['--root', root],
    stdout: statusBuffer,
    stderr: stderr,
  );
  final statusSummary = _extractStatusSummary(statusBuffer.content) ?? const {};

  final docsPacket =
      jsonDecode(docsPacketFile.readAsStringSync()) as Map<String, Object?>;
  final pehPacket =
      jsonDecode(pehPacketFile.readAsStringSync()) as Map<String, Object?>;

  final currentMeasurementState =
      (docsPacket['currentMeasurementState'] as Map?)?.cast<String, Object?>() ??
      const {};
  final firstMeasurementCommand = ((pehPacket['measurementCommands'] as List?) ??
          (docsPacket['macMiniNextCommands'] as List?) ??
          const <Object?>[])
      .cast<Object?>()
      .map((entry) {
        if (entry is Map && entry['command'] is List) {
          return (entry['command'] as List).cast<Object?>();
        }
        return entry;
      })
      .firstWhere(
        (entry) => entry is List && entry.isNotEmpty,
        orElse: () => const <Object?>[],
      );

  final summary = {
    'schemaVersion': 1,
    'report': 'reusable_parsing_qa_handoff_summary',
    'handoffClean': statusExit == 0,
    'statusExit': statusExit,
    'primaryBranch': docsPacket['primaryBranch'],
    'validatedFloorCommit': docsPacket['baselineCommit'],
    'validatedFloorLabel': docsPacket['baselineCommitLabel'],
    'windowsWorkingBranch': docsPacket['windowsWorkingBranch'],
    'windowsExecutionBranch': pehPacket['inventoryExecutionBranch'],
    'windowsExecutionCommit': pehPacket['inventoryExecutionCommit'],
    'docsAligned': statusSummary['docsAligned'],
    'parityApplicable': statusSummary['parityApplicable'],
    'parityOk': statusSummary['parityOk'],
    'packetExecutionHeadAligned': statusSummary['packetExecutionHeadAligned'],
    'scriptExecutionHeadAligned': statusSummary['scriptExecutionHeadAligned'],
    'readyForMacMeasurementWave': pehPacket['readyForMacMeasurementWave'],
    'readyToClaimNinetyPlus': pehPacket['readyToClaimNinetyPlus'],
    'totalRemainingChecked':
        currentMeasurementState['totalRemainingChecked'] ??
        pehPacket['totalRemainingChecked'] ??
        0,
    'nextTradesByRemainingGap':
        currentMeasurementState['nextTradesByRemainingGap'] ??
        pehPacket['nextTradesByRemainingGap'] ??
        const <Object>[],
    'claimBlockingFindings':
        docsPacket['claimBlockingFindings'] ??
        pehPacket['claimBlockingFindings'] ??
        const <Object>[],
    'claimNextActions':
        docsPacket['claimNextActions'] ??
        pehPacket['claimNextActions'] ??
        const <Object>[],
    'measurementCommandCount': pehPacket['measurementCommandCount'] ?? 0,
    'rollupCommandCount': pehPacket['rollupCommandCount'] ?? 0,
    'firstMeasurementCommand': firstMeasurementCommand,
    'statusPath': 'tool/reusable_parsing_qa_handoff_status.dart',
    'docsPacketPath': docsPacketFile.path,
    'executionPacketPath': pehPacketFile.path,
  };

  stdout.writeln(
    'QA_REUSABLE_PARSING_HANDOFF_SUMMARY '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  return statusExit == 0 ? 0 : 1;
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

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}

String _join(String root, String path) {
  final normalizedRoot = root.replaceAll('/', Platform.pathSeparator);
  final normalizedPath = path.replaceAll('/', Platform.pathSeparator);
  if (normalizedRoot.endsWith(Platform.pathSeparator)) {
    return '$normalizedRoot$normalizedPath';
  }
  return '$normalizedRoot${Platform.pathSeparator}$normalizedPath';
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
