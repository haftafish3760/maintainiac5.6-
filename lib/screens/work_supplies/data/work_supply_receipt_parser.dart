import 'work_supply_catalog.dart';
import 'work_supply_models.dart';
import 'work_supply_receipt_confidence.dart';

part 'work_supply_receipt_parser_terms.dart';
part 'work_supply_receipt_parser_trade_scores.dart';
part 'work_supply_receipt_parser_trade_scores_appliances.dart';
part 'work_supply_receipt_parser_trade_scores_core.dart';
part 'work_supply_receipt_parser_trade_scores_finishes.dart';
part 'work_supply_receipt_parser_trade_scores_exterior.dart';
part 'work_supply_receipt_parser_trade_scores_garage.dart';
part 'work_supply_receipt_parser_trade_scores_low_voltage_tools.dart';
part 'work_supply_receipt_parser_trade_scores_well_septic.dart';

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

typedef _ReceiptCatalogEntry = ({
  WorkSupplyItem item,
  String searchableText,
  String normalizedText,
  String variantText,
});

final List<_ReceiptCatalogEntry> _receiptCatalogIndex = [
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

final _receiptCatalogEntryById = {
  for (final entry in _receiptCatalogIndex) entry.item.id: entry,
};

final _receiptCatalogTokenIndex = _buildReceiptCatalogTokenIndex(
  _receiptCatalogIndex,
);

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

ReceiptLineMatch? matchReceiptLineToCatalog(
  String rawText, {
  ReceiptParserLearningMemory? memory,
  int maxCandidates = 80,
  String? tradeScope,
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
    tradeScope: tradeScope,
  );
  final searchLimit = maxCandidates < 16 ? maxCandidates : 16;
  final candidatePool = fallbackCandidates.isNotEmpty
      ? fallbackCandidates
      : searchWorkSupplies(_parserSearchText(expanded))
            .where((item) => _matchesTradeScope(item, tradeScope))
            .take(searchLimit)
            .toList();
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
  String? tradeScope,
}) {
  final tokens = _receiptCandidateTokens(text);
  if (tokens.isEmpty) return const [];
  final candidateScores = <String, int>{};
  for (final token in tokens) {
    for (final alternate in _receiptTokenAlternates(token)) {
      final entries = _receiptCatalogTokenIndex[alternate];
      if (entries == null) continue;
      for (final entry in entries) {
        candidateScores.update(
          entry.item.id,
          (score) => score + 1,
          ifAbsent: () => 1,
        );
      }
    }
  }
  if (candidateScores.isEmpty) return const [];
  final scored = <({WorkSupplyItem item, int score})>[];
  for (final id in candidateScores.keys) {
    final entry = _receiptCatalogEntryById[id];
    if (entry == null) continue;
    if (!_matchesTradeScope(entry.item, tradeScope)) continue;
    var score = candidateScores[id] ?? 0;
    final packCount = RegExp(r'\b(\d+)\s*pack\b').firstMatch(text);
    if (packCount != null &&
        entry.normalizedText.contains('${packCount.group(1)} pack')) {
      score += 80;
    }
    if (RegExp(r'\b(drywall|sheetrock|gypsum)\s+screws?\b').hasMatch(text) &&
        entry.item.trade == 'Drywall' &&
        entry.normalizedText.contains('screw')) {
      score += 120;
    }
    if (text.contains('condenser pad') && entry.item.trade == 'HVAC') {
      if (entry.normalizedText.contains('condenser pad')) {
        score += 140;
      } else if (entry.normalizedText.contains('equipment pad')) {
        score -= 40;
      }
    }
    if (entry.variantText.isNotEmpty && text.contains(entry.variantText)) {
      score += 20;
    }
    score += _receiptFallbackSpecificityScore(text, entry);
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

int _receiptFallbackSpecificityScore(String text, _ReceiptCatalogEntry entry) {
  final itemName = entry.item.name.toLowerCase();
  final normalizedText = entry.normalizedText;
  var score = 0;
  if (RegExp(r'\bwood\s+screws?\b').hasMatch(text)) {
    if (normalizedText.contains('wood screw')) {
      score += 1000;
    } else if (normalizedText.contains('screw')) {
      score -= 500;
    }
  }
  if (RegExp(r'\b(anode|anode rod)\b').hasMatch(text)) {
    if (itemName.contains('water heater repair part') ||
        normalizedText.contains('anode')) {
      score += 220;
    } else if (itemName.contains('water heater') ||
        normalizedText.contains('water heater')) {
      score -= 24;
    }
  }
  if (RegExp(
    r'\b(heating element|water heater element|element)\b',
  ).hasMatch(text)) {
    if (itemName.contains('water heater repair part') ||
        normalizedText.contains('element')) {
      score += 180;
    } else if (itemName.contains('water heater') ||
        normalizedText.contains('water heater')) {
      score -= 20;
    }
  }
  if (RegExp(r'\b(float switch|piggyback|pump float)\b').hasMatch(text)) {
    if (itemName.contains('pump control part') ||
        normalizedText.contains('float switch') ||
        normalizedText.contains('piggyback')) {
      score += 190;
    } else if (itemName.contains('sump pump')) {
      score -= 20;
    }
  }
  if (RegExp(r'\b(high water alarm|pump alarm)\b').hasMatch(text)) {
    if (itemName.contains('pump control part') ||
        normalizedText.contains('high water alarm') ||
        normalizedText.contains('pump alarm')) {
      score += 210;
    } else if (itemName.contains('sump pump')) {
      score -= 22;
    }
  }
  return score;
}

List<String> _receiptCandidateTokens(String text) {
  return text
      .split(RegExp(r'\s+'))
      .where(
        (token) =>
            token.isNotEmpty &&
            !_isParserNoiseToken(token) &&
            (token.length > 2 || token.contains('/') || token.contains('-')),
      )
      .toList();
}

Map<String, List<_ReceiptCatalogEntry>> _buildReceiptCatalogTokenIndex(
  List<_ReceiptCatalogEntry> entries,
) {
  final index = <String, List<_ReceiptCatalogEntry>>{};
  for (final entry in entries) {
    final tokens = _receiptCandidateTokens(entry.normalizedText).toSet();
    for (final token in tokens) {
      index.putIfAbsent(token, () => []).add(entry);
    }
  }
  return {
    for (final entry in index.entries)
      entry.key: List.unmodifiable(entry.value),
  };
}

bool _matchesTradeScope(WorkSupplyItem item, String? tradeScope) {
  if (tradeScope == null || tradeScope.trim().isEmpty) return true;
  return item.trade.toLowerCase() == tradeScope.trim().toLowerCase();
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
  final indexedText = _indexedReceiptTextFor(item);
  final screwLine = RegExp(
    r'\b(?:deck|drywall|machine|sheet\s*metal|wood)?\s*screws?\b',
  ).hasMatch(text);
  if (screwLine) {
    if (indexedText.contains('screw')) {
      score += 80;
    } else {
      score -= 40;
    }
    if (RegExp(r'\bwood\s+screws?\b').hasMatch(text)) {
      if (indexedText.contains('wood screw')) {
        score += 120;
      } else {
        score -= 100;
      }
    }
  }
  if (_containsExactPhrase(text, item.variant)) score += 20;
  if (_containsBareSingleInchSize(text, item.variant)) score += 18;
  if (_containsExactPhrase(text, item.name)) score += 8;
  if (_containsExactPhrase(text, item.itemType)) score += 4;
  if (_containsExactPhrase(text, item.system)) score += 4;
  score += _tradeContextScore(text, item);
  return score;
}

bool _containsBareSingleInchSize(String text, String variant) {
  if (text.contains(' x ')) return false;
  final normalizedVariant = _normalize(variant);
  final match = RegExp(
    r'^(\d+(?:-\d/\d|\.\d+)?) in$',
  ).firstMatch(normalizedVariant);
  if (match == null) return false;
  final size = match.group(1)!;
  return RegExp('(^| )${RegExp.escape(size)}( |\$)').hasMatch(text);
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
