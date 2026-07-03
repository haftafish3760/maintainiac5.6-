import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserEvidenceAttributionSuite extends QaSuite {
  const WorkSupplyParserEvidenceAttributionSuite()
    : super('inventory.evidence_attribution');

  static const _scannedFiles = [
    'lib/screens/work_supplies/data/work_supply_receipt_parser.dart',
    'lib/screens/work_supplies/data/work_supply_inventory_receipt_models.dart',
    'lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart',
    'lib/shared/receipts/receipt_line_models.dart',
    'docs/inventory_parser_qa_harness_plan.md',
  ];

  static const _requiredEvidenceTokens = <_EvidenceToken>[
    _EvidenceToken(
      name: 'raw_receipt_text',
      tokens: ['rawReceiptText', 'rawText', 'receiptEvidenceText'],
      category: QaFailureTriage.parserEngine,
    ),
    _EvidenceToken(
      name: 'normalized_or_cleaned_text',
      tokens: ['cleanedLine', 'normalizedLine', 'normalizedText', '_normalize'],
      category: QaFailureTriage.normalization,
    ),
    _EvidenceToken(
      name: 'matched_terms',
      tokens: ['matchedTerms', 'catalogMatchedTerms'],
      category: QaFailureTriage.alias,
    ),
    _EvidenceToken(
      name: 'confidence_reason',
      tokens: ['confidenceReasons', 'parserReviewReason', 'reason'],
      category: QaFailureTriage.confidence,
    ),
    _EvidenceToken(
      name: 'original_parsed_identity',
      tokens: [
        'originalParsedDescription',
        'originalParsedInventoryItemId',
        'originalParsedInventoryPath',
      ],
      category: QaFailureTriage.governance,
    ),
    _EvidenceToken(
      name: 'processing_source',
      tokens: ['ReceiptProcessingSource', 'source: source'],
      category: QaFailureTriage.governance,
    ),
    _EvidenceToken(
      name: 'field_source_attribution',
      tokens: ['fieldSource', 'sourceAttribution', 'evidenceSource'],
      category: QaFailureTriage.parserEngine,
      warningOnly: true,
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final sourceByPath = <String, String>{};
    for (final path in _scannedFiles) {
      final file = File(path);
      if (!file.existsSync()) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_evidence_scan_file:$path',
            message: 'Evidence attribution scan file is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix:
                'Update this suite when parser evidence model files move.',
            metadata: const {'triageCategory': QaFailureTriage.schema},
          ),
        );
        continue;
      }
      sourceByPath[path] = file.readAsStringSync();
    }
    final source = sourceByPath.values.join('\n');

    final present = <String>[];
    final missing = <String>[];
    for (final token in _requiredEvidenceTokens) {
      if (token.isPresentIn(source)) {
        present.add(token.name);
        continue;
      }
      missing.add(token.name);
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_evidence_contract:${token.name}',
          message: 'Parser evidence contract is missing an evidence field.',
          severity: token.warningOnly ? QaSeverity.warning : QaSeverity.error,
          expected: token.name,
          actual: 'not found',
          suggestedFix:
              'Keep raw evidence, cleaned/derived text, match evidence, confidence reasons, and source attribution separate.',
          metadata: {'triageCategory': token.category},
        ),
      );
    }

    _checkRawEvidenceNotNormalizedInPlace(failures, sourceByPath);

    return timer.finish(
      suite: name,
      checked: _requiredEvidenceTokens.length + _scannedFiles.length + 2,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'presentEvidenceContracts': present,
        'missingEvidenceContracts': missing,
        'filesScanned': sourceByPath.keys.toList()..sort(),
      },
    );
  }

  void _checkRawEvidenceNotNormalizedInPlace(
    List<QaFailure> failures,
    Map<String, String> sourceByPath,
  ) {
    final bridge =
        sourceByPath['lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart'] ??
        '';
    if (!bridge.contains('rawReceiptText: sourceLine.receiptEvidenceText')) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'raw_evidence_not_directly_preserved',
          message:
              'Parsed receipt bridge does not clearly preserve source evidence text.',
          expected: 'rawReceiptText: sourceLine.receiptEvidenceText',
          actual: 'direct mapping not found',
          suggestedFix:
              'Assign source evidence to rawReceiptText before any normalized or display text transformation.',
          metadata: const {'triageCategory': QaFailureTriage.parserEngine},
        ),
      );
    }

    final draft =
        sourceByPath['lib/shared/receipts/receipt_line_models.dart'] ?? '';
    if (!draft.contains('final String rawReceiptText;') ||
        !draft.contains("'rawReceiptText': rawReceiptText")) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'raw_evidence_not_serialized',
          message:
              'Receipt line draft does not serialize raw receipt evidence.',
          expected: 'rawReceiptText field and map serialization',
          actual: 'missing field or serialization token',
          suggestedFix:
              'Persist raw evidence separately from display/normalized fields so parser decisions remain auditable.',
          metadata: const {'triageCategory': QaFailureTriage.parserEngine},
        ),
      );
    }
  }
}

class _EvidenceToken {
  const _EvidenceToken({
    required this.name,
    required this.tokens,
    required this.category,
    this.warningOnly = false,
  });

  final String name;
  final List<String> tokens;
  final String category;
  final bool warningOnly;

  bool isPresentIn(String source) {
    return tokens.any(source.contains);
  }
}
