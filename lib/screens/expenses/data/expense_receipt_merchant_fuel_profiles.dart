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
  ..._fuelMerchantBrandSeeds,
  ..._fuelMerchantRegionalSeeds,
  ..._fuelMerchantTruckEvSeeds,
];
