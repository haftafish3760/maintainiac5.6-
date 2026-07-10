part of 'expense_receipt_parser.dart';

final _categoryRules = [
  _CategoryKeywordRule(
    category: 'Fuel',
    pattern: RegExp(
      r'\b(diesel|dsl|d1|d2|ulsd|ultra low sulfur diesel|clear diesel|'
      r'highway diesel|on road diesel|on-road diesel|b(?:[1-9]|[1-9]\d|100)|biodiesel|'
      r'reefer fuel|tractor diesel|'
      r'truck diesel|off road diesel|off-road diesel|dyed diesel|'
      r'red diesel|red dye diesel|red dyed diesel|farm diesel|ag diesel|'
      r'renewable diesel|rd20|rd99|r20|r99|hvo|hvo100|'
      r'hydrotreated vegetable oil|hpr diesel|hpr fuel|'
      r'def fluid|diesel exhaust fluid|gasoline|gas |fuel|'
      r'fuel sale|motor fuel|unl\b|reg unl|unleaded|plus unleaded|'
      r'premium|regular|midgrade|super unleaded|no ethanol|ethanol free|'
      r'non ethanol|rec fuel|recreational fuel|marine gas|marine fuel|e0|'
      r'cng|lng|compressed natural gas|liquefied natural gas|'
      r'gas natural comprimido|renewable natural gas|rng|gge|dge|'
      r'propane|lpg|l\.?p\.? gas|gas l\.?p\.?|autogas|auto gas|'
      r'hydrogen|h2 fuel|fuel cell|kg h2|'
      r'e[- ]?10|e[- ]?15|e[- ]?20|e[- ]?30|e[- ]?50|e[- ]?85|'
      r'flex fuel|flexfuel|gasohol|ethanol|'
      r'octane|87 octane|89 octane|91 octane|'
      r'93 octane|pump|island|ev charge|charging|carga el[eé]ctrica|'
      r'carga ev|sesi[oó]n de carga|energy sale|energy delivered|energia delivered|'
      r'energ[ií]a|chargepoint|'
      r'tesla supercharger|supercharger|kerosene|kero|queroseno|k[- ]?1)\b',
    ),
    confidence: .94,
    reason: 'Fuel keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Charging Fees',
    pattern: RegExp(
      r'\b(ev charging fee|charging fee|session fee|idle fee|ev parking fee|connection fee|station fee|(?:dcfc|evse|charging)\s+(?:time|minutes?|mins?)|cuota de sesi[oó]n|tarifa de sesi[oó]n|tarifa por inactividad|tarifa por minuto|cuota de carga|tarifa de carga)\b',
    ),
    confidence: .9,
    reason: 'EV charging fee keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Maintenance',
    pattern: RegExp(
      r'\b(oil change|lube service|motor oil|engine oil|full synthetic|'
      r'synthetic oil|synthetic motor oil|synthetic blend|oil filter|'
      r'air filter|cabin filter|brake pads?|'
      r'brake fluid|tire|tires|tire rotation|tpms|wiper|wiper blades?|'
      r'coolant|antifreeze|washer fluid|battery|spark plug|'
      r'transmission fluid|fuel filter|serpentine belt|headlight|'
      r'taillight|bulb)\b',
    ),
    confidence: .9,
    reason: 'Maintenance keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Repair',
    pattern: RegExp(
      r'\b(repair|labor|labour|diagnostic|diag\b|tow|towing|alignment|mount and balance|mount/balance|install|installation|mechanic|shop supplies|hazmat|environmental fee|service fee)\b',
    ),
    confidence: .86,
    reason: 'Repair keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Vehicle Parts',
    pattern: RegExp(
      r'\b(rotor|caliper|alternator|starter|radiator|thermostat|'
      r'water pump|fuel pump|sensor|oxygen sensor|o2 sensor|strut|shock|'
      r'bearing|hub assembly|cv axle|tie rod|control arm|muffler|'
      r'catalytic|brake shoes?|brake hardware|hose assembly|'
      r'belt tensioner)\b',
    ),
    confidence: .86,
    reason: 'Vehicle parts keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Vehicle Supplies',
    pattern: RegExp(
      r'\b(car wash|wash wax|microfiber|funnel|tire shine|'
      r'glass cleaner|degreaser|floor mat|phone mount|charger cable|'
      r'jumper cable|booster cable|ratchet strap|bungee|cargo strap|'
      r'air freshener|ice scraper|snow brush|shop towels?|'
      r'lavado de auto|lavado de carro)\b',
    ),
    confidence: .82,
    reason: 'Vehicle supply keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Tolls',
    pattern: RegExp(
      r'\b(toll|turnpike|ezpass|e-zpass|sunpass|peach pass|fastrak|i-pass|ipass|good to go|express lane)\b',
    ),
    confidence: .92,
    reason: 'Toll keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Parking',
    pattern: RegExp(
      r'\b(parking|parking fee|garage|meter|valet|parkmobile|spot hero|spothero|estacionamiento)\b',
    ),
    confidence: .9,
    reason: 'Parking keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Insurance',
    pattern: RegExp(r'\b(insurance|premium|policy)\b'),
    confidence: .86,
    reason: 'Insurance keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Registration',
    pattern: RegExp(r'\b(registration|tag renewal|license plate|dmv)\b'),
    confidence: .9,
    reason: 'Registration keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Cell Phone',
    pattern: RegExp(
      r'\b(phone|cellular|mobile|wireless|verizon|at&t|att|t-mobile|tmobile|spectrum mobile|xfinity mobile|cricket|boost mobile|metro by t-mobile|visible)\b',
    ),
    confidence: .9,
    reason: 'Cell phone keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Materials',
    pattern: RegExp(
      r'\b(lumber|stud|2x4|2x6|2x8|2x10|2x12|deck board|'
      r'treated board|pressure treated|trim board|baseboard|moulding|'
      r'molding|pipe|pvc|cpvc|pex|copper|cop|cu|black iron|'
      r'galvanized|sharkbite|fitting|elbow|street elbow|tee|wye|'
      r'coupling|adapter|bushing|reducer|union|valve|ball valve|'
      r'gate valve|supply line|wax ring|plumbers? putty|plumbing putty|'
      r'putty|paint|primer|stain|polyurethane|caulk|silicone|sealant|'
      r'adhesive|liquid nails|thinset|grout|mortar|concrete mix|cement|'
      r'screws?|scrws?|nails?|fasteners?|anchors?|lag bolt|washer|nut|'
      r'plywood|osb|drywall|sheetrock|joint compound|spackle|mud pan|'
      r'corner bead|conduit|emt|romex|nm-b|uf-b|thhn|wire|breaker|'
      r'gfci|outlet|receptacle|switch|junction box|cover plate|'
      r'capacitor|run capacitor|dual run capacitor|mfd|pleated filter|'
      r'furnace filter|ac filter|hvac filter|duct|ductwork|mastic|'
      r'foil tape|hvac tape|painters? tape|masking tape|filter grille|'
      r'register|vent cover|line set|refrigerant line|shingle|roofing|'
      r'flashing|drip edge|underlayment|housewrap|flashing tape)\b',
    ),
    confidence: .88,
    reason: 'Material keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Tools',
    pattern: RegExp(
      r'\b(tool|drill|impact|driver|blade|bit|wrench|saw|socket|'
      r'ratchet|plier|pliers|level|laser level|tape measure|hammer|'
      r'sander|grinder|multimeter|tester|snips|knife|toolbox|tool box)\b',
    ),
    confidence: .88,
    reason: 'Tool keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Groceries',
    pattern: RegExp(
      r'\b(grocery|groceries|produce|plu|milk|bread|eggs|cheese|meat|'
      r'chicken breast|water case|case water|bottled water|soda|fruit|'
      r'bananas?|apples?|lettuce|paper towels|toilet paper|snack pack|'
      r'granola|yogurt|agua|botella|agua botella)\b',
    ),
    confidence: .82,
    reason: 'Grocery keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Personal',
    pattern: RegExp(
      r'\b(cig(?:arette)?s?|cigar|tobacco|nicotine|vape|beer|wine|'
      r'alcohol|liquor|lottery|lotto|scratch(?:er|off)?|atm fee|'
      r'atm surcharge|cash advance|cerveza|cigarrillos?|loter[ií]a)\b',
    ),
    confidence: .9,
    reason: 'Personal convenience item keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Meals',
    pattern: RegExp(
      r'\b(meal|food|coffee|snacks?|restaurant|sandwich|sub\b|burger|'
      r'pizza|breakfast|lunch|dinner|combo|fries|drink|biscuit|chicken|'
      r'taco|burrito|wrap|salad|donut|doughnut|latte|cafe|'
      r'comida|bebida)\b|café',
    ),
    confidence: .84,
    reason: 'Meal keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Cleaning Supplies',
    pattern: RegExp(
      r'\b(cleaner|bleach|disinfect|soap|detergent|trash bags?|paper towels?|mop|broom|sponge|wipes)\b',
    ),
    confidence: .84,
    reason: 'Cleaning supply keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Office Supplies',
    pattern: RegExp(
      r'\b(paper|printer ink|toner|pen|pencil|folder|binder|notebook|envelope|clipboard)\b',
    ),
    confidence: .82,
    reason: 'Office supply keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Safety Gear',
    pattern: RegExp(
      r'\b(safety vest|gloves|hard hat|safety glasses|ear plugs|respirator|mask|knee pads)\b',
    ),
    confidence: .86,
    reason: 'Safety gear keyword matched.',
  ),
  _CategoryKeywordRule(
    category: 'Utilities',
    pattern: RegExp(r'\b(electric bill|water bill|gas bill|utility)\b'),
    confidence: .84,
    reason: 'Utility keyword matched.',
  ),
];
