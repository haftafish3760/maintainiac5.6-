import 'package:flutter/material.dart';

import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../../shared/widgets/industrial_panel_surface.dart';
import '../data/invoice_ledger_models.dart';
import 'invoice_day_screen.dart';
import 'invoice_form_screen.dart';
import 'invoice_home_calendar.dart';
import 'invoice_home_models.dart';
import 'invoice_home_sample_data.dart';
import 'invoice_home_widgets.dart';
import 'invoice_info_screens.dart';

part 'invoice_workspace_helpers.dart';

class InvoiceWorkspaceScreen extends StatefulWidget {
  const InvoiceWorkspaceScreen({required this.mode, super.key});

  final InvoiceWorkspaceMode mode;

  @override
  State<InvoiceWorkspaceScreen> createState() => _InvoiceWorkspaceScreenState();
}

class _InvoiceWorkspaceScreenState extends State<InvoiceWorkspaceScreen> {
  var _selectedDay = DateTime(2026, 6, 15);
  var _filter = InvoiceStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final isInvoices = widget.mode == InvoiceWorkspaceMode.invoices;
    final baseEntries = invoiceEntriesFor(widget.mode);
    final filtered = _filterEntries(baseEntries);
    final dayEntries = filtered.where(_isSelectedDay).toList();
    return AppScreenShell(
      section: AppSection.invoices,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        icon: Icon(isInvoices ? Icons.add_rounded : Icons.assignment_rounded),
        label: Text(isInvoices ? 'Invoice Actions' : 'Estimate Actions'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 84),
        children: [
          AppScreenHeader(title: isInvoices ? 'Invoices' : 'Estimates'),
          const SizedBox(height: 8),
          const GlobalOdometerHeader(section: AppSection.invoices),
          const SizedBox(height: 8),
          _WorkspaceHeader(
            mode: widget.mode,
            selectedDay: _selectedDay,
            entries: dayEntries,
          ),
          const SizedBox(height: 8),
          if (isInvoices) ...[
            InvoiceStatusRail(
              metrics: invoiceMetricsFor(widget.mode),
              selected: _filter,
              onSelected: _selectFilter,
            ),
            const SizedBox(height: 8),
          ],
          _WorkspaceEntryPanel(entries: dayEntries, isEstimate: !isInvoices),
          const SizedBox(height: 10),
          InvoiceMonthCalendarPanel(entries: filtered, onDaySelected: _openDay),
        ],
      ),
    );
  }

  List<InvoiceTimelineEntry> _filterEntries(
    List<InvoiceTimelineEntry> entries,
  ) {
    if (_filter == InvoiceStatusFilter.all) return entries;
    return entries.where((entry) => entry.filter == _filter).toList();
  }

  bool _isSelectedDay(InvoiceTimelineEntry entry) {
    return entry.day.year == _selectedDay.year &&
        entry.day.month == _selectedDay.month &&
        entry.day.day == _selectedDay.day;
  }

  void _selectFilter(InvoiceStatusFilter filter) {
    final filtered = filter == InvoiceStatusFilter.all
        ? invoiceEntriesFor(widget.mode)
        : invoiceEntriesFor(
            widget.mode,
          ).where((entry) => entry.filter == filter).toList();
    setState(() {
      _filter = filter;
      if (filtered.isNotEmpty) {
        _selectedDay = filtered
            .map((entry) => entry.day)
            .reduce((latest, day) => day.isAfter(latest) ? day : latest);
      }
    });
  }

  void _openDay(DateTime day) {
    setState(() => _selectedDay = day);
    final filtered = _filterEntries(invoiceEntriesFor(widget.mode));
    final entries = filtered.where((entry) {
      return entry.day.year == day.year &&
          entry.day.month == day.month &&
          entry.day.day == day.day;
    }).toList();
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        InvoiceDayScreen(
          mode: widget.mode,
          day: day,
          entries: entries,
          allEntries: filtered,
        ),
      ),
    );
  }

  Future<void> _showCreateSheet() async {
    final isInvoices = widget.mode == InvoiceWorkspaceMode.invoices;
    final action = await showModalBottomSheet<_InvoiceFabAction>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF20292D),
      builder: (context) => _InvoiceFabSheet(isInvoices: isInvoices),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _InvoiceFabAction.create:
        Navigator.of(context).push(
          appNativeRoute<void>(
            context,
            InvoiceFormScreen(
              documentType: isInvoices
                  ? InvoiceDocumentType.invoice
                  : InvoiceDocumentType.estimate,
            ),
          ),
        );
      case _InvoiceFabAction.drafts:
        _showMessage(
          isInvoices ? 'Invoice drafts are next.' : 'Estimate drafts are next.',
        );
      case _InvoiceFabAction.myInfo:
        Navigator.of(
          context,
        ).push(appNativeRoute<void>(context, const InvoiceCompanyInfoScreen()));
      case _InvoiceFabAction.savedClients:
        Navigator.of(
          context,
        ).push(appNativeRoute<void>(context, const InvoiceClientInfoScreen()));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.mode,
    required this.selectedDay,
    required this.entries,
  });

  final InvoiceWorkspaceMode mode;
  final DateTime selectedDay;
  final List<InvoiceTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final isInvoices = mode == InvoiceWorkspaceMode.invoices;
    final total = entries.fold<double>(0, (sum, entry) {
      return sum + invoiceAmountFromLabel(entry.amount);
    });
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isInvoices
                    ? Icons.receipt_long_rounded
                    : Icons.assignment_rounded,
                color: isInvoices ? _green : _blue,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isInvoices ? 'Invoices' : 'Estimates',
                  style: const TextStyle(
                    color: Color(0xFFE2E8EA),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              Text(
                _shortDate(selectedDay),
                style: const TextStyle(
                  color: Color(0xFFCAD2D5),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isInvoices)
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _MetricChip(
                  label: 'Due',
                  value: invoiceMoney(total),
                  color: _green,
                ),
                _MetricChip(
                  label: 'Invoices',
                  value: '${entries.length}',
                  color: _yellow,
                ),
                _MetricChip(
                  label: 'Open',
                  value: '${entries.where(_isOpenInvoice).length}',
                  color: _red,
                ),
              ],
            )
          else
            Text(
              'Tap a calendar day to review estimates created for that day.',
              style: const TextStyle(
                color: Color(0xFFCAD2D5),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkspaceEntryPanel extends StatelessWidget {
  const _WorkspaceEntryPanel({required this.entries, required this.isEstimate});

  final List<InvoiceTimelineEntry> entries;
  final bool isEstimate;

  @override
  Widget build(BuildContext context) {
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            isEstimate ? 'Estimates for this day' : 'Invoices for this day',
          ),
          const SizedBox(height: 7),
          if (entries.isEmpty)
            const _EmptyWorkspaceEntries()
          else
            for (final entry in entries) InvoiceWorkspaceEntryRow(entry: entry),
        ],
      ),
    );
  }
}

class InvoiceWorkspaceEntryRow extends StatelessWidget {
  const InvoiceWorkspaceEntryRow({required this.entry, super.key});

  final InvoiceTimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
      decoration: BoxDecoration(
        color: const Color(0xFF141A1D),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF4F5A60)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              '${entry.day.day}',
              style: const TextStyle(
                color: Color(0xFFE2E8EA),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE2E8EA),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFCAD2D5),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            entry.amount,
            style: TextStyle(
              color: invoiceStatusColor(entry.filter),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
