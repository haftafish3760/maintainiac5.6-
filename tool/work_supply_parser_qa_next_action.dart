import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_next_action.dart '
    '[--output build/parser_qa_pass_evidence/next_action.json]';

const _releaseCommandsPath =
    'build/parser_qa_pipeline/release_one_commands.json';
const _evidenceSummaryPath =
    'build/parser_qa_pass_evidence/evidence_summary.json';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaNextAction(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaNextAction(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }

  final commands = _readJson(_releaseCommandsPath);
  final evidence = _readJson(_evidenceSummaryPath);
  final missing = _stringList(evidence['missingArtifactNames']);
  final unsafe = _stringList(evidence['unsafeFindings']);
  final commandCells = _commandCellIds(commands['commands']);

  final nextActions = <String>[
    if (missing.isNotEmpty)
      'Regenerate missing local artifacts before parser QA expansion.',
    if (unsafe.isNotEmpty)
      'Stop release progression and fix unsafe local-only evidence flags.',
    if (commandCells.isEmpty)
      'Regenerate release-one command manifest before launching batch waves.',
    if (missing.isEmpty && unsafe.isEmpty && commandCells.isNotEmpty)
      'Start the next local-only residential parser QA batch wave.',
  ];

  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_next_action',
    'readyForNextBatch':
        missing.isEmpty && unsafe.isEmpty && commandCells.isNotEmpty,
    'releaseOneCellCount': commandCells.length,
    'sampleCells': commandCells.take(6).toList(),
    'missingArtifactNames': missing,
    'unsafeFindings': unsafe,
    'nextActions': nextActions,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
  };

  final output = _value(
    args,
    'output',
    'build/parser_qa_pass_evidence/next_action.json',
  );
  final file = File(output)..parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(summary));
  stdout.writeln(
    'QA_NEXT_ACTION ${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln('QA_NEXT_ACTION_ARTIFACT json=$output');
  return unsafe.isEmpty ? 0 : 1;
}

Map<String, Object?> _readJson(String path) {
  final file = File(path);
  if (!file.existsSync()) return const {};
  final decoded = jsonDecode(file.readAsStringSync());
  return decoded is Map ? decoded.cast<String, Object?>() : const {};
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return [for (final item in value) '$item'];
}

List<String> _commandCellIds(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map && item['cellId'] != null) '${item['cellId']}',
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
