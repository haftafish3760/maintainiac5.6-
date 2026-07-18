enum TripValidationFailureBoundary {
  nativeGps,
  nativeActivity,
  firestoreMirror,
  firebaseAuth,
  mapbox,
  hiveLocalStore,
  importFile,
  cloudFunction,
}

enum TripValidationFailureSeverity {
  info,
  warning,
  recoverable,
  sensitiveWriteBlocked,
}

class TripValidationFailureLogEvent {
  const TripValidationFailureLogEvent({
    required this.boundary,
    required this.severity,
    required this.reasonCode,
    required this.operation,
    required this.ownerVerified,
    required this.schemaVerified,
    required this.authorizationVerified,
    required this.recoveryAction,
  });

  final TripValidationFailureBoundary boundary;
  final TripValidationFailureSeverity severity;
  final String reasonCode;
  final String operation;
  final bool ownerVerified;
  final bool schemaVerified;
  final bool authorizationVerified;
  final String recoveryAction;

  Map<String, Object?> toSafeLogMap() => {
    'schemaVersion': 1,
    'boundary': boundary.name,
    'severity': severity.name,
    'reasonCode': _safeReason(reasonCode),
    'operation': _safeOperation(operation),
    'ownerVerified': ownerVerified,
    'schemaVerified': schemaVerified,
    'authorizationVerified': authorizationVerified,
    'recoveryAction': _safeRecoveryAction(recoveryAction),
    'externalDataValidatedBeforeUse': true,
    'authenticationDoesNotImplyAuthorization': true,
    'failClosedForSensitiveWrites': true,
    'failGracefullyForOptionalMaps': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'odometerRemainsOfficialMileageTruth': true,
    'remoteTotalsCanonical': false,
    'mapboxResponsesAreExternalInput': true,
    'validationFailureCanDeleteLocalData': false,
    'validationFailureCanConfirmMileage': false,
    'validationFailureCanCreateOfficialStop': false,
    'rawPayloadIncluded': false,
    'rawLocationIncluded': false,
    'preciseTimestampIncluded': false,
    'privateUserContentIncluded': false,
    'tokensIncluded': false,
  };
}

class TripValidationFailureLogPolicy {
  const TripValidationFailureLogPolicy._();

  static TripValidationFailureLogEvent classify({
    required TripValidationFailureBoundary boundary,
    required String reasonCode,
    required String operation,
    required bool ownerVerified,
    required bool schemaVerified,
    required bool authorizationVerified,
    bool sensitiveWrite = false,
    bool optionalMappingFeature = false,
  }) {
    final severity = _severityFor(
      ownerVerified: ownerVerified,
      schemaVerified: schemaVerified,
      authorizationVerified: authorizationVerified,
      sensitiveWrite: sensitiveWrite,
      optionalMappingFeature: optionalMappingFeature,
    );
    return TripValidationFailureLogEvent(
      boundary: boundary,
      severity: severity,
      reasonCode: reasonCode,
      operation: operation,
      ownerVerified: ownerVerified,
      schemaVerified: schemaVerified,
      authorizationVerified: authorizationVerified,
      recoveryAction: _recoveryActionFor(
        boundary: boundary,
        severity: severity,
        optionalMappingFeature: optionalMappingFeature,
      ),
    );
  }
}

TripValidationFailureSeverity _severityFor({
  required bool ownerVerified,
  required bool schemaVerified,
  required bool authorizationVerified,
  required bool sensitiveWrite,
  required bool optionalMappingFeature,
}) {
  if (sensitiveWrite && (!ownerVerified || !authorizationVerified)) {
    return TripValidationFailureSeverity.sensitiveWriteBlocked;
  }
  if (!schemaVerified || !ownerVerified || !authorizationVerified) {
    return optionalMappingFeature
        ? TripValidationFailureSeverity.warning
        : TripValidationFailureSeverity.recoverable;
  }
  return TripValidationFailureSeverity.info;
}

String _recoveryActionFor({
  required TripValidationFailureBoundary boundary,
  required TripValidationFailureSeverity severity,
  required bool optionalMappingFeature,
}) {
  if (severity == TripValidationFailureSeverity.sensitiveWriteBlocked) {
    return 'block_sensitive_write';
  }
  if (optionalMappingFeature ||
      boundary == TripValidationFailureBoundary.mapbox) {
    return 'disable_optional_map_feature';
  }
  if (boundary == TripValidationFailureBoundary.nativeGps ||
      boundary == TripValidationFailureBoundary.nativeActivity) {
    return 'continue_local_trip_without_bad_sample';
  }
  if (boundary == TripValidationFailureBoundary.firestoreMirror ||
      boundary == TripValidationFailureBoundary.cloudFunction) {
    return 'keep_local_truth_and_retry_mirror';
  }
  return 'keep_local_record_and_request_review';
}

String _safeReason(String value) {
  final clean = value.trim();
  if (clean.isEmpty || clean.length > 80) return 'validation_failed';
  if (_containsSensitiveValue(clean)) return 'validation_failed';
  return RegExp(r'^[a-z0-9_:-]+$').hasMatch(clean)
      ? clean
      : 'validation_failed';
}

String _safeOperation(String value) {
  final clean = value.trim();
  if (clean.isEmpty || clean.length > 80) return 'trip_tracking_operation';
  if (_containsSensitiveValue(clean)) return 'trip_tracking_operation';
  return RegExp(r'^[a-z0-9_:-]+$').hasMatch(clean)
      ? clean
      : 'trip_tracking_operation';
}

String _safeRecoveryAction(String value) {
  final clean = value.trim();
  return switch (clean) {
    'block_sensitive_write' ||
    'disable_optional_map_feature' ||
    'continue_local_trip_without_bad_sample' ||
    'keep_local_truth_and_retry_mirror' ||
    'keep_local_record_and_request_review' => clean,
    _ => 'keep_local_record_and_request_review',
  };
}

bool _containsSensitiveValue(String value) {
  final lower = value.toLowerCase();
  return lower.contains('token') ||
      lower.contains('secret') ||
      lower.contains('pk.') ||
      lower.contains('sk.') ||
      RegExp(r'-?\d{1,3}\.\d{4,}').hasMatch(value);
}
