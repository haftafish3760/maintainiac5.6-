// Calendar filtered timeline. This presentation-only control filters the
// read-only timeline; it does not mutate or persist source-owned records.

import 'package:flutter/material.dart';

import 'calendar_flow_models.dart';
import 'calendar_flow_widgets.dart';
import 'calendar_projection_contract.dart';

class CalendarFilteredTimeline extends StatefulWidget {
  const CalendarFilteredTimeline({
    super.key,
    required this.entries,
    required this.onOpen,
    this.enableFiltering = false,
  });

  final List<CalendarTimelineEntry> entries;
  final ValueChanged<CalendarTimelineEntry> onOpen;
  final bool enableFiltering;

  @override
  State<CalendarFilteredTimeline> createState() =>
      _CalendarFilteredTimelineState();
}

class _CalendarFilteredTimelineState extends State<CalendarFilteredTimeline> {
  CalendarProjectionSource? _source;
  CalendarEntryStatus? _status;
  CalendarBusinessClassification? _businessClassification;
  String? _vehicleId;
  String? _workProfileId;

  @override
  Widget build(BuildContext context) {
    final visible =
        widget.entries
            .where(
              (entry) => _source == null || entry.projection?.source == _source,
            )
            .where((entry) => _status == null || entry.status == _status)
            .where(
              (entry) =>
                  _businessClassification == null ||
                  entry.projection?.businessClassification ==
                      _businessClassification,
            )
            .where(
              (entry) =>
                  _vehicleId == null ||
                  entry.projection?.vehicleIds.contains(_vehicleId) == true,
            )
            .where(
              (entry) =>
                  _workProfileId == null ||
                  entry.projection?.workProfileId == _workProfileId,
            )
            .toList()
          ..sort((left, right) => left.timestamp.compareTo(right.timestamp));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.enableFiltering)
          _TimelineFilterPanel(
            source: _source,
            status: _status,
            businessClassification: _businessClassification,
            vehicleId: _vehicleId,
            workProfileId: _workProfileId,
            vehicleIds: _vehicleIds(widget.entries),
            workProfileIds: _workProfileIds(widget.entries),
            onSourceChanged: (value) => setState(() => _source = value),
            onStatusChanged: (value) => setState(() => _status = value),
            onBusinessClassificationChanged: (value) =>
                setState(() => _businessClassification = value),
            onVehicleChanged: (value) => setState(() => _vehicleId = value),
            onWorkProfileChanged: (value) =>
                setState(() => _workProfileId = value),
            onClear:
                _source == null &&
                    _status == null &&
                    _businessClassification == null &&
                    _vehicleId == null &&
                    _workProfileId == null
                ? null
                : () => setState(() {
                    _source = null;
                    _status = null;
                    _businessClassification = null;
                    _vehicleId = null;
                    _workProfileId = null;
                  }),
          ),
        if (widget.enableFiltering) const SizedBox(height: 8),
        if (visible.isEmpty)
          CalendarStatusPanel(
            icon: _hasNoFilters
                ? Icons.event_busy_rounded
                : Icons.filter_alt_off_rounded,
            title: _hasNoFilters || !widget.enableFiltering
                ? 'No entries for this day'
                : 'No matching entries',
            subtitle: _hasNoFilters || !widget.enableFiltering
                ? 'Add a record in its own screen, or plan work for this date.'
                : 'Clear a filter or add an entry in its own screen.',
          )
        else
          for (final entry in visible)
            CalendarTimelineItem(
              entry: entry,
              onTap: () => widget.onOpen(entry),
            ),
      ],
    );
  }

  bool get _hasNoFilters =>
      _source == null &&
      _status == null &&
      _businessClassification == null &&
      _vehicleId == null &&
      _workProfileId == null;
}

class _TimelineFilterPanel extends StatelessWidget {
  const _TimelineFilterPanel({
    required this.source,
    required this.status,
    required this.businessClassification,
    required this.vehicleId,
    required this.workProfileId,
    required this.vehicleIds,
    required this.workProfileIds,
    required this.onSourceChanged,
    required this.onStatusChanged,
    required this.onBusinessClassificationChanged,
    required this.onVehicleChanged,
    required this.onWorkProfileChanged,
    required this.onClear,
  });

  final CalendarProjectionSource? source;
  final CalendarEntryStatus? status;
  final CalendarBusinessClassification? businessClassification;
  final String? vehicleId;
  final String? workProfileId;
  final List<String> vehicleIds;
  final List<String> workProfileIds;
  final ValueChanged<CalendarProjectionSource?> onSourceChanged;
  final ValueChanged<CalendarEntryStatus?> onStatusChanged;
  final ValueChanged<CalendarBusinessClassification?>
  onBusinessClassificationChanged;
  final ValueChanged<String?> onVehicleChanged;
  final ValueChanged<String?> onWorkProfileChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Filter entries',
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF182227),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF53656D)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 8.0;
          final columns = constraints.maxWidth >= 760 ? 3 : 2;
          final fieldWidth =
              (constraints.maxWidth - (spacing * (columns - 1))) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: constraints.maxWidth,
                child: const Text(
                  'FILTER ENTRIES',
                  style: TextStyle(
                    color: Color(0xFFF7FAF4),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<CalendarProjectionSource?>(
                  initialValue: source,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Entry type'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All entry types'),
                    ),
                    for (final item in CalendarProjectionSource.values)
                      DropdownMenuItem(
                        value: item,
                        child: Text(_sourceLabel(item)),
                      ),
                  ],
                  onChanged: onSourceChanged,
                ),
              ),
              if (vehicleIds.isNotEmpty)
                SizedBox(
                  width: fieldWidth,
                  child: DropdownButtonFormField<String?>(
                    initialValue: vehicleId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Vehicle'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All vehicles'),
                      ),
                      for (final id in vehicleIds)
                        DropdownMenuItem(value: id, child: Text(id)),
                    ],
                    onChanged: onVehicleChanged,
                  ),
                ),
              if (workProfileIds.isNotEmpty)
                SizedBox(
                  width: fieldWidth,
                  child: DropdownButtonFormField<String?>(
                    initialValue: workProfileId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Work profile',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All profiles'),
                      ),
                      for (final id in workProfileIds)
                        DropdownMenuItem(value: id, child: Text(id)),
                    ],
                    onChanged: onWorkProfileChanged,
                  ),
                ),
              SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<CalendarEntryStatus?>(
                  initialValue: status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Review state'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All states')),
                    DropdownMenuItem(
                      value: CalendarEntryStatus.planned,
                      child: Text('Planned'),
                    ),
                    DropdownMenuItem(
                      value: CalendarEntryStatus.completed,
                      child: Text('Confirmed'),
                    ),
                    DropdownMenuItem(
                      value: CalendarEntryStatus.needsAttention,
                      child: Text('Needs review'),
                    ),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<CalendarBusinessClassification?>(
                  initialValue: businessClassification,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Business use'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All use types')),
                    DropdownMenuItem(
                      value: CalendarBusinessClassification.business,
                      child: Text('Business'),
                    ),
                    DropdownMenuItem(
                      value: CalendarBusinessClassification.personal,
                      child: Text('Personal'),
                    ),
                    DropdownMenuItem(
                      value: CalendarBusinessClassification.mixed,
                      child: Text('Business and personal'),
                    ),
                    DropdownMenuItem(
                      value: CalendarBusinessClassification.unclassified,
                      child: Text('Needs classification'),
                    ),
                  ],
                  onChanged: onBusinessClassificationChanged,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear_all_rounded),
                  label: const Text('Clear filters'),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

List<String> _vehicleIds(Iterable<CalendarTimelineEntry> entries) =>
    entries
        .expand((entry) => entry.projection?.vehicleIds ?? const <String>[])
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

List<String> _workProfileIds(Iterable<CalendarTimelineEntry> entries) =>
    entries
        .map((entry) => entry.projection?.workProfileId?.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

String _sourceLabel(CalendarProjectionSource source) => switch (source) {
  CalendarProjectionSource.activeWorkday => 'Active workday',
  CalendarProjectionSource.trip => 'Trip',
  CalendarProjectionSource.stop => 'Stop',
  CalendarProjectionSource.job => 'Job',
  CalendarProjectionSource.expense => 'Expense',
  CalendarProjectionSource.receipt => 'Receipt',
  CalendarProjectionSource.invoice => 'Invoice',
  CalendarProjectionSource.estimate => 'Estimate',
  CalendarProjectionSource.payment => 'Payment',
  CalendarProjectionSource.maintenance => 'Maintenance',
  CalendarProjectionSource.inventory => 'Inventory',
  CalendarProjectionSource.reminder => 'Reminder',
  CalendarProjectionSource.calendarSchedule => 'Calendar schedule',
  CalendarProjectionSource.workTime => 'Work time',
  CalendarProjectionSource.odometer => 'Odometer',
  CalendarProjectionSource.vehicleProfile => 'Vehicle profile',
};
