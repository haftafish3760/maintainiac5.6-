import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('financial ledger probe totals expenses deterministically', () {
    const probe = MaintainiacFinancialLedgerProbe();
    final summary = probe.summarize([
      const MaintainiacLedgerLine(
        id: 'fuel_1',
        category: 'fuel',
        amountCents: 5000,
        taxCents: 250,
      ),
      const MaintainiacLedgerLine(
        id: 'meal_1',
        category: 'meals',
        amountCents: 1200,
        business: false,
        refundCents: 200,
      ),
      const MaintainiacLedgerLine(
        id: 'material_1',
        category: 'materials',
        amountCents: 3000,
        discountCents: 500,
      ),
    ]);

    probe.assertBalanced(summary);
    expect(summary.totalCents, 8750);
    expect(summary.businessCents, 7750);
    expect(summary.personalCents, 1000);
    expect(summary.byCategory['fuel'], 5250);
    expect(summary.byCategory['meals'], 1000);
    expect(summary.byCategory['materials'], 2500);
  });

  test('financial ledger probe models inventory consumption cost', () {
    const probe = MaintainiacFinancialLedgerProbe();
    final line = probe.inventoryConsumption(
      id: 'job_material_1',
      unitCostCents: 275,
      quantity: 8,
      sourceId: 'inventory_move_1',
    );
    final summary = probe.summarize([line]);

    probe.assertBalanced(summary);
    expect(line.netCents, 2200);
    expect(line.sourceId, 'inventory_move_1');
    expect(summary.byCategory['materials'], 2200);
  });

  test('financial ledger probe rejects unsafe money lines', () {
    const probe = MaintainiacFinancialLedgerProbe();

    expect(
      () => probe.summarize([
        const MaintainiacLedgerLine(id: '', category: 'fuel', amountCents: 1),
      ]),
      throwsArgumentError,
    );
    expect(
      () => probe.inventoryConsumption(
        id: 'bad',
        unitCostCents: 100,
        quantity: 0,
        sourceId: 'move',
      ),
      throwsArgumentError,
    );
  });
}
