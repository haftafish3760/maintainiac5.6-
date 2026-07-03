import 'dart:convert';
import 'dart:io';

PipelineArtifact writePipelineSummary({
  required String outputDirectory,
  required Map<String, Object?> summary,
}) {
  final directory = Directory(outputDirectory)..createSync(recursive: true);
  final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
    RegExp(r'[:.]'),
    '',
  );
  final timestamped = File('${directory.path}/pipeline_summary_$stamp.json');
  final latest = File('${directory.path}/latest_pipeline_summary.json');
  final encoded = const JsonEncoder.withIndent('  ').convert({
    ...summary,
    'generatedAtIso': DateTime.now().toUtc().toIso8601String(),
  });
  timestamped.writeAsStringSync(encoded, flush: true);
  latest.writeAsStringSync(encoded, flush: true);
  return PipelineArtifact(
    timestampedJsonPath: timestamped.path,
    latestJsonPath: latest.path,
  );
}

class PipelineArtifact {
  const PipelineArtifact({
    required this.timestampedJsonPath,
    required this.latestJsonPath,
  });

  final String timestampedJsonPath;
  final String latestJsonPath;
}
