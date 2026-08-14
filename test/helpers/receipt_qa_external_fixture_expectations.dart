import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void expectReceiptQaExternalFixtureContract({
  required Map<String, Object?> manifest,
  required Map<String, Object?> fieldCoverage,
  required Map<String, Object?> packScores,
}) {
  final externalFixturePlan =
      manifest['externalFixturePlan']! as Map<String, Object?>;
  final manifestRealFixtureSupport =
      manifest['realFixtureSupport']! as Map<String, Object?>;
  expect(externalFixturePlan['schema'], 'receipt_qa_fixture_v1');
  expect(
    externalFixturePlan['schemaFile'],
    'test/fixtures/receipt_qa/receipt_qa_fixture_v1.schema.json',
  );
  expect(
    externalFixturePlan['inventoryFile'],
    'test/fixtures/receipt_qa/fixture_pack_inventory.json',
  );
  expect(externalFixturePlan['root'], 'test/fixtures/receipt_qa');
  expect(
    externalFixturePlan['textPolicy'],
    'raw_text_allowed_only_in_fixture_files_not_reports',
  );
  final externalPackFiles =
      externalFixturePlan['packFiles']! as Map<String, Object?>;
  expect(externalPackFiles.keys, containsAll(packScores.keys));
  for (final entry in externalPackFiles.entries) {
    expect(entry.value, 'test/fixtures/receipt_qa/${entry.key}.json');
  }
  expect(
    externalFixturePlan['summaryReportExcludes'],
    containsAll([
      'text',
      'rawText',
      'ocrText',
      'receiptImagePath',
      'cardNumber',
      'customerName',
    ]),
  );
  expect(
    manifestRealFixtureSupport,
    containsPair('privacyPolicy', 'synthetic_or_redacted_only'),
  );
  expect(
    manifestRealFixtureSupport,
    containsPair('expectedOutputsEditable', true),
  );
  expect(
    manifestRealFixtureSupport['fixtureKinds'],
    containsAll(['real_redacted', 'real_anonymized']),
  );
  expect(
    externalFixturePlan['requiredBeforeReady'],
    containsAll([
      contains('external JSON/CSV fixture files'),
      contains('runner loads external fixtures'),
    ]),
  );

  final fixtureSchemaFile = File(externalFixturePlan['schemaFile']! as String);
  expect(fixtureSchemaFile.existsSync(), isTrue);
  final fixtureInventoryFile = File(
    externalFixturePlan['inventoryFile']! as String,
  );
  expect(fixtureInventoryFile.existsSync(), isTrue);
  final fixtureSchema =
      jsonDecode(fixtureSchemaFile.readAsStringSync()) as Map<String, Object?>;
  final fixtureInventory =
      jsonDecode(fixtureInventoryFile.readAsStringSync())
          as Map<String, Object?>;
  final realFixtureSupport =
      fixtureInventory['realFixtureSupport']! as Map<String, Object?>;
  expect(fixtureSchema[r'$id'], 'maintainiac.receipt_qa_fixture_v1');
  expect(fixtureInventory['schema'], 'receipt_qa_fixture_pack_inventory_v1');
  expect(fixtureInventory['packs'], isA<Map<String, Object?>>());
  expect(
    fixtureSchema['required'],
    containsAll(['schema', 'pack', 'fixtures']),
  );
  expect(
    realFixtureSupport,
    containsPair('status', 'schema_ready_no_real_samples'),
  );
  expect(
    realFixtureSupport,
    containsPair('privacyPolicy', 'synthetic_or_redacted_only'),
  );
  expect(realFixtureSupport, containsPair('expectedOutputsEditable', true));
  expect(
    realFixtureSupport,
    containsPair('sensitiveThirdPartyDataAllowed', false),
  );
  expect(
    realFixtureSupport,
    containsPair(
      'artifactPolicy',
      'original_capture_preserved_derived_artifacts_separate',
    ),
  );

  final schemaDefs = fixtureSchema[r'$defs']! as Map<String, Object?>;
  final fixtureDef = schemaDefs['fixture']! as Map<String, Object?>;
  final expectedDef = schemaDefs['expected']! as Map<String, Object?>;
  final redactionDef = schemaDefs['redaction']! as Map<String, Object?>;
  final imageArtifactsDef =
      schemaDefs['imageArtifacts']! as Map<String, Object?>;
  expect(
    fixtureDef['required'],
    containsAll(['name', 'merchantNeedle', 'text', 'expected']),
  );
  expect(
    fixtureDef.toString(),
    allOf([
      contains('fixtureKind'),
      contains('real_redacted'),
      contains('real_anonymized'),
      contains('synthetic_or_redacted_only'),
      contains('artifactManifestId'),
      contains('imageArtifacts'),
    ]),
  );
  expect(
    redactionDef['required'],
    containsAll(['status', 'sensitiveFieldsRemoved']),
  );
  expect(
    imageArtifactsDef['required'],
    containsAll(['originalPreserved', 'sourceTruth']),
  );
  expect(
    expectedDef.toString(),
    allOf([
      contains('merchantName'),
      contains('dateIso'),
      contains('total'),
      contains('lineCategories'),
      contains('lineFamilies'),
      contains('lineUses'),
    ]),
  );
  expect(fieldCoverage['format'], 'fixture_field_coverage_v1');
  expect(fieldCoverage['externalFixtureFilesReady'], isTrue);
  expect(
    fieldCoverage['allRequiredFields'],
    containsAll(manifest['requiredFields']! as List<Object?>),
  );
  final coveragePacks = fieldCoverage['packs']! as Map<String, Object?>;
  expect(coveragePacks.keys, containsAll(packScores.keys));
  for (final entry in coveragePacks.entries) {
    final packCoverage = entry.value! as Map<String, Object?>;
    final requiredFields =
        packCoverage['requiredFields']! as Map<String, Object?>;
    expect(packCoverage['fixtureCount'], greaterThan(0));
    expect(
      requiredFields.keys,
      containsAll(manifest['requiredFields']! as List<Object?>),
    );
    expect(
      packCoverage['missingRequiredFieldCounts'],
      isA<Map<String, Object?>>(),
    );
    expect(packCoverage['readyForExternalExport'], isA<bool>());
  }
  expect(
    fieldCoverage.toString(),
    isNot(anyOf(contains('LOWE'), contains('MERCH TOTAL'))),
    reason: 'Fixture coverage reports counts only, never raw receipt text.',
  );
}
