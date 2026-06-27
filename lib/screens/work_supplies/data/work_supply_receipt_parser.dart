import 'work_supply_catalog.dart';
import 'work_supply_models.dart';
import 'work_supply_receipt_confidence.dart';

class ReceiptLineMatch {
  const ReceiptLineMatch({
    required this.rawText,
    required this.item,
    required this.confidence,
    required this.matchedTerms,
    this.source = ReceiptMatchSource.catalog,
  });

  final String rawText;
  final WorkSupplyItem item;
  final double confidence;
  final List<String> matchedTerms;
  final ReceiptMatchSource source;

  ReceiptConfidenceLevel get confidenceLevel =>
      receiptConfidenceLevelFor(confidence);

  bool get needsReview => confidenceLevel != ReceiptConfidenceLevel.good;

  String get confidenceLabel => receiptConfidenceLabel(confidenceLevel);

  String get confidenceGuidance => receiptConfidenceGuidance(confidenceLevel);
}

enum ReceiptMatchSource { catalog, learnedCorrection }

final _receiptCatalogIndex = [
  for (final item in workSupplyCatalogItems)
    (
      item: item,
      searchableText: item.searchableText.toLowerCase(),
      normalizedText: _normalize(
        '${item.searchableText} ${item.aliases.join(' ')}',
      ),
      variantText: _normalize(item.variant),
    ),
];

final _receiptCatalogTextById = {
  for (final entry in _receiptCatalogIndex) entry.item.id: entry.normalizedText,
};

class ReceiptParserLearningMemory {
  ReceiptParserLearningMemory([Map<String, String>? learnedItemIds])
    : _learnedItemIds = {...?learnedItemIds};

  final Map<String, String> _learnedItemIds;

  void confirmCorrection({
    required String receiptLine,
    required WorkSupplyItem item,
  }) {
    _learnedItemIds[_normalize(receiptLine)] = item.id;
  }

  WorkSupplyItem? learnedMatchFor(String receiptLine) {
    final normalized = _normalize(receiptLine);
    final learnedId =
        _learnedItemIds[normalized] ??
        _learnedItemIds[_withoutTrailingReceiptPrice(normalized)] ??
        _learnedPrefixMatchId(normalized, _learnedItemIds);
    if (learnedId == null) return null;
    for (final item in workSupplyCatalogItems) {
      if (item.id == learnedId) return item;
    }
    return null;
  }
}

String? _learnedPrefixMatchId(
  String normalized,
  Map<String, String> learnedItemIds,
) {
  final clean = _withoutTrailingReceiptPrice(normalized);
  for (final entry in learnedItemIds.entries) {
    final key = entry.key.trim();
    if (key.length < 5) continue;
    if (clean == key ||
        clean.startsWith('$key ') ||
        key.startsWith('$clean ')) {
      return entry.value;
    }
  }
  return null;
}

String _withoutTrailingReceiptPrice(String normalized) {
  return normalized.replaceFirst(RegExp(r'\s+\d+\s+\d{2}$'), '').trim();
}

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
  '1/2 in': ['1/2', 'half inch', 'half in', '.5 in'],
  '3/4 in': ['3/4', 'three quarter', 'three-quarter', '.75 in'],
  '1/4 in': ['1/4', 'quarter inch', 'quarter in'],
  '1 in': ['1 inch', 'one inch'],
  '1-1/4 in': ['1 1/4', '1-1/4', 'inch and a quarter'],
  '1-1/2 in': ['1 1/2', '1-1/2', 'inch and a half'],
  '90 elbow': ['90', '90d', 'el', 'ell', 'elbow'],
  '45 elbow': ['45', '45d', 'forty five', 'forty-five'],
  'tee': ['tee', 't fitting', 't'],
  'coupling': ['cplg', 'coup', 'coupler', 'coupling'],
  'reducing coupling': ['red coup', 'red cplg', 'reducer coupling'],
  'reducer': ['red', 'reducer'],
  'bushing': ['bush', 'bushing'],
  'street': ['street', 'st 90', 'st ell'],
  'wye': ['wye', 'y fitting', 'why fitting'],
  'copper': ['cop', 'cpr', 'cu', 'sweat', 'copper'],
  'pvc schedule 40': ['sch40', 'sch 40', 's40', 'sched 40', 'schedule 40'],
  'pvc dwv': ['dwv', 'drain waste vent'],
  'cpvc': ['cpvc', 'cpv'],
  'pex': ['pex', 'crimp'],
  'black iron': ['black iron', 'blk iron', 'black pipe'],
  'galvanized': ['galv', 'galvanized'],
  'cast iron': ['cast iron', 'ci'],
  'no-hub': ['no hub', 'no-hub', 'nh'],
  'compression gasket': ['compression gasket', 'service weight gasket'],
  'push-fit': ['push fit', 'push-to-connect', 'push connect'],
  'male adapter': ['male adapter', 'mip adapter', 'mpt adapter', 'male adapt'],
  'female adapter': [
    'female adapter',
    'fip adapter',
    'fpt adapter',
    'female adapt',
  ],
  'slip joint': ['slip joint', 's/j', 'sj'],
  'union': ['union'],
  'ball valve': ['ball valve'],
  'angle stop': ['angle stop', 'angle valve', 'shutoff'],
  'sillcock': ['sillcock', 'hose bibb', 'hose bib', 'frost free'],
  'primer': ['primer', 'purple primer'],
  'cement': ['cement', 'glue'],
  'crimp ring': ['crimp ring', 'pex ring'],
  'clamp ring': ['clamp ring', 'cinch ring'],
  'gfci': ['gfci', 'gfi', 'ground fault'],
  'afci': ['afci', 'arc fault'],
  'breaker': ['brkr', 'breaker'],
  'receptacle': ['recept', 'receptacle', 'outlet', 'wall socket'],
  'capacitor': ['cap', 'capacitor', 'run cap'],
  'pleated filter': ['pleated filter', 'furnace filter', 'ac filter'],
  'foil tape': ['foil tape', 'hvac tape', 'metal tape'],
  'adapter': ['adapt', 'adptr', 'adapter'],
  'tile': ['tile', 'ceramic', 'porcelain'],
  'thinset': ['thinset', 'thin set', 'tile mortar'],
  'grout': ['grout'],
};

ReceiptLineMatch? matchReceiptLineToCatalog(
  String rawText, {
  ReceiptParserLearningMemory? memory,
  int maxCandidates = 80,
}) {
  final learned = memory?.learnedMatchFor(rawText);
  if (learned != null) {
    return ReceiptLineMatch(
      rawText: rawText,
      item: learned,
      confidence: 0.98,
      matchedTerms: const ['learned'],
      source: ReceiptMatchSource.learnedCorrection,
    );
  }
  if (maxCandidates <= 0) return null;
  final normalized = _normalize(rawText);
  final expanded = _expandAliases(normalized);
  final fallbackCandidates = _fallbackReceiptCandidates(
    expanded,
    maxCandidates: maxCandidates,
  );
  final searchLimit = maxCandidates < 16 ? maxCandidates : 16;
  final candidatePool = fallbackCandidates.isNotEmpty
      ? fallbackCandidates
      : searchWorkSupplies(
          _parserSearchText(expanded),
        ).take(searchLimit).toList();
  if (candidatePool.isEmpty) return null;
  final scored =
      [
        for (final item in candidatePool)
          _scoredReceiptCandidate(expanded, item),
      ]..sort((a, b) {
        final score = b.score.compareTo(a.score);
        if (score != 0) return score;
        return a.item.name.compareTo(b.item.name);
      });
  final best = scored.first;
  if (best.terms.length < 3 && !_isStrongShortCatalogMatch(best.score)) {
    return null;
  }
  final confidence = _confidence(
    best.terms.length,
    expanded,
    best.item,
    score: best.score,
  );
  return ReceiptLineMatch(
    rawText: rawText,
    item: best.item,
    confidence: confidence,
    matchedTerms: best.terms,
  );
}

bool _isStrongShortCatalogMatch(int score) {
  return score >= 28;
}

String normalizeMerchantName(String rawText) {
  final normalized = _normalize(rawText);
  for (final entry in receiptMerchantAliases.entries) {
    if (entry.value.any(normalized.contains)) return entry.key;
  }
  return normalized;
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'(?<=\d)"'), ' in')
      .replaceAll(RegExp(r'(?<=\d)x(?=\d)'), ' x ')
      .replaceAll(RegExp(r'(?<=\d)\s*/\s*(?=\d)'), '/')
      .replaceAll(RegExp(r'(?<=\d)(in|inch)\b'), ' in')
      .replaceAll(RegExp(r'\bsch\s*40\b'), 'schedule 40')
      .replaceAll(RegExp(r'\bsched\s*40\b'), 'schedule 40')
      .replaceAll(RegExp(r'\bs\s*40\b'), 'schedule 40')
      .replaceAllMapped(
        RegExp(r'\b(\d{1,3})\s*a\b'),
        (match) => '${match.group(1)} amp',
      )
      .replaceAll(RegExp(r'\bw\s*/\s*g\b'), 'with ground')
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

String _parserSearchText(String value) {
  final tokens = value
      .split(RegExp(r'\s+'))
      .where((token) => !_isParserNoiseToken(token))
      .toList();
  return tokens.join(' ');
}

bool _isParserNoiseToken(String token) {
  return switch (token) {
    'lowes' ||
    'lowe' ||
    'home' ||
    'depot' ||
    'hd' ||
    'the' ||
    'sku' ||
    'item' ||
    'qty' ||
    'ea' ||
    'ft' => true,
    _ => false,
  };
}

List<WorkSupplyItem> _fallbackReceiptCandidates(
  String text, {
  required int maxCandidates,
}) {
  final tokens = text
      .split(RegExp(r'\s+'))
      .where(
        (token) =>
            token.isNotEmpty &&
            !_isParserNoiseToken(token) &&
            (token.length > 2 || token.contains('/') || token.contains('-')),
      )
      .toList();
  if (tokens.isEmpty) return const [];
  final scored = <({WorkSupplyItem item, int score})>[];
  for (final entry in _receiptCatalogIndex) {
    var score = 0;
    for (final token in tokens) {
      if (_receiptTokenAlternates(token).any(entry.searchableText.contains)) {
        score++;
      }
    }
    if (entry.variantText.isNotEmpty && text.contains(entry.variantText)) {
      score += 20;
    }
    score += _tradeContextScore(text, entry.item);
    if (score > 0) scored.add((item: entry.item, score: score));
  }
  scored.sort((a, b) {
    final score = b.score.compareTo(a.score);
    if (score != 0) return score;
    return a.item.name.compareTo(b.item.name);
  });
  return scored.map((entry) => entry.item).take(maxCandidates).toList();
}

List<String> _receiptTokenAlternates(String token) {
  return switch (token) {
    'half' => const ['half', '1/2'],
    'quarter' => const ['quarter', '1/4'],
    'three-quarter' => const ['three-quarter', '3/4'],
    'inch' => const ['inch', 'in'],
    'in' => const ['inch', 'in'],
    'ninety' => const ['ninety', '90'],
    'forty-five' => const ['forty-five', '45'],
    _ => [token],
  };
}

List<String> _matchedTerms(String text, WorkSupplyItem item) {
  final haystack = _indexedReceiptTextFor(item);
  final terms = <String>{};
  for (final token in text.split(RegExp(r'\s+'))) {
    if (token.isNotEmpty &&
        !_isParserNoiseToken(token) &&
        token != 'x' &&
        _containsTerm(haystack, token)) {
      terms.add(token);
    }
  }
  return terms.toList();
}

String _indexedReceiptTextFor(WorkSupplyItem item) {
  return _receiptCatalogTextById[item.id] ??
      _normalize('${item.searchableText} ${item.aliases.join(' ')}');
}

({WorkSupplyItem item, List<String> terms, int score}) _scoredReceiptCandidate(
  String text,
  WorkSupplyItem item,
) {
  final terms = _matchedTerms(text, item);
  return (
    item: item,
    terms: terms,
    score: _receiptItemScore(text, item, terms),
  );
}

int _receiptItemScore(String text, WorkSupplyItem item, List<String> terms) {
  var score = terms.length;
  if (_containsExactPhrase(text, item.variant)) score += 20;
  if (_containsExactPhrase(text, item.name)) score += 8;
  if (_containsExactPhrase(text, item.itemType)) score += 4;
  if (_containsExactPhrase(text, item.system)) score += 4;
  score += _tradeContextScore(text, item);
  return score;
}

int _tradeContextScore(String text, WorkSupplyItem item) {
  final trade = item.trade.toLowerCase();
  final category = item.category.toLowerCase();
  final system = item.system.toLowerCase();
  var score = 0;
  if (trade == 'carpentry' &&
      RegExp(
        r'\b(stud|lumber|kd|kiln|wood|board|treated|pt)\b',
      ).hasMatch(text)) {
    score += 16;
  }
  if (category == 'fasteners' &&
      RegExp(
        r'\b(screw|screws|nail|nails|fastener|fasteners)\b',
      ).hasMatch(text)) {
    score += 12;
  }
  if (category == 'fasteners') {
    final itemType = item.itemType.toLowerCase();
    final systemText = system.toLowerCase();
    final isScrewItem =
        itemType.contains('screw') || systemText.contains('screw');
    final isNailItem = itemType.contains('nail') || systemText.contains('nail');
    final receiptSaysScrew = RegExp(r'\b(screw|screws)\b').hasMatch(text);
    final receiptSaysNail = RegExp(r'\b(nail|nails)\b').hasMatch(text);
    if (receiptSaysScrew && isScrewItem) score += 18;
    if (receiptSaysNail && isNailItem) score += 18;
    if (receiptSaysScrew && isNailItem) score -= 24;
    if (receiptSaysNail && isScrewItem) score -= 24;
    if (text.contains('wood') && itemType.contains('wood screw')) score += 10;
    if (text.contains('drywall') && itemType.contains('drywall')) score += 10;
    if (text.contains('deck') && itemType.contains('deck')) score += 10;
    if (text.contains('framing') && itemType.contains('framing')) score += 10;
  }
  if (trade == 'electrical' &&
      RegExp(
        r'\b(gfci|gfi|receptacle|outlet|romex|nm-b|nmb|emt|conduit|awg|wire|breaker)\b',
      ).hasMatch(text)) {
    score += 16;
  }
  if (trade == 'electrical') {
    final variant = _normalize(item.variant);
    final ampRating = RegExp(r'\b(\d{1,3})\s*amp\b').firstMatch(text);
    if (ampRating != null) {
      final rating = '${ampRating.group(1)} amp';
      if (variant == rating) {
        score += 24;
      } else if (variant.endsWith('amp')) {
        score -= 18;
      }
    }
  }
  if (trade == 'plumbing' &&
      RegExp(
        r'\b(copper|pvc|cpvc|pex|dwv|pipe|fitting|coupling|elbow|tee|valve|brass)\b',
      ).hasMatch(text)) {
    score += 12;
  }
  if (trade == 'plumbing') {
    final itemType = item.itemType.toLowerCase();
    final receiptSaysTee = RegExp(r'\b(tee|t)\b').hasMatch(text);
    final receiptSaysCoupling = RegExp(
      r'\b(coupling|coup|cplg|coupler)\b',
    ).hasMatch(text);
    final receiptSaysPipe = RegExp(r'\b(pipe|stick)\b').hasMatch(text);
    if (receiptSaysTee && itemType.contains('tee')) score += 18;
    if (receiptSaysCoupling && itemType.contains('coupling')) score += 18;
    if (receiptSaysPipe && category == 'pipe and tubing') score += 24;
    if (receiptSaysPipe && category == 'fittings') score -= 24;
    if (receiptSaysTee && itemType.contains('coupling')) score -= 22;
    if (receiptSaysCoupling && itemType.contains('tee')) score -= 22;
  }
  if (trade == 'plumbing' &&
      RegExp(
        r'\b(stud|lumber|kd|wood|romex|gfci|emt|conduit)\b',
      ).hasMatch(text)) {
    score -= 18;
  }
  if (system == 'nm-b cable' && text.contains('with ground')) score += 8;
  if (trade == 'hvac' &&
      RegExp(
        r'\b(capacitor|mfd|run cap|pleated|filter|furnace filter|ac filter|foil tape|hvac tape|mastic|duct|condensate|thermostat|contactor)\b',
      ).hasMatch(text)) {
    score += 16;
  }
  if (trade == 'hvac') {
    final itemType = item.itemType.toLowerCase();
    if (RegExp(r'\b(capacitor|mfd|run cap)\b').hasMatch(text) &&
        itemType.contains('capacitor')) {
      score += 18;
    }
    if (RegExp(r'\b(pleated|filter)\b').hasMatch(text) &&
        itemType.contains('filter')) {
      score += 18;
    }
    if (RegExp(r'\b(foil tape|hvac tape|metal tape)\b').hasMatch(text) &&
        itemType.contains('tape')) {
      score += 18;
    }
  }
  return score;
}

bool _containsExactPhrase(String text, String phrase) {
  final normalizedPhrase = _normalize(phrase);
  if (normalizedPhrase.isEmpty) return false;
  return RegExp('(^| )${RegExp.escape(normalizedPhrase)}( |\$)').hasMatch(text);
}

bool _containsTerm(String haystack, String token) {
  if (token.contains('/') || token.contains('-')) {
    return RegExp('(^| )${RegExp.escape(token)}( |\$)').hasMatch(haystack);
  }
  if (token.length <= 2) {
    return RegExp('(^| )${RegExp.escape(token)}( |\$)').hasMatch(haystack);
  }
  return RegExp('(^| )${RegExp.escape(token)}( |\$)').hasMatch(haystack);
}

double _confidence(
  int matchedTermCount,
  String text,
  WorkSupplyItem item, {
  int score = 0,
}) {
  var confidence = (matchedTermCount / 8).clamp(0.15, 0.86);
  if (_isStrongShortCatalogMatch(score)) confidence = confidence.clamp(.86, 1);
  final normalizedName = _normalize(item.name);
  if (text.contains(normalizedName)) confidence += 0.08;
  if (item.aliases.any((alias) => text.contains(_normalize(alias)))) {
    confidence += 0.05;
  }
  if (text.contains(item.variant.toLowerCase())) confidence += 0.04;
  return confidence.clamp(0.15, 0.95);
}
