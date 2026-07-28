import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/theme/app_action_colors.dart';

enum WorkdayQuickActionKind {
  pauseDay,
  resumeDay,
  endDay,
  addFuel,
  addStop,
  addPickup,
  addDropOff,
  expense,
  payment,
  invoice,
  maintenance,
  materials,
  receipt,
  reminder,
  estimate,
  note,
  reviewStops,
  reviewGpsTrip,
  stopGpsTracking,
  tripDetails,
  retryTripLog,
  gpsSettings,
}

class WorkdayQuickActionSpec {
  const WorkdayQuickActionSpec({
    required this.kind,
    required this.icon,
    required this.label,
    required this.color,
    this.requiresOdometer = false,
  });

  final WorkdayQuickActionKind kind;
  final IconData icon;
  final String label;
  final Color color;
  final bool requiresOdometer;
}

const workdayQuickActions = [
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.pauseDay,
    icon: Icons.pause_rounded,
    label: 'Pause Day',
    color: Color(0xFFFFB02E),
    requiresOdometer: true,
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.endDay,
    icon: Icons.stop_rounded,
    label: 'End Day',
    color: AppActionColors.danger,
    requiresOdometer: true,
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.addFuel,
    icon: Icons.local_gas_station_rounded,
    label: 'Add Fuel',
    color: Color(0xFF1CA7E8),
    requiresOdometer: true,
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.addStop,
    icon: Icons.place_rounded,
    label: 'Add Stop',
    color: Color(0xFF1CA7E8),
    requiresOdometer: true,
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.addPickup,
    icon: Icons.archive_rounded,
    label: 'Add Pickup',
    color: AppActionColors.positive,
    requiresOdometer: true,
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.addDropOff,
    icon: Icons.outbox_rounded,
    label: 'Add Drop-Off',
    color: Color(0xFF9E3DDF),
    requiresOdometer: true,
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.expense,
    icon: Icons.receipt_long_rounded,
    label: 'Expense',
    color: Color(0xFFFF6F3D),
    requiresOdometer: true,
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.payment,
    icon: Icons.payments_rounded,
    label: 'Payment',
    color: AppActionColors.positive,
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.invoice,
    icon: Icons.description_rounded,
    label: 'Invoice',
    color: Color(0xFF607D8B),
  ),
];

const availableWorkdayQuickActions = [
  ...workdayQuickActions,
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.maintenance,
    icon: Icons.build_rounded,
    label: 'Maintenance',
    color: Color(0xFFFF9F1C),
    requiresOdometer: true,
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.materials,
    icon: Icons.inventory_2_rounded,
    label: 'Materials',
    color: Color(0xFF8F6CEB),
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.receipt,
    icon: Icons.camera_alt_rounded,
    label: 'Receipt',
    color: Color(0xFFFFD166),
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.reminder,
    icon: Icons.event_available_rounded,
    label: 'Reminder',
    color: Color(0xFF4FE8FF),
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.estimate,
    icon: Icons.request_quote_rounded,
    label: 'Estimate',
    color: Color(0xFF78909C),
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.note,
    icon: Icons.note_alt_rounded,
    label: 'Note',
    color: Color(0xFFB9C3C7),
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.reviewStops,
    icon: Icons.directions_walk_rounded,
    label: 'Review Stops',
    color: Color(0xFFFFB02E),
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.reviewGpsTrip,
    icon: Icons.fact_check_rounded,
    label: 'Review GPS',
    color: Color(0xFF1CA7E8),
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.stopGpsTracking,
    icon: Icons.gps_off_rounded,
    label: 'Stop GPS',
    color: AppActionColors.danger,
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.tripDetails,
    icon: Icons.route_rounded,
    label: 'Trip Details',
    color: Color(0xFF8F6CEB),
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.retryTripLog,
    icon: Icons.sync_rounded,
    label: 'Retry TripLog',
    color: Color(0xFF78909C),
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.gpsSettings,
    icon: Icons.gps_fixed_rounded,
    label: 'GPS Settings',
    color: Color(0xFF607D8B),
  ),
];

const defaultWorkdayQuickActionKinds = [
  WorkdayQuickActionKind.pauseDay,
  WorkdayQuickActionKind.endDay,
  WorkdayQuickActionKind.addFuel,
  WorkdayQuickActionKind.addStop,
  WorkdayQuickActionKind.addPickup,
  WorkdayQuickActionKind.addDropOff,
  WorkdayQuickActionKind.expense,
  WorkdayQuickActionKind.payment,
  WorkdayQuickActionKind.invoice,
];

class WorkdayQuickActionLayout {
  const WorkdayQuickActionLayout({required this.activeKinds});

  factory WorkdayQuickActionLayout.defaults() => const WorkdayQuickActionLayout(
    activeKinds: defaultWorkdayQuickActionKinds,
  );

  factory WorkdayQuickActionLayout.fromMap(Map<dynamic, dynamic> map) {
    final rawKinds = map['activeKinds'];
    if (rawKinds is! Iterable) return WorkdayQuickActionLayout.defaults();
    return WorkdayQuickActionLayout(
      activeKinds: _sanitizeActionKinds(
        rawKinds.map((value) => value?.toString() ?? ''),
      ),
    );
  }

  final List<WorkdayQuickActionKind> activeKinds;

  List<WorkdayQuickActionSpec> get activeActions => [
    for (final kind in activeKinds)
      if (_actionByKind[kind] != null) _actionByKind[kind]!,
  ];

  Map<String, Object?> toMap() => {
    'activeKinds': activeKinds.map((kind) => kind.name).toList(),
  };
}

List<WorkdayQuickActionKind> _sanitizeActionKinds(Iterable<String> rawKinds) {
  final selected = <WorkdayQuickActionKind>[];
  var hadSavedValues = false;
  for (final rawKind in rawKinds.take(availableWorkdayQuickActions.length)) {
    hadSavedValues = true;
    final kind = _actionKindFromName(rawKind);
    if (kind == null || selected.contains(kind)) continue;
    selected.add(kind);
  }
  return selected.isEmpty && hadSavedValues
      ? List.unmodifiable(defaultWorkdayQuickActionKinds)
      : List.unmodifiable(selected);
}

WorkdayQuickActionKind? _actionKindFromName(String rawKind) {
  final clean = rawKind.trim();
  for (final kind in WorkdayQuickActionKind.values) {
    if (kind.name == clean) return kind;
  }
  return null;
}

final Map<WorkdayQuickActionKind, WorkdayQuickActionSpec> _actionByKind = {
  for (final action in availableWorkdayQuickActions) action.kind: action,
};

class WorkdayQuickActionLayoutController extends ChangeNotifier {
  WorkdayQuickActionLayoutController._(this._box, this._layout);
  WorkdayQuickActionLayoutController.memory([WorkdayQuickActionLayout? layout])
    : _box = null,
      _layout = layout ?? WorkdayQuickActionLayout.defaults();

  static const boxName = 'dashboard_quick_action_layout';
  static const _layoutKey = 'activeWorkday';

  final Box<dynamic>? _box;
  WorkdayQuickActionLayout _layout;

  WorkdayQuickActionLayout get layout => _layout;

  static Future<WorkdayQuickActionLayoutController> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    final stored = box.get(_layoutKey);
    return WorkdayQuickActionLayoutController._(
      box,
      stored is Map
          ? WorkdayQuickActionLayout.fromMap(stored)
          : WorkdayQuickActionLayout.defaults(),
    );
  }

  Future<void> update(WorkdayQuickActionLayout layout) async {
    final normalized = WorkdayQuickActionLayout.fromMap(layout.toMap());
    if (_sameActionKinds(_layout.activeKinds, normalized.activeKinds)) return;
    _layout = normalized;
    await _box?.put(_layoutKey, normalized.toMap());
    notifyListeners();
  }
}

class WorkdayQuickActionLayoutScope
    extends InheritedNotifier<WorkdayQuickActionLayoutController> {
  const WorkdayQuickActionLayoutScope({
    super.key,
    required WorkdayQuickActionLayoutController controller,
    required super.child,
  }) : super(notifier: controller);

  static WorkdayQuickActionLayoutController? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<WorkdayQuickActionLayoutScope>()
          ?.notifier;
}

bool _sameActionKinds(
  List<WorkdayQuickActionKind> left,
  List<WorkdayQuickActionKind> right,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
