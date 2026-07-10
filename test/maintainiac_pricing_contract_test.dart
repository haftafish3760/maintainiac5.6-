import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test(
    'pricing contract balances estimate and invoice line totals in cents',
    () {
      const contract = MaintainiacPricingContract([
        MaintainiacPricedLine(
          id: 'material_line_1',
          sourceId: 'inventory_item_1',
          unitCostCents: 1000,
          quantity: 3,
          taxCents: 180,
          markupBasisPoints: 1500,
        ),
        MaintainiacPricedLine(
          id: 'material_line_2',
          sourceId: 'expense_receipt_1',
          unitCostCents: 250,
          quantity: 4,
          taxCents: 63,
          discountCents: 100,
        ),
      ]);

      expect(contract.validate(), isEmpty);
      expect(contract.subtotalCents, 4000);
      expect(contract.taxCents, 243);
      expect(contract.markupCents, 450);
      expect(contract.discountCents, 100);
      expect(contract.totalCents, 4593);
    },
  );

  test(
    'pricing contract allocates tax remainders deterministically per unit',
    () {
      const line = MaintainiacPricedLine(
        id: 'tax_split_1',
        sourceId: 'receipt_line_1',
        unitCostCents: 1000,
        quantity: 4,
        taxCents: 101,
      );

      expect(line.allocateTaxPerUnit(), [26, 25, 25, 25]);
      expect(
        line.allocateTaxPerUnit().fold(0, (sum, cents) => sum + cents),
        101,
      );
    },
  );

  test('pricing contract rejects unsafe money and source mutation', () {
    const contract = MaintainiacPricingContract([
      MaintainiacPricedLine(
        id: 'bad_negative',
        sourceId: 'source_1',
        unitCostCents: -1,
        quantity: 1,
      ),
      MaintainiacPricedLine(
        id: 'bad_discount',
        sourceId: 'source_2',
        unitCostCents: 100,
        quantity: 1,
        discountCents: 200,
      ),
      MaintainiacPricedLine(
        id: 'bad_mutation',
        sourceId: 'inventory_1',
        unitCostCents: 100,
        quantity: 1,
        sourceMutationAllowed: true,
      ),
    ]);

    final failures = contract.validate().join('\n');

    expect(failures, contains('unit cost must not be negative'));
    expect(failures, contains('discount cannot exceed line total'));
    expect(failures, contains('must not mutate source data'));
  });
}
