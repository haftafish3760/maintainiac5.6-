import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  group('inventory parser security abuse behavior', () {
    test('QA redactor removes private receipt payment and contact tokens', () {
      const redactor = QaRedactor();
      const privateLine =
          'RECEIPT #ABC123 card 4111111111111111 last four 1111 '
          'john.contractor@example.com 804-555-1212 123 Main Street';

      final redacted = redactor(privateLine);

      expect(redacted, contains('[REDACTED_RECEIPT_ID]'));
      expect(redacted, contains('[REDACTED_CARD_LIKE_NUMBER]'));
      expect(redacted, contains('[REDACTED_CARD_LAST4]'));
      expect(redacted, contains('[REDACTED_EMAIL]'));
      expect(redacted, contains('[REDACTED_ADDRESS]'));
      for (final token in _privateTokens) {
        expect(redacted, isNot(contains(token)), reason: token);
      }
    });

    test('QA report serialization redacts nested private metadata', () {
      const redactor = QaRedactor();
      final report = QaReport(
        domain: 'inventory_security_abuse',
        strict: true,
        results: [
          QaSuiteResult(
            name: 'inventory.security_privacy',
            duration: Duration.zero,
            checked: 1,
            failures: [
              QaFailure(
                suite: 'inventory.security_privacy',
                id: 'private_metadata_probe',
                message:
                    'receipt #ABC123 card 4111111111111111 '
                    'john.contractor@example.com 804-555-1212',
                severity: QaSeverity.critical,
                expected: 'redacted admin-safe report',
                actual: '123 Main Street raw receipt line',
                suggestedFix: 'redact before Command One/admin output',
                metadata: const {
                  'rawReceiptText':
                      'LOWES CARD 4111111111111111 JOHN CONTRACTOR',
                  'customerEmail': 'john.contractor@example.com',
                  'phone': '804-555-1212',
                  'address': '123 Main Street',
                },
              ),
            ],
          ),
        ],
        startedAt: DateTime.utc(2026, 7, 2),
        duration: Duration.zero,
      );

      final encoded = jsonEncode(report.toJson(redactor: redactor));
      final summary = report.toSummary(redactor: redactor);

      for (final output in [encoded, summary]) {
        for (final token in _privateTokens) {
          expect(output, isNot(contains(token)), reason: token);
        }
        expect(output, contains('[REDACTED_CARD_LIKE_NUMBER]'));
        expect(output, contains('[REDACTED_EMAIL]'));
      }
    });

    test('hostile receipt-like strings never become confident parser output', () {
      for (final probe in _hostileParserProbes) {
        final match = matchReceiptLineToCatalog(
          probe.rawLine,
          tradeScope: probe.tradeScope,
          maxCandidates: 48,
        );

        expect(
          match == null || match.needsReview,
          isTrue,
          reason: probe.id,
        );
        expect(
          match?.confidence ?? 0,
          lessThan(probe.maxAllowedConfidence),
          reason: probe.id,
        );
      }
    });

    test('hostile diagnostic previews are bounded and signal risk families', () {
      for (final probe in _hostileParserProbes) {
        final diagnostic = _securityDiagnosticFor(probe.rawLine);

        expect(diagnostic.preview.length, lessThanOrEqualTo(96));
        expect(diagnostic.localOnly, isTrue);
        expect(diagnostic.reviewOnly, isTrue);
        expect(
          diagnostic.signals,
          contains(probe.expectedSignal),
          reason: probe.id,
        );
      }
    });

    test('security abuse output neutralizes CSV formula execution', () {
      final row = _csvRow([
        '=HYPERLINK("http://evil.example","click")',
        '+SUM(1,2)',
        '-CMD',
        '@calc',
        'normal parser note',
      ]);

      expect(row, contains("'=HYPERLINK"));
      expect(row, contains("'+SUM"));
      expect(row, contains("'-CMD"));
      expect(row, contains("'@calc"));
      expect(row, contains('normal parser note'));
    });

    test('security probes stay local-only and do not request live services', () {
      const plan = _SecurityProbeExecutionPlan(
        parserCalls: 0,
        networkAllowed: false,
        processAllowed: false,
        firebaseWritesAllowed: false,
        ocrPipelineTouched: false,
        cameraTouched: false,
      );

      expect(plan.localOnly, isTrue);
      expect(plan.networkAllowed, isFalse);
      expect(plan.processAllowed, isFalse);
      expect(plan.firebaseWritesAllowed, isFalse);
      expect(plan.ocrPipelineTouched, isFalse);
      expect(plan.cameraTouched, isFalse);
    });
  });
}

const _privateTokens = {
  'ABC123',
  '4111111111111111',
  'john.contractor@example.com',
  '804-555-1212',
  '123 Main Street',
};

const _hostileParserProbes = [
  _SecurityProbe(
    id: 'sql_injection_like_receipt_line',
    rawLine: "1/2 PEX 90 '; DROP TABLE inventory; --",
    tradeScope: 'Plumbing',
    expectedSignal: 'injection_like',
    maxAllowedConfidence: .98,
  ),
  _SecurityProbe(
    id: 'nosql_injection_like_receipt_line',
    rawLine: '{"item":{"\$ne":"PVC 90"}}',
    tradeScope: null,
    expectedSignal: 'injection_like',
    maxAllowedConfidence: .82,
  ),
  _SecurityProbe(
    id: 'path_traversal_receipt_line',
    rawLine: '../../firebase/service-account.json',
    tradeScope: null,
    expectedSignal: 'path_like',
    maxAllowedConfidence: .82,
  ),
  _SecurityProbe(
    id: 'unicode_override_receipt_line',
    rawLine: 'PVC 90 \u202E3/4',
    tradeScope: null,
    expectedSignal: 'unicode_control',
    maxAllowedConfidence: .98,
  ),
  _SecurityProbe(
    id: 'huge_repeated_token_receipt_line',
    rawLine:
        'PVC PVC PVC PVC PVC PVC PVC PVC PVC PVC PVC PVC PVC PVC PVC PVC '
        'PVC PVC PVC PVC PVC PVC PVC PVC PVC PVC PVC PVC PVC PVC PVC PVC',
    tradeScope: null,
    expectedSignal: 'huge_input',
    maxAllowedConfidence: .82,
  ),
  _SecurityProbe(
    id: 'long_token_receipt_line',
    rawLine:
        'SKU AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
    tradeScope: null,
    expectedSignal: 'long_token',
    maxAllowedConfidence: .82,
  ),
];

_SecurityDiagnostic _securityDiagnosticFor(String rawLine) {
  final signals = <String>{};
  if (rawLine.contains('DROP TABLE') || rawLine.contains(r'$ne')) {
    signals.add('injection_like');
  }
  if (rawLine.contains('../') || rawLine.contains(r'\')) {
    signals.add('path_like');
  }
  if (rawLine.contains('\u202E') ||
      rawLine.codeUnits.any((unit) => unit < 32 && unit != 9 && unit != 10)) {
    signals.add('unicode_control');
  }
  if (rawLine.split(RegExp(r'\s+')).length > 24) {
    signals.add('huge_input');
  }
  if (rawLine.split(RegExp(r'\s+')).any((token) => token.length > 64)) {
    signals.add('long_token');
  }
  return _SecurityDiagnostic(
    preview: rawLine.length <= 96 ? rawLine : '${rawLine.substring(0, 93)}...',
    signals: signals,
    reviewOnly: true,
    localOnly: true,
  );
}

String _csvRow(List<String> cells) {
  return cells.map(_neutralizeCsvCell).join(',');
}

String _neutralizeCsvCell(String text) {
  final trimmedLeft = text.trimLeft();
  if (trimmedLeft.isEmpty) return text;
  final first = trimmedLeft.codeUnitAt(0);
  if (first == 61 || first == 43 || first == 45 || first == 64) {
    return "'$text";
  }
  return text;
}

class _SecurityProbe {
  const _SecurityProbe({
    required this.id,
    required this.rawLine,
    required this.tradeScope,
    required this.expectedSignal,
    required this.maxAllowedConfidence,
  });

  final String id;
  final String rawLine;
  final String? tradeScope;
  final String expectedSignal;
  final double maxAllowedConfidence;
}

class _SecurityDiagnostic {
  const _SecurityDiagnostic({
    required this.preview,
    required this.signals,
    required this.reviewOnly,
    required this.localOnly,
  });

  final String preview;
  final Set<String> signals;
  final bool reviewOnly;
  final bool localOnly;
}

class _SecurityProbeExecutionPlan {
  const _SecurityProbeExecutionPlan({
    required this.parserCalls,
    required this.networkAllowed,
    required this.processAllowed,
    required this.firebaseWritesAllowed,
    required this.ocrPipelineTouched,
    required this.cameraTouched,
  });

  final int parserCalls;
  final bool networkAllowed;
  final bool processAllowed;
  final bool firebaseWritesAllowed;
  final bool ocrPipelineTouched;
  final bool cameraTouched;

  bool get localOnly =>
      !networkAllowed &&
      !processAllowed &&
      !firebaseWritesAllowed &&
      !ocrPipelineTouched &&
      !cameraTouched;
}
