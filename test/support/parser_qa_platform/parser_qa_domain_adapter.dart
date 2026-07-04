class ParserQaDomainAdapter {
  const ParserQaDomainAdapter({
    required this.domain,
    required this.artifactPrefix,
    required this.fixtureRoot,
    required this.forbiddenBoundaryTokens,
    required this.supportedResultUses,
    required this.executionTargets,
    required this.pureInputFields,
    required this.pureOutputFields,
  });

  final String domain;
  final String artifactPrefix;
  final String fixtureRoot;
  final List<String> forbiddenBoundaryTokens;
  final List<String> supportedResultUses;
  final List<String> executionTargets;
  final List<String> pureInputFields;
  final List<String> pureOutputFields;

  List<String> validateContract() {
    final failures = <String>[];
    if (domain.trim().isEmpty) {
      failures.add('domain must not be empty');
    }
    if (artifactPrefix.trim().isEmpty) {
      failures.add('artifactPrefix must not be empty');
    }
    if (fixtureRoot.trim().isEmpty) {
      failures.add('fixtureRoot must not be empty');
    }
    if (forbiddenBoundaryTokens.isEmpty) {
      failures.add('forbiddenBoundaryTokens must not be empty');
    }
    if (supportedResultUses.isEmpty) {
      failures.add('supportedResultUses must not be empty');
    }
    if (executionTargets.isEmpty) {
      failures.add('executionTargets must not be empty');
    }
    if (pureInputFields.isEmpty) {
      failures.add('pureInputFields must not be empty');
    }
    if (pureOutputFields.isEmpty) {
      failures.add('pureOutputFields must not be empty');
    }
    if (_hasDuplicates(forbiddenBoundaryTokens)) {
      failures.add('forbiddenBoundaryTokens must be unique');
    }
    if (_hasDuplicates(supportedResultUses)) {
      failures.add('supportedResultUses must be unique');
    }
    if (_hasDuplicates(executionTargets)) {
      failures.add('executionTargets must be unique');
    }
    if (_hasDuplicates(pureInputFields)) {
      failures.add('pureInputFields must be unique');
    }
    if (_hasDuplicates(pureOutputFields)) {
      failures.add('pureOutputFields must be unique');
    }
    if (forbiddenBoundaryTokens.any((token) => token.trim().isEmpty)) {
      failures.add('forbiddenBoundaryTokens must not contain blanks');
    }
    if (supportedResultUses.any((use) => use.trim().isEmpty)) {
      failures.add('supportedResultUses must not contain blanks');
    }
    if (executionTargets.any((target) => target.trim().isEmpty)) {
      failures.add('executionTargets must not contain blanks');
    }
    if (pureInputFields.any((field) => field.trim().isEmpty)) {
      failures.add('pureInputFields must not contain blanks');
    }
    if (pureOutputFields.any((field) => field.trim().isEmpty)) {
      failures.add('pureOutputFields must not contain blanks');
    }
    for (final required in _requiredExecutionTargets) {
      if (!_containsNormalized(executionTargets, required)) {
        failures.add('executionTargets must include $required');
      }
    }
    for (final required in _requiredInputFields) {
      if (!_containsNormalized(pureInputFields, required)) {
        failures.add('pureInputFields must include $required');
      }
    }
    for (final required in _requiredOutputFields) {
      if (!_containsNormalized(pureOutputFields, required)) {
        failures.add('pureOutputFields must include $required');
      }
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'domain': domain,
      'artifactPrefix': artifactPrefix,
      'fixtureRoot': fixtureRoot,
      'forbiddenBoundaryTokens': forbiddenBoundaryTokens,
      'supportedResultUses': supportedResultUses,
      'executionTargets': executionTargets,
      'pureInputFields': pureInputFields,
      'pureOutputFields': pureOutputFields,
      'liveServicesAllowed': false,
      'writesProductionCatalog': false,
      'firebaseWritesAllowed': false,
      'ocrCameraExpensesTouched': false,
    };
  }
}

const _requiredExecutionTargets = ['qa_harness', 'command_line'];
const _requiredInputFields = ['localePackId', 'userConfirmedContext'];
const _requiredOutputFields = [
  'confidence',
  'reviewStatus',
  'warnings',
  'evidence',
  'suggestedAction',
];

const workSupplyParserDomainAdapter = ParserQaDomainAdapter(
  domain: 'work_supply_inventory_parser',
  artifactPrefix: 'work_supply_inventory_parser',
  fixtureRoot: 'test/fixtures/work_supply_parser',
  forbiddenBoundaryTokens: [
    'FirebaseFirestore.instance',
    'Hive.',
    'Hive.init',
    'Box<',
    'camera',
    'ocr',
    'expenses',
    'GoogleVision',
    'MLKit',
    'testWidgets',
    'WidgetTester',
    'pumpWidget',
  ],
  supportedResultUses: [
    'inventory',
    'estimate_materials',
    'job_materials',
    'invoice_materials',
    'fleet_vehicle_inventory',
  ],
  executionTargets: [
    'mobile_local',
    'backend_service',
    'qa_harness',
    'command_line',
    'cloud_batch',
  ],
  pureInputFields: [
    'ocrText',
    'enabledTradePacks',
    'parserSettings',
    'localePackId',
    'merchantHint',
    'workflowContext',
    'userConfirmedContext',
  ],
  pureOutputFields: [
    'rankedCandidates',
    'confidence',
    'reviewStatus',
    'warnings',
    'evidence',
    'suggestedAction',
  ],
);

const parserQaDomainAdapters = [
  workSupplyParserDomainAdapter,
  expenseReceiptParserDomainAdapter,
  maintenanceParserDomainAdapter,
];

bool _hasDuplicates(List<String> values) {
  final seen = <String>{};
  for (final value in values) {
    if (!seen.add(value.trim().toLowerCase())) return true;
  }
  return false;
}

bool _containsNormalized(List<String> values, String expected) {
  final normalized = expected.trim().toLowerCase();
  return values.any((value) => value.trim().toLowerCase() == normalized);
}

const maintenanceParserDomainAdapter = ParserQaDomainAdapter(
  domain: 'maintenance_parser',
  artifactPrefix: 'maintenance_parser',
  fixtureRoot: 'test/fixtures/maintenance_parser',
  forbiddenBoundaryTokens: [
    'FirebaseFirestore.instance',
    'Hive.',
    'Hive.init',
    'Box<',
    'camera',
    'ocr',
    'expenses',
  ],
  supportedResultUses: [
    'maintenance_task',
    'asset_service_history',
    'work_order',
    'fleet_vehicle_maintenance',
  ],
  executionTargets: [
    'mobile_local',
    'backend_service',
    'qa_harness',
    'command_line',
  ],
  pureInputFields: [
    'serviceText',
    'assetContext',
    'maintenanceSettings',
    'localePackId',
    'userConfirmedContext',
  ],
  pureOutputFields: [
    'rankedCandidates',
    'confidence',
    'reviewStatus',
    'warnings',
    'evidence',
    'suggestedAction',
  ],
);

const expenseReceiptParserDomainAdapter = ParserQaDomainAdapter(
  domain: 'expense_receipt_parser',
  artifactPrefix: 'expense_receipt_parser',
  fixtureRoot: 'test/fixtures/expense_receipts',
  forbiddenBoundaryTokens: [
    'FirebaseFirestore.instance',
    'Hive.',
    'Hive.init',
    'Box<',
    'CameraController',
    'ImagePicker',
    'GoogleVision',
    'MLKit',
    'TextRecognizer',
  ],
  supportedResultUses: [
    'expense_draft',
    'expense_review',
    'expense_ledger',
    'expense_recap',
    'expense_export',
  ],
  executionTargets: [
    'mobile_local',
    'backend_service',
    'qa_harness',
    'command_line',
  ],
  pureInputFields: [
    'ocrText',
    'expenseSettings',
    'localePackId',
    'merchantHint',
    'userConfirmedContext',
  ],
  pureOutputFields: [
    'expenseDraft',
    'confidence',
    'reviewStatus',
    'warnings',
    'evidence',
    'suggestedAction',
  ],
);
