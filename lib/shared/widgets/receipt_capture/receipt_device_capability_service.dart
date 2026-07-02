import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'receipt_assistance_policy.dart';
import 'receipt_native_camera_service.dart';

class ReceiptDeviceCapabilityService {
  const ReceiptDeviceCapabilityService({
    ReceiptNativeCameraService nativeCameraService =
        const ReceiptNativeCameraService(),
  }) : _nativeCameraService = nativeCameraService;

  final ReceiptNativeCameraService _nativeCameraService;

  Future<ReceiptHardwareProfile> detectHardwareProfile() async {
    final cpuCores = Platform.numberOfProcessors;
    final device = await _readDeviceInfo();
    final package = await _readPackageInfo();
    final cameraPermission = await _readCameraPermissionGranted();
    final nativeCamera = await _nativeCameraService.readCapabilities();
    return ReceiptHardwareProfile(
      platformName: Platform.operatingSystem,
      platformVersion: Platform.operatingSystemVersion,
      deviceModel: device.model,
      deviceManufacturer: device.manufacturer,
      deviceName: device.name,
      appVersion: package?.version,
      appBuildNumber: package?.buildNumber,
      availableRamMb: await _readAndroidMemoryMb(),
      cpuCores: cpuCores <= 0 ? null : cpuCores,
      androidSdk: device.androidSdk ?? _readAndroidSdk(),
      freeStorageMb: await _readFreeStorageMb(),
      cameraPermissionGranted: cameraPermission,
      cameraCount: nativeCamera.cameraCount,
      hasRearCamera: nativeCamera.hasRearCamera,
      hasFrontCamera: nativeCamera.hasFrontCamera,
      supportsTapFocus: nativeCamera.supportsTapFocus,
      supportsExposureCompensation: nativeCamera.supportsExposureCompensation,
      supportsZoom: nativeCamera.supportsZoom,
      supportsYuvLiveFrames: nativeCamera.supportsYuvLiveFrames,
      supportsNativeEdgeSignals: nativeCamera.supportsNativeEdgeSignals,
      maxStillWidth: nativeCamera.maxStillWidth,
      maxStillHeight: nativeCamera.maxStillHeight,
      rearCameraName: nativeCamera.engine.label,
    );
  }

  Future<int?> _readFreeStorageMb() async {
    try {
      final freeMb = await DiskSpacePlus().getFreeDiskSpace;
      if (freeMb == null || freeMb <= 0) return null;
      return freeMb.round();
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<ReceiptDeviceCapability> detectCapability({
    ReceiptPerformanceMode mode = ReceiptPerformanceMode.automatic,
  }) async {
    final hardware = await detectHardwareProfile();
    return ReceiptDeviceCapability.fromHardware(hardware: hardware, mode: mode);
  }

  Future<int?> _readAndroidMemoryMb() async {
    if (!Platform.isAndroid && !Platform.isLinux) return null;
    try {
      final file = File('/proc/meminfo');
      if (!await file.exists()) return null;
      final text = await file.readAsString();
      final total = RegExp(
        r'^MemTotal:\s+(\d+)\s+kB$',
        multiLine: true,
      ).firstMatch(text)?.group(1);
      final valueKb = int.tryParse(total ?? '');
      if (valueKb == null || valueKb <= 0) return null;
      return (valueKb / 1024).round();
    } catch (_) {
      return null;
    }
  }

  int? _readAndroidSdk() {
    if (!Platform.isAndroid) return null;
    final match = RegExp(
      r'Android\s+(\d+)',
      caseSensitive: false,
    ).firstMatch(Platform.operatingSystemVersion);
    return int.tryParse(match?.group(1) ?? '');
  }

  Future<_DeviceIdentity> _readDeviceInfo() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        return _DeviceIdentity(
          manufacturer: android.manufacturer,
          model: android.model,
          name: android.device,
          androidSdk: android.version.sdkInt,
        );
      }
      if (Platform.isIOS) {
        final ios = await info.iosInfo;
        return _DeviceIdentity(
          manufacturer: 'Apple',
          model: ios.utsname.machine,
          name: ios.name,
        );
      }
      if (Platform.isMacOS) {
        final mac = await info.macOsInfo;
        return _DeviceIdentity(
          manufacturer: 'Apple',
          model: mac.model,
          name: mac.computerName,
        );
      }
      if (Platform.isWindows) {
        final windows = await info.windowsInfo;
        return _DeviceIdentity(
          manufacturer: windows.registeredOwner,
          model: windows.productName,
          name: windows.computerName,
        );
      }
      if (Platform.isLinux) {
        final linux = await info.linuxInfo;
        return _DeviceIdentity(
          manufacturer: linux.prettyName,
          model: linux.machineId,
          name: linux.name,
        );
      }
    } on PlatformException {
      return const _DeviceIdentity();
    } catch (_) {
      return const _DeviceIdentity();
    }
    return const _DeviceIdentity();
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

class _DeviceIdentity {
  const _DeviceIdentity({
    this.manufacturer,
    this.model,
    this.name,
    this.androidSdk,
  });

  final String? manufacturer;
  final String? model;
  final String? name;
  final int? androidSdk;
}
