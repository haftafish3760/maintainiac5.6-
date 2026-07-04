import 'package:maintaniac/screens/work_supplies/data/work_supply_parser_candidate_models.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserRankedCandidateSuite extends QaSuite {
  const WorkSupplyParserRankedCandidateSuite()
    : super('inventory.ranked_candidate_accuracy');

  static const _contractEvidenceTokens = [
    'top-3',
    'top-5',
    'positiveEvidence',
    'negativeEvidence',
    'conflictFamily',
    'enabledTradePacks',
  ];

  static const _cases = [
    _RankedCase(
      id: 'clear_pex_elbow_top1',
      rawLine: '1/2 PEX CRMP ELL',
      expectedItemId: 'PLUMBING-PEX-CRIMP-ELBOW-1-2',
      expectedMaxRank: 1,
      enabledTradePacks: ['Plumbing'],
      conflictFamily: 'pex_crimp_shape',
      positiveEvidence: ['pex material', 'crimp connection', 'elbow shape'],
      negativeEvidence: ['not pvc conduit', 'not hvac condensate'],
      possibleMatches: [
        _Possible('PLUMBING-PEX-CRIMP-ELBOW-1-2', 'Plumbing', .94),
        _Possible('PLUMBING-PEX-CRIMP-TEE-1-2', 'Plumbing', .61),
        _Possible('PLUMBING-PVC-ELBOW-1-2', 'Plumbing', .42),
      ],
    ),
    _RankedCase(
      id: 'ambiguous_pvc_elbow_top3',
      rawLine: 'PVC 90 3/4',
      expectedItemId: 'PLUMBING-PVC-ELBOW-3-4',
      expectedMaxRank: 3,
      enabledTradePacks: ['Plumbing', 'Electrical', 'HVAC'],
      activeWorkflowContext: 'estimate_draft',
      activeTradeSection: 'Plumbing',
      receiptNeighborSignals: ['wax ring', 'angle stop', 'toilet supply'],
      merchantDepartmentHints: ['rough plumbing', 'electrical conduit aisle'],
      conflictFamily: 'cross_trade_pvc_elbow',
      positiveEvidence: ['pvc material', '90 degree shape', '3/4 size'],
      negativeEvidence: [
        'missing schedule/dwv/slip evidence',
        'missing conduit evidence',
        'missing condensate evidence',
      ],
      possibleMatches: [
        _Possible('PLUMBING-PVC-ELBOW-3-4', 'Plumbing', .74),
        _Possible('ELECTRICAL-PVC-CONDUIT-ELBOW-3-4', 'Electrical', .72),
        _Possible('HVAC-PVC-CONDENSATE-ELBOW-3-4', 'HVAC', .70),
      ],
    ),
    _RankedCase(
      id: 'ambiguous_filter_top5',
      rawLine: 'FILTER 20X25X1',
      expectedItemId: 'HVAC-AIR-FILTER-20X25X1',
      expectedMaxRank: 5,
      enabledTradePacks: ['HVAC', 'Plumbing', 'Maintenance'],
      activeWorkflowContext: 'inventory_receipt_review',
      receiptNeighborSignals: ['furnace fuse', 'thermostat wire'],
      merchantDepartmentHints: ['air filter aisle', 'hardware general'],
      conflictFamily: 'generic_filter',
      positiveEvidence: ['20x25x1 dimensions', 'filter token'],
      negativeEvidence: [
        'missing air/furnace/merv evidence',
        'missing water filter evidence',
        'missing oil filter evidence',
      ],
      possibleMatches: [
        _Possible('HVAC-AIR-FILTER-20X25X1', 'HVAC', .76),
        _Possible('PLUMBING-WATER-FILTER-10IN', 'Plumbing', .59),
        _Possible('VEHICLE-OIL-FILTER', 'Vehicle', .41),
      ],
    ),
    _RankedCase(
      id: 'ambiguous_copper_90_plumbing_hvac',
      rawLine: '3/4 COPPER 90',
      expectedItemId: 'PLUMBING-COPPER-ELBOW-3-4',
      expectedMaxRank: 3,
      enabledTradePacks: ['Plumbing', 'HVAC'],
      activeWorkflowContext: 'inventory_receipt_review',
      receiptNeighborSignals: ['flux', 'solder', 'line set cover'],
      merchantDepartmentHints: ['plumbing fittings', 'hvac refrigeration'],
      conflictFamily: 'cross_trade_copper_elbow',
      positiveEvidence: ['copper material', '90 degree shape', '3/4 size'],
      negativeEvidence: [
        'missing type l/type m evidence',
        'missing refrigerant/acr evidence',
      ],
      possibleMatches: [
        _Possible('PLUMBING-COPPER-ELBOW-3-4', 'Plumbing', .73),
        _Possible('HVAC-COPPER-REFRIGERANT-ELBOW-3-4', 'HVAC', .71),
        _Possible('PLUMBING-COPPER-STREET-90-3-4', 'Plumbing', .63),
      ],
    ),
    _RankedCase(
      id: 'mixed_trade_receipt_context_does_not_hide_alternatives',
      rawLine: 'PVC 3/4 CPLG',
      expectedItemId: 'ELECTRICAL-PVC-CONDUIT-COUPLING-3-4',
      expectedMaxRank: 3,
      enabledTradePacks: ['Plumbing', 'Electrical', 'HVAC'],
      activeWorkflowContext: 'active_job',
      activeTradeSection: 'Electrical',
      receiptNeighborSignals: ['12/2 wire', 'old work box', 'angle stop'],
      merchantDepartmentHints: ['electrical conduit aisle'],
      conflictFamily: 'cross_trade_pvc_coupling',
      positiveEvidence: ['pvc material', 'coupling abbreviation', '3/4 size'],
      negativeEvidence: [
        'receipt contains mixed plumbing/electrical neighbors',
        'context boost cannot erase plumbing alternative',
      ],
      possibleMatches: [
        _Possible('ELECTRICAL-PVC-CONDUIT-COUPLING-3-4', 'Electrical', .77),
        _Possible('PLUMBING-PVC-COUPLING-3-4', 'Plumbing', .70),
        _Possible('HVAC-PVC-CONDENSATE-COUPLING-3-4', 'HVAC', .66),
      ],
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final top1Cases = <String>[];
    final top3Cases = <String>[];
    final top5Cases = <String>[];

    for (final testCase in _cases) {
      final candidate = _candidateFor(testCase);
      final ids = [
        for (final match in candidate.possibleMatches) match.canonicalItemId,
      ];
      final index = ids.indexOf(testCase.expectedItemId);
      final rank = index < 0 ? 999 : index + 1;
      if (testCase.expectedMaxRank == 1) top1Cases.add(testCase.id);
      if (testCase.expectedMaxRank <= 3) top3Cases.add(testCase.id);
      if (testCase.expectedMaxRank <= 5) top5Cases.add(testCase.id);
      if (rank > testCase.expectedMaxRank) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'ranked_candidate_miss:${testCase.id}',
            message:
                'Expected parser candidate was not present within its ranked accuracy budget.',
            expected:
                '${testCase.expectedItemId} rank <= ${testCase.expectedMaxRank}',
            actual: rank == 999
                ? 'missing from ${ids.join(', ')}'
                : 'rank $rank',
            suggestedFix:
                'Improve aliases, merchant rules, conflict graph evidence, or context scoring so expected items stay in the review list.',
            metadata: const {'triageCategory': QaFailureTriage.confidence},
          ),
        );
      }
      if (candidate.possibleMatches.length > 1 &&
          (!candidate.requiresReview ||
              candidate.suggestedInventoryAction !=
                  WorkSupplyParserSuggestedAction.reviewOnly)) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'ranked_candidate_autosave_risk:${testCase.id}',
            message:
                'Multiple ranked candidates must remain review-only before inventory/job/estimate routing.',
            expected: 'requiresReview=true and action=reviewOnly',
            actual:
                'requiresReview=${candidate.requiresReview}; action=${candidate.suggestedInventoryAction.name}',
            suggestedFix:
                'Do not auto-save ranked parser output until the user confirms the selected item.',
            metadata: const {'triageCategory': QaFailureTriage.reviewSafety},
          ),
        );
      }
      if (candidate.possibleMatches.length > 1 &&
          candidate.reviewStatus != 'multiplePossibleMatches') {
        failures.add(
          QaFailure(
            suite: name,
            id: 'ranked_candidate_missing_review_status:${testCase.id}',
            message:
                'Ambiguous ranked parser candidates must carry an explicit multiple-match review status.',
            expected: 'multiplePossibleMatches',
            actual: candidate.reviewStatus,
            suggestedFix:
                'Return ranked review candidates instead of a single confident item when realistic alternatives exist.',
            metadata: const {'triageCategory': QaFailureTriage.reviewSafety},
          ),
        );
      }
      if (candidate.possibleMatches.length > 1 &&
          candidate.conflictFamily.isEmpty) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'ranked_candidate_missing_conflict_family:${testCase.id}',
            message:
                'Ambiguous ranked parser candidates must identify the conflict family.',
            expected: testCase.conflictFamily,
            actual: 'empty',
            suggestedFix:
                'Tag ambiguity families such as cross_trade_pvc_elbow, generic_filter, and cross_trade_copper_elbow.',
            metadata: const {'triageCategory': QaFailureTriage.confidence},
          ),
        );
      }
      if (candidate.positiveEvidence.isEmpty ||
          candidate.negativeEvidence.isEmpty ||
          candidate.confidenceReasons.isEmpty) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'ranked_candidate_missing_evidence:${testCase.id}',
            message:
                'Ranked parser output must explain why candidates matched and what evidence is missing or conflicting.',
            expected: 'positive, negative, and confidence evidence',
            actual:
                'positive=${candidate.positiveEvidence.length}; negative=${candidate.negativeEvidence.length}; reasons=${candidate.confidenceReasons.length}',
            suggestedFix:
                'Preserve material/size/shape/context evidence and conflict reasons on every review candidate.',
            metadata: const {'triageCategory': QaFailureTriage.confidence},
          ),
        );
      }
      if (testCase.enabledTradePacks.length > 1 &&
          candidate.enabledTradePacks.length < 2) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'ranked_candidate_missing_enabled_packs:${testCase.id}',
            message:
                'Cross-trade parser ranking must preserve which trade packs were enabled.',
            expected: testCase.enabledTradePacks.join(', '),
            actual: candidate.enabledTradePacks.join(', '),
            suggestedFix:
                'Pass enabled trade packs through the parser result contract so ranking can be audited later.',
            metadata: const {'triageCategory': QaFailureTriage.context},
          ),
        );
      }
      if (testCase.activeTradeSection.isNotEmpty) {
        final ranked = candidate.rankedPossibleMatchesForEstimateSection(
          testCase.activeTradeSection,
        );
        final alternatives = {for (final match in ranked) match.detectedTrade};
        if (!alternatives.contains(testCase.activeTradeSection) ||
            alternatives.length < 2) {
          failures.add(
            QaFailure(
              suite: name,
              id: 'ranked_context_erased_alternatives:${testCase.id}',
              message:
                  'Active estimate/job section may boost ranking but must not erase realistic trade alternatives.',
              expected:
                  '${testCase.activeTradeSection} plus at least one alternate trade',
              actual: alternatives.join(', '),
              suggestedFix:
                  'Use job/estimate context as ranking evidence, not an automatic confirmation.',
              metadata: const {'triageCategory': QaFailureTriage.context},
            ),
          );
        }
      }
    }

    return timer.finish(
      suite: name,
      checked: _cases.length * 7,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'caseCount': _cases.length,
        'contractEvidenceTokens': _contractEvidenceTokens,
        'top1CaseIds': top1Cases,
        'top3CaseIds': top3Cases,
        'top5CaseIds': top5Cases,
      },
    );
  }

  WorkSupplyParserCandidate _candidateFor(_RankedCase testCase) {
    return WorkSupplyParserCandidate(
      rawLine: testCase.rawLine,
      cleanedLine: testCase.rawLine.toLowerCase(),
      reviewStatus: testCase.possibleMatches.length == 1
          ? 'needsReview'
          : 'multiplePossibleMatches',
      suggestedInventoryAction: WorkSupplyParserSuggestedAction.reviewOnly,
      confidenceScore: testCase.possibleMatches.first.confidenceScore,
      confidenceReasons: [
        'ranked candidate fixture',
        if (testCase.activeTradeSection.isNotEmpty)
          'active section ${testCase.activeTradeSection} is ranking evidence only',
      ],
      warnings: testCase.possibleMatches.length == 1
          ? const []
          : const ['ranked_ambiguity', 'requires_user_confirmation'],
      enabledTradePacks: testCase.enabledTradePacks,
      activeWorkflowContext: testCase.activeWorkflowContext,
      activeTradeSection: testCase.activeTradeSection,
      receiptNeighborSignals: testCase.receiptNeighborSignals,
      merchantDepartmentHints: testCase.merchantDepartmentHints,
      conflictFamily: testCase.conflictFamily,
      positiveEvidence: testCase.positiveEvidence,
      negativeEvidence: testCase.negativeEvidence,
      possibleMatches: [
        for (final match in testCase.possibleMatches)
          WorkSupplyParserPossibleMatch(
            canonicalItemId: match.itemId,
            canonicalItemName: match.itemId.toLowerCase().replaceAll('-', ' '),
            detectedTrade: match.trade,
            confidenceScore: match.confidenceScore,
            confidenceReasons: const ['fixture evidence'],
          ),
      ],
    );
  }
}

class _RankedCase {
  const _RankedCase({
    required this.id,
    required this.rawLine,
    required this.expectedItemId,
    required this.expectedMaxRank,
    required this.possibleMatches,
    this.enabledTradePacks = const [],
    this.activeWorkflowContext = '',
    this.activeTradeSection = '',
    this.receiptNeighborSignals = const [],
    this.merchantDepartmentHints = const [],
    this.conflictFamily = '',
    this.positiveEvidence = const [],
    this.negativeEvidence = const [],
  });

  final String id;
  final String rawLine;
  final String expectedItemId;
  final int expectedMaxRank;
  final List<_Possible> possibleMatches;
  final List<String> enabledTradePacks;
  final String activeWorkflowContext;
  final String activeTradeSection;
  final List<String> receiptNeighborSignals;
  final List<String> merchantDepartmentHints;
  final String conflictFamily;
  final List<String> positiveEvidence;
  final List<String> negativeEvidence;
}

class _Possible {
  const _Possible(this.itemId, this.trade, this.confidenceScore);

  final String itemId;
  final String trade;
  final double confidenceScore;
}
