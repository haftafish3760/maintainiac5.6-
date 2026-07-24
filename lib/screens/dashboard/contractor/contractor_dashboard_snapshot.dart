import 'package:flutter/material.dart';

import '../../expenses/data/expense_ledger_store.dart';
import '../../invoices/data/invoice_ledger_models.dart';
import '../../invoices/data/invoice_ledger_store.dart';
import '../../invoices/data/invoice_record.dart';
import '../../../shared/jobs/maintainiac_job_store.dart';
import 'contractor_dashboard_models.dart';

class ContractorDashboardSnapshot {
  const ContractorDashboardSnapshot({
    required this.scaleMetrics,
    required this.operationsMetrics,
    required this.businessMetrics,
    required this.attentionItems,
    required this.jobsToday,
  });

  factory ContractorDashboardSnapshot.fromControllers({
    required DateTime now,
    required int vehicleCount,
    required int milesToday,
    required bool dayStarted,
    MaintainiacJobController? jobs,
    ExpenseLedgerController? expenses,
    InvoiceLedgerStore? invoices,
  }) {
    final activeJobs = jobs?.activeJobs ?? const <MaintainiacJobRecord>[];
    final jobsToday =
        activeJobs
            .where((job) => _sameDay(job.scheduledStart, now))
            .toList(growable: false)
          ..sort((left, right) => _jobTime(left).compareTo(_jobTime(right)));
    final expenseSummary = expenses?.summaryForWeek(now);
    final receiptReviewCount = expenses?.receiptsNeedingOcrReview.length ?? 0;
    final invoiceRecords =
        invoices?.records
            .where(
              (record) =>
                  record.isInvoice &&
                  record.status != InvoiceRecordStatus.voided &&
                  record.meta.deletedAt == null,
            )
            .toList(growable: false) ??
        const [];
    final unpaidRecords = invoiceRecords
        .where((record) => record.balanceDue > 0)
        .toList(growable: false);
    final overdueRecords = unpaidRecords
        .where(
          (record) =>
              record.status == InvoiceRecordStatus.overdue ||
              (record.dueDate?.isBefore(now) == true),
        )
        .toList(growable: false);
    final paymentsCents = _weeklyPaymentCents(invoiceRecords, now);
    final expenseCents = expenseSummary?.businessCents ?? 0;

    return ContractorDashboardSnapshot(
      scaleMetrics: [
        const ContractorMetric(
          label: 'Mode',
          value: 'Contractor',
          color: Color(0xFF7CC7FF),
        ),
        ContractorMetric(
          label: 'Open jobs',
          value: activeJobs.length.toString(),
          color: const Color(0xFF55D68A),
        ),
        ContractorMetric(
          label: 'Vehicles',
          value: vehicleCount.toString(),
          color: const Color(0xFFFFD166),
        ),
      ],
      operationsMetrics: [
        ContractorMetric(
          label: 'Day status',
          value: dayStarted ? 'Active' : 'Ready',
          color: dayStarted ? const Color(0xFF55D68A) : const Color(0xFF7CC7FF),
        ),
        ContractorMetric(
          label: 'Jobs today',
          value: jobsToday.length.toString(),
          color: const Color(0xFF7CC7FF),
        ),
        ContractorMetric(
          label: 'Receipts to review',
          value: receiptReviewCount.toString(),
          color: receiptReviewCount == 0
              ? const Color(0xFF55D68A)
              : const Color(0xFFFFD166),
        ),
        ContractorMetric(
          label: 'Unpaid invoices',
          value: unpaidRecords.length.toString(),
          color: unpaidRecords.isEmpty
              ? const Color(0xFF55D68A)
              : const Color(0xFFFF8552),
        ),
      ],
      businessMetrics: [
        ContractorMetric(
          label: 'Open jobs',
          value: activeJobs.length.toString(),
          color: const Color(0xFF4DA3FF),
        ),
        ContractorMetric(
          label: 'Payments this week',
          value: _money(paymentsCents),
          color: const Color(0xFF55D68A),
        ),
        ContractorMetric(
          label: 'Expenses this week',
          value: _money(expenseCents),
          color: const Color(0xFFFF5C5C),
        ),
        ContractorMetric(
          label: 'Miles today',
          value: milesToday.toString(),
          color: const Color(0xFFFFD166),
        ),
      ],
      attentionItems: [
        if (receiptReviewCount > 0)
          ContractorAttentionItem(
            title:
                '$receiptReviewCount ${receiptReviewCount == 1 ? 'receipt needs' : 'receipts need'} review',
            detail:
                'Confirm the receipt details before relying on the expense record.',
            color: const Color(0xFFFFC44D),
            icon: Icons.receipt_long_rounded,
          ),
        if (overdueRecords.isNotEmpty)
          ContractorAttentionItem(
            title:
                '${overdueRecords.length} ${overdueRecords.length == 1 ? 'invoice is' : 'invoices are'} overdue',
            detail: 'Open invoices to review balances and payment history.',
            color: const Color(0xFFFF8552),
            icon: Icons.request_quote_rounded,
          ),
      ],
      jobsToday: [
        for (final job in jobsToday)
          ContractorJobPreview(
            time: _timeLabel(job.scheduledStart),
            title: job.name,
            summary: _jobSummary(job),
            status: job.scheduledStart == null ? 'Not scheduled' : 'Scheduled',
          ),
      ],
    );
  }

  final List<ContractorMetric> scaleMetrics;
  final List<ContractorMetric> operationsMetrics;
  final List<ContractorMetric> businessMetrics;
  final List<ContractorAttentionItem> attentionItems;
  final List<ContractorJobPreview> jobsToday;
}

int _weeklyPaymentCents(List<InvoiceRecord> records, DateTime now) {
  final weekStart = DateTime(
    now.year,
    now.month,
    now.day - (now.weekday - DateTime.monday),
  );
  final weekEnd = weekStart.add(const Duration(days: 7));
  var cents = 0;
  for (final record in records) {
    for (final payment in record.payments) {
      if (!payment.paidAt.isBefore(weekStart) &&
          payment.paidAt.isBefore(weekEnd)) {
        cents += (payment.amount * 100).round();
      }
    }
  }
  return cents;
}

String _money(int cents) {
  final absolute = cents.abs();
  final dollars = (absolute ~/ 100).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final fraction = (absolute % 100).toString().padLeft(2, '0');
  return '${cents < 0 ? '-' : ''}\$$dollars.$fraction';
}

bool _sameDay(DateTime? value, DateTime other) =>
    value != null &&
    value.year == other.year &&
    value.month == other.month &&
    value.day == other.day;

DateTime _jobTime(MaintainiacJobRecord job) =>
    job.scheduledStart ?? job.updatedAt;

String _timeLabel(DateTime? value) {
  if (value == null) return 'Any time';
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
}

String _jobSummary(MaintainiacJobRecord job) {
  final details = [
    if (job.number.trim().isNotEmpty) 'Job ${job.number.trim()}',
    if (job.address.trim().isNotEmpty) job.address.trim(),
  ];
  return details.isEmpty ? 'Open the job for details.' : details.join(' - ');
}
