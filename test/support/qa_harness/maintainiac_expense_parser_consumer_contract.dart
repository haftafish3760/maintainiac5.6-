import 'maintainiac_qa_case_registry.dart';
import 'maintainiac_qa_environment.dart';

class MaintainiacExpenseParserQaFamily {
  const MaintainiacExpenseParserQaFamily({
    required this.id,
    required this.label,
    required this.files,
    required this.riskTags,
    required this.command,
    this.releaseBlocker = true,
  });

  final String id;
  final String label;
  final List<String> files;
  final Set<String> riskTags;
  final String command;
  final bool releaseBlocker;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('expense parser family missing id');
    if (label.trim().isEmpty) failures.add('$id missing label');
    if (files.isEmpty) failures.add('$id missing QA files');
    if (riskTags.length < 2) failures.add('$id needs searchable risk tags');
    if (!command.startsWith('flutter test ')) {
      failures.add('$id needs focused flutter test command');
    }
    if (_mentionsForbiddenImplementation(command)) {
      failures.add('$id command must not target OCR/camera implementation');
    }
    for (final file in files) {
      if (!file.startsWith('test/')) {
        failures.add('$id has non-test file $file');
      }
      if (!file.endsWith('.dart')) {
        failures.add('$id file must be a Dart QA file: $file');
      }
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'label': label,
      'files': files,
      'riskTags': riskTags.toList()..sort(),
      'command': command,
      'releaseBlocker': releaseBlocker,
    };
  }
}

class MaintainiacExpenseParserConsumerContract {
  const MaintainiacExpenseParserConsumerContract({
    required this.domain,
    required this.locale,
    required this.country,
    required this.families,
    required this.supportedResultUses,
    this.liveServicesAllowed = false,
    this.firebaseWritesAllowed = false,
    this.ocrCameraImplementationTouched = false,
    this.userConfirmedDataOverwritten = false,
  });

  final String domain;
  final String locale;
  final String country;
  final List<MaintainiacExpenseParserQaFamily> families;
  final Set<String> supportedResultUses;
  final bool liveServicesAllowed;
  final bool firebaseWritesAllowed;
  final bool ocrCameraImplementationTouched;
  final bool userConfirmedDataOverwritten;

  static const requiredRiskTags = {
    'parser-suggestion',
    'review-only',
    'draft-lifecycle',
    'local-first',
    'financial',
    'category',
    'diagnostics',
    'privacy',
    'redaction',
    'security',
    'materials-bridge',
    'source-of-truth',
    'sync',
    'telemetry',
    'regression',
  };

  static const requiredResultUses = {
    'expense_draft',
    'expense_review',
    'expense_ledger',
    'expense_recap',
    'expense_export',
  };

  List<String> validate() {
    final failures = <String>[];
    if (domain != 'expense_receipt_parser') {
      failures.add('expense consumer domain mismatch');
    }
    if (locale != 'en-US' && locale != 'es-US') {
      failures.add(
        'expense consumer locale must be release-one US English or Spanish',
      );
    }
    if (country != 'US') failures.add('expense consumer country must be US');
    if (liveServicesAllowed || firebaseWritesAllowed) {
      failures.add('expense parser consumer QA must run offline only');
    }
    if (ocrCameraImplementationTouched) {
      failures.add(
        'expense parser consumer must not touch OCR/camera implementation',
      );
    }
    if (userConfirmedDataOverwritten) {
      failures.add(
        'expense parser consumer must never overwrite confirmed data',
      );
    }
    if (!supportedResultUses.containsAll(requiredResultUses)) {
      failures.add('expense consumer missing result-use routing coverage');
    }
    if (families.length < 8) {
      failures.add('expense consumer needs broad QA family coverage');
    }

    final ids = <String>{};
    final tags = <String>{};
    final commands = <String>{};
    for (final family in families) {
      if (!ids.add(family.id)) {
        failures.add('duplicate expense parser QA family ${family.id}');
      }
      commands.add(family.command);
      tags.addAll(family.riskTags);
      failures.addAll(family.validate());
    }
    if (commands.length < 6) {
      failures.add('expense consumer needs surgical focused commands');
    }
    for (final tag in requiredRiskTags) {
      if (!tags.contains(tag)) {
        failures.add('expense consumer missing required risk tag $tag');
      }
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'domain': domain,
      'locale': locale,
      'country': country,
      'familyCount': families.length,
      'releaseBlockerFamilies': families
          .where((family) => family.releaseBlocker)
          .length,
      'supportedResultUses': supportedResultUses.toList()..sort(),
      'liveServicesAllowed': liveServicesAllowed,
      'firebaseWritesAllowed': firebaseWritesAllowed,
      'ocrCameraImplementationTouched': ocrCameraImplementationTouched,
      'userConfirmedDataOverwritten': userConfirmedDataOverwritten,
      'families': [for (final family in families) family.toJson()],
    };
  }
}

const maintainiacExpenseParserConsumerContract = MaintainiacExpenseParserConsumerContract(
  domain: 'expense_receipt_parser',
  locale: 'en-US',
  country: 'US',
  supportedResultUses: {
    'expense_draft',
    'expense_review',
    'expense_ledger',
    'expense_recap',
    'expense_export',
  },
  families: [
    MaintainiacExpenseParserQaFamily(
      id: 'parser_result_review',
      label: 'Expense parser suggestions stay review-only until confirmed',
      files: [
        'test/expense_receipt_parser_test.dart',
        'test/expense_receipt_assisted_review_flow_test.dart',
        'test/expense_parser_failure_diagnostics_test.dart',
      ],
      riskTags: {'parser-suggestion', 'review-only', 'diagnostics'},
      command: 'flutter test test/expense_receipt_parser_test.dart',
    ),
    MaintainiacExpenseParserQaFamily(
      id: 'draft_storage_lifecycle',
      label: 'Expense drafts persist locally before any mirror sync',
      files: [
        'test/expense_draft_store_test.dart',
        'test/expense_draft_storage_lifecycle_test.dart',
        'test/expense_receipt_line_record_test.dart',
      ],
      riskTags: {'draft-lifecycle', 'local-first', 'sync', 'source-of-truth'},
      command: 'flutter test test/expense_draft_store_test.dart',
    ),
    MaintainiacExpenseParserQaFamily(
      id: 'ledger_financial_math',
      label: 'Expense ledger totals use deterministic integer-cent math',
      files: [
        'test/expense_ledger_totals_test.dart',
        'test/expense_ledger_store_test.dart',
        'test/expense_ledger_fuel_test.dart',
      ],
      riskTags: {'financial', 'regression', 'category'},
      command: 'flutter test test/expense_ledger_totals_test.dart',
    ),
    MaintainiacExpenseParserQaFamily(
      id: 'category_classification',
      label: 'Receipt categories classify safely without forcing bad matches',
      files: [
        'test/expense_receipt_category_rules_test.dart',
        'test/expense_receipt_classifier_test.dart',
        'test/expense_receipt_item_memory_store_test.dart',
      ],
      riskTags: {'category', 'parser-suggestion', 'regression'},
      command: 'flutter test test/expense_receipt_category_rules_test.dart',
    ),
    MaintainiacExpenseParserQaFamily(
      id: 'privacy_redaction',
      label: 'Expense parser telemetry and reports redact private data',
      files: [
        'test/expense_telemetry_redaction_contract_guard_test.dart',
        'test/expense_screen_telemetry_test.dart',
        'test/helpers/expense_telemetry_schema_expectations.dart',
      ],
      riskTags: {'privacy', 'redaction', 'telemetry'},
      command:
          'flutter test test/expense_telemetry_redaction_contract_guard_test.dart',
    ),
    MaintainiacExpenseParserQaFamily(
      id: 'materials_bridge',
      label: 'Expense receipts can suggest inventory materials safely',
      files: [
        'test/expense_materials_receipt_bridge_test.dart',
        'test/expense_receipt_line_record_test.dart',
        'test/expense_receipt_assisted_review_flow_test.dart',
      ],
      riskTags: {'materials-bridge', 'review-only', 'local-first'},
      command: 'flutter test test/expense_materials_receipt_bridge_test.dart',
    ),
    MaintainiacExpenseParserQaFamily(
      id: 'failure_diagnostics',
      label:
          'Parser failures produce actionable diagnostics without private text leaks',
      files: [
        'test/expense_parser_failure_diagnostics_test.dart',
        'test/expense_receipt_line_record_test.dart',
        'test/expense_receipt_assisted_review_flow_test.dart',
      ],
      riskTags: {'diagnostics', 'privacy', 'security'},
      command: 'flutter test test/expense_parser_failure_diagnostics_test.dart',
    ),
    MaintainiacExpenseParserQaFamily(
      id: 'telemetry_boundary',
      label:
          'Expense telemetry bridge is scoped and does not mutate source records',
      files: [
        'test/expense_screen_telemetry_firestore_bridge_test.dart',
        'test/expense_screen_telemetry_test.dart',
        'test/expense_draft_storage_lifecycle_test.dart',
      ],
      riskTags: {'telemetry', 'security', 'sync'},
      command: 'flutter test test/expense_screen_telemetry_test.dart',
    ),
  ],
);

const maintainiacExpenseParserConsumerCases = [
  MaintainiacQaCase(
    id: 'expense_parser_consumer_contract',
    title: 'Expense parser consumer is wired to the shared QA backbone',
    module: MaintainiacQaModule.expenses,
    priority: MaintainiacQaCasePriority.releaseBlocker,
    behavior:
        'Expense parser QA families are labeled, review-only, offline, and local-first.',
    evidenceTarget: 'maintainiac_expense_parser_consumer_test',
    testCommand:
        'flutter test test/maintainiac_expense_parser_consumer_test.dart',
    tags: {'expenses', 'parser', 'qa-backbone'},
  ),
];

bool _mentionsForbiddenImplementation(String command) {
  final normalized = command.toLowerCase();
  return normalized.contains('googlevision') ||
      normalized.contains('mlkit') ||
      normalized.contains('camera');
}
