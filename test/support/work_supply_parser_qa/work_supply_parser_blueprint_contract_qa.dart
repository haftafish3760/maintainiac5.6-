import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserBlueprintContractSuite extends QaSuite {
  const WorkSupplyParserBlueprintContractSuite()
    : super('inventory.blueprint_contract');

  static const _requiredBlueprintFields = {
    'canonicalName',
    'aliases',
    'receiptPatterns',
    'negativeMatchTokens',
    'highImportanceTokens',
    'classification',
    'sourceConfidence',
    'needsReview',
    'promotionMode',
  };

  static const _requiredSafetyTokens = {
    'liveServicesAllowed',
    'promotionAllowed',
    'manual',
    'generated-needs-review',
    'promotion_must_require_manual_review',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final generator = File('tool/work_supply_catalog_blueprint_generator.dart');
    final validator = File('tool/work_supply_catalog_blueprint_validate.dart');
    final generatorText = generator.existsSync()
        ? generator.readAsStringSync()
        : '';
    final validatorText = validator.existsSync()
        ? validator.readAsStringSync()
        : '';
    final combined = '$generatorText\n$validatorText';

    for (final field in _requiredBlueprintFields) {
      if (combined.contains(field)) continue;
      failures.add(
        _failure(
          id: 'missing_blueprint_field:$field',
          message: 'Catalog blueprint pipeline is missing a required field.',
          expected: field,
          actual: 'not found in generator/validator',
          fix:
              'Add $field to the generated blueprint contract and validator before bulk catalog expansion.',
        ),
      );
    }
    for (final token in _requiredSafetyTokens) {
      if (combined.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_blueprint_safety:$token',
          message: 'Catalog blueprint pipeline is missing a safety control.',
          expected: token,
          actual: 'not found in generator/validator',
          fix:
              'Keep generated catalog rows review-only, local-only, and blocked from live-service promotion until explicitly approved.',
          category: QaFailureTriage.governance,
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: _requiredBlueprintFields.length + _requiredSafetyTokens.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'generatorPath': generator.path,
        'validatorPath': validator.path,
        'requiredBlueprintFields': _requiredBlueprintFields.toList()..sort(),
        'requiredSafetyTokens': _requiredSafetyTokens.toList()..sort(),
      },
    );
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String fix,
    String category = QaFailureTriage.schema,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.error,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: {'triageCategory': category},
    );
  }
}
