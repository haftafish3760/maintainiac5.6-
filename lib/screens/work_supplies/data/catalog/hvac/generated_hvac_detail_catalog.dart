part of '../../work_supply_catalog.dart';

final hvacGeneratedDetailCatalogCategory = _category(
  'Pro HVAC Detail Expansion Stock',
  [
    _system('Filter IAQ and Return Air Detail', [
      _type('Expanded Filter Size Detail', _hvacDetailFilterProducts()),
      _type('Humidifier UV and IAQ Detail', _hvacDetailIaqProducts()),
    ]),
    _system('Duct Fabrication and Air Distribution Detail', [
      _type('Round Sheet Metal Fitting Detail', _hvacDetailRoundDuctProducts()),
      _type(
        'Register Grille Boot Detail',
        _hvacDetailAirDistributionProducts(),
      ),
      _type(
        'Rectangular Trunk Plenum Detail',
        _hvacDetailTrunkPlenumProducts(),
      ),
    ]),
    _system('HVAC Electrical and Control Detail', [
      _type('Capacitor Contactor Relay Detail', _hvacDetailControlProducts()),
      _type(
        'Disconnect Whip and Low Voltage Detail',
        _hvacDetailElectricalProducts(),
      ),
    ]),
    _system('Refrigerant Mini Split and Condensate Detail', [
      _type('Line Set and Mini Split Detail', _hvacDetailLineSetProducts()),
      _type('Condensate Pump Drain Detail', _hvacDetailCondensateProducts()),
    ]),
    _system('Furnace Heat Service Detail', [
      _type('Ignition Sensor and Switch Detail', _hvacDetailFurnaceProducts()),
      _type('Motor Blower and Fan Detail', _hvacDetailMotorProducts()),
    ]),
    _system('HVAC Consumables and Service Tools Detail', [
      _type('Cleaner Sealant and Tape Detail', _hvacDetailConsumableProducts()),
      _type('Refrigerant Tool Accessory Detail', _hvacDetailToolProducts()),
    ]),
  ],
);

List<WorkSupplyItem> _hvacDetailFilterProducts() {
  return _hvacDetailProducts(
    baseName: 'HVAC Filter Detail',
    unit: 'each',
    variants: [
      for (final size in [
        '10 x 20',
        '12 x 12',
        '12 x 20',
        '14 x 14',
        '14 x 20',
        '14 x 25',
        '16 x 16',
        '16 x 20',
        '16 x 24',
        '16 x 25',
        '18 x 20',
        '18 x 24',
        '20 x 20',
        '20 x 24',
        '20 x 25',
        '24 x 24',
        '24 x 30',
      ])
        for (final depth in ['1 in', '2 in', '4 in', '5 in'])
          for (final rating in ['MERV 8', 'MERV 11', 'MERV 13', 'MERV 16'])
            for (final item in [
              'Pleated Furnace Filter',
              'Return Air Filter',
              'Media Cabinet Furnace Filter',
            ])
              '$size x $depth $rating $item',
    ],
    aliases: const [
      'air filter',
      'furnace filter',
      'return filter',
      'media filter',
      'merv filter',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailIaqProducts() {
  return _hvacDetailProducts(
    baseName: 'HVAC IAQ Detail',
    unit: 'each',
    variants: [
      for (final size in ['10 in', '12 in', '14 in', '16 in'])
        for (final item in [
          'Bypass Humidifier Pad',
          'Humidifier Water Panel',
          'Electronic Air Cleaner Cell',
          'Media Air Cleaner Cabinet',
        ])
          '$size $item',
      for (final voltage in ['24V', '120V'])
        for (final item in [
          'UV Lamp Ballast',
          'UV Air Purifier Bulb',
          'Humidifier Solenoid Valve',
          'Duct Mounted Humidistat',
        ])
          '$voltage $item',
      'ERV Filter Kit',
      'HRV Filter Kit',
      'Whole House Dehumidifier Filter',
      'IAQ Equipment Door Switch',
    ],
    aliases: const [
      'humidifier pad',
      'water panel',
      'uv bulb',
      'air cleaner',
      'erv filter',
      'hrv filter',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailRoundDuctProducts() {
  return _hvacDetailProducts(
    baseName: 'Round Duct Detail',
    unit: 'each',
    variants: [
      for (final size in [
        '3 in',
        '4 in',
        '5 in',
        '6 in',
        '7 in',
        '8 in',
        '9 in',
        '10 in',
        '12 in',
        '14 in',
        '16 in',
        '18 in',
      ])
        for (final gauge in ['26 Gauge', '28 Gauge', '30 Gauge'])
          for (final item in [
            'Round Duct Pipe',
            'Adjustable Elbow',
            'Pressed 90 Elbow',
            'Start Collar',
            'Takeoff Collar',
            'Spin In Takeoff',
            'Manual Damper',
            'Backdraft Damper',
            'End Cap',
            'Round Reducer',
            'Round Wye',
            'Round Tee',
          ])
            '$size $gauge $item',
    ],
    aliases: const [
      'round duct',
      'duct pipe',
      'sheet metal elbow',
      'start collar',
      'takeoff',
      'manual damper',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailAirDistributionProducts() {
  return _hvacDetailProducts(
    baseName: 'Air Distribution Detail',
    unit: 'each',
    variants: [
      for (final size in [
        '2 x 10',
        '2 x 12',
        '4 x 10',
        '4 x 12',
        '6 x 10',
        '6 x 12',
        '8 x 8',
        '10 x 10',
        '12 x 12',
        '14 x 14',
        '20 x 20',
        '20 x 25',
      ])
        for (final finish in ['White', 'Brown', 'Black', 'Brushed Nickel'])
          for (final item in [
            'Floor Register',
            'Ceiling Register',
            'Sidewall Register',
            'Return Air Grille',
            'Filter Return Grille',
            'Baseboard Diffuser',
          ])
            '$size $finish $item',
      for (final face in ['4 x 10', '4 x 12', '6 x 10', '6 x 12', '8 x 8'])
        for (final throat in ['5 in', '6 in', '7 in', '8 in'])
          for (final item in ['Straight Register Boot', 'Angle Register Boot'])
            '$face x $throat $item',
    ],
    aliases: const [
      'floor register',
      'ceiling register',
      'return grille',
      'filter grille',
      'register boot',
      'diffuser',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailTrunkPlenumProducts() {
  return _hvacDetailProducts(
    baseName: 'Duct Fabrication Detail',
    unit: 'each',
    variants: [
      for (final size in [
        '8 x 8',
        '10 x 10',
        '12 x 12',
        '14 x 14',
        '16 x 16',
        '16 x 20',
        '20 x 20',
        '20 x 25',
        '24 x 24',
      ])
        for (final item in [
          'Return Air Box',
          'Supply Plenum',
          'Return Plenum',
          'Duct Transition',
          'Duct End Cap',
          'Duct Access Door',
        ])
          '$size $item',
      for (final size in ['2 ft x 4 ft', '4 ft x 8 ft'])
        for (final thickness in ['1 in', '1-1/2 in', '2 in'])
          '$size x $thickness Foil Faced Duct Board',
      for (final length in ['36 in', '48 in', '60 in'])
        for (final item in ['Drive Cleat', 'S Cleat', 'Standing S Cleat'])
          '$length $item',
    ],
    aliases: const [
      'supply plenum',
      'return plenum',
      'return box',
      'duct board',
      'drive cleat',
      's cleat',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailControlProducts() {
  return _hvacDetailProducts(
    baseName: 'HVAC Control Detail',
    unit: 'each',
    variants: [
      for (final mfd in [
        '20/5 MFD',
        '25/5 MFD',
        '30/5 MFD',
        '35/5 MFD',
        '40/5 MFD',
        '45/5 MFD',
        '50/5 MFD',
        '55/5 MFD',
        '60/5 MFD',
        '70/5 MFD',
        '80/5 MFD',
      ])
        for (final volts in ['370V', '440V']) '$mfd $volts Dual Run Capacitor',
      for (final mfd in [
        '5 MFD',
        '7.5 MFD',
        '10 MFD',
        '15 MFD',
        '20 MFD',
        '25 MFD',
        '30 MFD',
        '35 MFD',
        '40 MFD',
      ])
        for (final volts in ['370V', '440V'])
          '$mfd $volts Single Run Capacitor',
      for (final pole in ['1 Pole', '2 Pole', '3 Pole'])
        for (final amp in ['25 Amp', '30 Amp', '40 Amp', '50 Amp'])
          for (final coil in ['24V Coil', '120V Coil'])
            '$pole $amp $coil Contactor',
      '40VA 24V Transformer',
      '50VA 24V Transformer',
      '75VA 24V Transformer',
      'Fan Relay 24V',
      'Defrost Relay 24V',
      'Hard Start Kit',
      'Compressor Saver Kit',
      'Time Delay Relay',
    ],
    aliases: const [
      'run capacitor',
      'dual cap',
      'single cap',
      'contactor',
      'relay',
      'hard start',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailElectricalProducts() {
  return _hvacDetailProducts(
    baseName: 'HVAC Electrical Detail',
    unit: 'each',
    variants: [
      for (final amp in ['30 Amp', '60 Amp'])
        for (final style in ['Fused', 'Non Fused', 'Pullout'])
          '$amp $style AC Disconnect',
      for (final size in ['1/2 in', '3/4 in', '1 in'])
        for (final length in ['4 ft', '6 ft', '8 ft'])
          '$size x $length AC Whip',
      for (final conductor in ['18/2', '18/3', '18/5', '18/7', '18/8'])
        for (final length in ['50 ft', '100 ft', '250 ft', '500 ft'])
          '$conductor x $length Thermostat Wire',
      '3 Amp Low Voltage Fuse',
      '5 Amp Low Voltage Fuse',
      'Low Voltage Fuse Holder',
      'Single Phase Surge Protector',
      'Equipment Ground Lug',
      'Liquid Tight Connector 1/2 in',
      'Liquid Tight Connector 3/4 in',
    ],
    aliases: const [
      'ac disconnect',
      'disconnect box',
      'ac whip',
      'stat wire',
      'thermostat wire',
      'low voltage fuse',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailLineSetProducts() {
  return _hvacDetailProducts(
    baseName: 'HVAC Line Set Detail',
    unit: 'each',
    variants: [
      for (final pair in [
        '1/4 x 3/8',
        '1/4 x 1/2',
        '1/4 x 5/8',
        '3/8 x 3/4',
        '3/8 x 7/8',
      ])
        for (final length in ['15 ft', '25 ft', '35 ft', '50 ft', '65 ft'])
          for (final item in ['Line Set', 'Mini Split Line Set'])
            '$pair x $length $item',
      for (final size in ['3 in', '4 in', '5 in'])
        for (final color in ['White', 'Ivory', 'Brown', 'Black'])
          for (final part in [
            'Line Set Cover',
            'Line Hide Wall Cap',
            'Line Hide Coupling',
            'Line Hide Elbow',
            'Line Hide End Cap',
          ])
            '$size $color $part',
    ],
    aliases: const [
      'line set',
      'mini split line set',
      'line hide',
      'line set cover',
      'copper line',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailCondensateProducts() {
  return _hvacDetailProducts(
    baseName: 'HVAC Condensate Detail',
    unit: 'each',
    variants: [
      for (final voltage in ['115V', '230V'])
        for (final item in [
          'Condensate Pump',
          'Mini Condensate Pump',
          'High Lift Condensate Pump',
        ])
          '$voltage $item',
      for (final size in [
        '24 x 24',
        '24 x 30',
        '30 x 30',
        '30 x 36',
        '36 x 48',
      ])
        for (final item in ['Secondary Drain Pan', 'Plastic Drain Pan'])
          '$size $item',
      for (final size in ['3/4 in', '1 in'])
        for (final part in [
          'PVC Condensate Pipe',
          'PVC Condensate 90 Elbow',
          'PVC Condensate Tee',
          'PVC Condensate Trap',
          'PVC Condensate Cleanout Tee',
        ])
          '$size $part',
      'Inline Float Switch',
      'Secondary Pan Float Switch',
      'Wet Switch',
      'Condensate Overflow Alarm',
      'Drain Pan Treatment Tablets',
      'Drain Line Cleaner 1 qt',
    ],
    aliases: const [
      'condensate pump',
      'cond pump',
      'drain pan',
      'float switch',
      'wet switch',
      'condensate drain',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailFurnaceProducts() {
  return _hvacDetailProducts(
    baseName: 'Furnace Service Detail',
    unit: 'each',
    variants: [
      for (final style in ['Universal', 'Flat', 'Round', 'Silicon Nitride'])
        '$style Hot Surface Ignitor',
      for (final style in ['Straight', 'Bent', 'Universal'])
        '$style Flame Sensor',
      for (final port in ['Single Port', 'Dual Port'])
        for (final rating in ['0.40 in WC', '0.60 in WC', '0.90 in WC'])
          '$port $rating Pressure Switch',
      for (final temp in [
        '150 Degree',
        '180 Degree',
        '200 Degree',
        '250 Degree',
      ])
        for (final item in ['Limit Switch', 'Rollout Switch']) '$temp $item',
      'Furnace Door Safety Switch',
      'Draft Inducer Motor',
      'Inducer Motor Gasket',
      'Combustion Blower Gasket',
      'Furnace Control Board',
      'Integrated Furnace Control Board',
      '24V Natural Gas Valve',
      '24V Propane Gas Valve',
      'Silicone Pressure Switch Tubing',
    ],
    aliases: const [
      'hot surface ignitor',
      'hsi',
      'flame sensor',
      'pressure switch',
      'limit switch',
      'rollout switch',
      'gas valve',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailMotorProducts() {
  return _hvacDetailProducts(
    baseName: 'HVAC Motor Detail',
    unit: 'each',
    variants: [
      for (final hp in [
        '1/6 hp',
        '1/4 hp',
        '1/3 hp',
        '1/2 hp',
        '3/4 hp',
        '1 hp',
      ])
        for (final voltage in ['115V', '208-230V'])
          for (final item in [
            'PSC Blower Motor',
            'ECM Blower Motor',
            'Condenser Fan Motor',
            'Draft Inducer Motor',
          ])
            '$hp $voltage $item',
      for (final size in ['10 x 8', '10 x 10', '11 x 10', '12 x 12', '13 x 10'])
        '$size Blower Wheel',
      for (final size in ['18 in', '20 in', '22 in', '24 in', '26 in'])
        for (final pitch in ['22 Degree', '27 Degree', '33 Degree'])
          '$size $pitch Condenser Fan Blade',
    ],
    aliases: const [
      'blower motor',
      'condenser fan motor',
      'inducer motor',
      'blower wheel',
      'fan blade',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailConsumableProducts() {
  return _hvacDetailProducts(
    baseName: 'HVAC Consumable Detail',
    unit: 'each',
    variants: [
      for (final size in ['1 qt', '1 gal', '2 gal'])
        for (final item in [
          'No Rinse Evaporator Coil Cleaner',
          'Condenser Coil Cleaner',
          'Alkaline Coil Cleaner',
          'Drain Line Cleaner',
        ])
          '$size $item',
      for (final size in ['2 in x 50 yd', '3 in x 50 yd', '4 in x 50 yd'])
        for (final item in ['UL 181 Foil Tape', 'Mastic Foil Tape'])
          '$size $item',
      for (final size in ['1 gal', '2 gal', '5 gal'])
        for (final item in ['Duct Mastic', 'Water Based Duct Sealant'])
          '$size $item',
      'Vacuum Pump Oil 1 qt',
      'Thread Sealant for Refrigeration',
      'Refrigerant Leak Detector Spray',
      'UV Dye Leak Detection Kit',
      'Pan Treatment Tablets',
      'Foam Gasket Tape',
      'Cork Insulation Tape',
      'Duct Strap Roll',
      'Metal Hanging Strap Roll',
    ],
    aliases: const [
      'coil cleaner',
      'duct mastic',
      'foil tape',
      'vacuum pump oil',
      'leak detector',
      'duct strap',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailToolProducts() {
  return _hvacDetailProducts(
    baseName: 'HVAC Tool Accessory Detail',
    unit: 'each',
    variants: [
      for (final cfm in ['3 CFM', '5 CFM', '7 CFM']) '$cfm Vacuum Pump',
      for (final refrigerant in ['R22', 'R410A', 'R32', 'R454B'])
        for (final item in [
          'Manifold Gauge Set',
          'Charging Hose Set',
          'Charging Adapter',
        ])
          '$refrigerant $item',
      'Digital Refrigerant Scale',
      'Micron Gauge',
      'Core Removal Tool',
      'Flaring Tool Kit',
      'Swaging Tool Kit',
      'Tubing Cutter',
      'Deburring Tool',
      'Nitrogen Regulator',
      'Low Loss Fitting Set',
      'Service Valve Wrench',
    ],
    aliases: const [
      'vacuum pump',
      'manifold gauge',
      'refrigerant scale',
      'micron gauge',
      'core removal tool',
      'flare tool',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailProducts({
  required String baseName,
  required String unit,
  required List<String> variants,
  required List<String> aliases,
}) {
  return [
    for (final variant in variants)
      WorkSupplyItem(
        id: '',
        name: '$variant $baseName',
        trade: '',
        category: '',
        system: '',
        itemType: '',
        variant: variant,
        unit: unit,
        aliases: aliases,
      ),
  ];
}
