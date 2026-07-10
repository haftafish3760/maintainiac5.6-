import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/reusable_parsing_qa_handoff_parity.dart '
    '[--root .] '
    '[--checkpoint docs/reusable_parsing_qa_checkpoint.json] '
    '[--peh-packet build/parser_qa_pipeline/peh_core_mac_handoff_packet.json]';

Future<void> main(List<String> args) async {
  final exit = runReusableParsingQaHandoffParity(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runReusableParsingQaHandoffParity(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }

  final root = _value(args, 'root', '.');
  final checkpointPath = _value(
    args,
    'checkpoint',
    'docs/reusable_parsing_qa_checkpoint.json',
  );
  final pehPacketPath = _value(
    args,
    'peh-packet',
    'build/parser_qa_pipeline/peh_core_mac_handoff_packet.json',
  );

  final checkpointFile = File(_resolve(root, checkpointPath));
  final pehPacketFile = File(_resolve(root, pehPacketPath));

  final missing = <String>[
    if (!checkpointFile.existsSync()) checkpointFile.path,
    if (!pehPacketFile.existsSync()) pehPacketFile.path,
  ];
  if (missing.isNotEmpty) {
    stderr.writeln('Missing parity inputs: ${missing.join(', ')}');
    return 66;
  }

  final checkpoint =
      jsonDecode(checkpointFile.readAsStringSync()) as Map<String, Object?>;
  final pehPacket =
      jsonDecode(pehPacketFile.readAsStringSync()) as Map<String, Object?>;

  final primaryBranch =
      checkpoint['primaryBranch']?.toString() ?? 'unknown-primary-branch';
  final validatedFloorCommit =
      checkpoint['validatedFloorCommit']?.toString() ??
      'unknown-validated-floor';
  final windowsWorkingBranch =
      checkpoint['windowsWorkingBranch']?.toString() ??
      'unknown-windows-branch';
  final readyForMacMeasurementWave =
      checkpoint['readyForMacMeasurementWave'] == true;
  final readyToClaimNinetyPlus =
      checkpoint['readyToClaimNinetyPlus'] == true;
  final totalRemainingChecked =
      (checkpoint['totalRemainingChecked'] as num?)?.toInt() ?? 0;
  final nextTradesByRemainingGap = _stringList(
    checkpoint['nextTradesByRemainingGap'],
  );

  final packetReusableBranch =
      pehPacket['reusableBaselineBranch']?.toString() ??
      'unknown-packet-reusable-branch';
  final packetReusableFloor =
      pehPacket['reusableValidatedFloorCommit']?.toString() ??
      'unknown-packet-reusable-floor';
  final packetInventoryBranch =
      pehPacket['inventoryExecutionBranch']?.toString() ??
      pehPacket['branch']?.toString() ??
      'unknown-packet-inventory-branch';
  final packetReadyForMacMeasurementWave =
      pehPacket['readyForMacMeasurementWave'] == true;
  final packetReadyToClaimNinetyPlus =
      pehPacket['readyToClaimNinetyPlus'] == true;
  final packetTotalRemainingChecked =
      (pehPacket['totalRemainingChecked'] as num?)?.toInt() ?? 0;
  final packetNextTradesByRemainingGap = _stringList(
    pehPacket['nextTradesByRemainingGap'],
  );

  final findings = <String>[
    if (packetReusableBranch != primaryBranch)
      'reusable baseline branch mismatch: checkpoint=$primaryBranch packet=$packetReusableBranch',
    if (packetReusableFloor != validatedFloorCommit)
      'reusable validated floor mismatch: checkpoint=$validatedFloorCommit packet=$packetReusableFloor',
    if (packetInventoryBranch != windowsWorkingBranch)
      'inventory execution branch mismatch: checkpoint=$windowsWorkingBranch packet=$packetInventoryBranch',
    if (packetReadyForMacMeasurementWave != readyForMacMeasurementWave)
      'readyForMacMeasurementWave mismatch: checkpoint=$readyForMacMeasurementWave packet=$packetReadyForMacMeasurementWave',
    if (packetReadyToClaimNinetyPlus != readyToClaimNinetyPlus)
      'readyToClaimNinetyPlus mismatch: checkpoint=$readyToClaimNinetyPlus packet=$packetReadyToClaimNinetyPlus',
    if (packetTotalRemainingChecked != totalRemainingChecked)
      'totalRemainingChecked mismatch: checkpoint=$totalRemainingChecked packet=$packetTotalRemainingChecked',
    if (!_sameStrings(packetNextTradesByRemainingGap, nextTradesByRemainingGap))
      'nextTradesByRemainingGap mismatch: checkpoint=${nextTradesByRemainingGap.join(",")} packet=${packetNextTradesByRemainingGap.join(",")}',
  ];

  final summary = {
    'schemaVersion': 1,
    'report': 'reusable_parsing_qa_handoff_parity',
    'checkpointPath': checkpointPath,
    'pehPacketPath': pehPacketPath,
    'primaryBranch': primaryBranch,
    'validatedFloorCommit': validatedFloorCommit,
    'windowsWorkingBranch': windowsWorkingBranch,
    'packetReusableBaselineBranch': packetReusableBranch,
    'packetReusableValidatedFloorCommit': packetReusableFloor,
    'packetInventoryExecutionBranch': packetInventoryBranch,
    'readyForMacMeasurementWave': readyForMacMeasurementWave,
    'readyToClaimNinetyPlus': readyToClaimNinetyPlus,
    'totalRemainingChecked': totalRemainingChecked,
    'nextTradesByRemainingGap': nextTradesByRemainingGap,
    'packetTotalRemainingChecked': packetTotalRemainingChecked,
    'packetNextTradesByRemainingGap': packetNextTradesByRemainingGap,
    'parityOk': findings.isEmpty,
    'findingCount': findings.length,
    'findings': findings,
  };

  stdout.writeln(
    'QA_REUSABLE_PARSING_HANDOFF_PARITY '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  return findings.isEmpty ? 0 : 1;
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

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}

String _resolve(String root, String path) {
  if (p.isAbsolute(path)) return path;
  return p.join(root, path);
}

final p = _Path();

class _Path {
  bool isAbsolute(String path) {
    if (path.length > 2 && path[1] == ':') return true;
    return path.startsWith('/') || path.startsWith(r'\');
  }

  String join(String a, String b) {
    final normalizedA = a.replaceAll('/', Platform.pathSeparator);
    final normalizedB = b.replaceAll('/', Platform.pathSeparator);
    if (normalizedA.endsWith(Platform.pathSeparator)) {
      return '$normalizedA$normalizedB';
    }
    return '$normalizedA${Platform.pathSeparator}$normalizedB';
  }
}
