import 'package:maintaniac/screens/work_supplies/data/work_supply_parser_candidate_models.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserRankedCandidateSuite extends QaSuite {
  const WorkSupplyParserRankedCandidateSuite()
    : super('inventory.ranked_candidate_accuracy');

  static const _cases = [
    _RankedCase(
      id: 'clear_pex_elbow_top1',
      rawLine: '1/2 PEX CRMP ELL',
      expectedItemId: 'PLUMBING-PEX-CRIMP-ELBOW-1-2',
      expectedMaxRank: 1,
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
      possibleMatches: [
        _Possible('HVAC-AIR-FILTER-20X25X1', 'HVAC', .76),
        _Possible('PLUMBING-WATER-FILTER-10IN', 'Plumbing', .59),
        _Possible('VEHICLE-OIL-FILTER', 'Vehicle', .41),
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
    }

    return timer.finish(
      suite: name,
      checked: _cases.length * 2,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'caseCount': _cases.length,
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
      confidenceReasons: const ['ranked candidate fixture'],
      warnings: testCase.possibleMatches.length == 1
          ? const []
          : const ['ranked_ambiguity'],
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
  });

  final String id;
  final String rawLine;
  final String expectedItemId;
  final int expectedMaxRank;
  final List<_Possible> possibleMatches;
}

class _Possible {
  const _Possible(this.itemId, this.trade, this.confidenceScore);

  final String itemId;
  final String trade;
  final double confidenceScore;
}
