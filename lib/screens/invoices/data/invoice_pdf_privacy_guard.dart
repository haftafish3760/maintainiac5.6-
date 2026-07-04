import '../../../shared/pdf/app_pdf_privacy_policy.dart';
import 'invoice_ledger_models.dart';
import 'invoice_record.dart';

class InvoicePdfPrivacyException implements Exception {
  const InvoicePdfPrivacyException(this.issues);

  final List<String> issues;

  @override
  String toString() {
    return 'Invoice PDF export blocked for private fields: ${issues.join(', ')}';
  }
}

class InvoicePdfPrivacyGuard {
  const InvoicePdfPrivacyGuard._();

  static List<String> issueCodesForRecord(InvoiceRecord record) {
    return AppPdfPrivacyPolicy.issueCodesForExport(
      bytes: const [],
      metadata: _recordExportText(record),
    );
  }

  static void ensureRecordCanExport(InvoiceRecord record) {
    final issues = issueCodesForRecord(record);
    if (issues.isEmpty) return;
    throw InvoicePdfPrivacyException(issues);
  }

  static Iterable<String> _recordExportText(InvoiceRecord record) sync* {
    yield record.title;
    yield record.invoiceNumber;
    yield record.poNumber;
    yield record.paymentMethod;
    yield record.terms;
    yield* _partyText(record.company);
    yield* _partyText(record.client);
    for (final line in record.lines) {
      yield line.name;
      yield line.details;
      yield line.unit;
    }
    for (final payment in record.payments) {
      yield payment.method;
      yield payment.note;
    }
  }

  static Iterable<String> _partyText(InvoicePartySnapshot party) sync* {
    yield party.displayName;
    yield party.companyName;
    yield party.street;
    yield party.city;
    yield party.state;
    yield party.postalCode;
    yield party.phone;
    yield party.email;
    yield party.website;
    yield party.notes;
    for (final phone in party.phones) {
      yield phone.type;
      yield phone.number;
    }
  }
}
