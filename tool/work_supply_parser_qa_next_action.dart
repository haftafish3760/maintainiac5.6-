import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_next_action.dart '
    '[--output build/parser_qa_pass_evidence/next_action.json]';

const _releaseCommandsPath =
    'build/parser_qa_pipeline/release_one_commands.json';
const _evidenceSummaryPath =
    'build/parser_qa_pass_evidence/evidence_summary.json';
const _waveRemediationsPath =
    'build/parser_qa_pass_evidence/wave_remediations.json';
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
  final readErrors = [
    ..._readErrorFinding(commands, _releaseCommandsPath),
    ..._readErrorFinding(evidence, _evidenceSummaryPath),
  ];
  final commandCells = _commandCellIds(commands['commands']);
  final maxStatusAgeMs = _intValue(args, 'max-status-age-ms', 900000);
  final maxActiveCellMs = _intValue(args, 'max-active-cell-ms', 900000);
  final waveRemediations = _waveRemediationSummaries(
    _readJson(_waveRemediationsPath),
  );
  final candidateBlockingWaves = _blockingWaveStatuses(
    _batchWaveRoot,
    now: DateTime.now().toUtc(),
    maxStatusAgeMs: maxStatusAgeMs,
    maxActiveCellMs: maxActiveCellMs,
  );
  final remediatedQueueIds = {
    for (final remediation in waveRemediations)
      if (remediation['valid'] == true) '${remediation['queueId']}',
  };
  final blockingWaves = [
    for (final wave in candidateBlockingWaves)
      if (wave['state'] != 'failed' ||
          !remediatedQueueIds.contains('${wave['queueId']}'))
        wave,
  ];
  final remediatedWaves = [
    for (final wave in candidateBlockingWaves)
      if (wave['state'] == 'failed' &&
          remediatedQueueIds.contains('${wave['queueId']}'))
        {
          ...wave,
          'remediation': waveRemediations.firstWhere(
            (remediation) => remediation['queueId'] == wave['queueId'],
          ),
        },
  ];
  final waveUnsafe = _waveUnsafeFindings(blockingWaves);
  final allUnsafe = [...unsafe, ...readErrors, ...waveUnsafe];

  final nextActions = <String>[
    if (missing.isNotEmpty)
      'Regenerate missing local artifacts before parser QA expansion.',
    if (allUnsafe.isNotEmpty)
      'Stop release progression and fix unsafe local-only evidence flags.',
    if (blockingWaves.any((wave) => wave['state'] == 'running'))
      'Wait for the active local-only parser QA wave to finish before launching another batch wave.',
    if (blockingWaves.any((wave) => wave['state'] == 'failed'))
      'Fix failed local parser QA wave evidence before launching another batch wave.',
    if (commandCells.isEmpty)
      'Regenerate release-one command manifest before launching batch waves.',
    if (missing.isEmpty &&
        allUnsafe.isEmpty &&
        blockingWaves.isEmpty &&
        commandCells.isNotEmpty)
      'Start the next local-only residential parser QA batch wave.',
  ];
  final readyForNextBatch =
      missing.isEmpty &&
      allUnsafe.isEmpty &&
      blockingWaves.isEmpty &&
      commandCells.isNotEmpty;

  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_next_action',
    'readyForNextBatch': readyForNextBatch,
    'releaseOneCellCount': commandCells.length,
    'sampleCells': commandCells.take(6).toList(),
    'activeWaveCount': blockingWaves
        .where((wave) => wave['state'] == 'running')
        .length,
    'activeWaves': [
      for (final wave in blockingWaves)
        if (wave['state'] == 'running') wave,
    ],
    'blockingWaveCount': blockingWaves.length,
    'blockingWaves': blockingWaves,
    'remediatedWaveCount': remediatedWaves.length,
    'remediatedWaves': remediatedWaves,
    'waveRemediations': waveRemediations,
    'maxStatusAgeMs': maxStatusAgeMs,
    'maxActiveCellMs': maxActiveCellMs,
    'missingArtifactNames': missing,
    'unsafeFindings': allUnsafe,
    'activeWaveUnsafeFindings': waveUnsafe,
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
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    return decoded is Map
        ? decoded.cast<String, Object?>()
        : {'_readError': 'JSON root is not an object.', '_readPath': path};
  } on FormatException catch (error) {
    return {'_readError': error.message, '_readPath': path};
  } on FileSystemException catch (error) {
    return {'_readError': error.message, '_readPath': path};
  }
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

List<String> _readErrorFinding(Map<String, Object?> json, String fallbackPath) {
  final error = json['_readError']?.toString();
  if (error == null || error.isEmpty) return const [];
  final path = json['_readPath']?.toString() ?? fallbackPath;
  return ['jsonReadError:$path:$error'];
}

List<Map<String, Object?>> _blockingWaveStatuses(
  String rootPath, {
  required DateTime now,
  required int maxStatusAgeMs,
  required int maxActiveCellMs,
}) {
  final root = Directory(rootPath);
  if (!root.existsSync()) return const [];
  final blockingByQueue = <String, Map<String, Object?>>{};
  for (final entity in _safeRecursiveList(root)) {
    if (entity is! File || !entity.path.endsWith('latest_status.json')) {
      continue;
    }
    final decoded = _readJson(entity.path);
    if (decoded['_readError'] != null) {
      blockingByQueue['read-error:${entity.path}'] = {
        'path': entity.path,
        'state': 'read_error',
        'queueId': '',
        'activeCellId': '',
        'completedCellCount': 0,
        'failedCellCount': 0,
        'readError': decoded['_readError'],
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'firebaseWritesAllowed': false,
        'ocrCameraExpensesTouched': false,
      };
      continue;
    }
    final state = '${decoded['state'] ?? ''}';
    final failedCellCount = _asInt(decoded['failedCellCount']) ?? 0;
    if (state != 'running' && state != 'failed' && failedCellCount == 0) {
      continue;
    }
    final queueId = '${decoded['queueId'] ?? ''}';
    final key = queueId.isEmpty ? entity.path : queueId;
    final updatedAt = DateTime.tryParse('${decoded['updatedAtIso'] ?? ''}');
    final statusAgeMs = updatedAt == null
        ? null
        : now.difference(updatedAt.toUtc()).inMilliseconds;
    final activeCellElapsedMs = _asInt(decoded['activeCellElapsedMs']);
    blockingByQueue[key] = {
      'path': entity.path,
      'state': state,
      'queueId': queueId,
      'activeCellId': decoded['activeCellId'] ?? '',
      'completedCellCount': decoded['completedCellCount'] ?? 0,
      'failedCellCount': failedCellCount,
      'hasFailedCells': failedCellCount > 0,
      'updatedAtIso': decoded['updatedAtIso'] ?? '',
      'statusAgeMs': statusAgeMs,
      'activeCellElapsedMs': activeCellElapsedMs,
      'statusStale':
          state == 'running' &&
          (statusAgeMs == null || statusAgeMs > maxStatusAgeMs),
      'activeCellStale':
          state == 'running' &&
          activeCellElapsedMs != null &&
          activeCellElapsedMs > maxActiveCellMs,
      'liveServicesAllowed': decoded['liveServicesAllowed'] ?? false,
      'writesProductionCatalog': decoded['writesProductionCatalog'] ?? false,
      'firebaseWritesAllowed': decoded['firebaseWritesAllowed'] ?? false,
      'ocrCameraExpensesTouched': decoded['ocrCameraExpensesTouched'] ?? false,
    };
  }
  final blocking = blockingByQueue.values.toList();
  blocking.sort((a, b) => '${a['path']}'.compareTo('${b['path']}'));
  return blocking;
}

List<Map<String, Object?>> _waveRemediationSummaries(
  Map<String, Object?> manifest,
) {
  final rawEntries = manifest['remediations'];
  if (rawEntries is! List) return const [];
  final summaries = <Map<String, Object?>>[];
  for (final rawEntry in rawEntries) {
    if (rawEntry is! Map) continue;
    final entry = rawEntry.cast<String, Object?>();
    final queueId = '${entry['queueId'] ?? ''}'.trim();
    final fixedCommit = '${entry['fixedCommit'] ?? ''}'.trim();
    final evidenceReport = '${entry['evidenceReport'] ?? ''}'.trim();
    final fixedCellIds = _stringList(entry['fixedCellIds']);
    final evidence = _readJson(evidenceReport);
    final evidenceFailureCount = _asInt(evidence['failureCount']);
    final evidenceChecked = _asInt(evidence['checked']);
    final evidenceValid =
        evidenceReport.isNotEmpty &&
        evidence['_readError'] == null &&
        evidenceFailureCount == 0 &&
        evidenceChecked != null &&
        evidenceChecked > 0;
    final valid =
        queueId.isNotEmpty &&
        fixedCommit.isNotEmpty &&
        fixedCellIds.isNotEmpty &&
        evidenceValid;
    summaries.add({
      'queueId': queueId,
      'fixedCellIds': fixedCellIds,
      'fixedCommit': fixedCommit,
      'evidenceReport': evidenceReport,
      'evidenceChecked': evidenceChecked ?? 0,
      'evidenceFailureCount': evidenceFailureCount,
      'valid': valid,
      if (evidence['_readError'] != null) 'readError': evidence['_readError'],
    });
  }
  summaries.sort((a, b) => '${a['queueId']}'.compareTo('${b['queueId']}'));
  return summaries;
}

List<String> _waveUnsafeFindings(List<Map<String, Object?>> waves) {
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
    final readError = wave['readError']?.toString();
    if (readError != null && readError.isNotEmpty) {
      findings.add('activeWaveStatusReadError:${wave['path']}:$readError');
    }
    if (wave['statusStale'] == true) {
      findings.add('activeWaveStatusStale:$queueId:${wave['statusAgeMs']}ms');
    }
    if (wave['activeCellStale'] == true) {
      findings.add(
        'activeWaveCellStale:$queueId:${wave['activeCellElapsedMs']}ms',
      );
    }
    if (wave['hasFailedCells'] == true) {
      findings.add('waveFailedCells:$queueId:${wave['failedCellCount']}');
    }
  }
  findings.sort();
  return findings;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
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

int _intValue(List<String> args, String key, int fallback) {
  final value = _value(args, key, '$fallback');
  return int.tryParse(value) ?? fallback;
}
