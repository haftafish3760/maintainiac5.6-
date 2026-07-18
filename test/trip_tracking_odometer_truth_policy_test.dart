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

  test(
    'safe summary claims lock GPS, Mapbox, cloud, and cache as advisory',
    () {
      final summary = <String, Object?>{
        ...TripTrackingOdometerTruthPolicy.safeSummaryClaims,
        'officialMileageSource': 'physicalOdometer',
      };
      final validation = TripTrackingOdometerTruthPolicy.validateSummary(
        summary,
      );

      expect(validation.isValid, isTrue);
      expect(summary['odometerIsGlobalTruth'], isTrue);
      expect(summary['physicalOdometerIsCanonical'], isTrue);
      expect(summary['physicalOdometerRequiredForOfficialMileage'], isTrue);
      expect(summary['confirmedOdometerOverridesExternalMileage'], isTrue);
      expect(summary['externalMileageCannotBecomeGlobalTruth'], isTrue);
      expect(summary['gpsDistanceCanOnlyAdviseMileageReview'], isTrue);
      expect(summary['mapMatchingCanOnlyAdviseMileageReview'], isTrue);
      expect(summary['optimizationCannotChangeOfficialMileage'], isTrue);
      expect(summary['gpsCanOverrideOdometer'], isFalse);
      expect(summary['mapboxCanOverrideOdometer'], isFalse);
      expect(summary['firebaseMirrorCanOverrideOdometer'], isFalse);
      expect(summary['cloudFunctionCanOverrideOdometer'], isFalse);
      expect(summary['importedFileCanOverrideOdometer'], isFalse);
      expect(summary['localCacheCanOverrideOdometer'], isFalse);
      expect(summary['sensorFusionCanOverrideOdometer'], isFalse);
      expect(summary['calibrationCanRewriteConfirmedOdometer'], isFalse);
      expect(summary['calibrationAppliesToFutureGpsProjectionOnly'], isTrue);
    },
  );

  test('summary validation rejects remote truth and sensitive leakage', () {
    final unsafe = <String, Object?>{
      ...TripTrackingOdometerTruthPolicy.safeSummaryClaims,
      'officialMileageSource': 'mapbox',
      'physicalOdometerRequiredForOfficialMileage': false,
      'confirmedOdometerOverridesExternalMileage': false,
      'externalMileageCannotBecomeGlobalTruth': false,
      'gpsDistanceCanOnlyAdviseMileageReview': false,
      'mapMatchingCanOnlyAdviseMileageReview': false,
      'optimizationCannotChangeOfficialMileage': false,
      'gpsCanOverrideOdometer': true,
      'debugToken': 'sk.do-not-log',
    };
    final validation = TripTrackingOdometerTruthPolicy.validateSummary(unsafe);

    expect(validation.isValid, isFalse);
    expect(
      validation.reasons,
      contains('missing_or_invalid_gpsCanOverrideOdometer'),
    );
    expect(
      validation.reasons,
      contains('missing_or_invalid_physicalOdometerRequiredForOfficialMileage'),
    );
    expect(validation.reasons, contains('invalid_official_mileage_source'));
    expect(
      validation.reasons,
      contains('odometer_truth_summary_contains_sensitive_text'),
    );
  });

  test('external distance cannot become official mileage without odometer', () {
    final gpsOnly = TripTrackingOdometerTruthPolicy.decideOfficialMileage(
      truthSource: null,
      confirmedOdometerMiles: null,
      assistSource: TripTrackingMileageAssistSource.gps,
      externalEstimatedMiles: 123.456,
    );

    expect(gpsOnly.accepted, isFalse);
    expect(gpsOnly.officialMileageMiles, isNull);
    expect(gpsOnly.reasonCode, 'external_mileage_requires_odometer_review');
    expect(gpsOnly.externalMileageWasAdvisoryOnly, isTrue);
    expect(gpsOnly.reviewRequired, isTrue);

    final summary = gpsOnly.toSafeSummary();
    expect(summary['odometerIsGlobalTruth'], isTrue);
    expect(summary['officialMileageMiles'], isNull);
    expect(summary['externalMileageCannotBecomeGlobalTruth'], isTrue);
    expect(summary['gpsCanOverrideOdometer'], isFalse);
    expect(summary['mapboxCanOverrideOdometer'], isFalse);
    expect(summary['routeGeometryIncluded'], isFalse);
  });

  test('confirmed odometer overrides GPS, Mapbox, and mirror estimates', () {
    for (final source in [
      TripTrackingMileageAssistSource.gps,
      TripTrackingMileageAssistSource.mapbox,
      TripTrackingMileageAssistSource.firebaseMirror,
      TripTrackingMileageAssistSource.cloudFunction,
      TripTrackingMileageAssistSource.importedFile,
      TripTrackingMileageAssistSource.localCache,
      TripTrackingMileageAssistSource.sensorFusion,
    ]) {
      final decision = TripTrackingOdometerTruthPolicy.decideOfficialMileage(
        truthSource: TripTrackingOdometerTruthSource.physicalOdometer,
        confirmedOdometerMiles: 88.125,
        assistSource: source,
        externalEstimatedMiles: 101.9,
      );

      expect(decision.accepted, isTrue, reason: source.name);
      expect(decision.officialMileageMiles, 88.125, reason: source.name);
      expect(
        decision.reasonCode,
        'confirmed_odometer_external_advisory_only',
        reason: source.name,
      );
      expect(decision.externalMileageWasAdvisoryOnly, isTrue);
      expect(decision.reviewRequired, isFalse);

      final summary = decision.toSafeSummary();
      expect(summary['officialMileageMiles'], 88.13, reason: source.name);
      expect(summary['officialMileageSource'], 'physicalOdometer');
      expect(
        TripTrackingOdometerTruthPolicy.validateSummary(summary).isValid,
        isTrue,
        reason: source.name,
      );
    }
  });

  test('invalid odometer value fails closed even with remote estimates', () {
    final decision = TripTrackingOdometerTruthPolicy.decideOfficialMileage(
      truthSource: TripTrackingOdometerTruthSource.userConfirmedReview,
      confirmedOdometerMiles: -4,
      assistSource: TripTrackingMileageAssistSource.mapbox,
      externalEstimatedMiles: 44,
    );

    expect(decision.accepted, isFalse);
    expect(decision.officialMileageMiles, isNull);
    expect(decision.reasonCode, 'external_mileage_requires_odometer_review');
    expect(decision.externalMileageWasAdvisoryOnly, isTrue);
    expect(decision.reviewRequired, isTrue);
  });
}
