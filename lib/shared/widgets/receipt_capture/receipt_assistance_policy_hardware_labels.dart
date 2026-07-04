part of 'receipt_assistance_policy.dart';

extension ReceiptHardwareProfileLabels on ReceiptHardwareProfile {
  String get storageClassLabel {
    return switch (storageClass) {
      ReceiptDeviceStorageClass.unknown => 'Unknown',
      ReceiptDeviceStorageClass.critical => 'Critical - strongest space saving',
      ReceiptDeviceStorageClass.low => 'Low - stronger space saving',
      ReceiptDeviceStorageClass.comfortable => 'Comfortable',
      ReceiptDeviceStorageClass.roomy => 'Roomy',
    };
  }

  String get lowPowerModeLabel => lowPowerMode ? 'On' : 'Off';

  String get accelerationLabel {
    return hasOnDeviceAcceleration ? 'Detected' : 'Not detected';
  }

  String get deviceLabel {
    final maker = deviceManufacturer?.trim();
    final model = deviceModel?.trim();
    if ((maker == null || maker.isEmpty) && (model == null || model.isEmpty)) {
      return 'Unknown device';
    }
    if (maker == null || maker.isEmpty) return model!;
    if (model == null || model.isEmpty) return maker;
    return '$maker $model';
  }

  String get appVersionLabel {
    final version = appVersion?.trim();
    final build = appBuildNumber?.trim();
    if (version == null || version.isEmpty) return 'Unknown';
    if (build == null || build.isEmpty) return version;
    return '$version+$build';
  }

  String get cameraLabel {
    if (!cameraPermissionGranted) return 'Camera permission not granted';
    if (!hasRearCamera) return 'No rear camera detected';
    return '$cameraCount camera${cameraCount == 1 ? '' : 's'} detected';
  }

  String get receiptCameraControlLabel {
    final controls = <String>[
      if (supportsTapFocus) 'focus assist',
      if (supportsZoom) 'pinch zoom',
      if (supportsExposureCompensation) 'brightness',
      if (supportsNativeEdgeSignals) 'edge guidance',
      if (supportsYuvLiveFrames) 'live readability',
    ];
    if (controls.isEmpty) return 'Basic receipt camera controls';
    return controls.join(', ');
  }

  ReceiptFeatureInstallRecommendation receiptInstallRecommendationFor({
    ReceiptPerformanceMode mode = ReceiptPerformanceMode.automatic,
  }) {
    final capability = ReceiptDeviceCapability.fromHardware(
      hardware: this,
      mode: mode,
    );
    return capability.receiptInstallRecommendationFor(storageClass);
  }

  ReceiptBrainFootprintSummary receiptBrainFootprintSummaryFor({
    ReceiptPerformanceMode mode = ReceiptPerformanceMode.automatic,
  }) {
    final capability = ReceiptDeviceCapability.fromHardware(
      hardware: this,
      mode: mode,
    );
    return capability.receiptBrainFootprintSummaryFor(storageClass);
  }

  ReceiptBrainDeploymentRecommendation receiptBrainRecommendationFor({
    ReceiptPerformanceMode mode = ReceiptPerformanceMode.automatic,
  }) {
    final capability = ReceiptDeviceCapability.fromHardware(
      hardware: this,
      mode: mode,
    );
    return capability.receiptBrainRecommendationFor(storageClass);
  }
}
