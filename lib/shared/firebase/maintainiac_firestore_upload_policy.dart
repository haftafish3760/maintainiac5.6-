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

  static const _allowedDashboardModes = <String>{
    'default',
    'gig_driver',
    'contractor',
    'solo_contractor',
    'fleet_owner',
    'employee',
    'customer',
    'personal',
  };

  static const _allowedMileageModes = <String>{
    'manual',
    'gps_assisted',
    'workday',
    'employee_shift',
    'fleet_review',
    'customer_hidden',
  };

  static const _allowedDashboardWorkStyles = <String>{
    'general_road',
    'rideshare',
    'delivery',
    'contractor',
    'equipment',
  };

  static const _allowedDashboardStopDetectionModes = <String>{
    'walking_assisted',
    'strong_debounce',
    'walking_ignored',
  };

  static const _allowedDashboardStopReviewReasons = <String>{
    'road_vehicle_stop_walk_review',
    'rideshare_stop_requires_extra_evidence',
    'delivery_stop_walk_review',
    'contractor_stop_walk_review',
    'equipment_ignores_walking_stop_evidence',
  };

  static const _allowedDashboardStopSignals = <String>{
    'no_stop',
    'stop_candidate',
    'review_only_stop',
    'likely_traffic_control',
    'equipment_ignored',
    'unsafe_evidence',
  };

  static const _allowedDashboardStopActionTokens = <String>{
    'keep_tracking',
    'continue_monitoring',
    'review_delivery_stop',
    'review_jobsite_stop',
    'review_shift_stop',
    'review_trip_stop',
  };

  static const _allowedDashboardStopClassificationReasons = <String>{
    'no_stop_review_needed',
    'unsafe_stop_evidence_rejected',
    'equipment_walking_evidence_ignored',
    'road_vehicle_stop_walk_review',
    'rideshare_stop_requires_extra_evidence',
    'delivery_stop_walk_review',
    'contractor_stop_walk_review',
    'stop_candidate_waiting_for_stronger_evidence',
    'stop_candidate_waiting_for_confirmation',
    'traffic_control_or_stationary_jitter',
  };

  static const _allowedDashboardRecoveryStates = <String>{
    'none',
    'ready',
    'pending_replay',
    'completed_review',
    'invalid_session',
    'invalid_review',
    'vehicle_mismatch',
    'odometer_mismatch',
    'projection_invalid',
  };

  static const _allowedDashboardRecoveryReasons = <String>{
    'trip_recovery_none',
    'trip_recovery_ready',
    'trip_recovery_pending_replay_ready',
    'trip_recovery_completed_review_present',
    'trip_recovery_invalid_session',
    'trip_recovery_invalid_review_present',
    'trip_recovery_vehicle_mismatch',
    'trip_recovery_odometer_mismatch',
    'trip_recovery_odometer_projection_invalid',
  };

  static const _allowedSyncModes = <String>{
    'device_retained',
    'local_only',
    'wifi_only',
    'wifi_and_mobile',
    'mobile_only',
    'firebase_backup',
    'company_sync',
  };

  static const _allowedGpsAssistStates = <String>{
    'off',
    'on',
    'gps_assisted',
    'battery_limited',
    'permission_denied',
    'unavailable',
  };

  static const _allowedDashboardGpsSignalQualities = <String>{
    'no_samples',
    'healthy',
    'reduced',
    'poor',
    'interrupted',
    'unsafe',
  };

  static const _allowedDashboardGpsSignalReasons = <String>{
    'gps_signal_waiting_for_samples',
    'gps_signal_healthy',
    'gps_signal_reduced_but_usable',
    'gps_signal_poor_measurement_quality',
    'gps_signal_interrupted_by_gap',
    'gps_signal_unsafe_provider_evidence',
  };

  static const _allowedDashboardMapboxAssistStates = <String>{
    'disabled',
    'unavailable',
    'rate_limited',
    'rejected',
    'visual_only',
    'distance_review',
  };

  static const _allowedDashboardMapboxAssistReasons = <String>{
    'mapbox_assist_disabled',
    'mapbox_route_unavailable',
    'mapbox_rate_limited',
    'mapbox_http_failure',
    'mapbox_response_not_object',
    'mapbox_service_code_not_ok',
    'mapbox_routes_missing',
    'mapbox_routes_invalid',
    'invalid_map_assist_threshold',
    'mapbox_visual_only_no_trusted_mileage',
    'mapbox_visual_assist_only',
    'mapbox_distance_review_only',
  };

  static const _allowedDashboardMapboxTrustedMileageSources = <String>{
    'none',
    'odometer',
    'gps_accepted',
  };

  static const _allowedStorageStates = <String>{
    'unknown',
    'green',
    'text_record_safe',
    'low_storage',
    'full',
    'local_only',
    'cloud_pending',
  };

  static const _allowedDeviceCapabilityStates = <String>{
    'unknown',
    'unavailable',
    'location_only',
    'foreground_ready',
    'background_ready',
    'motion_ready',
    'full_safety_assist',
  };

  static const _allowedSensorAssistStates = <String>{
    'unknown',
    'no_assist',
    'battery_available',
    'motion_available',
    'motion_battery_available',
  };

  static const _allowedOdometerCalibrationStates = <String>{
    'unknown',
    'disabled',
    'insufficient_history',
    'stable',
    'review_recommended',
    'invalid',
  };

  static const _allowedOdometerUsageStates = <String>{
    'unknown',
    'disabled',
    'insufficient_history',
    'normal',
    'review_recommended',
    'invalid',
  };

  static const _allowedDashboardWidgetTokens = <String>{
    'start_day',
    'live_odometer',
    'stops',
    'pay',
    'profit',
    'miles',
    'hours',
    'expenses',
    'jobs',
    'materials',
    'payments',
    'maintenance',
  };

  static const _allowedDashboardQuickActionTokens = <String>{
    'start_trip',
    'end_trip',
    'add_stop',
    'add_pickup',
    'add_dropoff',
    'add_job',
    'add_expense',
    'add_pay',
    'record_payment',
    'maintenance_log',
    'review_mileage',
  };

  static const _allowedTripProfiles = <String>{
    'roadVehicle',
    'rideshareVehicle',
    'deliveryVehicle',
    'contractorVehicle',
    'lowSpeedEquipment',
  };

  static const _allowedTripMotionStates = <String>{
    'unknown',
    'moving',
    'stopCandidate',
    'stopped',
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
    if (parts.any(_isUnsafePathSegment)) {
      throw ArgumentError.value(path, 'path', 'Unsafe Firestore path segment.');
    }
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

  static bool _isUnsafePathSegment(String segment) =>
      segment.isEmpty ||
      segment.length > 200 ||
      RegExp(r'[\x00-\x1F\x7F]').hasMatch(segment);

  static void _validateDocumentSize(MaintainiacFirestoreDocumentDraft draft) {
    late final int bytes;
    try {
      bytes = utf8.encode(jsonEncode(draft.data)).length;
    } catch (_) {
      throw ArgumentError.value(
        draft.path,
        'draft',
        'Firestore document contains unsupported data.',
      );
    }
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
      'workStyle',
      'stopDetectionMode',
      'stopReviewReasonCode',
      'stopSignal',
      'stopActionToken',
      'stopClassificationReason',
      'recommendedActivityRecognition',
      'requiresStrongerStopDebounce',
      'recoveryState',
      'recoveryReason',
      'recoveryUserActionRequired',
      'mileageMode',
      'syncMode',
      'gpsAssistState',
      'gpsSignalQuality',
      'gpsSignalReason',
      'gpsSignalReviewRequired',
      'mapboxAssistState',
      'mapboxAssistReason',
      'mapboxAssistReviewRequired',
      'mapboxTrustedMileageSource',
      'mapboxRouteDistanceMiles',
      'mapboxRouteDeltaMiles',
      'storageState',
      'deviceCapabilityState',
      'sensorAssistState',
      'odometerCalibrationState',
      'odometerCalibrationSamples',
      'odometerCalibrationMultiplier',
      'odometerUsageState',
      'odometerUsageReviewedDays',
      'dashboardWidgetTokens',
      'quickActionTokens',
      'freeSyncsRemaining',
      'syncsUsedInWindow',
      'batteryGpsLimited',
      'reviewRequired',
      'authorizationRequired',
      'authenticationImpliesAuthorization',
      'employeeTrackingRequiresMutualConsent',
      'preciseLocationIncluded',
      'externalRoutesCanonical',
      'odometerRemainsCanonical',
      'locationDataIncluded',
      'mapboxRouteGeometryIncluded',
      'rawModuleDataIncluded',
    };
    final validShape =
        draft.data['schema'] == 'dashboard_command_center_summary_v1' &&
        draft.data['dashboardId'] == parts[3] &&
        draft.data['locationDataIncluded'] == false &&
        draft.data['mapboxRouteGeometryIncluded'] == false &&
        draft.data['rawModuleDataIncluded'] == false &&
        draft.data.keys.every(allowed.contains) &&
        _isBoundedDashboardReference(draft.data['dashboardId']) &&
        _isBoundedDashboardReference(draft.data['createdByUid']) &&
        _isBoundedDashboardReference(draft.data['updatedByUid']) &&
        _isNonEmptyString(draft.data['updatedAt']) &&
        _hasValidOptionalStringField(draft.data, 'activeVehicleId') &&
        _hasValidOptionalStringField(draft.data, 'activeWorkdayId') &&
        _hasValidOptionalStringField(draft.data, 'activeWorkProfileId') &&
        _isAllowedString(draft.data['dashboardMode'], _allowedDashboardModes) &&
        _isAllowedString(
          draft.data['workStyle'],
          _allowedDashboardWorkStyles,
        ) &&
        _isAllowedString(
          draft.data['stopDetectionMode'],
          _allowedDashboardStopDetectionModes,
        ) &&
        _isAllowedString(
          draft.data['stopReviewReasonCode'],
          _allowedDashboardStopReviewReasons,
        ) &&
        _isAllowedString(
          draft.data['stopSignal'],
          _allowedDashboardStopSignals,
        ) &&
        _isAllowedString(
          draft.data['stopActionToken'],
          _allowedDashboardStopActionTokens,
        ) &&
        _isAllowedString(
          draft.data['stopClassificationReason'],
          _allowedDashboardStopClassificationReasons,
        ) &&
        draft.data['recommendedActivityRecognition'] is bool &&
        draft.data['requiresStrongerStopDebounce'] is bool &&
        _isAllowedString(
          draft.data['recoveryState'],
          _allowedDashboardRecoveryStates,
        ) &&
        _isAllowedString(
          draft.data['recoveryReason'],
          _allowedDashboardRecoveryReasons,
        ) &&
        draft.data['recoveryUserActionRequired'] is bool &&
        _isAllowedString(draft.data['mileageMode'], _allowedMileageModes) &&
        _isAllowedString(draft.data['syncMode'], _allowedSyncModes) &&
        _isIsoTimestamp(draft.data['updatedAt']) &&
        _isAllowedString(
          draft.data['gpsAssistState'],
          _allowedGpsAssistStates,
        ) &&
        _isAllowedString(
          draft.data['gpsSignalQuality'],
          _allowedDashboardGpsSignalQualities,
        ) &&
        _isAllowedString(
          draft.data['gpsSignalReason'],
          _allowedDashboardGpsSignalReasons,
        ) &&
        draft.data['gpsSignalReviewRequired'] is bool &&
        _isAllowedString(
          draft.data['mapboxAssistState'],
          _allowedDashboardMapboxAssistStates,
        ) &&
        _isAllowedString(
          draft.data['mapboxAssistReason'],
          _allowedDashboardMapboxAssistReasons,
        ) &&
        draft.data['mapboxAssistReviewRequired'] is bool &&
        _isAllowedString(
          draft.data['mapboxTrustedMileageSource'],
          _allowedDashboardMapboxTrustedMileageSources,
        ) &&
        _isValidDashboardMapboxMiles(draft.data['mapboxRouteDistanceMiles']) &&
        _isValidDashboardMapboxMiles(draft.data['mapboxRouteDeltaMiles']) &&
        _isAllowedString(draft.data['storageState'], _allowedStorageStates) &&
        _isAllowedString(
          draft.data['deviceCapabilityState'],
          _allowedDeviceCapabilityStates,
        ) &&
        _isAllowedString(
          draft.data['sensorAssistState'],
          _allowedSensorAssistStates,
        ) &&
        _isAllowedString(
          draft.data['odometerCalibrationState'],
          _allowedOdometerCalibrationStates,
        ) &&
        _isValidSyncsUsedInWindow(draft.data['odometerCalibrationSamples']) &&
        _isValidDashboardCalibrationMultiplier(
          draft.data['odometerCalibrationMultiplier'],
        ) &&
        _isAllowedString(
          draft.data['odometerUsageState'],
          _allowedOdometerUsageStates,
        ) &&
        _isValidSyncsUsedInWindow(draft.data['odometerUsageReviewedDays']) &&
        _hasValidDashboardTokenList(
          draft.data['dashboardWidgetTokens'],
          _allowedDashboardWidgetTokens,
        ) &&
        _hasValidDashboardTokenList(
          draft.data['quickActionTokens'],
          _allowedDashboardQuickActionTokens,
        ) &&
        _isValidFreeSyncsRemaining(draft.data['freeSyncsRemaining']) &&
        _isValidSyncsUsedInWindow(draft.data['syncsUsedInWindow']) &&
        _hasConsistentDashboardSyncCounters(draft.data) &&
        draft.data['batteryGpsLimited'] is bool &&
        draft.data['reviewRequired'] is bool &&
        draft.data['authorizationRequired'] == true &&
        draft.data['authenticationImpliesAuthorization'] == false &&
        draft.data['employeeTrackingRequiresMutualConsent'] == true &&
        draft.data['preciseLocationIncluded'] == false &&
        draft.data['externalRoutesCanonical'] == false &&
        draft.data['odometerRemainsCanonical'] == true;
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
    if (draft.data['createdByUid'] != draft.data['updatedByUid']) {
      throw ArgumentError.value(
        draft.path,
        'draft',
        'Organization dashboard summary owner fields must agree.',
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
        _isAllowedString(draft.data['profile'], _allowedTripProfiles) &&
        _isNonEmptyString(draft.data['startedAt']) &&
        _isNonEmptyString(draft.data['finishedAt']) &&
        _isIsoTimestamp(draft.data['createdAt']) &&
        _isIsoTimestamp(draft.data['updatedAt']) &&
        _isNonNegativeInt(startingOdometer) &&
        _isNonNegativeInt(estimatedEndingOdometer) &&
        (estimatedEndingOdometer as int) >= (startingOdometer as int) &&
        _isNonNegativeInt(confirmedEndingOdometer) &&
        (confirmedEndingOdometer as int) >= startingOdometer &&
        _isNonEmptyString(draft.data['odometerConfirmedAt']) &&
        _isNonNegativeFiniteNumber(acceptedMeters) &&
        _isNonNegativeFiniteNumber(acceptedMiles) &&
        draft.data['walkingReviewSuggested'] is bool &&
        _isAllowedString(draft.data['motionState'], _allowedTripMotionStates) &&
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
    final createdAt = DateTime.tryParse('${draft.data['createdAt'] ?? ''}');
    final updatedAt = DateTime.tryParse('${draft.data['updatedAt'] ?? ''}');
    return startedAt != null &&
        finishedAt != null &&
        confirmedAt != null &&
        createdAt != null &&
        updatedAt != null &&
        !finishedAt.isBefore(startedAt) &&
        !confirmedAt.isBefore(finishedAt) &&
        !updatedAt.isBefore(createdAt);
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

  static bool _isBoundedDashboardReference(Object? value) =>
      value is String &&
      value.trim().isNotEmpty &&
      value.length <= 128 &&
      RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value);

  static bool _hasValidOptionalStringField(
    Map<String, Object?> data,
    String field,
  ) => !data.containsKey(field) || _isBoundedDashboardReference(data[field]);

  static bool _isAllowedString(Object? value, Set<String> allowed) =>
      value is String && allowed.contains(value);

  static bool _isIsoTimestamp(Object? value) =>
      value is String && DateTime.tryParse(value) != null;

  static bool _isValidFreeSyncsRemaining(Object? value) =>
      value == null ||
      (value is int &&
          value >= 0 &&
          value <= HostedUsageLimits.freeUserSyncsPer24HourWindow);

  static bool _isValidSyncsUsedInWindow(Object? value) =>
      value == null || (value is int && value >= 0 && value <= 999);

  static bool _isValidDashboardCalibrationMultiplier(Object? value) =>
      value == null || (value is num && value >= .8 && value <= 1.25);

  static bool _isValidDashboardMapboxMiles(Object? value) =>
      value == null || (value is num && value >= 0 && value <= 12500);

  static bool _hasValidDashboardTokenList(Object? value, Set<String> allowed) {
    if (value == null) return true;
    if (value is! List || value.length > 12) return false;
    return value.every((item) => item is String && allowed.contains(item));
  }

  static bool _hasConsistentDashboardSyncCounters(Map<String, Object?> data) {
    final remaining = data['freeSyncsRemaining'];
    final used = data['syncsUsedInWindow'];
    if (remaining == null || used == null) return true;
    if (remaining is! int || used is! int) return false;
    return remaining ==
        HostedUsageLimits.freeSyncsRemaining(syncsUsedInWindow: used);
  }

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
