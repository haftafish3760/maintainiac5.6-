import 'package:flutter/material.dart';

import '../../data/work_supply_models.dart';

const plumbingTrade = WorkSupplyTrade(
  name: 'Plumbing',
  assetPath: 'assets/material_icons/plumbing.jpg',
  color: Color(0xFF2D7EA7),
  groups: [
    WorkSupplyGroup(
      name: 'Fittings',
      assetPath: 'assets/material_icons/plumbing/fittings.jpg',
      materials: [
        WorkSupplyMaterial(name: 'PVC Schedule 40', items: pvcFittings),
        WorkSupplyMaterial(name: 'CPVC', items: cpvcFittings),
        WorkSupplyMaterial(name: 'Copper', items: copperFittings),
        WorkSupplyMaterial(name: 'PEX', items: pexFittings),
        WorkSupplyMaterial(name: 'Iron', items: ironFittings),
        WorkSupplyMaterial(name: 'PVC DWV', items: dwvFittings),
      ],
    ),
    WorkSupplyGroup(
      name: 'Pipe',
      assetPath: 'assets/material_icons/plumbing/pipe.jpg',
      items: pipeItems,
    ),
    WorkSupplyGroup(
      name: 'Valves',
      assetPath: 'assets/material_icons/plumbing/valves.jpg',
      items: valveItems,
    ),
    WorkSupplyGroup(
      name: 'Supply Lines',
      assetPath: 'assets/material_icons/plumbing/supply_lines.jpg',
      items: supplyLineItems,
    ),
    WorkSupplyGroup(
      name: 'Drainage',
      assetPath: 'assets/material_icons/plumbing/drainage.jpg',
      items: drainageItems,
    ),
    WorkSupplyGroup(
      name: 'Consumables',
      assetPath: 'assets/material_icons/plumbing/consumables.jpg',
      items: plumbingConsumables,
    ),
  ],
);

const fittingSizes = ['1/2 in', '3/4 in', '1 in', '1-1/2 in', '2 in'];
const teeSizes = ['1/2 x 1/2 x 1/2', '3/4 x 3/4 x 1/2', '1 x 1 x 3/4'];

const pvcFittings = [
  WorkSupplyItem(
    name: 'PVC 90 Elbow',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath: 'assets/material_icons/plumbing/fittings/materials/pvc_90.jpg',
    keywords: ['90', 'elbow'],
    sizes: fittingSizes,
  ),
  WorkSupplyItem(
    name: 'PVC Street 90',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath:
        'assets/material_icons/plumbing/fittings/materials/pvc_street_90.jpg',
    keywords: ['street elbow'],
    sizes: fittingSizes,
  ),
  WorkSupplyItem(
    name: 'PVC Tee',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath: 'assets/material_icons/plumbing/fittings/materials/pvc_tee.jpg',
    keywords: ['tee', 't'],
    sizes: teeSizes,
  ),
  WorkSupplyItem(
    name: 'PVC Coupling',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath:
        'assets/material_icons/plumbing/fittings/materials/pvc_coupling.jpg',
    keywords: ['coupler'],
    sizes: fittingSizes,
  ),
  WorkSupplyItem(
    name: 'PVC Union',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath:
        'assets/material_icons/plumbing/fittings/materials/pvc_union.jpg',
    keywords: ['union'],
    sizes: fittingSizes,
  ),
];

const cpvcFittings = [
  WorkSupplyItem(
    name: 'CPVC 90 Elbow',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath: 'assets/material_icons/plumbing/fittings/materials/cpvc_90.jpg',
    keywords: ['90', 'elbow'],
    sizes: fittingSizes,
  ),
  WorkSupplyItem(
    name: 'CPVC Tee',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath: 'assets/material_icons/plumbing/fittings/materials/cpvc_tee.jpg',
    keywords: ['tee'],
    sizes: teeSizes,
  ),
  WorkSupplyItem(
    name: 'CPVC Coupling',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath:
        'assets/material_icons/plumbing/fittings/materials/cpvc_coupling.jpg',
    keywords: ['coupler'],
    sizes: fittingSizes,
  ),
];

const copperFittings = [
  WorkSupplyItem(
    name: 'Copper 90 Elbow',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath:
        'assets/material_icons/plumbing/fittings/materials/copper_90.jpg',
    keywords: ['90', 'elbow', 'sweat'],
    sizes: fittingSizes,
  ),
  WorkSupplyItem(
    name: 'Copper Street 90',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath:
        'assets/material_icons/plumbing/fittings/materials/copper_street_90.jpg',
    keywords: ['street elbow'],
    sizes: fittingSizes,
  ),
  WorkSupplyItem(
    name: 'Copper Tee',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath:
        'assets/material_icons/plumbing/fittings/materials/copper_tee.jpg',
    keywords: ['tee'],
    sizes: teeSizes,
  ),
  WorkSupplyItem(
    name: 'Copper Coupling',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath:
        'assets/material_icons/plumbing/fittings/materials/copper_coupling.jpg',
    keywords: ['coupler'],
    sizes: fittingSizes,
  ),
];

const pexFittings = [
  WorkSupplyItem(
    name: 'PEX 90 Elbow',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath: 'assets/material_icons/plumbing/fittings/materials/pex_90.jpg',
    keywords: ['90', 'elbow'],
    sizes: fittingSizes,
  ),
  WorkSupplyItem(
    name: 'PEX Tee',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath: 'assets/material_icons/plumbing/fittings/materials/pex_tee.jpg',
    keywords: ['tee'],
    sizes: teeSizes,
  ),
  WorkSupplyItem(
    name: 'PEX Crimp Rings',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'pack',
    keywords: ['rings', 'clamps'],
    sizes: fittingSizes,
  ),
];

const ironFittings = [
  WorkSupplyItem(
    name: 'Iron 90 Elbow',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath:
        'assets/material_icons/plumbing/fittings/materials/black_iron_90.jpg',
    keywords: ['black iron', 'threaded'],
    sizes: fittingSizes,
  ),
  WorkSupplyItem(
    name: 'Iron Tee',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath:
        'assets/material_icons/plumbing/fittings/materials/black_iron_tee.jpg',
    keywords: ['threaded tee'],
    sizes: fittingSizes,
  ),
  WorkSupplyItem(
    name: 'Iron Union',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath:
        'assets/material_icons/plumbing/fittings/materials/black_iron_union.jpg',
    keywords: ['threaded union'],
    sizes: fittingSizes,
  ),
];

const dwvFittings = [
  WorkSupplyItem(
    name: 'DWV 90 Elbow',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath: 'assets/material_icons/plumbing/fittings/standard_90.jpg',
    keywords: ['drain elbow'],
    sizes: fittingSizes,
  ),
  WorkSupplyItem(
    name: 'DWV Y Fitting',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath: 'assets/material_icons/plumbing/fittings/y_fittings.jpg',
    keywords: ['wye', 'y'],
    sizes: fittingSizes,
  ),
  WorkSupplyItem(
    name: 'Cleanout',
    trade: 'Plumbing',
    group: 'Fittings',
    unit: 'each',
    assetPath: 'assets/material_icons/plumbing/fittings/cleanouts.jpg',
    keywords: ['clean out'],
    sizes: fittingSizes,
  ),
];

const pipeItems = [
  WorkSupplyItem(
    name: 'PVC Pipe',
    trade: 'Plumbing',
    group: 'Pipe',
    unit: 'foot',
    assetPath: 'assets/material_icons/plumbing/pipe.jpg',
    purchaseUnits: ['Stick', 'Foot'],
    sizes: fittingSizes,
  ),
  WorkSupplyItem(
    name: 'Copper Pipe',
    trade: 'Plumbing',
    group: 'Pipe',
    unit: 'foot',
    assetPath: 'assets/material_icons/plumbing/pipe.jpg',
    purchaseUnits: ['Stick', 'Foot'],
    sizes: fittingSizes,
  ),
  WorkSupplyItem(
    name: 'PEX Tubing',
    trade: 'Plumbing',
    group: 'Pipe',
    unit: 'foot',
    assetPath: 'assets/material_icons/plumbing/pipe.jpg',
    purchaseUnits: ['Coil', 'Foot'],
    sizes: fittingSizes,
  ),
];

const valveItems = [
  WorkSupplyItem(
    name: 'Ball Valve',
    trade: 'Plumbing',
    group: 'Valves',
    unit: 'each',
    assetPath: 'assets/material_icons/plumbing/valves.jpg',
    sizes: fittingSizes,
  ),
  WorkSupplyItem(
    name: 'Angle Stop',
    trade: 'Plumbing',
    group: 'Valves',
    unit: 'each',
    assetPath: 'assets/material_icons/plumbing/valves.jpg',
    keywords: ['shutoff', 'stop valve'],
  ),
  WorkSupplyItem(
    name: 'Hose Bibb',
    trade: 'Plumbing',
    group: 'Valves',
    unit: 'each',
    assetPath: 'assets/material_icons/plumbing/valves.jpg',
    keywords: ['spigot'],
  ),
];

const supplyLineItems = [
  WorkSupplyItem(
    name: 'Faucet Supply Line',
    trade: 'Plumbing',
    group: 'Supply Lines',
    unit: 'each',
    assetPath: 'assets/material_icons/plumbing/supply_lines.jpg',
    sizes: ['12 in', '16 in', '20 in', '30 in'],
  ),
  WorkSupplyItem(
    name: 'Toilet Supply Line',
    trade: 'Plumbing',
    group: 'Supply Lines',
    unit: 'each',
    assetPath: 'assets/material_icons/plumbing/supply_lines.jpg',
    sizes: ['12 in', '16 in', '20 in'],
  ),
];

const drainageItems = [
  WorkSupplyItem(
    name: 'P-Trap',
    trade: 'Plumbing',
    group: 'Drainage',
    unit: 'each',
    assetPath: 'assets/material_icons/plumbing/drainage.jpg',
    sizes: ['1-1/4 in', '1-1/2 in'],
  ),
  WorkSupplyItem(
    name: 'Wax Ring',
    trade: 'Plumbing',
    group: 'Drainage',
    unit: 'each',
    assetPath: 'assets/material_icons/plumbing/drainage.jpg',
    keywords: ['toilet seal'],
  ),
];

const plumbingConsumables = [
  WorkSupplyItem(
    name: 'Teflon Tape',
    trade: 'Plumbing',
    group: 'Consumables',
    unit: 'roll',
    assetPath: 'assets/material_icons/plumbing/consumables.jpg',
    keywords: ['ptfe', 'thread tape'],
  ),
  WorkSupplyItem(
    name: 'Pipe Dope',
    trade: 'Plumbing',
    group: 'Consumables',
    unit: 'tube',
    assetPath: 'assets/material_icons/plumbing/consumables.jpg',
    keywords: ['thread sealant'],
  ),
  WorkSupplyItem(
    name: 'PVC Cement',
    trade: 'Plumbing',
    group: 'Consumables',
    unit: 'can',
    assetPath: 'assets/material_icons/plumbing/consumables.jpg',
    keywords: ['glue'],
  ),
];
