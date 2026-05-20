import 'package:flutter/material.dart';

import '../../shared/theme/app_action_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_button.dart';
import 'maintenance_models.dart';
import 'maintenance_setup_screen.dart';
import 'maintenance_svg_icon.dart';

class MaintenanceWorkSourceScreen extends StatefulWidget {
  const MaintenanceWorkSourceScreen({super.key});

  @override
  State<MaintenanceWorkSourceScreen> createState() =>
      _MaintenanceWorkSourceScreenState();
}

class _MaintenanceWorkSourceScreenState
    extends State<MaintenanceWorkSourceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance Setup')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
            children: const [MaintenanceTrackingSelectionPanel()],
          ),
        ),
      ),
    );
  }
}

class MaintenanceTrackingSelectionPanel extends StatefulWidget {
  const MaintenanceTrackingSelectionPanel({super.key, this.showCancel = true});

  final bool showCancel;

  @override
  State<MaintenanceTrackingSelectionPanel> createState() =>
      _MaintenanceTrackingSelectionPanelState();
}

class _MaintenanceTrackingSelectionPanelState
    extends State<MaintenanceTrackingSelectionPanel> {
  final Set<MaintenanceCatalogItem> _selected = <MaintenanceCatalogItem>{};

  @override
  Widget build(BuildContext context) {
    return _MaintenanceSetupSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to Maintenance',
            style: TextStyle(
              color: Color(0xFFE9EEF1),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Let's get your maintenance tracking set up.",
            style: TextStyle(
              color: Color(0xFFE9EEF1),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select the maintenance items you want Mainteniac to help you track.',
            style: TextStyle(
              color: Color(0xFFCAD4D8),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'You can change these selections at any time later in the settings menu.',
            style: TextStyle(
              color: Color(0xFFB8C4C8),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in maintenanceCatalog) ...[
            _MaintenanceTrackOption(
              item: item,
              selected: _selected.contains(item),
              onTap: () => _toggle(item),
            ),
            const SizedBox(height: 7),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.showCancel) ...[
                AppButton(
                  label: 'Cancel',
                  tone: AppButtonTone.destructive,
                  compact: true,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
              ],
              AppButton(
                label: 'Continue',
                tone: AppButtonTone.commit,
                compact: true,
                onPressed: _selected.isEmpty ? null : _continue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggle(MaintenanceCatalogItem item) {
    setState(() {
      _selected.contains(item) ? _selected.remove(item) : _selected.add(item);
    });
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MaintenanceSetupScreen(
          workSource: WorkSource.me,
          initialItems: _selected.toList(),
        ),
      ),
    );
  }
}

class _MaintenanceSetupSurface extends StatelessWidget {
  const _MaintenanceSetupSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF303A3E), Color(0xFF20282B), Color(0xFF151B1D)],
          stops: [0, 0.55, 1],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF67747A), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MaintenanceTrackOption extends StatelessWidget {
  const _MaintenanceTrackOption({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final MaintenanceCatalogItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? const Color(0xFF173A26)
        : const Color(0xFF293237);
    final border = selected
        ? AppActionColors.positive
        : const Color(0xFF647177);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Ink(
          height: 58,
          padding: const EdgeInsets.fromLTRB(8, 0, 9, 0),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: border, width: selected ? 2 : 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppActionColors.positive.withValues(alpha: 0.20),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE9EEF1), Color(0xFFBFC9CE)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF0D1214),
                    width: 1.4,
                  ),
                ),
                child: MaintenanceSvgIcon(itemName: item.name, size: 38),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE9EEF1),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SelectionBox(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionBox extends StatelessWidget {
  const _SelectionBox({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: selected ? AppActionColors.positive : const Color(0xFF182024),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: selected ? AppActionColors.positive : const Color(0xFFE2E8EA),
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
          : null,
    );
  }
}
