part of 'fuel_synthetic_parser_runner.dart';

class _FuelSyntheticProduct {
  const _FuelSyntheticProduct({
    required this.label,
    required this.spanishLabel,
    required this.fuelType,
    required this.unit,
    required this.basePrice,
  });

  final String label;
  final String spanishLabel;
  final String fuelType;
  final String unit;
  final double basePrice;
}

class _FuelSyntheticReceipt {
  const _FuelSyntheticReceipt({
    required this.name,
    required this.text,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    required this.unit,
    required this.fuelType,
    required this.expectedFillType,
    required this.locale,
    required this.odometer,
    required this.expectMixed,
    required this.expectCashExclusion,
    required this.expectDirtyText,
    required this.expectCommaDecimals,
    required this.expectPreauthHold,
    required this.expectFleetTenderExclusion,
    required this.expectPersonalConvenience,
    required this.expectMultiFuel,
    required this.expectPerUnitDiscount,
    required this.expectRewardUnitDiscount,
    required this.expectAlternatePrice,
    required this.expectMissingVolume,
    required this.expectEvMissingKwh,
    required this.expectHubometer,
    required this.expectNonEthanol,
    required this.expectWarehouseFuel,
    required this.expectPrivateIdentity,
    required this.expectDispenserShorthand,
    required this.secondaryQuantity,
    required this.secondaryUnitPrice,
    required this.secondaryAmount,
    required this.secondaryUnit,
    required this.secondaryFuelType,
    required this.expectedDiscountAdjustment,
    required this.expectedChargingFee,
    required this.expectedParkingFee,
    required this.expectedTax,
    required this.expectedCarWashAmount,
    required this.expectedPrepayRefundAmount,
  });

  final String name;
  final String text;
  final double quantity;
  final double unitPrice;
  final double amount;
  final String unit;
  final String fuelType;
  final String expectedFillType;
  final String locale;
  final int? odometer;
  final bool expectMixed;
  final bool expectCashExclusion;
  final bool expectDirtyText;
  final bool expectCommaDecimals;
  final bool expectPreauthHold;
  final bool expectFleetTenderExclusion;
  final bool expectPersonalConvenience;
  final bool expectMultiFuel;
  final bool expectPerUnitDiscount;
  final bool expectRewardUnitDiscount;
  final bool expectAlternatePrice;
  final bool expectMissingVolume;
  final bool expectEvMissingKwh;
  final bool expectHubometer;
  final bool expectNonEthanol;
  final bool expectWarehouseFuel;
  final bool expectPrivateIdentity;
  final bool expectDispenserShorthand;
  final double? secondaryQuantity;
  final double? secondaryUnitPrice;
  final double? secondaryAmount;
  final String? secondaryUnit;
  final String? secondaryFuelType;
  final double? expectedDiscountAdjustment;
  final double? expectedChargingFee;
  final double? expectedParkingFee;
  final double? expectedTax;
  final double? expectedCarWashAmount;
  final double? expectedPrepayRefundAmount;
}

const _products = [
  _FuelSyntheticProduct(
    label: 'REG UNL',
    spanishLabel: 'Gasolina Magna Regular',
    fuelType: 'Gasoline',
    unit: 'gallon',
    basePrice: 3.199,
  ),
  _FuelSyntheticProduct(
    label: 'PREMIUM UNLEADED',
    spanishLabel: 'Gasolina Premium',
    fuelType: 'Gasoline',
    unit: 'gallon',
    basePrice: 4.099,
  ),
  _FuelSyntheticProduct(
    label: 'DIESEL',
    spanishLabel: 'Diésel',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 3.899,
  ),
  _FuelSyntheticProduct(
    label: '#2 ULSD',
    spanishLabel: 'Gasoil Diésel No. 2',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 3.849,
  ),
  _FuelSyntheticProduct(
    label: 'ULTRA LOW SULFUR DIESEL',
    spanishLabel: 'Diésel Ultra Bajo Azufre',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 3.869,
  ),
  _FuelSyntheticProduct(
    label: 'ON-ROAD CLEAR DIESEL',
    spanishLabel: 'Diésel Claro de Carretera',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 3.879,
  ),
  _FuelSyntheticProduct(
    label: 'B20 DIESEL',
    spanishLabel: 'B20 Diésel',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 3.799,
  ),
  _FuelSyntheticProduct(
    label: 'B5 BIODIESEL',
    spanishLabel: 'Biodiesel B5',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 3.779,
  ),
  _FuelSyntheticProduct(
    label: 'B99 BIODIESEL',
    spanishLabel: 'Biodiesel B99',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 3.949,
  ),
  _FuelSyntheticProduct(
    label: 'B100 BIODIESEL',
    spanishLabel: 'Biodiesel B100',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 4.129,
  ),
  _FuelSyntheticProduct(
    label: 'OFF ROAD DIESEL',
    spanishLabel: 'Diésel Rojo',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 3.499,
  ),
  _FuelSyntheticProduct(
    label: 'RED DIESEL',
    spanishLabel: 'Diésel Rojo',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 3.529,
  ),
  _FuelSyntheticProduct(
    label: 'RD99 RENEWABLE DIESEL',
    spanishLabel: 'Diésel Renovable RD99',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 4.099,
  ),
  _FuelSyntheticProduct(
    label: 'R20 RENEWABLE DIESEL',
    spanishLabel: 'Diésel Renovable R20',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 3.959,
  ),
  _FuelSyntheticProduct(
    label: 'R99 RENEWABLE DIESEL',
    spanishLabel: 'Diésel Renovable R99',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 4.119,
  ),
  _FuelSyntheticProduct(
    label: 'HVO100 RENEWABLE DIESEL',
    spanishLabel: 'Diésel Renovable HVO100',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 4.149,
  ),
  _FuelSyntheticProduct(
    label: 'HPR DIESEL',
    spanishLabel: 'Diésel HPR',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 3.989,
  ),
  _FuelSyntheticProduct(
    label: 'DEF FLUID',
    spanishLabel: 'Fluido DEF',
    fuelType: 'DEF',
    unit: 'gallon',
    basePrice: 4.299,
  ),
  _FuelSyntheticProduct(
    label: 'DIESEL EXHAUST FLUID',
    spanishLabel: 'Fluido de Escape Diesel',
    fuelType: 'DEF',
    unit: 'gallon',
    basePrice: 4.319,
  ),
  _FuelSyntheticProduct(
    label: 'KEROSENE',
    spanishLabel: 'Kerosene',
    fuelType: 'Kerosene',
    unit: 'gallon',
    basePrice: 4.899,
  ),
  _FuelSyntheticProduct(
    label: 'K-1 KEROSENE',
    spanishLabel: 'Queroseno K-1',
    fuelType: 'Kerosene',
    unit: 'gallon',
    basePrice: 4.919,
  ),
  _FuelSyntheticProduct(
    label: 'E85 105 FLEX FUEL',
    spanishLabel: 'E85 105 Combustible Flexible',
    fuelType: 'E85',
    unit: 'gallon',
    basePrice: 2.799,
  ),
  _FuelSyntheticProduct(
    label: 'E-85 FLEXFUEL',
    spanishLabel: 'E-85 Combustible Flexible',
    fuelType: 'E85',
    unit: 'gallon',
    basePrice: 2.819,
  ),
  _FuelSyntheticProduct(
    label: 'E15 UNLEADED 88',
    spanishLabel: 'E15 Gasolina',
    fuelType: 'E15',
    unit: 'gallon',
    basePrice: 3.059,
  ),
  _FuelSyntheticProduct(
    label: 'E-20 ETHANOL 20',
    spanishLabel: 'Etanol 20',
    fuelType: 'E20',
    unit: 'gallon',
    basePrice: 2.959,
  ),
  _FuelSyntheticProduct(
    label: 'E30 FLEX FUEL',
    spanishLabel: 'Etanol 30',
    fuelType: 'E30',
    unit: 'gallon',
    basePrice: 2.899,
  ),
  _FuelSyntheticProduct(
    label: 'E50 FLEX FUEL',
    spanishLabel: 'Etanol 50',
    fuelType: 'E50',
    unit: 'gallon',
    basePrice: 2.849,
  ),
  _FuelSyntheticProduct(
    label: 'E10 ETHANOL 10',
    spanishLabel: 'E10 Gasolina',
    fuelType: 'E10',
    unit: 'gallon',
    basePrice: 3.249,
  ),
  _FuelSyntheticProduct(
    label: 'E-0 ETHANOL FREE',
    spanishLabel: 'E-0 Sin Etanol',
    fuelType: 'Gasoline',
    unit: 'gallon',
    basePrice: 3.599,
  ),
  _FuelSyntheticProduct(
    label: 'CNG COMPRESSED NATURAL GAS',
    spanishLabel: 'GNV Gas Natural Comprimido',
    fuelType: 'CNG',
    unit: 'GGE',
    basePrice: 2.799,
  ),
  _FuelSyntheticProduct(
    label: 'RNG RENEWABLE NATURAL GAS',
    spanishLabel: 'Gas Natural Renovable',
    fuelType: 'CNG',
    unit: 'GGE',
    basePrice: 2.829,
  ),
  _FuelSyntheticProduct(
    label: 'LNG LIQUEFIED NATURAL GAS',
    spanishLabel: 'Gas Natural Licuado',
    fuelType: 'LNG',
    unit: 'DGE',
    basePrice: 3.129,
  ),
  _FuelSyntheticProduct(
    label: 'RNG LIQUEFIED NATURAL GAS',
    spanishLabel: 'Gas Natural Renovable',
    fuelType: 'LNG',
    unit: 'DGE',
    basePrice: 3.159,
  ),
  _FuelSyntheticProduct(
    label: 'LPG AUTOGAS',
    spanishLabel: 'Propano Autogas',
    fuelType: 'Propane',
    unit: 'gallon',
    basePrice: 2.649,
  ),
  _FuelSyntheticProduct(
    label: 'L.P. GAS',
    spanishLabel: 'GLP Gas LP',
    fuelType: 'Propane',
    unit: 'gallon',
    basePrice: 2.669,
  ),
  _FuelSyntheticProduct(
    label: 'LIQUEFIED PETROLEUM GAS',
    spanishLabel: 'Gas LP',
    fuelType: 'Propane',
    unit: 'gallon',
    basePrice: 2.679,
  ),
  _FuelSyntheticProduct(
    label: 'HD-5',
    spanishLabel: 'HD-5 Propano',
    fuelType: 'Propane',
    unit: 'gallon',
    basePrice: 2.689,
  ),
  _FuelSyntheticProduct(
    label: 'M85',
    spanishLabel: 'Metanol M85',
    fuelType: 'Methanol',
    unit: 'gallon',
    basePrice: 2.499,
  ),
  _FuelSyntheticProduct(
    label: 'M100 METHANOL',
    spanishLabel: 'Metanol M100',
    fuelType: 'Methanol',
    unit: 'gallon',
    basePrice: 2.529,
  ),
  _FuelSyntheticProduct(
    label: 'AVGAS 100LL',
    spanishLabel: 'Gasolina de Aviacion 100LL',
    fuelType: 'Aviation Gasoline',
    unit: 'gallon',
    basePrice: 6.499,
  ),
  _FuelSyntheticProduct(
    label: 'JET A-1',
    spanishLabel: 'Turbosina A-1',
    fuelType: 'Jet Fuel',
    unit: 'gallon',
    basePrice: 5.999,
  ),
  _FuelSyntheticProduct(
    label: 'RACE FUEL 110',
    spanishLabel: 'Combustible de Carrera 110',
    fuelType: 'Racing Fuel',
    unit: 'gallon',
    basePrice: 12.499,
  ),
  _FuelSyntheticProduct(
    label: 'NITROMETHANE',
    spanishLabel: 'Nitrometano',
    fuelType: 'Nitromethane',
    unit: 'gallon',
    basePrice: 38,
  ),
  _FuelSyntheticProduct(
    label: 'E100 ETHANOL',
    spanishLabel: 'Etanol E100',
    fuelType: 'E100',
    unit: 'gallon',
    basePrice: 3.25,
  ),
  _FuelSyntheticProduct(
    label: 'H2 HYDROGEN FUEL',
    spanishLabel: 'Hidrogeno H2',
    fuelType: 'Hydrogen',
    unit: 'kg',
    basePrice: 15.999,
  ),
  _FuelSyntheticProduct(
    label: 'H70',
    spanishLabel: 'H70 Hidrogeno',
    fuelType: 'Hydrogen',
    unit: 'kg',
    basePrice: 16.249,
  ),
  _FuelSyntheticProduct(
    label: 'H35',
    spanishLabel: 'H35 Hidrogeno',
    fuelType: 'Hydrogen',
    unit: 'kg',
    basePrice: 15.749,
  ),
  _FuelSyntheticProduct(
    label: 'ENERGY',
    spanishLabel: 'Energia',
    fuelType: 'Electric',
    unit: 'kWh',
    basePrice: .439,
  ),
];

const _merchants = [
  'SHELL',
  'EXXON',
  'PILOT TRVL CTR',
  'RIVER ROAD MART 418',
  'SUNOCO',
  'QUIKTRIP',
  'WAWA',
  'RACEWAY',
  ..._warehouseFuelMerchants,
];

const _warehouseFuelMerchants = [
  'KROGER FUEL CENTER',
  'COSTCO GASOLINE',
  'SAMS CLUB FUEL',
];
