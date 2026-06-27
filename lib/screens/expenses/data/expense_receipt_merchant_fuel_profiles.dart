part of 'expense_receipt_parser.dart';

final _fuelMerchantProfiles = [
  for (final merchant in _fuelMerchantSeeds)
    _MerchantProfile(
      displayName: merchant.name,
      pattern: RegExp(merchant.pattern),
      defaultCategory: 'Fuel',
      secondaryCategories: const ['Meals', 'Groceries', 'Vehicle Supplies'],
    ),
];

class _MerchantSeed {
  const _MerchantSeed(
    this.name,
    this.pattern, {
    this.merchantType = FuelMerchantType.regionalConvenience,
    this.regions = const [],
    this.states = const [],
  });

  final String name;
  final String pattern;
  final FuelMerchantType merchantType;
  final List<String> regions;
  final List<String> states;
}

enum FuelMerchantType {
  fuelBrand,
  groceryFuel,
  regionalConvenience,
  truckStop,
  evCharging,
}

class FuelMerchantRegistryAudit {
  const FuelMerchantRegistryAudit({
    required this.vendorCount,
    required this.typeCounts,
    required this.regionCounts,
    required this.stateCounts,
    required this.vendorsMissingRegionMetadata,
    required this.vendorsMissingStateMetadata,
    required this.duplicateVendorNames,
    required this.invalidStateCodes,
  });

  final int vendorCount;
  final Map<FuelMerchantType, int> typeCounts;
  final Map<String, int> regionCounts;
  final Map<String, int> stateCounts;
  final List<String> vendorsMissingRegionMetadata;
  final List<String> vendorsMissingStateMetadata;
  final List<String> duplicateVendorNames;
  final List<String> invalidStateCodes;

  bool get passesCoreHealth =>
      vendorCount >= 75 &&
      typeCounts.keys.length >= 4 &&
      duplicateVendorNames.isEmpty &&
      invalidStateCodes.isEmpty;

  bool get hasStateLevelCoverage => stateCounts.length >= 30;
}

FuelMerchantRegistryAudit auditFuelMerchantRegistry() {
  final typeCounts = <FuelMerchantType, int>{};
  final regionCounts = <String, int>{};
  final stateCounts = <String, int>{};
  final seenNames = <String>{};
  final duplicateNames = <String>{};
  final missingRegions = <String>[];
  final missingStates = <String>[];
  final invalidStates = <String>[];

  for (final merchant in _fuelMerchantSeeds) {
    typeCounts.update(
      merchant.merchantType,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    final normalizedName = merchant.name.toLowerCase();
    if (!seenNames.add(normalizedName)) duplicateNames.add(merchant.name);
    if (merchant.regions.isEmpty) missingRegions.add(merchant.name);
    if (merchant.states.isEmpty &&
        merchant.merchantType != FuelMerchantType.fuelBrand &&
        merchant.merchantType != FuelMerchantType.evCharging) {
      missingStates.add(merchant.name);
    }
    for (final region in merchant.regions) {
      regionCounts.update(region, (value) => value + 1, ifAbsent: () => 1);
    }
    for (final state in merchant.states) {
      if (!_validFuelMerchantStateCodes.contains(state)) {
        invalidStates.add('${merchant.name}:$state');
      }
      stateCounts.update(state, (value) => value + 1, ifAbsent: () => 1);
    }
  }

  return FuelMerchantRegistryAudit(
    vendorCount: _fuelMerchantSeeds.length,
    typeCounts: Map.unmodifiable(typeCounts),
    regionCounts: Map.unmodifiable(regionCounts),
    stateCounts: Map.unmodifiable(stateCounts),
    vendorsMissingRegionMetadata: List.unmodifiable(missingRegions),
    vendorsMissingStateMetadata: List.unmodifiable(missingStates),
    duplicateVendorNames: List.unmodifiable(duplicateNames),
    invalidStateCodes: List.unmodifiable(invalidStates),
  );
}

const _allUsRegions = ['US'];
const _northeastRegions = ['US-NE'];
const _midAtlanticRegions = ['US-MA'];
const _southeastRegions = ['US-SE'];
const _midwestRegions = ['US-MW'];
const _southCentralRegions = ['US-SC'];
const _mountainWestRegions = ['US-MWST'];
const _westRegions = ['US-W'];
const _canadaRegions = ['CA'];
const _northAmericaRegions = ['US', 'CA'];
const _evRegions = ['US', 'CA', 'EV'];

const _validFuelMerchantStateCodes = {
  'AL',
  'AK',
  'AZ',
  'AR',
  'CA',
  'CO',
  'CT',
  'DE',
  'FL',
  'GA',
  'HI',
  'ID',
  'IL',
  'IN',
  'IA',
  'KS',
  'KY',
  'LA',
  'ME',
  'MD',
  'MA',
  'MI',
  'MN',
  'MS',
  'MO',
  'MT',
  'NE',
  'NV',
  'NH',
  'NJ',
  'NM',
  'NY',
  'NC',
  'ND',
  'OH',
  'OK',
  'OR',
  'PA',
  'RI',
  'SC',
  'SD',
  'TN',
  'TX',
  'UT',
  'VT',
  'VA',
  'WA',
  'WV',
  'WI',
  'WY',
  'DC',
  'PR',
};

const _fuelMerchantSeeds = [
  _MerchantSeed(
    'Shell',
    r'\b(shell|shell oil)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _northAmericaRegions,
  ),
  _MerchantSeed(
    'Exxon',
    r'\b(exxon|exxonmobil|exxon mobil)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _allUsRegions,
  ),
  _MerchantSeed(
    'Mobil',
    r'\b(mobil|exxonmobil|exxon mobil)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _allUsRegions,
  ),
  _MerchantSeed(
    'BP',
    r'\b(bp|bp#|british petroleum)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _allUsRegions,
  ),
  _MerchantSeed(
    'Chevron',
    r'\b(chevron)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _allUsRegions,
  ),
  _MerchantSeed(
    'Texaco',
    r'\b(texaco)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _allUsRegions,
  ),
  _MerchantSeed(
    'Conoco',
    r'\b(conoco)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _allUsRegions,
  ),
  _MerchantSeed(
    'Phillips 66',
    r'\b(phillips 66|phillips66)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _allUsRegions,
  ),
  _MerchantSeed(
    '76',
    r'\b(76 station|union 76)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _westRegions,
  ),
  _MerchantSeed(
    'Marathon',
    r'\b(marathon)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _allUsRegions,
  ),
  _MerchantSeed(
    'Speedway',
    r'\b(speedway)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _allUsRegions,
  ),
  _MerchantSeed(
    'Sunoco',
    r'\b(sunoco)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _allUsRegions,
  ),
  _MerchantSeed(
    'Valero',
    r'\b(valero)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _allUsRegions,
  ),
  _MerchantSeed(
    'CITGO',
    r'\b(citgo)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _allUsRegions,
  ),
  _MerchantSeed(
    'Sinclair',
    r'\b(sinclair)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _allUsRegions,
  ),
  _MerchantSeed(
    'Gulf',
    r'\b(gulf oil|gulf)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _allUsRegions,
  ),
  _MerchantSeed(
    'ARCO',
    r'\b(arco)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _westRegions,
  ),
  _MerchantSeed(
    'Amoco',
    r'\b(amoco)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _allUsRegions,
  ),
  _MerchantSeed(
    'Hess',
    r'\b(hess express|hess gas|hess station)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _northeastRegions,
  ),
  _MerchantSeed(
    'Irving Oil',
    r'\b(irving oil|irving mainway)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _northAmericaRegions,
  ),
  _MerchantSeed(
    'Petro-Canada',
    r'\b(petro[- ]?canada)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _canadaRegions,
  ),
  _MerchantSeed(
    'Esso',
    r'\b(esso)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _canadaRegions,
  ),
  _MerchantSeed(
    'Ultramar',
    r'\b(ultramar)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _canadaRegions,
  ),
  _MerchantSeed(
    'Pioneer Energy',
    r'\b(pioneer energy|pioneer gas)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _canadaRegions,
  ),
  _MerchantSeed(
    'Flying A',
    r'\b(flying a)\b',
    merchantType: FuelMerchantType.fuelBrand,
    regions: _westRegions,
  ),
  _MerchantSeed(
    'ampm',
    r'\b(am\s*pm|ampm|am/pm)\b',
    regions: _westRegions,
    states: ['AZ', 'CA', 'NV', 'OR', 'WA'],
  ),
  _MerchantSeed(
    'Kwik Trip',
    r'\b(kwik trip|kwik star)\b',
    regions: _midwestRegions,
    states: ['IA', 'IL', 'MI', 'MN', 'SD', 'WI'],
  ),
  _MerchantSeed(
    'Kum & Go',
    r'\b(kum and go|kum & go)\b',
    regions: _midwestRegions,
    states: ['AR', 'CO', 'IA', 'MN', 'MO', 'MT', 'NE', 'ND', 'OK', 'SD', 'WY'],
  ),
  _MerchantSeed(
    'Maverik',
    r'\b(maverik)\b',
    regions: _mountainWestRegions,
    states: [
      'AZ',
      'CO',
      'ID',
      'MT',
      'NE',
      'NV',
      'NM',
      'OR',
      'SD',
      'UT',
      'WA',
      'WY',
    ],
  ),
  _MerchantSeed(
    'Buc-ee\'s',
    r"\b(buc-ee'?s|bucees)\b",
    regions: _southeastRegions,
    states: ['AL', 'CO', 'FL', 'GA', 'KY', 'MO', 'SC', 'TN', 'TX'],
  ),
  _MerchantSeed(
    'Rutter\'s',
    r"\b(rutter'?s|rutters)\b",
    regions: _midAtlanticRegions,
    states: ['MD', 'PA', 'WV'],
  ),
  _MerchantSeed(
    'Royal Farms',
    r'\b(royal farms)\b',
    regions: _midAtlanticRegions,
    states: ['DE', 'MD', 'NJ', 'PA', 'VA', 'WV'],
  ),
  _MerchantSeed(
    'GetGo',
    r'\b(getgo|get go)\b',
    regions: _midwestRegions,
    states: ['IN', 'MD', 'OH', 'PA', 'WV'],
  ),
  _MerchantSeed(
    'Thorntons',
    r'\b(thorntons)\b',
    regions: _midwestRegions,
    states: ['FL', 'IL', 'IN', 'KY', 'OH', 'TN'],
  ),
  _MerchantSeed(
    'Turkey Hill',
    r'\b(turkey hill)\b',
    regions: _midAtlanticRegions,
    states: ['IN', 'OH', 'PA'],
  ),
  _MerchantSeed(
    'Murphy USA',
    r'\b(murphy usa|murphy express|murphy exp)\b',
    regions: _allUsRegions,
    states: [
      'AL',
      'AR',
      'FL',
      'GA',
      'IA',
      'IL',
      'IN',
      'KY',
      'LA',
      'MO',
      'MS',
      'NC',
      'OH',
      'OK',
      'SC',
      'TN',
      'TX',
    ],
  ),
  _MerchantSeed(
    'Murphy Oil',
    r'\b(murphy oil)\b',
    regions: _allUsRegions,
    states: ['AR', 'LA', 'TX'],
  ),
  _MerchantSeed(
    'Cumberland Farms',
    r"\b(cumberland farms|cumby'?s)\b",
    regions: _northeastRegions,
    states: ['CT', 'FL', 'MA', 'ME', 'NH', 'NY', 'RI', 'VT'],
  ),
  _MerchantSeed(
    'Fastrac',
    r'\b(fastrac|fastrack)\b',
    regions: _northeastRegions,
    states: ['NY'],
  ),
  _MerchantSeed(
    'Fas Mart',
    r'\b(fas mart|fasmart)\b',
    regions: _southeastRegions,
    states: ['GA', 'NC', 'SC', 'VA'],
  ),
  _MerchantSeed(
    'Scotchman',
    r'\b(scotchman)\b',
    regions: _southeastRegions,
    states: ['NC', 'SC'],
  ),
  _MerchantSeed(
    'Roadrunner Markets',
    r'\b(roadrunner markets?|road runner markets?)\b',
    regions: _southeastRegions,
    states: ['NC', 'SC', 'TN', 'VA'],
  ),
  _MerchantSeed(
    'Village Pantry',
    r'\b(village pantry)\b',
    regions: _midwestRegions,
    states: ['IL', 'IN', 'MI', 'OH'],
  ),
  _MerchantSeed(
    'E-Z Mart',
    r'\b(e[- ]?z mart|ez mart)\b',
    regions: _southCentralRegions,
    states: ['AR', 'LA', 'OK', 'TX'],
  ),
  _MerchantSeed(
    'Town Pump',
    r'\b(town pump)\b',
    regions: _mountainWestRegions,
    states: ['MT'],
  ),
  _MerchantSeed(
    'Holiday Stationstores',
    r'\b(holiday stationstores?|holiday gas|holiday fuel|holiday stores?)\b',
    regions: _midwestRegions,
    states: ['AK', 'ID', 'MI', 'MN', 'MT', 'ND', 'SD', 'WA', 'WI'],
  ),
  _MerchantSeed(
    'Loaf N Jug',
    r"\b(loaf n jug|loaf '?n jug|loaf and jug)\b",
    regions: _mountainWestRegions,
    states: ['CO', 'MT', 'NE', 'NM', 'ND', 'OK', 'SD', 'WY'],
  ),
  _MerchantSeed(
    'Tom Thumb',
    r'\b(tom thumb fuel|tom thumb food stores?)\b',
    regions: _southeastRegions,
    states: ['AL', 'FL'],
  ),
  _MerchantSeed(
    'Kangaroo Express',
    r'\b(kangaroo express|kangaroo)\b',
    regions: _southeastRegions,
    states: ['AL', 'FL', 'GA', 'NC', 'SC', 'TN', 'VA'],
  ),
  _MerchantSeed(
    'Stripes',
    r'\b(stripes convenience|stripes store|stripes fuel)\b',
    regions: _southCentralRegions,
    states: ['LA', 'NM', 'OK', 'TX'],
  ),
  _MerchantSeed(
    'Allsup\'s',
    r"\b(allsup'?s|allsups)\b",
    regions: _southCentralRegions,
    states: ['NM', 'OK', 'TX'],
  ),
  _MerchantSeed(
    'Yesway',
    r'\b(yesway)\b',
    regions: _southCentralRegions,
    states: ['IA', 'KS', 'MO', 'NE', 'NM', 'OK', 'SD', 'TX', 'WY'],
  ),
  _MerchantSeed(
    'United Dairy Farmers',
    r'\b(united dairy farmers|udf)\b',
    regions: _midwestRegions,
    states: ['IN', 'KY', 'OH'],
  ),
  _MerchantSeed(
    'Spinx',
    r'\b(spinx)\b',
    regions: _southeastRegions,
    states: ['SC'],
  ),
  _MerchantSeed(
    'Parker\'s',
    r"\b(parker'?s kitchen|parker'?s fuel|parkers kitchen)\b",
    regions: _southeastRegions,
    states: ['GA', 'SC'],
  ),
  _MerchantSeed(
    'Weigel\'s',
    r"\b(weigel'?s|weigels)\b",
    regions: _southeastRegions,
    states: ['TN'],
  ),
  _MerchantSeed(
    'Twice Daily',
    r'\b(twice daily)\b',
    regions: _southeastRegions,
    states: ['AL', 'KY', 'TN'],
  ),
  _MerchantSeed(
    'MAPCO',
    r'\b(mapco|mapco express)\b',
    regions: _southeastRegions,
    states: ['AL', 'AR', 'GA', 'KY', 'MS', 'TN'],
  ),
  _MerchantSeed(
    'CEFCO',
    r'\b(cefco)\b',
    regions: _southCentralRegions,
    states: ['AL', 'AR', 'FL', 'LA', 'MS', 'OK', 'TX'],
  ),
  _MerchantSeed(
    'DK',
    r'\b(dk fuel|dk convenience|delek)\b',
    regions: _southCentralRegions,
    states: ['AR', 'NM', 'TX'],
  ),
  _MerchantSeed(
    'GATE',
    r'\b(gate petroleum|gate express|gate store)\b',
    regions: _southeastRegions,
    states: ['FL', 'GA', 'NC', 'SC'],
  ),
  _MerchantSeed(
    'Daily\'s',
    r"\b(daily'?s convenience|dailys convenience|daily'?s fuel)\b",
    regions: _southeastRegions,
    states: ['FL', 'GA', 'NC'],
  ),
  _MerchantSeed(
    'Enmarket',
    r'\b(enmarket)\b',
    regions: _southeastRegions,
    states: ['GA', 'NC', 'SC'],
  ),
  _MerchantSeed(
    'Jiffy Trip',
    r'\b(jiffy trip)\b',
    regions: _southCentralRegions,
    states: ['OK'],
  ),
  _MerchantSeed(
    'Rebel',
    r'\b(rebel convenience|rebel gas|rebel stores?)\b',
    regions: _westRegions,
    states: ['AZ', 'CA', 'FL', 'NV'],
  ),
  _MerchantSeed(
    'Green Valley Grocery',
    r'\b(green valley grocery|gvg)\b',
    regions: _westRegions,
    states: ['NV'],
  ),
  _MerchantSeed(
    'Terrible Herbst',
    r"\b(terrible herbst|terrible'?s)\b",
    regions: _westRegions,
    states: ['AZ', 'CA', 'NV', 'UT'],
  ),
  _MerchantSeed(
    'Rotten Robbie',
    r'\b(rotten robbie)\b',
    regions: _westRegions,
    states: ['CA'],
  ),
  _MerchantSeed(
    'Jacksons',
    r'\b(jacksons food stores?|jacksons fuel)\b',
    regions: _westRegions,
    states: ['AZ', 'CA', 'ID', 'NV', 'OR', 'UT', 'WA'],
  ),
  _MerchantSeed(
    'Redwood Markets',
    r'\b(redwood markets?|redwood oil)\b',
    regions: _westRegions,
    states: ['CA'],
  ),
  _MerchantSeed(
    'ExtraMile',
    r'\b(extramile|extra mile)\b',
    regions: _westRegions,
    states: ['AK', 'AZ', 'CA', 'HI', 'ID', 'NV', 'OR', 'UT', 'WA'],
  ),
  _MerchantSeed(
    'Hele',
    r'\b(hele gas|hele station|hele fuel)\b',
    regions: _westRegions,
    states: ['HI'],
  ),
  _MerchantSeed(
    'Aloha Island Mart',
    r'\b(aloha island mart|aloha petroleum)\b',
    regions: _westRegions,
    states: ['HI'],
  ),
  _MerchantSeed(
    'GoMart',
    r'\b(go[- ]?mart)\b',
    regions: _midAtlanticRegions,
    states: ['OH', 'VA', 'WV'],
  ),
  _MerchantSeed(
    'Par Mar',
    r'\b(par mar|parmar)\b',
    regions: _midAtlanticRegions,
    states: ['KY', 'MD', 'OH', 'PA', 'VA', 'WV'],
  ),
  _MerchantSeed(
    'Mega Saver',
    r'\b(mega saver)\b',
    regions: _midwestRegions,
    states: ['IA', 'NE'],
  ),
  _MerchantSeed(
    'Kent Kwik',
    r'\b(kent kwik|kentkwik|kent companies)\b',
    regions: _southCentralRegions,
    states: ['NM', 'OK', 'TX'],
  ),
  _MerchantSeed(
    'Coen',
    r'\b(coen markets?|coen oil)\b',
    regions: _midAtlanticRegions,
    states: ['OH', 'PA', 'WV'],
  ),
  _MerchantSeed(
    'Crosby\'s',
    r"\b(crosby'?s|crosbys)\b",
    regions: _northeastRegions,
    states: ['NY', 'PA'],
  ),
  _MerchantSeed(
    'Mirabito',
    r'\b(mirabito)\b',
    regions: _northeastRegions,
    states: ['NY', 'PA', 'VT'],
  ),
  _MerchantSeed(
    'Byrne Dairy',
    r'\b(byrne dairy)\b',
    regions: _northeastRegions,
    states: ['NY'],
  ),
  _MerchantSeed(
    'Cliff\'s Local Market',
    r"\b(cliff'?s local market|cliffs local market)\b",
    regions: _northeastRegions,
    states: ['NY'],
  ),
  _MerchantSeed(
    'NOCO',
    r'\b(noco express|noco fuel|noco gas)\b',
    regions: _northeastRegions,
    states: ['NY'],
  ),
  _MerchantSeed(
    'High\'s',
    r"\b(high'?s dairy|high'?s convenience|highs dairy|highs convenience)\b",
    regions: _midAtlanticRegions,
    states: ['MD', 'PA', 'VA', 'WV'],
  ),
  _MerchantSeed(
    'Dash In',
    r'\b(dash in)\b',
    regions: _midAtlanticRegions,
    states: ['DE', 'MD', 'VA'],
  ),
  _MerchantSeed(
    'Pilot Flying J',
    r'\b(pilot|pilot trvl ctr|pilot travel center|flying j|flyingj|pilot flying j)\b',
    merchantType: FuelMerchantType.truckStop,
    regions: _allUsRegions,
  ),
  _MerchantSeed(
    'Love\'s',
    r"\b(love'?s travel|loves travel|love'?s|loves)\b",
    merchantType: FuelMerchantType.truckStop,
    regions: _allUsRegions,
  ),
  _MerchantSeed(
    'TravelCenters of America',
    r'\b(travelcenters of america|travel centers of america|ta travel|ta-petro|petro stopping|petro)\b',
    merchantType: FuelMerchantType.truckStop,
    regions: _allUsRegions,
  ),
  _MerchantSeed('Circle K', r'\b(circle k)\b', regions: _allUsRegions),
  _MerchantSeed(
    '7-Eleven Hawaii',
    r'\b(7-eleven hawaii|7 eleven hawaii)\b',
    regions: _westRegions,
    states: ['HI'],
  ),
  _MerchantSeed(
    '7-Eleven',
    r'\b(7-eleven|7 eleven|seven eleven|7eleven)\b',
    regions: _allUsRegions,
  ),
  _MerchantSeed(
    'OXXO',
    r'\b(oxxo)\b',
    regions: _northAmericaRegions,
    states: ['NM', 'TX'],
  ),
  _MerchantSeed(
    'Wawa',
    r'\b(wawa)\b',
    regions: _midAtlanticRegions,
    states: ['AL', 'FL', 'GA', 'MD', 'NJ', 'NC', 'OH', 'PA', 'VA'],
  ),
  _MerchantSeed(
    'Sheetz',
    r'\b(sheetz)\b',
    regions: _midAtlanticRegions,
    states: ['MD', 'MI', 'NC', 'OH', 'PA', 'VA', 'WV'],
  ),
  _MerchantSeed(
    'QuikTrip',
    r'\b(quiktrip|quick trip|qt kitchens|qt)\b',
    regions: _allUsRegions,
    states: [
      'AL',
      'AZ',
      'CO',
      'GA',
      'IA',
      'IL',
      'KS',
      'MO',
      'NC',
      'NE',
      'OK',
      'SC',
      'TX',
    ],
  ),
  _MerchantSeed(
    'QuickChek',
    r'\b(quickchek|quick chek)\b',
    regions: _northeastRegions,
    states: ['NJ', 'NY'],
  ),
  _MerchantSeed(
    'Quickie',
    r'\b(quickie)\b',
    regions: _northeastRegions,
    states: ['NY'],
  ),
  _MerchantSeed(
    'RaceTrac',
    r'\b(racetrac|race trac)\b',
    regions: _southeastRegions,
    states: ['AL', 'FL', 'GA', 'KY', 'LA', 'MS', 'SC', 'TN', 'TX'],
  ),
  _MerchantSeed(
    'RaceWay',
    r'\b(raceway)\b',
    regions: _southeastRegions,
    states: ['AL', 'FL', 'GA', 'LA', 'MS', 'NC', 'SC', 'TN', 'TX'],
  ),
  _MerchantSeed(
    'Casey\'s',
    r"\b(casey'?s|caseys)\b",
    regions: _midwestRegions,
    states: [
      'AR',
      'IL',
      'IN',
      'IA',
      'KS',
      'KY',
      'MI',
      'MN',
      'MO',
      'ND',
      'NE',
      'OH',
      'OK',
      'SD',
      'TN',
      'TX',
      'WI',
    ],
  ),
  _MerchantSeed(
    'Cenex',
    r'\b(cenex)\b',
    regions: _midwestRegions,
    states: [
      'CO',
      'IA',
      'ID',
      'IL',
      'KS',
      'MI',
      'MN',
      'MT',
      'ND',
      'NE',
      'OR',
      'SD',
      'WA',
      'WI',
      'WY',
    ],
  ),
  _MerchantSeed(
    'Huck\'s',
    r"\b(huck'?s|hucks)\b",
    regions: _midwestRegions,
    states: ['IL', 'IN', 'KY', 'MO', 'TN'],
  ),
  _MerchantSeed(
    'Minit Mart',
    r'\b(minit mart|minute mart)\b',
    regions: _southeastRegions,
    states: ['GA', 'KY', 'NC', 'OH', 'TN'],
  ),
  _MerchantSeed(
    'Plaid Pantry',
    r'\b(plaid pantry)\b',
    regions: _westRegions,
    states: ['OR', 'WA'],
  ),
  _MerchantSeed(
    'Stewart\'s Shops',
    r"\b(stewart'?s shops|stewarts shops)\b",
    regions: _northeastRegions,
    states: ['NY', 'VT'],
  ),
  _MerchantSeed(
    'OnCue',
    r'\b(oncue|on cue)\b',
    regions: _southCentralRegions,
    states: ['OK', 'TX'],
  ),
  _MerchantSeed(
    'ChargePoint',
    r'\b(chargepoint)\b',
    merchantType: FuelMerchantType.evCharging,
    regions: _evRegions,
  ),
  _MerchantSeed(
    'Tesla Supercharger',
    r'\b(tesla supercharger|supercharger)\b',
    merchantType: FuelMerchantType.evCharging,
    regions: _evRegions,
  ),
  _MerchantSeed(
    'Electrify America',
    r'\b(electrify america)\b',
    merchantType: FuelMerchantType.evCharging,
    regions: _evRegions,
  ),
  _MerchantSeed(
    'EVgo',
    r'\b(evgo|ev go)\b',
    merchantType: FuelMerchantType.evCharging,
    regions: _evRegions,
  ),
];
