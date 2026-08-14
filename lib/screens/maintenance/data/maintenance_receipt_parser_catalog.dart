part of 'maintenance_receipt_parser.dart';

final _itemDefinitions = <_ItemDefinition>[
  _ItemDefinition(
    itemName: 'Engine Oil',
    pattern: RegExp(
      r'\b(?:engine oil|motor oil|oil change|conventional oil|(?:0|5|10|15|20)w[- ]?\d+)\b',
    ),
    servicePattern: RegExp(r'\b(?:oil change|lube oil filter|lof service)\b'),
    detailA: _oilType,
    detailB: _oilWeight,
  ),
  _ItemDefinition(
    itemName: 'Oil Filter',
    pattern: RegExp(r'\b(?:oil filter|filter oil)\b'),
    servicePattern: RegExp(
      r'\b(?:oil filter (?:replace|replacement|installed)|lube oil filter|lof service)\b',
    ),
    detailB: _oilFilterPart,
  ),
  _ItemDefinition(
    itemName: 'Transmission Fluid and Filter',
    pattern: RegExp(
      r'\b(?:transmission fluid|trans fluid|transmission flush|cvt fluid)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:transmission (?:service|flush)|atf service|cvt service)\b',
    ),
    detailA: _fluidSpec,
  ),
  _ItemDefinition(
    itemName: 'Coolant',
    pattern: RegExp(r'\b(?:coolant|antifreeze|dex-?cool)\b'),
    servicePattern: RegExp(
      r'\b(?:coolant (?:service|flush|exchange)|radiator flush)\b',
    ),
    detailA: _fluidSpec,
  ),
  _ItemDefinition(
    itemName: 'Brake Fluid',
    pattern: RegExp(r'\b(?:brake fluid|dot\s*(?:3|4|5\.1))\b'),
    servicePattern: RegExp(r'\b(?:brake fluid (?:service|flush|exchange))\b'),
    detailA: _fluidSpec,
  ),
  _ItemDefinition(
    itemName: 'Brake Pads',
    pattern: RegExp(r'\b(?:brake pads?|disc brake pads?)\b'),
    servicePattern: RegExp(
      r'\b(?:brake pads?|disc brake pads?|pads?) (?:replace|replaced|replacement|installed)\b',
    ),
    detailA: _brakeAxle,
    detailB: _brakeFrictionMaterial,
  ),
  _ItemDefinition(
    itemName: 'Brake Rotors',
    pattern: RegExp(r'\b(?:brake rotors?|disc rotors?)\b'),
    servicePattern: RegExp(
      r'\b(?:brake rotors?|disc rotors?|rotors?) (?:replace|replaced|replacement|installed|resurfaced|machined|turned)\b',
    ),
    detailA: _brakeAxle,
    detailB: _brakeHardwareServiceType,
  ),
  _ItemDefinition(
    itemName: 'Brake Shoes',
    pattern: RegExp(r'\b(?:brake shoes?|drum brake shoes?)\b'),
    servicePattern: RegExp(
      r'\b(?:brake shoes?|drum brake shoes?|shoes?) (?:replace|replaced|replacement|installed)\b',
    ),
    detailA: _brakeAxle,
    detailB: _brakeFrictionMaterial,
  ),
  _ItemDefinition(
    itemName: 'Brake Drums',
    pattern: RegExp(r'\b(?:brake drums?|drum brake drums?)\b'),
    servicePattern: RegExp(
      r'\b(?:brake drums?|drum brake drums?|drums?) (?:replace|replaced|replacement|installed|resurfaced|machined|turned)\b',
    ),
    detailA: _brakeAxle,
    detailB: _brakeHardwareServiceType,
  ),
  _ItemDefinition(
    itemName: 'Brake Calipers',
    pattern: RegExp(r'\b(?:brake calipers?|disc brake calipers?)\b'),
    servicePattern: RegExp(
      r'\b(?:brake calipers?|disc brake calipers?|calipers?) (?:replace|replaced|replacement|installed|rebuilt)\b',
    ),
    detailA: _brakeAxle,
    detailB: _brakeHardwareServiceType,
  ),
  _ItemDefinition(
    itemName: 'Brake Hoses and Lines',
    pattern: RegExp(
      r'\b(?:brake hoses?|flex brake hoses?|brake lines?|brake hydraulic lines?)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:brake hoses?|flex brake hoses?|brake lines?|brake hydraulic lines?) (?:replace|replaced|replacement|installed)\b',
    ),
    detailA: _brakeAxle,
  ),
  _ItemDefinition(
    itemName: 'Brake Inspection',
    pattern: RegExp(
      r'\b(?:brake inspection|brake system inspection|inspect(?:ed)? brakes?)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:brake inspection|brake system inspection|brakes? inspected)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Engine Air Filter',
    pattern: RegExp(r'\b(?:engine air filter|air filter element)\b'),
    servicePattern: RegExp(
      r'\b(?:engine air filter (?:replace|replacement|installed))\b',
    ),
    detailB: _engineAirFilterPart,
  ),
  _ItemDefinition(
    itemName: 'Cabin Air Filter',
    pattern: RegExp(r'\b(?:cabin air filter|cabin filter)\b'),
    servicePattern: RegExp(
      r'\b(?:cabin (?:air )?filter (?:replace|replacement|installed))\b',
    ),
    detailB: _cabinAirFilterPart,
  ),
  _ItemDefinition(
    itemName: 'Spark Plugs',
    pattern: RegExp(r'\b(?:spark plugs?(?!\s+wires?)|ignition plugs?)\b'),
    servicePattern: RegExp(
      r'\b(?:spark plugs? (?:replace|replacement|installed)|tune[- ]?up)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Ignition Coils',
    pattern: RegExp(r'\b(?:ignition coils?|coil packs?|coil-on-plug)\b'),
    servicePattern: RegExp(
      r'\b(?:ignition coils?|coil packs?|coil-on-plug) (?:replace|replaced|replacement|installed)\b',
    ),
    detailA: _ignitionCoilType,
  ),
  _ItemDefinition(
    itemName: 'Spark Plug Wires',
    pattern: RegExp(r'\b(?:spark plug wires?|ignition wire sets?)\b'),
    servicePattern: RegExp(
      r'\b(?:spark plug wires?|ignition wire sets?) (?:replace|replaced|replacement|installed)\b',
    ),
    detailA: _sparkPlugWireType,
  ),
  _ItemDefinition(
    itemName: 'PCV Valve',
    pattern: RegExp(r'\b(?:pcv valve|positive crankcase ventilation valve)\b'),
    servicePattern: RegExp(
      r'\b(?:pcv valve|positive crankcase ventilation valve) (?:replace|replaced|replacement|installed)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Oxygen Sensors',
    pattern: RegExp(r'\b(?:oxygen sensors?|o2 sensors?)\b'),
    servicePattern: RegExp(
      r'\b(?:oxygen sensors?|o2 sensors?) (?:replace|replaced|replacement|installed)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Catalytic Converter',
    pattern: RegExp(r'\b(?:catalytic converters?|cat converters?)\b'),
    servicePattern: RegExp(
      r'\b(?:catalytic converters?|cat converters?) (?:replace|replaced|replacement|installed)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'EGR Valve',
    pattern: RegExp(r'\b(?:egr valve|exhaust gas recirculation valve)\b'),
    servicePattern: RegExp(
      r'\b(?:egr valve|exhaust gas recirculation valve) (?:replace|replaced|replacement|installed|cleaned)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Mass Air Flow Sensor',
    pattern: RegExp(r'\b(?:mass air flow sensors?|maf sensors?)\b'),
    servicePattern: RegExp(
      r'\b(?:mass air flow sensors?|maf sensors?) (?:replace|replaced|replacement|installed|cleaned)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Valve Cover Gasket',
    pattern: RegExp(r'\b(?:valve cover gaskets?|rocker cover gaskets?)\b'),
    servicePattern: RegExp(
      r'\b(?:valve cover gaskets?|rocker cover gaskets?) (?:replace|replaced|replacement|installed)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Oil Pan Gasket',
    pattern: RegExp(r'\b(?:oil pan gaskets?|engine oil pan gaskets?)\b'),
    servicePattern: RegExp(
      r'\b(?:oil pan gaskets?|engine oil pan gaskets?) (?:replace|replaced|replacement|installed)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Serpentine Belt',
    pattern: RegExp(r'\b(?:serpentine belt|drive belt)\b'),
    servicePattern: RegExp(
      r'\b(?:(?:serpentine|drive) belt (?:replace|replacement|installed))\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Belt Tensioner',
    pattern: RegExp(r'\b(?:belt tensioners?|drive belt tensioners?)\b'),
    servicePattern: RegExp(
      r'\b(?:belt tensioners?|drive belt tensioners?) (?:replace|replaced|replacement|installed)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Idler Pulley',
    pattern: RegExp(r'\b(?:idler pulleys?|belt idler pulleys?)\b'),
    servicePattern: RegExp(
      r'\b(?:idler pulleys?|belt idler pulleys?) (?:replace|replaced|replacement|installed)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Timing Belt',
    pattern: RegExp(r'\b(?:timing belt|camshaft belt)\b'),
    servicePattern: RegExp(
      r'\b(?:timing belt|camshaft belt) (?:replace|replaced|replacement|installed)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Radiator Hose',
    pattern: RegExp(
      r'\b(?:radiator hose|coolant hose|upper hose|lower hose)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:(?:radiator|coolant|upper|lower) hose (?:replace|replacement|installed))\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Radiator',
    pattern: RegExp(r'\b(?:engine )?radiator\b(?!\s*(?:cap|hose|flush))'),
    servicePattern: RegExp(
      r'\b(?:engine )?radiator (?:replace|replaced|replacement|installed)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Radiator Cap',
    pattern: RegExp(r'\bradiator caps?\b'),
    servicePattern: RegExp(
      r'\bradiator caps? (?:replace|replaced|replacement|installed)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Water Pump',
    pattern: RegExp(r'\b(?:water pump|engine water pump|coolant pump)\b'),
    servicePattern: RegExp(
      r'\b(?:water pump|engine water pump|coolant pump) (?:replace|replaced|replacement|installed)\b',
    ),
    detailA: _waterPumpType,
  ),
  _ItemDefinition(
    itemName: 'Thermostat',
    pattern: RegExp(r'\b(?:engine )?thermostat\b'),
    servicePattern: RegExp(
      r'\b(?:engine )?thermostat (?:replace|replaced|replacement|installed)\b',
    ),
    detailA: _thermostatTemperatureRating,
  ),
  _ItemDefinition(
    itemName: 'Steering and Suspension Inspection',
    pattern: RegExp(
      r'\b(?:steering (?:and |& )?suspension inspection|suspension inspection|front[- ]end inspection)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:steering (?:and |& )?suspension inspection|suspension inspection|front[- ]end inspection|suspension inspected)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Shocks and Struts',
    pattern: RegExp(r'\b(?:shock absorbers?|shocks?|struts?)\b'),
    servicePattern: RegExp(
      r'\b(?:shock absorbers?|shocks?|struts?) (?:replace|replaced|replacement|installed)\b',
    ),
    detailA: _suspensionServicePosition,
    detailB: _shockAndStrutComponent,
  ),
  _ItemDefinition(
    itemName: 'Ball Joints',
    pattern: RegExp(r'\bball joints?\b'),
    servicePattern: RegExp(
      r'\bball joints? (?:replace|replaced|replacement|installed)\b',
    ),
    detailA: _suspensionServicePosition,
    detailB: _ballJointPosition,
  ),
  _ItemDefinition(
    itemName: 'Tie Rod Ends',
    pattern: RegExp(r'\b(?:tie rod ends?|inner tie rods?|outer tie rods?)\b'),
    servicePattern: RegExp(
      r'\b(?:tie rod ends?|inner tie rods?|outer tie rods?) (?:replace|replaced|replacement|installed)\b',
    ),
    detailA: _suspensionServicePosition,
    detailB: _tieRodPosition,
  ),
  _ItemDefinition(
    itemName: 'Sway Bar Links',
    pattern: RegExp(r'\b(?:sway bar links?|stabilizer bar links?)\b'),
    servicePattern: RegExp(
      r'\b(?:sway bar links?|stabilizer bar links?) (?:replace|replaced|replacement|installed)\b',
    ),
    detailA: _suspensionServicePosition,
  ),
  _ItemDefinition(
    itemName: 'Wheel Bearings',
    pattern: RegExp(
      r'\b(?:wheel bearings?|hub bearing assemblies?|wheel hub assemblies?)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:wheel bearings?|hub bearing assemblies?|wheel hub assemblies?) (?:replace|replaced|replacement|installed)\b',
    ),
    detailA: _suspensionServicePosition,
    detailB: _wheelBearingComponent,
  ),
  _ItemDefinition(
    itemName: 'CV Axles',
    pattern: RegExp(
      r'\b(?:cv axles?|constant[- ]velocity axles?|drive axles?)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:cv axles?|constant[- ]velocity axles?|drive axles?) (?:replace|replaced|replacement|installed)\b',
    ),
    detailA: _suspensionServicePosition,
    detailB: _cvAxleType,
  ),
  _ItemDefinition(
    itemName: 'Engine Mounts',
    pattern: RegExp(r'\b(?:engine mounts?|motor mounts?)\b'),
    servicePattern: RegExp(
      r'\b(?:engine mounts?|motor mounts?) (?:replace|replaced|replacement|installed)\b',
    ),
    detailA: _engineMountType,
  ),
  _ItemDefinition(
    itemName: 'Wiper Blades',
    pattern: RegExp(r'\b(?:wiper blades?|windshield wipers?)\b'),
    servicePattern: RegExp(
      r'\b(?:wiper blades? (?:replace|replacement|installed))\b',
    ),
    detailB: _wiperSize,
  ),
  _ItemDefinition(
    itemName: 'Battery',
    pattern: RegExp(
      r'\b(?:automotive battery|car battery|battery group|battery grp|(?:duralast|diehard|legend|everstart)[^\n]{0,40}battery)\b',
    ),
    servicePattern: RegExp(
      r'\b(?<!key fob )(?<!remote key )(?<!keyless remote )battery (?:warranty )?(?:replace|replaced|replacement|installed|installation)\b',
    ),
    detailB: _batteryGroup,
  ),
  _ItemDefinition(
    itemName: 'Alternator',
    pattern: RegExp(r'\balternator\b'),
    servicePattern: RegExp(
      r'\balternator (?:replace|replaced|replacement|installed)\b',
    ),
    detailA: _engineElectricalComponentType,
  ),
  _ItemDefinition(
    itemName: 'Starter',
    pattern: RegExp(r'(?<!remote )\bstarter(?: motor| assembly)?\b'),
    servicePattern: RegExp(
      r'(?<!remote )\bstarter(?: motor| assembly)? (?:replace|replaced|replacement|installed)\b',
    ),
    detailA: _engineElectricalComponentType,
  ),
  _ItemDefinition(
    itemName: 'Power Steering Fluid',
    pattern: RegExp(r'\b(?:power steering fluid|p\/s fluid)\b'),
    servicePattern: RegExp(
      r'\b(?:power steering (?:fluid )?(?:service|flush|exchange))\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Differential Fluid',
    pattern: RegExp(
      r'\b(?:differential fluid|differential service|gear oil|75w[- ]?(?:90|140)|80w[- ]?90)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:differential (?:fluid )?(?:service|change|replacement)|gear oil (?:changed|replaced))\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Transfer Case Fluid',
    pattern: RegExp(r'\b(?:transfer case fluid|transfer case oil)\b'),
    servicePattern: RegExp(
      r'\b(?:transfer case (?:fluid )?(?:service|change|replacement)|transfer case (?:fluid|oil) (?:changed|replaced))\b',
    ),
    detailA: _fluidSpec,
  ),
  _ItemDefinition(
    itemName: 'Fuel Filter',
    pattern: RegExp(r'\b(?:fuel filter|gas filter)\b'),
    servicePattern: RegExp(
      r'\b(?:fuel filter (?:replace|replacement|installed))\b',
    ),
    detailB: _fuelFilterPart,
  ),
  _ItemDefinition(
    itemName: 'Fuel Pump',
    pattern: RegExp(r'\b(?:fuel pumps?|gas pumps?)\b'),
    servicePattern: RegExp(
      r'\b(?:fuel pumps?|gas pumps?) (?:replace|replaced|replacement|installed)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Fuel System Service',
    pattern: RegExp(
      r'\b(?:fuel system service|fuel injection service|fuel injector cleaning|induction service|throttle body cleaning)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:fuel system service|fuel injection service|fuel injector cleaning|induction service|throttle body cleaning)\b',
    ),
    detailA: _fuelSystemServiceType,
  ),
  _ItemDefinition(
    itemName: 'Air Conditioning Service',
    pattern: RegExp(
      r'\b(?:a\/?c service|air conditioning service|a\/?c recharge|refrigerant recharge|r-?134a recharge|r-?1234yf recharge)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:a\/?c service|air conditioning service|a\/?c recharge|refrigerant recharge|r-?134a recharge|r-?1234yf recharge)\b',
    ),
    detailA: _airConditioningServiceType,
    detailB: _airConditioningRefrigerant,
  ),
  _ItemDefinition(
    itemName: 'Tires',
    pattern: RegExp(
      r'\b(?:new tires?|replacement tires?|all[- ]season tires?|winter tires?|tire installation)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:tires? (?:replace|replacement|installed|installation)|tire installation)\b',
    ),
    detailA: _tireBrandAndType,
    detailB: _tireSize,
  ),
  _ItemDefinition(
    itemName: 'Washer Fluid',
    pattern: RegExp(
      r'\b(?:washer fluid|windshield wash|windshield washer fluid)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:washer fluid (?:filled|refill|service)|windshield washer fluid (?:filled|refill))\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Tire Rotation',
    pattern: RegExp(r'\b(?:tire rotation|rotate tires?)\b'),
    servicePattern: RegExp(r'\b(?:tire rotation|rotate tires?)\b'),
  ),
  _ItemDefinition(
    itemName: 'Wheel Alignment',
    pattern: RegExp(
      r'\b(?:wheel alignment|front[- ]end alignment|alignment service)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:wheel alignment|front[- ]end alignment|alignment service|wheels? aligned)\b',
    ),
    detailA: _wheelAlignmentType,
  ),
  ..._wheelBalancingItemDefinitions,
  ..._renewalItemDefinitions,
];

Set<String> get maintenanceReceiptSupportedItemNames =>
    Set.unmodifiable(_itemDefinitions.map((definition) => definition.itemName));
