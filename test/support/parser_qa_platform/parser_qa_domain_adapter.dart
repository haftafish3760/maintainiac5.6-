class ParserQaDomainAdapter {
  const ParserQaDomainAdapter({
    required this.domain,
    required this.artifactPrefix,
    required this.fixtureRoot,
    required this.forbiddenBoundaryTokens,
    required this.supportedResultUses,
  });

  final String domain;
  final String artifactPrefix;
  final String fixtureRoot;
  final List<String> forbiddenBoundaryTokens;
  final List<String> supportedResultUses;

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
    if (_hasDuplicates(forbiddenBoundaryTokens)) {
      failures.add('forbiddenBoundaryTokens must be unique');
    }
    if (_hasDuplicates(supportedResultUses)) {
      failures.add('supportedResultUses must be unique');
    }
    if (forbiddenBoundaryTokens.any((token) => token.trim().isEmpty)) {
      failures.add('forbiddenBoundaryTokens must not contain blanks');
    }
    if (supportedResultUses.any((use) => use.trim().isEmpty)) {
      failures.add('supportedResultUses must not contain blanks');
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
      'liveServicesAllowed': false,
      'writesProductionCatalog': false,
      'firebaseWritesAllowed': false,
      'ocrCameraExpensesTouched': false,
    };
  }
}

const workSupplyParserDomainAdapter = ParserQaDomainAdapter(
  domain: 'work_supply_inventory_parser',
  artifactPrefix: 'work_supply_inventory_parser',
  fixtureRoot: 'test/fixtures/work_supply_parser',
  forbiddenBoundaryTokens: [
    'FirebaseFirestore.instance',
    'camera',
    'ocr',
    'expenses',
    'GoogleVision',
    'MLKit',
  ],
  supportedResultUses: [
    'inventory',
    'estimate_materials',
    'job_materials',
    'invoice_materials',
    'fleet_vehicle_inventory',
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

const maintenanceParserDomainAdapter = ParserQaDomainAdapter(
  domain: 'maintenance_parser',
  artifactPrefix: 'maintenance_parser',
  fixtureRoot: 'test/fixtures/maintenance_parser',
  forbiddenBoundaryTokens: [
    'FirebaseFirestore.instance',
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
);

const expenseReceiptParserDomainAdapter = ParserQaDomainAdapter(
  domain: 'expense_receipt_parser',
  artifactPrefix: 'expense_receipt_parser',
  fixtureRoot: 'test/fixtures/expense_receipts',
  forbiddenBoundaryTokens: [
    'FirebaseFirestore.instance',
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
);
