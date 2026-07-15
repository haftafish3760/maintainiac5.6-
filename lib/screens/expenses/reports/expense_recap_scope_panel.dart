part of 'expense_recap_screen.dart';

class _RecapScopePanel extends StatelessWidget {
  const _RecapScopePanel({
    required this.selectedVehicleId,
    required this.selectedWorkProfileId,
    required this.vehicles,
    required this.workProfiles,
    required this.onVehicleChanged,
    required this.onWorkProfileChanged,
  });

  final String selectedVehicleId;
  final String selectedWorkProfileId;
  final List<VehicleProfile> vehicles;
  final List<ExpenseWorkProfile> workProfiles;
  final ValueChanged<String> onVehicleChanged;
  final ValueChanged<String> onWorkProfileChanged;

  @override
  Widget build(BuildContext context) {
    return _RecapPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _RecapPanelHeader(
            eyebrow: 'SCOPE',
            title: 'Grand Total',
            detail: 'Filter durable records without changing them.',
          ),
          const SizedBox(height: 10),
          _RecapScopeDropdown(
            label: 'Work profile',
            value: selectedWorkProfileId,
            entries: [
              const _RecapScopeEntry(
                id: '',
                label: 'All profiles · Grand Total',
              ),
              for (final profile in workProfiles)
                _RecapScopeEntry(id: profile.id, label: profile.name),
            ],
            onChanged: onWorkProfileChanged,
          ),
          const SizedBox(height: 8),
          _RecapScopeDropdown(
            label: 'Vehicle',
            value: selectedVehicleId,
            entries: [
              const _RecapScopeEntry(id: '', label: 'All vehicles'),
              for (final vehicle in vehicles)
                _RecapScopeEntry(id: vehicle.id, label: vehicle.displayName),
            ],
            onChanged: onVehicleChanged,
          ),
        ],
      ),
    );
  }
}

class _RecapScopeEntry {
  const _RecapScopeEntry({required this.id, required this.label});

  final String id;
  final String label;
}

class _RecapScopeDropdown extends StatelessWidget {
  const _RecapScopeDropdown({
    required this.label,
    required this.value,
    required this.entries,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<_RecapScopeEntry> entries;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label:$value'),
      initialValue: entries.any((entry) => entry.id == value) ? value : '',
      isExpanded: true,
      dropdownColor: const Color(0xFF263035),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF1C2326),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final entry in entries)
          DropdownMenuItem(value: entry.id, child: Text(entry.label)),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
