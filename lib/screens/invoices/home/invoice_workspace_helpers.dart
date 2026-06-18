part of 'invoice_workspace_screen.dart';

enum _InvoiceFabAction { create, drafts, myInfo, savedClients }

class _InvoiceFabSheet extends StatelessWidget {
  const _InvoiceFabSheet({required this.isInvoices});

  final bool isInvoices;

  @override
  Widget build(BuildContext context) {
    final createLabel = isInvoices
        ? 'Create New Invoice'
        : 'Create New Estimate';
    final draftLabel = isInvoices ? 'View Drafts' : 'View Estimate Drafts';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InvoiceFabSheetRow(
              icon: isInvoices
                  ? Icons.receipt_long_rounded
                  : Icons.assignment_rounded,
              label: createLabel,
              onTap: () => Navigator.of(context).pop(_InvoiceFabAction.create),
            ),
            _InvoiceFabSheetRow(
              icon: Icons.drafts_rounded,
              label: draftLabel,
              onTap: () => Navigator.of(context).pop(_InvoiceFabAction.drafts),
            ),
            _InvoiceFabSheetRow(
              icon: Icons.business_rounded,
              label: 'My Information',
              onTap: () => Navigator.of(context).pop(_InvoiceFabAction.myInfo),
            ),
            _InvoiceFabSheetRow(
              icon: Icons.group_rounded,
              label: 'Saved Clients',
              onTap: () =>
                  Navigator.of(context).pop(_InvoiceFabAction.savedClients),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceFabSheetRow extends StatelessWidget {
  const _InvoiceFabSheetRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 52,
      leading: Icon(icon, color: _yellow),
      title: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE2E8EA),
          fontWeight: FontWeight.w900,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
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
      width: 102,
      padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
      decoration: BoxDecoration(
        color: const Color(0xFF111719),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF48545A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFFE2E8EA),
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _EmptyWorkspaceEntries extends StatelessWidget {
  const _EmptyWorkspaceEntries();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'No records are assigned to this day yet.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFFCAD2D5), fontWeight: FontWeight.w800),
      ),
    );
  }
}

String _shortDate(DateTime day) => '${day.month}/${day.day}';

bool _isOpenInvoice(InvoiceTimelineEntry entry) {
  return entry.filter == InvoiceStatusFilter.unpaid ||
      entry.filter == InvoiceStatusFilter.overdue;
}

double invoiceAmountFromLabel(String label) {
  final cleaned = label.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(cleaned) ?? 0;
}

String invoiceMoney(double value) => '\$${value.round()}';

Color invoiceStatusColor(InvoiceStatusFilter filter) {
  return switch (filter) {
    InvoiceStatusFilter.paid => _green,
    InvoiceStatusFilter.unpaid => _yellow,
    InvoiceStatusFilter.overdue => _red,
    InvoiceStatusFilter.upcoming => _blue,
    InvoiceStatusFilter.approved => _green,
    InvoiceStatusFilter.sent => _blue,
    InvoiceStatusFilter.draft => _yellow,
    InvoiceStatusFilter.all => Colors.white,
  };
}

const _green = Color(0xFF27D56B);
const _blue = Color(0xFF34A9E8);
const _red = Color(0xFFFF5750);
const _yellow = Color(0xFFFFD166);
