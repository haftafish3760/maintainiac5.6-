enum MaintainiacPaymentKind { payment, refund, adjustment }

class MaintainiacPaymentRecord {
  const MaintainiacPaymentRecord({
    required this.id,
    required this.kind,
    required this.accountId,
    required this.invoiceId,
    required this.amountCents,
    required this.method,
    this.auditId = '',
    this.cardNumber = '',
    this.cardLast4 = '',
    this.mutatesInvoiceSource = false,
  });

  final String id;
  final MaintainiacPaymentKind kind;
  final String accountId;
  final String invoiceId;
  final int amountCents;
  final String method;
  final String auditId;
  final String cardNumber;
  final String cardLast4;
  final bool mutatesInvoiceSource;

  int get ledgerCents {
    return switch (kind) {
      MaintainiacPaymentKind.payment => amountCents,
      MaintainiacPaymentKind.refund => -amountCents,
      MaintainiacPaymentKind.adjustment => amountCents,
    };
  }

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('payment record missing id');
    if (accountId.trim().isEmpty) failures.add('$id missing account id');
    if (invoiceId.trim().isEmpty) failures.add('$id missing invoice id');
    if (kind != MaintainiacPaymentKind.adjustment && amountCents < 0) {
      failures.add('$id payment/refund amount must not be negative');
    }
    if (method.trim().isEmpty) failures.add('$id missing payment method');
    if (auditId.trim().isEmpty) failures.add('$id missing audit id');
    if (cardNumber.trim().isNotEmpty) {
      failures.add('$id must never store full card number');
    }
    if (cardLast4.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(cardLast4)) {
      failures.add('$id card last4 must be exactly four digits');
    }
    if (mutatesInvoiceSource) {
      failures.add('$id payment record must not mutate invoice source totals');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'accountId': accountId,
      'invoiceId': invoiceId,
      'amountCents': amountCents,
      'ledgerCents': ledgerCents,
      'method': method,
      if (auditId.isNotEmpty) 'auditId': auditId,
      if (cardLast4.isNotEmpty) 'cardLast4': cardLast4,
      'mutatesInvoiceSource': mutatesInvoiceSource,
    };
  }
}

class MaintainiacPaymentContract {
  const MaintainiacPaymentContract(this.records);

  final List<MaintainiacPaymentRecord> records;

  int paidTotalFor(String invoiceId) {
    return records
        .where((record) => record.invoiceId == invoiceId)
        .fold(0, (sum, record) => sum + record.ledgerCents);
  }

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    if (records.isEmpty) failures.add('payment contract has no records');
    for (final record in records) {
      if (!ids.add(record.id)) {
        failures.add('duplicate payment record id ${record.id}');
      }
      failures.addAll(record.validate());
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'recordCount': records.length,
      'records': [for (final record in records) record.toJson()],
    };
  }
}
