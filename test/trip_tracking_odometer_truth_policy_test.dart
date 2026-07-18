import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_truth_policy.dart';

void main() {
  test('physical odometer and confirmed review are the only mileage truth', () {
    expect(
      TripTrackingOdometerTruthPolicy.canSourceSetOfficialMileage(
        TripTrackingOdometerTruthSource.physicalOdometer,
      ),
      isTrue,
    );
    expect(
      TripTrackingOdometerTruthPolicy.canSourceSetOfficialMileage(
        TripTrackingOdometerTruthSource.userConfirmedReview,
      ),
      isTrue,
    );

    for (final source in TripTrackingMileageAssistSource.values) {
      expect(
        TripTrackingOdometerTruthPolicy.canAssistSourceSetOfficialMileage(
          source,
        ),
        isFalse,
        reason: '${source.name} must remain advisory only.',
      );
      expect(
        TripTrackingOdometerTruthPolicy.canAssistSourceApplyCalibration(source),
        isFalse,
        reason: '${source.name} must not apply calibration by itself.',
      );
    }
  });

  test('safe summary claims lock GPS, Mapbox, cloud, and cache as advisory', () {
    final summary = <String, Object?>{
      ...TripTrackingOdometerTruthPolicy.safeSummaryClaims,
      'officialMileageSource': 'physicalOdometer',
    };
    final validation = TripTrackingOdometerTruthPolicy.validateSummary(summary);

    expect(validation.isValid, isTrue);
    expect(summary['odometerIsGlobalTruth'], isTrue);
    expect(summary['physicalOdometerIsCanonical'], isTrue);
    expect(summary['gpsCanOverrideOdometer'], isFalse);
    expect(summary['mapboxCanOverrideOdometer'], isFalse);
    expect(summary['firebaseMirrorCanOverrideOdometer'], isFalse);
    expect(summary['cloudFunctionCanOverrideOdometer'], isFalse);
    expect(summary['importedFileCanOverrideOdometer'], isFalse);
    expect(summary['localCacheCanOverrideOdometer'], isFalse);
    expect(summary['sensorFusionCanOverrideOdometer'], isFalse);
    expect(summary['calibrationCanRewriteConfirmedOdometer'], isFalse);
    expect(summary['calibrationAppliesToFutureGpsProjectionOnly'], isTrue);
  });

  test('summary validation rejects remote truth and sensitive leakage', () {
    final unsafe = <String, Object?>{
      ...TripTrackingOdometerTruthPolicy.safeSummaryClaims,
      'officialMileageSource': 'mapbox',
      'gpsCanOverrideOdometer': true,
      'debugToken': 'sk.do-not-log',
    };
    final validation = TripTrackingOdometerTruthPolicy.validateSummary(unsafe);

    expect(validation.isValid, isFalse);
    expect(
      validation.reasons,
      contains('missing_or_invalid_gpsCanOverrideOdometer'),
    );
    expect(validation.reasons, contains('invalid_official_mileage_source'));
    expect(
      validation.reasons,
      contains('odometer_truth_summary_contains_sensitive_text'),
    );
  });
}
