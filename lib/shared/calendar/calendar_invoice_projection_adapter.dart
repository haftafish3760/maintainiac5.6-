// Invoice calendar projection. Invoice Ledger owns all financial records;
// this adapter makes read-only invoice, estimate, and payment events.

import '../../screens/invoices/data/invoice_ledger_models.dart';
import '../../screens/invoices/data/invoice_record.dart';
import 'calendar_projection_contract.dart';

class CalendarInvoiceProjectionAdapter {
  const CalendarInvoiceProjectionAdapter._();

  static Iterable<CalendarProjectionEvent> eventsForDay(
    Iterable<InvoiceRecord> records,
    DateTime day,
  ) sync* {
    for (final record in records) {
      if (_sameDay(record.issueDate, day)) {
        yield _documentEvent(record);
      }
      for (final payment in record.payments) {
        if (_sameDay(payment.paidAt, day)) {
          yield _paymentEvent(record, payment);
        }
      }
    }
  }

  static CalendarProjectionEvent _documentEvent(InvoiceRecord record) {
    final isEstimate = record.documentType == InvoiceDocumentType.estimate;
    return CalendarProjectionEvent(
      eventId: '${isEstimate ? 'estimate' : 'invoice'}:${record.id}',
      source: isEstimate
          ? CalendarProjectionSource.estimate
          : CalendarProjectionSource.invoice,
      sourceRecordId: record.id,
      timing: CalendarProjectionTiming(
        eventDate: record.issueDate,
        recordedAt: record.meta.updatedAt,
        timeSource: CalendarTimeSource.unknown,
      ),
      title: record.displayTitle,
      conciseDetail:
          '${isEstimate ? 'Estimate' : 'Invoice'} ${record.invoiceNumber} · ${_money(record.total)}',
      state: _documentState(record.status),
      sourceRecordStatus: record.status.name,
      revision: record.meta.updatedAt.millisecondsSinceEpoch,
      vehicleIds: record.vehicleId.isEmpty ? const [] : [record.vehicleId],
      workProfileId: record.profileId.isEmpty ? null : record.profileId,
      evidence: CalendarProjectionEvidence(
        summary: record.dueDate == null
            ? null
            : 'Due ${_dateLabel(record.dueDate!)}',
        explanation:
            'Created ${_dateLabel(record.meta.createdAt)}; last updated '
            '${_dateLabel(record.meta.updatedAt)}.',
      ),
      deepLink: CalendarProjectionDeepLink(
        target: isEstimate
            ? CalendarDeepLinkTarget.estimateDetail
            : CalendarDeepLinkTarget.invoiceDetail,
        sourceRecordId: record.id,
      ),
    );
  }

  static CalendarProjectionEvent _paymentEvent(
    InvoiceRecord record,
    InvoicePaymentRecord payment,
  ) => CalendarProjectionEvent(
    eventId: 'payment:${record.id}:${payment.id}',
    source: CalendarProjectionSource.payment,
    sourceRecordId: record.id,
    timing: CalendarProjectionTiming(
      eventDate: payment.paidAt,
      actualAt: payment.paidAt,
      recordedAt: record.meta.updatedAt,
      timeSource: CalendarTimeSource.actual,
    ),
    title: 'Payment · ${record.displayTitle}',
    conciseDetail: '${_money(payment.amount)}${_methodDetail(payment.method)}',
    state: record.status == InvoiceRecordStatus.voided
        ? CalendarProjectionState.voided
        : CalendarProjectionState.confirmed,
    sourceRecordStatus: record.status.name,
    revision: record.meta.updatedAt.millisecondsSinceEpoch,
    vehicleIds: record.vehicleId.isEmpty ? const [] : [record.vehicleId],
    workProfileId: record.profileId.isEmpty ? null : record.profileId,
    evidence: CalendarProjectionEvidence(
      summary: payment.note.trim().isEmpty ? null : payment.note.trim(),
      explanation:
          'Invoice record last updated ${_dateLabel(record.meta.updatedAt)}.',
    ),
    deepLink: CalendarProjectionDeepLink(
      target: CalendarDeepLinkTarget.paymentDetail,
      sourceRecordId: record.id,
    ),
  );

  static CalendarProjectionState _documentState(InvoiceRecordStatus status) =>
      switch (status) {
        InvoiceRecordStatus.draft => CalendarProjectionState.incomplete,
        InvoiceRecordStatus.voided => CalendarProjectionState.voided,
        InvoiceRecordStatus.overdue => CalendarProjectionState.needsReview,
        InvoiceRecordStatus.convertedToInvoice =>
          CalendarProjectionState.historical,
        _ => CalendarProjectionState.confirmed,
      };
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

String _money(double value) => '\$${value.toStringAsFixed(2)}';

String _methodDetail(String method) =>
    method.trim().isEmpty ? '' : ' · ${method.trim()}';

String _dateLabel(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
