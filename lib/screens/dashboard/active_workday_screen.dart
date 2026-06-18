import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/odometer/open_odometer_entry.dart';
import '../../shared/state/global_odometer.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../../shared/widgets/flow_placeholder_screen.dart';
import '../expenses/entry/expense_receipt_entry_screen.dart';
import 'active_workday_actions.dart';
import 'active_workday_quick_action_editor.dart';
import 'data/active_workday_store.dart';
import 'vehicle_profile_flow.dart';
import 'vehicle_profile_widgets.dart';

part 'active_workday_context_bar.dart';
part 'active_workday_session_widgets.dart';
part 'active_workday_navigation_helpers.dart';

class ActiveWorkdayScreen extends StatefulWidget {
  const ActiveWorkdayScreen({
    super.key,
    required this.activeVehicle,
    required this.workProfileName,
  });

  final VehicleProfilePreview activeVehicle;
  final String workProfileName;

  @override
  State<ActiveWorkdayScreen> createState() => _ActiveWorkdayScreenState();
}

class _ActiveWorkdayScreenState extends State<ActiveWorkdayScreen> {
  late final DateTime _startedAt;
  Timer? _timer;
  var _elapsed = Duration.zero;
  late var _activeVehicle = widget.activeVehicle;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed = DateTime.now().difference(_startedAt));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeWorkday = ActiveWorkdayScope.of(context);
    final session = activeWorkday.activeSession;
    final currentOdometer = GlobalOdometerScope.of(context).reading;
    final elapsed = session == null
        ? _elapsed
        : DateTime.now().difference(session.startedAt);
    final milesToday = session?.milesSoFar(currentOdometer).toString() ?? '0';

    return AppScreenShell(
      section: AppSection.dashboard,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
        children: [
          const GlobalOdometerHeader(),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _WorkdayContextBar(
                  activeVehicle: _activeVehicle,
                  workProfileName: widget.workProfileName,
                  onVehicleChanged: (vehicle) {
                    setState(() => _activeVehicle = vehicle);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Shift Timer',
                        value: _formatElapsed(elapsed),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricTile(
                        label: 'Miles Today',
                        value: milesToday,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: _SectionLabel('QUICK ACTIONS')),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        appNativeRoute<void>(
                          context,
                          const ActiveWorkdayQuickActionEditor(),
                        ),
                      ),
                      tooltip: 'Edit quick actions',
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: Color(0xFFE2E8EA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: workdayQuickActions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 72,
                  ),
                  itemBuilder: (context, index) {
                    return _QuickActionButton(
                      action: workdayQuickActions[index],
                      onTap: () =>
                          _handleQuickAction(workdayQuickActions[index]),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _SessionActivityList(events: session?.events ?? const []),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatElapsed(Duration elapsed) {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleQuickAction(WorkdayQuickActionSpec action) async {
    switch (action.label) {
      case 'Pause Day':
        await _recordOdometerEvent(
          title: 'Pause Odometer',
          saveLabel: 'Pause Day',
          type: ActiveWorkdayEventType.paused,
        );
      case 'End Day':
        final saved = await _recordOdometerEvent(
          title: 'Ending Odometer',
          saveLabel: 'End Day',
          type: ActiveWorkdayEventType.ended,
        );
        if (saved && mounted) Navigator.of(context).pop();
      case 'Add Fuel':
        await Navigator.of(context).push(
          appNativeRoute<void>(
            context,
            const ExpenseReceiptEntryScreen(initialCategory: 'Fuel'),
          ),
        );
        await _recordStoredEvent(ActiveWorkdayEventType.fuel);
      case 'Expense':
        await Navigator.of(context).push(
          appNativeRoute<void>(context, const ExpenseReceiptEntryScreen()),
        );
        await _recordStoredEvent(ActiveWorkdayEventType.expense);
      case 'Add Stop':
        await _openStopDialog('Stop', ActiveWorkdayEventType.stop);
      case 'Add Pickup':
        await _openStopDialog('Pickup', ActiveWorkdayEventType.pickup);
      case 'Add Drop-Off':
        await _openStopDialog('Drop-off', ActiveWorkdayEventType.dropOff);
      default:
        _openFlow(
          context,
          title: action.flowTitle,
          icon: action.icon,
          summary: action.flowSummary,
          requiresOdometer: action.requiresOdometer,
        );
    }
  }

  Future<bool> _recordOdometerEvent({
    required String title,
    required String saveLabel,
    required ActiveWorkdayEventType type,
  }) async {
    final saved = await openOdometerEntry(
      context,
      title: title,
      saveLabel: saveLabel,
    );
    if (!mounted) return false;
    if (saved) {
      await ActiveWorkdayScope.of(context).addEvent(
        type: type,
        odometerReading: GlobalOdometerScope.of(context).reading,
      );
    }
    return saved;
  }

  Future<void> _recordStoredEvent(
    ActiveWorkdayEventType type, {
    String? note,
  }) async {
    if (!mounted) return;
    await ActiveWorkdayScope.of(context).addEvent(
      type: type,
      odometerReading: GlobalOdometerScope.of(context).reading,
      note: note,
    );
  }

  Future<void> _openStopDialog(String kind, ActiveWorkdayEventType type) async {
    final noteController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101719),
        title: Text(
          'Add $kind',
          style: const TextStyle(
            color: Color(0xFFF0F4F2),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time: ${_timeLabel(DateTime.now())}',
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Odometer: ${GlobalOdometerScope.of(context).displayValue}',
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Stop note',
                hintText: 'Customer, store, pickup, delivery, or break',
                filled: true,
                fillColor: Color(0xFFAAB4B9),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save Stop'),
          ),
        ],
      ),
    );
    final note = noteController.text.trim();
    noteController.dispose();
    if (!mounted) return;
    if (saved == true) {
      await _recordStoredEvent(type, note: note);
    }
  }

  String _timeLabel(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
        ? value.hour - 12
        : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}
