import 'maintainiac_regression_registry.dart';

class MaintainiacParserRegressionBinding {
  const MaintainiacParserRegressionBinding({
    required this.consumerId,
    required this.familyId,
    required this.regression,
    required this.permanentCommand,
  });

  final String consumerId;
  final String familyId;
  final MaintainiacRegressionCase regression;
  final String permanentCommand;

  List<String> validate() {
    final failures = <String>[];
    if (consumerId.trim().isEmpty) {
      failures.add('binding missing consumer id');
    }
    if (familyId.trim().isEmpty) {
      failures.add('$consumerId binding missing family id');
    }
    failures.addAll(regression.validate());
    if (!permanentCommand.startsWith('flutter test ')) {
      failures.add('${regression.bugId} needs focused flutter command');
    }
    if (!permanentCommand.contains(' --plain-name ')) {
      failures.add('${regression.bugId} needs individual plain-name command');
    }
    if (!regression.moduleTags.contains('parser')) {
      failures.add('${regression.bugId} must be tagged parser');
    }
    if (!regression.moduleTags.contains(consumerId)) {
      failures.add('${regression.bugId} must tag owning consumer $consumerId');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'consumerId': consumerId,
      'familyId': familyId,
      'bindingKey': '$consumerId:$familyId',
      'permanentCommand': permanentCommand,
      'regression': {
        'bugId': regression.bugId,
        'description': regression.description,
        'rootCause': regression.rootCause,
        'inputFixture': regression.inputFixture,
        'expectedBehavior': regression.expectedBehavior,
        'fixedVersion': regression.fixedVersion,
        'area': regression.area,
        'moduleTags': regression.moduleTags.toList()..sort(),
        'permanentTest': regression.permanentTest,
      },
    };
  }
}

class MaintainiacParserRegressionBindingRegistry {
  const MaintainiacParserRegressionBindingRegistry(this.bindings);

  final List<MaintainiacParserRegressionBinding> bindings;

  List<String> validate() {
    final failures = <String>[];
    final bugIds = <String>{};
    final families = <String>{};
    for (final binding in bindings) {
      if (!bugIds.add(binding.regression.bugId)) {
        failures.add('duplicate parser regression ${binding.regression.bugId}');
      }
      families.add('${binding.consumerId}:${binding.familyId}');
      failures.addAll(binding.validate());
    }
    for (final required in {
      'work_supply_inventory_parser:dangerous_ambiguity_context',
      'work_supply_inventory_parser:locale_spanish_release_one',
      'expense_receipt_parser:draft_storage_lifecycle',
      'expense_receipt_parser:privacy_redaction',
    }) {
      if (!families.contains(required)) {
        failures.add('missing parser regression binding $required');
      }
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'bindingCount': bindings.length,
      'bindings': [for (final binding in bindings) binding.toJson()],
    };
  }
}

const maintainiacParserRegressionBindingRegistry = MaintainiacParserRegressionBindingRegistry([
  MaintainiacParserRegressionBinding(
    consumerId: 'work_supply_inventory_parser',
    familyId: 'dangerous_ambiguity_context',
    permanentCommand:
        'flutter test test/maintainiac_inventory_parser_consumer_test.dart --plain-name "inventory parser consumer rejects fake narrow coverage"',
    regression: MaintainiacRegressionCase(
      bugId: 'INVPARSER-0001',
      description:
          'Generic PVC lines must not produce a confident single inventory item without context.',
      rootCause:
          'Dangerous-word aliases can hide cross-trade ambiguity if not gated.',
      inputFixture: 'inventory_pvc_ambiguous_line',
      expectedBehavior: 'ranked candidates or review required',
      fixedVersion: '2026.07.03',
      area: 'inventory_parser',
      moduleTags: {
        'work_supply_inventory_parser',
        'parser',
        'ambiguity',
        'regression',
      },
      permanentTest: 'test/maintainiac_inventory_parser_consumer_test.dart',
    ),
  ),
  MaintainiacParserRegressionBinding(
    consumerId: 'work_supply_inventory_parser',
    familyId: 'locale_spanish_release_one',
    permanentCommand:
        'flutter test test/maintainiac_inventory_parser_consumer_test.dart --plain-name "inventory parser consumer labels broad release-one QA families"',
    regression: MaintainiacRegressionCase(
      bugId: 'INVPARSER-0002',
      description:
          'US Spanish inventory parser coverage must stay separate from English packs.',
      rootCause:
          'Mixed language aliases can bloat packs and create false positives.',
      inputFixture: 'inventory_es_us_language_pack_boundary',
      expectedBehavior: 'Spanish pack coverage is explicit and separated',
      fixedVersion: '2026.07.03',
      area: 'inventory_parser_locale',
      moduleTags: {
        'work_supply_inventory_parser',
        'parser',
        'spanish',
        'regression',
      },
      permanentTest: 'test/maintainiac_inventory_parser_consumer_test.dart',
    ),
  ),
  MaintainiacParserRegressionBinding(
    consumerId: 'expense_receipt_parser',
    familyId: 'draft_storage_lifecycle',
    permanentCommand:
        'flutter test test/maintainiac_expense_parser_consumer_test.dart --plain-name "expense parser consumer rejects unsafe fake readiness"',
    regression: MaintainiacRegressionCase(
      bugId: 'EXPPARSER-0001',
      description:
          'Expense parser suggestions must persist as local drafts before any mirror sync.',
      rootCause:
          'Cloud-first assumptions can lose user-entered expense data on interruption.',
      inputFixture: 'expense_draft_local_first_fixture',
      expectedBehavior: 'local draft exists before mirror payload',
      fixedVersion: '2026.07.03',
      area: 'expense_parser_drafts',
      moduleTags: {
        'expense_receipt_parser',
        'parser',
        'local-first',
        'regression',
      },
      permanentTest: 'test/maintainiac_expense_parser_consumer_test.dart',
    ),
  ),
  MaintainiacParserRegressionBinding(
    consumerId: 'expense_receipt_parser',
    familyId: 'privacy_redaction',
    permanentCommand:
        'flutter test test/maintainiac_expense_parser_consumer_test.dart --plain-name "expense parser consumer rejects unsafe fake readiness"',
    regression: MaintainiacRegressionCase(
      bugId: 'EXPPARSER-0002',
      description:
          'Expense parser diagnostics and telemetry must not leak private receipt text.',
      rootCause:
          'Raw receipt-like fields can accidentally enter reports without redaction.',
      inputFixture: 'expense_parser_private_text_fixture',
      expectedBehavior: 'diagnostics are actionable but redacted',
      fixedVersion: '2026.07.03',
      area: 'expense_parser_privacy',
      moduleTags: {'expense_receipt_parser', 'parser', 'privacy', 'regression'},
      permanentTest: 'test/maintainiac_expense_parser_consumer_test.dart',
    ),
  ),
]);
