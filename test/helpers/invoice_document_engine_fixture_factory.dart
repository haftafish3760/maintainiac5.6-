import 'package:maintaniac/screens/invoices/data/invoice_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_record.dart';
import 'package:maintaniac/screens/invoices/data/invoice_template_catalog.dart';

class InvoiceDocumentEngineFixtureFactory {
  const InvoiceDocumentEngineFixtureFactory._();

  static final DateTime fixedNow = DateTime(2026, 7, 4, 10, 30);

  static InvoiceRecord standardInvoice({
    String id = 'invoice-standard-fixture',
    String invoiceNumber = 'INV-QA-100',
    InvoiceTemplateDefinition? template,
    int lineCount = 12,
    InvoiceDocumentType documentType = InvoiceDocumentType.invoice,
    InvoiceDiscountRecord discount = const InvoiceDiscountRecord(
      type: InvoiceDiscountType.amount,
      value: 12.50,
    ),
    List<InvoicePaymentRecord>? payments,
  }) {
    return InvoiceRecord(
      id: id,
      documentType: documentType,
      invoiceNumber: invoiceNumber,
      numberMode: InvoiceNumberMode.automatic,
      status: InvoiceRecordStatus.draft,
      title: documentType == InvoiceDocumentType.estimate
          ? 'Confirmed Estimate Fixture'
          : 'Confirmed Invoice Fixture',
      issueDate: fixedNow,
      dueDate: fixedNow.add(const Duration(days: 30)),
      templateId:
          (template ?? InvoiceTemplateCatalog.byId('structured-logo')).id,
      company: contractorCompany(),
      client: customer(),
      lines: serviceLines(lineCount),
      discount: discount,
      payments:
          payments ??
          [
            InvoicePaymentRecord(
              id: 'payment-1',
              amount: 50,
              paidAt: fixedNow.add(const Duration(hours: 2)),
              method: 'Card',
            ),
          ],
      paymentMethod: 'Card',
      terms:
          'Payment due within 30 days. All values are confirmed by the user before PDF generation.',
      meta: InvoiceSyncMetadata(createdAt: fixedNow, updatedAt: fixedNow),
    );
  }

  static InvoiceRecord estimate({int lineCount = 10}) {
    return standardInvoice(
      id: 'estimate-fixture',
      invoiceNumber: 'EST-QA-100',
      lineCount: lineCount,
      documentType: InvoiceDocumentType.estimate,
      payments: const [],
      discount: const InvoiceDiscountRecord(
        type: InvoiceDiscountType.percent,
        value: 5,
      ),
    );
  }

  static InvoiceRecord missingOptionalFields() {
    return InvoiceRecord(
      id: 'invoice-missing-optional-fields',
      documentType: InvoiceDocumentType.invoice,
      invoiceNumber: 'INV-MISSING-001',
      numberMode: InvoiceNumberMode.automatic,
      status: InvoiceRecordStatus.draft,
      issueDate: fixedNow,
      company: const InvoicePartySnapshot(companyName: 'Maintainiac Repairs'),
      client: const InvoicePartySnapshot(displayName: 'Walk-up Customer'),
      lines: const [
        InvoiceLineItemRecord(
          id: 'labor',
          name: 'Service labor',
          details: '',
          quantity: 1,
          unit: '',
          unitPrice: 85,
          taxRate: 0,
          taxable: false,
        ),
      ],
      meta: InvoiceSyncMetadata(createdAt: fixedNow, updatedAt: fixedNow),
    );
  }

  static InvoiceRecord decimalsRefundsAndOverpayment() {
    return standardInvoice(
      id: 'invoice-decimals-refunds-overpayment',
      invoiceNumber: 'INV-QA-DECIMAL',
      lineCount: 0,
      discount: const InvoiceDiscountRecord(
        type: InvoiceDiscountType.amount,
        value: 1.005,
      ),
      payments: [
        InvoicePaymentRecord(
          id: 'payment-over',
          amount: 1000.005,
          paidAt: fixedNow,
          method: 'Card',
        ),
      ],
    ).copyWith(
      lines: const [
        InvoiceLineItemRecord(
          id: 'small-decimal',
          name: 'Small decimal material',
          details: 'Half-cent rounding probe',
          quantity: 3,
          unit: 'ea',
          unitPrice: 0.335,
          taxRate: 7.25,
        ),
        InvoiceLineItemRecord(
          id: 'labor-decimal',
          name: 'Decimal labor',
          details: 'Quarter hour labor billing',
          quantity: 2.25,
          unit: 'hr',
          unitPrice: 87.775,
          taxRate: 0,
          taxable: false,
        ),
        InvoiceLineItemRecord(
          id: 'refund-line',
          name: 'Returned customer part credit',
          details: 'Negative value should remain stable in totals',
          quantity: -1,
          unit: 'ea',
          unitPrice: 12.345,
          taxRate: 6.25,
        ),
      ],
    );
  }

  static InvoiceRecord longTextStress({int lineCount = 38}) {
    const longToken =
        'ConfirmedBusinessDocumentFieldWithNoNaturalBreaks1234567890'
        'ConfirmedBusinessDocumentFieldWithNoNaturalBreaks1234567890';
    return InvoiceRecord(
      id: 'invoice-long-text-fixture',
      documentType: InvoiceDocumentType.invoice,
      invoiceNumber: 'INV-$longToken',
      numberMode: InvoiceNumberMode.automatic,
      status: InvoiceRecordStatus.draft,
      title: 'Emergency repair $longToken',
      issueDate: fixedNow,
      dueDate: fixedNow.add(const Duration(days: 30)),
      company: const InvoicePartySnapshot(
        companyName: 'Maintainiac $longToken',
        street: '$longToken Service Plaza',
        city: 'Columbus',
        state: 'OH',
        postalCode: '43004',
        phone: '(555) 010-2409',
        email: '$longToken@example.com',
        website: '$longToken.example.com',
      ),
      client: const InvoicePartySnapshot(
        displayName: 'Customer $longToken',
        street: '$longToken Customer Way',
        city: 'Dayton',
        state: 'OH',
        postalCode: '45402',
        phone: '(555) 010-1017',
        email: 'customer.$longToken@example.com',
      ),
      lines: [
        for (var index = 1; index <= lineCount; index++)
          InvoiceLineItemRecord(
            id: 'long-text-line-$index',
            name: 'Line $index $longToken',
            details:
                'Confirmed labor, material handling, and job notes $longToken $longToken',
            quantity: index.isEven ? 1.5 : 2,
            unit: 'unit-$longToken',
            unitPrice: index.isEven ? 82.775 : 18.495,
            taxRate: index.isEven ? 0 : 6.25,
            taxable: !index.isEven,
          ),
      ],
      discount: const InvoiceDiscountRecord(
        type: InvoiceDiscountType.percent,
        value: 3.5,
      ),
      terms:
          'Payment due within 30 days. $longToken $longToken $longToken $longToken',
      meta: InvoiceSyncMetadata(createdAt: fixedNow, updatedAt: fixedNow),
    );
  }

  static InvoiceRecord hugeInvoice({int lineCount = 96}) {
    return standardInvoice(
      id: 'invoice-huge-fixture',
      invoiceNumber: 'INV-QA-HUGE',
      lineCount: lineCount,
      discount: const InvoiceDiscountRecord(
        type: InvoiceDiscountType.percent,
        value: 2.75,
      ),
    );
  }

  static InvoicePartySnapshot contractorCompany() {
    return const InvoicePartySnapshot(
      companyName: 'Maintainiac Field Services',
      displayName: 'Maintainiac Field Services',
      street: '100 Service Plaza',
      city: 'Columbus',
      state: 'OH',
      postalCode: '43004',
      phone: '(555) 010-2409',
      phones: [
        InvoicePhoneNumber(type: 'Office', number: '(555) 010-2409'),
        InvoicePhoneNumber(type: 'After Hours', number: '(555) 010-2410'),
      ],
      email: 'billing@example.com',
      website: 'maintainiac.example.com',
    );
  }

  static InvoicePartySnapshot customer() {
    return const InvoicePartySnapshot(
      displayName: 'Sample Customer',
      street: '42 Customer Way',
      city: 'Dayton',
      state: 'OH',
      postalCode: '45402',
      phone: '(555) 010-1017',
      email: 'customer@example.com',
    );
  }

  static List<InvoiceLineItemRecord> serviceLines(int count) {
    return [
      for (var index = 1; index <= count; index++)
        InvoiceLineItemRecord(
          id: 'service-line-$index',
          name: index.isEven
              ? 'Labor task $index'
              : 'Material and service item $index',
          details: index % 3 == 0
              ? 'Confirmed job notes, receipt backed materials, and technician observations for line $index'
              : 'Confirmed business document line $index',
          quantity: index.isEven ? 1.5 : 2,
          unit: index.isEven ? 'hr' : 'ea',
          unitPrice: index.isEven ? 82.75 : 18.49,
          taxRate: index.isEven ? 0 : 6.25,
          taxable: !index.isEven,
        ),
    ];
  }
}
