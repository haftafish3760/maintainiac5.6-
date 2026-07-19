import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:flutter/services.dart';

import 'device_capability.dart';
import 'device_feature_capabilities.dart';
import 'device_feature_capability_parser.dart';

abstract class DeviceCapabilityProbe {
  Future<DeviceCapabilityProfile> profile({bool refresh = false});
}

abstract class DeviceCapabilityLiveProbe implements DeviceCapabilityProbe {
  Stream<void> get changes;
}

/// One device-local source of truth for the whole running app. It does not use
/// account identity or durable storage, so separate devices on one account are
/// always classified from their own hardware and current conditions.
class DeviceCapabilityService implements DeviceCapabilityLiveProbe {
  DeviceCapabilityService({
    DeviceInfoPlugin? deviceInfo,
    MethodChannel? nativeChannel,
    EventChannel? eventChannel,
  }) : _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
       _nativeChannel =
           nativeChannel ??
           const MethodChannel('maintainiac/device_capabilities'),
       _eventChannel =
           eventChannel ??
           const EventChannel('maintainiac/device_capability_events');

  static final DeviceCapabilityService instance = DeviceCapabilityService();

  final DeviceInfoPlugin _deviceInfo;
  final MethodChannel _nativeChannel;
  final EventChannel _eventChannel;
  final DeviceCapabilityClassifier _classifier =
      const DeviceCapabilityClassifier();
  final DeviceFeatureCapabilityParser _featureParser =
      const DeviceFeatureCapabilityParser();

  Future<DeviceHardwareSnapshot>? _hardware;
  Future<DeviceCameraCapabilities>? _camera;
  Future<DeviceExtendedCapabilities>? _extendedStatic;
  Future<DeviceCapabilityProfile>? _cachedProfile;
  Stream<void>? _changes;

  @override
  Stream<void> get changes => _changes ??= _readChanges().asBroadcastStream();

  Stream<void> _readChanges() async* {
    try {
      await for (final _ in _eventChannel.receiveBroadcastStream()) {
        yield null;
      }
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  @override
  Future<DeviceCapabilityProfile> profile({bool refresh = false}) {
    if (!refresh) return _cachedProfile ??= _detect(refreshRuntime: false);
    return _cachedProfile = _detect(refreshRuntime: true);
  }

  void invalidate() {
    _hardware = null;
    _camera = null;
    _extendedStatic = null;
    _cachedProfile = null;
  }

  Future<DeviceCapabilityProfile> _detect({
    required bool refreshRuntime,
  }) async {
    final hardwareFuture = _hardware ??= _readHardware();
    final cameraFuture = _camera ??= _readCamera();
    final values = await Future.wait<Object>([
      hardwareFuture,
      _readRuntime(),
      cameraFuture,
      _readExtended(refreshRuntime: refreshRuntime),
    ]);
    return _classifier.classify(
      values[0] as DeviceHardwareSnapshot,
      runtime: values[1] as DeviceRuntimeSnapshot,
      camera: values[2] as DeviceCameraCapabilities,
      extended: values[3] as DeviceExtendedCapabilities,
    );
  }

  Future<DeviceHardwareSnapshot> _readHardware() async {
    final identity = await _readIdentity();
    final native = await _invokeMap('readRuntimeCapabilities');
    final cores = Platform.numberOfProcessors;
    return DeviceHardwareSnapshot(
      platform: Platform.operatingSystem,
      platformVersion: Platform.operatingSystemVersion,
      manufacturer: identity.manufacturer,
      model: identity.model,
      hardwareIdentifier: identity.hardwareIdentifier,
      androidSdk: identity.androidSdk,
      androidMediaPerformanceClass: _positiveInt(
        native['mediaPerformanceClass'],
      ),
      physicalRamMb:
          _positiveInt(native['physicalRamMb']) ?? identity.physicalRamMb,
      cpuCores: cores > 0 ? cores : null,
      cpuArchitecture:
          _trimmedString(native['cpuArchitecture']) ?? identity.cpuArchitecture,
      applicationHeapMb: _positiveInt(native['applicationHeapMb']),
      isLowRamDevice: identity.isLowRamDevice,
      isPhysicalDevice: identity.isPhysicalDevice,
    );
  }

  Future<DeviceRuntimeSnapshot> _readRuntime() async {
    final native = await _invokeMap('readRuntimeCapabilities');
    final identity = await _readIdentity();
    return DeviceRuntimeSnapshot(
      observedAt: DateTime.now().toUtc(),
      availableRamMb:
          _positiveInt(native['availableRamMb']) ?? identity.availableRamMb,
      freeStorageMb: await _readFreeStorageMb(),
      totalStorageMb: await _readTotalStorageMb(),
      powerSaving: native['powerSaving'] == true,
      thermalState: _thermalState(native['thermalState']),
    );
  }

  Future<DeviceCameraCapabilities> _readCamera() async {
    final value = await _invokeMap('readCameraCapabilities');
    return DeviceCameraCapabilities(
      available: value['available'] == true,
      cameraCount: _nonNegativeInt(value['cameraCount']) ?? 0,
      hasRearCamera: value['hasRearCamera'] == true,
      hasFrontCamera: value['hasFrontCamera'] == true,
      supportsTapFocus: value['supportsTapFocus'] == true,
      supportsContinuousFocus: value['supportsContinuousFocus'] == true,
      supportsExposureCompensation:
          value['supportsExposureCompensation'] == true,
      supportsZoom: value['supportsZoom'] == true,
      supportsMacroSelection: value['supportsMacroSelection'] == true,
      supportsTorch: value['supportsTorch'] == true,
      supportsRaw: value['supportsRaw'] == true,
      maxStillWidth: _nonNegativeInt(value['maxStillWidth']) ?? 0,
      maxStillHeight: _nonNegativeInt(value['maxStillHeight']) ?? 0,
    );
  }

  Future<DeviceExtendedCapabilities> _readExtended({
    required bool refreshRuntime,
  }) async {
    final stable = await (_extendedStatic ??= _readAllExtended());
    if (!refreshRuntime) return stable;
    final dynamic = _featureParser.parse(
      await _invokeMap('readDynamicCapabilities'),
    );
    return stable.withRuntime(
      battery: dynamic.battery,
      connectivity: dynamic.connectivity,
    );
  }

  Future<DeviceExtendedCapabilities> _readAllExtended() async {
    return _featureParser.parse(await _invokeMap('readExtendedCapabilities'));
  }

  Future<Map<Object?, Object?>> _invokeMap(String method) async {
    try {
      final value = await _nativeChannel.invokeMapMethod<Object?, Object?>(
        method,
      );
      return value ?? const {};
    } on MissingPluginException {
      return const {};
    } on PlatformException {
      return const {};
    } catch (_) {
      return const {};
    }
  }

  Future<_DeviceIdentity> _readIdentity() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return _DeviceIdentity(
          manufacturer: info.manufacturer,
          model: info.model,
          hardwareIdentifier: info.device,
          androidSdk: info.version.sdkInt,
          physicalRamMb: info.physicalRamSize > 0 ? info.physicalRamSize : null,
          availableRamMb: info.availableRamSize > 0
              ? info.availableRamSize
              : null,
          cpuArchitecture: info.supportedAbis.firstOrNull,
          isLowRamDevice: info.isLowRamDevice,
          isPhysicalDevice: info.isPhysicalDevice,
        );
      }
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return _DeviceIdentity(
          manufacturer: 'Apple',
          model: info.model,
          hardwareIdentifier: info.utsname.machine,
          physicalRamMb: info.physicalRamSize > 0 ? info.physicalRamSize : null,
          availableRamMb: info.availableRamSize > 0
              ? info.availableRamSize
              : null,
          cpuArchitecture: info.utsname.machine,
          isPhysicalDevice: info.isPhysicalDevice,
        );
      }
      if (Platform.isMacOS) {
        final info = await _deviceInfo.macOsInfo;
        return _DeviceIdentity(
          manufacturer: 'Apple',
          model: info.model,
          hardwareIdentifier: info.arch,
          physicalRamMb: info.memorySize > 0
              ? (info.memorySize / (1024 * 1024)).round()
              : null,
          cpuArchitecture: info.arch,
        );
      }
      if (Platform.isWindows) {
        final info = await _deviceInfo.windowsInfo;
        return _DeviceIdentity(
          manufacturer: info.registeredOwner,
          model: info.productName,
          hardwareIdentifier: info.deviceId,
          physicalRamMb: info.systemMemoryInMegabytes,
        );
      }
      if (Platform.isLinux) {
        final info = await _deviceInfo.linuxInfo;
        return _DeviceIdentity(
          manufacturer: info.prettyName,
          model: info.name,
          hardwareIdentifier: info.machineId,
        );
      }
    } on PlatformException {
      return const _DeviceIdentity();
    } catch (_) {
      return const _DeviceIdentity();
    }
    return const _DeviceIdentity();
  }

  Future<int?> _readFreeStorageMb() async {
    try {
      final value = await DiskSpacePlus().getFreeDiskSpace;
      return value != null && value > 0 ? value.round() : null;
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<int?> _readTotalStorageMb() async {
    try {
      final value = await DiskSpacePlus().getTotalDiskSpace;
      return value != null && value > 0 ? value.round() : null;
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static DeviceThermalState _thermalState(Object? value) {
    return switch (value?.toString()) {
      'nominal' => DeviceThermalState.nominal,
      'fair' => DeviceThermalState.fair,
      'serious' => DeviceThermalState.serious,
      'critical' => DeviceThermalState.critical,
      _ => DeviceThermalState.unknown,
    };
  }

  static int? _positiveInt(Object? value) {
    final parsed = value is num ? value.toInt() : int.tryParse('$value');
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static int? _nonNegativeInt(Object? value) {
    final parsed = value is num ? value.toInt() : int.tryParse('$value');
    return parsed != null && parsed >= 0 ? parsed : null;
  }

  static String? _trimmedString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class _DeviceIdentity {
  const _DeviceIdentity({
    this.manufacturer,
    this.model,
    this.hardwareIdentifier,
    this.androidSdk,
    this.physicalRamMb,
    this.availableRamMb,
    this.cpuArchitecture,
    this.isLowRamDevice = false,
    this.isPhysicalDevice = true,
  });

  final String? manufacturer;
  final String? model;
  final String? hardwareIdentifier;
  final int? androidSdk;
  final int? physicalRamMb;
  final int? availableRamMb;
  final String? cpuArchitecture;
  final bool isLowRamDevice;
  final bool isPhysicalDevice;
}
