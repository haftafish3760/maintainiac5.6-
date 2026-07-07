import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_plumbing_core_readiness_audit.dart';

void main() {
  group('Plumbing Core readiness audit', () {
    test('builds the item-level readiness report without mutation', () {
      final report = buildPlumbingCoreReadinessAudit();
      _writeLatestReport(report);
      final summary = report['summary']! as Map<String, Object?>;
      final actionQueues = report['actionQueues']! as Map<String, Object?>;

      expect(
        report['schema'],
        'maintainiac.inventory.plumbing_core_readiness_audit.v1',
      );
      expect(report['scope'], 'Plumbing / Residential / Core');
      expect(summary['coreRows'], greaterThan(1000));
      expect(summary['readyForMacValidation'], isFalse);
      expect(actionQueues['finishFirst'], isA<List<Map<String, Object?>>>());
      expect(
        actionQueues['criticalMetadata'],
        isA<List<Map<String, Object?>>>(),
      );
      expect(actionQueues['parserEvidence'], isA<List<Map<String, Object?>>>());
    });

    test('separates metadata-ready candidates from release-ready items', () {
      final report = buildPlumbingCoreReadinessAudit();
      final summary = report['summary']! as Map<String, Object?>;

      expect(summary['metadataReadyCandidates'], isA<int>());
      expect(summary['releaseReadyItems'], isA<int>());
      expect(
        summary['releaseReadyItems']! as int,
        lessThanOrEqualTo(summary['metadataReadyCandidates']! as int),
      );
    });

    test('reports family queues before broad generated parser shards', () {
      final report = buildPlumbingCoreReadinessAudit();
      final families = report['familyReadiness']! as List<Map<String, Object?>>;
      final familyNames = {
        for (final family in families) family['family']! as String,
      };

      expect(familyNames, contains('push-fit fittings and valves'));
      expect(familyNames, contains('pex fittings and valves'));
      expect(familyNames, contains('pvc dwv fittings and access'));
      expect(familyNames, contains('well pressure service'));
      expect(familyNames, contains('water treatment'));
    });
  });
}

void _writeLatestReport(Map<String, Object?> report) {
  final directory = Directory('build/parser_qa_curation/plumbing_core')
    ..createSync(recursive: true);
  final latest = File(
    '${directory.path}/latest_plumbing_core_readiness_audit.json',
  );
  latest.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(report),
    flush: true,
  );
}
