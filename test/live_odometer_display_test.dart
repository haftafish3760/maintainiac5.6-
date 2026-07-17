import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/live_odometer_display.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

void main() {
  test('confirmed odometer display is padded and not marked live', () {
    const snapshot = LiveOdometerDisplaySnapshot(
      confirmedReading: 1000,
      displayReading: 1000,
      isLive: false,
    );

    expect(snapshot.label, 'Odometer');
    expect(snapshot.displayValue, '0001000');
    expect(snapshot.deltaMiles, isZero);
    expect(snapshot.deltaLabel, isNull);
    expect(snapshot.statusLabelAt(DateTime.utc(2026)), isNull);
    expect(snapshot.toSafeDashboardMap(DateTime.utc(2026)), {
      'schemaVersion': 1,
      'label': 'Odometer',
      'displayValue': '0001000',
      'confirmedDisplayValue': '0001000',
      'isLive': false,
      'deltaMiles': 0,
      'statusLabel': null,
      'advisoryLabel': null,
      'freshness': 'inactive',
      'ageSeconds': null,
      'reviewRequired': false,
      'manualEntryBlocked': false,
      'truthLabel': 'Confirmed odometer',
      'confirmedReadingIsCanonical': true,
      'rawGpsIncluded': false,
      'routeGeometryIncluded': false,
      'mapboxMayOverrideOdometer': false,
    });
    expect(snapshot.semanticsLabelAt(DateTime.utc(2026)), 'Odometer 0001000');
  });

  test('live odometer display exposes only advisory delta text', () {
    final updatedAt = DateTime.utc(2026, 7, 17, 12);
    final snapshot = LiveOdometerDisplaySnapshot(
      confirmedReading: 1000,
      displayReading: 1003,
      isLive: true,
      liveUpdatedAt: updatedAt,
    );

    expect(snapshot.label, 'Live GPS odometer');
    expect(snapshot.displayValue, '0001003');
    expect(snapshot.deltaMiles, 3);
    expect(snapshot.deltaLabel, '+3 mi live');
    expect(snapshot.confirmedDisplayValue, '0001000');
    expect(snapshot.manualEntryBlocked, isTrue);
    expect(
      snapshot.advisoryLabel,
      'GPS-assisted estimate is 3 mi ahead of confirmed odometer.',
    );
    expect(
      snapshot.isStaleAt(updatedAt.add(const Duration(minutes: 1))),
      false,
    );
    expect(
      snapshot.ageSecondsAt(updatedAt.add(const Duration(minutes: 1))),
      60,
    );
    expect(
      snapshot.freshnessAt(updatedAt.add(const Duration(minutes: 1))),
      'fresh',
    );
    expect(
      snapshot.statusLabelAt(updatedAt.add(const Duration(minutes: 1))),
      '+3 mi live',
    );
    expect(
      snapshot.semanticsLabelAt(updatedAt.add(const Duration(minutes: 1))),
      'Live GPS odometer, 0001003, +3 mi live, confirmed 0001000',
    );
  });

  test('live odometer display shows paused state when updates go stale', () {
    final updatedAt = DateTime.utc(2026, 7, 17, 12);
    final now = updatedAt.add(const Duration(minutes: 6));
    final snapshot = LiveOdometerDisplaySnapshot(
      confirmedReading: 1000,
      displayReading: 1004,
      isLive: true,
      liveUpdatedAt: updatedAt,
    );

    expect(snapshot.isStaleAt(now), isTrue);
    expect(snapshot.ageSecondsAt(now), 360);
    expect(snapshot.freshnessAt(now), 'stale');
    expect(snapshot.statusLabelAt(now), 'Live GPS paused');
    expect(snapshot.toSafeDashboardMap(now), {
      'schemaVersion': 1,
      'label': 'Live GPS odometer',
      'displayValue': '0001004',
      'confirmedDisplayValue': '0001000',
      'isLive': true,
      'deltaMiles': 4,
      'statusLabel': 'Live GPS paused',
      'advisoryLabel':
          'GPS-assisted estimate is 4 mi ahead of confirmed odometer.',
      'freshness': 'stale',
      'ageSeconds': 360,
      'reviewRequired': true,
      'manualEntryBlocked': true,
      'truthLabel':
          'Confirmed odometer remains the mileage truth until trip review.',
      'confirmedReadingIsCanonical': true,
      'rawGpsIncluded': false,
      'routeGeometryIncluded': false,
      'mapboxMayOverrideOdometer': false,
    });
  });

  test('live odometer display never reports negative advisory mileage', () {
    const snapshot = LiveOdometerDisplaySnapshot(
      confirmedReading: 1000,
      displayReading: 999,
      isLive: true,
    );

    expect(snapshot.deltaMiles, isZero);
    expect(snapshot.deltaLabel, 'GPS live');
    expect(snapshot.confirmedReadingIsCanonical, isTrue);
    expect(snapshot.rawGpsIncluded, isFalse);
    expect(snapshot.routeGeometryIncluded, isFalse);
    expect(snapshot.mapboxMayOverrideOdometer, isFalse);
    expect(
      snapshot.advisoryLabel,
      'GPS-assisted odometer is live; confirmed mileage has not changed.',
    );
    expect(snapshot.displayValue, '0000999');
  });

  test('live odometer dashboard map bounds clock skew and long gaps', () {
    final updatedAt = DateTime.utc(2026, 7, 17, 12);
    final snapshot = LiveOdometerDisplaySnapshot(
      confirmedReading: 1000,
      displayReading: 1001,
      isLive: true,
      liveUpdatedAt: updatedAt,
    );

    expect(
      snapshot.ageSecondsAt(updatedAt.subtract(const Duration(minutes: 1))),
      0,
    );
    expect(
      snapshot.ageSecondsAt(updatedAt.add(const Duration(days: 3))),
      86400,
    );
  });

  test('global odometer publishes a reusable live display snapshot', () {
    final controller = GlobalOdometerController(initialReading: 1000);

    expect(controller.liveDisplaySnapshot.displayValue, '0001000');
    expect(controller.liveDisplaySnapshot.label, 'Odometer');
    expect(
      controller.beginLiveTripProjection(
        tripId: 'trip_live_display',
        startingOdometer: 1000,
      ),
      isTrue,
    );
    expect(
      controller.updateLiveTripProjection(
        tripId: 'trip_live_display',
        estimatedOdometer: 1002,
      ),
      isTrue,
    );

    final live = controller.liveDisplaySnapshot;

    expect(live.label, 'Live GPS odometer');
    expect(live.displayValue, '0001002');
    expect(live.deltaMiles, 2);
    expect(live.deltaLabel, '+2 mi live');
    expect(live.liveUpdatedAt, isNotNull);
    expect(controller.confirmedReading, 1000);
  });
}
