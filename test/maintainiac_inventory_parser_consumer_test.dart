import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('inventory parser consumer labels broad release-one QA families', () {
    const contract = maintainiacInventoryParserConsumerContract;

    expect(contract.validate(), isEmpty);
    expect(
      contract.releaseTrades,
      containsAll(['plumbing', 'electrical', 'hvac']),
    );
    expect(contract.packLevels, containsAll(['core', 'standard']));
    expect(contract.supportedResultUses, contains('job_materials'));
    expect(contract.liveServicesAllowed, isFalse);
    expect(contract.firebaseWritesAllowed, isFalse);
    expect(contract.ocrCameraImplementationTouched, isFalse);
    expect(contract.families, hasLength(greaterThanOrEqualTo(12)));
    expect(
      contract.families.map((family) => family.id),
      containsAll([
        'catalog_schema_metadata',
        'alias_vendor_sku',
        'dangerous_ambiguity_context',
        'locale_spanish_release_one',
        'workflow_routing',
        'generated_batch_runner',
        'catalog_expansion_lifecycle',
        'real_receipt_validation_privacy',
        'portable_parser_core_boundary',
      ]),
    );
  });

  test('inventory parser consumer references existing QA support files', () {
    const contract = maintainiacInventoryParserConsumerContract;
    final missing = <String>[];

    for (final family in contract.families) {
      for (final path in family.files) {
        if (!File(path).existsSync()) missing.add('${family.id}:$path');
      }
    }

    expect(missing, isEmpty, reason: missing.take(20).join('\n'));
  });

  test('inventory parser consumer keeps commands focused and offline', () {
    const contract = maintainiacInventoryParserConsumerContract;
    final commands = contract.families.map((family) => family.command).toSet();

    expect(commands.length, greaterThanOrEqualTo(8));
    expect(
      commands,
      contains(
        'flutter test test/work_supply_parser_generated_fixture_runner_test.dart',
      ),
    );
    expect(
      commands.any((command) {
        final lower = command.toLowerCase();
        return lower.contains('firebase') ||
            lower.contains('firestore') ||
            lower.contains('mlkit') ||
            lower.contains('googlevision') ||
            lower.contains('camera');
      }),
      isFalse,
    );
  });

  test('inventory parser consumer rejects fake narrow coverage', () {
    const fake = MaintainiacInventoryParserConsumerContract(
      domain: 'work_supply_inventory_parser',
      locale: 'en-US',
      country: 'US',
      releaseTrades: {'plumbing'},
      packLevels: {'core'},
      supportedResultUses: {'inventory'},
      families: [
        MaintainiacInventoryParserQaFamily(
          id: 'tiny',
          label: 'Tiny fake family',
          files: ['test/tiny.txt'],
          riskTags: {'schema'},
          command: 'dart test tiny',
        ),
      ],
    );

    final failures = fake.validate().join('\n');

    expect(failures, contains('missing release-one trades'));
    expect(failures, contains('missing release-one pack levels'));
    expect(failures, contains('missing result-use routing coverage'));
    expect(failures, contains('broad QA family coverage'));
    expect(failures, contains('focused flutter test command'));
    expect(failures, contains('must be a Dart QA file'));
    expect(failures, contains('missing required risk tag alias'));
  });
}
