import 'package:flutter/material.dart';

import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../invoices/data/invoice_ledger_models.dart';
import '../../invoices/data/invoice_ledger_store.dart';
import '../../invoices/data/invoice_record.dart';
import '../../invoices/home/invoice_form_screen.dart';

class ContractorWeeklyPaymentsScreen extends StatefulWidget {
  const ContractorWeeklyPaymentsScreen({required this.anchorDate, super.key});

  final DateTime anchorDate;

  @override
  State<ContractorWeeklyPaymentsScreen> createState() =>
      _ContractorWeeklyPaymentsScreenState();
}

class _ContractorWeeklyPaymentsScreenState
    extends State<ContractorWeeklyPaymentsScreen> {
  late DateTime _anchorDate = _dateOnly(widget.anchorDate);

  @override
  Widget build(BuildContext context) {
    final ledger = InvoiceLedgerScope.of(context);
    final range = contractorPaymentWeekRange(_anchorDate);
    final payments = contractorPaymentsForWeek(ledger.records, _anchorDate);
    final total = payments.fold<double>(0, (sum, entry) => sum + entry.amount);
    return AppScreenShell(
      section: AppSection.invoices,
      pinnedHeader: const GlobalOdometerHeader(section: AppSection.invoices),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        children: [
          AppScreenHeader(
            title: 'Payments This Week',
            actions: [
              IconButton(
                tooltip: 'Previous week',
                onPressed: () => _shiftWeek(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Current week',
                onPressed: _showCurrentWeek,
                icon: const Icon(Icons.today_rounded),
              ),
              IconButton(
                tooltip: 'Next week',
                onPressed: () => _shiftWeek(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _PaymentWeekSummary(
            range: range,
            paymentCount: payments.length,
            total: total,
          ),
          const SizedBox(height: 8),
          if (payments.isEmpty)
            const _EmptyPaymentWeek()
          else
            for (var offset = 0; offset < 7; offset++) ...[
              if (_paymentsForDay(
                payments,
                range.start.add(Duration(days: offset)),
              ).isNotEmpty)
                _PaymentDayGroup(
                  day: range.start.add(Duration(days: offset)),
                  payments: _paymentsForDay(
                    payments,
                    range.start.add(Duration(days: offset)),
                  ),
                  onOpenInvoice: _openInvoice,
                ),
              if (offset < 6 &&
                  _paymentsForDay(
                    payments,
                    range.start.add(Duration(days: offset)),
                  ).isNotEmpty)
                const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  void _shiftWeek(int offset) {
    setState(() => _anchorDate = _anchorDate.add(Duration(days: offset * 7)));
  }

  void _showCurrentWeek() {
    setState(() => _anchorDate = _dateOnly(DateTime.now()));
  }

  void _openInvoice(String invoiceId) {
    Navigator.of(context).push(
      appNativeRoute<void>(context, InvoiceFormScreen(recordId: invoiceId)),
    );
  }
}

class ContractorPaymentWeekRange {
  const ContractorPaymentWeekRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class ContractorWeeklyPaymentEntry {
  const ContractorWeeklyPaymentEntry({
    required this.invoiceId,
    required this.invoiceLabel,
    required this.customerLabel,
    required this.amount,
    required this.paidAt,
    required this.method,
    required this.note,
  });

  final String invoiceId;
  final String invoiceLabel;
  final String customerLabel;
  final double amount;
  final DateTime paidAt;
  final String method;
  final String note;
}

ContractorPaymentWeekRange contractorPaymentWeekRange(DateTime anchorDate) {
  final day = _dateOnly(anchorDate);
  final start = day.subtract(Duration(days: day.weekday - DateTime.monday));
  return ContractorPaymentWeekRange(
    start: start,
    end: start.add(const Duration(days: 6)),
  );
}

List<ContractorWeeklyPaymentEntry> contractorPaymentsForWeek(
  List<InvoiceRecord> records,
  DateTime anchorDate,
) {
  final range = contractorPaymentWeekRange(anchorDate);
  final entries = <ContractorWeeklyPaymentEntry>[];
  for (final record in records) {
    if (!record.isInvoice ||
        record.status == InvoiceRecordStatus.voided ||
        record.meta.deletedAt != null) {
      continue;
    }
    for (final payment in record.payments) {
      final paidDay = _dateOnly(payment.paidAt);
      if (paidDay.isBefore(range.start) || paidDay.isAfter(range.end)) continue;
      entries.add(
        ContractorWeeklyPaymentEntry(
          invoiceId: record.id,
          invoiceLabel: record.invoiceNumber.trim().isEmpty
              ? 'Invoice'
              : 'Invoice ${record.invoiceNumber.trim()}',
          customerLabel: record.client.bestName.isEmpty
              ? record.displayTitle
              : record.client.bestName,
          amount: payment.amount,
          paidAt: payment.paidAt,
          method: payment.method,
          note: payment.note,
        ),
      );
    }
  }
  entries.sort((left, right) => right.paidAt.compareTo(left.paidAt));
  return entries;
}

class _PaymentWeekSummary extends StatelessWidget {
  const _PaymentWeekSummary({
    required this.range,
    required this.paymentCount,
    required this.total,
  });

  final ContractorPaymentWeekRange range;
  final int paymentCount;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: _panelDecoration(const Color(0xFF55D68A)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_shortDate(range.start)} - ${_shortDate(range.end)}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '$paymentCount ${paymentCount == 1 ? 'payment' : 'payments'} recorded',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _money(total),
            style: const TextStyle(
              color: Color(0xFF55D68A),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentDayGroup extends StatelessWidget {
  const _PaymentDayGroup({
    required this.day,
    required this.payments,
    required this.onOpenInvoice,
  });

  final DateTime day;
  final List<ContractorWeeklyPaymentEntry> payments;
  final ValueChanged<String> onOpenInvoice;

  @override
  Widget build(BuildContext context) {
    final dayTotal = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: _panelDecoration(const Color(0xFF4DA3FF)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_weekday(day)} - ${_shortDate(day)}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                _money(dayTotal),
                style: const TextStyle(
                  color: Color(0xFF55D68A),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF445159)),
          for (final payment in payments)
            _PaymentRow(
              payment: payment,
              onTap: () => onOpenInvoice(payment.invoiceId),
            ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment, required this.onTap});

  final ContractorWeeklyPaymentEntry payment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      payment.customerLabel,
      if (payment.method.trim().isNotEmpty) payment.method.trim(),
    ].where((value) => value.trim().isNotEmpty).join(' - ');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.payments_rounded, color: Color(0xFF55D68A)),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.invoiceLabel,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (details.isNotEmpty)
                      Text(details, style: const TextStyle(fontSize: 12)),
                    if (payment.note.trim().isNotEmpty)
                      Text(
                        payment.note.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                  ],
                ),
              ),
              Text(
                _money(payment.amount),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPaymentWeek extends StatelessWidget {
  const _EmptyPaymentWeek();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(const Color(0xFF59666C)),
      child: const Column(
        children: [
          Icon(Icons.payments_outlined, size: 34, color: Color(0xFF9EAAAF)),
          SizedBox(height: 7),
          Text(
            'No payments were recorded for this week.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 3),
          Text(
            'Payments linked to saved invoices will appear here by payment date.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

List<ContractorWeeklyPaymentEntry> _paymentsForDay(
  List<ContractorWeeklyPaymentEntry> payments,
  DateTime day,
) => payments
    .where((payment) => _dateOnly(payment.paidAt) == _dateOnly(day))
    .toList(growable: false);

BoxDecoration _panelDecoration(Color borderColor) => BoxDecoration(
  color: const Color(0xFF172023),
  borderRadius: BorderRadius.circular(7),
  border: Border.all(color: borderColor, width: 1.4),
);

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _money(double amount) => '\$${amount.toStringAsFixed(2)}';

String _shortDate(DateTime day) => '${day.month}/${day.day}/${day.year}';

String _weekday(DateTime day) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][day.weekday - 1];
