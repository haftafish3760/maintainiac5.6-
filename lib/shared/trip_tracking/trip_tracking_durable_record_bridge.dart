import '../records/maintainiac_durable_record_store.dart';
import 'trip_tracking_session_store.dart';

class TripTrackingDurableRecordBridge {
  const TripTrackingDurableRecordBridge(this.store);

  static const module = 'trip_tracking';

  final MaintainiacDurableRecordStore store;

  Future<MaintainiacDurableRecord> saveReviewedTrip(
    TripTrackingReviewRecord review, {
    int? expectedRevision,
    DateTime? now,
  }) {
    final safeReview = _validatedReview(review);
    final safeTripId = _safeDurableTripId(safeReview.id);
    if (safeTripId == null) {
      throw ArgumentError('A durable trip record requires a safe trip id.');
    }
    return store.save(
      module: module,
      id: safeTripId,
      payload: _payloadFor(safeReview),
      expectedRevision: expectedRevision,
      now: now,
    );
  }

  TripTrackingReviewRecord? reviewForTrip(String tripId) {
    final safeTripId = _safeDurableTripId(tripId);
    if (safeTripId == null) return null;
    final record = store.recordFor(module, safeTripId);
    if (record == null || record.lifecycle.isDeleted) return null;
    return _reviewFromPayload(record.payload);
  }

  List<TripTrackingReviewRecord> reviewedTrips({String? vehicleId}) {
    final safeVehicleId = _safeDurableVehicleId(vehicleId);
    return store
        .recordsFor(module)
        .map((record) {
          return _reviewFromPayload(record.payload);
        })
        .whereType<TripTrackingReviewRecord>()
        .where((review) {
          return safeVehicleId == null || review.vehicleId == safeVehicleId;
        })
        .toList(growable: false);
  }

  Map<String, Object?> toSafeSummary() => const {
    'schemaVersion': 1,
    'module': module,
    'usesSharedDurableRecordStore': true,
    'storesReviewedTripsOnly': true,
    'hiveRemainsSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'remoteDataCanOverrideLocalDaytimeData': false,
    'remoteDataCanPurgeLocalDaytimeData': false,
    'remoteDataCanSilentlyResolveConflicts': false,
    'confirmedBackupCanOnlySuggestCleanup': true,
    'durableRecordRequiresConfirmedOdometer': true,
    'durableRecordRequiresValidTimeline': true,
    'durableRecordRequiresSafeIds': true,
    'backendAuthorizationRequiredForMirror': true,
    'authenticationDoesNotImplyAuthorization': true,
    'remotePayloadTrustedAfterValidationOnly': true,
    'mapboxDataAdvisoryOnly': true,
    'mapboxCanCreateDurableRecord': false,
    'mapboxCanReplaceDurableMileage': false,
    'rawGpsIncluded': false,
    'rawMapboxGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripTrackingDurableRecordBridgeSummaryValidation {
  const TripTrackingDurableRecordBridgeSummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripTrackingDurableRecordBridgeSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (summary['module'] != TripTrackingDurableRecordBridge.module ||
        summary['usesSharedDurableRecordStore'] != true ||
        summary['storesReviewedTripsOnly'] != true) {
      reasons.add('invalid_durable_bridge_scope');
    }
    if (summary['hiveRemainsSourceOfTruth'] != true ||
        summary['firestoreMirrorOnly'] != true ||
        summary['remoteDataCanOverrideLocalDaytimeData'] != false ||
        summary['remoteDataCanPurgeLocalDaytimeData'] != false ||
        summary['remoteDataCanSilentlyResolveConflicts'] != false ||
        summary['confirmedBackupCanOnlySuggestCleanup'] != true) {
      reasons.add('local_day_truth_boundary_missing');
    }
    if (summary['durableRecordRequiresConfirmedOdometer'] != true ||
        summary['durableRecordRequiresValidTimeline'] != true ||
        summary['durableRecordRequiresSafeIds'] != true) {
      reasons.add('durable_record_requirements_missing');
    }
    if (summary['backendAuthorizationRequiredForMirror'] != true ||
        summary['authenticationDoesNotImplyAuthorization'] != true ||
        summary['remotePayloadTrustedAfterValidationOnly'] != true) {
      reasons.add('authorization_boundary_missing');
    }
    if (summary['mapboxDataAdvisoryOnly'] != true ||
        summary['mapboxCanCreateDurableRecord'] != false ||
        summary['mapboxCanReplaceDurableMileage'] != false) {
      reasons.add('mapbox_can_control_durable_record');
    }
    if (summary['rawGpsIncluded'] != false ||
        summary['rawMapboxGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false) {
      reasons.add('summary_contains_sensitive_trip_material');
    }
    if (summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_text');
    }

    return TripTrackingDurableRecordBridgeSummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
}

TripTrackingReviewRecord _validatedReview(TripTrackingReviewRecord review) {
  final restored = TripTrackingReviewRecord.fromMap(review.toMap());
  if (!restored.isOdometerConfirmed ||
      !restored.hasValidTimeline ||
      restored.id.trim().isEmpty ||
      restored.vehicleId.trim().isEmpty) {
    throw ArgumentError(
      'A durable trip record requires a reviewed trip, safe IDs, and confirmed odometer mileage.',
    );
  }
  return restored;
}

String? _safeDurableTripId(Object? value) {
  if (value is! String) return null;
  final clean = value.trim();
  if (clean.isEmpty || clean.length > 80) return null;
  return RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(clean) ? clean : null;
}

String? _safeDurableVehicleId(Object? value) {
  if (value == null) return null;
  if (value is! String) return '';
  final clean = value.trim();
  if (clean.isEmpty || clean.length > 120) return '';
  return RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(clean) ? clean : '';
}

Map<String, dynamic> _payloadFor(TripTrackingReviewRecord review) {
  final map = Map<String, dynamic>.from(review.toMap());
  final engineSnapshot = map['engineSnapshot'];
  if (engineSnapshot is Map) {
    final safeEngineSnapshot = Map<String, dynamic>.from(engineSnapshot);
    safeEngineSnapshot.remove('walkingEvidence');
    safeEngineSnapshot['walkingEvidencePersistedInDurableRecord'] = false;
    map['engineSnapshot'] = safeEngineSnapshot;
  }
  for (final forbidden in const [
    'lastAccepted',
    'walkingEvidence',
    'pendingSample',
    'rawGps',
    'rawMapboxGeometry',
    'mapboxRoute',
    'routeGeometry',
    'coordinates',
  ]) {
    map.remove(forbidden);
  }
  map['durableRecordSchema'] = 'trip_tracking_review_v1';
  map['hiveRemainsSourceOfTruth'] = true;
  map['firestoreMirrorOnly'] = true;
  map['remoteDataCanOverrideLocalDaytimeData'] = false;
  map['remoteDataCanPurgeLocalDaytimeData'] = false;
  map['remoteDataCanSilentlyResolveConflicts'] = false;
  map['durableRecordRequiresConfirmedOdometer'] = true;
  map['confirmedOdometerRemainsCanonical'] = true;
  map['mapboxCanReplaceOdometer'] = false;
  map['mapboxCanCreateDurableRecord'] = false;
  map['rawGpsIncluded'] = false;
  map['rawMapboxGeometryIncluded'] = false;
  return map;
}

TripTrackingReviewRecord? _reviewFromPayload(Map<String, dynamic> payload) {
  if (payload['durableRecordSchema'] != 'trip_tracking_review_v1') return null;
  final review = TripTrackingReviewRecord.fromMap(payload);
  if (!review.isOdometerConfirmed || !review.hasValidTimeline) return null;
  return review;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}
