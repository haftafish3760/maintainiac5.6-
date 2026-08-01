// Regression coverage for confirmed odometer-to-allocation translation.
// Owns adapter boundaries only; durable persistence and Expense consumption
// are intentionally outside this GPS and odometer foundation test.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/odometer_correction_review.dart';
import 'package:maintaniac/shared/odometer/odometer_mileage_review.dart';
import 'package:maintaniac/shared/odometer/odometer_validation.dart';
import 'package:maintaniac/shared/trip_tracking/vehicle_mileage_allocation.dart';
import 'package:maintaniac/shared/trip_tracking/vehicle_mileage_allocation_odometer_adapter.dart';

void main() {
  OdometerReadingEvent event({
    OdometerMileageReview? review,
    bool affectsCurrentReading = true,
    OdometerCorrectionReview? correctionReview,
  }) => OdometerReadingEvent(
    id: 'odometer-event-1',
    reading: 1100,
    previousReading: 1000,
    recordedAt: DateTime.utc(2026, 8, 1, 12),
    mileageReview: review,
    affectsCurrentReading: affectsCurrentReading,
    correctionReview: correctionReview,
  );

  test('confirmed business odometer mileage becomes business allocation', () {
    final allocation = vehicleMileageAllocationFromOdometerEvent(
      event(
        review: const OdometerMileageReview(use: OdometerMileageUse.business),
      ),
      vehicleId: 'truck-1',
    );

    expect(allocation?.distanceTenths, 1000);
    expect(allocation?.businessTenths, 1000);
    expect(allocation?.use, VehicleMileageAllocationUse.business);
  });

  test('confirmed split odometer mileage preserves the selected split', () {
    final allocation = vehicleMileageAllocationFromOdometerEvent(
      event(
        review: const OdometerMileageReview(
          use: OdometerMileageUse.split,
          businessMiles: 30,
        ),
      ),
      vehicleId: 'truck-1',
    );

    expect(allocation?.businessTenths, 300);
    expect(allocation?.personalTenths, 700);
    expect(allocation?.use, VehicleMileageAllocationUse.split);
  });

  test('unresolved mileage remains unclassified', () {
    final allocation = vehicleMileageAllocationFromOdometerEvent(
      event(
        review: const OdometerMileageReview(use: OdometerMileageUse.unresolved),
      ),
      vehicleId: 'truck-1',
    );

    expect(allocation?.unclassifiedTenths, 1000);
    expect(allocation?.businessTenths, 0);
  });

  test(
    'corrections and unconfirmed intervals never become allocation evidence',
    () {
      expect(
        vehicleMileageAllocationFromOdometerEvent(
          event(
            review: const OdometerMileageReview(
              use: OdometerMileageUse.business,
            ),
            correctionReview: const OdometerCorrectionReview(
              reason: OdometerCorrectionReason.previousEntryWrong,
            ),
          ),
          vehicleId: 'truck-1',
        ),
        isNull,
      );
      expect(
        vehicleMileageAllocationFromOdometerEvent(
          event(affectsCurrentReading: false),
          vehicleId: 'truck-1',
        ),
        isNull,
      );
    },
  );
}
