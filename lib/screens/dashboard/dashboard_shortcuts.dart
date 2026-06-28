import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import 'dashboard_detail_screen.dart';

class FastRecordGrid extends StatelessWidget {
  const FastRecordGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardShortcutGrid(
      title: 'Fast record',
      shortcuts: [
        DashboardShortcut(
          title: 'Fuel',
          subtitle: r'$126 this week',
          icon: Icons.local_gas_station_rounded,
          color: _red,
          kind: DashboardDetailKind.fuel,
          startsInAddMode: true,
        ),
        DashboardShortcut(
          title: 'Expense',
          subtitle: r'$421 this week',
          icon: Icons.receipt_long_rounded,
          color: _yellow,
          kind: DashboardDetailKind.expenses,
          startsInAddMode: true,
        ),
        DashboardShortcut(
          title: 'Pay',
          subtitle: r'$44.80 per hr',
          icon: Icons.payments_rounded,
          color: _green,
          kind: DashboardDetailKind.pay,
          startsInAddMode: true,
        ),
        DashboardShortcut(
          title: 'Trip',
          subtitle: '386 mi this week',
          icon: Icons.route_rounded,
          color: _blue,
          kind: DashboardDetailKind.trips,
          startsInAddMode: true,
        ),
      ],
    );
  }
}

class WeeklyDetailLinks extends StatelessWidget {
  const WeeklyDetailLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardShortcutGrid(
      title: 'Weekly totals',
      shortcuts: [
        DashboardShortcut(
          title: 'Profit',
          subtitle: r'$1,763 net',
          icon: Icons.trending_up_rounded,
          color: _green,
          kind: DashboardDetailKind.profit,
        ),
        DashboardShortcut(
          title: 'Fuel',
          subtitle: r'$126 spent',
          icon: Icons.local_gas_station_rounded,
          color: _red,
          kind: DashboardDetailKind.fuel,
        ),
        DashboardShortcut(
          title: 'Expenses',
          subtitle: r'$421 total',
          icon: Icons.receipt_long_rounded,
          color: _yellow,
          kind: DashboardDetailKind.expenses,
        ),
        DashboardShortcut(
          title: 'Trips',
          subtitle: '64 stops',
          icon: Icons.route_rounded,
          color: _blue,
          kind: DashboardDetailKind.trips,
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
        onTap: () => _openDetail(context),
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

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        DashboardDetailScreen(
          kind: shortcut.kind,
          startsInAddMode: shortcut.startsInAddMode,
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
    required this.kind,
    this.startsInAddMode = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DashboardDetailKind kind;
  final bool startsInAddMode;
}

const _green = Color(0xFF20F060);
const _blue = Color(0xFF34A9E8);
const _red = Color(0xFFFF5750);
const _yellow = Color(0xFFFFD166);
