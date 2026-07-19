import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/device_capabilities/device_capabilities.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_device_capability_service.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'receipt camera consumes shared device facts without reprobe drift',
    () async {
      const channel = MethodChannel('maintainiac/receipt_shared_adapter_test');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'readCapabilities');
            return {
              'engine': 'cameraX',
              'available': true,
              'supportsYuvLiveFrames': true,
              'supportsNativeEdgeSignals': true,
              'maxStillWidth': 3000,
              'maxStillHeight': 2000,
            };
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      final service = ReceiptDeviceCapabilityService(
        deviceCapabilityProbe: _FakeSharedProbe(_profile()),
        nativeCameraService: const ReceiptNativeCameraService(
          methodChannel: channel,
        ),
      );
      final hardware = await service.detectHardwareProfile();

      expect(hardware.availableRamMb, 3072);
      expect(hardware.freeStorageMb, 499);
      expect(hardware.androidPerformanceClass, 33);
      expect(hardware.lowPowerMode, isTrue);
      expect(hardware.cameraCount, 2);
      expect(hardware.hasRearCamera, isTrue);
      expect(hardware.supportsContinuousFocus, isTrue);
      expect(hardware.supportsYuvLiveFrames, isTrue);
      expect(hardware.supportsNativeEdgeSignals, isTrue);
      expect(hardware.maxStillWidth, 4032);
      expect(hardware.maxStillHeight, 3024);
      expect(hardware.storageClass.name, 'low');
    },
  );
}

DeviceCapabilityProfile _profile() {
  return DeviceCapabilityProfile(
    hardware: const DeviceHardwareSnapshot(
      platform: 'android',
      androidSdk: 33,
      androidMediaPerformanceClass: 33,
      physicalRamMb: 3072,
      cpuCores: 4,
      isLowRamDevice: true,
    ),
    runtime: DeviceRuntimeSnapshot(
      observedAt: DateTime.utc(2026, 7, 16),
      freeStorageMb: 499,
      powerSaving: true,
    ),
    camera: const DeviceCameraCapabilities(
      available: true,
      cameraCount: 2,
      hasRearCamera: true,
      hasFrontCamera: true,
      supportsContinuousFocus: true,
      supportsExposureCompensation: true,
      supportsZoom: true,
      maxStillWidth: 4032,
      maxStillHeight: 3024,
    ),
    baselineTier: DevicePerformanceTier.entry,
    tier: DevicePerformanceTier.constrained,
    confidence: DeviceCapabilityConfidence.high,
    score: 2,
    limitingFactors: const ['limited_memory'],
  );
}

class _FakeSharedProbe implements DeviceCapabilityProbe {
  const _FakeSharedProbe(this.value);

  final DeviceCapabilityProfile value;

  @override
  Future<DeviceCapabilityProfile> profile({bool refresh = false}) async {
    expect(refresh, isTrue);
    return value;
  }
}
