import 'device_feature_capabilities.dart';

class DeviceFeatureCapabilityParser {
  const DeviceFeatureCapabilityParser();

  DeviceExtendedCapabilities parse(Map<Object?, Object?> value) {
    return DeviceExtendedCapabilities(
      cameraLenses: _cameraLenses(value['cameraLenses']),
      sensors: _sensors(_map(value['sensors'])),
      battery: _battery(_map(value['battery'])),
      display: _display(_map(value['display'])),
      media: _media(_map(value['media'])),
      graphics: _graphics(_map(value['graphics'])),
      connectivity: _connectivity(_map(value['connectivity'])),
    );
  }

  List<DeviceCameraLensCapability> _cameraLenses(Object? raw) {
    if (raw is! List) return const [];
    return List.unmodifiable(
      raw
          .map(_map)
          .where((item) => item.isNotEmpty)
          .map(
            (item) => DeviceCameraLensCapability(
              position: _text(item['position']) ?? 'unknown',
              lensType: _text(item['lensType']) ?? 'unknown',
              physicalLensCount: _positiveInt(item['physicalLensCount']) ?? 1,
              maxStillWidth: _nonNegativeInt(item['maxStillWidth']) ?? 0,
              maxStillHeight: _nonNegativeInt(item['maxStillHeight']) ?? 0,
              minFocalLengthMm: _positiveDouble(item['minFocalLengthMm']),
              maxFocalLengthMm: _positiveDouble(item['maxFocalLengthMm']),
              minAperture: _positiveDouble(item['minAperture']),
              maxOpticalOrSensorZoom:
                  _positiveDouble(item['maxOpticalOrSensorZoom']) ?? 1,
              maxDigitalZoom: _positiveDouble(item['maxDigitalZoom']) ?? 1,
              maxVideoFps: _nonNegativeInt(item['maxVideoFps']) ?? 0,
              supportsAutofocus: item['supportsAutofocus'] == true,
              supportsStabilization: item['supportsStabilization'] == true,
              supportsRaw: item['supportsRaw'] == true,
              supportsDepth: item['supportsDepth'] == true,
              supportsHdr: item['supportsHdr'] == true,
            ),
          ),
    );
  }

  DeviceSensorCapabilities _sensors(Map<Object?, Object?> value) {
    final types = _stringSet(value['types']);
    return DeviceSensorCapabilities(
      sensorCount: _nonNegativeInt(value['sensorCount']) ?? types.length,
      types: types,
      permissionGatedTypes: _stringSet(value['permissionGatedTypes']),
    );
  }

  DeviceBatteryCapabilities _battery(Map<Object?, Object?> value) {
    return DeviceBatteryCapabilities(
      levelPercent: _boundedPercent(value['levelPercent']),
      isCharging: value['isCharging'] == true,
      powerSource: _powerSource(value['powerSource']),
      health: _batteryHealth(value['health']),
      temperatureCelsius: _number(value['temperatureCelsius']),
      remainingChargeMah: _positiveInt(value['remainingChargeMah']),
      estimatedFullCapacityMah: _positiveInt(value['estimatedFullCapacityMah']),
      capacityEstimateReliable: value['capacityEstimateReliable'] == true,
    );
  }

  DeviceDisplayCapabilities _display(Map<Object?, Object?> value) {
    return DeviceDisplayCapabilities(
      widthPixels: _nonNegativeInt(value['widthPixels']) ?? 0,
      heightPixels: _nonNegativeInt(value['heightPixels']) ?? 0,
      densityScale: _positiveDouble(value['densityScale']) ?? 1,
      maxRefreshRateHz: _positiveDouble(value['maxRefreshRateHz']) ?? 0,
      supportsHdr: value['supportsHdr'] == true,
      supportsWideColor: value['supportsWideColor'] == true,
    );
  }

  DeviceMediaCapabilities _media(Map<Object?, Object?> value) {
    return DeviceMediaCapabilities(
      hardwareDecodeTypes: _stringSet(value['hardwareDecodeTypes']),
      hardwareEncodeTypes: _stringSet(value['hardwareEncodeTypes']),
    );
  }

  DeviceGraphicsCapabilities _graphics(Map<Object?, Object?> value) {
    return DeviceGraphicsCapabilities(
      apiName: _text(value['apiName']) ?? 'unknown',
      apiVersion: _text(value['apiVersion']) ?? 'unknown',
      featureLevel: _text(value['featureLevel']) ?? 'unknown',
      supportsCompute: value['supportsCompute'] == true,
      supportsRayTracing: value['supportsRayTracing'] == true,
    );
  }

  DeviceConnectivityCapabilities _connectivity(Map<Object?, Object?> value) {
    return DeviceConnectivityCapabilities(
      transports: _stringSet(value['transports']),
      isConnected: value['isConnected'] == true,
      isMetered: value['isMetered'] == true,
      isConstrained: value['isConstrained'] == true,
      downstreamKbps: _nonNegativeInt(value['downstreamKbps']),
      upstreamKbps: _nonNegativeInt(value['upstreamKbps']),
    );
  }

  static Map<Object?, Object?> _map(Object? value) {
    return value is Map ? Map<Object?, Object?>.from(value) : const {};
  }

  static Set<String> _stringSet(Object? value) {
    if (value is! List) return const {};
    return Set.unmodifiable(value.map(_text).whereType<String>());
  }

  static int? _boundedPercent(Object? value) {
    final number = _nonNegativeInt(value);
    return number != null && number <= 100 ? number : null;
  }

  static int? _positiveInt(Object? value) {
    final parsed = value is num ? value.toInt() : int.tryParse('$value');
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static int? _nonNegativeInt(Object? value) {
    final parsed = value is num ? value.toInt() : int.tryParse('$value');
    return parsed != null && parsed >= 0 ? parsed : null;
  }

  static double? _positiveDouble(Object? value) {
    final parsed = _number(value);
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static double? _number(Object? value) {
    return value is num ? value.toDouble() : double.tryParse('$value');
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static DevicePowerSource _powerSource(Object? value) {
    return DevicePowerSource.values.firstWhere(
      (item) => item.name == value?.toString(),
      orElse: () => DevicePowerSource.unknown,
    );
  }

  static DeviceBatteryHealth _batteryHealth(Object? value) {
    return DeviceBatteryHealth.values.firstWhere(
      (item) => item.name == value?.toString(),
      orElse: () => DeviceBatteryHealth.unknown,
    );
  }
}
