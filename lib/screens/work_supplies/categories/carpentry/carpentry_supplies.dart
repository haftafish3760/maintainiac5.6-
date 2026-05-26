import 'package:flutter/material.dart';

import '../../data/work_supply_models.dart';

const carpentryTrade = WorkSupplyTrade(
  name: 'Carpentry',
  assetPath: 'assets/material_icons/carpentry.jpg',
  color: Color(0xFFB57742),
  groups: [
    WorkSupplyGroup(
      name: 'Lumber',
      assetPath: 'assets/material_icons/carpentry/lumber.jpg',
      items: lumberItems,
    ),
    WorkSupplyGroup(
      name: 'Sheet Goods',
      assetPath: 'assets/material_icons/carpentry/sheet_goods.jpg',
      items: sheetItems,
    ),
    WorkSupplyGroup(
      name: 'Trim',
      assetPath: 'assets/material_icons/carpentry/trim.jpg',
      items: trimItems,
    ),
    WorkSupplyGroup(
      name: 'Fasteners',
      assetPath: 'assets/material_icons/carpentry/fasteners.jpg',
      items: fastenerItems,
    ),
    WorkSupplyGroup(
      name: 'Adhesives',
      assetPath: 'assets/material_icons/carpentry/adhesives.jpg',
      items: adhesiveItems,
    ),
    WorkSupplyGroup(
      name: 'Consumables',
      assetPath: 'assets/material_icons/carpentry/consumables.jpg',
      items: carpentryConsumables,
    ),
  ],
);

const lumberItems = [
  WorkSupplyItem(
    name: '2 x 4 Lumber',
    trade: 'Carpentry',
    group: 'Lumber',
    unit: 'piece',
    assetPath: 'assets/material_icons/carpentry/lumber.jpg',
    sizes: ['8 ft', '10 ft', '12 ft'],
  ),
  WorkSupplyItem(
    name: '2 x 6 Lumber',
    trade: 'Carpentry',
    group: 'Lumber',
    unit: 'piece',
    assetPath: 'assets/material_icons/carpentry/lumber.jpg',
    sizes: ['8 ft', '10 ft', '12 ft'],
  ),
];
const sheetItems = [
  WorkSupplyItem(
    name: 'Plywood',
    trade: 'Carpentry',
    group: 'Sheet Goods',
    unit: 'sheet',
    assetPath: 'assets/material_icons/carpentry/sheet_goods.jpg',
    sizes: ['1/4 in', '1/2 in', '3/4 in'],
  ),
  WorkSupplyItem(
    name: 'OSB',
    trade: 'Carpentry',
    group: 'Sheet Goods',
    unit: 'sheet',
    assetPath: 'assets/material_icons/carpentry/sheet_goods.jpg',
  ),
];
const trimItems = [
  WorkSupplyItem(
    name: 'Baseboard',
    trade: 'Carpentry',
    group: 'Trim',
    unit: 'foot',
    assetPath: 'assets/material_icons/carpentry/trim.jpg',
  ),
  WorkSupplyItem(
    name: 'Casing',
    trade: 'Carpentry',
    group: 'Trim',
    unit: 'foot',
    assetPath: 'assets/material_icons/carpentry/trim.jpg',
  ),
  WorkSupplyItem(
    name: 'Quarter Round',
    trade: 'Carpentry',
    group: 'Trim',
    unit: 'foot',
    assetPath: 'assets/material_icons/carpentry/trim.jpg',
  ),
];
const fastenerItems = [
  WorkSupplyItem(
    name: 'Deck Screws',
    trade: 'Carpentry',
    group: 'Fasteners',
    unit: 'box',
    assetPath: 'assets/material_icons/carpentry/fasteners.jpg',
  ),
  WorkSupplyItem(
    name: 'Trim Nails',
    trade: 'Carpentry',
    group: 'Fasteners',
    unit: 'box',
    assetPath: 'assets/material_icons/carpentry/fasteners.jpg',
  ),
  WorkSupplyItem(
    name: 'Drywall Screws',
    trade: 'Carpentry',
    group: 'Fasteners',
    unit: 'box',
    assetPath: 'assets/material_icons/carpentry/fasteners.jpg',
  ),
];
const adhesiveItems = [
  WorkSupplyItem(
    name: 'Construction Adhesive',
    trade: 'Carpentry',
    group: 'Adhesives',
    unit: 'tube',
    assetPath: 'assets/material_icons/carpentry/adhesives.jpg',
  ),
  WorkSupplyItem(
    name: 'Wood Glue',
    trade: 'Carpentry',
    group: 'Adhesives',
    unit: 'bottle',
    assetPath: 'assets/material_icons/carpentry/adhesives.jpg',
  ),
];
const carpentryConsumables = [
  WorkSupplyItem(
    name: 'Sandpaper',
    trade: 'Carpentry',
    group: 'Consumables',
    unit: 'pack',
    assetPath: 'assets/material_icons/carpentry/consumables.jpg',
  ),
  WorkSupplyItem(
    name: 'Rags',
    trade: 'Carpentry',
    group: 'Consumables',
    unit: 'pack',
    assetPath: 'assets/material_icons/carpentry/consumables.jpg',
  ),
];
