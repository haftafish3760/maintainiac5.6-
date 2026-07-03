import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/parser_qa_platform/parser_qa_platform.dart';
import 'support/qa_harness/qa_harness.dart';

void main() {
  group('parser QA platform reuse behavior', () {
    test('generic harness runs a non-inventory parser domain', () async {
      final harness = QaHarness(
        domain: 'synthetic_parser_domain',
        suites: const [_SyntheticParserSuite()],
      );

      final report = await harness.run(
        const QaContext(strict: false, redactor: QaRedactor()),
      );

      expect(report.domain, 'synthetic_parser_domain');
      expect(report.results, hasLength(1));
      expect(report.checked, 3);
      expect(report.failures, isEmpty);
      expect(report.adminHealth['domain'], 'synthetic_parser_domain');
      expect(report.adminHealth['status'], 'passing');
    });

    test(
      'domain adapters validate inventory and maintenance parser domains',
      () {
        expect(parserQaDomainAdapters.length, greaterThanOrEqualTo(2));
        for (final adapter in parserQaDomainAdapters) {
          expect(adapter.validateContract(), isEmpty, reason: adapter.domain);
          expect(adapter.toJson()['liveServicesAllowed'], isFalse);
          expect(adapter.toJson()['writesProductionCatalog'], isFalse);
          expect(adapter.toJson()['firebaseWritesAllowed'], isFalse);
          expect(adapter.supportedResultUses, isNotEmpty);
          expect(
            adapter.forbiddenBoundaryTokens.toSet().length,
            adapter.forbiddenBoundaryTokens.length,
          );
        }
      },
    );

    test('shared QA harness stays free of work-supply domain imports', () {
      final source = File(
        'test/support/qa_harness/qa_harness.dart',
      ).readAsStringSync().replaceAll('\\', '/');

      expect(source, contains('class QaHarness'));
      expect(source, contains('class QaSuite'));
      expect(source, contains('class QaReport'));
      expect(source, contains('class QaRedactor'));
      expect(source, isNot(contains('screens/work_supplies')));
      expect(source, isNot(contains('work_supply_')));
    });

    test('report serialization redacts private parser evidence', () {
      const redactor = QaRedactor();
      const failure = QaFailure(
        suite: 'synthetic.parser_privacy',
        id: 'private_evidence_is_redacted',
        message: 'customer Jane Smith paid card ending 1234 receipt #ABC123',
        actual:
            'raw receipt customer Jane Smith 123 Main Street card 4111111111111111',
        metadata: {
          'rawReceiptText': 'customer Jane Smith 123 Main Street',
          'customerEmail': 'jane@example.com',
          'deviceModel': 'Galaxy S24 Ultra',
        },
      );

      final json = failure.toJson(redactor: redactor);

      expect(json.toString(), isNot(contains('Jane Smith')));
      expect(json.toString(), isNot(contains('jane@example.com')));
      expect(json.toString(), isNot(contains('123 Main Street')));
      expect(json.toString(), isNot(contains('4111111111111111')));
      expect(json.toString(), contains('[REDACTED_PRIVATE_FIELD]'));
      expect(json.toString(), contains('Galaxy S24 Ultra'));
    });

    test('failure triage covers parser platform release categories', () {
      final cases = {
        'dangerous pvc generic conflict': QaFailureTriage.conflict,
        'alias collision': QaFailureTriage.alias,
        'merchant sku rule missing': QaFailureTriage.merchantRule,
        'Spanish locale failed': QaFailureTriage.locale,
        'Firebase network token found': QaFailureTriage.security,
        'receipt privacy leaked': QaFailureTriage.privacy,
        'tax total cost allocation': QaFailureTriage.economics,
        'review_status auto_save': QaFailureTriage.reviewSafety,
      };

      for (final entry in cases.entries) {
        expect(
          QaFailureTriage.classify(
            suite: 'synthetic',
            id: entry.key,
            message: entry.key,
          ),
          entry.value,
          reason: entry.key,
        );
      }
    });
  });
}

class _SyntheticParserSuite extends QaSuite {
  const _SyntheticParserSuite() : super('synthetic.parser_contract');

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    return timer.finish(
      suite: name,
      checked: 3,
      failures: const [],
      metrics: const {
        'domainAgnostic': true,
        'reviewOnly': true,
        'localOnly': true,
      },
    );
  }
}
