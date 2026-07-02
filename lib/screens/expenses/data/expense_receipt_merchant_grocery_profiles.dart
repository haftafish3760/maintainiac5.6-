part of 'expense_receipt_parser.dart';

final _groceryMerchantProfiles = [
  _MerchantProfile(
    displayName: 'Walmart',
    pattern: RegExp(r'\b(walmart|wal-mart|wm supercenter)\b'),
    defaultCategory: 'Groceries',
    secondaryCategories: const [
      'Maintenance',
      'Vehicle Parts',
      'Vehicle Supplies',
      'Tools',
      'Meals',
      'Office Supplies',
      'Cleaning Supplies',
    ],
  ),
  _MerchantProfile(
    displayName: 'Target',
    pattern: RegExp(r'\b(target)\b'),
    defaultCategory: 'Groceries',
    secondaryCategories: const [
      'Meals',
      'Office Supplies',
      'Cleaning Supplies',
      'Vehicle Supplies',
      'Safety Gear',
    ],
  ),
  for (final merchant in _groceryFuelMerchantSeeds)
    _MerchantProfile(
      displayName: merchant.name,
      pattern: RegExp(merchant.pattern),
      defaultCategory: 'Groceries',
      secondaryCategories: const ['Meals', 'Fuel'],
    ),
  for (final merchant in _groceryMerchantSeeds)
    _MerchantProfile(
      displayName: merchant.name,
      pattern: RegExp(merchant.pattern),
      defaultCategory: 'Groceries',
      secondaryCategories: const ['Meals'],
    ),
  _MerchantProfile(
    displayName: 'Costco',
    pattern: RegExp(r'\b(costco)\b'),
    defaultCategory: 'Groceries',
    secondaryCategories: const ['Fuel', 'Meals', 'Vehicle Supplies'],
  ),
  _MerchantProfile(
    displayName: 'Sam\'s Club',
    pattern: RegExp(r"\b(sam'?s club|sams club)\b"),
    defaultCategory: 'Groceries',
    secondaryCategories: const ['Fuel', 'Meals', 'Vehicle Supplies'],
  ),
];

const _groceryFuelMerchantSeeds = [
  _MerchantSeed('Kroger', r'\b(kroger)\b'),
  _MerchantSeed('Meijer', r'\b(meijer)\b'),
  _MerchantSeed('H-E-B', r'\b(h-e-b|heb)\b'),
  _MerchantSeed('Safeway', r'\b(safeway)\b'),
  _MerchantSeed('Albertsons', r'\b(albertsons)\b'),
  _MerchantSeed('Giant Food', r'\b(giant food|giant)\b'),
  _MerchantSeed('Stop & Shop', r'\b(stop ?& ?shop|stop and shop)\b'),
  _MerchantSeed('Harris Teeter', r'\b(harris teeter)\b'),
];

const _groceryMerchantSeeds = [
  _MerchantSeed('Food Lion', r'\b(food lion)\b'),
  _MerchantSeed('Wegmans', r'\b(wegmans)\b'),
  _MerchantSeed('Publix', r'\b(publix)\b'),
  _MerchantSeed('Aldi', r'\b(aldi)\b'),
];
