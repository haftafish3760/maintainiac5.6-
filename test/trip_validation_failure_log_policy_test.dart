import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_validation_failure_log_policy.dart';

void main() {
  test(
    'native GPS validation failure keeps trip local and drops bad sample',
    () {
      final event = TripValidationFailureLogPolicy.classify(
        boundary: TripValidationFailureBoundary.nativeGps,
        reasonCode: 'invalid_coordinate',
        operation: 'gps_sample_ingest',
        ownerVerified: true,
        schemaVerified: false,
        authorizationVerified: true,
      );
      final log = event.toSafeLogMap();

      expect(event.severity, TripValidationFailureSeverity.recoverable);
      expect(event.recoveryAction, 'continue_local_trip_without_bad_sample');
      expect(log['hiveRemainsOperationalSourceOfTruth'], isTrue);
      expect(log['validationFailureCanConfirmMileage'], isFalse);
    },
  );

  test(
    'sensitive Firestore writes fail closed without trusting auth alone',
    () {
      final event = TripValidationFailureLogPolicy.classify(
        boundary: TripValidationFailureBoundary.firestoreMirror,
        reasonCode: 'owner_mismatch',
        operation: 'trip_review_mirror_write',
        ownerVerified: false,
        schemaVerified: true,
        authorizationVerified: false,
        sensitiveWrite: true,
      );
      final log = event.toSafeLogMap();

      expect(
        event.severity,
        TripValidationFailureSeverity.sensitiveWriteBlocked,
      );
      expect(event.recoveryAction, 'block_sensitive_write');
      expect(log['authenticationDoesNotImplyAuthorization'], isTrue);
      expect(log['failClosedForSensitiveWrites'], isTrue);
      expect(log['firestoreMirrorOnly'], isTrue);
    },
  );

  test('Mapbox validation failures disable optional maps but not TripLog', () {
    final event = TripValidationFailureLogPolicy.classify(
      boundary: TripValidationFailureBoundary.mapbox,
      reasonCode: 'malformed_geometry',
      operation: 'route_preview',
      ownerVerified: true,
      schemaVerified: false,
      authorizationVerified: true,
      optionalMappingFeature: true,
    );
    final log = event.toSafeLogMap();

    expect(event.severity, TripValidationFailureSeverity.warning);
    expect(event.recoveryAction, 'disable_optional_map_feature');
    expect(log['failGracefullyForOptionalMaps'], isTrue);
    expect(log['mapboxResponsesAreExternalInput'], isTrue);
    expect(log['odometerRemainsOfficialMileageTruth'], isTrue);
  });

  test('mirror failures keep local truth and retry without remote totals', () {
    final event = TripValidationFailureLogPolicy.classify(
      boundary: TripValidationFailureBoundary.cloudFunction,
      reasonCode: 'response_shape_invalid',
      operation: 'sync_trip_summary',
      ownerVerified: true,
      schemaVerified: false,
      authorizationVerified: true,
    );
    final log = event.toSafeLogMap();

    expect(event.recoveryAction, 'keep_local_truth_and_retry_mirror');
    expect(log['remoteTotalsCanonical'], isFalse);
    expect(log['hiveRemainsOperationalSourceOfTruth'], isTrue);
    expect(log['firestoreMirrorOnly'], isTrue);
  });

  test(
    'safe log sanitizes tokens coordinates and private operation strings',
    () {
      final event = TripValidationFailureLogPolicy.classify(
        boundary: TripValidationFailureBoundary.mapbox,
        reasonCode: 'token=pk.secret_lat_35.227111',
        operation: 'route_preview_-80.843124_sk.secret',
        ownerVerified: false,
        schemaVerified: false,
        authorizationVerified: false,
        optionalMappingFeature: true,
      );
      final log = event.toSafeLogMap();
      final serialized = log.toString();

      expect(log['reasonCode'], 'validation_failed');
      expect(log['operation'], 'trip_tracking_operation');
      expect(log['rawPayloadIncluded'], isFalse);
      expect(log['rawLocationIncluded'], isFalse);
      expect(log['privateUserContentIncluded'], isFalse);
      expect(log['tokensIncluded'], isFalse);
      expect(serialized, isNot(contains('pk.secret')));
      expect(serialized, isNot(contains('sk.secret')));
      expect(serialized, isNot(contains('35.227111')));
      expect(serialized, isNot(contains('-80.843124')));
    },
  );
}
