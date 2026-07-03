import 'dart:convert';
import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserAccumulatedCoverageSuite extends QaSuite {
  const WorkSupplyParserAccumulatedCoverageSuite()
    : super('inventory.accumulated_coverage_contract');

  static const _priorityCells = {
    'plumbing.residential.core.en-US',
    'plumbing.residential.core.es-US',
    'electrical.residential.core.en-US',
    'electrical.residential.core.es-US',
    'hvac.residential.core.en-US',
    'hvac.residential.core.es-US',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final fixtures = _loadFixtures();
    final fixtureCells = <String, int>{};
    final blueprintCells = _discoverBlueprintCells();

    for (final fixture in fixtures) {
      if (fixture.trade.isEmpty ||
          fixture.marketScope.isEmpty ||
          fixture.tier.isEmpty ||
          fixture.localePackId.isEmpty) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'fixture_missing_cell:${fixture.id}',
            message:
                'Parser fixture is missing trade/scope/tier/locale cell metadata.',
            severity: QaSeverity.warning,
            expected: 'trade, marketScope, tier, localePackId',
            actual:
                'trade=${fixture.trade}; scope=${fixture.marketScope}; tier=${fixture.tier}; locale=${fixture.localePackId}',
            suggestedFix:
                'Generated fixtures must carry the same coverage cell as their catalog item batch.',
            metadata: const {'triageCategory': QaFailureTriage.fixture},
          ),
        );
        continue;
      }
      _increment(fixtureCells, fixture.cellId);
    }

    for (final cell in _priorityCells) {
      if ((fixtureCells[cell] ?? 0) == 0) {
        failures.add(
          _missingCellFailure(
            id: 'missing_priority_fixture_cell:$cell',
            message: 'Priority release-one parser fixture cell is missing.',
            expected: cell,
            actual: fixtureCells.keys.join(', '),
          ),
        );
      }
    }

    for (final cell in blueprintCells.keys) {
      if ((fixtureCells[cell] ?? 0) > 0) continue;
      failures.add(
        _missingCellFailure(
          id: 'blueprint_without_fixture_cell:$cell',
          message:
              'Catalog blueprint cell has no matching generated parser fixture evidence.',
          expected: cell,
          actual: fixtureCells.keys.join(', '),
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: fixtures.length + _priorityCells.length + blueprintCells.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'fixtureCells': _topCounts(fixtureCells, limit: 24),
        'blueprintCells': _topCounts(blueprintCells, limit: 24),
        'priorityCells': _priorityCells.toList()..sort(),
        'contract':
            'Every generated residential trade-pack catalog batch needs matching parser fixtures for the same trade/scope/tier/locale cell.',
      },
    );
  }

  QaFailure _missingCellFailure({
    required String id,
    required String message,
    required String expected,
    required String actual,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix:
          'Generate the matching fixture batch before treating this catalog cell as covered.',
      metadata: const {'triageCategory': QaFailureTriage.fixture},
    );
  }
}

class _CoverageFixture {
  const _CoverageFixture({
    required this.id,
    required this.trade,
    required this.marketScope,
    required this.tier,
    required this.localePackId,
  });

  final String id;
  final String trade;
  final String marketScope;
  final String tier;
  final String localePackId;

  String get cellId =>
      '${trade.toLowerCase()}.${marketScope.toLowerCase()}.${tier.toLowerCase()}.$localePackId';

  static _CoverageFixture fromJson(Map<String, Object?> json) {
    return _CoverageFixture(
      id: json['id'] as String? ?? 'fixture_without_id',
      trade: json['trade'] as String? ?? '',
      marketScope: json['marketScope'] as String? ?? '',
      tier: json['tier'] as String? ?? '',
      localePackId: json['localePackId'] as String? ?? '',
    );
  }
}

List<_CoverageFixture> _loadFixtures() {
  final file = File('test/fixtures/work_supply_parser/golden_fixtures.json');
  if (!file.existsSync()) return const [];
  final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return [
    for (final entry in decoded)
      _CoverageFixture.fromJson((entry as Map).cast<String, Object?>()),
  ];
}

Map<String, int> _discoverBlueprintCells() {
  final root = Directory('build/work_supply_catalog');
  if (!root.existsSync()) return const {};
  final counts = <String, int>{};
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('item_blueprints.json')) {
      continue;
    }
    final parts = entity.path.replaceAll('\\', '/').split('/');
    final index = parts.indexOf('work_supply_catalog');
    if (index < 0 || parts.length < index + 6) continue;
    final cell = [
      parts[index + 1],
      parts[index + 2],
      parts[index + 3],
      parts[index + 4],
    ].join('.');
    _increment(counts, cell);
  }
  return counts;
}

void _increment(Map<String, int> counts, String key) {
  counts.update(key, (count) => count + 1, ifAbsent: () => 1);
}

List<Map<String, Object?>> _topCounts(
  Map<String, int> counts, {
  int limit = 12,
}) {
  final entries = counts.entries.toList()
    ..sort((left, right) => right.value.compareTo(left.value));
  return [
    for (final entry in entries.take(limit))
      {'name': entry.key, 'count': entry.value},
  ];
}
