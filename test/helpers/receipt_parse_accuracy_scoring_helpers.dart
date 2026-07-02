part of 'receipt_parse_accuracy_harness.dart';

_FixtureScore _scoreFixture(
  ReceiptParseFixture fixture,
  ExpenseReceiptParseResult parsed,
) {
  final checks = <bool>[
    _equalsText(parsed.merchantName, fixture.expectedMerchant),
    if (fixture.expectedDate != null)
      parsed.receiptDate == fixture.expectedDate,
    if (fixture.expectedTimeMinutes != null)
      parsed.receiptTimeMinutes == fixture.expectedTimeMinutes,
    if (fixture.expectedSubtotal != null)
      _nearMoney(parsed.enteredSubtotal, fixture.expectedSubtotal),
    if (fixture.expectedTax != null)
      _nearMoney(parsed.enteredTax, fixture.expectedTax),
    if (fixture.expectedTotal != null)
      _nearMoney(parsed.enteredTotal, fixture.expectedTotal),
    parsed.quality.confidence >= fixture.minimumQuality,
    parsed.lines.length == fixture.lineExpectations.length,
  ];

  final lineCount = parsed.lines.length < fixture.lineExpectations.length
      ? parsed.lines.length
      : fixture.lineExpectations.length;
  for (var index = 0; index < lineCount; index++) {
    final expected = fixture.lineExpectations[index];
    final line = parsed.lines[index];
    final review = index < parsed.lineReviews.length
        ? parsed.lineReviews[index]
        : null;
    checks.add(line.category == expected.category);
    if (expected.descriptionContains != null) {
      checks.add(
        line.description.toLowerCase().contains(
          expected.descriptionContains!.toLowerCase(),
        ),
      );
    }
    if (expected.catalogItemName != null) {
      checks.add(
        line.catalogItemName == expected.catalogItemName ||
            review?.catalogItemName == expected.catalogItemName,
      );
    }
    if (expected.quantity != null) {
      checks.add(_nearNumber(line.quantity, expected.quantity));
    }
    if (expected.unitsPerPackage != null) {
      checks.add(_nearNumber(line.unitsPerPackage, expected.unitsPerPackage));
    }
    if (expected.unit != null) {
      checks.add(line.unit == expected.unit);
    }
    if (expected.subtotal != null) {
      checks.add(_nearMoney(line.subtotal, expected.subtotal));
    }
    if (expected.needsReview != null) {
      checks.add(line.parserNeedsReview == expected.needsReview);
    }
  }

  for (final expectedItem in fixture.expectedCatalogItems) {
    checks.add(
      parsed.lineReviews.any(
            (review) => review.catalogItemName == expectedItem,
          ) ||
          parsed.lines.any((line) => line.catalogItemName == expectedItem),
    );
  }

  final passed = checks.where((passed) => passed).length;
  return _FixtureScore(assertionCount: checks.length, passedCount: passed);
}

ReceiptFixtureReadiness _readinessForFixture(
  ReceiptParseFixture fixture,
  ExpenseReceiptParseResult parsed,
) {
  final issues = <String>[];
  final merchantScore =
      _equalsText(parsed.merchantName, fixture.expectedMerchant) ? 1.0 : 0.0;
  if (merchantScore < 1) issues.add('merchant');

  final totalsScore = _totalsReadinessScore(fixture, parsed, issues);
  final lineScore = _lineReadinessScore(fixture, parsed, issues);
  final catalogScore = _catalogReadinessScore(fixture, parsed, issues);
  final reviewScore = _reviewReadinessScore(parsed, issues);
  final overall = _weightedAverage(
    const [
      _WeightedScore(index: 0, weight: 1.2),
      _WeightedScore(index: 1, weight: 1.4),
      _WeightedScore(index: 2, weight: 2.2),
      _WeightedScore(index: 3, weight: 1.4),
      _WeightedScore(index: 4, weight: 1.0),
    ],
    [merchantScore, totalsScore, lineScore, catalogScore, reviewScore],
  );

  return ReceiptFixtureReadiness(
    name: fixture.name,
    overallScore: overall,
    merchantScore: merchantScore,
    totalsScore: totalsScore,
    lineScore: lineScore,
    catalogScore: catalogScore,
    reviewScore: reviewScore,
    trustLabel: parsed.diagnostics.trustLabel,
    issues: List.unmodifiable(issues),
  );
}

double _totalsReadinessScore(
  ReceiptParseFixture fixture,
  ExpenseReceiptParseResult parsed,
  List<String> issues,
) {
  final checks = <bool>[
    if (fixture.expectedDate != null)
      parsed.receiptDate == fixture.expectedDate,
    if (fixture.expectedTimeMinutes != null)
      parsed.receiptTimeMinutes == fixture.expectedTimeMinutes,
    if (fixture.expectedSubtotal != null)
      _nearMoney(parsed.enteredSubtotal, fixture.expectedSubtotal),
    if (fixture.expectedTax != null)
      _nearMoney(parsed.enteredTax, fixture.expectedTax),
    if (fixture.expectedTotal != null)
      _nearMoney(parsed.enteredTotal, fixture.expectedTotal),
  ];
  if (checks.isEmpty) return parsed.diagnostics.reconciled ? 1 : .86;
  final score = checks.where((passed) => passed).length / checks.length;
  if (score < 1) issues.add('totals');
  if (parsed.diagnostics.expectedSubtotalOrTotal != null &&
      parsed.lines.isNotEmpty &&
      !parsed.diagnostics.reconciled) {
    issues.add('line_total_mismatch');
    return score * .65;
  }
  if (parsed.diagnostics.hasCompleteExplicitTotals &&
      !parsed.diagnostics.taxMathReconciled) {
    issues.add('tax_math_mismatch');
    return score * .65;
  }
  return score;
}

double _lineReadinessScore(
  ReceiptParseFixture fixture,
  ExpenseReceiptParseResult parsed,
  List<String> issues,
) {
  final expectedLines = fixture.lineExpectations;
  if (expectedLines.isEmpty) return parsed.lines.isEmpty ? 1 : .92;
  final checks = <bool>[parsed.lines.length == expectedLines.length];
  final lineCount = parsed.lines.length < expectedLines.length
      ? parsed.lines.length
      : expectedLines.length;
  for (var index = 0; index < lineCount; index++) {
    final expected = expectedLines[index];
    final line = parsed.lines[index];
    checks.add(line.category == expected.category);
    if (expected.descriptionContains != null) {
      checks.add(
        line.description.toLowerCase().contains(
          expected.descriptionContains!.toLowerCase(),
        ),
      );
    }
    if (expected.quantity != null) {
      checks.add(_nearNumber(line.quantity, expected.quantity));
    }
    if (expected.unitsPerPackage != null) {
      checks.add(_nearNumber(line.unitsPerPackage, expected.unitsPerPackage));
    }
    if (expected.unit != null) checks.add(line.unit == expected.unit);
    if (expected.subtotal != null) {
      checks.add(_nearMoney(line.subtotal, expected.subtotal));
    }
    if (expected.needsReview != null) {
      checks.add(line.parserNeedsReview == expected.needsReview);
    }
  }
  final score = checks.where((passed) => passed).length / checks.length;
  if (score < 1) issues.add('lines');
  return score;
}

double _catalogReadinessScore(
  ReceiptParseFixture fixture,
  ExpenseReceiptParseResult parsed,
  List<String> issues,
) {
  final expectedCatalogItems = <String>{
    ...fixture.expectedCatalogItems,
    for (final line in fixture.lineExpectations)
      if (line.catalogItemName != null) line.catalogItemName!,
  };
  if (expectedCatalogItems.isEmpty) {
    if (parsed.diagnostics.materialLineCount == 0) return 1;
    final matched = parsed.diagnostics.catalogMatchedLineCount;
    final score = matched / parsed.diagnostics.materialLineCount;
    if (score < 1) issues.add('catalog');
    return score;
  }
  final matchedCount = expectedCatalogItems.where((expectedItem) {
    return parsed.lineReviews.any(
          (review) => review.catalogItemName == expectedItem,
        ) ||
        parsed.lines.any((line) => line.catalogItemName == expectedItem);
  }).length;
  final score = matchedCount / expectedCatalogItems.length;
  if (score < 1) issues.add('catalog');
  return score;
}

double _reviewReadinessScore(
  ExpenseReceiptParseResult parsed,
  List<String> issues,
) {
  if (parsed.diagnostics.detectedLineCount == 0) return .75;
  var score = 1 - parsed.diagnostics.reviewRatio;
  if (parsed.diagnostics.needsHeavyReview) {
    score = score.clamp(0, .72).toDouble();
    issues.add('heavy_review');
  }
  return score.clamp(0, 1).toDouble();
}

double _weightedAverage(List<_WeightedScore> weights, List<double> values) {
  var valueTotal = 0.0;
  var weightTotal = 0.0;
  for (final entry in weights) {
    final value = entry.index < values.length ? values[entry.index] : 0.0;
    valueTotal += value * entry.weight;
    weightTotal += entry.weight;
  }
  if (weightTotal == 0) return 1;
  return valueTotal / weightTotal;
}

class _WeightedScore {
  const _WeightedScore({required this.index, required this.weight});

  final int index;
  final double weight;
}

void _expectLines(
  ReceiptParseFixture fixture,
  ExpenseReceiptParseResult parsed,
) {
  final expectedLines = fixture.lineExpectations;
  expect(
    parsed.lines,
    hasLength(expectedLines.length),
    reason: '${fixture.name}: line count',
  );
  for (var index = 0; index < expectedLines.length; index++) {
    final expected = expectedLines[index];
    final line = parsed.lines[index];
    final review = index < parsed.lineReviews.length
        ? parsed.lineReviews[index]
        : null;
    expect(
      line.category,
      expected.category,
      reason: '${fixture.name}: line $index category',
    );
    if (expected.descriptionContains != null) {
      expect(
        line.description.toLowerCase(),
        contains(expected.descriptionContains!.toLowerCase()),
        reason: '${fixture.name}: line $index description',
      );
    }
    if (expected.catalogItemName != null) {
      expect(
        [line.catalogItemName, review?.catalogItemName],
        contains(expected.catalogItemName),
        reason: '${fixture.name}: line $index catalog',
      );
    }
    if (expected.quantity != null) {
      expect(
        line.quantity,
        expected.quantity,
        reason: '${fixture.name}: line $index quantity',
      );
    }
    if (expected.unitsPerPackage != null) {
      expect(
        line.unitsPerPackage,
        expected.unitsPerPackage,
        reason: '${fixture.name}: line $index units per package',
      );
    }
    if (expected.unit != null) {
      expect(
        line.unit,
        expected.unit,
        reason: '${fixture.name}: line $index unit',
      );
    }
    if (expected.subtotal != null) {
      expect(
        line.subtotal,
        expected.subtotal,
        reason: '${fixture.name}: line $index subtotal',
      );
    }
    if (expected.needsReview != null) {
      expect(
        line.parserNeedsReview,
        expected.needsReview,
        reason: '${fixture.name}: line $index review flag',
      );
    }
  }
}

bool _equalsText(String? actual, String expected) {
  return (actual ?? '').trim().toLowerCase() == expected.trim().toLowerCase();
}

bool _nearMoney(double? actual, double? expected) {
  if (actual == null || expected == null) return false;
  return (actual - expected).abs() < .01;
}

bool _nearNumber(double actual, double? expected) {
  if (expected == null) return false;
  return (actual - expected).abs() < .001;
}

class _FixtureScore {
  const _FixtureScore({
    required this.assertionCount,
    required this.passedCount,
  });

  final int assertionCount;
  final int passedCount;

  double get score => assertionCount == 0 ? 1 : passedCount / assertionCount;
}
