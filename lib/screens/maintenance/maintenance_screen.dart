import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_action_colors.dart';
import '../../shared/widgets/app_screen_shell.dart';
import 'maintenance_models.dart';
import 'maintenance_svg_icon.dart';
import 'maintenance_work_source_screen.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    if (state.maintenance.isEmpty) {
      return AppScreenShell(
        section: AppSection.maintenance,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
          children: const [
            GlobalOdometerHeader(),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: MaintenanceTrackingSelectionPanel(showCancel: false),
            ),
          ],
        ),
      );
    }

    final activeVehicle =
        state.activeVehicle ??
        (state.vehicles.isEmpty ? null : state.vehicles.first);
    final records =
        state.maintenance
            .where((record) => record.vehicleName == activeVehicle?.nickname)
            .toList()
          ..sort(_compareMaintenancePriority);

    return AppScreenShell(
      section: AppSection.maintenance,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
        children: [
          const GlobalOdometerHeader(),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _MaintenanceHeader(
              state: state,
              activeVehicle: activeVehicle,
              records: records,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _TrackedMaintenanceList(records: records),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _MaintenanceActionGrid(),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceHeader extends StatelessWidget {
  const _MaintenanceHeader({
    required this.state,
    required this.activeVehicle,
    required this.records,
  });

  final AppStateController state;
  final VehicleProfile? activeVehicle;
  final List<MaintenanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final next = records.isEmpty ? null : records.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Maintenance',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFFE7EEF1),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ActiveVehicleChip(state: state, vehicle: activeVehicle),
          ],
        ),
        const SizedBox(height: 8),
        _MaintenanceMessage(record: next, trackedCount: records.length),
      ],
    );
  }
}

class _ActiveVehicleChip extends StatelessWidget {
  const _ActiveVehicleChip({required this.state, required this.vehicle});

  final AppStateController state;
  final VehicleProfile? vehicle;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 104, maxWidth: 164),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectVehicle(context),
          borderRadius: BorderRadius.circular(6),
          child: Ink(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFAAB4B9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF87949A)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    vehicle?.nickname ?? 'Vehicle',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF101416),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF101416),
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectVehicle(BuildContext context) async {
    final selected = await showModalBottomSheet<VehicleProfile>(
      context: context,
      backgroundColor: const Color(0xFF2E3A40),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [
            const Text(
              'Choose Active Vehicle',
              style: TextStyle(
                color: Color(0xFF101416),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            for (final option in state.vehicles) ...[
              ListTile(
                tileColor: const Color(0xFFD3DBDE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                title: Text(
                  option.nickname,
                  style: const TextStyle(
                    color: Color(0xFF101416),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  '${option.year} ${option.make} ${option.model}',
                  style: const TextStyle(
                    color: Color(0xFF2F383D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => Navigator.pop(context, option),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
    if (selected != null) state.selectVehicle(selected);
  }
}

class _MaintenanceMessage extends StatelessWidget {
  const _MaintenanceMessage({required this.record, required this.trackedCount});

  final MaintenanceRecord? record;
  final int trackedCount;

  @override
  Widget build(BuildContext context) {
    final color = record == null
        ? const Color(0xFF20B24A)
        : _recordColor(record!);
    final title = record == null
        ? 'Ready to set up maintenance tracking'
        : '${record!.itemName} is next';
    final detail = record == null
        ? 'Add the services, renewals, and reminders you want the app to track.'
        : _messageDetail(record!, trackedCount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF111719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: record == null
                ? const MaintenanceSvgIcon(itemName: 'Wrench', size: 36)
                : MaintenanceSvgIcon(itemName: record!.itemName, size: 36),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE2E8EA),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _messageDetail(MaintenanceRecord record, int trackedCount) {
    final lead = record.timeOnly
        ? '${record.monthsRemaining.clamp(-99, 999)} months remaining'
        : '${formatMiles(record.milesRemaining)} miles remaining';
    final suffix = trackedCount == 1
        ? '1 tracked item'
        : '$trackedCount tracked items';
    return '$lead. Open the item to log service, adjust intervals, or review reminders. $suffix.';
  }
}

class _TrackedMaintenanceList extends StatelessWidget {
  const _TrackedMaintenanceList({required this.records});

  final List<MaintenanceRecord> records;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tracked Maintenance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF101416),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${records.length}',
                  style: const TextStyle(
                    color: Color(0xFF2F383D),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          for (final record in records) ...[
            _MaintenanceRow(record: record),
            if (record != records.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _MaintenanceRow extends StatelessWidget {
  const _MaintenanceRow({required this.record});

  final MaintenanceRecord record;

  @override
  Widget build(BuildContext context) {
    final color = _recordColor(record);
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(6),
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        decoration: BoxDecoration(
          color: const Color(0xFF111719),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: 1.6),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(5),
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: Center(
                child: MaintenanceSvgIcon(itemName: record.itemName, size: 34),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF3F7F8),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _recordStatus(record),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFC8D2D6),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ThresholdBadge(record: record, color: color),
          ],
        ),
      ),
    );
  }
}

class _ThresholdBadge extends StatelessWidget {
  const _ThresholdBadge({required this.record, required this.color});

  final MaintenanceRecord record;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = record.timeOnly
        ? '${record.monthsRemaining.clamp(-99, 999)} mo'
        : formatMiles(record.milesRemaining);
    return Container(
      constraints: const BoxConstraints(minWidth: 54),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _MaintenanceActionGrid extends StatelessWidget {
  const _MaintenanceActionGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionSpec(
        'Set Up Item',
        '🧰',
        AppActionColors.positive,
        () => Navigator.of(context).push(
          appNativeRoute<void>(context, const MaintenanceWorkSourceScreen()),
        ),
      ),
      _ActionSpec('Log Service', '🔧', AppActionColors.primary, () {}),
      _ActionSpec('Log Receipt', '🧾', AppActionColors.primary, () {}),
      _ActionSpec('Quick Service', '⚡', AppActionColors.primary, () {}),
      _ActionSpec('Supplies', '📦', AppActionColors.primary, () {}),
      _ActionSpec('History', '📋', AppActionColors.primary, () {}),
    ];

    return _Panel(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 46,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _FlowButton(
            label: action.label,
            emoji: action.emoji,
            color: action.color,
            onPressed: action.onPressed,
          );
        },
      ),
    );
  }
}

class _FlowButton extends StatelessWidget {
  const _FlowButton({
    required this.label,
    required this.emoji,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 19, height: 1)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(10, 10, 10, 11),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFAAB4B9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF78858B)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            offset: Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ActionSpec {
  const _ActionSpec(this.label, this.emoji, this.color, this.onPressed);

  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onPressed;
}

int _compareMaintenancePriority(MaintenanceRecord a, MaintenanceRecord b) {
  final severity = _attentionScore(b).compareTo(_attentionScore(a));
  if (severity != 0) return severity;
  final importance = b.importance.compareTo(a.importance);
  if (importance != 0) return importance;
  return a.itemName.compareTo(b.itemName);
}

int _attentionScore(MaintenanceRecord record) {
  if (record.timeOnly) {
    if (record.monthsRemaining <= 0) return 4000 + record.importance;
    if (record.monthsRemaining <= 1) return 3000 + record.importance;
    if (record.monthsRemaining <= 3) return 2000 + record.importance;
    if (record.monthsRemaining <= 6) return 1000 + record.importance;
    return record.importance;
  }
  if (record.milesRemaining <= 0) return 4000 + record.importance;
  if (record.milesRemaining <= 299) return 3000 + record.importance;
  if (record.milesRemaining <= 599) return 2000 + record.importance;
  if (record.milesRemaining <= 900) return 1000 + record.importance;
  return record.importance;
}

Color _recordColor(MaintenanceRecord record) {
  if (record.timeOnly) {
    if (record.monthsRemaining <= 1) return const Color(0xFFE3342F);
    if (record.monthsRemaining <= 3) return const Color(0xFFFF7A00);
    if (record.monthsRemaining <= 6) return const Color(0xFFFFC928);
    return const Color(0xFF20B24A);
  }
  return thresholdColor(record.milesRemaining);
}

String _recordStatus(MaintenanceRecord record) {
  final months = record.monthsRemaining.clamp(-99, 999);
  if (record.timeOnly) {
    return '$months months remaining • time-based renewal';
  }
  return '${formatMiles(record.milesRemaining)} miles • $months months remaining';
}

String formatMiles(int value) {
  final sign = value < 0 ? '-' : '';
  final digits = value.abs().toString();
  final buffer = StringBuffer(sign);
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
