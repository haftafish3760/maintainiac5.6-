import 'dart:io';
import 'dart:math';

import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

void main() {
  final random = Random();
  for (final trade in ['Plumbing', 'Electrical', 'HVAC']) {
    final items =
        workSupplyCatalogItems
            .where(
              (item) =>
                  item.trade == trade &&
                  item.packTier == WorkSupplyPackTier.core,
            )
            .toList()
          ..shuffle(random);
    stdout.writeln('\n$trade (${items.length} Core items available)');
    for (final item in items.take(30)) {
      stdout.writeln(
        '${item.id} | ${item.name} | aliases=${item.aliases.join(', ')} | '
        'priority=${item.parserPriority.name}',
      );
    }
  }
}
