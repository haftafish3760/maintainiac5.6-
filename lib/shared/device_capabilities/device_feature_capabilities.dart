enum DeviceBatteryHealth { unknown, good, degraded, overheating, failure }

enum DevicePowerSource { unknown, battery, usb, ac, wireless }

class DeviceCameraLensCapability {
  const DeviceCameraLensCapability({
    required this.position,
    required this.lensType,
    this.physicalLensCount = 1,
    this.maxStillWidth = 0,
    this.maxStillHeight = 0,
    this.minFocalLengthMm,
    this.maxFocalLengthMm,
    this.minAperture,
    this.maxOpticalOrSensorZoom = 1,
    this.maxDigitalZoom = 1,
    this.maxVideoFps = 0,
    this.supportsAutofocus = false,
    this.supportsStabilization = false,
    this.supportsRaw = false,
    this.supportsDepth = false,
    this.supportsHdr = false,
  });

  final String position;
  final String lensType;
  final int physicalLensCount;
  final int maxStillWidth;
  final int maxStillHeight;
  final double? minFocalLengthMm;
  final double? maxFocalLengthMm;
  final double? minAperture;
  final double maxOpticalOrSensorZoom;
  final double maxDigitalZoom;
  final int maxVideoFps;
  final bool supportsAutofocus;
  final bool supportsStabilization;
  final bool supportsRaw;
  final bool supportsDepth;
  final bool supportsHdr;

  int get maxStillMegapixels {
    if (maxStillWidth <= 0 || maxStillHeight <= 0) return 0;
    return ((maxStillWidth * maxStillHeight) / 1000000).round();
  }
}

class DeviceSensorCapabilities {
  const DeviceSensorCapabilities({
    this.sensorCount = 0,
    this.types = const <String>{},
    this.permissionGatedTypes = const <String>{},
  });

  final int sensorCount;
  final Set<String> types;
  final Set<String> permissionGatedTypes;

  bool supports(String type) => types.contains(type);
  bool get hasMotion => supports('accelerometer') && supports('gyroscope');
  bool get hasHeading => supports('magnetometer');
  bool get hasPressure => supports('barometer');
  bool get hasStepDetection =>
      supports('step_counter') || supports('step_detector');
  bool get hasExerciseSignals =>
      hasStepDetection ||
      supports('activity_recognition') ||
      supports('walking_distance') ||
      supports('walking_pace') ||
      supports('walking_cadence') ||
      supports('floor_counting');
  bool get hasMotionStateTransitions =>
      supports('motion_detect') ||
      supports('stationary_detect') ||
      supports('significant_motion') ||
      supports('activity_recognition');
  bool get hasBodySignals =>
      supports('heart_rate') ||
      supports('heart_beat') ||
      permissionGatedTypes.contains('heart_rate');
  bool get hasAltitudeContext =>
      supports('barometer') || supports('floor_counting');
  bool get hasAmbientContext =>
      supports('ambient_light') || supports('proximity');
}

class DeviceBatteryCapabilities {
  const DeviceBatteryCapabilities({
    this.levelPercent,
    this.isCharging = false,
    this.powerSource = DevicePowerSource.unknown,
    this.health = DeviceBatteryHealth.unknown,
    this.temperatureCelsius,
    this.remainingChargeMah,
    this.estimatedFullCapacityMah,
    this.capacityEstimateReliable = false,
  });

  final int? levelPercent;
  final bool isCharging;
  final DevicePowerSource powerSource;
  final DeviceBatteryHealth health;
  final double? temperatureCelsius;
  final int? remainingChargeMah;

  /// Android may provide an estimate. iOS does not expose battery design
  /// capacity publicly, so this remains null rather than guessing.
  final int? estimatedFullCapacityMah;
  final bool capacityEstimateReliable;

  bool get isLow => levelPercent != null && levelPercent! <= 20;
  bool get isCritical => levelPercent != null && levelPercent! <= 10;
}

class DeviceDisplayCapabilities {
  const DeviceDisplayCapabilities({
    this.widthPixels = 0,
    this.heightPixels = 0,
    this.densityScale = 1,
    this.maxRefreshRateHz = 0,
    this.supportsHdr = false,
    this.supportsWideColor = false,
  });

  final int widthPixels;
  final int heightPixels;
  final double densityScale;
  final double maxRefreshRateHz;
  final bool supportsHdr;
  final bool supportsWideColor;

  int get longestEdge =>
      widthPixels > heightPixels ? widthPixels : heightPixels;
}

class DeviceMediaCapabilities {
  const DeviceMediaCapabilities({
    this.hardwareDecodeTypes = const <String>{},
    this.hardwareEncodeTypes = const <String>{},
  });

  final Set<String> hardwareDecodeTypes;
  final Set<String> hardwareEncodeTypes;

  bool canHardwareDecode(String codec) => hardwareDecodeTypes.contains(codec);
  bool canHardwareEncode(String codec) => hardwareEncodeTypes.contains(codec);
}

class DeviceConnectivityCapabilities {
  const DeviceConnectivityCapabilities({
    this.transports = const <String>{},
    this.isConnected = false,
    this.isMetered = false,
    this.isConstrained = false,
    this.downstreamKbps,
    this.upstreamKbps,
  });

  final Set<String> transports;
  final bool isConnected;
  final bool isMetered;
  final bool isConstrained;
  final int? downstreamKbps;
  final int? upstreamKbps;

  bool get permitsLargeTransfer => isConnected && !isMetered && !isConstrained;
}

class DeviceGraphicsCapabilities {
  const DeviceGraphicsCapabilities({
    this.apiName = 'unknown',
    this.apiVersion = 'unknown',
    this.featureLevel = 'unknown',
    this.supportsCompute = false,
    this.supportsRayTracing = false,
  });

  final String apiName;
  final String apiVersion;
  final String featureLevel;
  final bool supportsCompute;
  final bool supportsRayTracing;
}

class DeviceExtendedCapabilities {
  const DeviceExtendedCapabilities({
    this.cameraLenses = const [],
    this.sensors = const DeviceSensorCapabilities(),
    this.battery = const DeviceBatteryCapabilities(),
    this.display = const DeviceDisplayCapabilities(),
    this.media = const DeviceMediaCapabilities(),
    this.graphics = const DeviceGraphicsCapabilities(),
    this.connectivity = const DeviceConnectivityCapabilities(),
  });

  static const empty = DeviceExtendedCapabilities();

  final List<DeviceCameraLensCapability> cameraLenses;
  final DeviceSensorCapabilities sensors;
  final DeviceBatteryCapabilities battery;
  final DeviceDisplayCapabilities display;
  final DeviceMediaCapabilities media;
  final DeviceGraphicsCapabilities graphics;
  final DeviceConnectivityCapabilities connectivity;

  DeviceExtendedCapabilities withRuntime({
    required DeviceBatteryCapabilities battery,
    required DeviceConnectivityCapabilities connectivity,
  }) {
    return DeviceExtendedCapabilities(
      cameraLenses: cameraLenses,
      sensors: sensors,
      battery: battery,
      display: display,
      media: media,
      graphics: graphics,
      connectivity: connectivity,
    );
  }
}
