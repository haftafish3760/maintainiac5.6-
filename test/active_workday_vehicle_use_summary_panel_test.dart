// Regression coverage for the opt-in Active Day vehicle-use summary.
//
// Owns presentation-level evidence tests. It does not test persistence,
// Expense behavior, GPS, or odometer entry. The Active Day Dashboard consumes
// this panel only as a read-only projection of confirmed mileage.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/active_workday_vehicle_use_summary_panel.dart';
import 'package:maintaniac/screens/dashboard/data/vehicle_mileage_allocation_dashboard_scope.dart';
import 'package:maintaniac/shared/records/maintainiac_durable_record_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';
import 'package:maintaniac/shared/trip_tracking/vehicle_mileage_allocation.dart';
import 'package:maintaniac/shared/vehicle_mileage_allocation/vehicle_mileage_allocation_durable_store.dart';

void main() {
  final day = DateTime.utc(2026, 8, 1);

  VehicleMileageAllocationRecord allocation() =>
      VehicleMileageAllocationRecord.confirmed(
        id: 'allocation-1',
        vehicleId: 'vehicle-1',
        sourceType: 'odometer',
        sourceId: 'odometer-1',
        sourceRevision: 1,
        occurredAt: day.add(const Duration(hours: 12)),
        confirmedAt: day.add(const Duration(hours: 12, minutes: 1)),
        use: VehicleMileageAllocationUse.business,
        distanceTenths: 125,
      );

  Widget subject({
    required VehicleMileageAllocationDashboardController controller,
    required TripTrackingSettings settings,
  }) {
    return MaterialApp(
      home: VehicleMileageAllocationDashboardScope(
        controller: controller,
        child: TripTrackingSettingsScope(
          controller: TripTrackingSettingsController.memory(settings),
          child: Scaffold(
            body: ActiveWorkdayVehicleUseSummaryPanel(
              vehicleId: 'vehicle-1',
              day: day,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('stays hidden until the user opts in', (tester) async {
    final store = VehicleMileageAllocationDurableStore(
      records: MaintainiacDurableRecordStore.memory(),
    );
    final controller = VehicleMileageAllocationDashboardController(
      store: store,
    );
    await store.save(allocation());

    await tester.pumpWidget(
      subject(controller: controller, settings: const TripTrackingSettings()),
    );

    expect(find.text('VEHICLE USE'), findsNothing);
  });

  testWidgets('shows only confirmed mileage as a read-only summary', (
    tester,
  ) async {
    final store = VehicleMileageAllocationDurableStore(
      records: MaintainiacDurableRecordStore.memory(),
    );
    final controller = VehicleMileageAllocationDashboardController(
      store: store,
    );
    await store.save(allocation());

    await tester.pumpWidget(
      subject(
        controller: controller,
        settings: const TripTrackingSettings(
          vehicleMileageAllocationEnabled: true,
        ),
      ),
    );

    expect(find.text('VEHICLE USE'), findsOneWidget);
    expect(find.text('100.0% business'), findsOneWidget);
    expect(find.textContaining('12.5 confirmed mi today'), findsOneWidget);
    expect(find.textContaining('based on confirmed mileage'), findsOneWidget);
  });

  testWidgets('refreshes after bootstrap persists confirmed evidence', (
    tester,
  ) async {
    final store = VehicleMileageAllocationDurableStore(
      records: MaintainiacDurableRecordStore.memory(),
    );
    final controller = VehicleMileageAllocationDashboardController(
      store: store,
    );
    await tester.pumpWidget(
      subject(
        controller: controller,
        settings: const TripTrackingSettings(
          vehicleMileageAllocationEnabled: true,
        ),
      ),
    );
    expect(find.text('Review needed'), findsOneWidget);

    await store.save(allocation());
    controller.refreshProjection();
    await tester.pump();

    expect(find.text('100.0% business'), findsOneWidget);
  });
}
