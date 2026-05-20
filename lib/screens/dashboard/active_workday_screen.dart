import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/widgets/app_screen_shell.dart';
import '../../shared/widgets/flow_placeholder_screen.dart';
import 'active_workday_actions.dart';
import 'active_workday_quick_action_editor.dart';
import 'vehicle_profile_flow.dart';
import 'vehicle_profile_widgets.dart';

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
                        value: _formatElapsed(_elapsed),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: _MetricTile(label: 'Miles Today', value: '0'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: _SectionLabel('QUICK ACTIONS')),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
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
                    );
                  },
                ),
                const SizedBox(height: 12),
                const _SessionActivityList(),
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
}

class _WorkdayContextBar extends StatelessWidget {
  const _WorkdayContextBar({
    required this.activeVehicle,
    required this.workProfileName,
    required this.onVehicleChanged,
  });

  final VehicleProfilePreview activeVehicle;
  final String workProfileName;
  final ValueChanged<VehicleProfilePreview> onVehicleChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _WorkProfilePanel(workProfileName: workProfileName)),
        const SizedBox(width: 8),
        Expanded(
          child: ActiveVehicleDrawer(
            activeVehicle: activeVehicle,
            onChanged: onVehicleChanged,
            fullWidth: true,
          ),
        ),
      ],
    );
  }
}

class _WorkProfilePanel extends StatelessWidget {
  const _WorkProfilePanel({required this.workProfileName});

  final String workProfileName;

  @override
  Widget build(BuildContext context) {
    return VehicleProfilePanel(
      label: 'WORK PROFILE',
      child: InkWell(
        onTap: () => _openWorkProfiles(context),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 7, 8),
          child: Row(
            children: [
              const Text(
                '💼',
                textScaler: TextScaler.noScaling,
                style: TextStyle(fontSize: 18, height: 1),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  workProfileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF101416),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _openWorkProfiles(BuildContext context) {
    _openFlow(
      context,
      title: 'Work Profiles',
      icon: Icons.work_rounded,
      summary:
          'Work profiles keep jobs, contracts, or business lines separated while preserving the active day workflow.',
      requiresOdometer: false,
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      decoration: BoxDecoration(
        color: const Color(0xFF101416),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF59636A)),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: Color(0xFF50F77A),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action});

  final WorkdayQuickActionSpec action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openFlow(
        context,
        title: action.flowTitle,
        icon: action.icon,
        summary: action.flowSummary,
        requiresOdometer: action.requiresOdometer,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: action.color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: action.color.withValues(alpha: 0.42),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              action.emoji,
              textScaler: TextScaler.noScaling,
              style: const TextStyle(fontSize: 29, height: 1),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            action.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionActivityList extends StatelessWidget {
  const _SessionActivityList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SectionLabel('CURRENT SESSION ACTIVITY'),
        SizedBox(height: 8),
        _SessionRow(time: 'Now', text: 'Workday started'),
        _SessionRow(time: 'Next', text: 'Quick actions will log entries here'),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.time, required this.text});

  final String time;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF151B1E),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF3E4A50)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              time,
              style: const TextStyle(
                color: Color(0xFF50F77A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFE2E8EA),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xFFE2E8EA),
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

void _openFlow(
  BuildContext context, {
  required String title,
  required IconData icon,
  required String summary,
  required bool requiresOdometer,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FlowPlaceholderScreen(
        title: title,
        icon: icon,
        summary: summary,
        requiresOdometer: requiresOdometer,
      ),
    ),
  );
}
