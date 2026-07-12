import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

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

    test('locks the current Plumbing Core curation baseline', () {
      final report = buildPlumbingCoreCurationAudit();

      expect(report['coreCount'], 1261);
      expect(report['missingRequiredFamilies'], isEmpty);
      expect(report['suspiciousCoreItems'], isEmpty);
      expect(report['likelyCoreOutsideCore'], isEmpty);

      final summary = report['summary']! as Map<String, Object?>;
      expect(summary['suspiciousCoreTotal'], 0);
      expect(summary['likelyCoreOutsideCoreTotal'], 0);
      // These values lock the reviewed catalog-audit snapshot. They are not a
      // release readiness claim; that remains false until real receipt QA.
      expect(summary['readinessFloor'], 56);
      expect(summary['readinessAverage'], 77.5);
      expect(summary['readyForMacValidation'], isFalse);

      final items = {
        for (final item in workSupplyCatalogItems) item.name: item,
      };
      expect(
        items['1-1/4 x 12 in Tailpiece']!.packTier,
        WorkSupplyPackTier.core,
      );
      expect(
        items['1-1/2 x 12 in Tubular Extension Tube']!.packTier,
        WorkSupplyPackTier.core,
      );
      expect(
        items['12 in No-Hub Coupling']!.packTier,
        isNot(WorkSupplyPackTier.core),
      );
      expect(
        items['1/2 x 2 in Black Iron Nipple']!.packTier,
        isNot(WorkSupplyPackTier.core),
      );
      expect(
        items['3/4 x 4 in Black Iron Nipple']!.packTier,
        WorkSupplyPackTier.core,
      );
      expect(
        items['3/8 in Brass Compression Union']!.packTier,
        WorkSupplyPackTier.core,
      );
      expect(
        items['1/4 in Push-Fit Cap']!.packTier,
        isNot(WorkSupplyPackTier.core),
      );
      expect(
        items['stainless kitchen basket strainer Sink Drain Finish Part']!
            .packTier,
        WorkSupplyPackTier.core,
      );
      expect(
        items['1/2 hp Well Pump Control Box']!.packTier,
        WorkSupplyPackTier.core,
      );
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

    test('Plumbing service-truck stock resolves to Core', () {
      final drift = workSupplyCatalogItems
          .where(
            (item) =>
                item.trade == 'Plumbing' &&
                item.category == 'Service Truck Stock' &&
                item.packTier != WorkSupplyPackTier.core,
          )
          .map((item) => '${item.id}: ${item.name} (${item.packTier.name})')
          .toList(growable: false);

      expect(
        drift,
        isEmpty,
        reason:
            'Plumbing Service Truck Stock must stay Core; otherwise common '
            'same-day water treatment, drain, and repair rows can fall into '
            'later packs.\n${drift.take(50).join('\n')}',
      );
    });
  });
}
