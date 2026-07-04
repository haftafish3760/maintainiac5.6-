import 'invoice_ledger_models.dart';
import '../../../shared/pdf/app_generated_pdf_models.dart';

class InvoiceRecord {
  const InvoiceRecord({
    required this.id,
    required this.documentType,
    required this.invoiceNumber,
    required this.numberMode,
    required this.status,
    required this.issueDate,
    required this.meta,
    this.title = '',
    this.poNumber = '',
    this.dueDate,
    this.vehicleId = '',
    this.profileId = '',
    this.templateId = 'structured-logo',
    this.company = const InvoicePartySnapshot(),
    this.client = const InvoicePartySnapshot(),
    this.lines = const [],
    this.discount = const InvoiceDiscountRecord(),
    this.payments = const [],
    this.paymentMethod = '',
    this.terms = '',
    this.ownerSignature = InvoiceSignatureSnapshot.nullSnapshot,
    this.customerSignature = InvoiceSignatureSnapshot.nullSnapshot,
    this.documentHashSha256 = '',
    this.pdfEvents = const [],
    this.auditEvents = const [],
  });

  factory InvoiceRecord.fromMap(Map<dynamic, dynamic> map) {
    return InvoiceRecord(
      id: map['id'] as String? ?? '',
      documentType: _enumByName(
        InvoiceDocumentType.values,
        map['documentType'],
        InvoiceDocumentType.invoice,
      ),
      invoiceNumber: map['invoiceNumber'] as String? ?? '',
      numberMode: _enumByName(
        InvoiceNumberMode.values,
        map['numberMode'],
        InvoiceNumberMode.automatic,
      ),
      status: _enumByName(
        InvoiceRecordStatus.values,
        map['status'],
        InvoiceRecordStatus.draft,
      ),
      title: map['title'] as String? ?? '',
      poNumber: map['poNumber'] as String? ?? '',
      issueDate: _dateValue(map['issueDate']) ?? DateTime.now(),
      dueDate: _dateValue(map['dueDate']),
      vehicleId: map['vehicleId'] as String? ?? '',
      profileId: map['profileId'] as String? ?? '',
      templateId: map['templateId'] as String? ?? 'structured-logo',
      company: InvoicePartySnapshot.fromMap(map['company'] as Map?),
      client: InvoicePartySnapshot.fromMap(map['client'] as Map?),
      lines: _listOfMaps(
        map['lines'],
      ).map(InvoiceLineItemRecord.fromMap).toList(growable: false),
      discount: InvoiceDiscountRecord.fromMap(map['discount'] as Map?),
      payments: _listOfMaps(
        map['payments'],
      ).map(InvoicePaymentRecord.fromMap).toList(growable: false),
      paymentMethod: map['paymentMethod'] as String? ?? '',
      terms: map['terms'] as String? ?? '',
      ownerSignature: InvoiceSignatureSnapshot.fromMap(
        map['ownerSignature'] as Map?,
      ),
      customerSignature: InvoiceSignatureSnapshot.fromMap(
        map['customerSignature'] as Map?,
      ),
      documentHashSha256: map['documentHashSha256'] as String? ?? '',
      pdfEvents: _listOfMaps(
        map['pdfEvents'],
      ).map(InvoicePdfDeliveryEvent.fromMap).toList(growable: false),
      auditEvents:
          (map['auditEvents'] as List?)?.whereType<String>().toList() ??
          const [],
      meta: InvoiceSyncMetadata.fromMap(map['meta'] as Map?),
    );
  }

  final String id;
  final InvoiceDocumentType documentType;
  final String invoiceNumber;
  final InvoiceNumberMode numberMode;
  final InvoiceRecordStatus status;
  final String title;
  final String poNumber;
  final DateTime issueDate;
  final DateTime? dueDate;
  final String vehicleId;
  final String profileId;
  final String templateId;
  final InvoicePartySnapshot company;
  final InvoicePartySnapshot client;
  final List<InvoiceLineItemRecord> lines;
  final InvoiceDiscountRecord discount;
  final List<InvoicePaymentRecord> payments;
  final String paymentMethod;
  final String terms;
  final InvoiceSignatureSnapshot ownerSignature;
  final InvoiceSignatureSnapshot customerSignature;
  final String documentHashSha256;
  final List<InvoicePdfDeliveryEvent> pdfEvents;
  final List<String> auditEvents;
  final InvoiceSyncMetadata meta;

  int get subtotalCents => lines.fold(
    0,
    (sum, line) =>
        sum +
        AppInvoiceMoney.lineSubtotalCents(
          quantity: line.quantity,
          unitPrice: line.unitPrice,
        ),
  );
  int get discountAmountCents => AppInvoiceMoney.discountCents(
    type: discount.type,
    value: discount.value,
    subtotalCents: subtotalCents,
  );
  int get taxableSubtotalCents => subtotalCents - discountAmountCents;
  int get taxTotalCents => lines.fold(
    0,
    (sum, line) =>
        sum +
        (line.taxable
            ? AppInvoiceMoney.taxCents(
                subtotalCents: AppInvoiceMoney.lineSubtotalCents(
                  quantity: line.quantity,
                  unitPrice: line.unitPrice,
                ),
                taxRate: line.taxRate,
              )
            : 0),
  );
  int get totalCents => taxableSubtotalCents + taxTotalCents;
  int get paidTotalCents =>
      AppInvoiceMoney.sumCents(payments.map((payment) => payment.amount));
  int get balanceDueCents => totalCents - paidTotalCents;
  double get subtotal => AppInvoiceMoney.toDouble(subtotalCents);
  double get discountAmount => AppInvoiceMoney.toDouble(discountAmountCents);
  double get taxableSubtotal => AppInvoiceMoney.toDouble(taxableSubtotalCents);
  double get taxTotal => AppInvoiceMoney.toDouble(taxTotalCents);
  double get total => AppInvoiceMoney.toDouble(totalCents);
  double get paidTotal => AppInvoiceMoney.toDouble(paidTotalCents);
  double get balanceDue => AppInvoiceMoney.toDouble(balanceDueCents);
  bool get dirty => meta.dirty;
  bool get isInvoice => documentType == InvoiceDocumentType.invoice;
  bool get isEstimate => documentType == InvoiceDocumentType.estimate;

  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    if (client.bestName.isNotEmpty) return client.bestName;
    return invoiceNumber;
  }

  InvoiceRecord copyWith({
    String? id,
    InvoiceDocumentType? documentType,
    String? invoiceNumber,
    InvoiceNumberMode? numberMode,
    InvoiceRecordStatus? status,
    String? title,
    String? poNumber,
    DateTime? issueDate,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? vehicleId,
    String? profileId,
    String? templateId,
    InvoicePartySnapshot? company,
    InvoicePartySnapshot? client,
    List<InvoiceLineItemRecord>? lines,
    InvoiceDiscountRecord? discount,
    List<InvoicePaymentRecord>? payments,
    String? paymentMethod,
    String? terms,
    InvoiceSignatureSnapshot? ownerSignature,
    InvoiceSignatureSnapshot? customerSignature,
    String? documentHashSha256,
    List<InvoicePdfDeliveryEvent>? pdfEvents,
    List<String>? auditEvents,
    InvoiceSyncMetadata? meta,
  }) {
    return InvoiceRecord(
      id: id ?? this.id,
      documentType: documentType ?? this.documentType,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      numberMode: numberMode ?? this.numberMode,
      status: status ?? this.status,
      title: title ?? this.title,
      poNumber: poNumber ?? this.poNumber,
      issueDate: issueDate ?? this.issueDate,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      vehicleId: vehicleId ?? this.vehicleId,
      profileId: profileId ?? this.profileId,
      templateId: templateId ?? this.templateId,
      company: company ?? this.company,
      client: client ?? this.client,
      lines: lines ?? this.lines,
      discount: discount ?? this.discount,
      payments: payments ?? this.payments,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      terms: terms ?? this.terms,
      ownerSignature: ownerSignature ?? this.ownerSignature,
      customerSignature: customerSignature ?? this.customerSignature,
      documentHashSha256: documentHashSha256 ?? this.documentHashSha256,
      pdfEvents: pdfEvents ?? this.pdfEvents,
      auditEvents: auditEvents ?? this.auditEvents,
      meta: meta ?? this.meta,
    );
  }

  InvoiceRecord recordPdfGenerated(
    AppGeneratedPdfDocument document, {
    DateTime? at,
    String fileHashSha256 = '',
  }) {
    return _withPdfEvent(
      InvoicePdfDeliveryEvent.generatedFrom(
        document,
        at: at,
        fileHashSha256: fileHashSha256,
      ),
    );
  }

  InvoiceRecord recordPdfPreviewed(
    AppGeneratedPdfDocument document, {
    DateTime? at,
  }) {
    return _withPdfEvent(InvoicePdfDeliveryEvent.previewed(document, at: at));
  }

  InvoiceRecord recordPdfArchived({
    required String pdfKind,
    required String fileName,
    required int byteSize,
    required String fileHashSha256,
    DateTime? at,
  }) {
    return _withPdfEvent(
      InvoicePdfDeliveryEvent.archived(
        sourceRecordId: id,
        pdfKind: pdfKind,
        fileName: fileName,
        byteSize: byteSize,
        fileHashSha256: fileHashSha256,
        at: at,
      ),
    );
  }

  InvoiceRecord recordPdfShared({
    String pdfKind = '',
    String fileName = '',
    int byteSize = 0,
    DateTime? at,
  }) {
    return _withPdfEvent(
      InvoicePdfDeliveryEvent.action(
        type: InvoicePdfDeliveryEventType.shared,
        sourceRecordId: id,
        pdfKind: pdfKind.isEmpty ? documentType.name : pdfKind,
        fileName: fileName,
        byteSize: byteSize,
        at: at,
      ),
    );
  }

  InvoiceRecord recordPdfPrinted({
    String pdfKind = '',
    String fileName = '',
    int byteSize = 0,
    DateTime? at,
  }) {
    return _withPdfEvent(
      InvoicePdfDeliveryEvent.action(
        type: InvoicePdfDeliveryEventType.printed,
        sourceRecordId: id,
        pdfKind: pdfKind.isEmpty ? documentType.name : pdfKind,
        fileName: fileName,
        byteSize: byteSize,
        at: at,
      ),
    );
  }

  InvoiceRecord recordPdfDeliveryCancelled({
    required String reasonCode,
    String pdfKind = '',
    String fileName = '',
    int byteSize = 0,
    DateTime? at,
  }) {
    return _withPdfEvent(
      InvoicePdfDeliveryEvent.cancelled(
        sourceRecordId: id,
        pdfKind: pdfKind.isEmpty ? documentType.name : pdfKind,
        fileName: fileName,
        byteSize: byteSize,
        reasonCode: reasonCode,
        at: at,
      ),
    );
  }

  InvoiceRecord recordPdfDeliveryFailed({
    required String reasonCode,
    String pdfKind = '',
    String fileName = '',
    DateTime? at,
  }) {
    return _withPdfEvent(
      InvoicePdfDeliveryEvent.failed(
        sourceRecordId: id,
        pdfKind: pdfKind.isEmpty ? documentType.name : pdfKind,
        fileName: fileName,
        reasonCode: reasonCode,
        at: at,
      ),
    );
  }

  InvoiceRecord _withPdfEvent(InvoicePdfDeliveryEvent event) {
    final nextEvents = [...pdfEvents, event];
    final boundedEvents =
        nextEvents.length <= invoicePdfDeliveryEventHistoryLimit
        ? nextEvents
        : nextEvents.sublist(
            nextEvents.length - invoicePdfDeliveryEventHistoryLimit,
          );
    return copyWith(
      documentHashSha256: event.hasFileHash
          ? event.fileHashSha256
          : documentHashSha256,
      pdfEvents: boundedEvents,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentType': documentType.name,
      'invoiceNumber': invoiceNumber,
      'numberMode': numberMode.name,
      'status': status.name,
      'title': title,
      'poNumber': poNumber,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'vehicleId': vehicleId,
      'profileId': profileId,
      'templateId': templateId,
      'company': company.toMap(),
      'client': client.toMap(),
      'lines': [for (final line in lines) line.toMap()],
      'discount': discount.toMap(),
      'payments': [for (final payment in payments) payment.toMap()],
      'paymentMethod': paymentMethod,
      'terms': terms,
      'ownerSignature': ownerSignature.toMap(),
      'customerSignature': customerSignature.toMap(),
      'documentHashSha256': documentHashSha256,
      'pdfEvents': [for (final event in pdfEvents) event.toMap()],
      'auditEvents': auditEvents,
      'meta': meta.toMap(),
    };
  }
}

List<Map<dynamic, dynamic>> _listOfMaps(Object? value) {
  return (value as List?)?.whereType<Map>().toList(growable: false) ?? const [];
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  return values.firstWhere(
    (value) => value.name == name,
    orElse: () => fallback,
  );
}

DateTime? _dateValue(Object? value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}
