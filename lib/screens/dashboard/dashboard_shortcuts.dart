import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../invoices/home/invoice_info_screens.dart';
import 'gig_dashboard_record_review_screens.dart';

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
          subtitle: 'Review fuel spending',
          icon: Icons.local_gas_station_rounded,
          color: _red,
          onTap: () => _openExpenseReview(context, category: 'Fuel'),
        ),
        DashboardShortcut(
          title: 'Expense',
          subtitle: 'Review all spending',
          icon: Icons.receipt_long_rounded,
          color: _yellow,
          onTap: () => _openExpenseReview(context),
        ),
        DashboardShortcut(
          title: 'Pay',
          subtitle: 'Record money received',
          icon: Icons.payments_rounded,
          color: _green,
          onTap: () => Navigator.of(
            context,
          ).push(appNativeRoute<void>(context, const InvoicePaymentScreen())),
          startsInAddMode: true,
        ),
        DashboardShortcut(
          title: 'Trip',
          subtitle: 'Odometer first',
          icon: Icons.route_rounded,
          color: _blue,
          onTap: onStartTrip,
          startsInAddMode: true,
        ),
      ],
    );
  }

  void _openExpenseReview(BuildContext context, {String? category}) {
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        GigExpenseCategoryBreakdownScreen(category: category),
      ),
    );
  }
}

class WeeklyDetailLinks extends StatelessWidget {
  const WeeklyDetailLinks({super.key, required this.weekStart});

  final DateTime weekStart;

  @override
  Widget build(BuildContext context) {
    return DashboardShortcutGrid(
      title: 'Weekly totals',
      shortcuts: [
        DashboardShortcut(
          title: 'Profit',
          subtitle: 'Payments review',
          icon: Icons.trending_up_rounded,
          color: _green,
          onTap: () => Navigator.of(context).push(
            appNativeRoute<void>(
              context,
              GigPaymentsReviewScreen(
                startInclusive: weekStart,
                endExclusive: weekStart.add(const Duration(days: 7)),
              ),
            ),
          ),
        ),
        DashboardShortcut(
          title: 'Fuel',
          subtitle: 'Weekly fuel',
          icon: Icons.local_gas_station_rounded,
          color: _red,
          onTap: () => Navigator.of(context).push(
            appNativeRoute<void>(
              context,
              GigExpenseCategoryBreakdownScreen(
                category: 'Fuel',
                startInclusive: weekStart,
                endExclusive: weekStart.add(const Duration(days: 7)),
              ),
            ),
          ),
        ),
        DashboardShortcut(
          title: 'Expenses',
          subtitle: 'Weekly total',
          icon: Icons.receipt_long_rounded,
          color: _yellow,
          onTap: () => Navigator.of(context).push(
            appNativeRoute<void>(
              context,
              GigExpenseCategoryBreakdownScreen(
                startInclusive: weekStart,
                endExclusive: weekStart.add(const Duration(days: 7)),
              ),
            ),
          ),
        ),
        DashboardShortcut(
          title: 'Trips',
          subtitle: 'Weekly trips',
          icon: Icons.route_rounded,
          color: _blue,
        ),
      ],
    );
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
