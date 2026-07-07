import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'receipt external fixture schema plan is executable and privacy-safe',
    () {
      final schemaFile = File(
        'test/fixtures/receipt_qa/receipt_qa_fixture_v1.schema.json',
      );
      final inventoryFile = File(
        'test/fixtures/receipt_qa/fixture_pack_inventory.json',
      );

      expect(schemaFile.existsSync(), isTrue);
      expect(inventoryFile.existsSync(), isTrue);

      final schema =
          jsonDecode(schemaFile.readAsStringSync()) as Map<String, Object?>;
      final inventory =
          jsonDecode(inventoryFile.readAsStringSync()) as Map<String, Object?>;

      expect(schema[r'$id'], 'maintainiac.receipt_qa_fixture_v1');
      expect(schema['additionalProperties'], isFalse);
      expect(inventory['schema'], 'receipt_qa_fixture_pack_inventory_v1');
      expect(inventory['fixtureSchema'], 'receipt_qa_fixture_v1');
      expect(inventory['externalFixtureFilesReady'], isFalse);

      final realFixtureSupport =
          inventory['realFixtureSupport']! as Map<String, Object?>;
      expect(realFixtureSupport['privacyPolicy'], 'synthetic_or_redacted_only');
      expect(realFixtureSupport['expectedOutputsEditable'], isTrue);
      expect(realFixtureSupport['sensitiveThirdPartyDataAllowed'], isFalse);
      expect(
        realFixtureSupport['artifactPolicy'],
        'original_capture_preserved_derived_artifacts_separate',
      );

      final raw =
          '${schemaFile.readAsStringSync()} ${inventoryFile.readAsStringSync()}';
      expect(raw, isNot(contains('receiptImagePath')));
      expect(raw, isNot(contains('sourceImageBytes')));
      expect(raw, isNot(contains('customerName')));
      expect(raw, isNot(contains('cardNumber')));
    },
  );

  test('receipt external fixture schema gate is executable', () async {
    final result = await Process.run('dart', [
      'tool/receipt_external_fixture_schema_gate.dart',
    ]);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(
      result.stdout.toString(),
      contains('Receipt external fixture schema gate: PASS'),
    );
  });
}
