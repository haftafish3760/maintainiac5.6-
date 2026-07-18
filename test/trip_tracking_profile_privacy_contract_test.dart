import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_profile_strategy.dart';

void main() {
  test(
    'driver profile dashboard maps expose privacy defaults for every profile',
    () {
      for (final profile in TripTrackingProfile.values) {
        final summary = TripTrackingProfileStrategy.forProfile(
          profile,
        ).toDashboardProfileMap();

        expect(summary['mapsRequiredForTracking'], isFalse);
        expect(summary['odometerRemainsCanonical'], isTrue);
        expect(summary['locationSharingRequiresActiveOptIn'], isTrue);
        expect(summary['employeeTrackingRequiresMutualConsent'], isTrue);
        expect(summary['employerGodModeAllowed'], isFalse);
        expect(summary['rawLocationIncluded'], isFalse);
        expect(summary['rawSensorPayloadIncluded'], isFalse);
      }
    },
  );
}
