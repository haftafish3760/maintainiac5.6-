part of 'expense_receipt_parser.dart';

final _autoServiceMerchantProfiles = [
  _MerchantProfile(
    displayName: 'Advance Auto Parts',
    pattern: RegExp(r'\b(advance auto|aap store|advanceauto)\b'),
    defaultCategory: 'Maintenance',
  ),
  _MerchantProfile(
    displayName: 'AutoZone',
    pattern: RegExp(r'\b(autozone|auto zone)\b'),
    defaultCategory: 'Maintenance',
    secondaryCategories: const ['Tools', 'Vehicle Parts', 'Vehicle Supplies'],
  ),
  _MerchantProfile(
    displayName: "O'Reilly Auto Parts",
    pattern: RegExp(r"\b(o'?reilly|oreilly)\b"),
    defaultCategory: 'Maintenance',
    secondaryCategories: const ['Tools', 'Vehicle Parts', 'Vehicle Supplies'],
  ),
  _MerchantProfile(
    displayName: 'NAPA Auto Parts',
    pattern: RegExp(r'\b(napa|napa auto|napa auto parts)\b'),
    defaultCategory: 'Maintenance',
    secondaryCategories: const ['Tools', 'Vehicle Parts', 'Vehicle Supplies'],
  ),
  _MerchantProfile(
    displayName: 'Jiffy Lube',
    pattern: RegExp(r'\b(jiffy lube)\b'),
    defaultCategory: 'Maintenance',
    secondaryCategories: const ['Repair'],
  ),
  _MerchantProfile(
    displayName: 'Goodyear',
    pattern: RegExp(r'\b(goodyear)\b'),
    defaultCategory: 'Maintenance',
    secondaryCategories: const ['Repair'],
  ),
  _MerchantProfile(
    displayName: 'Firestone',
    pattern: RegExp(r'\b(firestone)\b'),
    defaultCategory: 'Maintenance',
    secondaryCategories: const ['Repair'],
  ),
  _MerchantProfile(
    displayName: 'Mavis Tires & Brakes',
    pattern: RegExp(r'\b(mavis|mavis tires)\b'),
    defaultCategory: 'Maintenance',
    secondaryCategories: const ['Repair'],
  ),
  _MerchantProfile(
    displayName: 'Valvoline',
    pattern: RegExp(r'\b(valvoline)\b'),
    defaultCategory: 'Maintenance',
    secondaryCategories: const ['Repair'],
  ),
  _MerchantProfile(
    displayName: 'Take 5 Oil Change',
    pattern: RegExp(r'\b(take 5|take five oil)\b'),
    defaultCategory: 'Maintenance',
    secondaryCategories: const ['Repair'],
  ),
  _MerchantProfile(
    displayName: 'Pep Boys',
    pattern: RegExp(r'\b(pep boys|pepboys)\b'),
    defaultCategory: 'Maintenance',
    secondaryCategories: const ['Repair', 'Vehicle Parts', 'Vehicle Supplies'],
  ),
  _MerchantProfile(
    displayName: 'Midas',
    pattern: RegExp(r'\b(midas)\b'),
    defaultCategory: 'Repair',
    secondaryCategories: const ['Maintenance'],
  ),
  _MerchantProfile(
    displayName: 'Meineke',
    pattern: RegExp(r'\b(meineke)\b'),
    defaultCategory: 'Repair',
    secondaryCategories: const ['Maintenance'],
  ),
  _MerchantProfile(
    displayName: 'Discount Tire',
    pattern: RegExp(r'\b(discount tire)\b'),
    defaultCategory: 'Maintenance',
    secondaryCategories: const ['Repair'],
  ),
  _MerchantProfile(
    displayName: 'NTB',
    pattern: RegExp(r'\b(ntb|national tire)\b'),
    defaultCategory: 'Maintenance',
    secondaryCategories: const ['Repair'],
  ),
];
