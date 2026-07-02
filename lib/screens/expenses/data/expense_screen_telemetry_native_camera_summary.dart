part of 'expense_screen_telemetry.dart';

class _ExpenseTelemetryNativeCameraSummary {
  final _engineCounts = <String, int>{};
  final _surfaceActualCounts = <String, int>{};
  final _surfaceVerificationCounts = <String, int>{};
  final _identityCounts = <String, int>{};
  final _settingsContractVersionCounts = <String, int>{};
  final _controlContractVersionCounts = <String, int>{};
  final _devicePolicyCounts = <String, int>{};
  final _workloadTierCounts = <String, int>{};
  final _resolutionTierCounts = <String, int>{};
  final _recoveryResumeStatusCounts = <String, int>{};
  final _recoveryFreshnessCounts = <String, int>{};
  final _recoveryStorageStatusCounts = <String, int>{};
  final _capabilityPolicyCodeCounts = <String, int>{};
  final _captureSourcePolicyCounts = <String, int>{};

  var recoveredPhotoCount = 0;
  var multipleSectionCount = 0;

  Map<String, int> get engineCounts => Map.unmodifiable(_engineCounts);
  Map<String, int> get surfaceActualCounts {
    return Map.unmodifiable(_surfaceActualCounts);
  }

  Map<String, int> get surfaceVerificationCounts {
    return Map.unmodifiable(_surfaceVerificationCounts);
  }

  Map<String, int> get identityCounts => Map.unmodifiable(_identityCounts);
  Map<String, int> get settingsContractVersionCounts {
    return Map.unmodifiable(_settingsContractVersionCounts);
  }

  Map<String, int> get controlContractVersionCounts {
    return Map.unmodifiable(_controlContractVersionCounts);
  }

  Map<String, int> get devicePolicyCounts {
    return Map.unmodifiable(_devicePolicyCounts);
  }

  Map<String, int> get workloadTierCounts {
    return Map.unmodifiable(_workloadTierCounts);
  }

  Map<String, int> get resolutionTierCounts {
    return Map.unmodifiable(_resolutionTierCounts);
  }

  Map<String, int> get recoveryResumeStatusCounts {
    return Map.unmodifiable(_recoveryResumeStatusCounts);
  }

  Map<String, int> get recoveryFreshnessCounts {
    return Map.unmodifiable(_recoveryFreshnessCounts);
  }

  Map<String, int> get recoveryStorageStatusCounts {
    return Map.unmodifiable(_recoveryStorageStatusCounts);
  }

  Map<String, int> get capabilityPolicyCodeCounts {
    return Map.unmodifiable(_capabilityPolicyCodeCounts);
  }

  Map<String, int> get captureSourcePolicyCounts {
    return Map.unmodifiable(_captureSourcePolicyCounts);
  }

  String get topEngine => _topCountKey(_engineCounts);
  String get topSurfaceActual => _topCountKey(_surfaceActualCounts);
  String get topSurfaceVerification => _topCountKey(_surfaceVerificationCounts);
  String get topIdentity => _topCountKey(_identityCounts);
  String get topSettingsContractVersion {
    return _topCountKey(_settingsContractVersionCounts);
  }

  String get topControlContractVersion {
    return _topCountKey(_controlContractVersionCounts);
  }

  String get topDevicePolicy => _topCountKey(_devicePolicyCounts);
  String get topWorkloadTier => _topCountKey(_workloadTierCounts);
  String get topResolutionTier => _topCountKey(_resolutionTierCounts);
  String get topRecoveryResumeStatus {
    return _topCountKey(_recoveryResumeStatusCounts);
  }

  String get topRecoveryFreshness => _topCountKey(_recoveryFreshnessCounts);
  String get topRecoveryStorageStatus {
    return _topCountKey(_recoveryStorageStatusCounts);
  }

  String get topRecoveryAction {
    return _nativeRecoveryAction(
      freshnessCounts: _recoveryFreshnessCounts,
      storageStatusCounts: _recoveryStorageStatusCounts,
    );
  }

  String get topCapabilityPolicyCode =>
      _topCountKey(_capabilityPolicyCodeCounts);
  String get topCaptureSourcePolicy => _topCountKey(_captureSourcePolicyCounts);

  void recordIdentity(Map<String, Object?> metadata) {
    _mergeCountMap(
      _engineCounts,
      _metadataValue(metadata['nativeCameraEngineBuckets']),
    );
    _increment(
      _surfaceActualCounts,
      _stringValue(metadata['nativeReceiptCameraSurfaceActual']),
    );
    _mergeCountMap(
      _surfaceActualCounts,
      _metadataValue(metadata['nativeReceiptCameraSurfaceActualBuckets']),
    );
    _increment(
      _surfaceVerificationCounts,
      _stringValue(metadata['nativeReceiptCameraSurfaceVerification']),
    );
    _mergeCountMap(
      _surfaceVerificationCounts,
      _metadataValue(metadata['nativeReceiptCameraSurfaceVerificationBuckets']),
    );
    _increment(_identityCounts, _stringValue(metadata['nativeCameraIdentity']));
    _mergeCountMap(
      _identityCounts,
      _metadataValue(metadata['nativeCameraIdentityBuckets']),
    );
    _mergeCountMap(
      _controlContractVersionCounts,
      _metadataValue(metadata['nativeControlContractVersionBuckets']),
    );
    _increment(
      _settingsContractVersionCounts,
      _stringValue(metadata['settingsContractVersion']),
    );
    _mergeCountMap(
      _settingsContractVersionCounts,
      _metadataValue(metadata['settingsContractVersionBuckets']),
    );
  }

  void recordPolicyAndRecovery(Map<String, Object?> metadata) {
    _mergeCountMap(
      _devicePolicyCounts,
      _metadataValue(metadata['nativeDevicePolicyBuckets']),
    );
    _mergeCountMap(
      _workloadTierCounts,
      _metadataValue(metadata['nativeCameraWorkloadTierBuckets']),
    );
    _mergeCountMap(
      _resolutionTierCounts,
      _metadataValue(metadata['nativeCameraResolutionTierBuckets']),
    );
    _mergeCountMap(
      _recoveryResumeStatusCounts,
      _metadataValue(metadata['nativeRecoveryResumeStatusBuckets']),
    );
    _mergeCountMap(
      _recoveryFreshnessCounts,
      _metadataValue(metadata['nativeRecoveryFreshnessBuckets']),
    );
    _mergeCountMap(
      _recoveryStorageStatusCounts,
      _metadataValue(metadata['nativeRecoveryStorageStatusBuckets']),
    );
    recoveredPhotoCount += _intValue(
      metadata['nativeRecoveryRecoveredPhotoTotal'],
    );
    multipleSectionCount += _intValue(
      metadata['nativeRecoveryMultipleSectionCount'],
    );
    _mergeCountMap(
      _capabilityPolicyCodeCounts,
      _metadataValue(metadata['capabilityPolicyCodeCounts']),
    );
    _mergeCountMap(
      _captureSourcePolicyCounts,
      _metadataValue(metadata['nativeCaptureSourcePolicyCounts']),
    );
  }
}
