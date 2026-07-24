import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/odometer/open_odometer_entry.dart';
import '../expenses/data/expense_ledger_models.dart';
import '../expenses/entry/expense_receipt_entry_screen.dart';
import '../invoices/home/invoice_info_screens.dart';
import 'data/active_workday_store.dart';

class FastRecordGrid extends StatelessWidget {
  const FastRecordGrid({super.key, required this.onStartTrip});

  final VoidCallback onStartTrip;

  @override
  Widget build(BuildContext context) {
    return DashboardShortcutGrid(
      title: 'Fast record',
      shortcuts: [
        DashboardShortcut(
          title: 'Fuel',
          subtitle: 'Odometer + receipt',
          icon: Icons.local_gas_station_rounded,
          color: _red,
          onTap: () => _openExpense(context, category: 'Fuel'),
          startsInAddMode: true,
        ),
        DashboardShortcut(
          title: 'Expense',
          subtitle: 'Odometer + details',
          icon: Icons.receipt_long_rounded,
          color: _yellow,
          onTap: () => _openExpense(context),
          startsInAddMode: true,
        ),
        DashboardShortcut(
          title: 'Payment',
          subtitle: 'Record money received',
          icon: Icons.payments_rounded,
          color: _green,
          onTap: () => Navigator.of(
            context,
          ).push(appNativeRoute<void>(context, const InvoicePaymentScreen())),
          startsInAddMode: true,
        ),
        DashboardShortcut(
          title: 'Start Trip',
          subtitle: 'Odometer first',
          icon: Icons.route_rounded,
          color: _blue,
          onTap: onStartTrip,
          startsInAddMode: true,
        ),
      ],
    );
  }

  Future<void> _openExpense(BuildContext context, {String? category}) async {
    final reading = await openOdometerEntryResult(
      context,
      title: category == 'Fuel' ? 'Fuel Stop Odometer' : 'Expense Odometer',
      saveLabel: category == 'Fuel'
          ? 'Continue to Fuel'
          : 'Continue to Expense',
    );
    if (reading == null || !context.mounted) return;
    final saved = await Navigator.of(context).push<ExpenseReceiptRecord>(
      appNativeRoute<ExpenseReceiptRecord>(
        context,
        ExpenseReceiptEntryScreen(
          initialCategory: category,
          initialOdometerReading: reading,
        ),
      ),
    );
    if (saved == null || !context.mounted) return;
    final activeWorkday = ActiveWorkdayScope.maybeOf(context);
    if (activeWorkday?.activeSession != null) {
      final updated = await activeWorkday!.addEvent(
        type: category == 'Fuel'
            ? ActiveWorkdayEventType.fuel
            : ActiveWorkdayEventType.expense,
        odometerReading: saved.odometerReading ?? reading,
        note: category == 'Fuel' ? 'Fuel expense saved' : 'Expense saved',
      );
      if (updated == null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The expense saved, but it could not be added to today. Open the expense to try again.',
            ),
          ),
        );
      }
    }
  }
}

class DashboardShortcutGrid extends StatelessWidget {
  const DashboardShortcutGrid({
    super.key,
    required this.title,
    required this.shortcuts,
  });

  final String title;
  final List<DashboardShortcut> shortcuts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 2.65,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final shortcut in shortcuts) _ShortcutTile(shortcut: shortcut),
          ],
        ),
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({required this.shortcut});

  final DashboardShortcut shortcut;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: shortcut.onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(10, 8, 9, 9),
          decoration: BoxDecoration(
            color: const Color(0xFF151B1E),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: shortcut.color, width: 1.3),
            boxShadow: [
              BoxShadow(
                color: shortcut.color.withValues(alpha: 0.16),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(shortcut.icon, color: shortcut.color, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      shortcut.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE2E8EA),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      shortcut.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFCAD2D5),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                shortcut.startsInAddMode
                    ? Icons.add_rounded
                    : Icons.chevron_right_rounded,
                color: const Color(0xFFE2E8EA),
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardShortcut {
  const DashboardShortcut({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.startsInAddMode = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool startsInAddMode;
}

const _green = Color(0xFF20F060);
const _blue = Color(0xFF34A9E8);
const _red = Color(0xFFFF5750);
const _yellow = Color(0xFFFFD166);
