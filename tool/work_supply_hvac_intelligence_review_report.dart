import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';

void main() {
  final reviewItems =
      workSupplyCatalogItems
          .where(
            (item) => item.trade == 'HVAC' && item.intelligence.needsReview,
          )
          .toList(growable: false)
        ..sort((left, right) => left.name.compareTo(right.name));
  final rows = [
    for (final item in reviewItems)
      {
        'id': item.id,
        'name': item.name,
        'system': item.system,
        'itemType': item.itemType,
        'variant': item.variant,
        'missing': [
          if (item.intelligence.material.isEmpty) 'material',
          if (item.intelligence.size.isEmpty) 'size',
          if (item.intelligence.shapeOrStyle.isEmpty) 'shape',
        ],
      },
  ];
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'schema': 'maintainiac.inventory.hvac_intelligence_review.v1',
      'count': rows.length,
      'items': rows,
    }),
  );
}
