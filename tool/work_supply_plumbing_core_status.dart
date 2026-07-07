import 'dart:convert';
import 'dart:io';

const _defaultReportPath =
    'build/parser_qa_curation/plumbing_core/latest_plumbing_core_readiness_audit.json';

void main(List<String> args) {
  final reportPath = _argValue(args, '--report') ?? _defaultReportPath;
  final limit = int.tryParse(_argValue(args, '--limit') ?? '') ?? 20;
  final familyFilter = (_argValue(args, '--family') ?? '').trim().toLowerCase();
  final file = File(reportPath);
  if (!file.existsSync()) {
    stderr.writeln('Missing Plumbing Core readiness report: $reportPath');
    exitCode = 2;
    return;
  }

  final report = (jsonDecode(file.readAsStringSync()) as Map)
      .cast<String, Object?>();
  final summary = (report['summary'] as Map).cast<String, Object?>();
  final families = [
    for (final entry in report['familyReadiness'] as List<dynamic>)
      (entry as Map).cast<String, Object?>(),
  ];
  final items = [
    for (final entry in report['items'] as List<dynamic>)
      (entry as Map).cast<String, Object?>(),
  ];

  stdout.writeln(
    'PLUMBING_CORE_STATUS '
    'core=${summary['coreRows']} '
    'releaseReady=${summary['releaseReadyItems']} '
    'metadataReady=${summary['metadataReadyCandidates']} '
    'needsWork=${summary['needsWorkItems']} '
    'critical=${summary['criticalItems']} '
    'average=${summary['readinessAverage']} '
    'macReady=${summary['readyForMacValidation']}',
  );
  stdout.writeln('FAMILIES');
  for (final family in families) {
    if (familyFilter.isNotEmpty &&
        family['family'].toString().toLowerCase() != familyFilter) {
      continue;
    }
    stdout.writeln(
      '${family['family']}: '
      '${family['releaseReady']}/${family['total']} release-ready, '
      '${family['critical']} critical, next=${family['nextAction']}',
    );
  }

  final queue =
      items
          .where(
            (item) =>
                item['status'] != 'release_ready_candidate' &&
                (familyFilter.isEmpty ||
                    item['family'].toString().toLowerCase() == familyFilter),
          )
          .toList(growable: false)
        ..sort((left, right) {
          final leftScore = left['readinessPercent'] as int;
          final rightScore = right['readinessPercent'] as int;
          final byScore = rightScore.compareTo(leftScore);
          if (byScore != 0) return byScore;
          return left['name'].toString().compareTo(right['name'].toString());
        });

  stdout.writeln(
    'NEXT_BATCH limit=$limit family=${familyFilter.ifEmpty('all')}',
  );
  for (final item in queue.take(limit)) {
    stdout.writeln(
      '${item['id']} | ${item['family']} | ${item['readinessPercent']} | '
      '${item['name']} | issues=${(item['issues'] as List).join(',')} | '
      'warnings=${(item['warnings'] as List).join(',')}',
    );
  }
}

String? _argValue(List<String> args, String name) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == name && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('$name=')) return arg.substring(name.length + 1);
  }
  return null;
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
