import 'package:flutter_test/flutter_test.dart';

import 'support/parser_qa_platform/parser_qa_platform.dart';

void main() {
  test(
    'domain adapters keep inventory and maintenance on the shared platform',
    () {
      final inventory = workSupplyParserDomainAdapter.toJson();
      final maintenance = maintenanceParserDomainAdapter.toJson();

      expect(inventory['domain'], 'work_supply_inventory_parser');
      expect(maintenance['domain'], 'maintenance_parser');
      expect(inventory['artifactPrefix'], isNot(maintenance['artifactPrefix']));
      expect(
        inventory['supportedResultUses'].toString(),
        contains('estimate_materials'),
      );
      expect(
        maintenance['supportedResultUses'].toString(),
        contains('work_order'),
      );
      expect(inventory['firebaseWritesAllowed'], isFalse);
      expect(maintenance['ocrCameraExpensesTouched'], isFalse);
    },
  );

  test('all registered domain adapters satisfy the reusable contract', () {
    for (final adapter in parserQaDomainAdapters) {
      expect(
        adapter.validateContract(),
        isEmpty,
        reason: '${adapter.domain} should be safe to run on the QA platform.',
      );
      expect(
        adapter.forbiddenBoundaryTokens,
        contains('FirebaseFirestore.instance'),
      );
      expect(adapter.toJson()['liveServicesAllowed'], isFalse);
      expect(adapter.toJson()['writesProductionCatalog'], isFalse);
      expect(adapter.toJson()['firebaseWritesAllowed'], isFalse);
      expect(adapter.toJson()['ocrCameraExpensesTouched'], isFalse);
    }
  });

  test('domain adapter contract rejects unsafe incomplete domains', () {
    const adapter = ParserQaDomainAdapter(
      domain: '',
      artifactPrefix: 'parser',
      fixtureRoot: '',
      forbiddenBoundaryTokens: ['ocr', 'OCR'],
      supportedResultUses: ['inventory', 'inventory'],
    );

    final failures = adapter.validateContract();

    expect(failures, contains('domain must not be empty'));
    expect(failures, contains('fixtureRoot must not be empty'));
    expect(failures, contains('forbiddenBoundaryTokens must be unique'));
    expect(failures, contains('supportedResultUses must be unique'));
  });
}
