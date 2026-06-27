import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_parse_accuracy_harness.dart';
import 'helpers/receipt_regression_fixture_packs.dart';

void main() {
  test('receipt regression report stays above readiness floor', () {
    final reports = <_PackReport>[
      for (final entry in receiptRegressionFixturePacks.entries)
        _PackReport(name: entry.key, result: scoreReceiptFixtures(entry.value)),
    ];
    final allFixtures = [
      for (final pack in receiptRegressionFixturePacks.values) ...pack,
    ];
    final overall = scoreReceiptFixtures(allFixtures);

    // ignore: avoid_print
    print(_formatReceiptRegressionReport(reports, overall));

    expect(overall.fixtureCount, allFixtures.length);
    expect(overall.averageReadiness, greaterThanOrEqualTo(.72));
    expect(overall.averageScore, greaterThanOrEqualTo(.78));
    expect(overall.passRate, greaterThanOrEqualTo(.92));
    expect(overall.issueCounts.containsKey('merchant'), isFalse);
    for (final report in reports) {
      expect(
        report.result.averageReadiness,
        greaterThanOrEqualTo(.62),
        reason: '${report.name}: ${report.result.readinessSummary}',
      );
      expect(
        report.result.averageScore,
        greaterThanOrEqualTo(.62),
        reason: '${report.name}: ${report.result.summary}',
      );
    }
  });
}

class _PackReport {
  const _PackReport({required this.name, required this.result});

  final String name;
  final ReceiptParseHarnessResult result;
}

String _formatReceiptRegressionReport(
  List<_PackReport> reports,
  ReceiptParseHarnessResult overall,
) {
  final buffer = StringBuffer()
    ..writeln('')
    ..writeln('Receipt Regression Report')
    ..writeln('=========================')
    ..writeln('')
    ..writeln(_packHeader)
    ..writeln(_packDivider);
  for (final report in reports) {
    buffer.writeln(_packRow(report.name, report.result));
  }
  buffer
    ..writeln(_packDivider)
    ..writeln(_packRow('overall', overall))
    ..writeln('')
    ..writeln('Weakest fixtures')
    ..writeln('----------------')
    ..writeln(_fixtureHeader)
    ..writeln(_fixtureDivider);
  for (final fixture in overall.weakestFixtures) {
    buffer.writeln(_fixtureRow(fixture));
  }
  buffer
    ..writeln('')
    ..writeln('Issue buckets')
    ..writeln('-------------');
  if (overall.issueCounts.isEmpty) {
    buffer.writeln('none');
  } else {
    final sortedIssues = overall.issueCounts.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final issue in sortedIssues) {
      buffer.writeln('${issue.key}: ${issue.value}');
    }
  }
  return buffer.toString();
}

const _packHeader =
    'Pack         Fixtures  Ready  Pass    Score   Quality Readiness Issues';
const _packDivider =
    '------------ --------- ------ ------- ------- ------- --------- ------';
const _fixtureHeader =
    'Fixture                                      State   Ready  M  T  L  C  R  Issues';
const _fixtureDivider =
    '-------------------------------------------- ------- ------ -- -- -- -- -- ----------------';

String _packRow(String packName, ReceiptParseHarnessResult result) {
  return '${_pad(packName, 12)} '
      '${_pad(result.fixtureCount.toString(), 9)} '
      '${_pad('${result.readyFixtureCount}/${result.fixtureCount}', 6)} '
      '${_pad(_percent(result.passRate), 7)} '
      '${_pad(_percent(result.averageScore), 7)} '
      '${_pad(_percent(result.averageQuality), 7)} '
      '${_pad(_percent(result.averageReadiness), 9)} '
      '${result.issueCounts.length}';
}

String _fixtureRow(ReceiptFixtureReadiness fixture) {
  return '${_pad(fixture.name, 44)} '
      '${_pad(fixture.label.name, 7)} '
      '${_pad(_percent(fixture.overallScore), 6)} '
      '${_pad(_shortPercent(fixture.merchantScore), 2)} '
      '${_pad(_shortPercent(fixture.totalsScore), 2)} '
      '${_pad(_shortPercent(fixture.lineScore), 2)} '
      '${_pad(_shortPercent(fixture.catalogScore), 2)} '
      '${_pad(_shortPercent(fixture.reviewScore), 2)} '
      '${fixture.issues.isEmpty ? '-' : fixture.issues.join(',')}';
}

String _percent(double value) {
  return '${(value * 100).toStringAsFixed(1)}%';
}

String _shortPercent(double value) {
  return (value * 100).round().toString();
}

String _pad(String value, int width) {
  final clipped = value.length <= width ? value : value.substring(0, width - 1);
  return clipped.padRight(width);
}
