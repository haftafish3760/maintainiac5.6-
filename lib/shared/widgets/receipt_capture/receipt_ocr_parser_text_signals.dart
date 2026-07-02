part of '../../receipts/receipt_ocr_contract.dart';

String _normalizeReceiptMerchantHeaderText(String line) {
  return line
      .toLowerCase()
      .replaceAll(RegExp(r'0'), 'o')
      .replaceAll(RegExp(r'[1!|]'), 'i')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

bool _looksLikeReceiptItemCandidate(String line) {
  final clean = line.trim();
  if (clean.length < 4) return false;
  final lower = clean.toLowerCase();
  if (_looksLikeReceiptReturnRefundOrCreditLine(clean)) return false;
  if (_hasReceiptTotalCandidate(clean) ||
      _hasReceiptTaxCandidate(clean) ||
      _hasReceiptSubtotalCandidate(clean)) {
    return false;
  }
  if (RegExp(
    r'\b(auth|balance|cash|change|coupon|discount|ebt|food\s*stamp|'
    r'gift\s*cards?|invoice|loyalty|markdown|merchant|payment|promo|'
    r'promotion|rebate|receipt|reward|rewards|saved|savings|snap|store|'
    r'survey|terminal|thank|transaction|visa|mastercard|amex|cards?)\b',
  ).hasMatch(lower)) {
    return false;
  }
  return RegExp(r'[a-zA-Z]').hasMatch(clean);
}

bool _looksLikeReceiptReturnRefundOrCreditLine(String line) {
  final lower = _normalizeReceiptSummaryKeywordText(line);
  if (!_hasReceiptPriceCandidate(line)) return false;
  return RegExp(
    r'\b(?:credit\s+balance|refund|return(?:ed)?|store\s+credit)\b',
  ).hasMatch(lower);
}

bool _looksLikeReceiptSkuOrCodeSignal(String line) {
  return RegExp(
    r'(?:^|\s)(?:sku|upc|item|model|part|#)?\s*#?[a-z0-9]*\d[a-z0-9#/-]{2,}(?:\s|$)',
    caseSensitive: false,
  ).hasMatch(line);
}

bool _looksLikeReceiptQuantityOrUnitSignal(String line) {
  return RegExp(
    r'\b(?:qty|quantity|pk|pack|ct|count|ea|each|gal|gals|gallon|gallons|qt|quart|oz|fl oz|lb|lbs|ft|feet|in|inch|inches|sq ft|yd|yard|yards|kwh)\b',
    caseSensitive: false,
  ).hasMatch(line);
}

bool _looksLikeReceiptAtPriceQuantitySignal(String line) {
  return RegExp(
    r'(?:^|\s)\d+(?:\.\d+)?\s*(?:@|x)\s*\$?\d',
    caseSensitive: false,
  ).hasMatch(line);
}

String _normalizeFuelReceiptSignalText(String line) {
  return line
      .toLowerCase()
      .replaceAll(RegExp(r'\bpr[1i!|]ce\b'), 'price')
      .replaceAll(RegExp(r'\bv[0o]l\b'), 'vol')
      .replaceAll(RegExp(r'\bqnty\b'), 'quantity')
      .replaceAll(RegExp(r'\bgall[0o]ns\b'), 'gallons')
      .replaceAll(RegExp(r'\bga[1il|!]\b'), 'gal')
      .replaceAll(RegExp(r'\bd[1i!|]esel\b'), 'diesel')
      .replaceAll(RegExp(r'\bfue[1i!|]\b'), 'fuel');
}

bool _looksLikeFuelReceiptQuantitySignal(String line) {
  final clean = _normalizeFuelReceiptSignalText(line);
  return RegExp(
    r'\b(\d+(?:\.\d+)?)\s*(?:gal|gals|gallon|gallons|gl|kwh|l|liter|liters)\b|\b(?:gal|gals|gallon|gallons|gl|volume|vol|qty|quantity|fuel\s+qty|fuel\s+volume|kwh)\s*[:#]?\s*(\d+(?:\.\d+)?)\b',
    caseSensitive: false,
  ).hasMatch(clean);
}

bool _looksLikeFuelReceiptUnitPriceSignal(String line) {
  final clean = _normalizeFuelReceiptSignalText(line);
  return RegExp(
    r'\b(?:price\s*/\s*(?:gal|gallon|kwh)|'
    r'price\s*per\s*(?:gal|gallon|kwh)|unit\s*price|fuel\s*price|'
    r'ppu|ppg|ppl|rate)\s*[:#]?\s*\$?\d+(?:\.\d{2,4})?\b|'
    r'\$?\d+\.\d{3,4}\s*/\s*(?:gal|gallon|g|kwh)\b|'
    r'\b\d+(?:\.\d+)?\s*(?:gal|gals|gallon|gallons|gl)\s+'
    r'\$?\d+\.\d{2,4}\b',
    caseSensitive: false,
  ).hasMatch(clean);
}

bool _looksLikeGenericReceiptItemText(String line) {
  return RegExp(
    r'\b(?:misc|general mdse|merchandise|item|department|dept|unknown)\b',
    caseSensitive: false,
  ).hasMatch(line);
}

bool _looksLikeMaterialExpenseLine(String line) {
  return RegExp(
    r'\b(?:adhesive|anchor|bolt|bracket|caulk|cement|concrete|conduit|'
    r'connector|coupling|copper|drywall|elbow|fastener|fitting|glue|'
    r'lumber|nail|nut|oatey|paint|pipe|plumber|plumbers|plywood|pvc|'
    r'putt|putty|screw|sealant|sheetrock|tee|thread|valve|washer|wire|'
    r'wood)\b',
    caseSensitive: false,
  ).hasMatch(line);
}

bool _looksLikeFuelExpenseLine(String line) {
  final clean = _normalizeFuelReceiptSignalText(line);
  return RegExp(
    r'\b(?:diesel|fuel|gasoline|gal|gals|gallon|gallons|midgrade|premium|price\s*/\s*gal|price\s*per\s*gal|pump|regular|unleaded|vol|volume)\b',
    caseSensitive: false,
  ).hasMatch(clean);
}

bool _looksLikeVehicleSupplyExpenseLine(String line) {
  return RegExp(
    r'\b(?:air freshener|battery|brake|brakes|bungee|cargo strap|'
    r'car wash|charger cable|coolant|def|degreaser|filter|floor mat|'
    r'fluid|funnel|glass cleaner|jumper cable|microfiber|motor oil|oil|'
    r'phone mount|ratchet strap|shop towels?|snow brush|tire|tires|'
    r'tire shine|wash wax|washer fluid|wiper|wipers)\b',
    caseSensitive: false,
  ).hasMatch(line);
}

bool _looksLikeFoodOrGroceryExpenseLine(String line) {
  return RegExp(
    r'\b(?:apple|apples|banana|bananas|beverage|bread|chips|coffee|deli|drink|eggs|food|fruit|grocery|meal|milk|produce|snack|soda|water)\b',
    caseSensitive: false,
  ).hasMatch(line);
}

bool _looksLikeBusinessSupplyExpenseLine(String line) {
  return RegExp(
    r'\b(?:batteries|binder|box|cleaner|envelope|glove|gloves|ink|marker|notebook|office|paper|pen|pencil|printer|tape|trash bags)\b',
    caseSensitive: false,
  ).hasMatch(line);
}

bool _looksLikeServiceExpenseLine(String line) {
  return RegExp(
    r'\b(?:delivery|fee|labor|labour|rental|service|shipping)\b',
    caseSensitive: false,
  ).hasMatch(line);
}

bool _looksLikeReceiptTenderLine(String line) {
  final clean = line.trim();
  if (_looksLikeReceiptTenderReferenceLine(clean)) return true;
  if (!_hasReceiptPriceCandidate(clean)) return false;
  final lower = clean.toLowerCase();
  return RegExp(
    r'\b(auth(?:code)?|balance|begin bal|card|cash|change|credit|debit|ebt|ending bal|food\s*stamp|gift|merchant/gift|paid|payment|snap|tender|transaction amt|visa|mastercard|amex|discover)\b',
  ).hasMatch(lower);
}

bool _looksLikeReceiptTenderReferenceLine(String line) {
  final lower = line.trim().toLowerCase();
  if (!RegExp(
    r'\b(auth(?:code)?|approval|card|gift|merchant/gift|reference|ref#?|trace)\b',
  ).hasMatch(lower)) {
    return false;
  }
  if (RegExp(
    r'\b(subtotal|tax|total|amount paid|amount due|balance due|change|cash|payment|paid|visa|mastercard|amex|discover)\b',
  ).hasMatch(_normalizeReceiptSummaryKeywordText(lower))) {
    return false;
  }
  return RegExp(r'\d{3,}').hasMatch(lower);
}

bool _looksLikeReceiptMetadataLine(String line) {
  final clean = line.trim();
  final lower = clean.toLowerCase();
  if (clean.length < 3) return false;
  if (_looksLikeLocalReceiptMerchantNameSignal(clean)) return false;
  if (_looksLikeReceiptAddressOrContactLine(clean)) return true;
  if (_hasReceiptPriceCandidate(clean)) return false;
  return RegExp(
    r'\b(auth(?:code)?|business\s*lic(?:ense)?|cashier|invoice|lic(?:ense)?\s*(?:no|num|number|#)?|order|register|sale#|sales#|store|tax\s*id|terminal|thank|trans#?|transaction)\b',
  ).hasMatch(lower);
}

bool _looksLikeReceiptAddressOrContactLine(String line) {
  final clean = line.trim();
  final lower = clean.toLowerCase();
  if (RegExp(r'\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}').hasMatch(clean)) {
    return true;
  }
  if (RegExp(r'\b\d{5}(?:-\d{4})?\b').hasMatch(clean) &&
      RegExp(
        r'\b(?:al|ak|az|ar|ca|co|ct|de|fl|ga|hi|ia|id|il|in|ks|ky|la|ma|md|me|mi|mn|mo|ms|mt|nc|nd|ne|nh|nj|nm|nv|ny|oh|ok|or|pa|ri|sc|sd|tn|tx|ut|va|vt|wa|wi|wv|wy)\b',
      ).hasMatch(lower)) {
    return true;
  }
  if (RegExp(
    r'\b(?:address|ave|avenue|blvd|boulevard|circle|cir|court|ct|drive|dr|highway|hwy|lane|ln|parkway|pkwy|place|pl|plaza|road|rd|route|rte|street|st|suite|ste|terrace|ter|way)\b',
  ).hasMatch(lower)) {
    return RegExp(r'\d').hasMatch(clean) ||
        clean.split(RegExp(r'\s+')).length > 2;
  }
  return false;
}

bool _looksLikeReceiptBarcodeOrIdLine(String line) {
  final clean = line.trim();
  if (clean.length < 6) return false;
  final letters = RegExp(r'[a-zA-Z]').allMatches(clean).length;
  final digits = RegExp(r'\d').allMatches(clean).length;
  if (letters > 2 || digits < 6) return false;
  return RegExp(r'^[\s#:\-*\d]+$').hasMatch(clean);
}
