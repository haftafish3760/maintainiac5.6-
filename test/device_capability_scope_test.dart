import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/device_capabilities/device_capabilities.dart';

void main() {
  testWidgets('scope exposes one live device profile to descendant screens', (
    tester,
  ) async {
    final probe = _FakeProbe();
    final controller = DeviceCapabilityController(probe: probe);
    await controller.initialize();

    late DeviceCapabilityController observed;
    await tester.pumpWidget(
      DeviceCapabilityScope(
        controller: controller,
        child: Builder(
          builder: (context) {
            observed = DeviceCapabilityScope.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(observed, same(controller));
    expect(observed.profile?.tier, DevicePerformanceTier.balanced);
    await observed.refreshRuntime();
    expect(probe.refreshCount, 1);
    controller.dispose();
  });

  testWidgets('native change events debounce into one live refresh', (
    tester,
  ) async {
    final probe = _FakeLiveProbe();
    final controller = DeviceCapabilityController(probe: probe);
    await controller.initialize();

    probe.emit();
    probe.emit();
    await tester.pump(const Duration(milliseconds: 251));
    await tester.pump();

    expect(probe.refreshCount, 1);
    controller.dispose();
    await probe.close();
  });
}

class _FakeLiveProbe extends _FakeProbe implements DeviceCapabilityLiveProbe {
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  void emit() => _changes.add(null);
  Future<void> close() => _changes.close();
}

class _FakeProbe implements DeviceCapabilityProbe {
  int refreshCount = 0;

  @override
  Future<DeviceCapabilityProfile> profile({bool refresh = false}) async {
    if (refresh) refreshCount++;
    return DeviceCapabilityProfile(
      hardware: const DeviceHardwareSnapshot(
        platform: 'android',
        physicalRamMb: 6144,
        cpuCores: 8,
      ),
      runtime: DeviceRuntimeSnapshot(
        observedAt: DateTime.utc(2026, 7, 15),
        availableRamMb: 2000,
        freeStorageMb: 8000,
      ),
      camera: const DeviceCameraCapabilities(),
      baselineTier: DevicePerformanceTier.balanced,
      tier: DevicePerformanceTier.balanced,
      confidence: DeviceCapabilityConfidence.medium,
      score: 4,
      limitingFactors: const [],
    );
  }
}
