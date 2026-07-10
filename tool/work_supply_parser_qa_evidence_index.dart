import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_evidence_index.dart '
    '[--root build/parser_qa_batch_waves] '
    '[--output build/parser_qa_batch_waves/latest_evidence_index.json]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaEvidenceIndex(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaEvidenceIndex(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final root = _value(args, 'root', 'build/parser_qa_batch_waves');
  final output = _value(args, 'output', '$root/latest_evidence_index.json');
  final rootDir = Directory(root);
  if (!rootDir.existsSync()) {
    stderr.writeln('Evidence root not found: $root');
    return 66;
  }
  final waves = <Map<String, Object?>>[];
  for (final entity in rootDir.listSync()) {
    if (entity is! Directory) continue;
    final summary = File('${entity.path}/wave_summary.json');
    final plan = File('${entity.path}/wave_plan.json');
    if (!summary.existsSync() && !plan.existsSync()) continue;
    final source = summary.existsSync() ? summary : plan;
    final json = jsonDecode(source.readAsStringSync()) as Map;
    waves.add({
      'waveId': json['waveId'] ?? entity.uri.pathSegments.last,
      'qaLayer': json['qaLayer'],
      'dryRun': json['dryRun'],
      'wavePath': entity.path,
      'waveSummaryPath': summary.existsSync() ? summary.path : '',
      'wavePlanPath': plan.existsSync() ? plan.path : '',
      'queueSummaryPath': json['queueSummaryPath'] ?? '',
      'liveServicesAllowed': json['liveServicesAllowed'] ?? false,
      'writesProductionCatalog': json['writesProductionCatalog'] ?? false,
      'firebaseWritesAllowed': json['firebaseWritesAllowed'] ?? false,
      'ocrCameraExpensesTouched': json['ocrCameraExpensesTouched'] ?? false,
    });
  }
  waves.sort((a, b) => a['waveId'].toString().compareTo(b['waveId'].toString()));
  final unsafe = waves.any(
    (wave) =>
        wave['liveServicesAllowed'] == true ||
        wave['writesProductionCatalog'] == true ||
        wave['firebaseWritesAllowed'] == true ||
        wave['ocrCameraExpensesTouched'] == true,
  );
  final report = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_evidence_index',
    'root': root,
    'waveCount': waves.length,
    'unsafe': unsafe,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
    'waves': waves,
  };
  final json = const JsonEncoder.withIndent('  ').convert(report);
  File(output)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(json, flush: true);
  stdout.writeln('QA_EVIDENCE_INDEX $json');
  stdout.writeln('QA_EVIDENCE_INDEX_ARTIFACT json=$output');
  return unsafe ? 1 : 0;
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
