part of 'work_supply_receipt_parser.dart';

int _plumbingReceiptScore(
  String text,
  String trade,
  String category,
  String system,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'plumbing') return score;
  if (RegExp(
    r'\b(copper|pvc|cpvc|pex|dwv|pipe|fitting|coupling|elbow|tee|valve|brass)\b',
  ).hasMatch(text)) {
    score += 12;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final receiptSaysTee = RegExp(r'\b(tee|t)\b').hasMatch(text);
  final receiptSaysCoupling = RegExp(
    r'\b(coupling|coup|cplg|coupler)\b',
  ).hasMatch(text);
  final receiptSaysPipe = RegExp(r'\b(pipe|stick)\b').hasMatch(text);
  final receiptSaysNipple = RegExp(r'\b(nipple|npt nipple)\b').hasMatch(text);
  final receiptSaysSupplyStop = RegExp(
    r'\b(supply stop|angle stop|straight stop|stop valve|shutoff|shut off)\b',
  ).hasMatch(text);
  final receiptSaysPvc = RegExp(r'\b(pvc|sch40|schedule 40)\b').hasMatch(text);
  final receiptSaysToiletRepair = RegExp(
    r'\b(toilet wax|wax ring|fill valve|flush valve|flapper|tank lever|tank bolt|toilet flange|flange repair)\b',
  ).hasMatch(text);
  final receiptSaysLowVoltageThermostatAdapter = RegExp(
    r'\b(c-wire adapter|common wire adapter|thermostat c-wire adapter|thermostat wire|stat wire|low voltage wire)\b',
  ).hasMatch(text);
  final receiptSaysWaterHeaterPart =
      RegExp(
        r'\b(water heater|relief valve|t p valve|t and p valve|temperature pressure|drain valve|dielectric nipple|anode|anode rod|heating element|water heater element|thermostat)\b',
      ).hasMatch(text) &&
      !receiptSaysLowVoltageThermostatAdapter;
  final receiptSaysSupplyLine = RegExp(
    r'\b(supply line|faucet connector|toilet connector|closet line|lav supply|braided line|dishwasher line|icemaker line|washer hose)\b',
  ).hasMatch(text);
  final receiptSaysFaucetRepair = RegExp(
    r'\b(faucet cartridge|faucet stem|faucet repair|o ring|seat washer|aerator|pop up drain|pop-up drain|basket strainer|sink strainer)\b',
  ).hasMatch(text);
  final receiptSaysShowerTubRepair = RegExp(
    r'\b(shower cartridge|mixing valve cartridge|shower trim|tub spout|diverter spout|shower head|shower arm|tub waste|tub drain|tub stopper)\b',
  ).hasMatch(text);
  final receiptSaysPumpPart = RegExp(
    r'\b(sump pump|condensate pump|pump check valve|discharge hose|pump tubing|pump float|float switch|piggyback|high water alarm|pump alarm)\b',
  ).hasMatch(text);
  final receiptSaysDrainFinishPart = RegExp(
    r'\b(basket strainer|sink strainer|air gap|dishwasher branch|dishwasher hose|disposal flange|disposal connector|splash guard|trap adapter|'
    r'marvel adapter|desanco|wall bend|trap arm|slip joint|slip nut|slip washer|nut washer|nut and washer|escutcheon|cleanout|clean out|floor drain|'
    r'drain grate|closet flange repair|flange repair ring|flange spacer|closet bolt cap)\b',
  ).hasMatch(text);
  final receiptSaysSealServicePart = RegExp(
    r'\b(faucet washer|bib washer|seat washer|o ring|o-ring|oring|stem packing|valve packing|bonnet packing|packing nut|flush valve seal|tank gasket|'
    r'tank to bowl|closet seal|toilet seal|hose washer|hose bibb washer|vacuum breaker|anti siphon|anti-siphon|pipe dope|thread sealant|ptfe tape|teflon tape|gas tape)\b',
  ).hasMatch(text);
  if (RegExp(r'\b(cond pump|condensate pump|little pump)\b').hasMatch(text)) {
    score -= 80;
  }
  if (receiptSaysTee && itemType.contains('tee')) score += 18;
  if (RegExp(r'\bpex\b').hasMatch(text) && receiptSaysTee) {
    if (itemName.contains('pex tee')) {
      score += 140;
    } else if (!itemName.contains('pex')) {
      score -= 48;
    }
  }
  if (receiptSaysTee && !text.contains(' x ') && item.variant.contains(' x ')) {
    score -= 24;
  }
  if (receiptSaysCoupling && itemType.contains('coupling')) score += 18;
  if (RegExp(
    r'\b(slip joint|slip nut|slip washer|nut washer)\b',
  ).hasMatch(text)) {
    if (itemType.contains('slip joint nuts and washers') ||
        itemName.contains('slip joint nut and washer')) {
      score += 180;
    } else if (itemName.contains('beveled washer') ||
        itemName.contains('poly washer') ||
        itemName.contains('drain pan')) {
      score -= 80;
    }
  }
  if (receiptSaysPipe && category == 'pipe and tubing') score += 24;
  if (receiptSaysNipple && itemType.contains('nipple')) score += 26;
  if (RegExp(r'\b(bi|black iron|black pipe)\b').hasMatch(text) &&
      receiptSaysNipple &&
      itemName.contains('black iron') &&
      itemName.contains('nipple')) {
    score += 92;
  }
  if (receiptSaysPipe && category == 'fittings') score -= 24;
  if (receiptSaysTee && itemType.contains('coupling')) score -= 22;
  if (receiptSaysCoupling && itemType.contains('tee')) score -= 22;
  if (receiptSaysNipple && itemType.contains('elbow')) score -= 18;
  if (receiptSaysPvc && text.contains('ball valve')) {
    if (itemName.contains('pvc ball valve')) {
      score += 58;
    } else if (itemName.contains('ball valve') && !itemName.contains('pvc')) {
      score -= 24;
    }
  }
  if (receiptSaysSupplyStop) {
    if (itemType.contains('supply stop') ||
        itemType.contains('stop valve') ||
        itemName.contains('supply stop') ||
        itemName.contains('stop valve')) {
      score += 64;
      if (text.contains('escutcheon') &&
          item.aliases.any(
            (alias) => _normalize(alias).contains('escutcheon'),
          )) {
        score += 86;
      }
    } else if (itemType.contains('elbow') || itemName.contains('elbow')) {
      score -= 40;
    }
  }
  if (receiptSaysToiletRepair && category == 'toilet repair') {
    score += 36;
    for (final term in [
      'wax ring',
      'fill valve',
      'flush valve',
      'flapper',
      'tank lever',
      'tank bolt',
      'toilet flange',
      'flange repair',
    ]) {
      if (text.contains(term) && itemName.contains(term)) score += 48;
    }
  }
  if (receiptSaysSupplyLine && category == 'supply lines') {
    score += 42;
    for (final term in [
      'faucet supply line',
      'toilet supply line',
      'appliance supply line',
      'gas appliance connector',
    ]) {
      if (itemName.contains(term)) score += 18;
    }
    for (final term in [
      'faucet connector',
      'toilet connector',
      'closet line',
      'lav supply',
      'dishwasher line',
      'icemaker line',
      'washer hose',
      'gas connector',
    ]) {
      if (text.contains(term) &&
          item.aliases.any((alias) => _normalize(alias).contains(term))) {
        score += 42;
      }
    }
  }
  if (receiptSaysFaucetRepair && category == 'sink and faucet repair') {
    score += 42;
    for (final term in [
      'faucet cartridge',
      'faucet stem',
      'faucet o-ring',
      'faucet aerator',
      'lavatory pop-up assembly',
      'kitchen sink basket strainer',
    ]) {
      if (itemName.contains(term)) score += 24;
    }
    for (final term in [
      'pop up drain',
      'pop-up drain',
      'basket strainer',
      'sink strainer',
      'aerator',
      'faucet stem',
      'faucet cartridge',
    ]) {
      if (text.contains(term) &&
          (itemName.contains(term.replaceAll('pop-up', 'pop-up')) ||
              item.aliases.any((alias) => _normalize(alias).contains(term)))) {
        score += 46;
      }
    }
  }
  if (receiptSaysShowerTubRepair && category == 'shower and tub repair') {
    score += 42;
    for (final term in [
      'shower cartridge',
      'shower valve trim kit',
      'tub spout',
      'shower head',
      'shower arm',
      'tub waste and overflow kit',
      'tub drain stopper',
    ]) {
      if (itemName.contains(term)) score += 28;
    }
    for (final term in [
      'mixing valve cartridge',
      'diverter spout',
      'showerhead',
      'tub drain kit',
      'tub stopper',
    ]) {
      if (text.contains(term) &&
          item.aliases.any((alias) => _normalize(alias).contains(term))) {
        score += 46;
      }
    }
  }
  if (receiptSaysDrainFinishPart &&
      category == 'drain and finish service stock') {
    score += 46;
    if (RegExp(r'\b(nut washer|nut and washer)\b').hasMatch(text) &&
        itemName.contains('slip joint nut and washer')) {
      score += 140;
    }
    if (receiptSaysSupplyStop) score -= 68;
    for (final term in [
      'basket strainer',
      'sink strainer',
      'air gap',
      'dishwasher branch',
      'dishwasher hose',
      'disposal connector',
      'disposal flange',
      'splash guard',
      'trap adapter',
      'marvel adapter',
      'desanco',
      'wall bend',
      'trap arm',
      'slip nut',
      'slip washer',
      'escutcheon',
      'cleanout',
      'clean out',
      'floor drain',
      'drain grate',
      'flange repair',
      'flange spacer',
      'closet bolt',
    ]) {
      if (text.contains(term) &&
          (itemName.contains(term) ||
              item.aliases.any((alias) => _normalize(alias).contains(term)))) {
        score += 56;
      }
    }
    if (text.contains('clean out') && itemName.contains('cleanout')) {
      score += 44;
    }
    if (text.contains('closet flange repair') &&
        itemName.contains('closet flange repair')) {
      score += 58;
    }
    if (text.contains('dishwasher branch') &&
        itemName.contains('dishwasher branch')) {
      score += 58;
    }
    if (text.contains('floor drain') && itemName.contains('floor drain')) {
      score += 50;
    }
  }
  if (receiptSaysSealServicePart &&
      category == 'seals packing and thread service') {
    score += 48;
    for (final term in [
      'faucet washer',
      'bib washer',
      'seat washer',
      'o ring',
      'o-ring',
      'stem packing',
      'valve packing',
      'bonnet packing',
      'packing nut',
      'flush valve seal',
      'tank gasket',
      'tank to bowl',
      'closet seal',
      'toilet seal',
      'hose washer',
      'hose bibb washer',
      'vacuum breaker',
      'anti siphon',
      'anti-siphon',
      'pipe dope',
      'thread sealant',
      'ptfe tape',
      'teflon tape',
      'gas tape',
    ]) {
      if (text.contains(term) &&
          (itemName.contains(term.replaceAll('o ring', 'o-ring')) ||
              itemName.contains(term.replaceAll('teflon', 'ptfe')) ||
              item.aliases.any((alias) => _normalize(alias).contains(term)))) {
        score += 58;
      }
    }
    if (text.contains('pipe dope') &&
        itemName.contains('pipe joint compound')) {
      score += 66;
    }
    if (text.contains('teflon tape') && itemName.contains('ptfe tape')) {
      score += 66;
    }
    if (text.contains('vacuum breaker') &&
        itemName.contains('vacuum breaker')) {
      score += 62;
    }
    if (text.contains('hose bibb') && itemName.contains('hose bibb')) {
      score += 52;
    }
  }
  final isWaterHeaterItem =
      category == 'water heater' || itemName.contains('water heater');
  final isPumpItem = category == 'pumps' || itemName.contains('pump');
  if (receiptSaysWaterHeaterPart && isWaterHeaterItem) {
    score += 38;
    if (RegExp(r'\b(anode|anode rod)\b').hasMatch(text)) {
      if (itemName.contains('water heater repair part') ||
          item.aliases.any((alias) => _normalize(alias).contains('anode'))) {
        score += 180;
      } else if (itemName.contains('relief valve') ||
          itemName.contains('drain valve') ||
          itemName.contains('dielectric')) {
        score -= 54;
      }
    }
    if (RegExp(
      r'\b(heating element|water heater element|element)\b',
    ).hasMatch(text)) {
      if (itemName.contains('water heater repair part') ||
          item.aliases.any((alias) => _normalize(alias).contains('element'))) {
        score += 160;
      } else if (itemName.contains('relief valve') ||
          itemName.contains('drain valve') ||
          itemName.contains('dielectric')) {
        score -= 42;
      }
    }
    if (text.contains('thermostat') &&
        (itemName.contains('water heater repair part') ||
            item.aliases.any(
              (alias) => _normalize(alias).contains('thermostat'),
            ))) {
      score += 72;
    }
    if (RegExp(
          r'\b(relief valve|t p valve|t and p valve|temperature pressure)\b',
        ).hasMatch(text) &&
        itemName.contains('relief valve')) {
      score += 72;
      if (itemName.contains('temperature and pressure relief valve')) {
        score += 160;
      } else if (itemName.contains('water heater repair part')) {
        score -= 90;
      }
    }
    if (text.contains('drain valve') && itemName.contains('drain valve')) {
      score += 48;
    }
    if (text.contains('dielectric') && itemName.contains('dielectric')) {
      score += 48;
    }
  }
  if (receiptSaysPumpPart && isPumpItem) {
    score += 36;
    if (text.contains('pump check valve')) {
      if (itemName.contains('pump check valve')) {
        score += 140;
      } else if (!itemName.contains('check valve')) {
        score -= 44;
      }
    }
    if (RegExp(r'\b(float switch|piggyback|pump float)\b').hasMatch(text)) {
      if (itemName.contains('pump control part') ||
          item.aliases.any((alias) => _normalize(alias).contains('float'))) {
        score += 92;
      } else if (itemName.contains('sump pump')) {
        score -= 40;
      }
    }
    if (RegExp(r'\b(high water alarm|pump alarm)\b').hasMatch(text)) {
      if (itemName.contains('pump control part') ||
          item.aliases.any((alias) => _normalize(alias).contains('alarm'))) {
        score += 96;
      } else if (itemName.contains('sump pump')) {
        score -= 42;
      }
    }
    for (final term in [
      'sump pump',
      'condensate pump',
      'pump check valve',
      'discharge hose',
      'pump tubing',
      'float switch',
    ]) {
      if (text.contains(term) && itemName.contains(term)) score += 48;
    }
  }
  if (system == 'brass') {
    if (text.contains('compression') && itemType.contains('compression')) {
      score += 18;
    }
    if (text.contains('flare') && itemType.contains('flare')) score += 18;
    if (text.contains('barb') && itemType.contains('barb')) score += 18;
    if (text.contains('union') && itemType.contains('union')) score += 18;
  }
  if (RegExp(
    r'\b(stud|lumber|kd|wood|romex|gfci|emt|conduit)\b',
  ).hasMatch(text)) {
    score -= 18;
  }
  return score;
}
