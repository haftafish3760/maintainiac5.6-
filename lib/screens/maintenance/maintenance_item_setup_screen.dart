import 'package:flutter/material.dart';

import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/industrial_panel.dart';
import '../../shared/widgets/record_form_fields.dart' show RecordDropdownField;
import '../../shared/widgets/record_text_field.dart';
import 'maintenance_models.dart';

class MaintenanceItemSetupScreen extends StatefulWidget {
  const MaintenanceItemSetupScreen({
    required this.items,
    required this.entries,
    super.key,
  });

  final List<MaintenanceCatalogItem> items;
  final List<ReceiptLineEntry> entries;

  @override
  State<MaintenanceItemSetupScreen> createState() =>
      _MaintenanceItemSetupScreenState();
}

class _MaintenanceItemSetupScreenState
    extends State<MaintenanceItemSetupScreen> {
  late final Map<String, _SetupDraft> _drafts = {
    for (final item in widget.items) item.name: _SetupDraft.fromItem(item),
  };

  @override
  void dispose() {
    for (final draft in _drafts.values) {
      draft.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            padding: const EdgeInsets.all(10),
            children: [
              const AppScreenHeader(title: 'Maintenance Item Setup'),
              const SizedBox(height: 10),
              for (final item in widget.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ItemSetupPanel(
                    item: item,
                    draft: _drafts[item.name]!,
                    entries: widget.entries
                        .where((entry) => entry.itemName == item.name)
                        .toList(),
                  ),
                ),
              IndustrialPanel(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: 'Save Maintenance Setup',
                    tone: AppButtonTone.commit,
                    onPressed: _save,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final state = AppStateScope.of(context);
    final records = <MaintenanceRecord>[];
    for (final item in widget.items) {
      final draft = _drafts[item.name]!;
      records.add(
        MaintenanceRecord(
          itemName: item.name,
          vehicleName: draft.vehicleName.isEmpty
              ? (state.activeVehicle?.nickname ?? 'Current Vehicle')
              : draft.vehicleName,
          intervalMiles: draft.intervalMiles,
          milesSinceService: draft.milesSinceService,
          intervalMonths: draft.intervalMonths,
          monthsSinceService: draft.monthsSinceService,
          importance: item.importance,
          timeOnly: item.timeOnly,
        ),
      );
    }
    state.addMaintenanceRecords(records);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _ItemSetupPanel extends StatefulWidget {
  const _ItemSetupPanel({
    required this.item,
    required this.draft,
    required this.entries,
  });

  final MaintenanceCatalogItem item;
  final _SetupDraft draft;
  final List<ReceiptLineEntry> entries;

  @override
  State<_ItemSetupPanel> createState() => _ItemSetupPanelState();
}

class _ItemSetupPanelState extends State<_ItemSetupPanel> {
  bool _advanced = false;
  bool _reminders = false;
  bool _inApp = true;
  bool _push = false;
  bool _sound = false;

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final state = AppStateScope.of(context);
    return IndustrialPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.item.icon, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.item.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (widget.entries.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final entry in widget.entries)
              Text(
                '${entry.productName.isEmpty ? entry.itemName : entry.productName} • ${entry.totalUnits.toStringAsFixed(1)} ${entry.measurement}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
          ],
          const SizedBox(height: 10),
          if (state.vehicles.length > 1)
            RecordDropdownField<String>(
              label: 'Vehicle',
              value: draft.vehicleName.isEmpty
                  ? state.activeVehicle?.nickname ??
                        state.vehicles.first.nickname
                  : draft.vehicleName,
              items: state.vehicles.map((vehicle) => vehicle.nickname).toList(),
              itemLabel: (nickname) => state.vehicles
                  .firstWhere((vehicle) => vehicle.nickname == nickname)
                  .displayName,
              onChanged: (value) => setState(() => draft.vehicleName = value),
            ),
          const SizedBox(height: 8),
          const Text(
            'Service Starting Point',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RecordTextField(
                  label: 'Last service odometer',
                  controller: draft.lastOdometer,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RecordTextField(
                  label: 'Estimated miles since',
                  controller: draft.estimatedMiles,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RecordTextField(
                  label: 'Last service date',
                  controller: draft.lastDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RecordTextField(
                  label: 'Estimated months since',
                  controller: draft.estimatedMonths,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Interval', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _MilesDropdown(draft: draft)),
              const SizedBox(width: 8),
              Expanded(child: _MonthsDropdown(draft: draft)),
            ],
          ),
          const SizedBox(height: 10),
          _DueRecap(draft: draft, currentOdometer: state.odometer),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Advanced Details',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            value: _advanced,
            onChanged: (value) => setState(() => _advanced = value),
          ),
          if (_advanced) ...[
            Row(
              children: [
                Expanded(
                  child: RecordTextField(
                    label: widget.item.detailA,
                    controller: draft.detailA,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RecordTextField(
                    label: widget.item.detailB,
                    controller: draft.detailB,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Maintenance Reminders',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: const Text('Off until you turn them on.'),
            value: _reminders,
            onChanged: (value) => setState(() => _reminders = value),
          ),
          if (_reminders) ...[
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('In-app alerts'),
              value: _inApp,
              onChanged: (value) => setState(() => _inApp = value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Push notifications'),
              value: _push,
              onChanged: (value) => setState(() => _push = value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sound alerts'),
              value: _sound,
              onChanged: (value) => setState(() => _sound = value ?? false),
            ),
          ],
        ],
      ),
    );
  }
}

class _MilesDropdown extends StatelessWidget {
  const _MilesDropdown({required this.draft});

  final _SetupDraft draft;

  @override
  Widget build(BuildContext context) {
    final values = [
      3000,
      3500,
      4000,
      4500,
      5000,
      5500,
      6000,
      7500,
      10000,
      12000,
      24000,
      30000,
      50000,
      60000,
      100000,
    ];
    return RecordDropdownField<int>(
      label: 'Miles interval',
      value: values.contains(draft.intervalMiles)
          ? draft.intervalMiles
          : values.first,
      items: values,
      itemLabel: (value) => '$value',
      onChanged: (value) => draft.intervalMiles = value,
    );
  }
}

class _MonthsDropdown extends StatelessWidget {
  const _MonthsDropdown({required this.draft});

  final _SetupDraft draft;

  @override
  Widget build(BuildContext context) {
    final values = [3, 6, 9, 12, 18, 24, 36, 48, 60];
    return RecordDropdownField<int>(
      label: 'Time interval',
      value: values.contains(draft.intervalMonths)
          ? draft.intervalMonths
          : values.first,
      items: values,
      itemLabel: (value) => '$value months',
      onChanged: (value) => draft.intervalMonths = value,
    );
  }
}

class _DueRecap extends StatelessWidget {
  const _DueRecap({required this.draft, required this.currentOdometer});

  final _SetupDraft draft;
  final int currentOdometer;

  @override
  Widget build(BuildContext context) {
    final milesUsed = draft.milesSinceService;
    final remaining = draft.intervalMiles - milesUsed;
    final dueOdometer = currentOdometer + remaining;
    final color = thresholdColor(remaining);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '$remaining miles remaining • Due at odometer $dueOdometer',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SetupDraft {
  _SetupDraft.fromItem(MaintenanceCatalogItem item)
    : intervalMiles = item.defaultMiles,
      intervalMonths = item.defaultMonths;

  String vehicleName = '';
  int intervalMiles;
  int intervalMonths;
  final lastOdometer = TextEditingController();
  final estimatedMiles = TextEditingController(text: '0');
  final lastDate = TextEditingController();
  final estimatedMonths = TextEditingController(text: '0');
  final detailA = TextEditingController();
  final detailB = TextEditingController();

  int get milesSinceService => int.tryParse(estimatedMiles.text) ?? 0;
  int get monthsSinceService => int.tryParse(estimatedMonths.text) ?? 0;

  void dispose() {
    lastOdometer.dispose();
    estimatedMiles.dispose();
    lastDate.dispose();
    estimatedMonths.dispose();
    detailA.dispose();
    detailB.dispose();
  }
}
