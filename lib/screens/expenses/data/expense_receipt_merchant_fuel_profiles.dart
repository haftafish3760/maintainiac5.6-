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
  const _MerchantSeed(this.name, this.pattern);

  final String name;
  final String pattern;
}

const _fuelMerchantSeeds = [
  _MerchantSeed('Shell', r'\b(shell)\b'),
  _MerchantSeed('Exxon', r'\b(exxon)\b'),
  _MerchantSeed('Mobil', r'\b(mobil)\b'),
  _MerchantSeed('BP', r'\b(bp|british petroleum)\b'),
  _MerchantSeed('Chevron', r'\b(chevron)\b'),
  _MerchantSeed('Texaco', r'\b(texaco)\b'),
  _MerchantSeed('Conoco', r'\b(conoco)\b'),
  _MerchantSeed('Phillips 66', r'\b(phillips 66|phillips66)\b'),
  _MerchantSeed('76', r'\b(76 station|union 76)\b'),
  _MerchantSeed('Marathon', r'\b(marathon)\b'),
  _MerchantSeed('Speedway', r'\b(speedway)\b'),
  _MerchantSeed('Sunoco', r'\b(sunoco)\b'),
  _MerchantSeed('Valero', r'\b(valero)\b'),
  _MerchantSeed('CITGO', r'\b(citgo)\b'),
  _MerchantSeed('Sinclair', r'\b(sinclair)\b'),
  _MerchantSeed('Gulf', r'\b(gulf oil|gulf)\b'),
  _MerchantSeed('ARCO', r'\b(arco)\b'),
  _MerchantSeed('Amoco', r'\b(amoco)\b'),
  _MerchantSeed('Kwik Trip', r'\b(kwik trip|kwik star)\b'),
  _MerchantSeed('Kum & Go', r'\b(kum and go|kum & go)\b'),
  _MerchantSeed('Maverik', r'\b(maverik)\b'),
  _MerchantSeed('Buc-ee\'s', r"\b(buc-ee'?s|bucees)\b"),
  _MerchantSeed('Rutter\'s', r"\b(rutter'?s|rutters)\b"),
  _MerchantSeed('Royal Farms', r'\b(royal farms)\b'),
  _MerchantSeed('GetGo', r'\b(getgo|get go)\b'),
  _MerchantSeed('Thorntons', r'\b(thorntons)\b'),
  _MerchantSeed('Turkey Hill', r'\b(turkey hill)\b'),
  _MerchantSeed('Murphy USA', r'\b(murphy usa|murphy express)\b'),
  _MerchantSeed('Pilot Flying J', r'\b(pilot|flying j|pilot flying j)\b'),
  _MerchantSeed('Love\'s', r"\b(love'?s travel|loves travel|love'?s)\b"),
  _MerchantSeed(
    'TravelCenters of America',
    r'\b(travelcenters of america|travel centers of america|ta travel|ta-petro|petro stopping|petro)\b',
  ),
  _MerchantSeed('Circle K', r'\b(circle k)\b'),
  _MerchantSeed('7-Eleven', r'\b(7-eleven|7 eleven|seven eleven)\b'),
  _MerchantSeed('Wawa', r'\b(wawa)\b'),
  _MerchantSeed('Sheetz', r'\b(sheetz)\b'),
  _MerchantSeed('QuikTrip', r'\b(quiktrip|quick trip|qt kitchens|qt)\b'),
  _MerchantSeed('QuickChek', r'\b(quickchek|quick chek)\b'),
  _MerchantSeed('Quickie', r'\b(quickie)\b'),
  _MerchantSeed('RaceTrac', r'\b(racetrac|race trac)\b'),
  _MerchantSeed('RaceWay', r'\b(raceway)\b'),
  _MerchantSeed('Casey\'s', r"\b(casey'?s|caseys)\b"),
  _MerchantSeed('Cenex', r'\b(cenex)\b'),
  _MerchantSeed('Huck\'s', r"\b(huck'?s|hucks)\b"),
  _MerchantSeed('Minit Mart', r'\b(minit mart|minute mart)\b'),
  _MerchantSeed('Mapco', r'\b(mapco)\b'),
  _MerchantSeed('Plaid Pantry', r'\b(plaid pantry)\b'),
  _MerchantSeed('Stewart\'s Shops', r"\b(stewart'?s shops|stewarts shops)\b"),
  _MerchantSeed('OnCue', r'\b(oncue|on cue)\b'),
  _MerchantSeed('ChargePoint', r'\b(chargepoint)\b'),
  _MerchantSeed('Tesla Supercharger', r'\b(tesla supercharger|supercharger)\b'),
  _MerchantSeed('Electrify America', r'\b(electrify america)\b'),
  _MerchantSeed('EVgo', r'\b(evgo|ev go)\b'),
];
