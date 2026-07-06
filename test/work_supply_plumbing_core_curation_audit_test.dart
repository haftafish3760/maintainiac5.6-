import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_plumbing_core_curation_audit.dart';

void main() {
  group('Plumbing Core curation audit', () {
    test('produces a read-only professional lock report', () {
      final report = buildPlumbingCoreCurationAudit();

      expect(
        report['schema'],
        'maintainiac.inventory.plumbing_core_curation_audit.v1',
      );
      expect(report['scope'], 'Plumbing / Residential / Core');
      expect((report['coreCount']! as int), greaterThan(0));

      final rules = report['rules']! as Map<String, Object?>;
      expect(rules['noMutation'], isTrue);
      expect(rules['broadGeneratedParserWavesAllowed'], isFalse);
    });

    test('reports family coverage before broad parser waves', () {
      final report = buildPlumbingCoreCurationAudit();
      final coverage =
          report['requiredFamilyCoverage']! as List<Map<String, Object?>>;
      final familyNames = {
        for (final family in coverage) family['family']! as String,
      };

      expect(familyNames, contains('pipe fittings and adapters'));
      expect(familyNames, contains('toilet and fixture repair'));
      expect(familyNames, contains('well pump and pressure service'));
      expect(familyNames, contains('water treatment and softener service'));

      for (final family in coverage) {
        expect(family['actualRows'], isA<int>());
        expect(family['minimumRows'], isA<int>());
        expect(family['sample'], isA<List<String>>());
      }
    });

    test('surfaces candidates and suspicious rows as review queues', () {
      final report = buildPlumbingCoreCurationAudit();

      expect(
        report['likelyCoreOutsideCore'],
        isA<List<Map<String, Object?>>>(),
      );
      expect(report['suspiciousCoreItems'], isA<List<Map<String, Object?>>>());

      final summary = report['summary']! as Map<String, Object?>;
      expect(summary['readyForMacValidation'], isFalse);
      expect(summary['readinessFloor'], isA<int>());
      expect(summary['readinessAverage'], isA<double>());
    });
  });
}
