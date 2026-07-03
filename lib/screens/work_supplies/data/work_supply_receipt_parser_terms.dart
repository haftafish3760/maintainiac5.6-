part of 'work_supply_receipt_parser.dart';

const receiptMerchantAliases = {
  'lowes': ['lowe s', 'lowe\'s', 'lowes', 'lowe'],
  'home depot': ['home depot', 'the home depot', 'homedepot', 'h depot'],
  'harbor freight': ['harbor freight', 'h freight', 'hft'],
  'ferguson': ['ferguson', 'ferguson plumbing', 'ferguson supply'],
  'ace hardware': ['ace', 'ace hardware'],
  'menards': ['menards'],
  'grainger': ['grainger'],
  'amazon': ['amazon', 'amzn'],
};

const receiptTermAliases = {
  ..._receiptTermAliasesPart1,
  ..._receiptTermAliasesPart2,
  ..._receiptTermAliasesPart3,
  ..._receiptTermAliasesPart4,
  ..._receiptTermAliasesPart5,
};

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'(?<=[a-z])0(?=[a-z])'), 'o')
      .replaceAll(RegExp(r'(?<=\d)"'), ' in')
      .replaceAll(RegExp(r'(?<=\d)x(?=\d)'), ' x ')
      .replaceAll(RegExp(r'(?<=\d)\s*/\s*(?=\d)'), '/')
      .replaceAll(RegExp(r'(?<=\d)(ft|feet)\b'), ' ft')
      .replaceAll(RegExp(r'(?<=\d)(in|inch)\b'), ' in')
      .replaceAll(RegExp(r'(?<=\d)(lb|lbs|pound|pounds)\b'), ' lb')
      .replaceAll(RegExp(r'(?<=\d)(oz|ounce|ounces)\b'), ' oz')
      .replaceAll(RegExp(r'\bqt\b'), 'quart')
      .replaceAll(RegExp(r'\bpt\b'), 'pint')
      .replaceAll(RegExp(r'(?<=\d)(gal|gallon|gallons)\b'), ' gal')
      .replaceAll(RegExp(r'(?<=\d)(pk|pack|ct|count)\b'), ' pack')
      .replaceAllMapped(
        RegExp(r'\br\s*-?\s*(\d{2})\b'),
        (match) => 'r-${match.group(1)}',
      )
      .replaceAllMapped(
        RegExp(r'\b(10|12|14|18)\s*-\s*([23578])\b'),
        (match) => '${match.group(1)}/${match.group(2)}',
      )
      .replaceAll(RegExp(r'\bnm\s*-?\s*b\b'), 'nm-b')
      .replaceAll(RegExp(r'\bsch\s*40\b'), 'schedule 40')
      .replaceAll(RegExp(r'\bsched\s*40\b'), 'schedule 40')
      .replaceAll(RegExp(r'\bs\s*40\b'), 'schedule 40')
      .replaceAllMapped(
        RegExp(r'\b(\d{1,3})\s*a\b'),
        (match) => '${match.group(1)} amp',
      )
      .replaceAll(RegExp(r'\bw\s*/\s*g\b'), 'with ground')
      .replaceAll(RegExp(r'\bw\s+g\b'), 'with ground')
      .replaceAll(RegExp(r'\b1\s*p\b'), '1p')
      .replaceAll(RegExp(r'\b2\s*p\b'), '2p')
      .replaceAll(RegExp(r'\bc\s*x\s*c\b'), 'copper copper')
      .replaceAll(RegExp(r'\bs\s*x\s*s\b'), 'slip slip')
      .replaceAll(RegExp(r'\bsx\s*m\b'), 'slip male')
      .replaceAll(RegExp(r'\bsx\s*f\b'), 'slip female')
      .replaceAll(RegExp(r'\bsxm\b'), 'slip male')
      .replaceAll(RegExp(r'\bsxf\b'), 'slip female')
      .replaceAll(RegExp(r'\bslip\s*x\s*mip\b'), 'male adapter')
      .replaceAll(RegExp(r'\bslip\s*x\s*fip\b'), 'female adapter')
      .replaceAll(RegExp(r'\bm\.?i\.?p\.?\b'), 'mip')
      .replaceAll(RegExp(r'\bf\.?i\.?p\.?\b'), 'fip')
      .replaceAll(RegExp(r'\bm\.?p\.?t\.?\b'), 'mpt')
      .replaceAll(RegExp(r'\bf\.?p\.?t\.?\b'), 'fpt')
      .replaceAll(RegExp(r'\bs\s*/\s*j\b'), 'slip joint')
      .replaceAll(RegExp(r'[^a-z0-9/.-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _expandAliases(String value) {
  var expanded = value;
  for (final entry in receiptTermAliases.entries) {
    if (entry.value.any((alias) => _containsAlias(value, alias))) {
      expanded = '$expanded ${entry.key}';
    }
  }
  return expanded;
}

bool _containsAlias(String text, String alias) {
  final normalizedAlias = _normalize(alias);
  if (normalizedAlias.isEmpty) return false;
  return RegExp('(^| )${RegExp.escape(normalizedAlias)}( |\$)').hasMatch(text);
}
