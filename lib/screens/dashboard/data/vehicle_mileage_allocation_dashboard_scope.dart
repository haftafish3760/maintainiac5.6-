/// Dashboard access to durable vehicle-use allocation evidence.
///
/// Owns a read-refresh signal and exposes the published allocation bucket to
/// Dashboard projections. It does not persist, classify, edit Expenses, or
/// change odometer history. Active Day Dashboard panels consume this scope.
library;

import 'package:flutter/widgets.dart';

import '../../../shared/vehicle_mileage_allocation/vehicle_mileage_allocation_durable_store.dart';

class VehicleMileageAllocationDashboardController extends ChangeNotifier {
  VehicleMileageAllocationDashboardController({required this.store});

  final VehicleMileageAllocationDurableStore store;

  /// Signals that bootstrap completed an allocation sync.
  ///
  /// The durable store remains the only source of allocation records.
  void refreshProjection() => notifyListeners();
}

class VehicleMileageAllocationDashboardScope
    extends InheritedNotifier<VehicleMileageAllocationDashboardController> {
  const VehicleMileageAllocationDashboardScope({
    super.key,
    required VehicleMileageAllocationDashboardController controller,
    required super.child,
  }) : super(notifier: controller);

  static VehicleMileageAllocationDashboardController? maybeOf(
    BuildContext context,
  ) => context
      .dependOnInheritedWidgetOfExactType<
        VehicleMileageAllocationDashboardScope
      >()
      ?.notifier;
}
