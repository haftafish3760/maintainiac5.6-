import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('payment contract balances payments refunds and adjustments', () {
    const contract = MaintainiacPaymentContract([
      MaintainiacPaymentRecord(
        id: 'payment_1',
        kind: MaintainiacPaymentKind.payment,
        accountId: 'acct_1',
        invoiceId: 'invoice_1',
        amountCents: 10000,
        method: 'card',
        auditId: 'AUD-PAY-0001',
        cardLast4: '4242',
      ),
      MaintainiacPaymentRecord(
        id: 'refund_1',
        kind: MaintainiacPaymentKind.refund,
        accountId: 'acct_1',
        invoiceId: 'invoice_1',
        amountCents: 1500,
        method: 'card',
        auditId: 'AUD-PAY-0002',
        cardLast4: '4242',
      ),
      MaintainiacPaymentRecord(
        id: 'adjustment_1',
        kind: MaintainiacPaymentKind.adjustment,
        accountId: 'acct_1',
        invoiceId: 'invoice_1',
        amountCents: -500,
        method: 'manual_adjustment',
        auditId: 'AUD-PAY-0003',
      ),
    ]);

    expect(contract.validate(), isEmpty);
    expect(contract.paidTotalFor('invoice_1'), 8000);
  });

  test(
    'payment contract allows audited positive payment and refund ledger math',
    () {
      const contract = MaintainiacPaymentContract([
        MaintainiacPaymentRecord(
          id: 'payment_1',
          kind: MaintainiacPaymentKind.payment,
          accountId: 'acct_1',
          invoiceId: 'invoice_1',
          amountCents: 10000,
          method: 'cash',
          auditId: 'AUD-PAY-0001',
        ),
        MaintainiacPaymentRecord(
          id: 'refund_1',
          kind: MaintainiacPaymentKind.refund,
          accountId: 'acct_1',
          invoiceId: 'invoice_1',
          amountCents: 1500,
          method: 'cash',
          auditId: 'AUD-PAY-0002',
        ),
      ]);

      expect(contract.validate(), isEmpty);
      expect(contract.paidTotalFor('invoice_1'), 8500);
      expect(contract.toJson().toString(), contains('ledgerCents'));
    },
  );

  test('payment contract rejects sensitive or source-mutating records', () {
    const contract = MaintainiacPaymentContract([
      MaintainiacPaymentRecord(
        id: 'bad_card',
        kind: MaintainiacPaymentKind.payment,
        accountId: 'acct_1',
        invoiceId: 'invoice_1',
        amountCents: 1000,
        method: 'card',
        auditId: 'AUD-PAY-0004',
        cardNumber: '4242424242424242',
      ),
      MaintainiacPaymentRecord(
        id: 'bad_last4',
        kind: MaintainiacPaymentKind.payment,
        accountId: 'acct_1',
        invoiceId: 'invoice_1',
        amountCents: 1000,
        method: 'card',
        auditId: 'AUD-PAY-0005',
        cardLast4: '42',
      ),
      MaintainiacPaymentRecord(
        id: 'bad_mutation',
        kind: MaintainiacPaymentKind.refund,
        accountId: 'acct_1',
        invoiceId: 'invoice_1',
        amountCents: 100,
        method: 'cash',
        auditId: '',
        mutatesInvoiceSource: true,
      ),
    ]);

    final failures = contract.validate().join('\n');

    expect(failures, contains('must never store full card number'));
    expect(failures, contains('card last4 must be exactly four digits'));
    expect(failures, contains('missing audit id'));
    expect(failures, contains('must not mutate invoice source totals'));
  });
}
