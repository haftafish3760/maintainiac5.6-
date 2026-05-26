import 'package:flutter/material.dart';

import '../../data/work_supply_models.dart';

const electricalTrade = WorkSupplyTrade(
  name: 'Electrical',
  assetPath: 'assets/material_icons/electrical.jpg',
  color: Color(0xFFF6B73C),
  groups: [
    WorkSupplyGroup(
      name: 'Wiring and Cable',
      assetPath: 'assets/material_icons/electrical/wiring_cable.jpg',
      items: wireItems,
    ),
    WorkSupplyGroup(
      name: 'Breakers',
      assetPath: 'assets/material_icons/electrical/breakers.jpg',
      items: breakerItems,
    ),
    WorkSupplyGroup(
      name: 'Outlets',
      assetPath: 'assets/material_icons/electrical/outlets.jpg',
      items: outletItems,
    ),
    WorkSupplyGroup(
      name: 'Switches',
      assetPath: 'assets/material_icons/electrical/switches.jpg',
      items: switchItems,
    ),
    WorkSupplyGroup(
      name: 'Boxes',
      assetPath: 'assets/material_icons/electrical/junction_boxes.jpg',
      items: boxItems,
    ),
    WorkSupplyGroup(
      name: 'Connectors',
      assetPath: 'assets/material_icons/electrical/connectors.jpg',
      items: connectorItems,
    ),
    WorkSupplyGroup(
      name: 'Consumables',
      assetPath: 'assets/material_icons/electrical/consumables.jpg',
      items: electricalConsumables,
    ),
  ],
);

const wireItems = [
  WorkSupplyItem(
    name: 'Romex NM-B Cable',
    trade: 'Electrical',
    group: 'Wiring and Cable',
    unit: 'foot',
    assetPath: 'assets/material_icons/electrical/wire/nmb_cable.jpg',
    keywords: ['romex', 'nmb', 'house wire'],
    purchaseUnits: ['Roll', 'Foot'],
    sizes: ['14/2', '14/3', '12/2', '12/3', '10/2', '10/3'],
  ),
  WorkSupplyItem(
    name: 'UF-B Cable',
    trade: 'Electrical',
    group: 'Wiring and Cable',
    unit: 'foot',
    assetPath: 'assets/material_icons/electrical/wire/uf_b_cable.jpg',
    keywords: ['underground feeder'],
    purchaseUnits: ['Roll', 'Foot'],
    sizes: ['14/2', '12/2', '10/2'],
  ),
  WorkSupplyItem(
    name: 'THHN Wire',
    trade: 'Electrical',
    group: 'Wiring and Cable',
    unit: 'foot',
    assetPath: 'assets/material_icons/electrical/wire/thhn_wire.jpg',
    purchaseUnits: ['Spool', 'Foot'],
    sizes: ['14 AWG', '12 AWG', '10 AWG', '8 AWG', '6 AWG'],
  ),
  WorkSupplyItem(
    name: 'Low Voltage Wire',
    trade: 'Electrical',
    group: 'Wiring and Cable',
    unit: 'foot',
    assetPath: 'assets/material_icons/electrical/wire/low_voltage_wire.jpg',
    keywords: ['thermostat wire', 'doorbell wire'],
  ),
];

const breakerItems = [
  WorkSupplyItem(
    name: 'Standard Breaker',
    trade: 'Electrical',
    group: 'Breakers',
    unit: 'each',
    assetPath: 'assets/material_icons/electrical/breakers.jpg',
    sizes: ['15 Amp', '20 Amp', '30 Amp', '40 Amp', '50 Amp', '60 Amp'],
  ),
  WorkSupplyItem(
    name: 'GFCI Breaker',
    trade: 'Electrical',
    group: 'Breakers',
    unit: 'each',
    assetPath: 'assets/material_icons/electrical/breakers.jpg',
    sizes: ['15 Amp', '20 Amp', '30 Amp', '50 Amp'],
  ),
  WorkSupplyItem(
    name: 'AFCI Breaker',
    trade: 'Electrical',
    group: 'Breakers',
    unit: 'each',
    assetPath: 'assets/material_icons/electrical/breakers.jpg',
    sizes: ['15 Amp', '20 Amp'],
  ),
  WorkSupplyItem(
    name: 'Dual Function Breaker',
    trade: 'Electrical',
    group: 'Breakers',
    unit: 'each',
    assetPath: 'assets/material_icons/electrical/breakers.jpg',
    sizes: ['15 Amp', '20 Amp'],
  ),
];

const outletItems = [
  WorkSupplyItem(
    name: 'Duplex Outlet',
    trade: 'Electrical',
    group: 'Outlets',
    unit: 'each',
    assetPath: 'assets/material_icons/electrical/outlets.jpg',
    sizes: ['15 Amp', '20 Amp'],
  ),
  WorkSupplyItem(
    name: 'GFCI Outlet',
    trade: 'Electrical',
    group: 'Outlets',
    unit: 'each',
    assetPath: 'assets/material_icons/electrical/outlets.jpg',
    sizes: ['15 Amp', '20 Amp'],
  ),
  WorkSupplyItem(
    name: 'Weather Resistant GFCI',
    trade: 'Electrical',
    group: 'Outlets',
    unit: 'each',
    assetPath: 'assets/material_icons/electrical/outlets.jpg',
  ),
];

const switchItems = [
  WorkSupplyItem(
    name: 'Single Pole Switch',
    trade: 'Electrical',
    group: 'Switches',
    unit: 'each',
    assetPath: 'assets/material_icons/electrical/switches.jpg',
    keywords: ['light switch'],
  ),
  WorkSupplyItem(
    name: 'Three-Way Switch',
    trade: 'Electrical',
    group: 'Switches',
    unit: 'each',
    assetPath: 'assets/material_icons/electrical/switches.jpg',
  ),
  WorkSupplyItem(
    name: 'Dimmer Switch',
    trade: 'Electrical',
    group: 'Switches',
    unit: 'each',
    assetPath: 'assets/material_icons/electrical/switches.jpg',
  ),
];

const boxItems = [
  WorkSupplyItem(
    name: 'Single Gang Box',
    trade: 'Electrical',
    group: 'Boxes',
    unit: 'each',
    assetPath: 'assets/material_icons/electrical/junction_boxes.jpg',
  ),
  WorkSupplyItem(
    name: 'Double Gang Box',
    trade: 'Electrical',
    group: 'Boxes',
    unit: 'each',
    assetPath: 'assets/material_icons/electrical/junction_boxes.jpg',
  ),
  WorkSupplyItem(
    name: 'Weatherproof Box',
    trade: 'Electrical',
    group: 'Boxes',
    unit: 'each',
    assetPath: 'assets/material_icons/electrical/junction_boxes.jpg',
  ),
];

const connectorItems = [
  WorkSupplyItem(
    name: 'Wire Nuts',
    trade: 'Electrical',
    group: 'Connectors',
    unit: 'box',
    assetPath: 'assets/material_icons/electrical/connectors.jpg',
    keywords: ['wire connector'],
  ),
  WorkSupplyItem(
    name: 'Push-In Connectors',
    trade: 'Electrical',
    group: 'Connectors',
    unit: 'box',
    assetPath: 'assets/material_icons/electrical/connectors.jpg',
  ),
  WorkSupplyItem(
    name: 'Romex Connectors',
    trade: 'Electrical',
    group: 'Connectors',
    unit: 'pack',
    assetPath: 'assets/material_icons/electrical/connectors.jpg',
  ),
];

const electricalConsumables = [
  WorkSupplyItem(
    name: 'Electrical Tape',
    trade: 'Electrical',
    group: 'Consumables',
    unit: 'roll',
    assetPath: 'assets/material_icons/electrical/consumables.jpg',
  ),
  WorkSupplyItem(
    name: 'Cable Staples',
    trade: 'Electrical',
    group: 'Consumables',
    unit: 'box',
    assetPath: 'assets/material_icons/electrical/fasteners.jpg',
  ),
];
