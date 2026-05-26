import 'package:flutter/material.dart';

import '../../data/work_supply_models.dart';

const hvacTrade = WorkSupplyTrade(
  name: 'HVAC',
  assetPath: 'assets/material_icons/hvac.jpg',
  color: Color(0xFF4EB7C4),
  groups: [
    WorkSupplyGroup(
      name: 'Filters',
      assetPath: 'assets/material_icons/hvac/filters.jpg',
      items: filterItems,
    ),
    WorkSupplyGroup(
      name: 'Refrigerant',
      assetPath: 'assets/material_icons/hvac/refrigerant.jpg',
      items: refrigerantItems,
    ),
    WorkSupplyGroup(
      name: 'Line Sets',
      assetPath: 'assets/material_icons/hvac/line_sets.jpg',
      items: lineSetItems,
    ),
    WorkSupplyGroup(
      name: 'Thermostats',
      assetPath: 'assets/material_icons/hvac/thermostats.jpg',
      items: thermostatItems,
    ),
    WorkSupplyGroup(
      name: 'Electrical Parts',
      assetPath: 'assets/material_icons/hvac/electrical.jpg',
      items: hvacElectricalItems,
    ),
    WorkSupplyGroup(
      name: 'Consumables',
      assetPath: 'assets/material_icons/hvac/consumables.jpg',
      items: hvacConsumables,
    ),
  ],
);

const filterItems = [
  WorkSupplyItem(
    name: 'Air Filter',
    trade: 'HVAC',
    group: 'Filters',
    unit: 'each',
    assetPath: 'assets/material_icons/hvac/filters.jpg',
    sizes: [
      '16 x 20 x 1',
      '16 x 25 x 1',
      '20 x 20 x 1',
      '20 x 25 x 1',
      '20 x 25 x 4',
    ],
  ),
];
const refrigerantItems = [
  WorkSupplyItem(
    name: 'R-410A Refrigerant',
    trade: 'HVAC',
    group: 'Refrigerant',
    unit: 'pound',
    assetPath: 'assets/material_icons/hvac/refrigerant.jpg',
    purchaseUnits: ['Cylinder', 'Pound'],
  ),
  WorkSupplyItem(
    name: 'R-32 Refrigerant',
    trade: 'HVAC',
    group: 'Refrigerant',
    unit: 'pound',
    assetPath: 'assets/material_icons/hvac/refrigerant.jpg',
    purchaseUnits: ['Cylinder', 'Pound'],
  ),
  WorkSupplyItem(
    name: 'R-454B Refrigerant',
    trade: 'HVAC',
    group: 'Refrigerant',
    unit: 'pound',
    assetPath: 'assets/material_icons/hvac/refrigerant.jpg',
    purchaseUnits: ['Cylinder', 'Pound'],
  ),
];
const lineSetItems = [
  WorkSupplyItem(
    name: 'Copper Line Set',
    trade: 'HVAC',
    group: 'Line Sets',
    unit: 'foot',
    assetPath: 'assets/material_icons/hvac/line_sets.jpg',
    sizes: ['1/4 x 3/8', '1/4 x 1/2', '3/8 x 3/4', '3/8 x 7/8'],
  ),
];
const thermostatItems = [
  WorkSupplyItem(
    name: 'Basic Thermostat',
    trade: 'HVAC',
    group: 'Thermostats',
    unit: 'each',
    assetPath: 'assets/material_icons/hvac/thermostats.jpg',
  ),
  WorkSupplyItem(
    name: 'Smart Thermostat',
    trade: 'HVAC',
    group: 'Thermostats',
    unit: 'each',
    assetPath: 'assets/material_icons/hvac/thermostats.jpg',
  ),
];
const hvacElectricalItems = [
  WorkSupplyItem(
    name: 'Capacitor',
    trade: 'HVAC',
    group: 'Electrical Parts',
    unit: 'each',
    assetPath: 'assets/material_icons/hvac/electrical.jpg',
  ),
  WorkSupplyItem(
    name: 'Contactor',
    trade: 'HVAC',
    group: 'Electrical Parts',
    unit: 'each',
    assetPath: 'assets/material_icons/hvac/electrical.jpg',
  ),
  WorkSupplyItem(
    name: 'Fuse',
    trade: 'HVAC',
    group: 'Electrical Parts',
    unit: 'pack',
    assetPath: 'assets/material_icons/hvac/electrical.jpg',
  ),
];
const hvacConsumables = [
  WorkSupplyItem(
    name: 'Foil Tape',
    trade: 'HVAC',
    group: 'Consumables',
    unit: 'roll',
    assetPath: 'assets/material_icons/hvac/consumables.jpg',
  ),
  WorkSupplyItem(
    name: 'Duct Mastic',
    trade: 'HVAC',
    group: 'Consumables',
    unit: 'bucket',
    assetPath: 'assets/material_icons/hvac/sealants.jpg',
  ),
];
