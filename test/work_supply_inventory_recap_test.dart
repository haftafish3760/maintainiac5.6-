import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_recap.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

void main() {
  const item = WorkSupplyItem(
    id: 'TEST',
    name: 'Test supply',
    trade: 'Plumbing',
    category: 'Fittings',
    system: 'Copper',
    itemType: '90 Elbows',
    variant: '1/2 in',
    unit: 'each',
  );

  test('month recap uses calendar month boundaries', () {
    final records = [
      _record(item, DateTime.utc(2026, 1, 31), 10),
      _record(item, DateTime.utc(2026, 2, 1), 20),
      _record(item, DateTime.utc(2026, 2, 28), 30),
      _record(item, DateTime.utc(2026, 3, 1), 40),
    ];

    final february = buildWorkSupplyMonthRecap(
      records: records,
      month: DateTime.utc(2026, 2, 12),
    );

    expect(february.totalSpent, 50);
    expect(february.itemCount, 2);
    expect(february.start, DateTime.utc(2026, 2));
    expect(february.end, DateTime.utc(2026, 2, 28));
  });

  test('rolling recaps are separate from calendar month recap', () {
    final records = [
      _record(item, DateTime.utc(2026, 1, 30), 10),
      _record(item, DateTime.utc(2026, 2, 1), 20),
      _record(item, DateTime.utc(2026, 2, 28), 30),
    ];

    final recaps = buildWorkSupplyInventoryRecaps(
      records: records,
      today: DateTime.utc(2026, 2, 28),
    );

    final thirtyDays = recaps.singleWhere(
      (recap) => recap.label == 'Past 30 Days',
    );
    final thisMonth = recaps.singleWhere(
      (recap) => recap.label == 'This Month',
    );

    expect(thirtyDays.totalSpent, 60);
    expect(thisMonth.totalSpent, 50);
  });
}

WorkSupplyInventoryRecord _record(
  WorkSupplyItem item,
  DateTime loggedAt,
  double subtotal,
) {
  return WorkSupplyInventoryRecord(
    item: item,
    onHand: 1,
    threshold: 1,
    lastUnitCost: subtotal,
    storageArea: 'Company inventory',
    receiptLinked: true,
    lineSubtotal: subtotal,
    loggedAt: loggedAt,
  );
}
