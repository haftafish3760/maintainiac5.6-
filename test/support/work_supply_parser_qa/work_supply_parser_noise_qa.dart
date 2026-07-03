import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReceiptNoiseSuite extends QaSuite {
  const WorkSupplyParserReceiptNoiseSuite() : super('inventory.noise_lines');

  static const _noiseLines = [
    'SUBTOTAL 142.17',
    'TOTAL 153.92',
    'SALES TAX 11.75',
    'TAX EXEMPT',
    'CASH 200.00',
    'CHANGE DUE 46.08',
    'CREDIT CARD',
    'VISA 1234 APPROVED',
    'MASTERCARD ENDING 9876',
    'AUTH 019283',
    'APPROVAL 456789',
    'TRANSACTION ID 00112233',
    'RECEIPT #ABC123',
    'THANK YOU FOR SHOPPING',
    'CUSTOMER COPY',
    'RETURN POLICY 90 DAYS',
    'SURVEY CODE 555 123 444',
    'PRO XTRA MEMBER',
    'MILITARY DISCOUNT',
    'PROMO SAVINGS',
    'INVOICE TOTAL',
    'BALANCE DUE',
    'ITEMS SOLD 14',
    'QTY SKU DESCRIPTION PRICE',
    'DEBIT US AID A0000000031010',
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];

    for (final line in _noiseLines) {
      final redacted = context.redactor(line);
      if (redacted.length > line.length + 32) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'noise_redaction_expanded:${_id(line)}',
            message: 'Receipt-noise redaction expanded the line unexpectedly.',
            expected: 'same length or shorter normalized text',
            actual: redacted,
            suggestedFix:
                'Keep noise/report redaction compact so diagnostics stay cheap and safe.',
          ),
        );
      }
    }

    if (context.isFullProfile) {
      for (final line in _noiseLines.take(context.maxGeneratedCases)) {
        final match = matchReceiptLineToCatalog(line, maxCandidates: 12);
        if (match == null) continue;
        failures.add(
          QaFailure(
            suite: name,
            id: 'noise_item_match:${_id(line)}',
            message: 'Receipt noise produced an inventory item candidate.',
            expected: 'unknown/no inventory candidate',
            actual:
                '${match.item.trade} / ${match.item.name} confidence=${match.confidence}',
            suggestedFix:
                'Filter receipt totals, payment, loyalty, auth, return, discount, and header/footer lines before item matching.',
          ),
        );
      }
    }

    return timer.finish(
      suite: name,
      checked:
          _noiseLines.length +
          (context.isFullProfile
              ? _noiseLines.take(context.maxGeneratedCases).length
              : 0),
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'noiseLineCount': _noiseLines.length,
        'parserCalls': context.isFullProfile
            ? _noiseLines.take(context.maxGeneratedCases).length
            : 0,
      },
    );
  }

  String _id(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
