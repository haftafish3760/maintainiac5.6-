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

enum MaintainiacPaymentSettlementStatus {
  open,
  paidInFull,
  overpaidNeedsReview,
}

class MaintainiacInvoicePaymentSnapshot {
  const MaintainiacInvoicePaymentSnapshot({
    required this.invoiceId,
    required this.accountId,
    required this.invoiceTotalCents,
    required this.records,
    required this.expectedBalanceDueCents,
    this.allowOverpayment = false,
  });

  final String invoiceId;
  final String accountId;
  final int invoiceTotalCents;
  final List<MaintainiacPaymentRecord> records;
  final int expectedBalanceDueCents;
  final bool allowOverpayment;

  int get paidCents {
    return records.fold(0, (sum, record) => sum + record.ledgerCents);
  }

  int get balanceDueCents => invoiceTotalCents - paidCents;

  int get grossPaymentCents {
    return records
        .where((record) => record.kind == MaintainiacPaymentKind.payment)
        .fold(0, (sum, record) => sum + record.amountCents);
  }

  int get grossRefundCents {
    return records
        .where((record) => record.kind == MaintainiacPaymentKind.refund)
        .fold(0, (sum, record) => sum + record.amountCents);
  }

  MaintainiacPaymentSettlementStatus get status {
    if (balanceDueCents < 0) {
      return MaintainiacPaymentSettlementStatus.overpaidNeedsReview;
    }
    if (balanceDueCents == 0) {
      return MaintainiacPaymentSettlementStatus.paidInFull;
    }
    return MaintainiacPaymentSettlementStatus.open;
  }

  List<String> validate() {
    final failures = <String>[];
    if (invoiceId.trim().isEmpty) {
      failures.add('payment snapshot missing invoice id');
    }
    if (accountId.trim().isEmpty) failures.add('$invoiceId missing account id');
    if (invoiceTotalCents < 0) {
      failures.add('$invoiceId invoice total cannot be negative');
    }
    if (expectedBalanceDueCents != balanceDueCents) {
      failures.add(
        '$invoiceId expected balance $expectedBalanceDueCents '
        'does not match computed balance $balanceDueCents',
      );
    }
    if (grossRefundCents > grossPaymentCents) {
      failures.add('$invoiceId refunds cannot exceed captured payments');
    }
    if (status == MaintainiacPaymentSettlementStatus.overpaidNeedsReview &&
        !allowOverpayment) {
      failures.add('$invoiceId overpayment requires explicit review');
    }
    for (final record in records) {
      if (record.invoiceId != invoiceId) {
        failures.add('${record.id} belongs to a different invoice');
      }
      if (record.accountId != accountId) {
        failures.add('${record.id} belongs to a different account');
      }
      failures.addAll(record.validate());
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'invoiceId': invoiceId,
      'accountId': accountId,
      'invoiceTotalCents': invoiceTotalCents,
      'paidCents': paidCents,
      'balanceDueCents': balanceDueCents,
      'expectedBalanceDueCents': expectedBalanceDueCents,
      'status': status.name,
      'allowOverpayment': allowOverpayment,
      'recordCount': records.length,
      'recordIds': [for (final record in records) record.id],
    };
  }
}

class MaintainiacPaymentLedgerPolicy {
  const MaintainiacPaymentLedgerPolicy(this.snapshots);

  final List<MaintainiacInvoicePaymentSnapshot> snapshots;

  List<String> validate() {
    final failures = <String>[];
    final invoiceIds = <String>{};
    if (snapshots.isEmpty) {
      failures.add('payment ledger policy has no snapshots');
    }
    for (final snapshot in snapshots) {
      if (!invoiceIds.add(snapshot.invoiceId)) {
        failures.add('duplicate payment snapshot ${snapshot.invoiceId}');
      }
      failures.addAll(snapshot.validate());
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'snapshotCount': snapshots.length,
      'snapshots': [for (final snapshot in snapshots) snapshot.toJson()],
    };
  }
}
