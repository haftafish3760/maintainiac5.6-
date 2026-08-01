/// Compact Active Day vehicle-use summary from confirmed mileage evidence.
///
/// Owns only transparent, read-only Dashboard presentation. It does not edit
/// expenses, classify trips, persist allocations, or infer business use.
/// Consumed by ActiveWorkdayScreen when the user has explicitly opted in.
library;

import 'package:flutter/material.dart';

import '../../shared/trip_tracking/trip_tracking_settings_store.dart';
import 'data/vehicle_mileage_allocation_dashboard_projection.dart';
import 'data/vehicle_mileage_allocation_dashboard_scope.dart';

class ActiveWorkdayVehicleUseSummaryPanel extends StatelessWidget {
  const ActiveWorkdayVehicleUseSummaryPanel({
    super.key,
    required this.vehicleId,
    required this.day,
  });

  final String vehicleId;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final dashboard = VehicleMileageAllocationDashboardScope.maybeOf(context);
    final settings = TripTrackingSettingsScope.maybeOf(context)?.settings;
    if (dashboard == null ||
        settings?.vehicleMileageAllocationEnabled != true) {
      return const SizedBox.shrink();
    }
    final dayStart = DateTime(day.year, day.month, day.day);
    final projection =
        VehicleMileageAllocationDashboardProjection.fromDurableStore(
          store: dashboard.store,
          settings: settings!,
          vehicleId: vehicleId,
          from: dayStart,
          until: dayStart.add(const Duration(days: 1)),
        );
    final percent = projection.suggestedBusinessPercent;
    final summary = projection.readModel.summary;
    final accent = projection.requiresReview || percent == null
        ? const Color(0xFFFFC46B)
        : const Color(0xFF50F77A);
    final value = percent == null
        ? 'Review needed'
        : '${(percent * 100).toStringAsFixed(1)}% business';
    final mileage = summary.totalTenths / 10;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF101416),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF59636A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VEHICLE USE',
            style: TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: .6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${mileage.toStringAsFixed(1)} confirmed mi today. ${projection.explanation}',
            style: const TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
