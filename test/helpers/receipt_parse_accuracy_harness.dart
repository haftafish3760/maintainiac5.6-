import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

part 'receipt_parse_accuracy_scoring_helpers.dart';

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
