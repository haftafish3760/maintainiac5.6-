import 'dart:convert';
import 'dart:io';

import '../qa_harness/qa_harness.dart';

const _goldenFixturePath =
    'test/fixtures/work_supply_parser/golden_fixtures.json';

class WorkSupplyParserCategoryInferenceSuite extends QaSuite {
  const WorkSupplyParserCategoryInferenceSuite()
    : super('inventory.category_inference_contract');

  static const _sourcePaths = {
    'test/support/work_supply_parser_qa/work_supply_parser_category_inference_qa.dart',
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_workflow_routing_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_context_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_pack_overlap_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_conflict_graph_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_estimate_section_qa.dart',
  };

  static const _categoryOutputs = {
    'inventory category',
    'expense category',
    'job material category',
    'tax/reporting category',
    'maintenance relevance',
    'billable material',
    'default unit cost',
    'default markup',
    'trade section',
    'category of work',
  };

  static const _inferenceSignals = {
    'trade',
    'merchant',
    'active job',
    'estimate section',
    'enabled trade packs',
    'vehicle inventory',
    'user business type',
    'previous corrections',
    'item family',
    'item type',
    'material',
    'connection type',
  };

  static const _categoryRules = {
    'category_inference_never_auto_saves',
    'category_inference_returns_ranked_candidates',
    'category_inference_keeps_ambiguity_visible',
    'category_inference_context_boosts_not_forces',
    'category_inference_requires_review_for_cross_trade_items',
    'category_inference_preserves_confidence_reasons',
    'category_inference_preserves_missing_fields',
    'category_inference_routes_to_workflow_without_mutating_source',
    'category_inference_separates_catalog_identity_from_user_inventory',
    'category_inference_can_return_unknown',
  };

  static const _ambiguousCategoryCases = {
    'PVC elbow',
    'PVC conduit',
    'PVC condensate',
    'foil tape',
    'electrical tape',
    'drywall tape',
    'filter',
    'old work box',
    'J box',
    'threaded rod',
    'all thread',
    'tapcon',
  };

  static const _fixtureRiskAxes = {
    'pvc',
    'pvc_conduit',
    'pvc_condensate',
    'foil_tape',
    'electrical_tape',
    'drywall_tape',
    'filter',
    'old_work_box',
    'j_box',
    'threaded_rod',
    'all_thread',
    'tapcon',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    final fixtures = _loadFixtures();
    final fixtureRiskCounts = _fixtureRiskCounts(fixtures);
    var checked = 0;

    checked += _categoryOutputs.length;
    _requireTokens(
      failures,
      source,
      _categoryOutputs,
      idPrefix: 'missing_category_output',
      message: 'Category inference QA is missing a parser output category.',
      fix:
          'Category inference must cover inventory, expense, job material, tax/reporting, maintenance, billable, cost, markup, trade section, and category-of-work outputs.',
      triage: QaFailureTriage.category,
    );

    checked += _inferenceSignals.length;
    _requireTokens(
      failures,
      source,
      _inferenceSignals,
      idPrefix: 'missing_inference_signal',
      message: 'Category inference QA is missing a ranking signal.',
      fix:
          'Category ranking must consider trade, merchant, job/estimate context, enabled packs, vehicle inventory, business type, corrections, family/type, material, and connection type.',
      triage: QaFailureTriage.context,
    );

    checked += _categoryRules.length;
    _requireRules(failures, source, _categoryRules);

    checked += _ambiguousCategoryCases.length;
    _requireTokens(
      failures,
      source,
      _ambiguousCategoryCases,
      idPrefix: 'missing_ambiguous_category_case',
      message: 'Category inference QA is missing a cross-trade ambiguity case.',
      fix:
          'Add category fixtures for PVC, tape, filters, boxes, threaded rod/all-thread, tapcons, and other cross-trade items.',
      triage: QaFailureTriage.conflict,
    );

    checked += _fixtureRiskAxes.length + fixtures.length;
    _requireFixtureAxes(failures, fixtureRiskCounts);

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'fixtureRiskCounts': fixtureRiskCounts,
        'contract':
            'Category inference ranks possible workflow destinations and categories, but never hides ambiguity or mutates receipt/job/estimate/invoice sources.',
      },
    );
  }

  void _requireRules(
    List<QaFailure> failures,
    String source,
    Set<String> rules,
  ) {
    final lower = _normalizeContractText(source);
    for (final rule in rules) {
      if (lower.contains(_normalizeContractText(rule))) continue;
      failures.add(
        _failure(
          id: 'missing_category_inference_rule:${_safeId(rule)}',
          message: 'Category inference QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit category inference rules before parser candidates feed inventory, job, estimate, invoice, expense, or reporting categories.',
          triage: QaFailureTriage.category,
        ),
      );
    }
  }

  void _requireTokens(
    List<QaFailure> failures,
    String source,
    Set<String> tokens, {
    required String idPrefix,
    required String message,
    required String fix,
    required String triage,
  }) {
    final lower = _normalizeContractText(source);
    for (final token in tokens) {
      if (lower.contains(_normalizeContractText(token))) continue;
      failures.add(
        _failure(
          id: '$idPrefix:${_safeId(token)}',
          message: message,
          expected: token,
          actual: 'not found',
          fix: fix,
          triage: triage,
        ),
      );
    }
  }

  String _readSources() {
    final buffer = StringBuffer();
    for (final path in _sourcePaths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      buffer.writeln(file.readAsStringSync());
    }
    return buffer.toString();
  }

  void _requireFixtureAxes(
    List<QaFailure> failures,
    Map<String, int> fixtureRiskCounts,
  ) {
    for (final axis in _fixtureRiskAxes) {
      if ((fixtureRiskCounts[axis] ?? 0) > 0) continue;
      failures.add(
        _failure(
          id: 'missing_category_fixture_axis:$axis',
          message:
              'Category inference fixture corpus is missing a required ambiguity axis.',
          expected: axis,
          actual: fixtureRiskCounts.keys.join(', '),
          fix:
              'Add a synthetic review fixture for this cross-trade category inference case.',
          triage: QaFailureTriage.fixture,
        ),
      );
    }
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String fix,
    required String triage,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: {'triageCategory': triage},
    );
  }
}

Map<String, int> _fixtureRiskCounts(List<_CategoryFixture> fixtures) {
  final counts = <String, int>{};
  for (final fixture in fixtures) {
    final tags = fixture.riskTags.map((tag) => tag.toLowerCase()).toSet();
    final line = fixture.rawLine.toLowerCase();
    final axes = {
      ...tags,
      if (line.contains('pvc')) 'pvc',
      if (line.contains('cond') || line.contains('conduit')) 'pvc_conduit',
      if (line.contains('condensate')) 'pvc_condensate',
      if (line.contains('foil tape')) 'foil_tape',
      if (line.contains('elec tape') || line.contains('electrical tape'))
        'electrical_tape',
      if (line.contains('drywall tape')) 'drywall_tape',
      if (line.contains('filter')) 'filter',
      if (line.contains('old work box')) 'old_work_box',
      if (line.contains('j box')) 'j_box',
      if (line.contains('threaded rod')) 'threaded_rod',
      if (line.contains('all thread')) 'all_thread',
      if (line.contains('tapcon')) 'tapcon',
    };
    for (final axis in axes) {
      counts.update(axis, (count) => count + 1, ifAbsent: () => 1);
    }
  }
  return counts;
}

List<_CategoryFixture> _loadFixtures() {
  final file = File(_goldenFixturePath);
  if (!file.existsSync()) return const [];
  final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return [
    for (final entry in decoded)
      _CategoryFixture.fromJson((entry as Map).cast<String, Object?>()),
  ];
}

class _CategoryFixture {
  const _CategoryFixture({required this.rawLine, required this.riskTags});

  final String rawLine;
  final List<String> riskTags;

  static _CategoryFixture fromJson(Map<String, Object?> json) {
    return _CategoryFixture(
      rawLine: json['rawLine'] as String? ?? '',
      riskTags: [
        for (final tag in json['riskTags'] as List<dynamic>? ?? const [])
          tag.toString(),
      ],
    );
  }
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
