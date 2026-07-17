part of 'maintainiac_firestore_upload_queue.dart';

class MaintainiacFirestoreUploadPolicy {
  const MaintainiacFirestoreUploadPolicy._();

  static const maxBatchSize = 20;
  static const maxQueuedRecords = 500;
  static const maxDocumentBytes = 768 * 1024;
  static const retryInitialDelay = Duration(seconds: 30);
  static const retryMaximumDelay = Duration(hours: 6);
  static const _tripMetersPerMile = 1609.344;

  static Duration retryDelayForAttempt(int attemptCount) {
    final exponent = attemptCount.clamp(1, 16).toInt() - 1;
    final seconds = retryInitialDelay.inSeconds * (1 << exponent);
    return Duration(
      seconds: seconds > retryMaximumDelay.inSeconds
          ? retryMaximumDelay.inSeconds
          : seconds,
    );
  }

  static const allowedTopLevelCollections = <String>{
    'users',
    MaintainiacFirestoreSchema.orgs,
    MaintainiacFirestoreSchema.catalogPacks,
    MaintainiacFirestoreSchema.parserHealth,
    MaintainiacFirestoreSchema.catalogHealth,
    MaintainiacFirestoreSchema.sharedCorrectionCandidates,
  };

  static const blockedSensitiveKeys = <String>{
    'rawReceiptText',
    'receiptText',
    'ocrText',
    'merchantName',
    'storeName',
    'customerName',
    'jobName',
    'description',
    'correctedDescription',
    'catalogItemName',
    'itemName',
    'lineText',
    'address',
    'phone',
    'email',
    'vin',
    'plateNumber',
  };

  static const blockedEverywhereKeys = <String>{
    'rawReceiptText',
    'rawOcrText',
    'ocrText',
    'importedText',
    'localPath',
    'path',
    'vin',
    'VIN',
    'vehicleIdentificationNumber',
    'licensePlate',
    'plate',
    'plateNumber',
    'tagNumber',
    'passengerName',
    'passengerPhone',
    'passengerAddress',
    'patientName',
    'patientPhone',
    'patientAddress',
    'medicalRecordNumber',
    'diagnosis',
    'dateOfBirth',
    'dob',
  };

  static void validateDraft(MaintainiacFirestoreDocumentDraft draft) {
    _validatePath(draft.path);
    _validateDocumentSize(draft);
    _validateNoSensitiveKeys(
      draft.data,
      allowPrivateExpenseBackup: _isPrivateExpenseBackupPath(draft.path),
    );
    _validateTripMileageSummaryShape(draft);
    _validateDashboardSummaryShape(draft);
    _validateCatalogReadShape(draft);
  }

  static void _validatePath(String path) {
    final clean = path.trim();
    if (clean.isEmpty ||
        clean.startsWith('/') ||
        clean.endsWith('/') ||
        clean.contains('//') ||
        clean.contains('..')) {
      throw ArgumentError.value(path, 'path', 'Unsafe Firestore path.');
    }
    final parts = clean.split('/');
    if (parts.length.isOdd) {
      throw ArgumentError.value(path, 'path', 'Path must target a document.');
    }
    if (!allowedTopLevelCollections.contains(parts.first)) {
      throw ArgumentError.value(
        path,
        'path',
        'Unsupported top-level collection.',
      );
    }
  }

  static void _validateDocumentSize(MaintainiacFirestoreDocumentDraft draft) {
    final bytes = utf8.encode(jsonEncode(draft.data)).length;
    if (bytes > maxDocumentBytes) {
      throw ArgumentError.value(
        bytes,
        draft.path,
        'Firestore document is too large for the guarded queue.',
      );
    }
  }

  static bool _isPrivateExpenseBackupPath(String path) {
    final parts = path.trim().split('/');
    return parts.length >= 4 &&
        parts.first == MaintainiacFirestoreSchema.orgs &&
        (parts[2] == MaintainiacFirestoreSchema.orgExpenses ||
            parts[2] == MaintainiacFirestoreSchema.orgSettings);
  }

  static void _validateDashboardSummaryShape(
    MaintainiacFirestoreDocumentDraft draft,
  ) {
    final parts = draft.path.trim().split('/');
    final isOrganizationDashboardPath =
        parts.length == 4 &&
        parts[0] == MaintainiacFirestoreSchema.orgs &&
        parts[2] == MaintainiacFirestoreSchema.orgDashboardSummaries;
    final isPersonalDashboardPath =
        parts.length == 4 &&
        parts[0] == 'users' &&
        parts[2] == MaintainiacFirestoreSchema.orgDashboardSummaries;
    if (!isOrganizationDashboardPath && !isPersonalDashboardPath) return;

    const allowed = {
      'schema',
      'dashboardId',
      'orgId',
      'createdByUid',
      'updatedByUid',
      'updatedAt',
      'activeVehicleId',
      'activeWorkdayId',
      'activeWorkProfileId',
      'dashboardMode',
      'mileageMode',
      'syncMode',
      'gpsAssistState',
      'storageState',
      'freeSyncsRemaining',
      'syncsUsedInWindow',
      'batteryGpsLimited',
      'reviewRequired',
      'locationDataIncluded',
      'rawModuleDataIncluded',
    };
    final validShape =
        draft.data['schema'] == 'dashboard_command_center_summary_v1' &&
        draft.data['dashboardId'] == parts[3] &&
        draft.data['locationDataIncluded'] == false &&
        draft.data['rawModuleDataIncluded'] == false &&
        draft.data.keys.every(allowed.contains) &&
        _isNonEmptyString(draft.data['createdByUid']) &&
        _isNonEmptyString(draft.data['updatedByUid']) &&
        _isNonEmptyString(draft.data['updatedAt']) &&
        _isNonEmptyString(draft.data['dashboardMode']) &&
        _isNonEmptyString(draft.data['mileageMode']) &&
        _isNonEmptyString(draft.data['syncMode']) &&
        _isNonEmptyString(draft.data['gpsAssistState']) &&
        _isNonEmptyString(draft.data['storageState']) &&
        draft.data['batteryGpsLimited'] is bool &&
        draft.data['reviewRequired'] is bool;
    if (!validShape) {
      throw ArgumentError.value(
        draft.path,
        'draft',
        'Dashboard uploads must be reference-only command-center summaries.',
      );
    }
    if (isPersonalDashboardPath) {
      if (draft.data['createdByUid'] != parts[1] ||
          draft.data['updatedByUid'] != parts[1] ||
          draft.data.containsKey('orgId')) {
        throw ArgumentError.value(
          draft.path,
          'draft',
          'Personal dashboard summary must match its user path.',
        );
      }
      return;
    }
    if (draft.data['orgId'] != parts[1]) {
      throw ArgumentError.value(
        draft.path,
        'draft',
        'Organization dashboard summary must match its organization path.',
      );
    }
  }

  static void _validateTripMileageSummaryShape(
    MaintainiacFirestoreDocumentDraft draft,
  ) {
    final parts = draft.path.trim().split('/');
    final isOrganizationMileagePath =
        parts.length == 4 &&
        parts[0] == MaintainiacFirestoreSchema.orgs &&
        parts[2] == MaintainiacFirestoreSchema.orgMileageRecords;
    final isPersonalMileagePath =
        parts.length == 4 &&
        parts[0] == 'users' &&
        parts[2] == MaintainiacFirestoreSchema.orgMileageRecords;
    if (!isOrganizationMileagePath && !isPersonalMileagePath) return;

    if (draft.data['tripId'] != parts[3]) {
      throw ArgumentError.value(
        draft.path,
        'draft',
        'Mileage backup path must match its reviewed trip id.',
      );
    }
    if (draft.data['schema'] !=
            TripTrackingFirestoreContract.reviewedSummarySchema ||
        draft.data['locationDataIncluded'] != false ||
        draft.data['visibilityScope'] != 'mileage_only' ||
        !draft.data.keys.every(
          TripTrackingFirestoreContract.reviewedSummaryFields.contains,
        ) ||
        !TripTrackingFirestoreContract.requiredReviewedSummaryFields.every(
          draft.data.containsKey,
        )) {
      throw ArgumentError.value(
        draft.path,
        'draft',
        'Mileage uploads must be coordinate-free reviewed trip summaries.',
      );
    }
    _validateTripMileageSummaryValues(draft);
    if (draft.data['createdByUid'] != draft.data['updatedByUid']) {
      throw ArgumentError.value(
        draft.path,
        'draft',
        'Mileage backups must be owned by one authenticated user.',
      );
    }
    if (isOrganizationMileagePath) {
      if (draft.data['orgId'] != parts[1] ||
          draft.data['organizationSharingConsent'] != true) {
        throw ArgumentError.value(
          draft.path,
          'draft',
          'Organization mileage requires matching explicit sharing consent.',
        );
      }
      return;
    }
    if (draft.data.containsKey('orgId') ||
        draft.data.containsKey('organizationSharingConsent')) {
      throw ArgumentError.value(
        draft.path,
        'draft',
        'Personal mileage cannot carry organization sharing fields.',
      );
    }
    if (draft.data['createdByUid'] != parts[1] ||
        draft.data['updatedByUid'] != parts[1]) {
      throw ArgumentError.value(
        draft.path,
        'draft',
        'Personal mileage must match the authenticated user backup path.',
      );
    }
  }

  static void _validateTripMileageSummaryValues(
    MaintainiacFirestoreDocumentDraft draft,
  ) {
    final startingOdometer = draft.data['startingOdometer'];
    final estimatedEndingOdometer = draft.data['estimatedEndingOdometer'];
    final confirmedEndingOdometer = draft.data['confirmedEndingOdometer'];
    final acceptedMeters = draft.data['acceptedMeters'];
    final acceptedMiles = draft.data['acceptedMiles'];
    final receivedSampleCount = draft.data['receivedSampleCount'];
    final acceptedSampleCount = draft.data['acceptedSampleCount'];
    final valid =
        _isNonEmptyString(draft.data['tripId']) &&
        _isNonEmptyString(draft.data['createdByUid']) &&
        _isNonEmptyString(draft.data['updatedByUid']) &&
        _isNonEmptyString(draft.data['vehicleId']) &&
        _isNonEmptyString(draft.data['profile']) &&
        _isNonEmptyString(draft.data['startedAt']) &&
        _isNonEmptyString(draft.data['finishedAt']) &&
        _isNonEmptyString(draft.data['createdAt']) &&
        _isNonEmptyString(draft.data['updatedAt']) &&
        _isNonNegativeInt(startingOdometer) &&
        _isNonNegativeInt(estimatedEndingOdometer) &&
        (estimatedEndingOdometer as int) >= (startingOdometer as int) &&
        _isNonNegativeInt(confirmedEndingOdometer) &&
        (confirmedEndingOdometer as int) >= startingOdometer &&
        _isNonEmptyString(draft.data['odometerConfirmedAt']) &&
        _isNonNegativeFiniteNumber(acceptedMeters) &&
        _isNonNegativeFiniteNumber(acceptedMiles) &&
        draft.data['walkingReviewSuggested'] is bool &&
        _isNonEmptyString(draft.data['motionState']) &&
        _isNonNegativeInt(receivedSampleCount) &&
        _isNonNegativeInt(acceptedSampleCount) &&
        (acceptedSampleCount as int) <= (receivedSampleCount as int);
    if (!valid) {
      throw ArgumentError.value(
        draft.path,
        'draft',
        'Mileage uploads must contain sane reviewed trip values.',
      );
    }
    if (!_hasCoherentTripMileageDistance(
      startingOdometer: startingOdometer,
      estimatedEndingOdometer: estimatedEndingOdometer,
      acceptedMeters: acceptedMeters,
      acceptedMiles: acceptedMiles,
    )) {
      throw ArgumentError.value(
        draft.path,
        'draft',
        'Mileage upload meters, miles, and odometer estimate must agree.',
      );
    }
    if (!_hasCoherentTripMileageTimeline(draft)) {
      throw ArgumentError.value(
        draft.path,
        'draft',
        'Mileage upload timestamps must reflect review after trip completion.',
      );
    }
  }

  static bool _hasCoherentTripMileageTimeline(
    MaintainiacFirestoreDocumentDraft draft,
  ) {
    final startedAt = DateTime.tryParse('${draft.data['startedAt'] ?? ''}');
    final finishedAt = DateTime.tryParse('${draft.data['finishedAt'] ?? ''}');
    final confirmedAt = DateTime.tryParse(
      '${draft.data['odometerConfirmedAt'] ?? ''}',
    );
    return startedAt != null &&
        finishedAt != null &&
        confirmedAt != null &&
        !finishedAt.isBefore(startedAt) &&
        !confirmedAt.isBefore(finishedAt);
  }

  static bool _hasCoherentTripMileageDistance({
    required Object? startingOdometer,
    required Object? estimatedEndingOdometer,
    required Object? acceptedMeters,
    required Object? acceptedMiles,
  }) {
    if (startingOdometer is! int ||
        estimatedEndingOdometer is! int ||
        acceptedMeters is! num ||
        acceptedMiles is! num) {
      return false;
    }
    final expectedMiles = acceptedMeters / _tripMetersPerMile;
    final meterMileDrift = (acceptedMiles - expectedMiles).abs();
    final odometerDelta = estimatedEndingOdometer - startingOdometer;
    return meterMileDrift <= 0.01 && odometerDelta == expectedMiles.round();
  }

  static bool _isNonEmptyString(Object? value) =>
      value is String && value.trim().isNotEmpty;

  static bool _isNonNegativeInt(Object? value) => value is int && value >= 0;

  static bool _isNonNegativeFiniteNumber(Object? value) =>
      value is num && value.isFinite && value >= 0;

  static void _validateNoSensitiveKeys(
    Object? value, {
    String parent = '',
    bool allowPrivateExpenseBackup = false,
  }) {
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        final blocked = allowPrivateExpenseBackup
            ? blockedEverywhereKeys.contains(key)
            : blockedSensitiveKeys.contains(key);
        if (blocked) {
          throw ArgumentError.value(
            key,
            parent,
            'Sensitive field is not allowed in Firestore upload queue.',
          );
        }
        _validateNoSensitiveKeys(
          entry.value,
          parent: key,
          allowPrivateExpenseBackup: allowPrivateExpenseBackup,
        );
      }
    } else if (value is Iterable) {
      for (final item in value) {
        _validateNoSensitiveKeys(
          item,
          parent: parent,
          allowPrivateExpenseBackup: allowPrivateExpenseBackup,
        );
      }
    }
  }

  static void _validateCatalogReadShape(
    MaintainiacFirestoreDocumentDraft draft,
  ) {
    if (!draft.path.startsWith('${MaintainiacFirestoreSchema.catalogPacks}/')) {
      return;
    }
    if (draft.data['firestoreItemDocumentReadCount'] != 0) {
      throw ArgumentError.value(
        draft.data['firestoreItemDocumentReadCount'],
        draft.path,
        'Catalog packs must never require item-document reads.',
      );
    }
    if (draft.data['deliveryMode'] != 'manifest_storage_chunks') {
      throw ArgumentError.value(
        draft.data['deliveryMode'],
        draft.path,
        'Catalog packs must use manifest plus Storage chunks.',
      );
    }
  }
}
