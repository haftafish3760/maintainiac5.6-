import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _footprintAuditTimeout = Timeout(Duration(minutes: 2));

void main() {
  test('receipt camera footprint audit exposes machine-readable source and artifacts', () async {
    final result = await Process.run('dart', ['run', 'tool/receipt_camera_footprint_audit.dart', '--json']);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    final report = jsonDecode(_extractJsonObject(result.stdout as String)) as Map<String, Object?>;
    final source = report['source']! as Map<String, Object?>;
    final groups = source['groups']! as Map<String, Object?>;
    final artifacts = report['artifacts']! as Map<String, Object?>;
    final androidCandidateStatuses = artifacts['androidInstallCandidateStatus']! as List<Object?>;
    final iosCandidateStatuses = artifacts['iosInstallCandidateStatus']! as List<Object?>;

    expect(report['scope'], 'receipt_camera_ocr_source');
    expect(report['excludes'], contains('tests'));
    expect(report['excludes'], contains('pdf_receipt_import_viewer'));
    expect(report['excludedPathFragments'], contains('receipt_pdf'));
    expect(report['excludes'], contains('compiled_packaging_overhead_from_source_total'));
    expect(source['totalBytes'], greaterThan(0));
    expect(source['thresholdStatus'], 'ok');
    expect(source['totalBytes'] as int, lessThan(source['reviewThresholdBytes'] as int));
    expect(source['totalLabel'], isA<String>());
    expect(source['fileCount'], greaterThan(0));
    expect(groups.keys, contains('receipt_capture_dart'));
    expect(groups.keys, contains('shared_receipt_contracts'));
    expect(groups.keys, contains('android_native_receipt_camera'));
    expect(groups.keys, contains('ios_native_receipt_camera'));
    expect(artifacts['android'], isA<List<Object?>>());
    expect(artifacts['ios'], isA<List<Object?>>());
    expect(artifacts['androidInstallCandidateBlockBytes'], greaterThan(0));
    expect(artifacts['iosInstallCandidateBlockBytes'], greaterThan(0));
    expect(androidCandidateStatuses, isNotEmpty);
    expect(iosCandidateStatuses, isNotEmpty);
    for (final status in [...androidCandidateStatuses, ...iosCandidateStatuses]) {
      final item = status! as Map<String, Object?>;
      final path = item['path']! as String;
      expect(path, isNot(endsWith('app-debug.apk')));
      expect(path, isNot(endsWith('app-release.apk')));
      expect(item['status'], 'ok', reason: '${item['path']} is oversized');
    }
  }, timeout: _footprintAuditTimeout);
}

String _extractJsonObject(String output) {
  final start = output.indexOf('{');
  final end = output.lastIndexOf('}');
  if (start < 0 || end <= start) {
    throw FormatException('No JSON object found in output.', output);
  }
  return output.substring(start, end + 1);
}
