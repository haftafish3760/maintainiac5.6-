// Inventory ownership: full read-only detail for a source transaction opened
// from Calendar. Editing remains in the Inventory owner workflow.

import 'package:flutter/material.dart';

import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../data/work_supply_models.dart';

class WorkSupplyInventoryTransactionDetailScreen extends StatelessWidget {
  const WorkSupplyInventoryTransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  final WorkSupplyInventoryTransaction transaction;

  @override
  Widget build(BuildContext context) => AppScreenShell(
    section: AppSection.materials,
    body: ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
      children: [
        const AppBackButton(),
        const SizedBox(height: 8),
        const GlobalOdometerHeader(section: AppSection.materials),
        const SizedBox(height: 12),
        Text(
          'Inventory transaction',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: const Color(0xFFE8ECEE),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _typeLabel(transaction.type),
          style: const TextStyle(
            color: Color(0xFF65B8FF),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        _DetailCard(
          title: transaction.item.name,
          rows: [
            _DetailRow('Occurred', _dateTime(context, transaction.occurredAt)),
            _DetailRow('Quantity change', _quantity(transaction)),
            _DetailRow(
              'On hand after',
              '${transaction.quantityAfter.toStringAsFixed(2)} ${transaction.item.unit}',
            ),
            _DetailRow('Storage', _storage(transaction)),
          ],
        ),
        const SizedBox(height: 10),
        _DetailCard(
          title: 'Cost and receipt',
          rows: [
            _DetailRow('Line total', _money(transaction.lineTotal)),
            _DetailRow('Business use', _businessUse(transaction)),
            _DetailRow(
              'Receipt proof',
              transaction.receiptLinked ? 'Linked' : 'Not linked',
            ),
            if (transaction.sourceMerchantName.trim().isNotEmpty)
              _DetailRow('Merchant', transaction.sourceMerchantName.trim()),
          ],
        ),
        if (transaction.jobName.trim().isNotEmpty ||
            transaction.jobNumber.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          _DetailCard(
            title: 'Linked work',
            rows: [
              if (transaction.jobName.trim().isNotEmpty)
                _DetailRow('Job', transaction.jobName.trim()),
              if (transaction.jobNumber.trim().isNotEmpty)
                _DetailRow('Job number', transaction.jobNumber.trim()),
            ],
          ),
        ],
        if (transaction.note.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          _DetailCard(
            title: 'Note',
            rows: [_DetailRow('', transaction.note.trim())],
          ),
        ],
        const SizedBox(height: 14),
        const Text(
          'Calendar is showing this Inventory-owned record. Use the Inventory screen to correct stock records.',
          style: TextStyle(color: Color(0xFFB7C4CA), height: 1.3),
        ),
      ],
    ),
  );
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.rows});
  final String title;
  final List<_DetailRow> rows;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF172126),
      border: Border.all(color: const Color(0xFF53656D)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE8ECEE),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        for (final row in rows)
          Padding(padding: const EdgeInsets.only(bottom: 6), child: row),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => RichText(
    text: TextSpan(
      style: const TextStyle(color: Color(0xFFE8ECEE), height: 1.25),
      children: [
        if (label.isNotEmpty)
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: Color(0xFFB7C4CA),
              fontWeight: FontWeight.w800,
            ),
          ),
        TextSpan(text: value),
      ],
    ),
  );
}

String _typeLabel(WorkSupplyStockEventType value) => switch (value) {
  WorkSupplyStockEventType.stockAdded => 'Stock added',
  WorkSupplyStockEventType.countAdjusted => 'Stock adjusted',
  WorkSupplyStockEventType.stockConsumed => 'Stock consumed',
  WorkSupplyStockEventType.transfer => 'Stock transferred',
};

String _quantity(WorkSupplyInventoryTransaction value) =>
    '${value.quantityChange >= 0 ? '+' : ''}${value.quantityChange.toStringAsFixed(2)} ${value.item.unit}';
String _storage(WorkSupplyInventoryTransaction value) => [
  value.storageArea,
  if (value.storageDetail.trim().isNotEmpty) value.storageDetail.trim(),
].where((value) => value.trim().isNotEmpty).join(' · ');
String _money(double value) => '\$${value.toStringAsFixed(2)}';
String _businessUse(WorkSupplyInventoryTransaction value) =>
    '${(value.businessPercent * 100).toStringAsFixed(0)}% ${value.businessUse}';
String _dateTime(BuildContext context, DateTime value) =>
    '${MaterialLocalizations.of(context).formatMediumDate(value)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(value))}';
