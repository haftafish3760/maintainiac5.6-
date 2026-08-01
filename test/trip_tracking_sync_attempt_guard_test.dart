import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/firebase/hosted_usage_limits.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_sync_attempt_guard.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_sync_policy.dart';

void main() {
  test('free users may mirror validated local trip records within quota', () {
    final decision = TripTrackingSyncAttemptGuard.evaluate(
      request(syncsUsedInWindow: 2),
    );

    expect(decision.mayUploadMirror, isTrue);
    expect(decision.mustReserveFreeAttemptBeforeUpload, isTrue);
    expect(decision.consumesFreeAttempt, isTrue);
    expect(
      decision.freeSyncsRemainingBeforeAttempt,
      HostedUsageLimits.freeUserSyncsPer24HourWindow - 2,
    );
    expect(decision.mirrorPayload['canonicalSource'], 'hive');
    expect(decision.mirrorPayload['firestoreRole'], 'mirror');
    expect(decision.mirrorPayload['deviceIdMatchesLocalRecord'], isTrue);
    expect(decision.mirrorPayload['tripDayKeyValidated'], isTrue);
    expect(decision.mirrorPayload['localRevisionMonotonic'], isTrue);
    expect(decision.mirrorPayload['ownerValidatedBeforeMirror'], isTrue);
    expect(decision.mirrorPayload['canOverrideLocalDaytimeData'], isFalse);
    expect(decision.mirrorPayload['canDeleteLocalData'], isFalse);
    expect(decision.mirrorPayload['odometerIsGlobalTruth'], isTrue);
    expect(
      decision.mirrorPayload['calibrationCanUploadAsOfficialMileage'],
      isFalse,
    );
    expect(
      decision
          .mirrorPayload['poorGpsCalibrationDaysCanUploadAsCalibrationProof'],
      isFalse,
    );
    expect(decision.mirrorPayload['mapboxDataIncluded'], isFalse);
    expect(decision.mirrorPayload['rawRouteHistoryIncluded'], isFalse);
    expect(decision.toSafeSummary()['revisionFresh'], isTrue);
    expect(decision.toSafeSummary()['firestoreMirrorOnly'], isTrue);
    expect(
      decision.toSafeSummary()['remoteBackupCanPurgeLocalRecordsSilently'],
      isFalse,
    );
    expect(decision.toSafeSummary()['tokensIncluded'], isFalse);
    expect(decision.toSafeSummary()['preciseLocationIncluded'], isFalse);
    expect(decision.toSafeSummary()['rawTripRecordsIncluded'], isFalse);
  });

  test('free users are blocked after the configured sync limit', () {
    final decision = TripTrackingSyncAttemptGuard.evaluate(
      request(
        syncsUsedInWindow: TripTrackingBackupSyncPolicy.freeSyncsPerWindow,
      ),
    );

    expect(decision.status, TripTrackingSyncAttemptStatus.blockedQuota);
    expect(decision.mayUploadMirror, isFalse);
    expect(decision.mustReserveFreeAttemptBeforeUpload, isFalse);
    expect(decision.consumesFreeAttempt, isFalse);
    expect(decision.freeSyncsRemainingBeforeAttempt, 0);
    expect(decision.mirrorPayload, isEmpty);
    expect(decision.userFacingReason, contains('24-hour window'));
  });

  test('network policy blocks without consuming a free sync attempt', () {
    final decision = TripTrackingSyncAttemptGuard.evaluate(
      request(
        networkPolicy: TripTrackingBackupNetworkPolicy.wifiOnly,
        wifiAvailable: false,
        mobileDataAvailable: true,
        syncsUsedInWindow: 0,
      ),
    );

    expect(decision.status, TripTrackingSyncAttemptStatus.blockedNetwork);
    expect(decision.mayUploadMirror, isFalse);
    expect(decision.mustReserveFreeAttemptBeforeUpload, isFalse);
    expect(decision.consumesFreeAttempt, isFalse);
    expect(
      decision.freeSyncsRemainingBeforeAttempt,
      HostedUsageLimits.freeUserSyncsPer24HourWindow,
    );
    expect(decision.toSafeSummary()['syncAttemptCanDeleteLocalData'], isFalse);
  });

  test('unknown or malformed free usage fails closed before upload', () {
    for (final used in const <int?>[null, -1, 1000]) {
      final decision = TripTrackingSyncAttemptGuard.evaluate(
        request(syncsUsedInWindow: used),
      );

      expect(
        decision.status,
        TripTrackingSyncAttemptStatus.blockedUnverifiedUsage,
        reason: 'used=$used',
      );
      expect(decision.mayUploadMirror, isFalse);
      expect(decision.consumesFreeAttempt, isFalse);
      expect(decision.mirrorPayload, isEmpty);
      expect(
        decision.toSafeSummary()['remoteBackupCanOverrideLocalDay'],
        isFalse,
      );
    }
  });

  test(
    'paid users bypass free quota but still obey source and network gates',
    () {
      final decision = TripTrackingSyncAttemptGuard.evaluate(
        request(
          accountTier: TripTrackingSyncAccountTier.paid,
          syncsUsedInWindow: 900,
        ),
      );

      expect(decision.status, TripTrackingSyncAttemptStatus.ready);
      expect(decision.mayUploadMirror, isTrue);
      expect(decision.mustReserveFreeAttemptBeforeUpload, isFalse);
      expect(decision.consumesFreeAttempt, isFalse);
      expect(decision.freeSyncsRemainingBeforeAttempt, isNull);
      expect(decision.mirrorPayload['canonicalSource'], 'hive');
      expect(
        decision.toSafeSummary()['odometerRemainsOfficialMileageTruth'],
        isTrue,
      );
    },
  );

  test('authentication never implies authorization for trip mirrors', () {
    final decision = TripTrackingSyncAttemptGuard.evaluate(
      request(authenticatedUid: 'otherUser', syncsUsedInWindow: 0),
    );

    expect(decision.status, TripTrackingSyncAttemptStatus.blockedInvalidOwner);
    expect(decision.ownerValid, isFalse);
    expect(decision.mayUploadMirror, isFalse);
    expect(decision.mirrorPayload, isEmpty);
    expect(
      decision.toSafeSummary()['authorizationCheckedAfterAuthentication'],
      isTrue,
    );
    expect(
      decision.toSafeSummary()['firebaseAuthDoesNotGrantMirrorAuthority'],
      isTrue,
    );
  });

  test('stale local revisions cannot replay over newer local trip state', () {
    final stale = TripTrackingSyncAttemptGuard.evaluate(
      request(
        source: validSource(localRevision: 3),
        syncsUsedInWindow: 0,
        lastMirroredLocalRevision: 3,
      ),
    );
    final fresh = TripTrackingSyncAttemptGuard.evaluate(
      request(
        source: validSource(localRevision: 4),
        syncsUsedInWindow: 0,
        lastMirroredLocalRevision: 3,
      ),
    );

    expect(stale.status, TripTrackingSyncAttemptStatus.blockedStaleRevision);
    expect(stale.mayUploadMirror, isFalse);
    expect(stale.mirrorPayload, isEmpty);
    expect(stale.userFacingReason, contains('newer local revision'));
    expect(
      stale.toSafeSummary()['staleMirrorRevisionCanOverrideLocalDay'],
      isFalse,
    );
    expect(fresh.status, TripTrackingSyncAttemptStatus.ready);
  });

  test(
    'invalid local source records never become Firestore mirror payloads',
    () {
      final invalidSources = [
        validSource(recordId: 'bad:id'),
        validSource(ownerUid: 'sk.secret'),
        validSource(deviceId: 'device token'),
        validSource(schemaVersion: 0),
        validSource(localRevision: 0),
        validSource(localPersisted: false),
        validSource(tripDayKey: '2026-99-99'),
        validSource(distanceMiles: -0.1),
        validSource(distanceMiles: 2500.1),
        validSource(updatedAtUtc: DateTime.utc(2019, 12, 31, 23, 59)),
        validSource(updatedAtUtc: DateTime.utc(2200)),
      ];

      for (final source in invalidSources) {
        final decision = TripTrackingSyncAttemptGuard.evaluate(
          request(source: source, syncsUsedInWindow: 0),
        );

        expect(
          decision.status,
          TripTrackingSyncAttemptStatus.blockedInvalidSource,
          reason: source.toSafeSyncMirrorPayload().toString(),
        );
        expect(decision.sourceValid, isFalse);
        expect(decision.mayUploadMirror, isFalse);
        expect(decision.mirrorPayload, isEmpty);
      }
    },
  );

  test('future and stale local mirrors are blocked before upload', () {
    final receivedAt = DateTime.utc(2026, 7, 18, 12);
    final future = TripTrackingSyncAttemptGuard.evaluate(
      request(
        source: validSource(
          recordId: 'future-trip',
          updatedAtUtc: receivedAt.add(const Duration(minutes: 3)),
        ),
        receivedAtUtc: receivedAt,
      ),
    );
    final stale = TripTrackingSyncAttemptGuard.evaluate(
      request(
        source: validSource(
          recordId: 'stale-trip',
          updatedAtUtc: receivedAt.subtract(const Duration(days: 40)),
        ),
        receivedAtUtc: receivedAt,
      ),
    );
    final recent = TripTrackingSyncAttemptGuard.evaluate(
      request(
        source: validSource(
          recordId: 'recent-trip',
          updatedAtUtc: receivedAt.subtract(const Duration(days: 3)),
        ),
        receivedAtUtc: receivedAt,
      ),
    );

    expect(future.status, TripTrackingSyncAttemptStatus.blockedInvalidSource);
    expect(stale.status, TripTrackingSyncAttemptStatus.blockedInvalidSource);
    expect(recent.status, TripTrackingSyncAttemptStatus.ready);
    expect(future.mayUploadMirror, isFalse);
    expect(stale.mirrorPayload, isEmpty);
    expect(recent.mirrorPayload['canonicalSource'], 'hive');
  });

  test('storage protection blocks backup without deleting local trip data', () {
    final decision = TripTrackingSyncAttemptGuard.evaluate(
      request(storageAvailableForSmallRecordWrite: false, syncsUsedInWindow: 0),
    );

    expect(decision.status, TripTrackingSyncAttemptStatus.blockedStorage);
    expect(decision.mayUploadMirror, isFalse);
    expect(decision.consumesFreeAttempt, isFalse);
    expect(decision.mirrorPayload, isEmpty);
    expect(decision.userFacingReason, contains('safe local storage'));
    expect(
      decision.toSafeSummary()['remoteBackupCanPurgeLocalRecordsSilently'],
      isFalse,
    );
  });

  test('safe summary keeps Mapbox and odometer trust boundaries explicit', () {
    final decision = TripTrackingSyncAttemptGuard.evaluate(
      request(syncsUsedInWindow: 1),
    );
    final summary = decision.toSafeSummary();

    expect(summary['hiveRemainsOperationalSourceOfTruth'], isTrue);
    expect(summary['firestoreMirrorOnly'], isTrue);
    expect(summary['remoteBackupCanOverrideLocalDay'], isFalse);
    expect(summary['odometerIsGlobalTruth'], isTrue);
    expect(summary['odometerRemainsOfficialMileageTruth'], isTrue);
    expect(summary['calibrationRequiresTrustedGpsWindow'], isTrue);
    expect(summary['poorGpsDaysExcludedFromCalibration'], isTrue);
    expect(summary['syncAttemptCanCreateCalibration'], isFalse);
    expect(summary['syncAttemptCanApplyCalibration'], isFalse);
    expect(summary['syncAttemptCanCreateOfficialMileage'], isFalse);
    expect(summary['mapboxCanReplaceOdometer'], isFalse);
    expect(summary['validatedBeforeUpload'], isTrue);
    expect(summary['deviceIdMatchesLocalRecord'], isTrue);
    expect(summary['tripDayKeyValidated'], isTrue);
    expect(summary['mirrorPayloadHasMonotonicLocalRevision'], isTrue);
    expect(summary['authenticatedUidMustOwnSourceRecord'], isTrue);
    expect(summary['firebaseAuthDoesNotGrantMirrorAuthority'], isTrue);
    expect(summary['authenticationAloneAuthorizesMirrorUpload'], isFalse);
    expect(summary['mirrorPayloadRequiresLocalPersistence'], isTrue);
    expect(summary['mirrorPayloadExcludesRawRouteHistory'], isTrue);
    expect(summary['blockedAttemptConsumesFreeSync'], isFalse);
    expect(summary['remoteQuotaCountersCanOverrideLocalLedger'], isFalse);
    expect(summary['cloudFunctionCanGrantExtraFreeSyncs'], isFalse);
    expect(summary['firestoreCounterCanConsumeFreeSync'], isFalse);
    expect(summary['quotaReservationMustPrecedeNetworkUpload'], isTrue);
    expect(summary['quotaScopeMustIncludeAccountDeviceAndModule'], isTrue);
    expect(summary['tokensIncluded'], isFalse);
    expect(summary['preciseLocationIncluded'], isFalse);
    expect(summary['rawTripRecordsIncluded'], isFalse);
    expect(summary.toString(), isNot(contains('pk.')));
    expect(summary.toString(), isNot(contains('sk.')));
  });

  test('mirror payload explicitly prevents auth-only upload authority', () {
    final decision = TripTrackingSyncAttemptGuard.evaluate(
      request(syncsUsedInWindow: 1),
    );
    final summary = decision.toSafeSummary();

    expect(decision.mayUploadMirror, isTrue);
    expect(summary['authorizationCheckedAfterAuthentication'], isTrue);
    expect(summary['authenticatedUidMustOwnSourceRecord'], isTrue);
    expect(summary['firebaseAuthDoesNotGrantMirrorAuthority'], isTrue);
    expect(summary['authenticationAloneAuthorizesMirrorUpload'], isFalse);
    expect(decision.mirrorPayload['ownerValidatedBeforeMirror'], isTrue);
    expect(decision.mirrorPayload['deviceIdMatchesLocalRecord'], isTrue);
  });

  test('safe sync attempt summary validates trust boundaries', () {
    final validation = TripTrackingSyncAttemptSummaryValidation.fromSummary(
      TripTrackingSyncAttemptGuard.evaluate(
        request(syncsUsedInWindow: 1),
      ).toSafeSummary(),
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.reasons, isEmpty);
  });

  test('sync attempt summary rejects forged upload and truth claims', () {
    final blocked = TripTrackingSyncAttemptGuard.evaluate(
      request(syncsUsedInWindow: 6),
    ).toSafeSummary();
    final validation = TripTrackingSyncAttemptSummaryValidation.fromSummary({
      ...blocked,
      'mayUploadMirror': true,
      'consumesFreeAttempt': true,
      'remoteBackupCanOverrideLocalDay': true,
      'remoteBackupCanPurgeLocalRecordsSilently': true,
      'syncAttemptCanDeleteLocalData': true,
      'blockedAttemptConsumesFreeSync': true,
      'odometerIsGlobalTruth': false,
      'syncAttemptCanCreateCalibration': true,
      'syncAttemptCanApplyCalibration': true,
      'syncAttemptCanCreateOfficialMileage': true,
      'mapboxCanReplaceOdometer': true,
      'tokensIncluded': true,
      'debug': 'runtime token near 35.123456',
    });

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      contains('sync_attempt_status_conflicts_with_authority'),
    );
    expect(
      validation.reasons,
      contains('sync_attempt_local_truth_boundary_missing'),
    );
    expect(validation.reasons, contains('sync_attempt_can_create_trip_truth'));
    expect(
      validation.reasons,
      contains('summary_contains_sensitive_sync_material'),
    );
  });
}

TripTrackingSyncAttemptRequest request({
  TripTrackingSyncAccountTier accountTier = TripTrackingSyncAccountTier.free,
  String authenticatedUid = 'userA',
  TripTrackingSyncSourceRecord? source,
  TripTrackingBackupNetworkPolicy networkPolicy =
      TripTrackingBackupNetworkPolicy.wifiAndMobileData,
  bool? wifiAvailable = true,
  bool? mobileDataAvailable = false,
  int? syncsUsedInWindow = 0,
  bool storageAvailableForSmallRecordWrite = true,
  DateTime? receivedAtUtc,
  int? lastMirroredLocalRevision,
}) {
  return TripTrackingSyncAttemptRequest(
    accountTier: accountTier,
    authenticatedUid: authenticatedUid,
    source: source ?? validSource(),
    networkPolicy: networkPolicy,
    wifiAvailable: wifiAvailable,
    mobileDataAvailable: mobileDataAvailable,
    syncsUsedInWindow: syncsUsedInWindow,
    storageAvailableForSmallRecordWrite: storageAvailableForSmallRecordWrite,
    receivedAtUtc: receivedAtUtc,
    lastMirroredLocalRevision: lastMirroredLocalRevision,
  );
}

TripTrackingSyncSourceRecord validSource({
  int schemaVersion = 1,
  String recordId = 'trip-20260717-001',
  String ownerUid = 'userA',
  String deviceId = 'deviceA',
  TripTrackingSyncSourceKind kind = TripTrackingSyncSourceKind.liveTrip,
  DateTime? updatedAtUtc,
  int localRevision = 1,
  bool localPersisted = true,
  String? tripDayKey = '2026-07-17',
  double? distanceMiles = 12.4,
}) {
  return TripTrackingSyncSourceRecord(
    schemaVersion: schemaVersion,
    recordId: recordId,
    ownerUid: ownerUid,
    deviceId: deviceId,
    kind: kind,
    updatedAtUtc: updatedAtUtc ?? DateTime.utc(2026, 7, 17, 18),
    localRevision: localRevision,
    localPersisted: localPersisted,
    tripDayKey: tripDayKey,
    distanceMiles: distanceMiles,
  );
}
