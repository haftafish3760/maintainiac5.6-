import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/odometer/open_odometer_entry.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/action_tile.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/industrial_panel.dart';
import '../../shared/calendar/calendar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return AppScaffold(
      title: 'Maintaniac',
      currentIndex: 0,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 18),
        children: [
          _SelectorRow(state: state),
          const SizedBox(height: 10),
          const _DashboardMessage(),
          const SizedBox(height: 10),
          _StartDayButton(onTap: () => _startDay(context)),
          const SizedBox(height: 12),
          const _WeeklyRecap(),
          const SizedBox(height: 12),
          _QuickActions(
            onMaintenance: () => Navigator.of(context).push(
              appNativeRoute(
                context,
                const _QuickActionPlaceholder(title: 'Maintenance Event'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const DashboardCalendar(),
        ],
      ),
    );
  }

  Future<void> _startDay(BuildContext context) async {
    final saved = await openOdometerEntry(
      context,
      title: 'Starting Odometer',
      saveLabel: 'Start Day',
    );
    if (!saved || !context.mounted) return;
    Navigator.of(
      context,
    ).push(appNativeRoute(context, const _ActiveDayScreen()));
  }
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage();

  @override
  Widget build(BuildContext context) {
    return IndustrialPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(color: Color(0xAA28A745), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Ready to start today.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ),
          const Text(
            'No urgent alerts',
            style: TextStyle(
              color: Color(0xFFC9D0C8),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorRow extends StatelessWidget {
  const _SelectorRow({required this.state});

  final AppStateController state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BorderLabel(
            label: 'Active Vehicle',
            child: Text(
              state.activeVehicle?.displayName ?? 'Add vehicle profile',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: BorderLabel(
            label: 'Work Profile',
            child: Text(
              state.activeWorkProfile?.name ?? 'Add work profile',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

class _StartDayButton extends StatelessWidget {
  const _StartDayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IndustrialPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(
        children: [
          const Text(
            'Start tracking when the work day begins',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTapDown: (_) {},
            onTap: onTap,
            child: Container(
              width: 148,
              height: 138,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFF171918),
                border: Border.all(color: const Color(0xFFCED2C8), width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xAA24FF55),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black87,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Container(
                width: 116,
                height: 116,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFF242725),
                  border: Border.all(color: AppColors.green, width: 4),
                ),
                child: const Text(
                  'START\nDAY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyRecap extends StatelessWidget {
  const _WeeklyRecap();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Gross', '\$4,825'),
      ('Profit', '\$3,640'),
      ('Expenses', '\$612'),
      ('Miles', '812'),
    ];
    return IndustrialPanel(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Week at a glance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                'May 18-24',
                style: TextStyle(
                  color: Color(0xFFC9D0C8),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                Expanded(
                  child: _RecapMetric(
                    label: items[index].$1,
                    value: items[index].$2,
                  ),
                ),
                if (index != items.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RecapMetric extends StatelessWidget {
  const _RecapMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF161A18).withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF42FF68),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onMaintenance});

  final VoidCallback onMaintenance;

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('Fuel', '⛽', AppColors.blue, () {}),
      ('Receipt', '📷', AppColors.blue, () {}),
      ('Expense', '🧾', AppColors.red, () {}),
      ('Payment', '💵', AppColors.green, () {}),
      ('Maintenance', '🛠️', AppColors.blue, onMaintenance),
      ('Settings', '⚙️', AppColors.panelLight, () {}),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 72,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: actions.length,
      itemBuilder: (_, index) => ActionTile(
        label: actions[index].$1,
        icon: actions[index].$2,
        color: actions[index].$3,
        onTap: actions[index].$4,
        height: 72,
      ),
    );
  }
}

class _ActiveDayScreen extends StatelessWidget {
  const _ActiveDayScreen();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Active Day',
      currentIndex: 0,
      child: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          const IndustrialPanel(
            child: Row(
              children: [
                Expanded(
                  child: BorderLabel(
                    label: 'Shift Timer',
                    child: Text(
                      '00:00:14',
                      style: TextStyle(
                        color: Color(0xFF42FF68),
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: BorderLabel(
                    label: 'Miles Today',
                    child: Text(
                      '0.0',
                      style: TextStyle(
                        color: Color(0xFF42FF68),
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _QuickActions(onMaintenance: () {}),
        ],
      ),
    );
  }
}

class _QuickActionPlaceholder extends StatelessWidget {
  const _QuickActionPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppScreenHeader(title: title),
          const Expanded(child: Center(child: Text('Flow shell'))),
        ],
      ),
    );
  }
}
