part of 'expense_recap_screen.dart';

class _RecapScopePanel extends StatelessWidget {
  const _RecapScopePanel({
    required this.workProfileId,
    required this.vehicleId,
    required this.jobId,
    required this.workProfiles,
    required this.vehicles,
    required this.jobs,
    required this.onWorkProfileChanged,
    required this.onVehicleChanged,
    required this.onJobChanged,
  });

  final String workProfileId;
  final String vehicleId;
  final String jobId;
  final List<ExpenseWorkProfileRecord> workProfiles;
  final List<ExpenseVehicleProfileRecord> vehicles;
  final List<ExpenseJobRecord> jobs;
  final ValueChanged<String> onWorkProfileChanged;
  final ValueChanged<String> onVehicleChanged;
  final ValueChanged<String> onJobChanged;

  @override
  Widget build(BuildContext context) {
    return _RecapPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _RecapPanelHeader(
            eyebrow: 'SCOPE',
            title: 'Everything together',
            detail: 'Optionally narrow this recap without changing records.',
          ),
          const SizedBox(height: 8),
          _ScopeDropdown(
            label: 'Work profile',
            value: workProfileId,
            allLabel: 'All work profiles',
            options: [
              for (final profile in workProfiles)
                (id: profile.id, label: profile.name),
            ],
            onChanged: onWorkProfileChanged,
          ),
          const SizedBox(height: 8),
          _ScopeDropdown(
            label: 'Vehicle',
            value: vehicleId,
            allLabel: 'All vehicles',
            options: [
              for (final vehicle in vehicles)
                (id: vehicle.id, label: vehicle.displayName),
            ],
            onChanged: onVehicleChanged,
          ),
          const SizedBox(height: 8),
          _ScopeDropdown(
            label: 'Job',
            value: jobId,
            allLabel: 'All jobs and general expenses',
            options: [for (final job in jobs) (id: job.id, label: job.name)],
            onChanged: onJobChanged,
          ),
        ],
      ),
    );
  }
}

class _ScopeDropdown extends StatelessWidget {
  const _ScopeDropdown({
    required this.label,
    required this.value,
    required this.allLabel,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String allLabel;
  final List<({String id, String label})> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final availableValues = options.map((option) => option.id).toSet();
    final selected = availableValues.contains(value) ? value : '';
    return DropdownButtonFormField<String>(
      key: ValueKey('recap_scope_$label:$selected'),
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem(value: '', child: Text(allLabel)),
        for (final option in options)
          DropdownMenuItem(value: option.id, child: Text(option.label)),
      ],
      onChanged: (next) => onChanged(next ?? ''),
    );
  }
}
