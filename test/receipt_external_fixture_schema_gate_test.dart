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
      expect(inventory['externalFixtureFilesReady'], isTrue);

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

  test('long receipt pack is externally loaded and privacy declared', () {
    final inventory =
        jsonDecode(
              File(
                'test/fixtures/receipt_qa/fixture_pack_inventory.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final packs = inventory['packs']! as Map<String, Object?>;
    final longEntry = packs['long_receipt']! as Map<String, Object?>;
    final fixtureFile = File(longEntry['file']! as String);
    final pack =
        jsonDecode(fixtureFile.readAsStringSync()) as Map<String, Object?>;
    final fixtures = pack['fixtures']! as List<Object?>;

    expect(longEntry['status'], 'external_loaded_schema_validated');
    expect(longEntry['fixtureCount'], fixtures.length);
    expect(fixtures, hasLength(4));
    for (final raw in fixtures.cast<Map<String, Object?>>()) {
      expect(raw['sourcePolicy'], 'synthetic_or_redacted_only');
      expect(raw['expectedEditable'], isTrue);
      final redaction = raw['redaction']! as Map<String, Object?>;
      expect(redaction['sensitiveFieldsRemoved'], isTrue);
    }
  });

  test('damaged OCR pack is externally loaded and privacy declared', () {
    final inventory =
        jsonDecode(
              File(
                'test/fixtures/receipt_qa/fixture_pack_inventory.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final packs = inventory['packs']! as Map<String, Object?>;
    final entry = packs['damaged_ocr']! as Map<String, Object?>;
    final fixtureFile = File(entry['file']! as String);
    final pack =
        jsonDecode(fixtureFile.readAsStringSync()) as Map<String, Object?>;
    final fixtures = pack['fixtures']! as List<Object?>;

    expect(entry['status'], 'external_loaded_schema_validated');
    expect(entry['fixtureCount'], fixtures.length);
    expect(fixtures, hasLength(7));
    for (final raw in fixtures.cast<Map<String, Object?>>()) {
      expect(raw['sourcePolicy'], 'synthetic_or_redacted_only');
      expect(raw['expectedEditable'], isTrue);
      expect(raw['photoQuality'], isA<Map<String, Object?>>());
      final redaction = raw['redaction']! as Map<String, Object?>;
      expect(redaction['sensitiveFieldsRemoved'], isTrue);
    }
  });

  test('all externally loaded pack files match inventory counts', () {
    final inventory =
        jsonDecode(
              File(
                'test/fixtures/receipt_qa/fixture_pack_inventory.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final packs = inventory['packs']! as Map<String, Object?>;
    const expectedExternalPacks = {
      'adjustment': 1,
      'contractor_supply': 2,
      'damaged_ocr': 7,
      'device_tiers': 2,
      'fuel': 6,
      'long_receipt': 4,
      'maintenance': 2,
      'noisy': 4,
      'privacy_admin': 2,
      'retail': 4,
    };

    for (final expected in expectedExternalPacks.entries) {
      final entry = packs[expected.key]! as Map<String, Object?>;
      expect(entry['status'], 'external_loaded_schema_validated');
      expect(entry['fixtureCount'], expected.value);
      final file = File(entry['file']! as String);
      expect(file.existsSync(), isTrue);
      final pack = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      expect(pack['pack'], expected.key);
      expect(pack['fixtures'], hasLength(expected.value));
    }
  });

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
