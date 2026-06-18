part of 'expense_receipt_parser.dart';

final _mealMerchantProfiles = [
  for (final merchant in _mealMerchantSeeds)
    _MerchantProfile(
      displayName: merchant.name,
      pattern: RegExp(merchant.pattern),
      defaultCategory: 'Meals',
    ),
];

const _mealMerchantSeeds = [
  _MerchantSeed('McDonald\'s', r"\b(mcdonald'?s|mcdonalds)\b"),
  _MerchantSeed('Burger King', r'\b(burger king)\b'),
  _MerchantSeed('Chick-fil-A', r'\b(chick-fil-a|chick fil a)\b'),
  _MerchantSeed('Hardee\'s', r"\b(hardee'?s|hardees)\b"),
  _MerchantSeed('Wendy\'s', r"\b(wendy'?s|wendys)\b"),
  _MerchantSeed('Subway', r'\b(subway)\b'),
  _MerchantSeed('Starbucks', r'\b(starbucks)\b'),
  _MerchantSeed('Dunkin\'', r"\b(dunkin'?|dunkin donuts)\b"),
  _MerchantSeed('Taco Bell', r'\b(taco bell)\b'),
  _MerchantSeed('Bojangles', r"\b(bojangles|bo'?s chicken)\b"),
  _MerchantSeed('Popeyes', r"\b(popeyes|popeye'?s)\b"),
  _MerchantSeed('KFC', r'\b(kfc|kentucky fried chicken)\b'),
  _MerchantSeed('Arby\'s', r"\b(arby'?s|arbys)\b"),
  _MerchantSeed('Sonic', r'\b(sonic drive|sonic)\b'),
  _MerchantSeed('Panera Bread', r'\b(panera)\b'),
  _MerchantSeed('Chipotle', r'\b(chipotle)\b'),
  _MerchantSeed('Domino\'s', r"\b(domino'?s|dominos)\b"),
  _MerchantSeed('Pizza Hut', r'\b(pizza hut)\b'),
];
