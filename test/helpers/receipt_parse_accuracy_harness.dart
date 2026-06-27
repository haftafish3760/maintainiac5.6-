import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

class ReceiptParseFixture {
  const ReceiptParseFixture({
    required this.name,
    required this.text,
    required this.expectedMerchant,
    this.expectedDate,
    this.expectedTimeMinutes,
    this.expectedSubtotal,
    this.expectedTax,
    this.expectedTotal,
    this.expectedLineCategories = const [],
    this.expectedLines = const [],
    this.expectedCatalogItems = const [],
    this.minimumQuality = .58,
    this.minimumScore = .82,
  });

  final String name;
  final String text;
  final String expectedMerchant;
  final DateTime? expectedDate;
  final int? expectedTimeMinutes;
  final double? expectedSubtotal;
  final double? expectedTax;
  final double? expectedTotal;
  final List<String> expectedLineCategories;
  final List<ReceiptLineExpectation> expectedLines;
  final List<String> expectedCatalogItems;
  final double minimumQuality;
  final double minimumScore;

  List<ReceiptLineExpectation> get lineExpectations {
    if (expectedLines.isNotEmpty) return expectedLines;
    return [
      for (final category in expectedLineCategories)
        ReceiptLineExpectation(category: category),
    ];
  }
}

class ReceiptLineExpectation {
  const ReceiptLineExpectation({
    required this.category,
    this.descriptionContains,
    this.catalogItemName,
    this.quantity,
    this.unitsPerPackage,
    this.unit,
    this.subtotal,
    this.needsReview,
  });

  final String category;
  final String? descriptionContains;
  final String? catalogItemName;
  final double? quantity;
  final double? unitsPerPackage;
  final String? unit;
  final double? subtotal;
  final bool? needsReview;
}

class ReceiptParseHarnessResult {
  const ReceiptParseHarnessResult({
    required this.fixtureCount,
    required this.assertionCount,
    required this.passedCount,
    required this.averageQuality,
    required this.averageScore,
    required this.averageReadiness,
    required this.fixtureScores,
    required this.fixtureReadiness,
    required this.issueCounts,
  });

  final int fixtureCount;
  final int assertionCount;
  final int passedCount;
  final double averageQuality;
  final double averageScore;
  final double averageReadiness;
  final Map<String, double> fixtureScores;
  final Map<String, ReceiptFixtureReadiness> fixtureReadiness;
  final Map<String, int> issueCounts;

  double get passRate => assertionCount == 0 ? 1 : passedCount / assertionCount;
  int get readyFixtureCount => fixtureReadiness.values
      .where((readiness) => readiness.label == ReceiptReadinessLabel.ready)
      .length;

  List<ReceiptFixtureReadiness> get weakestFixtures {
    final sorted = fixtureReadiness.values.toList(growable: false)
      ..sort((a, b) => a.overallScore.compareTo(b.overallScore));
    return List.unmodifiable(sorted.take(5));
  }

  String get summary {
    return 'fixtures=$fixtureCount passRate=${(passRate * 100).toStringAsFixed(1)}% '
        'avgScore=${(averageScore * 100).toStringAsFixed(1)}% '
        'avgQuality=${(averageQuality * 100).toStringAsFixed(1)}% '
        'avgReadiness=${(averageReadiness * 100).toStringAsFixed(1)}%';
  }

  String get readinessSummary {
    final weak = weakestFixtures
        .map(
          (fixture) =>
              '${fixture.name}:${(fixture.overallScore * 100).round()}%',
        )
        .join(', ');
    final issues = issueCounts.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(', ');
    return 'ready=$readyFixtureCount/$fixtureCount weakest=[$weak] issues=[$issues]';
  }
}

enum ReceiptReadinessLabel { ready, review, blocked }

class ReceiptFixtureReadiness {
  const ReceiptFixtureReadiness({
    required this.name,
    required this.overallScore,
    required this.merchantScore,
    required this.totalsScore,
    required this.lineScore,
    required this.catalogScore,
    required this.reviewScore,
    required this.trustLabel,
    required this.issues,
  });

  final String name;
  final double overallScore;
  final double merchantScore;
  final double totalsScore;
  final double lineScore;
  final double catalogScore;
  final double reviewScore;
  final String trustLabel;
  final List<String> issues;

  ReceiptReadinessLabel get label {
    if (overallScore >= .9 && issues.isEmpty) {
      return ReceiptReadinessLabel.ready;
    }
    if (overallScore >= .68) return ReceiptReadinessLabel.review;
    return ReceiptReadinessLabel.blocked;
  }

  String get summary {
    return '$name ${label.name} ${(overallScore * 100).toStringAsFixed(1)}% '
        'merchant=${(merchantScore * 100).round()} '
        'totals=${(totalsScore * 100).round()} '
        'lines=${(lineScore * 100).round()} '
        'catalog=${(catalogScore * 100).round()} '
        'review=${(reviewScore * 100).round()} '
        'trust=$trustLabel';
  }
}

ReceiptParseHarnessResult expectReceiptFixtures(
  List<ReceiptParseFixture> fixtures,
) {
  final report = scoreReceiptFixtures(fixtures);
  for (final entry in report.fixtureScores.entries) {
    final fixture = fixtures.firstWhere((item) => item.name == entry.key);
    expect(
      entry.value,
      greaterThanOrEqualTo(fixture.minimumScore),
      reason: '${fixture.name}: scored ${(entry.value * 100).round()}%',
    );
  }
  expect(
    report.passRate,
    1,
    reason: '${report.summary} ${report.readinessSummary}',
  );
  expectReceiptFixtureDetails(fixtures);
  return report;
}

ReceiptParseHarnessResult scoreReceiptFixtures(
  List<ReceiptParseFixture> fixtures,
) {
  var assertions = 0;
  var passed = 0;
  var qualityTotal = 0.0;
  final scores = <String, double>{};
  final readiness = <String, ReceiptFixtureReadiness>{};
  final issueCounts = <String, int>{};

  for (final fixture in fixtures) {
    final parsed = parseExpenseReceiptText(fixture.text);
    qualityTotal += parsed.quality.confidence;
    final score = _scoreFixture(fixture, parsed);
    assertions += score.assertionCount;
    passed += score.passedCount;
    scores[fixture.name] = score.score;
    final fixtureReadiness = _readinessForFixture(fixture, parsed);
    readiness[fixture.name] = fixtureReadiness;
    for (final issue in fixtureReadiness.issues) {
      issueCounts.update(issue, (value) => value + 1, ifAbsent: () => 1);
    }
  }
  final averageReadiness = readiness.isEmpty
      ? 1.0
      : readiness.values
                .map((item) => item.overallScore)
                .reduce((a, b) => a + b) /
            readiness.length;

  return ReceiptParseHarnessResult(
    fixtureCount: fixtures.length,
    assertionCount: assertions,
    passedCount: passed,
    averageQuality: fixtures.isEmpty ? 1 : qualityTotal / fixtures.length,
    averageScore: scores.isEmpty
        ? 1
        : scores.values.reduce((a, b) => a + b) / scores.length,
    fixtureScores: Map.unmodifiable(scores),
    averageReadiness: averageReadiness,
    fixtureReadiness: Map.unmodifiable(readiness),
    issueCounts: Map.unmodifiable(issueCounts),
  );
}

void expectReceiptFixtureDetails(List<ReceiptParseFixture> fixtures) {
  for (final fixture in fixtures) {
    final parsed = parseExpenseReceiptText(fixture.text);
    expect(
      parsed.merchantName,
      fixture.expectedMerchant,
      reason: '${fixture.name}: merchant',
    );
    if (fixture.expectedDate != null) {
      expect(
        parsed.receiptDate,
        fixture.expectedDate,
        reason: '${fixture.name}: date',
      );
    }
    if (fixture.expectedTimeMinutes != null) {
      expect(
        parsed.receiptTimeMinutes,
        fixture.expectedTimeMinutes,
        reason: '${fixture.name}: time',
      );
    }
    if (fixture.expectedSubtotal != null) {
      expect(
        parsed.enteredSubtotal,
        fixture.expectedSubtotal,
        reason: '${fixture.name}: subtotal',
      );
    }
    if (fixture.expectedTax != null) {
      expect(
        parsed.enteredTax,
        fixture.expectedTax,
        reason: '${fixture.name}: tax',
      );
    }
    if (fixture.expectedTotal != null) {
      expect(
        parsed.enteredTotal,
        fixture.expectedTotal,
        reason: '${fixture.name}: total',
      );
    }
    expect(
      parsed.quality.confidence,
      greaterThanOrEqualTo(fixture.minimumQuality),
      reason: '${fixture.name}: quality',
    );
    _expectLines(fixture, parsed);
  }
}

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
