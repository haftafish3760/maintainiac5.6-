import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:maintaniac/shared/device_capabilities/device_capabilities.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final profile = await DeviceCapabilityService.instance.profile(refresh: true);
  final policy = profile.operationalPolicy;
  final payload = <String, Object?>{
    'diagnostics': profile.toPrivacySafeDiagnostics(),
    'hardware': {
      'physicalRamMb': profile.hardware.physicalRamMb,
      'availableRamMb': profile.runtime.availableRamMb,
      'cpuCores': profile.hardware.cpuCores,
      'cpuArchitecture': profile.hardware.cpuArchitecture,
      'applicationHeapMb': profile.hardware.applicationHeapMb,
      'mediaPerformanceClass': profile.hardware.androidMediaPerformanceClass,
    },
    'storage': {
      'freeMb': profile.runtime.freeStorageMb,
      'totalMb': profile.runtime.totalStorageMb,
      'freeFraction': profile.runtime.freeStorageFraction,
    },
    'cameraLenses': profile.extended.cameraLenses
        .map(
          (lens) => {
            'position': lens.position,
            'type': lens.lensType,
            'physicalLensCount': lens.physicalLensCount,
            'megapixels': lens.maxStillMegapixels,
            'focalRangeMm': [lens.minFocalLengthMm, lens.maxFocalLengthMm],
            'maxZoom': lens.maxDigitalZoom,
            'maxFps': lens.maxVideoFps,
            'autofocus': lens.supportsAutofocus,
            'stabilization': lens.supportsStabilization,
            'raw': lens.supportsRaw,
            'depth': lens.supportsDepth,
            'hdr': lens.supportsHdr,
          },
        )
        .toList(growable: false),
    'sensors': profile.extended.sensors.types.toList()..sort(),
    'battery': {
      'levelPercent': profile.extended.battery.levelPercent,
      'charging': profile.extended.battery.isCharging,
      'source': profile.extended.battery.powerSource.name,
      'health': profile.extended.battery.health.name,
      'temperatureCelsius': profile.extended.battery.temperatureCelsius,
      'estimatedFullCapacityMah':
          profile.extended.battery.estimatedFullCapacityMah,
      'capacityEstimateReliable':
          profile.extended.battery.capacityEstimateReliable,
    },
    'display': {
      'pixels': [
        profile.extended.display.widthPixels,
        profile.extended.display.heightPixels,
      ],
      'density': profile.extended.display.densityScale,
      'maxRefreshHz': profile.extended.display.maxRefreshRateHz,
      'hdr': profile.extended.display.supportsHdr,
      'wideColor': profile.extended.display.supportsWideColor,
    },
    'media': {
      'hardwareDecode': profile.extended.media.hardwareDecodeTypes.toList(),
      'hardwareEncode': profile.extended.media.hardwareEncodeTypes.toList(),
    },
    'graphics': {
      'api': profile.extended.graphics.apiName,
      'version': profile.extended.graphics.apiVersion,
      'featureLevel': profile.extended.graphics.featureLevel,
      'compute': profile.extended.graphics.supportsCompute,
      'rayTracing': profile.extended.graphics.supportsRayTracing,
    },
    'connectivity': {
      'transports': profile.extended.connectivity.transports.toList(),
      'connected': profile.extended.connectivity.isConnected,
      'metered': profile.extended.connectivity.isMetered,
      'constrained': profile.extended.connectivity.isConstrained,
      'downstreamKbps': profile.extended.connectivity.downstreamKbps,
      'upstreamKbps': profile.extended.connectivity.upstreamKbps,
    },
    'policy': {
      'deferHeavyWork': policy.deferNonEssentialHeavyWork,
      'allowLargeTransfer': policy.allowLargeNetworkTransfer,
      'liveAnalysisFps': policy.liveAnalysisFps,
      'maxOcrBatchImages': policy.maxOcrBatchImages,
      'maxPdfRasterDpi': policy.maxPdfRasterDpi,
      'tripLocationIntervalSeconds': policy.tripLocationIntervalSeconds,
      'maxCameraMegapixels': policy.maxCameraMegapixels,
      'preferredVideoCodec': policy.preferredVideoCodec,
    },
  };
  for (final entry in payload.entries) {
    if (entry.key == 'cameraLenses' && entry.value is List<Object?>) {
      final lenses = entry.value! as List<Object?>;
      for (var index = 0; index < lenses.length; index++) {
        debugPrint(
          'MAINTAINIAC_DEVICE_CAPABILITY_QA_CAMERA_$index='
          '${jsonEncode(lenses[index])}',
        );
      }
      continue;
    }
    debugPrint(
      'MAINTAINIAC_DEVICE_CAPABILITY_QA_${entry.key.toUpperCase()}='
      '${jsonEncode(entry.value)}',
    );
  }
  runApp(const _ProbeCompleteApp());
}

class _ProbeCompleteApp extends StatelessWidget {
  const _ProbeCompleteApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Device capability QA complete')),
      ),
    );
  }
}
