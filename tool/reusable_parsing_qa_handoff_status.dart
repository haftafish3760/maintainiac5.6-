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

  final missing = <String>[
    if (!indexFile.existsSync()) indexFile.path,
    if (!markerFile.existsSync()) markerFile.path,
    if (!runbookFile.existsSync()) runbookFile.path,
    if (!boundaryFile.existsSync()) boundaryFile.path,
    if (!checkpointFile.existsSync()) checkpointFile.path,
    if (!packetFile.existsSync()) packetFile.path,
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

  final branch = packet['primaryBranch']?.toString() ?? 'unknown-branch';
  final validatedFloor = packet['baselineCommit']?.toString() ?? 'unknown';
  final validatedFloorLabel =
      packet['baselineCommitLabel']?.toString() ?? 'unknown';
  final headShort =
      _gitValue(['rev-parse', '--short', 'HEAD'], root) ?? 'unknown-head';
  final headFull = _gitValue(['rev-parse', 'HEAD'], root) ?? headShort;
  final currentBranch =
      _gitValue(['rev-parse', '--abbrev-ref', 'HEAD'], root) ?? 'unknown-branch';
  final windowsWorkingBranch =
      File.fromUri(docsDir.resolve('reusable_parsing_qa_checkpoint.json'))
              .existsSync()
          ? ((jsonDecode(
                  File.fromUri(
                    docsDir.resolve('reusable_parsing_qa_checkpoint.json'),
                  ).readAsStringSync(),
                ) as Map<String, Object?>)['windowsWorkingBranch']
              ?.toString() ??
              'unknown-windows-branch')
          : 'unknown-windows-branch';

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
    'validatedFloorCommit': validatedFloor,
    'validatedFloorLabel': validatedFloorLabel,
    'headCommit': headShort,
    'headCommitFull': headFull,
    'docsAligned': agrees,
    'parityApplicable': parityApplicable,
    'parityOk': parityApplicable ? (paritySummary?['parityOk'] == true) : null,
    'parityExit': parityExit,
    'parityFindingCount': parityApplicable ? ((paritySummary?['findingCount'] ?? 0)) : 0,
    'parityFindings': parityApplicable ? ((paritySummary?['findings'] ?? const <Object>[])) : const <Object>[],
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
  return agrees && (!parityApplicable || parityExit == 0) ? 0 : 1;
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
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
