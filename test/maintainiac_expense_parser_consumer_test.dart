import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('expense parser consumer labels broad release-one QA families', () {
    const contract = maintainiacExpenseParserConsumerContract;

    expect(contract.validate(), isEmpty);
    expect(contract.domain, 'expense_receipt_parser');
    expect(contract.country, 'US');
    expect(contract.supportedResultUses, contains('expense_draft'));
    expect(contract.supportedResultUses, contains('expense_export'));
    expect(contract.liveServicesAllowed, isFalse);
    expect(contract.firebaseWritesAllowed, isFalse);
    expect(contract.ocrCameraImplementationTouched, isFalse);
    expect(contract.userConfirmedDataOverwritten, isFalse);
    expect(contract.families, hasLength(greaterThanOrEqualTo(8)));
    expect(
      contract.families.map((family) => family.id),
      containsAll([
        'parser_result_review',
        'draft_storage_lifecycle',
        'ledger_financial_math',
        'privacy_redaction',
        'materials_bridge',
        'failure_diagnostics',
      ]),
    );
  });

  test('expense parser consumer references existing QA files', () {
    const contract = maintainiacExpenseParserConsumerContract;
    final missing = <String>[];

    for (final family in contract.families) {
      for (final path in family.files) {
        if (!File(path).existsSync()) missing.add('${family.id}:$path');
      }
    }

    expect(missing, isEmpty, reason: missing.take(20).join('\n'));
  });

  test('expense parser consumer keeps commands focused and provider-free', () {
    const contract = maintainiacExpenseParserConsumerContract;
    final commands = contract.families.map((family) => family.command).toSet();

    expect(commands.length, greaterThanOrEqualTo(6));
    expect(
      commands,
      contains('flutter test test/expense_receipt_parser_test.dart'),
    );
    expect(
      commands.any((command) {
        final lower = command.toLowerCase();
        return lower.contains('mlkit') ||
            lower.contains('googlevision') ||
            lower.contains('camera');
      }),
      isFalse,
    );
  });

  test('expense parser consumer rejects unsafe fake readiness', () {
    const fake = MaintainiacExpenseParserConsumerContract(
      domain: 'expense_receipt_parser',
      locale: 'en-US',
      country: 'US',
      liveServicesAllowed: true,
      firebaseWritesAllowed: true,
      ocrCameraImplementationTouched: true,
      userConfirmedDataOverwritten: true,
      supportedResultUses: {'expense_draft'},
      families: [
        MaintainiacExpenseParserQaFamily(
          id: 'tiny',
          label: 'Tiny fake family',
          files: ['test/tiny.txt'],
          riskTags: {'privacy'},
          command: 'dart test tiny',
        ),
      ],
    );

    final failures = fake.validate().join('\n');

    expect(failures, contains('offline only'));
    expect(failures, contains('must not touch OCR/camera implementation'));
    expect(failures, contains('never overwrite confirmed data'));
    expect(failures, contains('missing result-use routing coverage'));
    expect(failures, contains('broad QA family coverage'));
    expect(failures, contains('focused flutter test command'));
    expect(failures, contains('must be a Dart QA file'));
    expect(failures, contains('missing required risk tag review-only'));
  });
}
