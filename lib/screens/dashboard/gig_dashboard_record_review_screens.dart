// Gig dashboard record-review destinations for payments and expense categories.
//
// Owns read-only, dashboard-launched summaries and routes users into the
// canonical receipt entry flow. Does not own ledger persistence, receipt
// editing, odometer truth, or payment creation. Consumed by Gig dashboard
// telemetry and shortcuts; records remain local-ledger source of truth.
import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../expenses/data/expense_ledger_models.dart';
import '../expenses/data/expense_ledger_store.dart';
import '../expenses/entry/expense_receipt_entry_screen.dart';
import '../invoices/data/invoice_ledger_models.dart';
import '../invoices/data/invoice_ledger_store.dart';
import '../invoices/home/invoice_info_screens.dart';

class GigExpenseCategoryBreakdownScreen extends StatelessWidget {
  const GigExpenseCategoryBreakdownScreen({
    super.key,
    this.category,
    this.startInclusive,
    this.endExclusive,
  });

  /// A null category intentionally means the all-expenses review.
  final String? category;
  final DateTime? startInclusive;
  final DateTime? endExclusive;

  @override
  Widget build(BuildContext context) {
    final normalizedCategory = category?.trim();
    final receipts =
        (ExpenseLedgerScope.maybeOf(context)?.receipts ?? const [])
            .where((receipt) => receipt.isActive)
            .where(
              (receipt) =>
                  normalizedCategory == null ||
                  normalizedCategory.isEmpty ||
                  receipt.lines.any(
                    (line) =>
                        line.category.trim().toLowerCase() ==
                        normalizedCategory.toLowerCase(),
                  ),
            )
            .where(
              (receipt) =>
                  (startInclusive == null ||
                      !receipt.receiptDate.isBefore(startInclusive!)) &&
                  (endExclusive == null ||
                      receipt.receiptDate.isBefore(endExclusive!)),
            )
            .toList(growable: false)
          ..sort((a, b) => b.sortDate.compareTo(a.sortDate));
    final totalCents = receipts.fold<int>(
      0,
      (sum, receipt) => sum + receipt.totalCents,
    );
    final title = normalizedCategory == null || normalizedCategory.isEmpty
        ? 'Expense Review'
        : '$normalizedCategory Review';
    return AppScreenShell(
      section: AppSection.expenses,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          appNativeRoute<void>(
            context,
            ExpenseReceiptEntryScreen(initialCategory: normalizedCategory),
          ),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add expense'),
      ),
      pinnedHeader: AppScreenHeader(title: title),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
        children: [
          _SummaryPanel(
            eyebrow: normalizedCategory == null || normalizedCategory.isEmpty
                ? 'ALL CATEGORIES'
                : 'CATEGORY TOTAL',
            value: _money(totalCents),
            detail:
                '${_rangeLabel()} · ${receipts.length} saved ${receipts.length == 1 ? 'receipt' : 'receipts'}',
            color: const Color(0xFFFFD166),
          ),
          const SizedBox(height: 12),
          if (receipts.isEmpty)
            const _EmptyRecords(
              title: 'No expenses recorded yet',
              detail: 'Use Add expense when you are ready to save one.',
            )
          else
            for (final receipt in receipts)
              _ExpenseReceiptRow(receipt: receipt),
        ],
      ),
    );
  }

  String _rangeLabel() => startInclusive == null && endExclusive == null
      ? 'All saved records'
      : 'Selected period';
}

class GigPaymentsReviewScreen extends StatelessWidget {
  const GigPaymentsReviewScreen({
    super.key,
    this.startInclusive,
    this.endExclusive,
  });

  final DateTime? startInclusive;
  final DateTime? endExclusive;

  @override
  Widget build(BuildContext context) {
    final records = InvoiceLedgerScope.maybeOf(context)?.records ?? const [];
    final payments = <_PaymentLine>[
      for (final record in records)
        if (record.isInvoice &&
            record.status != InvoiceRecordStatus.voided &&
            record.meta.deletedAt == null)
          for (final payment in record.payments)
            if ((startInclusive == null ||
                    !payment.paidAt.isBefore(startInclusive!)) &&
                (endExclusive == null ||
                    payment.paidAt.isBefore(endExclusive!)))
              _PaymentLine(payment: payment, recordLabel: record.displayTitle),
    ]..sort((a, b) => b.payment.paidAt.compareTo(a.payment.paidAt));
    final totalCents = payments.fold<int>(
      0,
      (sum, line) => sum + (line.payment.amount * 100).round(),
    );
    return AppScreenShell(
      section: AppSection.invoices,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(appNativeRoute<void>(context, const InvoicePaymentScreen())),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Record payment'),
      ),
      pinnedHeader: const AppScreenHeader(title: 'Payments Review'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
        children: [
          _SummaryPanel(
            eyebrow: 'SAVED PAYMENTS',
            value: _money(totalCents),
            detail:
                '${_rangeLabel()} · ${payments.length} ${payments.length == 1 ? 'payment' : 'payments'} recorded',
            color: const Color(0xFF20F060),
          ),
          const SizedBox(height: 12),
          if (payments.isEmpty)
            const _EmptyRecords(
              title: 'No payments recorded yet',
              detail: 'Use Record payment when money comes in.',
            )
          else
            for (final line in payments) _PaymentRow(line: line),
        ],
      ),
    );
  }

  String _rangeLabel() => startInclusive == null && endExclusive == null
      ? 'All saved records'
      : 'Selected period';
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.eyebrow,
    required this.value,
    required this.detail,
    required this.color,
  });

  final String eyebrow;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF121A1E),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: .8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: Color(0xFFCAD2D5),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          detail,
          style: const TextStyle(
            color: Color(0xFFE2E8EA),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords({required this.title, required this.detail});
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF172126),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE2E8EA),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          style: const TextStyle(color: Color(0xFFCAD2D5), fontSize: 12),
        ),
      ],
    ),
  );
}

class _ExpenseReceiptRow extends StatelessWidget {
  const _ExpenseReceiptRow({required this.receipt});
  final ExpenseReceiptRecord receipt;

  @override
  Widget build(BuildContext context) => _RecordRow(
    icon: Icons.receipt_long_rounded,
    color: const Color(0xFFFFD166),
    title: receipt.title,
    detail: '${receipt.primaryCategoryLabel} · ${_date(receipt.receiptDate)}',
    amount: _money(receipt.totalCents),
  );
}

class _PaymentLine {
  const _PaymentLine({required this.payment, required this.recordLabel});
  final InvoicePaymentRecord payment;
  final String recordLabel;
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.line});
  final _PaymentLine line;

  @override
  Widget build(BuildContext context) => _RecordRow(
    icon: Icons.payments_rounded,
    color: const Color(0xFF20F060),
    title: line.recordLabel,
    detail:
        '${line.payment.method.trim().isEmpty ? 'Payment' : line.payment.method} · ${_date(line.payment.paidAt)}',
    amount: _money((line.payment.amount * 100).round()),
  );
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.amount,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String amount;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFF172126),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE2E8EA),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFCAD2D5), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          amount,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

String _money(int cents) {
  final absolute = cents.abs();
  final dollars = (absolute ~/ 100).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${cents < 0 ? '-' : ''}\$$dollars.${(absolute % 100).toString().padLeft(2, '0')}';
}

String _date(DateTime value) => '${value.month}/${value.day}/${value.year}';
