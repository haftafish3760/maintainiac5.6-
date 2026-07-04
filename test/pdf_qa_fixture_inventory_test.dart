import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PDF QA fixture inventory covers world-class hardening areas', () {
    final file = File('test/fixtures/pdf_qa/fixture_pack_inventory.json');

    expect(file.existsSync(), isTrue);
    final inventory =
        jsonDecode(file.readAsStringSync()) as Map<String, Object?>;

    expect(inventory['schema'], 'pdf_qa_fixture_pack_inventory_v1');
    final backbone = inventory['sharedBackbone']! as Map<String, Object?>;
    expect(backbone['styleSource'], 'tool/receipt_qa_runner.dart');
    expect(
      backbone['reportingPolicy'],
      'use_shared_maintainiac_qa_reporting_when_available',
    );
    expect(backbone['privacyPolicy'], 'synthetic_or_redacted_only');
    expect(
      backbone['duplicatePolicy'],
      'do_not_create_pdf_specific_fake_users_hive_or_firebase_mirrors',
    );

    final suites = inventory['requiredSuites']! as Map<String, Object?>;
    expect(
      suites.keys,
      containsAll([
        'malformed_pdfs',
        'large_pdfs',
        'encrypted_pdfs',
        'image_only_pdfs',
        'text_layer_extraction',
        'rotated_and_cropped_pages',
        'import_ownership',
        'storage_cleanup',
        'privacy_and_security_logs',
        'pdf_to_receipt_review',
        'invoice_generation',
        'cross_platform_storage',
        'render_smoke',
      ]),
    );

    for (final entry in suites.entries) {
      final suite = entry.value! as Map<String, Object?>;
      expect(suite['status'], isA<String>(), reason: entry.key);
      expect(suite['status'], isNot('partial'), reason: entry.key);
      final testFiles = suite['currentTestFiles']! as List<Object?>;
      expect(testFiles, isNotEmpty, reason: entry.key);
      for (final path in testFiles.cast<String>()) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
      expect(
        suite['fixtureKeys'] as List<Object?>,
        isNotEmpty,
        reason: entry.key,
      );
    }

    final serialized = jsonEncode(inventory).toLowerCase();
    expect(serialized, isNot(contains('cardnumber')));
    expect(serialized, isNot(contains('customername')));
    expect(serialized, isNot(contains('rawocrtext')));
    expect(serialized, isNot(contains('private@example.com')));
    expect(serialized, isNot(contains('service_pdf_security_test.dart')));
    expect(serialized, isNot(contains('service_pdf_inspector_test.dart')));
  });
}
