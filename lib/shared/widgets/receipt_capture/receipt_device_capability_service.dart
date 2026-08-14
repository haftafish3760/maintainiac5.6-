import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../device_capabilities/device_capabilities.dart';
import 'receipt_assistance_policy.dart';
import 'receipt_native_camera_contract.dart';
import 'receipt_native_camera_service.dart';

/// Receipt-specific adapter over the app-wide device capability source.
///
/// General hardware/runtime detection must stay in [DeviceCapabilityService].
/// This adapter adds only receipt-camera permission and native signals that are
/// not yet represented by the shared camera capability model.
class ReceiptDeviceCapabilityService {
  const ReceiptDeviceCapabilityService({
    DeviceCapabilityProbe? deviceCapabilityProbe,
    ReceiptNativeCameraService nativeCameraService =
        const ReceiptNativeCameraService(),
  }) : _deviceCapabilityProbe = deviceCapabilityProbe,
       _nativeCameraService = nativeCameraService;

  final DeviceCapabilityProbe? _deviceCapabilityProbe;
  final ReceiptNativeCameraService _nativeCameraService;

  DeviceCapabilityProbe get _sharedProbe =>
      _deviceCapabilityProbe ?? DeviceCapabilityService.instance;

  Future<ReceiptHardwareProfile> detectHardwareProfile() async {
    final values = await Future.wait<Object?>([
      _sharedProbe.profile(refresh: true),
      _nativeCameraService.readCapabilities(),
      _readCameraPermissionGranted(),
      _readPackageInfo(),
    ]);
    final shared = values[0]! as DeviceCapabilityProfile;
    final nativeCamera = values[1]! as ReceiptNativeCameraCapabilities;
    final cameraPermission = values[2]! as bool;
    final package = values[3] as PackageInfo?;
    final hardware = shared.hardware;
    final runtime = shared.runtime;
    final camera = shared.camera;

    return ReceiptHardwareProfile(
      platformName: hardware.platform,
      platformVersion: hardware.platformVersion,
      deviceModel: hardware.model,
      deviceManufacturer: hardware.manufacturer,
      deviceName: hardware.hardwareIdentifier,
      appVersion: package?.version,
      appBuildNumber: package?.buildNumber,
      // Receipt work must follow the memory the app can use right now, not
      // just the amount installed in the phone.  Fall back to total memory
      // only when the operating system cannot report a live value.
      availableRamMb: runtime.availableRamMb ?? hardware.physicalRamMb,
      cpuCores: hardware.cpuCores,
      androidSdk: hardware.androidSdk,
      androidPerformanceClass: hardware.androidMediaPerformanceClass,
      isLowRamDevice: hardware.isLowRamDevice,
      freeStorageMb: runtime.freeStorageMb,
      lowPowerMode: runtime.powerSaving || runtime.isThermallyConstrained,
      hasOnDeviceAcceleration: hardware.androidMediaPerformanceClass != null,
      cameraPermissionGranted: cameraPermission,
      cameraCount: camera.cameraCount,
      hasRearCamera: camera.hasRearCamera,
      hasFrontCamera: camera.hasFrontCamera,
      supportsTapFocus: camera.supportsTapFocus,
      supportsContinuousFocus: camera.supportsContinuousFocus,
      supportsExposureCompensation: camera.supportsExposureCompensation,
      supportsZoom: camera.supportsZoom,
      supportsYuvLiveFrames: nativeCamera.supportsYuvLiveFrames,
      supportsNativeEdgeSignals: nativeCamera.supportsNativeEdgeSignals,
      maxStillWidth: camera.maxStillWidth > 0
          ? camera.maxStillWidth
          : nativeCamera.maxStillWidth,
      maxStillHeight: camera.maxStillHeight > 0
          ? camera.maxStillHeight
          : nativeCamera.maxStillHeight,
      rearCameraName: nativeCamera.engine.label,
    );
  }

  Future<ReceiptDeviceCapability> detectCapability({
    ReceiptPerformanceMode mode = ReceiptPerformanceMode.automatic,
  }) async {
    final hardware = await detectHardwareProfile();
    return ReceiptDeviceCapability.fromHardware(hardware: hardware, mode: mode);
  }

  Future<PackageInfo?> _readPackageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _readCameraPermissionGranted() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted || status.isLimited;
    } catch (_) {
      return false;
    }
  }
}
