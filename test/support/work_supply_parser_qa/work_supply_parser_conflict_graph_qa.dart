import 'package:maintaniac/screens/work_supplies/data/work_supply_parser_candidate_models.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserConflictGraphSuite extends QaSuite {
  const WorkSupplyParserConflictGraphSuite()
    : super('inventory.conflict_graph');

  static const _rules = [
    _ConflictRule(
      id: 'pvc_plumbing_vs_conduit_vs_hvac',
      ambiguousLine: 'PVC 90 3/4',
      family: 'PVC elbow',
      competingTrades: ['Plumbing', 'Electrical', 'HVAC'],
      requiredPositiveEvidence: ['pipe', 'conduit', 'condensate'],
      requiredNegativeEvidence: ['missing trade-specific material purpose'],
    ),
    _ConflictRule(
      id: 'tape_electrical_vs_hvac_vs_drywall',
      ambiguousLine: 'FOIL TAPE',
      family: 'tape',
      competingTrades: ['Electrical', 'HVAC', 'Drywall'],
      requiredPositiveEvidence: ['electrical', 'foil', 'drywall'],
      requiredNegativeEvidence: ['generic tape token'],
    ),
    _ConflictRule(
      id: 'filter_hvac_vs_water_vs_oil',
      ambiguousLine: 'FILTER 20X25X1',
      family: 'filter',
      competingTrades: ['HVAC', 'Plumbing', 'Vehicle'],
      requiredPositiveEvidence: ['air', 'water', 'oil'],
      requiredNegativeEvidence: ['filter alone is dangerous'],
    ),
    _ConflictRule(
      id: 'box_electrical_vs_storage_vs_packaging',
      ambiguousLine: 'J BOX',
      family: 'box',
      competingTrades: ['Electrical', 'General', 'Packaging'],
      requiredPositiveEvidence: ['junction', 'old work', 'carton'],
      requiredNegativeEvidence: ['box alone is dangerous'],
    ),
    _ConflictRule(
      id: 'coupling_plumbing_vs_conduit_vs_hvac',
      ambiguousLine: '3/4 COUPLING',
      family: 'coupling',
      competingTrades: ['Plumbing', 'Electrical', 'HVAC'],
      requiredPositiveEvidence: ['pvc pipe', 'conduit', 'duct'],
      requiredNegativeEvidence: ['coupling alone is dangerous'],
    ),
    _ConflictRule(
      id: 'copper_elbow_plumbing_vs_hvac',
      ambiguousLine: '3/4 COPPER 90',
      family: 'copper elbow',
      competingTrades: ['Plumbing', 'HVAC'],
      requiredPositiveEvidence: [
        'type l/type m water supply',
        'acr refrigerant',
      ],
      requiredNegativeEvidence: ['copper 90 alone is dangerous'],
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final families = <String>{};
    final competingTrades = <String>{};

    for (final rule in _rules) {
      families.add(rule.family);
      competingTrades.addAll(rule.competingTrades);
      if (rule.competingTrades.length < 2) {
        failures.add(_failure(rule, 'missing_competing_trades'));
      }
      if (rule.requiredPositiveEvidence.length < 2) {
        failures.add(_failure(rule, 'missing_positive_evidence'));
      }
      if (rule.requiredNegativeEvidence.isEmpty) {
        failures.add(_failure(rule, 'missing_negative_evidence'));
      }
      final candidate = _candidateFor(rule);
      if (!candidate.requiresReview ||
          candidate.suggestedInventoryAction !=
              WorkSupplyParserSuggestedAction.reviewOnly) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'conflict_autosave_risk:${rule.id}',
            message:
                'Conflict graph candidate became auto-accepted or non-review.',
            expected: 'review-only ambiguous candidate',
            actual:
                'requiresReview=${candidate.requiresReview}; action=${candidate.suggestedInventoryAction.name}',
            suggestedFix:
                'Keep conflict families review-only until stronger trade, merchant, SKU, or job context exists.',
            metadata: const {'triageCategory': QaFailureTriage.reviewSafety},
          ),
        );
      }
      final candidateTrades = {
        for (final match in candidate.possibleMatches) match.detectedTrade,
      };
      for (final trade in rule.competingTrades) {
        if (candidateTrades.contains(trade)) continue;
        failures.add(
          QaFailure(
            suite: name,
            id: 'conflict_missing_ranked_trade:${rule.id}:$trade',
            message:
                'Conflict graph candidate hid a realistic competing trade.',
            expected: rule.competingTrades.join(', '),
            actual: candidateTrades.join(', '),
            suggestedFix:
                'Preserve ranked alternatives for overlapping materials instead of collapsing to one trade.',
            metadata: const {'triageCategory': QaFailureTriage.conflict},
          ),
        );
      }
      if (!candidate.warnings.contains('conflict_graph')) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'conflict_warning_missing:${rule.id}',
            message: 'Conflict graph candidate did not preserve a warning.',
            expected: 'conflict_graph warning',
            actual: candidate.warnings.join(', '),
            suggestedFix:
                'Carry conflict warnings into parser review output so users know why confirmation is required.',
            metadata: const {'triageCategory': QaFailureTriage.conflict},
          ),
        );
      }
    }

    return timer.finish(
      suite: name,
      checked: _rules.length * 7,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'ruleCount': _rules.length,
        'families': families.toList()..sort(),
        'competingTrades': competingTrades.toList()..sort(),
      },
    );
  }

  QaFailure _failure(_ConflictRule rule, String id) {
    return QaFailure(
      suite: name,
      id: '$id:${rule.id}',
      message: 'Conflict graph rule is missing required metadata.',
      expected: 'competing trades plus positive and negative evidence',
      actual: rule.family,
      suggestedFix:
          'Document what separates this ambiguous receipt family before parser rules rely on it.',
      metadata: const {'triageCategory': QaFailureTriage.conflict},
    );
  }

  WorkSupplyParserCandidate _candidateFor(_ConflictRule rule) {
    final baseScore = .72;
    return WorkSupplyParserCandidate(
      rawLine: rule.ambiguousLine,
      cleanedLine: rule.ambiguousLine.toLowerCase(),
      reviewStatus: 'multiplePossibleMatches',
      suggestedInventoryAction: WorkSupplyParserSuggestedAction.reviewOnly,
      warnings: const ['conflict_graph'],
      missingFields: const ['strongTradeEvidence'],
      confidenceScore: baseScore,
      confidenceReasons: [
        'ambiguous ${rule.family}',
        'requires stronger evidence',
      ],
      possibleMatches: [
        for (var i = 0; i < rule.competingTrades.length; i += 1)
          WorkSupplyParserPossibleMatch(
            canonicalItemId:
                '${rule.competingTrades[i].toUpperCase()}-${rule.family.toUpperCase().replaceAll(' ', '-')}',
            canonicalItemName: '${rule.competingTrades[i]} ${rule.family}',
            detectedTrade: rule.competingTrades[i],
            confidenceScore: baseScore - (i * .02),
            confidenceReasons: [
              rule.requiredPositiveEvidence[i %
                  rule.requiredPositiveEvidence.length],
            ],
            rejectedReasons: rule.requiredNegativeEvidence,
          ),
      ],
    );
  }
}

class _ConflictRule {
  const _ConflictRule({
    required this.id,
    required this.ambiguousLine,
    required this.family,
    required this.competingTrades,
    required this.requiredPositiveEvidence,
    required this.requiredNegativeEvidence,
  });

  final String id;
  final String ambiguousLine;
  final String family;
  final List<String> competingTrades;
  final List<String> requiredPositiveEvidence;
  final List<String> requiredNegativeEvidence;
}
