import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('generated parser fixture batch matches expected safety contracts', () {
    const fixturePath = String.fromEnvironment(
      'PARSER_QA_GENERATED_FIXTURE_PATH',
    );
    const maxCases = int.fromEnvironment(
      'PARSER_QA_GENERATED_FIXTURE_MAX_CASES',
      defaultValue: 1000,
    );
    const reportDir = String.fromEnvironment(
      'PARSER_QA_GENERATED_REPORT_DIR',
      defaultValue: 'build/parser_qa_reports/generated_fixtures',
    );
    const fixtureIdsCsv = String.fromEnvironment(
      'PARSER_QA_GENERATED_FIXTURE_IDS',
    );
    const startIndex = int.fromEnvironment(
      'PARSER_QA_GENERATED_FIXTURE_START_INDEX',
    );
    if (fixturePath.trim().isEmpty) {
      // This entry point is intentionally opt-in so normal smoke runs do not
      // accidentally pay parser-call cost.
      expect(fixturePath, isEmpty);
      return;
    }

    final file = File(fixturePath);
    expect(file.existsSync(), isTrue, reason: fixturePath);

    final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    final fixtureIds = _csvSet(fixtureIdsCsv);
    final allFixtures = [
      for (final entry in decoded)
        _GeneratedFixture.fromJson((entry as Map).cast<String, Object?>()),
    ];
    final fixtures = _selectGeneratedFixtures(
      allFixtures,
      fixtureIds: fixtureIds,
      startIndex: startIndex,
      maxCases: maxCases,
    );
    expect(
      fixtures,
      isNotEmpty,
      reason: fixtureIds.isEmpty
          ? fixturePath
          : 'No generated fixtures matched PARSER_QA_GENERATED_FIXTURE_IDS=$fixtureIdsCsv',
    );
    final warmupLines = _warmupLinesFor(fixtures);
    final warmupTimer = Stopwatch()..start();
    for (final line in warmupLines) {
      matchReceiptLineToCatalog(
        line,
        tradeScope: 'Plumbing',
        maxCandidates: 24,
      );
    }
    warmupTimer.stop();

    final failures = <String>[];
    final timings = <Map<String, Object?>>[];
    for (final fixture in fixtures) {
      final timer = Stopwatch()..start();
      final match = matchReceiptLineToCatalog(
        fixture.rawLine,
        tradeScope: fixture.tradeScope,
        localePackId: fixture.localePackId,
        maxCandidates: 24,
      );
      timer.stop();
      timings.add({
        'id': fixture.id,
        'durationMs': timer.elapsedMilliseconds,
        'caseType': fixture.caseType,
      });

      if (fixture.expectUnknown) {
        if (match != null && match.confidence > fixture.maxConfidence) {
          failures.add(
            '${fixture.id}: expected review/unknown <= '
            '${fixture.maxConfidence}, got ${match.item.name} '
            'confidence=${match.confidence}',
          );
        }
        continue;
      }
      if (match == null) {
        failures.add('${fixture.id}: expected match, got null');
        continue;
      }
      if (fixture.expectedTrade.isNotEmpty &&
          match.item.trade != fixture.expectedTrade) {
        failures.add(
          '${fixture.id}: expected trade ${fixture.expectedTrade}, '
          'got ${match.item.trade}',
        );
      }
      if (fixture.expectedNameContains.isNotEmpty &&
          !match.item.name.toLowerCase().contains(
            fixture.expectedNameContains.toLowerCase(),
          )) {
        failures.add(
          '${fixture.id}: expected name containing '
          '"${fixture.expectedNameContains}", got "${match.item.name}"',
        );
      }
    }

    timings.sort(
      (a, b) => (b['durationMs'] as int).compareTo(a['durationMs'] as int),
    );
    final artifact = _writeGeneratedFixtureReport(
      reportDir: reportDir,
      fixturePath: fixturePath,
      checked: fixtures.length,
      failures: failures,
      warmupMs: warmupTimer.elapsedMilliseconds,
      timings: timings,
      maxCases: maxCases,
      fixtureIds: fixtureIds,
      warmupCallCount: warmupLines.length,
    );
    // ignore: avoid_print
    print(
      'QA_GENERATED_FIXTURE_RUN path=$fixturePath checked=${fixtures.length} '
      'failures=${failures.length} warmupMs=${warmupTimer.elapsedMilliseconds} '
      'fixtureIds=${fixtureIds.toList()..sort()} '
      'semanticTimingExcludesWarmup=true report=${artifact.latestJsonPath} '
      'slowest=${timings.take(5).toList()}',
    );
    expect(failures, isEmpty, reason: failures.take(20).join('\n'));
  });

  test('generated fixture runner filters explicit fixture ids surgically', () {
    const fixtures = [
      _GeneratedFixture(
        id: 'electrical_residential_core_en_US_dangerous_pvc_conduit_00044',
        rawLine: 'GRAINGER PVC COND 3/4 45.08',
        caseType: 'ambiguous_review',
      ),
      _GeneratedFixture(
        id: 'electrical_residential_core_en_US_nm_b_wire_00046',
        rawLine: 'LOWES NM-B 12/2 25FT',
        caseType: 'clear_match',
      ),
    ];

    final selected = _selectGeneratedFixtures(
      fixtures,
      fixtureIds: const {
        'electrical_residential_core_en_US_dangerous_pvc_conduit_00044',
      },
      startIndex: 0,
      maxCases: 10,
    );

    expect(selected, hasLength(1));
    expect(
      selected.single.id,
      'electrical_residential_core_en_US_dangerous_pvc_conduit_00044',
    );
  });

  test('generated fixture runner selects fixture chunks by offset', () {
    final fixtures = [
      for (var index = 0; index < 5; index++)
        _GeneratedFixture(
          id: 'fixture_$index',
          rawLine: 'LOWES NM-B 12/2 25FT',
          caseType: 'clear_match',
        ),
    ];

    final selected = _selectGeneratedFixtures(
      fixtures,
      fixtureIds: const {},
      startIndex: 2,
      maxCases: 2,
    );

    expect(selected.map((fixture) => fixture.id), ['fixture_2', 'fixture_3']);
  });
}

List<String> _warmupLinesFor(List<_GeneratedFixture> fixtures) {
  final lines = <String>{
    'HD 3/4 PVC SCH40 COUPLING',
    'HD 1/2 PEX CRMP ELL',
    'HD TOILET WAX RING',
    'HD 3/8 ALL THREAD ROD',
  };
  for (final fixture in fixtures.take(12)) {
    if (fixture.rawLine.trim().isNotEmpty) lines.add(fixture.rawLine);
  }
  return lines.toList(growable: false);
}

Set<String> _csvSet(String value) {
  return value
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toSet();
}

List<_GeneratedFixture> _selectGeneratedFixtures(
  List<_GeneratedFixture> fixtures, {
  required Set<String> fixtureIds,
  required int startIndex,
  required int maxCases,
}) {
  return [
    for (final fixture in fixtures)
      if (fixtureIds.isEmpty || fixtureIds.contains(fixture.id)) fixture,
  ].skip(startIndex).take(maxCases).toList(growable: false);
}

_GeneratedFixtureRunArtifact _writeGeneratedFixtureReport({
  required String reportDir,
  required String fixturePath,
  required int checked,
  required List<String> failures,
  required int warmupMs,
  required List<Map<String, Object?>> timings,
  required int maxCases,
  required Set<String> fixtureIds,
  required int warmupCallCount,
}) {
  final directory = Directory(reportDir)..createSync(recursive: true);
  final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
    RegExp(r'[:.]'),
    '',
  );
  final timestamped = File(
    '${directory.path}/generated_fixture_run_$stamp.json',
  );
  final latest = File('${directory.path}/latest_generated_fixture_run.json');
  final report = {
    'schemaVersion': 1,
    'domain': 'work_supply_inventory_parser_generated_fixtures',
    'fixturePath': fixturePath,
    'maxCases': maxCases,
    'fixtureIds': fixtureIds.toList()..sort(),
    'checked': checked,
    'failureCount': failures.length,
    'failures': failures.take(100).toList(),
    'warmupMs': warmupMs,
    'semanticTimingExcludesWarmup': true,
    'slowestCases': timings.take(20).toList(),
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
    'parserCalls': checked + warmupCallCount,
    'warmupCallCount': warmupCallCount,
    'generatedAtIso': DateTime.now().toUtc().toIso8601String(),
  };
  final encoded = const JsonEncoder.withIndent('  ').convert(report);
  timestamped.writeAsStringSync(encoded, flush: true);
  latest.writeAsStringSync(encoded, flush: true);
  return _GeneratedFixtureRunArtifact(
    timestampedJsonPath: timestamped.path,
    latestJsonPath: latest.path,
  );
}

class _GeneratedFixtureRunArtifact {
  const _GeneratedFixtureRunArtifact({
    required this.timestampedJsonPath,
    required this.latestJsonPath,
  });

  final String timestampedJsonPath;
  final String latestJsonPath;
}

class _GeneratedFixture {
  const _GeneratedFixture({
    required this.id,
    required this.rawLine,
    required this.caseType,
    this.expectedTrade = '',
    this.expectedNameContains = '',
    this.tradeScope,
    this.localePackId = '',
    this.expectUnknown = false,
    this.maxConfidence = 1,
  });

  final String id;
  final String rawLine;
  final String caseType;
  final String expectedTrade;
  final String expectedNameContains;
  final String? tradeScope;
  final String localePackId;
  final bool expectUnknown;
  final double maxConfidence;

  static _GeneratedFixture fromJson(Map<String, Object?> json) {
    return _GeneratedFixture(
      id: json['id'] as String? ?? 'generated_fixture_without_id',
      rawLine: json['rawLine'] as String? ?? '',
      caseType: json['caseType'] as String? ?? '',
      expectedTrade: json['expectedTrade'] as String? ?? '',
      expectedNameContains: json['expectedNameContains'] as String? ?? '',
      tradeScope: json['tradeScope'] as String?,
      localePackId: json['localePackId'] as String? ?? '',
      expectUnknown: json['expectUnknown'] as bool? ?? false,
      maxConfidence: (json['maxConfidence'] as num?)?.toDouble() ?? 1,
    );
  }
}
