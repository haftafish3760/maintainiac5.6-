import 'package:maintaniac/screens/work_supplies/data/work_supply_parser_candidate_models.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserEstimateSectionSuite extends QaSuite {
  const WorkSupplyParserEstimateSectionSuite()
    : super('inventory.estimate_section_ranking');

  static const _cases = [
    _EstimateSectionCase(
      id: 'plumbing_section_prefers_plumbing_pvc',
      line: 'PVC 90 3/4',
      estimateSectionTrade: 'Plumbing',
      expectedTopTrade: 'Plumbing',
    ),
    _EstimateSectionCase(
      id: 'electrical_section_prefers_conduit_pvc',
      line: 'PVC 90 3/4',
      estimateSectionTrade: 'Electrical',
      expectedTopTrade: 'Electrical',
    ),
    _EstimateSectionCase(
      id: 'hvac_section_prefers_condensate_pvc',
      line: 'PVC 90 3/4',
      estimateSectionTrade: 'HVAC',
      expectedTopTrade: 'HVAC',
    ),
    _EstimateSectionCase(
      id: 'unknown_section_keeps_base_confidence_order',
      line: 'PVC 90 3/4',
      estimateSectionTrade: '',
      expectedTopTrade: 'Plumbing',
    ),
    _EstimateSectionCase(
      id: 'plumbing_section_prefers_soft_copper_tubing',
      line: '3/4 COPPER TUBING',
      estimateSectionTrade: 'Plumbing',
      expectedTopTrade: 'Plumbing',
    ),
    _EstimateSectionCase(
      id: 'hvac_section_prefers_acr_copper_tubing',
      line: '3/4 COPPER TUBING',
      estimateSectionTrade: 'HVAC',
      expectedTopTrade: 'HVAC',
    ),
    _EstimateSectionCase(
      id: 'electrical_section_prefers_conduit_coupling',
      line: '3/4 PVC CPLG',
      estimateSectionTrade: 'Electrical',
      expectedTopTrade: 'Electrical',
    ),
    _EstimateSectionCase(
      id: 'hvac_section_prefers_condensate_coupling',
      line: '3/4 PVC CPLG',
      estimateSectionTrade: 'HVAC',
      expectedTopTrade: 'HVAC',
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    for (final testCase in _cases) {
      final candidate = _candidateFor(testCase.line);
      final ranked = candidate.rankedPossibleMatchesForEstimateSection(
        testCase.estimateSectionTrade,
      );
      final actualTopTrade = ranked.isEmpty
          ? 'none'
          : ranked.first.detectedTrade;
      if (actualTopTrade != testCase.expectedTopTrade) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'wrong_estimate_section_rank:${testCase.id}',
            message:
                'Estimate section context did not rank the expected trade candidate first.',
            expected: testCase.expectedTopTrade,
            actual: actualTopTrade,
            suggestedFix:
                'Let active estimate/job trade context influence ranking without overriding parser ambiguity.',
            metadata: {
              'triageCategory': QaFailureTriage.parserEngine,
              'line': testCase.line,
              'estimateSectionTrade': testCase.estimateSectionTrade,
            },
          ),
        );
      }
      if (!candidate.requiresReview ||
          candidate.suggestedInventoryAction !=
              WorkSupplyParserSuggestedAction.reviewOnly) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'estimate_section_autosave_risk:${testCase.id}',
            message:
                'Estimate section context must not turn ambiguous parser output into an auto-save action.',
            expected:
                'requiresReview=true and suggestedInventoryAction=reviewOnly',
            actual:
                'requiresReview=${candidate.requiresReview}, suggestedInventoryAction=${candidate.suggestedInventoryAction.name}',
            suggestedFix:
                'Keep mixed-trade receipt matches review-only until the user confirms the material.',
            metadata: {
              'triageCategory': QaFailureTriage.reviewSafety,
              'line': testCase.line,
            },
          ),
        );
      }
      if (ranked.length < 3) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'estimate_section_hidden_ambiguity:${testCase.id}',
            message:
                'Estimate section ranking hid realistic mixed-trade alternatives.',
            expected: 'at least Plumbing, Electrical, and HVAC alternatives',
            actual: '${ranked.length} alternatives',
            suggestedFix:
                'Preserve ranked possible matches for mixed-trade jobs and remodel estimates.',
            metadata: {
              'triageCategory': QaFailureTriage.parserEngine,
              'line': testCase.line,
            },
          ),
        );
      }
    }

    return timer.finish(
      suite: name,
      checked: _cases.length * 3,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'caseCount': _cases.length,
        'contexts': [
          for (final testCase in _cases)
            testCase.estimateSectionTrade.isEmpty
                ? 'unknown'
                : testCase.estimateSectionTrade,
        ],
        'guardrails': const [
          'context changes ranking',
          'ambiguity remains visible',
          'no auto-save from section context',
        ],
      },
    );
  }

  WorkSupplyParserCandidate _candidateFor(String line) {
    if (line == '3/4 COPPER TUBING') {
      return WorkSupplyParserCandidate(
        rawLine: line,
        cleanedLine: line.toLowerCase(),
        reviewStatus: 'multiplePossibleMatches',
        suggestedInventoryAction: WorkSupplyParserSuggestedAction.reviewOnly,
        warnings: const ['mixed_trade_copper_tubing_ambiguity'],
        missingFields: const ['tradeContext'],
        possibleMatches: const [
          WorkSupplyParserPossibleMatch(
            canonicalItemId: 'PLUMBING-COPPER-TUBING-3-4',
            canonicalItemName: '3/4 in Soft Copper Tubing',
            detectedTrade: 'Plumbing',
            confidenceScore: .73,
            confidenceReasons: ['copper material', 'tubing token', '3/4 size'],
          ),
          WorkSupplyParserPossibleMatch(
            canonicalItemId: 'HVAC-ACR-COPPER-TUBING-3-4',
            canonicalItemName: '3/4 in ACR Copper Tubing',
            detectedTrade: 'HVAC',
            confidenceScore: .72,
            confidenceReasons: ['copper material', 'tubing token', '3/4 size'],
          ),
          WorkSupplyParserPossibleMatch(
            canonicalItemId: 'ELECTRICAL-COPPER-GROUND-3-4',
            canonicalItemName: '3/4 in Copper Bonding Stock',
            detectedTrade: 'Electrical',
            confidenceScore: .41,
            confidenceReasons: ['copper material', 'shared stock wording'],
          ),
        ],
        confidenceScore: .73,
        confidenceReasons: const ['3/4 copper tubing is shared by multiple lanes'],
      );
    }

    return WorkSupplyParserCandidate(
      rawLine: line,
      cleanedLine: line.toLowerCase(),
      reviewStatus: 'multiplePossibleMatches',
      suggestedInventoryAction: WorkSupplyParserSuggestedAction.reviewOnly,
      warnings: const ['mixed_trade_pvc_ambiguity'],
      missingFields: const ['connectionType'],
      possibleMatches: const [
        WorkSupplyParserPossibleMatch(
          canonicalItemId: 'PLUMBING-PVC-ELBOW-3-4',
          canonicalItemName: '3/4 in PVC pressure elbow',
          detectedTrade: 'Plumbing',
          confidenceScore: .74,
          confidenceReasons: ['pvc material', 'elbow token', '3/4 size'],
        ),
        WorkSupplyParserPossibleMatch(
          canonicalItemId: 'ELECTRICAL-PVC-CONDUIT-ELBOW-3-4',
          canonicalItemName: '3/4 in PVC conduit elbow',
          detectedTrade: 'Electrical',
          confidenceScore: .70,
          confidenceReasons: ['pvc material', 'elbow token', '3/4 size'],
        ),
        WorkSupplyParserPossibleMatch(
          canonicalItemId: 'HVAC-PVC-CONDENSATE-ELBOW-3-4',
          canonicalItemName: '3/4 in PVC condensate elbow',
          detectedTrade: 'HVAC',
          confidenceScore: .69,
          confidenceReasons: ['pvc material', 'elbow token', '3/4 size'],
        ),
      ],
      confidenceScore: .74,
      confidenceReasons: const ['PVC 90 is shared by multiple trades'],
    );
  }
}

class _EstimateSectionCase {
  const _EstimateSectionCase({
    required this.id,
    required this.line,
    required this.estimateSectionTrade,
    required this.expectedTopTrade,
  });

  final String id;
  final String line;
  final String estimateSectionTrade;
  final String expectedTopTrade;
}
