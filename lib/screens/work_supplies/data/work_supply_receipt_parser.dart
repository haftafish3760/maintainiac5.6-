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
    final learnedId = _learnedItemIds[_normalize(receiptLine)];
    if (learnedId == null) return null;
    for (final item in workSupplyCatalogItems) {
      if (item.id == learnedId) return item;
    }
    return null;
  }
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
  'adapter': ['adapt', 'adptr', 'adapter'],
  'tile': ['tile', 'ceramic', 'porcelain'],
  'thinset': ['thinset', 'thin set', 'tile mortar'],
  'grout': ['grout'],
};

ReceiptLineMatch? matchReceiptLineToCatalog(
  String rawText, {
  ReceiptParserLearningMemory? memory,
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
  final normalized = _normalize(rawText);
  final expanded = _expandAliases(normalized);
  final fallbackCandidates = _fallbackReceiptCandidates(expanded);
  final candidatePool = fallbackCandidates.isNotEmpty
      ? fallbackCandidates
      : searchWorkSupplies(_parserSearchText(expanded)).take(16).toList();
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
  if (best.terms.length < 3) return null;
  final confidence = _confidence(best.terms.length, expanded, best.item);
  return ReceiptLineMatch(
    rawText: rawText,
    item: best.item,
    confidence: confidence,
    matchedTerms: best.terms,
  );
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
    if (entry.value.any(value.contains)) expanded = '$expanded ${entry.key}';
  }
  return expanded;
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
    'ea' => true,
    _ => false,
  };
}

List<WorkSupplyItem> _fallbackReceiptCandidates(String text) {
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
    if (score > 0) scored.add((item: entry.item, score: score));
  }
  scored.sort((a, b) {
    final score = b.score.compareTo(a.score);
    if (score != 0) return score;
    return a.item.name.compareTo(b.item.name);
  });
  return scored.map((entry) => entry.item).take(80).toList();
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
  return [
    for (final token in text.split(RegExp(r'\s+')))
      if (token.isNotEmpty && _containsTerm(haystack, token)) token,
  ];
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
    return haystack.contains(token);
  }
  return RegExp('(^| )${RegExp.escape(token)}( |\$)').hasMatch(haystack);
}

double _confidence(int matchedTermCount, String text, WorkSupplyItem item) {
  var confidence = (matchedTermCount / 8).clamp(0.15, 0.86);
  final normalizedName = _normalize(item.name);
  if (text.contains(normalizedName)) confidence += 0.08;
  if (item.aliases.any((alias) => text.contains(_normalize(alias)))) {
    confidence += 0.05;
  }
  if (text.contains(item.variant.toLowerCase())) confidence += 0.04;
  return confidence.clamp(0.15, 0.95);
}
