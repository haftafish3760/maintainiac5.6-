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

  test(
    'payment ledger policy proves invoice balance without source mutation',
    () {
      const policy = MaintainiacPaymentLedgerPolicy([
        MaintainiacInvoicePaymentSnapshot(
          invoiceId: 'invoice_1',
          accountId: 'acct_1',
          invoiceTotalCents: 10000,
          expectedBalanceDueCents: 1500,
          records: [
            MaintainiacPaymentRecord(
              id: 'payment_1',
              kind: MaintainiacPaymentKind.payment,
              accountId: 'acct_1',
              invoiceId: 'invoice_1',
              amountCents: 10000,
              method: 'card',
              auditId: 'AUD-PAY-0001',
            ),
            MaintainiacPaymentRecord(
              id: 'refund_1',
              kind: MaintainiacPaymentKind.refund,
              accountId: 'acct_1',
              invoiceId: 'invoice_1',
              amountCents: 1500,
              method: 'card',
              auditId: 'AUD-PAY-0002',
            ),
          ],
        ),
      ]);

      expect(policy.validate(), isEmpty);
      expect(policy.toJson().toString(), contains('balanceDueCents'));
    },
  );

  test('payment ledger policy rejects cross-account and overpay risks', () {
    const policy = MaintainiacPaymentLedgerPolicy([
      MaintainiacInvoicePaymentSnapshot(
        invoiceId: 'invoice_bad',
        accountId: 'acct_1',
        invoiceTotalCents: 1000,
        expectedBalanceDueCents: 0,
        records: [
          MaintainiacPaymentRecord(
            id: 'cross_account_payment',
            kind: MaintainiacPaymentKind.payment,
            accountId: 'acct_2',
            invoiceId: 'invoice_other',
            amountCents: 2000,
            method: 'cash',
            auditId: 'AUD-PAY-0006',
          ),
          MaintainiacPaymentRecord(
            id: 'refund_without_enough_payment',
            kind: MaintainiacPaymentKind.refund,
            accountId: 'acct_1',
            invoiceId: 'invoice_bad',
            amountCents: 3000,
            method: 'cash',
            auditId: 'AUD-PAY-0007',
          ),
        ],
      ),
    ]);

    final failures = policy.validate().join('\n');

    expect(failures, contains('does not match computed balance'));
    expect(failures, contains('belongs to a different invoice'));
    expect(failures, contains('belongs to a different account'));
    expect(failures, contains('refunds cannot exceed captured payments'));
  });
}
