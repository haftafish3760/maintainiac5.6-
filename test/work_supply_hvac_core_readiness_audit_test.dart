import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_hvac_core_readiness_audit.dart';

void main() {
  group('HVAC Core readiness audit', () {
    test('builds the item-level readiness report without mutation', () {
      final report = buildHvacCoreReadinessAudit();
      _writeLatestReport(report);
      final summary = report['summary']! as Map<String, Object?>;
      final actionQueues = report['actionQueues']! as Map<String, Object?>;

      expect(
        report['schema'],
        'maintainiac.inventory.hvac_core_readiness_audit.v1',
      );
      expect(report['scope'], 'HVAC / Residential / Core');
      expect(summary['coreRows'], greaterThan(0));
      expect(summary['metadataReadyCandidates'], isA<int>());
      expect(summary['releaseReadyItems'], isA<int>());
      expect(summary['criticalItems'], isA<int>());
      expect(actionQueues['finishFirst'], isA<List<Map<String, Object?>>>());
      expect(
        actionQueues['criticalMetadata'],
        isA<List<Map<String, Object?>>>(),
      );
      expect(actionQueues['parserEvidence'], isA<List<Map<String, Object?>>>());
    });

    test('reports required HVAC Core families', () {
      final report = buildHvacCoreReadinessAudit();
      final families = report['familyReadiness']! as List<Map<String, Object?>>;
      final familyNames = {
        for (final family in families) family['family']! as String,
      };

      expect(familyNames, contains('air filters'));
      expect(familyNames, contains('controls and electrical'));
      expect(familyNames, contains('condensate'));
      expect(familyNames, contains('tape sealants and duct repair'));
      expect(familyNames, contains('ignition and gas heat'));
      expect(familyNames, contains('motors and blower parts'));
    });

    test('does not claim Mac validation until all Core rows are ready', () {
      final report = buildHvacCoreReadinessAudit();
      final summary = report['summary']! as Map<String, Object?>;
      final ready = summary['readyForMacValidation']! as bool;
      final releaseReady = summary['releaseReadyItems']! as int;
      final coreRows = summary['coreRows']! as int;
      final critical = summary['criticalItems']! as int;

      if (ready) {
        expect(releaseReady, coreRows);
        expect(critical, 0);
      } else {
        expect(releaseReady < coreRows || critical > 0, isTrue);
      }
    });
  });
}

void _writeLatestReport(Map<String, Object?> report) {
  final directory = Directory('build/parser_qa_curation/hvac_core')
    ..createSync(recursive: true);
  final latest = File(
    '${directory.path}/latest_hvac_core_readiness_audit.json',
  );
  latest.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(report),
    flush: true,
  );
}
