import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_plumbing_core_curation_audit.dart';

void main() {
  test('writes the Plumbing Core curation audit artifact', () {
    final report = buildPlumbingCoreCurationAudit();
    final directory = Directory('build/parser_qa_curation/plumbing_core')
      ..createSync(recursive: true);
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      ':',
      '',
    );
    final encoded = const JsonEncoder.withIndent('  ').convert(report);
    final latest = File(
      '${directory.path}/latest_plumbing_core_curation_audit.json',
    );
    final stamped = File(
      '${directory.path}/plumbing_core_curation_audit_$timestamp.json',
    );

    latest.writeAsStringSync(encoded, flush: true);
    stamped.writeAsStringSync(encoded, flush: true);

    // ignore: avoid_print
    print(
      'PLUMBING_CORE_CURATION_AUDIT '
      'core=${report['coreCount']} '
      'outsideCandidates=${(report['likelyCoreOutsideCore'] as List).length} '
      'suspiciousCore=${(report['suspiciousCoreItems'] as List).length} '
      'missingFamilies=${(report['missingRequiredFamilies'] as List).length} '
      'report=${latest.path}',
    );

    expect(latest.existsSync(), isTrue);
    expect(stamped.existsSync(), isTrue);
  });
}
