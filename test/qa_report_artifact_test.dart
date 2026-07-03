import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test(
    'writeQaReport creates redacted timestamped and latest artifacts',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'parser_qa_report_',
      );
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });

      final report = QaReport(
        domain: 'artifact_probe',
        strict: false,
        results: const [
          QaSuiteResult(
            name: 'inventory.security_privacy',
            duration: Duration(milliseconds: 4),
            checked: 1,
            failures: [
              QaFailure(
                suite: 'inventory.security_privacy',
                id: 'privacy_probe',
                message: 'private receipt data must be redacted',
                actual:
                    'RECEIPT #ABC123 card 4111111111111111 '
                    'VISA 1234 phone 804-555-1212 '
                    'email john.contractor@example.com 123 Main Street',
                metadata: {
                  'rawReceiptLine': 'RECEIPT #ABC123 customer John Contractor',
                  'customerName': 'John Contractor',
                  'customerEmail': 'john.contractor@example.com',
                  'customerAddress': '123 Main Street',
                  'cardLast4': '1234',
                  'nested': {'payment': 'VISA 1234', 'phone': '804-555-1212'},
                },
              ),
            ],
          ),
        ],
        startedAt: DateTime(2026, 1, 2, 3, 4, 5),
        duration: const Duration(milliseconds: 5),
        runConfig: const QaRunConfig(
          profile: 'smoke',
          preset: 'quick',
          maxGeneratedCases: 100,
        ),
      );

      final artifact = await writeQaReport(
        report: report,
        outputDirectory: directory.path,
      );

      final timestamped = File(artifact.timestampedJsonPath);
      final latestJson = File(artifact.latestJsonPath);
      final latestSummary = File(artifact.latestSummaryPath);
      final packHealthJson = File(artifact.timestampedPackHealthJsonPath);
      final latestPackHealthJson = File(artifact.latestPackHealthJsonPath);

      expect(timestamped.existsSync(), isTrue);
      expect(latestJson.existsSync(), isTrue);
      expect(latestSummary.existsSync(), isTrue);
      expect(packHealthJson.existsSync(), isTrue);
      expect(latestPackHealthJson.existsSync(), isTrue);
      expect(artifact.timestampedJsonPath, isNot(artifact.latestJsonPath));
      expect(
        artifact.timestampedPackHealthJsonPath,
        isNot(artifact.latestPackHealthJsonPath),
      );
      expect(timestamped.readAsStringSync(), latestJson.readAsStringSync());
      expect(
        packHealthJson.readAsStringSync(),
        latestPackHealthJson.readAsStringSync(),
      );

      final decoded = jsonDecode(latestJson.readAsStringSync()) as Map;
      final packHealth =
          jsonDecode(latestPackHealthJson.readAsStringSync()) as Map;
      final summary = latestSummary.readAsStringSync();

      expect(decoded['runConfig'], isA<Map>());
      expect(decoded['packHealth'], isA<Map>());
      expect(decoded['adminHealth'], isA<Map>());
      expect(decoded['adminHealth']['status'], 'blocked');
      expect(decoded['adminHealth']['blockingFailureCount'], 1);
      expect(packHealth['healthScore'], isA<num>());
      expect(packHealth['readinessLabel'], isA<String>());
      expect(summary, contains('QA_RUN_CONFIG'));
      expect(summary, contains('QA_PACK_HEALTH'));
      expect(summary, contains('QA_ADMIN_HEALTH'));
      final jsonContent = latestJson.readAsStringSync();
      expect(jsonContent, contains('[REDACTED_PRIVATE_FIELD]'));
      expect(jsonContent, contains('[REDACTED_PRIVATE_VALUE]'));
      for (final content in [jsonContent, summary]) {
        expect(content, contains('[REDACTED_RECEIPT_ID]'));
        expect(content, contains('[REDACTED_CARD_LIKE_NUMBER]'));
        expect(content, contains('[REDACTED_CARD_LAST4]'));
        expect(content, contains('[REDACTED_PHONE]'));
        expect(content, contains('[REDACTED_EMAIL]'));
        expect(content, contains('[REDACTED_ADDRESS]'));
        expect(content, isNot(contains('ABC123')));
        expect(content, isNot(contains('4111111111111111')));
        expect(content, isNot(contains('1234')));
        expect(content, isNot(contains('804-555-1212')));
        expect(content, isNot(contains('John Contractor')));
        expect(content, isNot(contains('john.contractor@example.com')));
        expect(content, isNot(contains('123 Main Street')));
        expect(content, isNot(contains('VISA 1234')));
      }
    },
  );
}
