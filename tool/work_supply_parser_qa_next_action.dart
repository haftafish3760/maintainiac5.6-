import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_next_action.dart '
    '[--output build/parser_qa_pass_evidence/next_action.json]';

const _releaseCommandsPath =
    'build/parser_qa_pipeline/release_one_commands.json';
const _evidenceSummaryPath =
    'build/parser_qa_pass_evidence/evidence_summary.json';
const _batchWaveRoot = 'build/parser_qa_batch_waves';

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
  final activeWaves = _runningWaveStatuses(_batchWaveRoot);
  final activeUnsafe = _activeWaveUnsafeFindings(activeWaves);
  final allUnsafe = [...unsafe, ...activeUnsafe];

  final nextActions = <String>[
    if (missing.isNotEmpty)
      'Regenerate missing local artifacts before parser QA expansion.',
    if (allUnsafe.isNotEmpty)
      'Stop release progression and fix unsafe local-only evidence flags.',
    if (activeWaves.isNotEmpty)
      'Wait for the active local-only parser QA wave to finish before launching another batch wave.',
    if (commandCells.isEmpty)
      'Regenerate release-one command manifest before launching batch waves.',
    if (missing.isEmpty &&
        allUnsafe.isEmpty &&
        activeWaves.isEmpty &&
        commandCells.isNotEmpty)
      'Start the next local-only residential parser QA batch wave.',
  ];
  final readyForNextBatch =
      missing.isEmpty &&
      allUnsafe.isEmpty &&
      activeWaves.isEmpty &&
      commandCells.isNotEmpty;

  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_next_action',
    'readyForNextBatch': readyForNextBatch,
    'releaseOneCellCount': commandCells.length,
    'sampleCells': commandCells.take(6).toList(),
    'activeWaveCount': activeWaves.length,
    'activeWaves': activeWaves,
    'missingArtifactNames': missing,
    'unsafeFindings': allUnsafe,
    'activeWaveUnsafeFindings': activeUnsafe,
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
  return allUnsafe.isEmpty ? 0 : 1;
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

List<Map<String, Object?>> _runningWaveStatuses(String rootPath) {
  final root = Directory(rootPath);
  if (!root.existsSync()) return const [];
  final activeByQueue = <String, Map<String, Object?>>{};
  for (final entity in _safeRecursiveList(root)) {
    if (entity is! File || !entity.path.endsWith('latest_status.json')) {
      continue;
    }
    final decoded = _readJson(entity.path);
    if (decoded['state'] != 'running') continue;
    final queueId = '${decoded['queueId'] ?? ''}';
    final key = queueId.isEmpty ? entity.path : queueId;
    activeByQueue[key] = {
      'path': entity.path,
      'queueId': queueId,
      'activeCellId': decoded['activeCellId'] ?? '',
      'completedCellCount': decoded['completedCellCount'] ?? 0,
      'failedCellCount': decoded['failedCellCount'] ?? 0,
      'liveServicesAllowed': decoded['liveServicesAllowed'] ?? false,
      'writesProductionCatalog': decoded['writesProductionCatalog'] ?? false,
      'firebaseWritesAllowed': decoded['firebaseWritesAllowed'] ?? false,
      'ocrCameraExpensesTouched': decoded['ocrCameraExpensesTouched'] ?? false,
    };
  }
  final active = activeByQueue.values.toList();
  active.sort((a, b) => '${a['path']}'.compareTo('${b['path']}'));
  return active;
}

List<String> _activeWaveUnsafeFindings(List<Map<String, Object?>> waves) {
  final findings = <String>[];
  const unsafeFlags = {
    'liveServicesAllowed',
    'writesProductionCatalog',
    'firebaseWritesAllowed',
    'ocrCameraExpensesTouched',
  };
  for (final wave in waves) {
    final queueId = '${wave['queueId'] ?? ''}';
    for (final flag in unsafeFlags) {
      if (wave[flag] != true) continue;
      findings.add('activeWave:$queueId:$flag=true');
    }
  }
  findings.sort();
  return findings;
}

Iterable<FileSystemEntity> _safeRecursiveList(Directory root) sync* {
  List<FileSystemEntity> children;
  try {
    children = root.listSync(followLinks: false);
  } on FileSystemException {
    return;
  }
  for (final child in children) {
    yield child;
    if (child is Directory) {
      yield* _safeRecursiveList(child);
    }
  }
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
