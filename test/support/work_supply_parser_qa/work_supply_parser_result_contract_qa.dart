import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_parser_candidate_models.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserResultContractSuite extends QaSuite {
  const WorkSupplyParserResultContractSuite()
    : super('inventory.result_contract');

  static const _scannedFiles = [
    'lib/screens/work_supplies/data/work_supply_receipt_parser.dart',
    'lib/screens/work_supplies/data/work_supply_inventory_receipt_models.dart',
    'lib/screens/work_supplies/data/work_supply_parser_candidate_models.dart',
    'lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart',
    'lib/shared/receipts/receipt_line_models.dart',
    'docs/inventory_parser_qa_harness_plan.md',
  ];

  static const _requiredFields = <_ContractField>[
    _ContractField('rawLine', ['rawLine', 'rawText', 'rawReceiptText']),
    _ContractField('cleanedLine', ['cleanedLine', 'normalizedLine']),
    _ContractField('merchantGuess', ['merchantGuess', 'merchantName']),
    _ContractField('detectedTrade', ['detectedTrade', 'trade']),
    _ContractField('detectedCategory', ['detectedCategory', 'category']),
    _ContractField('detectedSubcategory', ['detectedSubcategory']),
    _ContractField('detectedSystem', ['detectedSystem', 'system']),
    _ContractField('detectedItemType', ['detectedItemType', 'itemType']),
    _ContractField('canonicalItemId', [
      'canonicalItemId',
      'catalogItemId',
      'inventoryItemId',
    ]),
    _ContractField('canonicalItemName', [
      'canonicalItemName',
      'displayName',
      'description',
    ]),
    _ContractField('material', ['material']),
    _ContractField('composition', ['composition']),
    _ContractField('size', ['size']),
    _ContractField('dimensions', ['dimensions']),
    _ContractField('length', ['length']),
    _ContractField('width', ['width']),
    _ContractField('height', ['height']),
    _ContractField('diameter', ['diameter']),
    _ContractField('schedule', ['schedule']),
    _ContractField('gauge', ['gauge']),
    _ContractField('rating', ['rating']),
    _ContractField('color', ['color']),
    _ContractField('finish', ['finish']),
    _ContractField('variant', ['variant']),
    _ContractField('quantityPurchased', ['quantityPurchased', 'quantity']),
    _ContractField('packageQuantity', ['packageQuantity', 'unitsPerPackage']),
    _ContractField('stockQuantityCandidate', [
      'stockQuantityCandidate',
      'totalUnits',
    ]),
    _ContractField('unit', ['unit']),
    _ContractField('unitPrice', ['unitPrice', 'unitCost']),
    _ContractField('lineTotal', ['lineTotal', 'subtotal']),
    _ContractField('matchedAliases', ['matchedAliases', 'matchedTerms']),
    _ContractField('matchedMerchantRules', ['matchedMerchantRules']),
    _ContractField('matchedParserPack', ['matchedParserPack']),
    _ContractField('enabledTradePacks', ['enabledTradePacks']),
    _ContractField('activeWorkflowContext', ['activeWorkflowContext']),
    _ContractField('activeTradeSection', ['activeTradeSection']),
    _ContractField('receiptNeighborSignals', ['receiptNeighborSignals']),
    _ContractField('merchantDepartmentHints', ['merchantDepartmentHints']),
    _ContractField('conflictFamily', ['conflictFamily']),
    _ContractField('positiveEvidence', ['positiveEvidence']),
    _ContractField('negativeEvidence', ['negativeEvidence']),
    _ContractField('possibleMatches', ['possibleMatches']),
    _ContractField('confidenceScore', ['confidenceScore', 'confidence']),
    _ContractField('confidenceReasons', [
      'confidenceReasons',
      'parserReviewReason',
    ]),
    _ContractField('warnings', ['warnings', 'warning']),
    _ContractField('missingFields', ['missingFields']),
    _ContractField('reviewStatus', ['reviewStatus', 'parserReviewLabel']),
    _ContractField('suggestedInventoryAction', [
      'suggestedInventoryAction',
      'reviewAction',
    ]),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _scannedFiles
        .map((path) {
          final file = File(path);
          if (!file.existsSync()) {
            failures.add(
              QaFailure(
                suite: name,
                id: 'missing_contract_scan_file:$path',
                message: 'Parser result contract scan file is missing.',
                expected: path,
                actual: 'not found',
                suggestedFix:
                    'Update this suite when parser result model files move.',
                metadata: const {'triageCategory': QaFailureTriage.schema},
              ),
            );
            return '';
          }
          return file.readAsStringSync();
        })
        .join('\n');

    final present = <String>[];
    final missing = <String>[];
    for (final field in _requiredFields) {
      if (field.isPresentIn(source)) {
        present.add(field.name);
        continue;
      }
      missing.add(field.name);
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_result_field:${field.name}',
          message:
              'Parser result contract is missing a required output field or equivalent.',
          severity: QaSeverity.warning,
          expected: field.name,
          actual: 'not found',
          suggestedFix:
              'Add this field or an explicitly mapped equivalent before release-gating structured parser candidates.',
          metadata: const {'triageCategory': QaFailureTriage.parserEngine},
        ),
      );
    }
    final candidateFailures = _candidateRoundTripFailures();
    failures.addAll(candidateFailures);

    return timer.finish(
      suite: name,
      checked: _requiredFields.length + _scannedFiles.length + 9,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'requiredFieldCount': _requiredFields.length,
        'presentFieldCount': present.length,
        'missingFieldCount': missing.length,
        'roundTripCheckCount': 9,
        'roundTripFailureCount': candidateFailures.length,
        'presentFields': present,
        'missingFields': missing,
      },
    );
  }

  List<QaFailure> _candidateRoundTripFailures() {
    final candidate = WorkSupplyParserCandidate(
      rawLine: 'PVC EL 3/4',
      cleanedLine: 'pvc el 3/4',
      merchantGuess: 'local hardware',
      detectedTrade: 'Plumbing',
      detectedCategory: 'Pipe and Fittings',
      detectedSubcategory: 'PVC',
      detectedSystem: 'Pressure Pipe',
      detectedItemType: 'Elbow',
      canonicalItemId: 'PLUMBING-PVC-ELBOW-3-4',
      canonicalItemName: '3/4 in PVC elbow',
      material: 'PVC',
      size: '3/4 in',
      matchedAliases: const ['PVC EL 3/4'],
      matchedMerchantRules: const ['generic_pvc_abbreviation'],
      matchedParserPack: 'us-en-residential-plumbing-core',
      enabledTradePacks: const ['Plumbing', 'Electrical', 'HVAC'],
      activeWorkflowContext: 'mixed_remodel_estimate',
      activeTradeSection: 'Plumbing',
      receiptNeighborSignals: const [
        '12/2 wire also present',
        'condensate fitting also present',
      ],
      merchantDepartmentHints: const ['hardware aisle unknown'],
      conflictFamily: 'pvc_elbow_cross_trade',
      positiveEvidence: const ['pvc material', '3/4 size'],
      negativeEvidence: const [
        'missing schedule evidence',
        'missing conduit evidence',
        'mixed receipt neighbor evidence',
      ],
      possibleMatches: const [
        WorkSupplyParserPossibleMatch(
          canonicalItemId: 'PLUMBING-PVC-ELBOW-3-4',
          canonicalItemName: '3/4 in PVC elbow',
          detectedTrade: 'Plumbing',
          confidenceScore: .74,
          confidenceReasons: ['size matched', 'pvc material matched'],
        ),
        WorkSupplyParserPossibleMatch(
          canonicalItemId: 'ELECTRICAL-PVC-CONDUIT-ELBOW-3-4',
          canonicalItemName: '3/4 in PVC conduit elbow',
          detectedTrade: 'Electrical',
          confidenceScore: .66,
          confidenceReasons: ['pvc material matched'],
          rejectedReasons: ['missing conduit token'],
        ),
      ],
      confidenceScore: .74,
      confidenceReasons: const ['ambiguous PVC elbow wording'],
      warnings: const ['ambiguous_trade_context'],
      missingFields: const ['connectionType'],
      reviewStatus: 'multiplePossibleMatches',
      suggestedInventoryAction: WorkSupplyParserSuggestedAction.reviewOnly,
    );
    final restored = WorkSupplyParserCandidate.fromMap(candidate.toMap());
    final expectations = <_RoundTripExpectation>[
      _RoundTripExpectation(
        'raw_line_preserved',
        restored.rawLine == candidate.rawLine,
      ),
      _RoundTripExpectation(
        'possible_matches_ranked',
        restored.possibleMatches.length == 2 &&
            restored.possibleMatches.first.confidenceScore >
                restored.possibleMatches.last.confidenceScore,
      ),
      _RoundTripExpectation(
        'alternate_rejected_reason_preserved',
        restored.possibleMatches.last.rejectedReasons.contains(
          'missing conduit token',
        ),
      ),
      _RoundTripExpectation(
        'warnings_preserved',
        restored.warnings.contains('ambiguous_trade_context'),
      ),
      _RoundTripExpectation(
        'missing_fields_preserved',
        restored.missingFields.contains('connectionType'),
      ),
      _RoundTripExpectation(
        'confidence_reasons_preserved',
        restored.confidenceReasons.contains('ambiguous PVC elbow wording'),
      ),
      _RoundTripExpectation(
        'merchant_rules_preserved',
        restored.matchedMerchantRules.contains('generic_pvc_abbreviation'),
      ),
      _RoundTripExpectation(
        'enabled_trade_packs_preserved',
        restored.enabledTradePacks.contains('Electrical') &&
            restored.enabledTradePacks.contains('HVAC'),
      ),
      _RoundTripExpectation(
        'workflow_context_preserved',
        restored.activeWorkflowContext == 'mixed_remodel_estimate',
      ),
      _RoundTripExpectation(
        'active_trade_section_preserved',
        restored.activeTradeSection == 'Plumbing',
      ),
      _RoundTripExpectation(
        'receipt_neighbors_preserved',
        restored.receiptNeighborSignals.contains('12/2 wire also present'),
      ),
      _RoundTripExpectation(
        'merchant_hints_preserved',
        restored.merchantDepartmentHints.contains('hardware aisle unknown'),
      ),
      _RoundTripExpectation(
        'conflict_family_preserved',
        restored.conflictFamily == 'pvc_elbow_cross_trade',
      ),
      _RoundTripExpectation(
        'positive_evidence_preserved',
        restored.positiveEvidence.contains('pvc material'),
      ),
      _RoundTripExpectation(
        'negative_evidence_preserved',
        restored.negativeEvidence.contains('missing conduit evidence'),
      ),
      _RoundTripExpectation(
        'suggested_action_preserved',
        restored.suggestedInventoryAction ==
            WorkSupplyParserSuggestedAction.reviewOnly,
      ),
      _RoundTripExpectation('requires_review_guarded', restored.requiresReview),
    ];
    return [
      for (final expectation in expectations)
        if (!expectation.passed)
          QaFailure(
            suite: name,
            id: 'candidate_round_trip:${expectation.id}',
            message:
                'Parser candidate contract lost required review evidence during serialization.',
            severity: QaSeverity.warning,
            expected: expectation.id,
            actual: 'failed',
            suggestedFix:
                'Keep parser candidates review-only and preserve ranked alternatives, warnings, missing fields, confidence evidence, and suggested actions.',
            metadata: const {'triageCategory': QaFailureTriage.parserEngine},
          ),
    ];
  }
}

class _ContractField {
  const _ContractField(this.name, this.acceptedTokens);

  final String name;
  final List<String> acceptedTokens;

  bool isPresentIn(String source) {
    return acceptedTokens.any(source.contains);
  }
}

class _RoundTripExpectation {
  const _RoundTripExpectation(this.id, this.passed);

  final String id;
  final bool passed;
}
