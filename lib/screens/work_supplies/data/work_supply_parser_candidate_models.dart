enum WorkSupplyParserSuggestedAction {
  reviewOnly,
  addToInventory,
  addToActiveJob,
  addToEstimateDraft,
  routeToExpense,
  ignoreNoise,
}

class WorkSupplyParserPossibleMatch {
  const WorkSupplyParserPossibleMatch({
    required this.canonicalItemId,
    required this.canonicalItemName,
    required this.detectedTrade,
    required this.confidenceScore,
    this.confidenceReasons = const [],
    this.rejectedReasons = const [],
  });

  final String canonicalItemId;
  final String canonicalItemName;
  final String detectedTrade;
  final double confidenceScore;
  final List<String> confidenceReasons;
  final List<String> rejectedReasons;

  Map<String, Object?> toMap() {
    return {
      'canonicalItemId': canonicalItemId,
      'canonicalItemName': canonicalItemName,
      'detectedTrade': detectedTrade,
      'confidenceScore': confidenceScore,
      'confidenceReasons': confidenceReasons,
      'rejectedReasons': rejectedReasons,
    };
  }

  static WorkSupplyParserPossibleMatch fromMap(Map value) {
    return WorkSupplyParserPossibleMatch(
      canonicalItemId: _string(value['canonicalItemId']),
      canonicalItemName: _string(value['canonicalItemName']),
      detectedTrade: _string(value['detectedTrade']),
      confidenceScore: _double(value['confidenceScore']),
      confidenceReasons: _stringList(value['confidenceReasons']),
      rejectedReasons: _stringList(value['rejectedReasons']),
    );
  }
}

class WorkSupplyParserCandidate {
  const WorkSupplyParserCandidate({
    required this.rawLine,
    required this.cleanedLine,
    required this.reviewStatus,
    required this.suggestedInventoryAction,
    this.merchantGuess = '',
    this.detectedTrade = '',
    this.detectedCategory = '',
    this.detectedSubcategory = '',
    this.detectedSystem = '',
    this.detectedItemType = '',
    this.canonicalItemId = '',
    this.canonicalItemName = '',
    this.material = '',
    this.composition = '',
    this.size = '',
    this.dimensions = '',
    this.length = '',
    this.width = '',
    this.height = '',
    this.diameter = '',
    this.schedule = '',
    this.gauge = '',
    this.rating = '',
    this.color = '',
    this.finish = '',
    this.variant = '',
    this.quantityPurchased = 1,
    this.packageQuantity = 1,
    this.stockQuantityCandidate = 1,
    this.unit = 'each',
    this.unitPrice = 0,
    this.lineTotal = 0,
    this.matchedAliases = const [],
    this.matchedMerchantRules = const [],
    this.matchedParserPack = '',
    this.possibleMatches = const [],
    this.confidenceScore = 0,
    this.confidenceReasons = const [],
    this.warnings = const [],
    this.missingFields = const [],
  });

  final String rawLine;
  final String cleanedLine;
  final String merchantGuess;
  final String detectedTrade;
  final String detectedCategory;
  final String detectedSubcategory;
  final String detectedSystem;
  final String detectedItemType;
  final String canonicalItemId;
  final String canonicalItemName;
  final String material;
  final String composition;
  final String size;
  final String dimensions;
  final String length;
  final String width;
  final String height;
  final String diameter;
  final String schedule;
  final String gauge;
  final String rating;
  final String color;
  final String finish;
  final String variant;
  final double quantityPurchased;
  final double packageQuantity;
  final double stockQuantityCandidate;
  final String unit;
  final double unitPrice;
  final double lineTotal;
  final List<String> matchedAliases;
  final List<String> matchedMerchantRules;
  final String matchedParserPack;
  final List<WorkSupplyParserPossibleMatch> possibleMatches;
  final double confidenceScore;
  final List<String> confidenceReasons;
  final List<String> warnings;
  final List<String> missingFields;
  final String reviewStatus;
  final WorkSupplyParserSuggestedAction suggestedInventoryAction;

  bool get requiresReview {
    return reviewStatus != 'confirmed' ||
        warnings.isNotEmpty ||
        missingFields.isNotEmpty ||
        possibleMatches.length != 1;
  }

  double get calculatedStockQuantity => quantityPurchased * packageQuantity;

  double get calculatedUnitPrice {
    final stockQuantity = calculatedStockQuantity;
    return stockQuantity <= 0 ? 0 : lineTotal / stockQuantity;
  }

  bool get hasConsistentStockQuantity {
    return (stockQuantityCandidate - calculatedStockQuantity).abs() <= .001;
  }

  List<WorkSupplyParserPossibleMatch> rankedPossibleMatchesForEstimateSection(
    String estimateSectionTrade,
  ) {
    final sectionTrade = estimateSectionTrade.trim().toLowerCase();
    final ranked = [...possibleMatches];
    ranked.sort((left, right) {
      final rightScore = _estimateSectionScore(right, sectionTrade);
      final leftScore = _estimateSectionScore(left, sectionTrade);
      return rightScore.compareTo(leftScore);
    });
    return ranked;
  }

  Map<String, Object?> toMap() {
    return {
      'rawLine': rawLine,
      'cleanedLine': cleanedLine,
      'merchantGuess': merchantGuess,
      'detectedTrade': detectedTrade,
      'detectedCategory': detectedCategory,
      'detectedSubcategory': detectedSubcategory,
      'detectedSystem': detectedSystem,
      'detectedItemType': detectedItemType,
      'canonicalItemId': canonicalItemId,
      'canonicalItemName': canonicalItemName,
      'material': material,
      'composition': composition,
      'size': size,
      'dimensions': dimensions,
      'length': length,
      'width': width,
      'height': height,
      'diameter': diameter,
      'schedule': schedule,
      'gauge': gauge,
      'rating': rating,
      'color': color,
      'finish': finish,
      'variant': variant,
      'quantityPurchased': quantityPurchased,
      'packageQuantity': packageQuantity,
      'stockQuantityCandidate': stockQuantityCandidate,
      'unit': unit,
      'unitPrice': unitPrice,
      'lineTotal': lineTotal,
      'matchedAliases': matchedAliases,
      'matchedMerchantRules': matchedMerchantRules,
      'matchedParserPack': matchedParserPack,
      'possibleMatches': [for (final match in possibleMatches) match.toMap()],
      'confidenceScore': confidenceScore,
      'confidenceReasons': confidenceReasons,
      'warnings': warnings,
      'missingFields': missingFields,
      'reviewStatus': reviewStatus,
      'suggestedInventoryAction': suggestedInventoryAction.name,
    };
  }

  static WorkSupplyParserCandidate fromMap(Map value) {
    return WorkSupplyParserCandidate(
      rawLine: _string(value['rawLine']),
      cleanedLine: _string(value['cleanedLine']),
      merchantGuess: _string(value['merchantGuess']),
      detectedTrade: _string(value['detectedTrade']),
      detectedCategory: _string(value['detectedCategory']),
      detectedSubcategory: _string(value['detectedSubcategory']),
      detectedSystem: _string(value['detectedSystem']),
      detectedItemType: _string(value['detectedItemType']),
      canonicalItemId: _string(value['canonicalItemId']),
      canonicalItemName: _string(value['canonicalItemName']),
      material: _string(value['material']),
      composition: _string(value['composition']),
      size: _string(value['size']),
      dimensions: _string(value['dimensions']),
      length: _string(value['length']),
      width: _string(value['width']),
      height: _string(value['height']),
      diameter: _string(value['diameter']),
      schedule: _string(value['schedule']),
      gauge: _string(value['gauge']),
      rating: _string(value['rating']),
      color: _string(value['color']),
      finish: _string(value['finish']),
      variant: _string(value['variant']),
      quantityPurchased: _double(value['quantityPurchased'], fallback: 1),
      packageQuantity: _double(value['packageQuantity'], fallback: 1),
      stockQuantityCandidate: _double(
        value['stockQuantityCandidate'],
        fallback: 1,
      ),
      unit: _string(value['unit'], fallback: 'each'),
      unitPrice: _double(value['unitPrice']),
      lineTotal: _double(value['lineTotal']),
      matchedAliases: _stringList(value['matchedAliases']),
      matchedMerchantRules: _stringList(value['matchedMerchantRules']),
      matchedParserPack: _string(value['matchedParserPack']),
      possibleMatches: [
        if (value['possibleMatches'] is List)
          for (final match in value['possibleMatches'] as List)
            if (match is Map) WorkSupplyParserPossibleMatch.fromMap(match),
      ],
      confidenceScore: _double(value['confidenceScore']),
      confidenceReasons: _stringList(value['confidenceReasons']),
      warnings: _stringList(value['warnings']),
      missingFields: _stringList(value['missingFields']),
      reviewStatus: _string(value['reviewStatus'], fallback: 'needsReview'),
      suggestedInventoryAction: _suggestedAction(
        value['suggestedInventoryAction'],
      ),
    );
  }
}

double _estimateSectionScore(
  WorkSupplyParserPossibleMatch match,
  String estimateSectionTrade,
) {
  final tradeBoost =
      estimateSectionTrade.isNotEmpty &&
          match.detectedTrade.toLowerCase() == estimateSectionTrade
      ? .08
      : 0;
  return match.confidenceScore + tradeBoost;
}

WorkSupplyParserSuggestedAction _suggestedAction(Object? value) {
  final name = _string(value);
  for (final action in WorkSupplyParserSuggestedAction.values) {
    if (action.name == name) return action;
  }
  return WorkSupplyParserSuggestedAction.reviewOnly;
}

String _string(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

double _double(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

List<String> _stringList(Object? value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  return const [];
}
