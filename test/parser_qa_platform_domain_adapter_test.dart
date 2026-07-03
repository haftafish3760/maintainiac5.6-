import 'package:flutter_test/flutter_test.dart';

import 'support/parser_qa_platform/parser_qa_platform.dart';

void main() {
  test(
    'domain adapters keep inventory and maintenance on the shared platform',
    () {
      final inventory = workSupplyParserDomainAdapter.toJson();
      final expense = expenseReceiptParserDomainAdapter.toJson();
      final maintenance = maintenanceParserDomainAdapter.toJson();

      expect(inventory['domain'], 'work_supply_inventory_parser');
      expect(expense['domain'], 'expense_receipt_parser');
      expect(maintenance['domain'], 'maintenance_parser');
      expect(inventory['artifactPrefix'], isNot(maintenance['artifactPrefix']));
      expect(expense['artifactPrefix'], isNot(inventory['artifactPrefix']));
      expect(
        inventory['supportedResultUses'].toString(),
        contains('estimate_materials'),
      );
      expect(
        expense['supportedResultUses'].toString(),
        contains('expense_ledger'),
      );
      expect(
        maintenance['supportedResultUses'].toString(),
        contains('work_order'),
      );
      expect(inventory['firebaseWritesAllowed'], isFalse);
      expect(expense['liveServicesAllowed'], isFalse);
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

  test('expense parser adapter stays out of camera and OCR implementation', () {
    expect(
      expenseReceiptParserDomainAdapter.forbiddenBoundaryTokens,
      containsAll(['CameraController', 'GoogleVision', 'MLKit']),
    );
    expect(
      expenseReceiptParserDomainAdapter.supportedResultUses,
      containsAll(['expense_draft', 'expense_review', 'expense_ledger']),
    );
    expect(
      expenseReceiptParserDomainAdapter.supportedResultUses,
      isNot(contains('camera_capture')),
    );
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
