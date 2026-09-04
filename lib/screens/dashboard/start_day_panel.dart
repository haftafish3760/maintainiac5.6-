import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/trip_tracking/trip_tracking_controller.dart';
import '../../shared/trip_tracking/trip_tracking_settings_store.dart';
import '../expenses/data/expense_ledger_store.dart';
import '../expenses/data/expense_ledger_models.dart';
import '../invoices/data/invoice_ledger_models.dart';
import '../invoices/data/invoice_ledger_store.dart';
import '../settings/trip_tracking_settings_screen.dart';
import 'dashboard_shortcuts.dart';
import 'contractor/contractor_dashboard_screen.dart';
import 'gig_dashboard_record_review_screens.dart';

class PreDayStartContent extends StatelessWidget {
  const PreDayStartContent({
    super.key,
    required this.onStartDay,
    this.hasActiveDay = false,
  });

  final VoidCallback onStartDay;
  final bool hasActiveDay;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekStart = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - DateTime.monday),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DashboardTitleBand(),
          const SizedBox(height: 10),
          _PreDayCommandCenter(
            onStartDay: onStartDay,
            hasActiveDay: hasActiveDay,
          ),
          const SizedBox(height: 14),
          FastRecordGrid(onStartTrip: onStartDay),
          const SizedBox(height: 12),
          WeeklyDetailLinks(weekStart: weekStart),
        ],
      ),
    );
  }
}

class _DashboardTitleBand extends StatelessWidget {
  const _DashboardTitleBand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.delivery_dining_rounded, color: _blue, size: 24),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Recap',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            appNativeRoute<void>(context, const ContractorDashboardScreen()),
          ),
          icon: const Icon(Icons.dashboard_customize_rounded, size: 18),
          label: const Text('Dashboard'),
        ),
      ],
    );
  }
}

class _PreDayCommandCenter extends StatelessWidget {
  const _PreDayCommandCenter({
    required this.onStartDay,
    required this.hasActiveDay,
  });

  final VoidCallback onStartDay;
  final bool hasActiveDay;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expenseLedger = ExpenseLedgerScope.maybeOf(context);
    final invoiceLedger = InvoiceLedgerScope.maybeOf(context);
    final businessExpenseCents =
        expenseLedger?.summaryForWeek(now).businessCents ?? 0;
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - DateTime.monday),
    );
    final weekEnd = weekStart.add(const Duration(days: 7));
    final paymentCents =
        invoiceLedger?.records
            .where(
              (record) =>
                  record.isInvoice &&
                  record.status != InvoiceRecordStatus.voided &&
                  record.meta.deletedAt == null,
            )
            .expand((record) => record.payments)
            .where(
              (payment) =>
                  !payment.paidAt.isBefore(weekStart) &&
                  payment.paidAt.isBefore(weekEnd),
            )
            .fold<int>(
              0,
              (total, payment) => total + (payment.amount * 100).round(),
            ) ??
        0;
    final fuelCents =
        expenseLedger?.receipts
            .where((receipt) => receipt.isActive)
            .where(
              (receipt) =>
                  !receipt.receiptDate.isBefore(weekStart) &&
                  receipt.receiptDate.isBefore(weekEnd),
            )
            .where(
              (receipt) => receipt.lines.any(
                (line) => line.category.trim().toLowerCase() == 'fuel',
              ),
            )
            .fold<int>(0, (sum, receipt) => sum + receipt.totalCents) ??
        0;
    final tracking = TripTrackingScope.maybeOf(context);
    final gpsEnabled =
        TripTrackingSettingsScope.maybeOf(
          context,
        )?.settings.gpsAssistedTrackingEnabled ??
        true;
    final readiness = !gpsEnabled
        ? _Readiness('GPS assistance off', _yellow, Icons.location_off_rounded)
        : tracking?.awaitingInitialFix == true
        ? _Readiness(
            'Waiting for GPS',
            _yellow,
            Icons.location_searching_rounded,
          )
        : tracking?.nativeProviderRegistered == true
        ? _Readiness('GPS ready', _green, Icons.location_on_rounded)
        : _Readiness('GPS checks at start', _blue, Icons.gps_fixed_rounded);
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _MetricGrid(
          paymentCents: paymentCents,
          expenseCents: businessExpenseCents,
          fuelCents: fuelCents,
          readiness: readiness,
          weekStart: weekStart,
          weekEnd: weekEnd,
        );
        final startButton = _StartDayCommandButton(
          onPressed: onStartDay,
          hasActiveDay: hasActiveDay,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [metrics, const SizedBox(height: 10), startButton],
        );
      },
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.paymentCents,
    required this.expenseCents,
    required this.fuelCents,
    required this.readiness,
    required this.weekStart,
    required this.weekEnd,
  });
  final int paymentCents;
  final int expenseCents;
  final int fuelCents;
  final _Readiness readiness;
  final DateTime weekStart;
  final DateTime weekEnd;

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    childAspectRatio: 1.9,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      _MetricReadout(
        label: 'Payments this week',
        value: _formatDashboardMoney(paymentCents),
        color: _green,
        icon: Icons.payments_rounded,
        onTap: () => Navigator.of(context).push(
          appNativeRoute<void>(
            context,
            GigPaymentsReviewScreen(
              startInclusive: weekStart,
              endExclusive: weekEnd,
            ),
          ),
        ),
      ),
      _MetricReadout(
        label: 'Expenses this week',
        value: _formatDashboardMoney(expenseCents),
        color: _yellow,
        icon: Icons.receipt_long_rounded,
        onTap: () => Navigator.of(context).push(
          appNativeRoute<void>(
            context,
            GigExpenseCategoryBreakdownScreen(
              startInclusive: weekStart,
              endExclusive: weekEnd,
            ),
          ),
        ),
      ),
      _MetricReadout(
        label: 'Fuel recorded',
        value: _formatDashboardMoney(fuelCents),
        color: _red,
        icon: Icons.local_gas_station_rounded,
        onTap: () => Navigator.of(context).push(
          appNativeRoute<void>(
            context,
            GigExpenseCategoryBreakdownScreen(
              category: 'Fuel',
              startInclusive: weekStart,
              endExclusive: weekEnd,
            ),
          ),
        ),
      ),
      _MetricReadout(
        label: readiness.label,
        value: 'Tracking',
        color: readiness.color,
        icon: readiness.icon,
        onTap: () => Navigator.of(context).push(
          appNativeRoute<void>(context, const TripTrackingSettingsScreen()),
        ),
      ),
    ],
  );
}

class _Readiness {
  const _Readiness(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

class _StartDayCommandButton extends StatelessWidget {
  const _StartDayCommandButton({
    required this.onPressed,
    required this.hasActiveDay,
  });
  final VoidCallback onPressed;
  final bool hasActiveDay;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 54,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(
        hasActiveDay ? Icons.play_arrow_rounded : Icons.play_circle_rounded,
      ),
      label: Text(hasActiveDay ? 'Resume day' : 'Start day'),
      style: FilledButton.styleFrom(
        backgroundColor: _green,
        foregroundColor: const Color(0xFF08110D),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}

String _formatDashboardMoney(int cents) {
  final negative = cents < 0;
  final absolute = cents.abs();
  final dollars = (absolute ~/ 100).toString();
  final grouped = dollars.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final fraction = (absolute % 100).toString().padLeft(2, '0');
  return '${negative ? '-' : ''}\$$grouped.$fraction';
}

class _MetricReadout extends StatelessWidget {
  const _MetricReadout({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF141A1D),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF627077), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFCAD2D5),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      shadows: [
                        Shadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _green = Color(0xFF20F060);
const _blue = Color(0xFF34A9E8);
const _red = Color(0xFFFF5750);
const _yellow = Color(0xFFFFD166);
