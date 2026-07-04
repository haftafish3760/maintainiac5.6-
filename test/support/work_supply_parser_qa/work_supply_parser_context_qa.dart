import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserContextSuite extends QaSuite {
  const WorkSupplyParserContextSuite() : super('inventory.trade_context');

  static const _tradeScopes = <String?>[null, 'Plumbing', 'Electrical', 'HVAC'];
  static const _contextEvidenceTokens = [
    'ambiguous mixed-trade lines',
    'active estimate/job trade section',
    'receipt-neighbor signals',
    'merchant/department hints',
    'cross_trade_copper',
    'pvc_coupling_shorthand',
    'mixed_trade_overlap',
  ];

  static const _cases = [
    _ContextCase(
      line: 'PVC EL 3/4',
      risk: 'PVC elbow can mean plumbing fitting, conduit body, or other work.',
      ambiguousWithoutScope: true,
    ),
    _ContextCase(
      line: 'PVC 90 1/2',
      risk: 'PVC 90 can be plumbing DWV/pressure or electrical conduit.',
      ambiguousWithoutScope: true,
    ),
    _ContextCase(
      line: 'PVC COND 3/4',
      risk: 'Conduit wording should bias electrical without hiding ambiguity.',
      expectedScopedTrade: 'Electrical',
    ),
    _ContextCase(
      line: 'PVC 3/4 CPLG',
      risk:
          'PVC coupling can be plumbing pressure/DWV, electrical conduit, or HVAC condensate.',
      ambiguousWithoutScope: true,
    ),
    _ContextCase(
      line: 'PVC CONDUIT 3/4 CPLG',
      risk:
          'Conduit wording should bias electrical while still preserving review context.',
      expectedScopedTrade: 'Electrical',
    ),
    _ContextCase(
      line: '3/4 COPPER 90',
      risk:
          'Copper 90 can be plumbing supply fitting or HVAC refrigeration fitting.',
      ambiguousWithoutScope: true,
    ),
    _ContextCase(
      line: 'FOIL TAPE',
      risk: 'Tape appears in HVAC, drywall, electrical, and general supplies.',
      ambiguousWithoutScope: true,
    ),
    _ContextCase(
      line: 'ELEC TAPE',
      risk: 'Electrical tape should not become unrelated tape or plumbing.',
      expectedScopedTrade: 'Electrical',
    ),
    _ContextCase(
      line: 'FILTER 20X25X1',
      risk:
          'Filter can be HVAC air filter, water filter, oil filter, or noise.',
      ambiguousWithoutScope: true,
    ),
    _ContextCase(
      line: 'J BOX',
      risk: 'Box is dangerously generic; J-box should bias electrical.',
      expectedScopedTrade: 'Electrical',
    ),
    _ContextCase(
      line: 'THHN 12 BLK',
      risk:
          'Wire wording should bias electrical and reject unrelated black items.',
      expectedScopedTrade: 'Electrical',
    ),
    _ContextCase(
      line: '3/4 COUPLING',
      risk: 'Coupling can belong to plumbing, electrical, HVAC, or fasteners.',
      ambiguousWithoutScope: true,
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final failures = <QaFailure>[];
    final expectedChecks = _cases.fold<int>(
      0,
      (sum, testCase) => sum + _scopesFor(context, testCase).length,
    );
    final timer = QaStopwatch.start();

    if (!context.isFullProfile) {
      return timer.finish(
        suite: name,
        checked: expectedChecks,
        failures: failures,
        maxFailures: context.maxFailuresPerSuite,
        metrics: {
          'mode': 'context-matrix-smoke',
          'caseCount': _cases.length,
          'contextEvidenceTokens': _contextEvidenceTokens,
          'tradeScopes': _tradeScopes.whereType<String>().join(', '),
          'parserCalls': 0,
          'note': 'Context parser assertions run in full/release profiles.',
        },
      );
    }

    final warmup = Stopwatch()..start();
    const warmupLines = [
      ('HD 3/4 PVC SCH40 COUPLING', 'Plumbing'),
      ('PVC COND 3/4', 'Electrical'),
      ('FOIL TAPE', 'HVAC'),
      ('J BOX', 'Electrical'),
      ('THHN 12 BLK', 'Electrical'),
    ];
    for (final (line, tradeScope) in warmupLines) {
      matchReceiptLineToCatalog(
        line,
        tradeScope: tradeScope,
        maxCandidates: 24,
      );
    }
    warmup.stop();
    final warmupMs = warmup.elapsedMilliseconds;
    final semanticTimer = QaStopwatch.start();
    final observedTrades = <String, Set<String>>{};
    final slowestCases = <Map<String, Object?>>[];
    for (final testCase in _cases.take(context.maxGeneratedCases)) {
      final caseTimer = Stopwatch()..start();
      ReceiptLineMatch? unscopedMatch;
      for (final scope in _scopesFor(context, testCase)) {
        final match = matchReceiptLineToCatalog(
          testCase.line,
          tradeScope: scope,
          maxCandidates: 24,
        );
        if (scope == null) unscopedMatch = match;
        if (match != null) {
          observedTrades
              .putIfAbsent(testCase.line, () => <String>{})
              .add(match.item.trade);
        }
        if (scope != null && match != null && match.item.trade != scope) {
          failures.add(
            QaFailure(
              suite: name,
              id: 'scope_leaked:${_id(testCase.line)}:$scope',
              message: 'Trade-scoped parser result returned the wrong trade.',
              expected: scope,
              actual:
                  '${match.item.trade} / ${match.item.name} confidence=${match.confidence}',
              suggestedFix:
                  'Keep trade-scope filtering hard while preserving review warnings for ambiguous receipt lines.',
              metadata: {'risk': testCase.risk, 'line': testCase.line},
            ),
          );
        }
        if (scope == testCase.expectedScopedTrade && match == null) {
          failures.add(
            QaFailure(
              suite: name,
              id: 'expected_scope_missing:${_id(testCase.line)}:${testCase.expectedScopedTrade}',
              message: 'Expected trade context did not produce a candidate.',
              expected: testCase.expectedScopedTrade,
              actual: 'null',
              suggestedFix:
                  'Add trade-specific aliases or receipt patterns for this context fixture.',
              metadata: {'risk': testCase.risk, 'line': testCase.line},
            ),
          );
        }
      }
      if (testCase.ambiguousWithoutScope &&
          unscopedMatch != null &&
          unscopedMatch.confidence >= .82) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'unscoped_false_confident:${_id(testCase.line)}',
            message:
                'Ambiguous mixed-trade receipt line produced a confident unscoped match.',
            expected: 'needs review, unknown, or confidence < 0.82',
            actual:
                '${unscopedMatch.item.trade} / ${unscopedMatch.item.name} confidence=${unscopedMatch.confidence}',
            suggestedFix:
                'Return ranked ambiguity or lower confidence unless job/trade context supplies stronger evidence.',
            metadata: {'risk': testCase.risk, 'line': testCase.line},
          ),
        );
      }
      caseTimer.stop();
      slowestCases.add({
        'id': _id(testCase.line),
        'line': testCase.line,
        'durationMs': caseTimer.elapsedMilliseconds,
        'scopes': _scopesFor(
          context,
          testCase,
        ).map((scope) => scope ?? 'unscoped').join(', '),
      });
    }
    slowestCases.sort(
      (a, b) => (b['durationMs'] as int).compareTo(a['durationMs'] as int),
    );

    return semanticTimer.finish(
      suite: name,
      checked: expectedChecks,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'caseCount': _cases.length,
        'contextEvidenceTokens': _contextEvidenceTokens,
        'tradeScopes': context.isReleaseProfile
            ? _tradeScopes.whereType<String>().join(', ')
            : 'unscoped + expected scoped trade',
        'observedTradesByLine': {
          for (final entry in observedTrades.entries)
            entry.key: entry.value.toList()..sort(),
        },
        'warmupMs': warmupMs,
        'warmupLines': [
          for (final (line, tradeScope) in warmupLines) '$tradeScope: $line',
        ],
        'semanticTimingExcludesWarmup': true,
        'slowestTradeContextCases': slowestCases.take(5).toList(),
      },
    );
  }

  String _id(String line) {
    return line
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  List<String?> _scopesFor(QaContext context, _ContextCase testCase) {
    if (context.isReleaseProfile) return _tradeScopes;
    if (testCase.expectedScopedTrade.isEmpty) return const [null];
    return [null, testCase.expectedScopedTrade];
  }
}

class _ContextCase {
  const _ContextCase({
    required this.line,
    required this.risk,
    this.ambiguousWithoutScope = false,
    this.expectedScopedTrade = '',
  });

  final String line;
  final String risk;
  final bool ambiguousWithoutScope;
  final String expectedScopedTrade;
}
