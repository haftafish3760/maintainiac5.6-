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
  ),
  _ItemDefinition(
    itemName: 'Brake Rotors',
    pattern: RegExp(r'\b(?:brake rotors?|disc rotors?)\b'),
    servicePattern: RegExp(
      r'\b(?:brake rotors?|disc rotors?|rotors?) (?:replace|replaced|replacement|installed)\b',
    ),
    detailA: _brakeAxle,
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
    pattern: RegExp(r'\b(?:spark plugs?|ignition plugs?)\b'),
    servicePattern: RegExp(
      r'\b(?:spark plugs? (?:replace|replacement|installed)|tune[- ]?up)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'PCV Valve',
    pattern: RegExp(r'\b(?:pcv valve|positive crankcase ventilation valve)\b'),
    servicePattern: RegExp(
      r'\b(?:pcv valve|positive crankcase ventilation valve) (?:replace|replaced|replacement|installed)\b',
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
    itemName: 'Key Fob Battery',
    pattern: RegExp(
      r'\b(?:key fob battery|remote key battery|keyless remote battery)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:key fob|remote key|keyless remote) battery (?:replace|replaced|replacement|installed)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Registration',
    pattern: RegExp(
      r'\b(?:vehicle registration|registration renewal|license plate renewal)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:vehicle registration|registration|license plate) (?:renewed|renewal completed)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Inspection',
    pattern: RegExp(
      r'\b(?:vehicle inspection|safety inspection|emissions inspection|state inspection)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:vehicle|safety|emissions|state) inspection (?:passed|completed|performed)\b',
    ),
  ),
];

Set<String> get maintenanceReceiptSupportedItemNames =>
    Set.unmodifiable(_itemDefinitions.map((definition) => definition.itemName));

final _maintenanceRetailMerchant = RegExp(
  r"\b(?:advance\s*auto\s*parts|advanceautoparts|auto\s*zone|o\s*[’'`]?\s*reilly\s*auto\s*parts|napa\s*auto\s*parts|carquest|pep\s*boys|wal\s*-?\s*mart|costco(?:\s*wholesale)?|sam[’'`]?\s*s\s*club|tractor\s*supply(?:\s*co)?|rural\s*king)\b",
);
final _purchaseSignal = RegExp(
  r'\b(?:amount paid|cashier|register|change due|retail sale|sku|part no|item price)\b',
);
final _serviceSignal = RegExp(
  r'\b(?:service performed|work completed|completed services?|repair order|work order|technician|labor|vehicle mileage|customer vehicle|installed|replaced|replacement|oil change|tire rotation|flush service|registration renewed|renewal completed|inspection passed|inspection completed)\b',
);
final _strongServiceSignal = RegExp(
  r'\b(?:service performed|work completed|repair order|work order|technician|labor|vehicle mileage|customer vehicle|installed|replaced|registration renewed|renewal completed|inspection passed|inspection completed)\b',
);
final _performedOnLine = RegExp(
  r'\b(?:service|labor|installed|replaced|replacement|performed|change|rotation|flush|renewed|passed|completed)\b',
);
final _estimateOrQuoteSignal = RegExp(
  r'\b(?:estimate|quotation|quote|proposed work)\b',
);
final _explicitCompletionSignal = RegExp(
  r'\b(?:service performed|work completed|paid in full|installed|replaced|renewed|inspection passed)\b',
);
final _notCompletedLine = RegExp(
  r'\b(?:declined|deferred|recommended|recommendation|estimate|estimated|quote|quoted|proposed|not performed|not authorized|not approved|cancel(?:ed|led)|customer refused|future service)\b',
);
final _notCompletedSectionHeading = RegExp(
  r'^(?:(?:declined|deferred|recommended|recommendations|estimate|estimated|quoted|proposed)(?: services?| work| items?)?|requested services?|customer (?:request(?:s|ed)?(?: services?)?|concerns?|states?|declined|refused)|(?:authorized|approved)(?: services?| work| repairs?)|not (?:authorized|approved)|cancel(?:ed|led)(?: services?| work| repairs?)|no work performed|inspection (?:results?|findings?)|(?:pending|future)(?: services?| work| repairs?)|parts on order|awaiting parts|diagnos(?:is|tic (?:results?|findings?)))\s*:?\s*$',
);
final _completedSectionHeading = RegExp(
  r'^(?:service performed|performed services?|work completed|completed services?)\s*:?\s*$',
);
final _returnOrExchangeLine = RegExp(
  r'\b(?:return(?:ed)?|refund(?:ed)?|exchange(?:d)?|voided item)\b',
);
final _coreAdjustmentLine = RegExp(
  r'\b(?:core\s+(?:charge|deposit|credit|refund|return|exchange)|(?:credit|refund|return)\s+core)\b',
);
final _transactionPolicyLine = RegExp(r'\b(?:return|refund|exchange) policy\b');
final _standaloneReturnHeading = RegExp(
  r'^(?:return|refund|exchange)\s*:?\s*$',
);
final _purchaseLineSignal = RegExp(r'\b(?:sku|part|qty|item)\b');
final _transactionCompletionSignal = RegExp(
  r'\b(?:amount paid|retail sale|paid|payment|tender|cash|credit|debit|total)\b',
);
final _pricedLine = RegExp(r'(?:^|\s)[-+]?\$?\d+[.,]\d{2}(?:\s|$)');
final _metadataLine = RegExp(
  r'\b(?:store|date|time|receipt|invoice|phone|address|subtotal|tax|total|amount paid)\b',
);
final _serviceOdometerOutPattern = RegExp(
  r'\b(?:odometer|odo|mileage)\s*out\s*[:#]?\s*(\d{3,8})\b',
);
final _serviceOdometerInPattern = RegExp(
  r'(?:\b(?:odometer|odo|mileage)\s*in|\bmiles in)\s*[:#]?\s*(\d{3,8})\b',
);
final _serviceOdometerPattern = RegExp(
  r'\b(?<!prior )(?<!previous )(?<!last )(?<!last recorded )(?:odometer|odo|vehicle mileage|mileage|current miles)\s*[:#]?\s*(\d{3,8})\b',
);
final _dueOdometerPattern = RegExp(
  r'\b(?:next service due|next service|next due|due at|service due at|next oil change)\D{0,24}(\d{4,8})\b',
);
final _intervalMilesPattern = RegExp(
  r'\b(?:due in|interval|every|next service in)\D{0,16}(\d{3,6})\s*(?:mi|mile|miles)\b',
);
final _serviceOdometerKilometersPattern = RegExp(
  r'\b(?:odometer|odo|mileage)(?:\s*(?:in|out))?\s*[:#]?\s*\d{3,8}\s*(?:kms?|kilomet(?:er|re)s?)\b',
);
final _dueOdometerKilometersPattern = RegExp(
  r'\b(?:next service due|next service|next due|due at|service due at|next oil change)\D{0,24}\d{4,8}\s*(?:kms?|kilomet(?:er|re)s?)\b',
);
final _intervalKilometersPattern = RegExp(
  r'\b(?:due in|interval|every|next service in)\D{0,16}\d{3,6}\s*(?:kms?|kilomet(?:er|re)s?)\b',
);
final _intervalMonthsPattern = RegExp(
  r'\b(?:due in|interval|every|next service in)\D{0,16}(\d{1,2})\s*(?:mo|month|months)\b',
);

T? _enumValue<T extends Enum>(List<T> values, Object? raw) {
  final name = '$raw';
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

int? _jsonInt(Object? raw) {
  return raw is int ? raw : int.tryParse('$raw');
}

int? _jsonNonNegativeInt(Object? raw) {
  if (raw == null) return null;
  final value = _jsonInt(raw);
  if (value == null || value < 0) {
    throw const FormatException('Receipt integer field is invalid.');
  }
  return value;
}

double? _jsonDouble(Object? raw) {
  final value = raw is num ? raw.toDouble() : double.tryParse('$raw');
  return value != null && value.isFinite ? value : null;
}

DateTime? _jsonDate(Object? raw) {
  if (raw == null) return null;
  final value = DateTime.tryParse('$raw');
  if (value == null) throw const FormatException('Receipt date is invalid.');
  return value;
}

String? _jsonNullableString(Object? raw) {
  if (raw == null) return null;
  final value = '$raw'.trim();
  return value.isEmpty ? null : value;
}

List<Map<dynamic, dynamic>> _jsonMaps(Object? raw) {
  if (raw is! Iterable) {
    throw const FormatException('Receipt list is invalid.');
  }
  return [
    for (final value in raw)
      if (value is Map)
        value
      else
        throw const FormatException('Receipt list entry is invalid.'),
  ];
}
