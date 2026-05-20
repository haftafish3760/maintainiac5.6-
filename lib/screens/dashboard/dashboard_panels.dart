import 'package:flutter/material.dart';

import '../../shared/widgets/flow_placeholder_screen.dart';
import 'vehicle_profile_flow.dart';
import 'vehicle_profile_widgets.dart';

class DashboardContextSelectors extends StatelessWidget {
  const DashboardContextSelectors({
    super.key,
    required this.activeVehicle,
    required this.workProfile,
    required this.onVehicleChanged,
  });

  final VehicleProfilePreview activeVehicle;
  final String workProfile;
  final ValueChanged<VehicleProfilePreview> onVehicleChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(child: _WorkProfileDrawer(workProfile: workProfile)),
          const SizedBox(width: 8),
          Expanded(
            child: ActiveVehicleDrawer(
              activeVehicle: activeVehicle,
              onChanged: onVehicleChanged,
              fullWidth: true,
            ),
          ),
        ],
      ),
    );
  }
}

class AlertCenterStrip extends StatefulWidget {
  const AlertCenterStrip({super.key});

  @override
  State<AlertCenterStrip> createState() => _AlertCenterStripState();
}

class _WorkProfileDrawer extends StatelessWidget {
  const _WorkProfileDrawer({required this.workProfile});

  final String workProfile;

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
                  workProfile,
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const FlowPlaceholderScreen(
          title: 'Work Profiles',
          icon: Icons.work_rounded,
          summary:
              'Work profiles will let users keep jobs, contracts, or business lines separated without forcing everyone to use that workflow.',
          details: [
            'Default users can ignore this and keep one simple work profile.',
            'Users with multiple jobs can create separate profiles for clean reporting.',
            'This screen will also control whether the work profile selector is shown on the dashboard.',
          ],
        ),
      ),
    );
  }
}

class _AlertCenterStripState extends State<AlertCenterStrip> {
  var _visible = true;

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFFD166),
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => _openAlertDetails(context),
              borderRadius: BorderRadius.circular(4),
              child: const _AlertReadout(),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _visible = false),
            tooltip: 'Hide alerts',
            icon: const Icon(Icons.close_rounded),
            color: const Color(0xFFDCE4E7),
          ),
        ],
      ),
    );
  }

  void _openAlertDetails(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close alerts',
      barrierColor: Colors.black.withValues(alpha: 0.28),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 188, 12, 0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: const _AlertDetailsPanel(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AlertDetailsPanel extends StatelessWidget {
  const _AlertDetailsPanel();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE2E8EA),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Alerts',
                    style: TextStyle(
                      color: Color(0xFF101416),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const _AlertCard(
              number: 1,
              appArea: 'Maintenance',
              title: 'Engine oil service approaching',
              detail:
                  'Truck 1 is nearing its engine oil service interval. Review the current odometer reading, confirm whether service has already been completed, or schedule the oil change before it becomes overdue.',
              occurred: 'Today',
              threshold: 'Approximately 420 miles remaining',
            ),
            const SizedBox(height: 8),
            const _AlertCard(
              number: 2,
              appArea: 'Expenses',
              title: 'Fuel receipt needs attachment',
              detail:
                  'A fuel expense from yesterday was saved without receipt documentation. Attach a photo or PDF, or mark the expense as no receipt available so the record is complete.',
              occurred: 'Yesterday',
              threshold: 'Receipt documentation incomplete',
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.number,
    required this.appArea,
    required this.title,
    required this.detail,
    required this.occurred,
    required this.threshold,
  });

  final int number;
  final String appArea;
  final String title;
  final String detail;
  final String occurred;
  final String threshold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF101416), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Alert $number • $appArea',
            style: const TextStyle(
              color: Color(0xFF101416),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF101416),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(
              color: Color(0xFF2F383D),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Date: $occurred\nRecord status: $threshold',
            style: const TextStyle(
              color: Color(0xFF4A555A),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _AlertActionButton(
                icon: Icons.open_in_new_rounded,
                label: appArea == 'Maintenance'
                    ? 'Review Service'
                    : 'Open Record',
              ),
              const _AlertActionButton(
                icon: Icons.schedule_rounded,
                label: 'Remind Later',
              ),
              const _AlertActionButton(
                icon: Icons.push_pin_rounded,
                label: 'Keep Visible',
              ),
              const _AlertActionButton(
                icon: Icons.archive_rounded,
                label: 'Archive',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertActionButton extends StatelessWidget {
  const _AlertActionButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: FilledButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 15),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2E6FA8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _AlertReadout extends StatelessWidget {
  const _AlertReadout();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF171D0F), Color(0xFF050806)],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2B3524), width: 1.1),
      ),
      child: Row(
        children: [
          const Text(
            'ALERTS',
            style: TextStyle(
              color: Color(0xFFFFD166),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '2 items: engine oil service, fuel receipt',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFFE8ECEE),
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
