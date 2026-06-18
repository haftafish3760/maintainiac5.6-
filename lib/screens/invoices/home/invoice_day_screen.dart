import 'package:flutter/material.dart';

import '../../../shared/calendar/month_year_picker.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../../shared/widgets/industrial_panel_surface.dart';
import 'invoice_home_models.dart';

class InvoiceDayScreen extends StatelessWidget {
  const InvoiceDayScreen({
    required this.mode,
    required this.day,
    required this.entries,
    required this.allEntries,
    super.key,
  });

  final InvoiceWorkspaceMode mode;
  final DateTime day;
  final List<InvoiceTimelineEntry> entries;
  final List<InvoiceTimelineEntry> allEntries;

  @override
  Widget build(BuildContext context) {
    final isInvoice = mode == InvoiceWorkspaceMode.invoices;
    final invoiceEntries = entries.where(_isInvoiceRecord).toList();
    return AppScreenShell(
      section: AppSection.invoices,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const GlobalOdometerHeader(section: AppSection.invoices),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: const AppBackButton(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
            child: IndustrialPanelSurface(
              dark: true,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    calendarFullDateLabel(day),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isInvoice
                        ? 'Invoices assigned to this date for the active vehicle or company.'
                        : 'Estimates assigned to this date for the active vehicle or company.',
                    style: const TextStyle(fontSize: 12, height: 1.25),
                  ),
                  const SizedBox(height: 12),
                  if (invoiceEntries.isNotEmpty) ...[
                    _DayMoneyStrip(entries: invoiceEntries),
                    const Divider(color: Color(0xFF7B8588), height: 24),
                  ],
                  if (entries.isEmpty)
                    const _EmptyInvoiceDay()
                  else
                    for (final entry in entries) _InvoiceDayEntry(entry: entry),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayMoneyStrip extends StatelessWidget {
  const _DayMoneyStrip({required this.entries});

  final List<InvoiceTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<double>(0, (sum, entry) {
      return sum + _amountFromLabel(entry.amount);
    });
    return Row(
      children: [
        Expanded(
          child: _DayStat(
            label: 'Day Income',
            value: _money(total),
            color: const Color(0xFF6BE58D),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DayStat(
            label: 'Invoices',
            value: '${entries.length}',
            color: const Color(0xFFFFC928),
          ),
        ),
      ],
    );
  }
}

class _DayStat extends StatelessWidget {
  const _DayStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF12191C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceDayEntry extends StatelessWidget {
  const _InvoiceDayEntry({required this.entry});

  final InvoiceTimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF20292D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _statusColor(entry.filter)),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(entry.filter), color: _statusColor(entry.filter)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  entry.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.amount,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(entry.status, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyInvoiceDay extends StatelessWidget {
  const _EmptyInvoiceDay();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 22),
      child: Text(
        'No invoice or estimate records are assigned to this day yet.',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

bool _isInvoiceRecord(InvoiceTimelineEntry entry) {
  return entry.filter == InvoiceStatusFilter.paid ||
      entry.filter == InvoiceStatusFilter.unpaid ||
      entry.filter == InvoiceStatusFilter.overdue ||
      entry.filter == InvoiceStatusFilter.upcoming;
}

IconData _statusIcon(InvoiceStatusFilter filter) {
  return switch (filter) {
    InvoiceStatusFilter.paid => Icons.check_circle_rounded,
    InvoiceStatusFilter.unpaid => Icons.schedule_rounded,
    InvoiceStatusFilter.overdue => Icons.warning_rounded,
    InvoiceStatusFilter.upcoming => Icons.event_available_rounded,
    InvoiceStatusFilter.approved => Icons.verified_rounded,
    InvoiceStatusFilter.sent => Icons.send_rounded,
    InvoiceStatusFilter.draft => Icons.edit_document,
    InvoiceStatusFilter.all => Icons.description_rounded,
  };
}

Color _statusColor(InvoiceStatusFilter filter) {
  return switch (filter) {
    InvoiceStatusFilter.paid => const Color(0xFF6BE58D),
    InvoiceStatusFilter.unpaid => const Color(0xFFFFC928),
    InvoiceStatusFilter.overdue => const Color(0xFFFF6B58),
    InvoiceStatusFilter.upcoming => const Color(0xFF7FB9FF),
    InvoiceStatusFilter.approved => const Color(0xFF6BE58D),
    InvoiceStatusFilter.sent => const Color(0xFF7FB9FF),
    InvoiceStatusFilter.draft => const Color(0xFFFFD166),
    InvoiceStatusFilter.all => Colors.white,
  };
}

double _amountFromLabel(String label) {
  final cleaned = label.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(cleaned) ?? 0;
}

String _money(double value) {
  final dollars = value.round();
  return '\$${dollars.toString()}';
}
