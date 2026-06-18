import 'package:flutter/material.dart';

import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import 'invoice_day_screen.dart';
import 'invoice_form_screen.dart';
import 'invoice_home_calendar.dart';
import 'invoice_home_models.dart';
import 'invoice_home_sample_data.dart';
import 'invoice_home_widgets.dart';
import 'invoice_info_screens.dart';
import 'invoice_workspace_screen.dart';
import '../data/invoice_ledger_models.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  @override
  Widget build(BuildContext context) {
    final entries = [
      ...invoiceEntriesFor(InvoiceWorkspaceMode.invoices),
      ...invoiceEntriesFor(InvoiceWorkspaceMode.estimates),
    ];
    return AppScreenShell(
      section: AppSection.invoices,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLandingActions,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Invoice Actions'),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const GlobalOdometerHeader(section: AppSection.invoices),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: const _InvoiceTitle(),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: InvoiceQuickActionGrid(
              actions: _quickActions,
              onSelected: _handleQuickAction,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: InvoiceMonthCalendarPanel(
              key: const Key('invoice-home-calendar'),
              entries: entries,
              onDaySelected: _openDay,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _openWorkspace(InvoiceWorkspaceMode mode) {
    Navigator.of(
      context,
    ).push(appNativeRoute<void>(context, InvoiceWorkspaceScreen(mode: mode)));
  }

  Future<void> _handleQuickAction(InvoiceQuickActionType action) async {
    switch (action) {
      case InvoiceQuickActionType.createInvoice:
        _openWorkspace(InvoiceWorkspaceMode.invoices);
      case InvoiceQuickActionType.createEstimate:
        _openWorkspace(InvoiceWorkspaceMode.estimates);
      case InvoiceQuickActionType.myInfo:
        Navigator.of(
          context,
        ).push(appNativeRoute<void>(context, const InvoiceCompanyInfoScreen()));
      case InvoiceQuickActionType.clientInfo:
        Navigator.of(
          context,
        ).push(appNativeRoute<void>(context, const InvoiceClientInfoScreen()));
      case InvoiceQuickActionType.recordPayment:
        Navigator.of(
          context,
        ).push(appNativeRoute<void>(context, const InvoicePaymentScreen()));
    }
  }

  Future<void> _showLandingActions() async {
    final action = await showModalBottomSheet<InvoiceQuickActionType>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF20292D),
      builder: (context) => const _InvoiceLandingFabSheet(),
    );
    if (!mounted || action == null) return;
    await _handleLandingFabAction(action);
  }

  Future<void> _handleLandingFabAction(InvoiceQuickActionType action) async {
    switch (action) {
      case InvoiceQuickActionType.createInvoice:
        Navigator.of(
          context,
        ).push(appNativeRoute<void>(context, const InvoiceFormScreen()));
      case InvoiceQuickActionType.createEstimate:
        Navigator.of(context).push(
          appNativeRoute<void>(
            context,
            const InvoiceFormScreen(documentType: InvoiceDocumentType.estimate),
          ),
        );
      case InvoiceQuickActionType.myInfo:
      case InvoiceQuickActionType.clientInfo:
      case InvoiceQuickActionType.recordPayment:
        await _handleQuickAction(action);
    }
  }

  void _openDay(DateTime day) {
    final allEntries = [
      ...invoiceEntriesFor(InvoiceWorkspaceMode.invoices),
      ...invoiceEntriesFor(InvoiceWorkspaceMode.estimates),
    ];
    final entries = allEntries
        .where(
          (entry) =>
              entry.day.year == day.year &&
              entry.day.month == day.month &&
              entry.day.day == day.day,
        )
        .toList();
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        InvoiceDayScreen(
          mode: InvoiceWorkspaceMode.invoices,
          day: day,
          entries: entries,
          allEntries: allEntries,
        ),
      ),
    );
  }
}

class _InvoiceTitle extends StatelessWidget {
  const _InvoiceTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invoices, Estimates, and Payments',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 2),
        Text(
          'Choose the workspace you need, or tap a calendar day to review records for that date.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, height: 1.2),
        ),
      ],
    );
  }
}

class _InvoiceLandingFabSheet extends StatelessWidget {
  const _InvoiceLandingFabSheet();

  @override
  Widget build(BuildContext context) {
    const actions = [
      _LandingFabOption(
        glyph: '📄',
        label: 'Create New Invoice',
        detail: 'Bill a customer for completed work.',
        action: InvoiceQuickActionType.createInvoice,
      ),
      _LandingFabOption(
        glyph: '📝',
        label: 'Create New Estimate',
        detail: 'Quote work before the customer approves it.',
        action: InvoiceQuickActionType.createEstimate,
      ),
      _LandingFabOption(
        glyph: '💵',
        label: 'Record Payment',
        detail: 'Log money received without opening a full invoice.',
        action: InvoiceQuickActionType.recordPayment,
      ),
      _LandingFabOption(
        glyph: '👥',
        label: 'Add New Contact',
        detail: 'Open saved clients and add customer details.',
        action: InvoiceQuickActionType.clientInfo,
      ),
      _LandingFabOption(
        glyph: '🏢',
        label: 'My Info',
        detail: 'Company information used on invoices and estimates.',
        action: InvoiceQuickActionType.myInfo,
      ),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Invoice Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              for (final action in actions) ...[
                _InvoiceLandingFabRow(option: action),
                const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceLandingFabRow extends StatelessWidget {
  const _InvoiceLandingFabRow({required this.option});

  final _LandingFabOption option;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 58,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      leading: Text(
        option.glyph,
        style: const TextStyle(fontSize: 26, height: 1),
      ),
      title: Text(
        option.label,
        style: const TextStyle(
          color: Color(0xFFE2E8EA),
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        option.detail,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFCAD2D5),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: () => Navigator.of(context).pop(option.action),
    );
  }
}

class _LandingFabOption {
  const _LandingFabOption({
    required this.glyph,
    required this.label,
    required this.detail,
    required this.action,
  });

  final String glyph;
  final String label;
  final String detail;
  final InvoiceQuickActionType action;
}

const _quickActions = [
  InvoiceQuickAction(
    label: 'My Info',
    iconName: 'company',
    action: InvoiceQuickActionType.myInfo,
  ),
  InvoiceQuickAction(
    label: 'Saved Clients',
    iconName: 'client',
    action: InvoiceQuickActionType.clientInfo,
  ),
  InvoiceQuickAction(
    label: 'Payments',
    iconName: 'payment',
    action: InvoiceQuickActionType.recordPayment,
  ),
  InvoiceQuickAction(
    label: 'Estimates',
    iconName: 'estimate',
    action: InvoiceQuickActionType.createEstimate,
  ),
  InvoiceQuickAction(
    label: 'Invoices',
    iconName: 'invoice',
    action: InvoiceQuickActionType.createInvoice,
  ),
];
