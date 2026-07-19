import 'device_capability.dart';

class DeviceOperationalPolicy {
  const DeviceOperationalPolicy({
    required this.deferNonEssentialHeavyWork,
    required this.allowLargeNetworkTransfer,
    required this.liveAnalysisFps,
    required this.maxOcrBatchImages,
    required this.maxPdfRasterDpi,
    required this.tripLocationIntervalSeconds,
    required this.maxCameraMegapixels,
    required this.preferredVideoCodec,
  });

  final bool deferNonEssentialHeavyWork;
  final bool allowLargeNetworkTransfer;
  final int liveAnalysisFps;
  final int maxOcrBatchImages;
  final int maxPdfRasterDpi;
  final int tripLocationIntervalSeconds;
  final int maxCameraMegapixels;
  final String preferredVideoCodec;

  factory DeviceOperationalPolicy.fromProfile(DeviceCapabilityProfile profile) {
    final battery = profile.extended.battery;
    final constrained =
        profile.runtime.powerSaving ||
        profile.runtime.isThermallyConstrained ||
        (profile.runtime.freeStorageMb != null &&
            profile.runtime.freeStorageMb! < 3000) ||
        (profile.runtime.freeStorageFraction != null &&
            profile.runtime.freeStorageFraction! < 0.05) ||
        (!battery.isCharging && battery.isLow);
    final budget = profile.budget;
    final cameraMegapixels = profile.camera.maxStillMegapixels;
    final safeCameraMegapixels = switch (profile.tier) {
      DevicePerformanceTier.constrained => 8,
      DevicePerformanceTier.entry => 12,
      DevicePerformanceTier.balanced => 16,
      DevicePerformanceTier.enhanced => 24,
      DevicePerformanceTier.performance => 36,
      DevicePerformanceTier.flagship => 50,
    };
    final media = profile.extended.media;
    final preferredCodec = media.canHardwareEncode('hevc')
        ? 'hevc'
        : media.canHardwareEncode('h264')
        ? 'h264'
        : 'platform_default';
    return DeviceOperationalPolicy(
      deferNonEssentialHeavyWork: constrained,
      allowLargeNetworkTransfer:
          !constrained && profile.extended.connectivity.permitsLargeTransfer,
      liveAnalysisFps: constrained
          ? budget.preferredLiveAnalysisFps.clamp(3, 5)
          : budget.preferredLiveAnalysisFps,
      maxOcrBatchImages: constrained
          ? budget.maxOcrBatchImages.clamp(1, 3)
          : budget.maxOcrBatchImages,
      maxPdfRasterDpi: constrained
          ? budget.maxPdfRasterDpi.clamp(100, 140)
          : budget.maxPdfRasterDpi,
      tripLocationIntervalSeconds: constrained
          ? budget.tripLocationIntervalSeconds.clamp(10, 20)
          : budget.tripLocationIntervalSeconds,
      maxCameraMegapixels: cameraMegapixels <= 0
          ? safeCameraMegapixels
          : cameraMegapixels.clamp(1, safeCameraMegapixels),
      preferredVideoCodec: preferredCodec,
    );
  }
}

extension DeviceOperationalPolicyAccess on DeviceCapabilityProfile {
  DeviceOperationalPolicy get operationalPolicy =>
      DeviceOperationalPolicy.fromProfile(this);
}
