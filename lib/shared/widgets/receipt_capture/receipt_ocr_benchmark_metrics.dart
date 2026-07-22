/// Pure-Dart scoring for labeled receipt OCR benchmark runs.
class ReceiptOcrBenchmarkCase {
  const ReceiptOcrBenchmarkCase({
    required this.id,
    required this.expectedText,
    required this.actualText,
    this.expectedMerchant,
    this.actualMerchant,
    this.expectedDate,
    this.actualDate,
    this.expectedSubtotal,
    this.actualSubtotal,
    this.expectedTax,
    this.actualTax,
    this.expectedTotal,
    this.actualTotal,
    this.expectedLines = const [],
    this.actualLines = const [],
    this.expectedRoute,
    this.actualRoute,
  });

  final String id;
  final String expectedText;
  final String actualText;
  final String? expectedMerchant;
  final String? actualMerchant;
  final String? expectedDate;
  final String? actualDate;
  final String? expectedSubtotal;
  final String? actualSubtotal;
  final String? expectedTax;
  final String? actualTax;
  final String? expectedTotal;
  final String? actualTotal;
  final List<String> expectedLines;
  final List<String> actualLines;
  final String? expectedRoute;
  final String? actualRoute;
}

class ReceiptOcrBenchmarkReport {
  const ReceiptOcrBenchmarkReport({
    required this.caseCount,
    required this.characterAccuracy,
    required this.wordAccuracy,
    required this.numericAccuracy,
    required this.merchantAccuracy,
    required this.dateAccuracy,
    required this.subtotalAccuracy,
    required this.taxAccuracy,
    required this.totalAccuracy,
    required this.lineReconstructionAccuracy,
    required this.routingAccuracy,
    required this.metricCaseCounts,
  });

  final int caseCount;
  final double characterAccuracy;
  final double wordAccuracy;
  final double numericAccuracy;
  final double merchantAccuracy;
  final double dateAccuracy;
  final double subtotalAccuracy;
  final double taxAccuracy;
  final double totalAccuracy;
  final double lineReconstructionAccuracy;
  final double routingAccuracy;
  final Map<String, int> metricCaseCounts;

  Map<String, double> get metrics => Map.unmodifiable({
    'character': characterAccuracy,
    'word': wordAccuracy,
    'numeric': numericAccuracy,
    'merchant': merchantAccuracy,
    'date': dateAccuracy,
    'subtotal': subtotalAccuracy,
    'tax': taxAccuracy,
    'total': totalAccuracy,
    'lineReconstruction': lineReconstructionAccuracy,
    'routing': routingAccuracy,
  });

  Map<String, int> get coverage => Map.unmodifiable(metricCaseCounts);

  List<String> below(double minimum) => metrics.entries
      .where(
        (entry) =>
            (metricCaseCounts[entry.key] ?? 0) > 0 && entry.value < minimum,
      )
      .map((entry) => entry.key)
      .toList(growable: false);
}

ReceiptOcrBenchmarkReport scoreReceiptOcrBenchmark(
  Iterable<ReceiptOcrBenchmarkCase> cases,
) {
  final values = cases.toList(growable: false);
  double average(
    bool Function(ReceiptOcrBenchmarkCase item) included,
    double Function(ReceiptOcrBenchmarkCase item) score,
  ) {
    final labeled = values.where(included).toList(growable: false);
    return labeled.isEmpty
        ? 0
        : labeled.map(score).reduce((a, b) => a + b) / labeled.length;
  }

  final coverage = <String, int>{
    'character': values.where((item) => item.expectedText.isNotEmpty).length,
    'word': values.where((item) => item.expectedText.isNotEmpty).length,
    'numeric': values.where((item) => item.expectedText.isNotEmpty).length,
    'merchant': values.where((item) => item.expectedMerchant != null).length,
    'date': values.where((item) => item.expectedDate != null).length,
    'subtotal': values.where((item) => item.expectedSubtotal != null).length,
    'tax': values.where((item) => item.expectedTax != null).length,
    'total': values.where((item) => item.expectedTotal != null).length,
    'lineReconstruction': values
        .where((item) => item.expectedLines.isNotEmpty)
        .length,
    'routing': values.where((item) => item.expectedRoute != null).length,
  };
  return ReceiptOcrBenchmarkReport(
    caseCount: values.length,
    characterAccuracy: average(
      (item) => item.expectedText.isNotEmpty,
      (item) => _sequenceAccuracy(
        _characters(item.expectedText),
        _characters(item.actualText),
      ),
    ),
    wordAccuracy: average(
      (item) => item.expectedText.isNotEmpty,
      (item) =>
          _sequenceAccuracy(_words(item.expectedText), _words(item.actualText)),
    ),
    numericAccuracy: average(
      (item) => item.expectedText.isNotEmpty,
      (item) => _sequenceAccuracy(
        _numbers(item.expectedText),
        _numbers(item.actualText),
      ),
    ),
    merchantAccuracy: average(
      (item) => item.expectedMerchant != null,
      (item) => _fieldAccuracy(item.expectedMerchant, item.actualMerchant),
    ),
    dateAccuracy: average(
      (item) => item.expectedDate != null,
      (item) => _fieldAccuracy(item.expectedDate, item.actualDate),
    ),
    subtotalAccuracy: average(
      (item) => item.expectedSubtotal != null,
      (item) => _fieldAccuracy(item.expectedSubtotal, item.actualSubtotal),
    ),
    taxAccuracy: average(
      (item) => item.expectedTax != null,
      (item) => _fieldAccuracy(item.expectedTax, item.actualTax),
    ),
    totalAccuracy: average(
      (item) => item.expectedTotal != null,
      (item) => _fieldAccuracy(item.expectedTotal, item.actualTotal),
    ),
    lineReconstructionAccuracy: average(
      (item) => item.expectedLines.isNotEmpty,
      (item) => _sequenceAccuracy(
        item.expectedLines.map(_normalize).toList(),
        item.actualLines.map(_normalize).toList(),
      ),
    ),
    routingAccuracy: average(
      (item) => item.expectedRoute != null,
      (item) => _fieldAccuracy(item.expectedRoute, item.actualRoute),
    ),
    metricCaseCounts: Map.unmodifiable(coverage),
  );
}

double _fieldAccuracy(String? expected, String? actual) {
  if (expected == null) return actual == null ? 1 : 0;
  return _normalize(expected) == _normalize(actual ?? '') ? 1 : 0;
}

List<String> _characters(String value) => _normalize(value).split('');
List<String> _words(String value) => RegExp(
  r'\S+',
).allMatches(_normalize(value)).map((match) => match.group(0)!).toList();
List<String> _numbers(String value) => RegExp(r'-?\d+(?:[.,]\d+)?')
    .allMatches(value)
    .map((match) => match.group(0)!.replaceAll(',', ''))
    .toList();
String _normalize(String value) =>
    value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

double _sequenceAccuracy(List<String> expected, List<String> actual) {
  if (expected.isEmpty) return actual.isEmpty ? 1 : 0;
  final distance = List.generate(
    expected.length + 1,
    (index) => List<int>.generate(
      actual.length + 1,
      (inner) => index == 0
          ? inner
          : inner == 0
          ? index
          : 0,
    ),
  );
  for (var row = 1; row <= expected.length; row++) {
    for (var column = 1; column <= actual.length; column++) {
      distance[row][column] = expected[row - 1] == actual[column - 1]
          ? distance[row - 1][column - 1]
          : 1 +
                [
                  distance[row - 1][column],
                  distance[row][column - 1],
                  distance[row - 1][column - 1],
                ].reduce((a, b) => a < b ? a : b);
    }
  }
  return 1 -
      distance.last.last /
          [expected.length, actual.length].reduce((a, b) => a > b ? a : b);
}
