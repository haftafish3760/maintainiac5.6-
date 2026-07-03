import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test(
    'parser consumer gate validates inventory and expense consumers together',
    () {
      const gate = maintainiacParserConsumerGate;

      expect(gate.validate(), isEmpty);
      expect(gate.inventory.domain, 'work_supply_inventory_parser');
      expect(gate.expense.domain, 'expense_receipt_parser');
      expect(gate.toJson()['consumerCount'], 2);
      expect(gate.toJson()['totalFamilyCount'], greaterThanOrEqualTo(20));
      expect(gate.toJson()['liveServicesAllowed'], isFalse);
      expect(gate.toJson()['firebaseWritesAllowed'], isFalse);
      expect(gate.toJson()['ocrCameraImplementationTouched'], isFalse);
    },
  );

  test('parser consumer gate rejects unsafe or narrow consumers', () {
    const badGate = MaintainiacParserConsumerGate(
      inventory: MaintainiacInventoryParserConsumerContract(
        domain: 'work_supply_inventory_parser',
        locale: 'en-US',
        country: 'US',
        liveServicesAllowed: true,
        supportedResultUses: {'inventory'},
        releaseTrades: {'plumbing'},
        packLevels: {'core'},
        families: [],
      ),
      expense: MaintainiacExpenseParserConsumerContract(
        domain: 'expense_receipt_parser',
        locale: 'en-US',
        country: 'US',
        firebaseWritesAllowed: true,
        ocrCameraImplementationTouched: true,
        supportedResultUses: {'expense_review'},
        families: [],
      ),
    );

    final failures = badGate.validate().join('\n');

    expect(
      failures,
      contains('inventory:inventory consumer missing release-one trades'),
    );
    expect(
      failures,
      contains('expense:expense consumer missing result-use routing coverage'),
    );
    expect(failures, contains('parser consumers must not allow live services'));
    expect(
      failures,
      contains('parser consumers must not allow Firebase writes'),
    );
    expect(
      failures,
      contains('parser consumers must not touch OCR/camera implementation'),
    );
    expect(
      failures,
      contains('parser consumer gate needs at least 20 QA families'),
    );
  });
}
