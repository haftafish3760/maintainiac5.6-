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
    'confirmedBackupCanOnlySuggestCleanup': true,
    'durableRecordRequiresConfirmedOdometer': true,
    'durableRecordRequiresValidTimeline': true,
    'durableRecordRequiresSafeIds': true,
    'backendAuthorizationRequiredForMirror': true,
    'authenticationDoesNotImplyAuthorization': true,
    'remotePayloadTrustedAfterValidationOnly': true,
    'mapboxDataAdvisoryOnly': true,
    'rawGpsIncluded': false,
    'rawMapboxGeometryIncluded': false,
    'tokensIncluded': false,
  };
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
  map['durableRecordRequiresConfirmedOdometer'] = true;
  map['confirmedOdometerRemainsCanonical'] = true;
  map['mapboxCanReplaceOdometer'] = false;
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
