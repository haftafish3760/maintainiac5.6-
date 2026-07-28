/// Compact Active Day financial command-center metrics from saved ledgers.
///
/// Owns responsive presentation of received, business-spent, net, and fuel
/// totals. It does not edit ledger records or infer income from invoices.
/// Consumed by ActiveWorkdayScreen; all values remain local, attributed data.
library;

import 'package:flutter/material.dart';

import '../expenses/data/expense_ledger_store.dart';
import '../invoices/data/invoice_ledger_store.dart';
import 'data/active_workday_financial_snapshot.dart';
import 'data/active_workday_store.dart';

class ActiveWorkdayFinancialSummaryPanel extends StatelessWidget {
  const ActiveWorkdayFinancialSummaryPanel({
    super.key,
    required this.session,
    required this.day,
  });

  final ActiveWorkdaySessionRecord? session;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final currentSession = session;
    if (currentSession == null) return const SizedBox.shrink();
    final expenses = ExpenseLedgerScope.maybeOf(context);
    final invoices = InvoiceLedgerScope.maybeOf(context);
    final listenables = <Listenable>[?expenses, ?invoices];
    if (listenables.isEmpty) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, _) {
        final summary = ActiveWorkdayFinancialSnapshot.forSession(
          day: day,
          vehicleId: currentSession.vehicleId,
          workProfileId: currentSession.workProfileId,
          invoices: invoices?.records ?? const [],
          expenses: expenses?.receipts ?? const [],
        );
        return _FinancialSummaryContent(summary: summary);
      },
    );
  }
}

class _FinancialSummaryContent extends StatelessWidget {
  const _FinancialSummaryContent({required this.summary});

  final ActiveWorkdayFinancialSnapshot summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'TODAY\'S MONEY',
          style: TextStyle(
            color: Color(0xFFE2E8EA),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: .6,
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 420 ? 4 : 2;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: columns == 4 ? 1.22 : 1.9,
              children: [
                _FinancialMetricTile('Received', summary.receivedCents),
                _FinancialMetricTile('Spent', summary.spentCents),
                _FinancialMetricTile('Net', summary.netCents, signed: true),
                _FinancialMetricTile('Fuel', summary.fuelCents),
              ],
            );
          },
        ),
        const SizedBox(height: 5),
        Text(
          summary.expenseReceiptCount == 0
              ? 'Saved, attributed ledger records only. Add a payment or expense when it happens.'
              : '${summary.expenseReceiptCount} attributed expense ${summary.expenseReceiptCount == 1 ? 'record' : 'records'} today. Totals never estimate income or mileage.',
          style: const TextStyle(
            color: Color(0xFFCAD2D5),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _FinancialMetricTile extends StatelessWidget {
  const _FinancialMetricTile(this.label, this.cents, {this.signed = false});

  final String label;
  final int cents;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final negative = cents < 0;
    final value = _formatCurrency(cents, signed: signed);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF101416),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF59636A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: negative
                    ? const Color(0xFFFF8585)
                    : const Color(0xFF50F77A),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(int cents, {bool signed = false}) {
  final sign = cents < 0 ? '-' : (signed && cents > 0 ? '+' : '');
  final absolute = cents.abs();
  final dollars = absolute ~/ 100;
  final remainder = absolute.remainder(100).toString().padLeft(2, '0');
  return '$sign\$$dollars.$remainder';
}
