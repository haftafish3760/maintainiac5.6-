import 'package:flutter_test/flutter_test.dart';

import 'support/parser_qa_platform/parser_qa_platform.dart';

void main() {
  test(
    'domain adapters keep inventory and maintenance on the shared platform',
    () {
      final inventory = workSupplyParserDomainAdapter.toJson();
      final expense = expenseReceiptParserDomainAdapter.toJson();
      final maintenance = maintenanceParserDomainAdapter.toJson();

      expect(inventory['domain'], 'work_supply_inventory_parser');
      expect(expense['domain'], 'expense_receipt_parser');
      expect(maintenance['domain'], 'maintenance_parser');
      expect(inventory['artifactPrefix'], isNot(maintenance['artifactPrefix']));
      expect(expense['artifactPrefix'], isNot(inventory['artifactPrefix']));
      expect(
        inventory['supportedResultUses'].toString(),
        contains('estimate_materials'),
      );
      expect(
        inventory['executionTargets'].toString(),
        contains('mobile_local'),
      );
      expect(inventory['executionTargets'].toString(), contains('qa_harness'));
      expect(inventory['executionTargets'].toString(), contains('cloud_batch'));
      expect(expense['executionTargets'].toString(), contains('cloud_batch'));
      expect(
        maintenance['executionTargets'].toString(),
        contains('cloud_batch'),
      );
      expect(inventory['pureInputFields'].toString(), contains('ocrText'));
      expect(
        inventory['pureInputFields'].toString(),
        contains('enabledTradePacks'),
      );
      expect(
        inventory['pureOutputFields'].toString(),
        contains('rankedCandidates'),
      );
      expect(
        inventory['pureOutputFields'].toString(),
        contains('reviewStatus'),
      );
      expect(
        expense['supportedResultUses'].toString(),
        contains('expense_ledger'),
      );
      expect(
        maintenance['supportedResultUses'].toString(),
        contains('work_order'),
      );
      expect(inventory['firebaseWritesAllowed'], isFalse);
      expect(expense['liveServicesAllowed'], isFalse);
      expect(maintenance['ocrCameraExpensesTouched'], isFalse);
    },
  );

  test('all registered domain adapters satisfy the reusable contract', () {
    expect(parserQaDomainAdapters.map((adapter) => adapter.domain).toSet(), {
      'work_supply_inventory_parser',
      'expense_receipt_parser',
      'maintenance_parser',
    });
    expect(
      parserQaDomainAdapters.map((adapter) => adapter.artifactPrefix).toSet(),
      hasLength(parserQaDomainAdapters.length),
      reason:
          'Each parser adapter needs an isolated artifact prefix so reports do not overwrite each other.',
    );
    expect(
      parserQaDomainAdapters.map((adapter) => adapter.fixtureRoot).toSet(),
      hasLength(parserQaDomainAdapters.length),
      reason:
          'Each parser adapter needs its own fixture root so inventory, expenses, and maintenance do not bleed together.',
    );

    for (final adapter in parserQaDomainAdapters) {
      expect(
        adapter.validateContract(),
        isEmpty,
        reason: '${adapter.domain} should be safe to run on the QA platform.',
      );
      expect(
        adapter.forbiddenBoundaryTokens,
        contains('liveCloudDocumentStore.instance'),
      );
      expect(adapter.forbiddenBoundaryTokens, contains('Hive.'));
      expect(adapter.forbiddenBoundaryTokens, contains('Hive.init'));
      expect(adapter.toJson()['liveServicesAllowed'], isFalse);
      expect(adapter.toJson()['writesProductionCatalog'], isFalse);
      expect(adapter.toJson()['firebaseWritesAllowed'], isFalse);
      expect(adapter.toJson()['ocrCameraExpensesTouched'], isFalse);
      expect(adapter.toJson()['executionTargets'], contains('qa_harness'));
      expect(adapter.toJson()['executionTargets'], contains('command_line'));
      expect(adapter.toJson()['executionTargets'], contains('mobile_local'));
      expect(adapter.toJson()['executionTargets'], contains('backend_service'));
      expect(adapter.toJson()['executionTargets'], contains('cloud_batch'));
      expect(adapter.toJson()['pureOutputFields'], contains('reviewStatus'));
      expect(adapter.toJson()['pureOutputFields'], contains('evidence'));
    }
  });

  test('expense parser adapter stays out of camera and OCR implementation', () {
    expect(
      expenseReceiptParserDomainAdapter.forbiddenBoundaryTokens,
      containsAll(['CameraController', 'GoogleVision', 'MLKit']),
    );
    expect(
      expenseReceiptParserDomainAdapter.supportedResultUses,
      containsAll(['expense_draft', 'expense_review', 'expense_ledger']),
    );
    expect(
      expenseReceiptParserDomainAdapter.supportedResultUses,
      isNot(contains('camera_capture')),
    );
  });

  test('domain adapter contract rejects unsafe incomplete domains', () {
    const adapter = ParserQaDomainAdapter(
      domain: '',
      artifactPrefix: 'parser',
      fixtureRoot: '',
      forbiddenBoundaryTokens: ['ocr', 'OCR'],
      supportedResultUses: ['inventory', 'inventory'],
      executionTargets: ['qa_harness', 'qa_harness', ''],
      pureInputFields: ['ocrText', 'ocrText', ''],
      pureOutputFields: ['reviewStatus', 'reviewStatus', ''],
    );

    final failures = adapter.validateContract();

    expect(failures, contains('domain must not be empty'));
    expect(failures, contains('fixtureRoot must not be empty'));
    expect(failures, contains('forbiddenBoundaryTokens must be unique'));
    expect(
      failures,
      contains('forbiddenBoundaryTokens must include cloud mirror boundary'),
    );
    expect(
      failures,
      contains('forbiddenBoundaryTokens must include Hive boundary'),
    );
    expect(
      failures,
      contains('forbiddenBoundaryTokens must include camera boundary'),
    );
    expect(failures, contains('supportedResultUses must be unique'));
    expect(failures, contains('executionTargets must be unique'));
    expect(failures, contains('executionTargets must not contain blanks'));
    expect(failures, contains('executionTargets must include mobile_local'));
    expect(failures, contains('executionTargets must include backend_service'));
    expect(failures, contains('executionTargets must include command_line'));
    expect(failures, contains('executionTargets must include cloud_batch'));
    expect(failures, contains('pureInputFields must be unique'));
    expect(failures, contains('pureInputFields must not contain blanks'));
    expect(failures, contains('pureOutputFields must be unique'));
    expect(failures, contains('pureOutputFields must not contain blanks'));
    expect(failures, contains('pureInputFields must include localePackId'));
    expect(
      failures,
      contains('pureInputFields must include userConfirmedContext'),
    );
    expect(failures, contains('pureOutputFields must include confidence'));
    expect(failures, contains('pureOutputFields must include warnings'));
    expect(failures, contains('pureOutputFields must include evidence'));
    expect(failures, contains('pureOutputFields must include suggestedAction'));
  });
}
